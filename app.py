from flask import Flask, jsonify, request, render_template
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import config
from datetime import date, datetime, timedelta
import decimal

app = Flask(__name__)
CORS(app)


def get_db():
    return mysql.connector.connect(
        host=config.DB_HOST,
        user=config.DB_USER,
        password=config.DB_PASSWORD,
        database=config.DB_NAME
    )


def serialize_row(cursor, row):
    cols = [c[0] for c in cursor.description]
    result = {}
    for col, val in zip(cols, row):
        if isinstance(val, (date, datetime)):
            result[col] = val.isoformat()
        elif isinstance(val, decimal.Decimal):
            result[col] = float(val)
        else:
            result[col] = val
    return result


def serialize_rows(cursor, rows):
    return [serialize_row(cursor, r) for r in rows]


# ─── Page Routes ──────────────────────────────────────────────────────────────

@app.route('/')
def page_dashboard():
    return render_template('dashboard.html')

@app.route('/assets')
def page_assets():
    return render_template('assets.html')

@app.route('/vendors')
def page_vendors():
    return render_template('vendors.html')

@app.route('/employees')
def page_employees():
    return render_template('employees.html')

@app.route('/purchase-orders')
def page_purchase_orders():
    return render_template('purchase_orders.html')


# ─── Dashboard ────────────────────────────────────────────────────────────────

@app.route('/api/dashboard/stats')
def dashboard_stats():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()

        cur.execute("SELECT COUNT(*) FROM asset")
        total_assets = cur.fetchone()[0]

        cur.execute("SELECT COUNT(*) FROM vendor_master")
        active_vendors = cur.fetchone()[0]

        cur.execute("SELECT COUNT(*) FROM purchase_order_header WHERE status='PENDING'")
        open_pos = cur.fetchone()[0]

        cur.execute("SELECT COUNT(*) FROM individual WHERE person_type='EMPLOYEE'")
        total_employees = cur.fetchone()[0]

        cur.execute("""
            SELECT s.status_name, COUNT(a.internal_id) AS cnt
            FROM asset_status s
            LEFT JOIN asset a ON a.thisobject2status = s.internal_id
            GROUP BY s.status_name
        """)
        assets_by_status = [{'status_name': r[0], 'count': r[1]} for r in cur.fetchall()]

        cur.execute("""
            SELECT a.internal_id, a.asset_tag, a.make, a.asset_model,
                   sub.subtype_name, st.status_name, a.purchase_cost
            FROM asset a
            JOIN asset_subtype_master sub ON sub.internal_id = a.thisobject2subtype
            JOIN asset_status st ON st.internal_id = a.thisobject2status
            ORDER BY a.internal_id DESC
            LIMIT 10
        """)
        recent_assets = []
        for r in cur.fetchall():
            recent_assets.append({
                'internal_id': r[0], 'asset_tag': r[1], 'make': r[2],
                'asset_model': r[3], 'subtype_name': r[4], 'status_name': r[5],
                'purchase_cost': float(r[6]) if r[6] is not None else None
            })

        cur.execute("""
            SELECT t.type_name, COUNT(a.internal_id) AS cnt
            FROM asset_type_master t
            LEFT JOIN asset_subtype_master sub ON sub.thisobject2asset_type = t.internal_id
            LEFT JOIN asset a ON a.thisobject2subtype = sub.internal_id
            GROUP BY t.type_name
        """)
        asset_distribution = [{'type_name': r[0], 'count': r[1]} for r in cur.fetchall()]

        today = date.today()
        in_30 = today + timedelta(days=30)
        cur.execute("""
            SELECT m.internal_id, m.maintenance_date AS opened_on, m.description AS notes,
                   m.status, m.cost, a.asset_tag, a.make, a.asset_model
            FROM maintenance_record m
            JOIN asset a ON a.internal_id = m.thisobject2asset
            JOIN (
                SELECT thisobject2asset, MIN(internal_id) AS min_id
                FROM maintenance_record
                WHERE status != 'COMPLETED'
                  AND maintenance_date BETWEEN %s AND %s
                GROUP BY thisobject2asset
            ) dedup ON dedup.thisobject2asset = m.thisobject2asset
                   AND dedup.min_id = m.internal_id
            WHERE m.status != 'COMPLETED'
              AND m.maintenance_date BETWEEN %s AND %s
            ORDER BY m.maintenance_date ASC
            LIMIT 5
        """, (today.isoformat(), in_30.isoformat(), today.isoformat(), in_30.isoformat()))
        maintenance_due = []
        for r in cur.fetchall():
            maintenance_due.append({
                'internal_id': r[0],
                'opened_on': r[1].isoformat() if r[1] else None,
                'notes': r[2], 'status': r[3],
                'cost': float(r[4]) if r[4] else None,
                'asset_tag': r[5], 'make': r[6], 'asset_model': r[7]
            })

        cur.execute("""
            SELECT status, COUNT(*) AS cnt
            FROM purchase_order_header
            GROUP BY status
        """)
        po_summary = [{'status': r[0], 'count': r[1]} for r in cur.fetchall()]

        cur.execute("SELECT COUNT(*) FROM individual_phone_map")
        total_phone_contacts = cur.fetchone()[0]

        return jsonify({
            'total_assets': total_assets,
            'active_vendors': active_vendors,
            'open_pos': open_pos,
            'total_employees': total_employees,
            'total_phone_contacts': total_phone_contacts,
            'assets_by_status': assets_by_status,
            'recent_assets': recent_assets,
            'asset_distribution_by_type': asset_distribution,
            'maintenance_due': maintenance_due,
            'po_summary': po_summary
        })
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected():
            conn.close()


