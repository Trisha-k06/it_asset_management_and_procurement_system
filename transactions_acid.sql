USE it_asset_mgmt_db;

-- ============================================================
-- TRANSACTION 1: Create a New Purchase Order
-- PO Header + Multiple PO Detail rows
-- ============================================================

BEGIN;

  SAVEPOINT sp_po_header;

  INSERT INTO purchase_order_header (po_number, po_date, status, thisobject2vendor)
  VALUES ('PO-2024-0042', CURDATE(), 'PENDING', 3);

  -- Capture the generated PO ID for use in detail rows
  SET @po_id = LAST_INSERT_ID();

  SAVEPOINT sp_po_details;

  INSERT INTO purchase_order_detail
    (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
  VALUES
    (@po_id, 'Dell Latitude 5540 Laptop',   10, 75000.00, 13500.00,  763500.00),
    (@po_id, 'USB-C Docking Station',        10,  8500.00,  1530.00,   86530.00),
    (@po_id, 'Logitech MX Keys Keyboard',    20,  4200.00,   756.00,   85356.00);

  -- Verify line totals are consistent (optional guard)
  -- If any INSERT above fails, MySQL rolls the entire transaction back
  -- automatically on connection loss; we can also ROLLBACK explicitly.

COMMIT;

-- ---- ROLLBACK SCENARIO ----
-- If po_number 'PO-2024-0042' already exists (UNIQUE violation on INSERT header):
--   MySQL raises error → application catches it → ROLLBACK;
--   Neither the header nor the detail rows are persisted.
--
-- If detail INSERT fails (e.g. bad @po_id):
--   ROLLBACK TO sp_po_details; -- undo details only
--   ROLLBACK;                  -- or abort the whole transaction


-- ============================================================
-- TRANSACTION 2: Receive Goods
-- GRN Header + GRN Details + Update PO status + Register Assets
-- ============================================================

BEGIN;

  SAVEPOINT sp_grn_header;

  INSERT INTO goods_receipt_header (grn_date, thisobject2po)
  VALUES (CURDATE(), 1);          -- PO internal_id = 1

  SET @grn_id = LAST_INSERT_ID();

  SAVEPOINT sp_grn_details;

  -- Record quantities received against each PO detail line
  INSERT INTO goods_receipt_detail (thisobject2grn, thisobject2podetail, qty_received)
  VALUES
    (@grn_id, 1, 10),   -- PO detail line 1: 10 laptops received
    (@grn_id, 2, 10),   -- PO detail line 2: 10 docking stations
    (@grn_id, 3, 20);   -- PO detail line 3: 20 keyboards

  SAVEPOINT sp_update_po_status;

  UPDATE purchase_order_header
  SET    status = 'FULLY_RECEIVED'
  WHERE  internal_id = 1;

  SAVEPOINT sp_register_assets;

  -- Register each received asset unit (example: first laptop)
  -- In practice this loops per received unit; shown for one unit here
  INSERT INTO asset
    (asset_tag, serial_no, make, asset_model, purchase_cost,
     warranty_start, warranty_end, thisobject2subtype, thisobject2status)
  VALUES
    ('ASSET-LAP-001', 'DLLSN00001', 'Dell', 'Latitude 5540', 75000.00,
     CURDATE(), DATE_ADD(CURDATE(), INTERVAL 3 YEAR), 2, 1),
    ('ASSET-LAP-002', 'DLLSN00002', 'Dell', 'Latitude 5540', 75000.00,
     CURDATE(), DATE_ADD(CURDATE(), INTERVAL 3 YEAR), 2, 1);

COMMIT;

-- ---- ROLLBACK SCENARIO ----
-- If GRN detail INSERT fails (invalid thisobject2podetail FK):
--   ROLLBACK TO sp_grn_details; -- undo GRN details, keep header
--   ROLLBACK;                   -- or abort everything
--
-- If asset registration fails:
--   ROLLBACK TO sp_register_assets; -- keep GRN, undo asset rows only
--   ROLLBACK;                       -- or full abort


-- ============================================================
-- TRANSACTION 3: Add a New Asset and Assign It to an Employee
-- ============================================================

BEGIN;

  SAVEPOINT sp_new_asset;

  INSERT INTO asset
    (asset_tag, serial_no, make, asset_model, purchase_cost,
     warranty_start, warranty_end, thisobject2subtype, thisobject2status)
  VALUES
    ('ASSET-MON-010', 'LGSN20240010', 'LG', 'UltraWide 34WQ75', 32000.00,
     CURDATE(), DATE_ADD(CURDATE(), INTERVAL 2 YEAR), 4, 1);

  SET @new_asset_id = LAST_INSERT_ID();

  SAVEPOINT sp_allocate_asset;

  INSERT INTO asset_allocation
    (thisobject2asset, thisobject2individual, allocation_type,
     allocated_on, expected_return_date, allocation_status)
  VALUES
    (@new_asset_id, 7, 'PERMANENT',
     CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 'ACTIVE');

COMMIT;

-- ---- ROLLBACK SCENARIO ----
-- If the individual (id=7) does not exist (FK violation on asset_allocation):
--   MySQL raises error → ROLLBACK;
--   The asset row is also removed — no orphan asset left unallocated.


-- ============================================================
-- TRANSACTION 4: Update Vendor Contact Details
-- vendor_master (email) + address via vendor_address_map
-- NOTE: vendor_phone_map is not in the current DDL; if added, include
--       a similar UPDATE block after sp_vendor_address.
-- ============================================================

BEGIN;

  SAVEPOINT sp_vendor_email;

  UPDATE vendor_master
  SET    vendor_email = 'procurement@techsupplies.in'
  WHERE  internal_id = 3;

  -- Guard: ensure the vendor actually exists
  IF ROW_COUNT() = 0 THEN
    ROLLBACK;
    -- Application raises: "Vendor not found"
  END IF;

  SAVEPOINT sp_vendor_address;

  -- Update the primary address linked to this vendor
  UPDATE address a
    JOIN vendor_address_map vam ON vam.thisobject2address = a.internal_id
  SET
    a.building_no    = '12B',
    a.address_line1  = 'Tech Park, Outer Ring Road',
    a.area           = 'Marathahalli',
    a.zipcode        = '560037'
  WHERE vam.thisobject2vendor = 3
    AND vam.is_primary        = TRUE;

COMMIT;

-- ---- ROLLBACK SCENARIO ----
-- If vendor internal_id = 3 doesn't exist → ROW_COUNT() = 0 → ROLLBACK.
-- If address UPDATE hits a FK violation → MySQL error → ROLLBACK;
--   Email change is also undone (atomicity).


-- ============================================================
-- TRANSACTION 5: Deactivate a Product
-- Check no open POs reference this product, then set is_active = FALSE
-- ============================================================

BEGIN;

  -- Step 1: Count open POs that reference this product by name/model
  -- (Schema has no direct FK from purchase_order_detail to product_master;
  --  the check uses item_description pattern matching as a proxy.
  --  In a stricter schema, add thisobject2product FK to purchase_order_detail.)

  SELECT COUNT(*) INTO @open_po_count
  FROM   purchase_order_detail pod
    JOIN purchase_order_header poh ON poh.internal_id = pod.thisobject2po
    JOIN product_master pm         ON pod.item_description LIKE CONCAT('%', pm.model, '%')
  WHERE  pm.internal_id = 5
    AND  poh.status NOT IN ('FULLY_RECEIVED', 'CANCELLED');

  SAVEPOINT sp_open_po_check;

  -- Step 2: Abort if open POs exist
  -- (MySQL stored-procedure style; in app code use conditional ROLLBACK)
  IF @open_po_count > 0 THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cannot deactivate product: open purchase orders exist.';
  END IF;

  SAVEPOINT sp_deactivate_product;

  UPDATE product_master
  SET    is_active = FALSE
  WHERE  internal_id = 5;

COMMIT;

-- ---- ROLLBACK SCENARIO ----
-- If @open_po_count > 0 → ROLLBACK issued before any UPDATE.
-- If UPDATE fails (e.g. internal_id 5 not found) → ROW_COUNT() = 0
--   → application can check and ROLLBACK explicitly.
-- In either case, product remains active; no partial state is saved.