# ─── Asset Masters ─────────────────────────────────────────────────────────────

@app.route('/api/asset-types')
def get_asset_types():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT internal_id, type_name, description FROM asset_type_master ORDER BY type_name")
        return jsonify([{'internal_id': r[0], 'type_name': r[1], 'description': r[2]} for r in cur.fetchall()])
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/asset-subtypes')
def get_asset_subtypes():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        type_id = request.args.get('type_id')
        if type_id:
            cur.execute("""
                SELECT internal_id, subtype_name, description, thisobject2asset_type
                FROM asset_subtype_master WHERE thisobject2asset_type=%s ORDER BY subtype_name
            """, (type_id,))
        else:
            cur.execute("""
                SELECT internal_id, subtype_name, description, thisobject2asset_type
                FROM asset_subtype_master ORDER BY subtype_name
            """)
        return jsonify([{
            'internal_id': r[0], 'subtype_name': r[1],
            'description': r[2], 'thisobject2asset_type': r[3]
        } for r in cur.fetchall()])
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/asset-statuses')
def get_asset_statuses():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT internal_id, status_name FROM asset_status ORDER BY status_name")
        return jsonify([{'internal_id': r[0], 'status_name': r[1]} for r in cur.fetchall()])
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


# ─── Assets ────────────────────────────────────────────────────────────────────

@app.route('/api/assets', methods=['GET'])
def get_assets():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        search   = request.args.get('search', '')
        status_id = request.args.get('status_id')
        type_id  = request.args.get('type_id')

        sql = """
            SELECT a.internal_id, a.asset_tag, a.serial_no, a.make, a.asset_model,
                   a.purchase_cost, a.warranty_start, a.warranty_end,
                   sub.subtype_name, sub.internal_id AS subtype_id,
                   st.status_name, st.internal_id AS status_id,
                   t.type_name, t.internal_id AS type_id,
                   a.thisobject2subtype AS thisobject2assetsubtype, a.thisobject2status AS thisobject2assetstatus
            FROM asset a
            JOIN asset_subtype_master sub ON sub.internal_id = a.thisobject2subtype
            JOIN asset_status st          ON st.internal_id  = a.thisobject2status
            LEFT JOIN asset_type_master t ON t.internal_id   = sub.thisobject2asset_type
            WHERE 1=1
        """
        params = []
        if search:
            sql += " AND (a.asset_tag LIKE %s OR a.make LIKE %s OR a.asset_model LIKE %s OR a.serial_no LIKE %s)"
            params += [f'%{search}%'] * 4
        if status_id:
            sql += " AND a.thisobject2status=%s"
            params.append(status_id)
        if type_id:
            sql += " AND sub.thisobject2asset_type=%s"
            params.append(type_id)
        sql += " ORDER BY a.internal_id DESC"

        cur.execute(sql, params)
        result = []
        for r in cur.fetchall():
            result.append({
                'internal_id': r[0], 'asset_tag': r[1], 'serial_no': r[2],
                'make': r[3], 'asset_model': r[4],
                'purchase_cost': float(r[5]) if r[5] is not None else None,
                'warranty_start': r[6].isoformat() if r[6] else None,
                'warranty_end': r[7].isoformat() if r[7] else None,
                'asset_kind': None, 'subtype_name': r[8], 'subtype_id': r[9],
                'status_name': r[10], 'status_id': r[11],
                'type_name': r[12], 'type_id': r[13],
                'thisobject2assetsubtype': r[14], 'thisobject2assetstatus': r[15]
            })
        return jsonify(result)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/assets/<int:asset_id>', methods=['GET'])
def get_asset(asset_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            SELECT a.internal_id, a.asset_tag, a.serial_no, a.make, a.asset_model,
                   a.purchase_cost, a.warranty_start, a.warranty_end,
                   sub.subtype_name, sub.internal_id AS subtype_id,
                   st.status_name, st.internal_id AS status_id,
                   t.type_name, t.internal_id AS type_id,
                   a.thisobject2subtype AS thisobject2assetsubtype, a.thisobject2status AS thisobject2assetstatus
            FROM asset a
            JOIN asset_subtype_master sub ON sub.internal_id = a.thisobject2subtype
            JOIN asset_status st          ON st.internal_id  = a.thisobject2status
            LEFT JOIN asset_type_master t ON t.internal_id   = sub.thisobject2asset_type
            WHERE a.internal_id=%s
        """, (asset_id,))
        row = cur.fetchone()
        if not row:
            return jsonify({'error': 'Asset not found'}), 404

        asset = {
            'internal_id': row[0], 'asset_tag': row[1], 'serial_no': row[2],
            'make': row[3], 'asset_model': row[4],
            'purchase_cost': float(row[5]) if row[5] is not None else None,
            'warranty_start': row[6].isoformat() if row[6] else None,
            'warranty_end': row[7].isoformat() if row[7] else None,
            'asset_kind': None, 'subtype_name': row[8], 'subtype_id': row[9],
            'status_name': row[10], 'status_id': row[11],
            'type_name': row[12], 'type_id': row[13],
            'thisobject2assetsubtype': row[14], 'thisobject2assetstatus': row[15]
        }

        cur.execute("""
            SELECT aa.internal_id, aa.allocation_type, aa.allocated_on,
                   aa.expected_return_date, aa.actual_return_date, aa.allocation_status,
                   i.first_name, i.last_name, i.email
            FROM asset_allocation aa
            LEFT JOIN individual i ON i.internal_id = aa.thisobject2individual
            WHERE aa.thisobject2asset=%s ORDER BY aa.allocated_on DESC
        """, (asset_id,))
        asset['allocations'] = []
        for r in cur.fetchall():
            asset['allocations'].append({
                'internal_id': r[0], 'allocation_type': r[1],
                'allocated_on': r[2].isoformat() if r[2] else None,
                'expected_return_date': r[3].isoformat() if r[3] else None,
                'actual_return_date': r[4].isoformat() if r[4] else None,
                'allocation_status': r[5],
                'employee_name': f"{r[6]} {r[7]}" if r[6] else None, 'email': r[8]
            })

        cur.execute("""
            SELECT internal_id, maintenance_date AS opened_on, description AS notes, cost, status
            FROM maintenance_record WHERE thisobject2asset=%s ORDER BY maintenance_date DESC
        """, (asset_id,))
        asset['maintenance'] = []
        for r in cur.fetchall():
            asset['maintenance'].append({
                'internal_id': r[0],
                'opened_on': r[1].isoformat() if r[1] else None,
                'closed_on': None,
                'notes': r[2], 'cost': float(r[3]) if r[3] else None, 'status': r[4]
            })

        return jsonify(asset)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/assets', methods=['POST'])
def create_asset():
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO asset (asset_tag, serial_no, make, asset_model, purchase_cost,
                               warranty_start, warranty_end,
                               thisobject2subtype, thisobject2status)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """, (
            data['asset_tag'], data.get('serial_no'), data.get('make'), data.get('asset_model'),
            data.get('purchase_cost') or None, data.get('warranty_start') or None,
            data.get('warranty_end') or None,
            data['thisobject2assetsubtype'], data['thisobject2assetstatus']
        ))
        conn.commit()
        return jsonify({'internal_id': cur.lastrowid, 'message': 'Asset created'}), 201
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/assets/<int:asset_id>', methods=['PUT'])
def update_asset(asset_id):
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            UPDATE asset SET asset_tag=%s, serial_no=%s, make=%s, asset_model=%s,
                purchase_cost=%s, warranty_start=%s, warranty_end=%s,
                thisobject2subtype=%s, thisobject2status=%s
            WHERE internal_id=%s
        """, (
            data['asset_tag'], data.get('serial_no'), data.get('make'), data.get('asset_model'),
            data.get('purchase_cost') or None, data.get('warranty_start') or None,
            data.get('warranty_end') or None,
            data['thisobject2assetsubtype'], data['thisobject2assetstatus'],
            asset_id
        ))
        conn.commit()
        if cur.rowcount == 0:
            return jsonify({'error': 'Asset not found'}), 404
        return jsonify({'message': 'Asset updated'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/assets/<int:asset_id>', methods=['DELETE'])
def delete_asset(asset_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("DELETE FROM asset_allocation   WHERE thisobject2asset=%s", (asset_id,))
        cur.execute("DELETE FROM maintenance_record WHERE thisobject2asset=%s", (asset_id,))
        cur.execute("DELETE FROM asset WHERE internal_id=%s", (asset_id,))
        conn.commit()
        if cur.rowcount == 0:
            return jsonify({'error': 'Asset not found'}), 404
        return jsonify({'message': 'Asset deleted'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


# ─── Asset Allocation ──────────────────────────────────────────────────────────

@app.route('/api/allocations', methods=['GET'])
def get_allocations():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        asset_id      = request.args.get('asset_id')
        individual_id = request.args.get('individual_id')

        sql = """
            SELECT aa.internal_id, aa.allocation_type, aa.allocated_on,
                   aa.expected_return_date, aa.actual_return_date, aa.allocation_status,
                   aa.thisobject2asset, aa.thisobject2individual,
                   a.asset_tag, a.make, a.asset_model,
                   i.first_name, i.last_name, i.email
            FROM asset_allocation aa
            JOIN asset a ON a.internal_id = aa.thisobject2asset
            LEFT JOIN individual i ON i.internal_id = aa.thisobject2individual
            WHERE 1=1
        """
        params = []
        if asset_id:
            sql += " AND aa.thisobject2asset=%s"; params.append(asset_id)
        if individual_id:
            sql += " AND aa.thisobject2individual=%s"; params.append(individual_id)
        sql += " ORDER BY aa.allocated_on DESC"

        cur.execute(sql, params)
        result = []
        for r in cur.fetchall():
            result.append({
                'internal_id': r[0], 'allocation_type': r[1],
                'allocated_on': r[2].isoformat() if r[2] else None,
                'expected_return_date': r[3].isoformat() if r[3] else None,
                'actual_return_date': r[4].isoformat() if r[4] else None,
                'allocation_status': r[5], 'asset_id': r[6], 'individual_id': r[7],
                'asset_tag': r[8], 'make': r[9], 'asset_model': r[10],
                'employee_name': f"{r[11]} {r[12]}" if r[11] else None, 'email': r[13]
            })
        return jsonify(result)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/allocations', methods=['POST'])
def create_allocation():
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO asset_allocation
                (thisobject2asset, thisobject2individual, allocation_type,
                 allocated_on, expected_return_date, allocation_status)
            VALUES (%s,%s,%s,%s,%s,%s)
        """, (
            data['thisobject2asset'], data.get('thisobject2individual'),
            data.get('allocation_type', 'ASSIGNED'),
            data.get('allocated_on') or date.today().isoformat(),
            data.get('expected_return_date') or None,
            data.get('allocation_status', 'ACTIVE')
        ))
        conn.commit()
        return jsonify({'internal_id': cur.lastrowid, 'message': 'Allocation created'}), 201
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/allocations/<int:alloc_id>', methods=['PUT'])
def update_allocation(alloc_id):
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            UPDATE asset_allocation
            SET allocation_status=%s, actual_return_date=%s, expected_return_date=%s
            WHERE internal_id=%s
        """, (data.get('allocation_status'), data.get('actual_return_date') or None,
              data.get('expected_return_date') or None, alloc_id))
        conn.commit()
        return jsonify({'message': 'Allocation updated'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


# ─── Maintenance ───────────────────────────────────────────────────────────────

@app.route('/api/maintenance', methods=['GET'])
def get_maintenance():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        asset_id = request.args.get('asset_id')
        sql = """
            SELECT m.internal_id, m.thisobject2asset, m.maintenance_date AS opened_on,
                   m.description AS notes, m.cost, m.status,
                   a.asset_tag, a.make, a.asset_model
            FROM maintenance_record m
            JOIN asset a ON a.internal_id = m.thisobject2asset
            WHERE 1=1
        """
        params = []
        if asset_id:
            sql += " AND m.thisobject2asset=%s"; params.append(asset_id)
        sql += " ORDER BY m.maintenance_date DESC"
        cur.execute(sql, params)
        result = []
        for r in cur.fetchall():
            result.append({
                'internal_id': r[0], 'asset_id': r[1],
                'opened_on': r[2].isoformat() if r[2] else None,
                'closed_on': None,
                'notes': r[3], 'cost': float(r[4]) if r[4] else None,
                'status': r[5], 'asset_tag': r[6], 'make': r[7], 'asset_model': r[8]
            })
        return jsonify(result)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/maintenance', methods=['POST'])
def create_maintenance():
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO maintenance_record (thisobject2asset, maintenance_date, description, cost, status)
            VALUES (%s,%s,%s,%s,%s)
        """, (
            data['thisobject2asset'], data.get('opened_on') or date.today().isoformat(),
            data.get('notes'), data.get('cost') or None,
            data.get('status', 'OPEN')
        ))
        conn.commit()
        return jsonify({'internal_id': cur.lastrowid, 'message': 'Maintenance record created'}), 201
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/maintenance/<int:maint_id>', methods=['PUT'])
def update_maintenance(maint_id):
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            UPDATE maintenance_record
            SET maintenance_date=%s, description=%s, cost=%s, status=%s
            WHERE internal_id=%s
        """, (
            data.get('opened_on') or None,
            data.get('notes'), data.get('cost') or None,
            data.get('status'), maint_id
        ))
        conn.commit()
        return jsonify({'message': 'Maintenance record updated'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


# ─── Vendors ───────────────────────────────────────────────────────────────────

@app.route('/api/vendors', methods=['GET'])
def get_vendors():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        search = request.args.get('search', '')
        sql = """
            SELECT v.internal_id, v.vendor_name, v.gst_no, v.vendor_email,
                   a.building_no, a.address_line1, a.area, a.zipcode, ci.city_name
            FROM vendor_master v
            LEFT JOIN (
                SELECT thisobject2vendor, MIN(thisobject2address) AS addr_id
                FROM vendor_address_map
                WHERE is_primary=1
                GROUP BY thisobject2vendor
            ) primary_addr ON primary_addr.thisobject2vendor = v.internal_id
            LEFT JOIN address a  ON a.internal_id  = primary_addr.addr_id
            LEFT JOIN city ci    ON ci.internal_id = a.thisobject2city
            WHERE 1=1
        """
        params = []
        if search:
            sql += " AND (v.vendor_name LIKE %s OR v.vendor_email LIKE %s OR v.gst_no LIKE %s)"
            params += [f'%{search}%'] * 3
        sql += " ORDER BY v.vendor_name"
        cur.execute(sql, params)
        result = []
        for r in cur.fetchall():
            parts = [p for p in [r[4], r[5], r[6], r[7], r[8]] if p]
            result.append({
                'internal_id': r[0], 'vendor_name': r[1], 'gst_no': r[2],
                'vendor_email': r[3], 'address': ', '.join(parts) if parts else None
            })
        return jsonify(result)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/vendors/<int:vendor_id>', methods=['GET'])
def get_vendor(vendor_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            SELECT v.internal_id, v.vendor_name, v.gst_no, v.vendor_email,
                   a.internal_id, a.building_no, a.address_line1, a.address_line2,
                   a.area, a.zipcode, a.address_type, ci.city_name
            FROM vendor_master v
            LEFT JOIN vendor_address_map vam ON vam.thisobject2vendor=v.internal_id
            LEFT JOIN address a ON a.internal_id = vam.thisobject2address
            LEFT JOIN city ci   ON ci.internal_id = a.thisobject2city
            WHERE v.internal_id=%s
        """, (vendor_id,))
        rows = cur.fetchall()
        if not rows:
            return jsonify({'error': 'Vendor not found'}), 404
        r = rows[0]
        vendor = {
            'internal_id': r[0], 'vendor_name': r[1], 'gst_no': r[2], 'vendor_email': r[3],
            'addresses': [{
                'addr_id': row[4], 'building_no': row[5], 'address_line1': row[6],
                'address_line2': row[7], 'area': row[8], 'zipcode': row[9],
                'address_type': row[10], 'city_name': row[11]
            } for row in rows if row[4]]
        }
        return jsonify(vendor)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/vendors', methods=['POST'])
def create_vendor():
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO vendor_master (vendor_name, gst_no, vendor_email)
            VALUES (%s,%s,%s)
        """, (data['vendor_name'], data.get('gst_no') or None, data.get('vendor_email') or None))
        conn.commit()
        return jsonify({'internal_id': cur.lastrowid, 'message': 'Vendor created'}), 201
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/vendors/<int:vendor_id>', methods=['PUT'])
def update_vendor(vendor_id):
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            UPDATE vendor_master SET vendor_name=%s, gst_no=%s, vendor_email=%s
            WHERE internal_id=%s
        """, (data['vendor_name'], data.get('gst_no') or None, data.get('vendor_email') or None, vendor_id))
        conn.commit()
        if cur.rowcount == 0:
            return jsonify({'error': 'Vendor not found'}), 404
        return jsonify({'message': 'Vendor updated'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/vendors/<int:vendor_id>', methods=['DELETE'])
def delete_vendor(vendor_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("DELETE FROM vendor_address_map WHERE thisobject2vendor=%s", (vendor_id,))
        cur.execute("DELETE FROM vendor_master WHERE internal_id=%s", (vendor_id,))
        conn.commit()
        if cur.rowcount == 0:
            return jsonify({'error': 'Vendor not found'}), 404
        return jsonify({'message': 'Vendor deleted'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


# ─── Departments & Companies ───────────────────────────────────────────────────

@app.route('/api/departments')
def get_departments():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            SELECT d.internal_id, d.dept_code, d.dept_name, d.thisobject2company, c.company_name
            FROM department d
            JOIN company c ON c.internal_id=d.thisobject2company
            ORDER BY d.dept_name
        """)
        return jsonify([{
            'internal_id': r[0], 'dept_code': r[1], 'dept_name': r[2],
            'thisobject2company': r[3], 'company_name': r[4]
        } for r in cur.fetchall()])
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/companies')
def get_companies():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT internal_id, company_name, gst_no, company_email FROM company ORDER BY company_name")
        return jsonify([{
            'internal_id': r[0], 'company_name': r[1], 'gst_no': r[2], 'company_email': r[3]
        } for r in cur.fetchall()])
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


# ─── Employees ─────────────────────────────────────────────────────────────────

@app.route('/api/employees', methods=['GET'])
def get_employees():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        search  = request.args.get('search', '')
        dept_id = request.args.get('dept_id')

        sql = """
            SELECT i.internal_id, i.first_name, i.last_name, i.email,
                   i.person_type, i.thisobject2company, c.company_name,
                   d.dept_name, d.internal_id AS dept_id, idm.status
            FROM individual i
            JOIN company c ON c.internal_id=i.thisobject2company
            LEFT JOIN individual_department_map idm
                ON idm.internal_id = (
                    SELECT MAX(idm2.internal_id)
                    FROM individual_department_map idm2
                    WHERE idm2.thisobject2individual = i.internal_id
                )
            LEFT JOIN department d ON d.internal_id=idm.thisobject2department
            WHERE i.person_type='EMPLOYEE'
        """
        params = []
        if search:
            sql += " AND (i.first_name LIKE %s OR i.last_name LIKE %s OR i.email LIKE %s)"
            params += [f'%{search}%'] * 3
        if dept_id:
            sql += " AND idm.thisobject2department=%s"; params.append(dept_id)
        sql += " ORDER BY i.first_name, i.last_name"

        cur.execute(sql, params)
        result = []
        for r in cur.fetchall():
            result.append({
                'internal_id': r[0], 'first_name': r[1], 'last_name': r[2],
                'email': r[3], 'person_type': r[4],
                'thisobject2company': r[5], 'company_name': r[6],
                'dept_name': r[7], 'dept_id': r[8], 'status': r[9]
            })
        return jsonify(result)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/employees/<int:emp_id>', methods=['GET'])
def get_employee(emp_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            SELECT i.internal_id, i.first_name, i.last_name, i.email,
                   i.person_type, i.thisobject2company, c.company_name, i.id_num
            FROM individual i
            JOIN company c ON c.internal_id=i.thisobject2company
            WHERE i.internal_id=%s
        """, (emp_id,))
        row = cur.fetchone()
        if not row:
            return jsonify({'error': 'Employee not found'}), 404
        emp = {
            'internal_id': row[0], 'first_name': row[1], 'last_name': row[2],
            'email': row[3], 'person_type': row[4],
            'thisobject2company': row[5], 'company_name': row[6], 'id_num': row[7]
        }
        cur.execute("""
            SELECT idm.internal_id, d.dept_name, d.internal_id AS dept_id,
                   idm.start_date, idm.end_date, idm.status
            FROM individual_department_map idm
            JOIN department d ON d.internal_id=idm.thisobject2department
            WHERE idm.thisobject2individual=%s ORDER BY idm.start_date DESC
        """, (emp_id,))
        emp['departments'] = [{
            'map_id': r[0], 'dept_name': r[1], 'dept_id': r[2],
            'start_date': r[3].isoformat() if r[3] else None,
            'end_date': r[4].isoformat() if r[4] else None,
            'status': r[5]
        } for r in cur.fetchall()]
        return jsonify(emp)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/employees', methods=['POST'])
def create_employee():
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO individual (first_name, last_name, email, person_type, thisobject2company, id_num)
            VALUES (%s,%s,%s,'EMPLOYEE',%s,%s)
        """, (
            data['first_name'], data.get('last_name'), data.get('email'),
            data['thisobject2company'], data.get('id_num') or None
        ))
        emp_id = cur.lastrowid
        if data.get('thisobject2department'):
            cur.execute("""
                INSERT INTO individual_department_map
                    (thisobject2individual, thisobject2department, start_date, status)
                VALUES (%s,%s,%s,'ACTIVE')
            """, (emp_id, data['thisobject2department'], date.today().isoformat()))
        conn.commit()
        return jsonify({'internal_id': emp_id, 'message': 'Employee created'}), 201
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/employees/<int:emp_id>', methods=['PUT'])
def update_employee(emp_id):
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            UPDATE individual SET first_name=%s, last_name=%s, email=%s,
                thisobject2company=%s, id_num=%s
            WHERE internal_id=%s
        """, (
            data['first_name'], data.get('last_name'), data.get('email'),
            data['thisobject2company'], data.get('id_num') or None, emp_id
        ))
        conn.commit()
        if cur.rowcount == 0:
            return jsonify({'error': 'Employee not found'}), 404
        return jsonify({'message': 'Employee updated'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/employees/<int:emp_id>', methods=['DELETE'])
def delete_employee(emp_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("DELETE FROM individual_department_map WHERE thisobject2individual=%s", (emp_id,))
        cur.execute("DELETE FROM asset_allocation WHERE thisobject2individual=%s", (emp_id,))
        cur.execute("DELETE FROM individual WHERE internal_id=%s", (emp_id,))
        conn.commit()
        if cur.rowcount == 0:
            return jsonify({'error': 'Employee not found'}), 404
        return jsonify({'message': 'Employee deleted'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


# ─── Employee Phone Numbers ────────────────────────────────────────────────────

@app.route('/api/employees/<int:emp_id>/phones', methods=['GET'])
def get_employee_phones(emp_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            SELECT p.internal_id, p.country_dial_code, p.phone_number, p.phone_type,
                   m.is_primary, m.internal_id AS map_id
            FROM phone_number p
            JOIN individual_phone_map m ON m.thisobject2phone = p.internal_id
            WHERE m.thisobject2individual = %s
            ORDER BY m.is_primary DESC, p.internal_id
        """, (emp_id,))
        return jsonify([{
            'internal_id': r[0], 'country_dial_code': r[1],
            'phone_number': r[2], 'phone_type': r[3],
            'is_primary': bool(r[4]), 'map_id': r[5]
        } for r in cur.fetchall()])
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/employees/<int:emp_id>/phones', methods=['POST'])
def add_employee_phone(emp_id):
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO phone_number (country_dial_code, phone_number, phone_type)
            VALUES (%s, %s, %s)
        """, (data.get('country_dial_code', '+91'), data['phone_number'], data.get('phone_type', 'Mobile')))
        phone_id = cur.lastrowid
        cur.execute("""
            INSERT INTO individual_phone_map (thisobject2individual, thisobject2phone, is_primary)
            VALUES (%s, %s, %s)
        """, (emp_id, phone_id, bool(data.get('is_primary', False))))
        conn.commit()
        return jsonify({'internal_id': phone_id, 'message': 'Phone added'}), 201
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/employees/<int:emp_id>/phones/<int:phone_id>', methods=['DELETE'])
def delete_employee_phone(emp_id, phone_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("DELETE FROM individual_phone_map WHERE thisobject2individual=%s AND thisobject2phone=%s",
                    (emp_id, phone_id))
        cur.execute("DELETE FROM phone_number WHERE internal_id=%s", (phone_id,))
        conn.commit()
        return jsonify({'message': 'Phone deleted'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


# ─── Purchase Orders ───────────────────────────────────────────────────────────

@app.route('/api/purchase-orders', methods=['GET'])
def get_purchase_orders():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        status    = request.args.get('status')
        vendor_id = request.args.get('vendor_id')

        sql = """
            SELECT poh.internal_id, poh.po_number, poh.po_date, poh.status,
                   poh.total_amount, poh.thisobject2vendor, v.vendor_name
            FROM purchase_order_header poh
            JOIN vendor_master v ON v.internal_id=poh.thisobject2vendor
            WHERE 1=1
        """
        params = []
        if status:
            sql += " AND poh.status=%s"; params.append(status)
        if vendor_id:
            sql += " AND poh.thisobject2vendor=%s"; params.append(vendor_id)
        sql += " ORDER BY poh.internal_id DESC"

        cur.execute(sql, params)
        result = []
        for r in cur.fetchall():
            result.append({
                'internal_id': r[0], 'po_number': r[1],
                'po_date': r[2].isoformat() if r[2] else None,
                'status': r[3],
                'total_amount': float(r[4]) if r[4] is not None else None,
                'vendor_id': r[5], 'vendor_name': r[6]
            })
        return jsonify(result)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/purchase-orders/<int:po_id>', methods=['GET'])
def get_purchase_order(po_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            SELECT poh.internal_id, poh.po_number, poh.po_date, poh.status,
                   poh.total_amount, poh.thisobject2vendor, v.vendor_name, v.vendor_email
            FROM purchase_order_header poh
            JOIN vendor_master v ON v.internal_id=poh.thisobject2vendor
            WHERE poh.internal_id=%s
        """, (po_id,))
        row = cur.fetchone()
        if not row:
            return jsonify({'error': 'PO not found'}), 404
        po = {
            'internal_id': row[0], 'po_number': row[1],
            'po_date': row[2].isoformat() if row[2] else None,
            'status': row[3],
            'total_amount': float(row[4]) if row[4] is not None else None,
            'vendor_id': row[5], 'vendor_name': row[6], 'vendor_email': row[7]
        }
        cur.execute("""
            SELECT internal_id, item_description, quantity, unit_price,
                   gst_amount, total_price
            FROM purchase_order_detail WHERE thisobject2po=%s ORDER BY internal_id
        """, (po_id,))
        po['details'] = [{
            'internal_id': r[0], 'item_description': r[1], 'quantity': r[2],
            'unit_price': float(r[3]) if r[3] else None,
            'gst_amount': float(r[4]) if r[4] else None,
            'total_price': float(r[5]) if r[5] else None,
            'gst_percent': None
        } for r in cur.fetchall()]
        return jsonify(po)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/purchase-orders', methods=['POST'])
def create_purchase_order():
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        details = data.get('details', [])
        total = sum(
            (float(d.get('quantity', 0)) * float(d.get('unit_price', 0))) + float(d.get('gst_amount', 0))
            for d in details
        ) or (data.get('total_amount') or 0)

        cur.execute("""
            INSERT INTO purchase_order_header (po_number, po_date, status, thisobject2vendor, total_amount)
            VALUES (%s,%s,%s,%s,%s)
        """, (
            data['po_number'], data.get('po_date') or date.today().isoformat(),
            data.get('status', 'PENDING'), data['thisobject2vendor'], total
        ))
        po_id = cur.lastrowid

        for d in details:
            qty = float(d.get('quantity', 0))
            up  = float(d.get('unit_price', 0))
            gst = float(d.get('gst_amount', 0))
            tp  = (qty * up) + gst
            cur.execute("""
                INSERT INTO purchase_order_detail
                    (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
                VALUES (%s,%s,%s,%s,%s,%s)
            """, (po_id, d.get('item_description'), qty, up, gst, tp))

        conn.commit()
        return jsonify({'internal_id': po_id, 'message': 'PO created'}), 201
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/purchase-orders/<int:po_id>', methods=['PUT'])
def update_purchase_order(po_id):
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            UPDATE purchase_order_header
            SET status=%s, thisobject2vendor=%s, po_date=%s
            WHERE internal_id=%s
        """, (data.get('status'), data.get('thisobject2vendor'), data.get('po_date') or None, po_id))
        conn.commit()
        if cur.rowcount == 0:
            return jsonify({'error': 'PO not found'}), 404
        return jsonify({'message': 'PO updated'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/purchase-orders/<int:po_id>', methods=['DELETE'])
def delete_purchase_order(po_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT internal_id FROM goods_receipt_header WHERE thisobject2po=%s", (po_id,))
        grn_ids = [r[0] for r in cur.fetchall()]
        if grn_ids:
            fmt = ','.join(['%s'] * len(grn_ids))
            cur.execute(f"DELETE FROM goods_receipt_detail WHERE thisobject2grn IN ({fmt})", grn_ids)
            cur.execute("DELETE FROM goods_receipt_header WHERE thisobject2po=%s", (po_id,))
        cur.execute("DELETE FROM purchase_order_detail WHERE thisobject2po=%s", (po_id,))
        cur.execute("DELETE FROM purchase_order_header WHERE internal_id=%s", (po_id,))
        conn.commit()
        return jsonify({'message': 'PO deleted'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/purchase-orders/<int:po_id>/details', methods=['POST'])
def add_po_detail(po_id):
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        qty = float(data.get('quantity', 0))
        up  = float(data.get('unit_price', 0))
        gst = float(data.get('gst_amount', 0))
        tp  = (qty * up) + gst
        cur.execute("""
            INSERT INTO purchase_order_detail
                (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
            VALUES (%s,%s,%s,%s,%s,%s)
        """, (po_id, data.get('item_description'), qty, up, gst, tp))
        conn.commit()
        return jsonify({'internal_id': cur.lastrowid, 'message': 'Line item added'}), 201
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/purchase-orders/<int:po_id>/details/<int:detail_id>', methods=['DELETE'])
def delete_po_detail(po_id, detail_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("DELETE FROM goods_receipt_detail WHERE thisobject2podetail=%s", (detail_id,))
        cur.execute("DELETE FROM purchase_order_detail WHERE internal_id=%s AND thisobject2po=%s",
                    (detail_id, po_id))
        conn.commit()
        return jsonify({'message': 'Line item deleted'})
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


# ─── Goods Receipts ────────────────────────────────────────────────────────────

@app.route('/api/goods-receipts', methods=['GET'])
def get_goods_receipts():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        po_id = request.args.get('po_id')
        sql = """
            SELECT grh.internal_id, grh.grn_date, grh.thisobject2po,
                   poh.po_number, v.vendor_name
            FROM goods_receipt_header grh
            JOIN purchase_order_header poh ON poh.internal_id=grh.thisobject2po
            JOIN vendor_master v ON v.internal_id=poh.thisobject2vendor
            WHERE 1=1
        """
        params = []
        if po_id:
            sql += " AND grh.thisobject2po=%s"; params.append(po_id)
        sql += " ORDER BY grh.internal_id DESC"
        cur.execute(sql, params)
        result = []
        for r in cur.fetchall():
            result.append({
                'internal_id': r[0],
                'grn_date': r[1].isoformat() if r[1] else None,
                'po_id': r[2], 'po_number': r[3], 'vendor_name': r[4]
            })
        return jsonify(result)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/goods-receipts', methods=['POST'])
def create_goods_receipt():
    conn = None
    try:
        data = request.get_json()
        conn = get_db()
        cur = conn.cursor()
        po_id = data['thisobject2po']

        cur.execute("""
            INSERT INTO goods_receipt_header (grn_date, thisobject2po)
            VALUES (%s,%s)
        """, (data.get('grn_date') or data.get('received_date') or date.today().isoformat(), po_id))
        grn_id = cur.lastrowid

        for d in data.get('details', []):
            cur.execute("""
                INSERT INTO goods_receipt_detail (thisobject2grn, thisobject2podetail, qty_received)
                VALUES (%s,%s,%s)
            """, (grn_id, d['thisobject2podetail'], d.get('qty_received', 0)))

        # Auto-update PO to FULLY_RECEIVED if all quantities covered
        cur.execute("""
            SELECT pod.quantity, COALESCE(SUM(grd.qty_received), 0)
            FROM purchase_order_detail pod
            LEFT JOIN goods_receipt_detail grd ON grd.thisobject2podetail=pod.internal_id
            WHERE pod.thisobject2po=%s
            GROUP BY pod.internal_id, pod.quantity
        """, (po_id,))
        rows = cur.fetchall()
        all_received = bool(rows) and all(float(r[1]) >= float(r[0]) for r in rows)
        if all_received:
            cur.execute("UPDATE purchase_order_header SET status='FULLY_RECEIVED' WHERE internal_id=%s", (po_id,))

        conn.commit()
        return jsonify({
            'internal_id': grn_id, 'message': 'Goods receipt created',
            'po_fully_received': all_received
        }), 201
    except Error as e:
        if conn: conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


# ─── Products ──────────────────────────────────────────────────────────────────

@app.route('/api/products')
def get_products():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            SELECT internal_id, product_name, manufacturer, model, category,
                   is_active, description, warranty_months
            FROM product_master WHERE is_active=1 ORDER BY product_name
        """)
        return jsonify([{
            'internal_id': r[0], 'product_name': r[1], 'manufacturer': r[2],
            'model': r[3], 'category': r[4], 'is_active': bool(r[5]),
            'description': r[6], 'warranty_months': r[7]
        } for r in cur.fetchall()])
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


@app.route('/api/products/<int:prod_id>')
def get_product(prod_id):
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            SELECT internal_id, product_name, manufacturer, model, category,
                   is_active, description, warranty_months
            FROM product_master WHERE internal_id=%s
        """, (prod_id,))
        row = cur.fetchone()
        if not row:
            return jsonify({'error': 'Product not found'}), 404
        prod = {
            'internal_id': row[0], 'product_name': row[1], 'manufacturer': row[2],
            'model': row[3], 'category': row[4], 'is_active': bool(row[5]),
            'description': row[6], 'warranty_months': row[7]
        }
        cur.execute("""
            SELECT spec_key, spec_value FROM product_specification
            WHERE thisobject2product=%s ORDER BY spec_key
        """, (prod_id,))
        prod['specifications'] = [{'key': r[0], 'value': r[1]} for r in cur.fetchall()]
        return jsonify(prod)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn and conn.is_connected(): conn.close()


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)
