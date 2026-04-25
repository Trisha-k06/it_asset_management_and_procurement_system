-- =============================================================
-- seed_data.sql  — IT Asset Management System
-- Run AFTER all 01_tables_*.sql, 06_constraints_fk.sql,
-- 07_insert_data.sql, and 08_migrate_to_final.sql
-- Uses INSERT IGNORE to avoid duplicating existing rows.
-- =============================================================

USE it_asset_mgmt_db;
SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS = 0;

-- ─────────────────────────────────────────────────────────────
-- 1. company_address_map
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO company_address_map (thisobject2company, thisobject2address, is_primary)
VALUES (
  (SELECT internal_id FROM company WHERE company_name='TechNova'  LIMIT 1),
  (SELECT internal_id FROM address WHERE building_no='1A'         LIMIT 1),
  1
),
(
  (SELECT internal_id FROM company WHERE company_name='InnoCore'  LIMIT 1),
  (SELECT internal_id FROM address WHERE building_no='2B'         LIMIT 1),
  1
),
(
  (SELECT internal_id FROM company WHERE company_name='AlphaSys'  LIMIT 1),
  (SELECT internal_id FROM address WHERE building_no='3C'         LIMIT 1),
  1
);

-- ─────────────────────────────────────────────────────────────
-- 2. Sites
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO site (site_name, site_type, thisobject2company)
VALUES
('Chennai HQ',    'Headquarters', (SELECT internal_id FROM company WHERE company_name='TechNova' LIMIT 1)),
('Bangalore Dev', 'Development',  (SELECT internal_id FROM company WHERE company_name='TechNova' LIMIT 1)),
('Mumbai Sales',  'Sales',        (SELECT internal_id FROM company WHERE company_name='TechNova' LIMIT 1)),
('Delhi Support', 'Support',      (SELECT internal_id FROM company WHERE company_name='InnoCore' LIMIT 1)),
('Hyderabad DC',  'Data Center',  (SELECT internal_id FROM company WHERE company_name='AlphaSys' LIMIT 1));

-- ─────────────────────────────────────────────────────────────
-- 3. Departments
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO department (dept_code, dept_name, thisobject2company)
VALUES
('IT-OPS',  'IT Operations',       (SELECT internal_id FROM company WHERE company_name='TechNova' LIMIT 1)),
('IT-SEC',  'IT Security',         (SELECT internal_id FROM company WHERE company_name='TechNova' LIMIT 1)),
('FIN',     'Finance',             (SELECT internal_id FROM company WHERE company_name='TechNova' LIMIT 1)),
('HR',      'Human Resources',     (SELECT internal_id FROM company WHERE company_name='TechNova' LIMIT 1)),
('SALES',   'Sales & Marketing',   (SELECT internal_id FROM company WHERE company_name='TechNova' LIMIT 1)),
('DEVOPS',  'DevOps & Cloud',      (SELECT internal_id FROM company WHERE company_name='InnoCore' LIMIT 1)),
('QA',      'Quality Assurance',   (SELECT internal_id FROM company WHERE company_name='AlphaSys' LIMIT 1));

-- ─────────────────────────────────────────────────────────────
-- 4. individual_department_map
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO individual_department_map
    (thisobject2individual, thisobject2department, start_date, status)
VALUES
((SELECT internal_id FROM individual WHERE email='u1@mail.com'  LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='IT-OPS'   LIMIT 1), '2023-01-10', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u2@mail.com'  LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='IT-SEC'   LIMIT 1), '2023-02-15', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u3@mail.com'  LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='FIN'      LIMIT 1), '2023-03-01', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u4@mail.com'  LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='HR'       LIMIT 1), '2023-03-20', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u5@mail.com'  LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='SALES'    LIMIT 1), '2023-04-05', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u6@mail.com'  LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='DEVOPS'   LIMIT 1), '2023-04-10', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u7@mail.com'  LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='QA'       LIMIT 1), '2023-05-01', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u8@mail.com'  LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='IT-OPS'   LIMIT 1), '2023-05-15', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u9@mail.com'  LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='IT-SEC'   LIMIT 1), '2023-06-01', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u10@mail.com' LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='FIN'      LIMIT 1), '2023-06-20', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u11@mail.com' LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='SALES'    LIMIT 1), '2023-07-01', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u12@mail.com' LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='DEVOPS'   LIMIT 1), '2023-07-15', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u13@mail.com' LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='QA'       LIMIT 1), '2023-08-01', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u14@mail.com' LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='HR'       LIMIT 1), '2023-08-20', 'ACTIVE'),
((SELECT internal_id FROM individual WHERE email='u15@mail.com' LIMIT 1),
 (SELECT internal_id FROM department WHERE dept_code='IT-OPS'   LIMIT 1), '2023-09-01', 'ACTIVE');

-- ─────────────────────────────────────────────────────────────
-- 5. Asset type master  (IT Equipment already exists from 07_insert_data; add 5 more)
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO asset_type_master (type_name, description) VALUES
('Computing',  'Laptops, desktops, and workstations'),
('Peripheral', 'Monitors, printers, scanners, input devices'),
('Network',    'Routers, switches, access points'),
('Mobile',     'Smartphones and tablets'),
('Server',     'Physical and rack servers');

-- ─────────────────────────────────────────────────────────────
-- 6. Asset subtype master  (Laptop already exists under IT Equipment; add new ones)
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO asset_subtype_master (subtype_name, description, thisobject2asset_type) VALUES
('Workstation', 'Desktop workstation computer',
  (SELECT internal_id FROM asset_type_master WHERE type_name='Computing'  LIMIT 1)),
('Laptop-Pro',  'Enterprise-grade portable laptop',
  (SELECT internal_id FROM asset_type_master WHERE type_name='Computing'  LIMIT 1)),
('Monitor',     'Display monitor',
  (SELECT internal_id FROM asset_type_master WHERE type_name='Peripheral' LIMIT 1)),
('Printer',     'Laser or inkjet printer',
  (SELECT internal_id FROM asset_type_master WHERE type_name='Peripheral' LIMIT 1)),
('Router',      'Network router',
  (SELECT internal_id FROM asset_type_master WHERE type_name='Network'    LIMIT 1)),
('Switch',      'Network switch',
  (SELECT internal_id FROM asset_type_master WHERE type_name='Network'    LIMIT 1)),
('Tablet',      'iPad or Android tablet',
  (SELECT internal_id FROM asset_type_master WHERE type_name='Mobile'     LIMIT 1)),
('Smartphone',  'Mobile phone',
  (SELECT internal_id FROM asset_type_master WHERE type_name='Mobile'     LIMIT 1)),
('Rack Server', 'Physical rack-mounted server',
  (SELECT internal_id FROM asset_type_master WHERE type_name='Server'     LIMIT 1));

-- ─────────────────────────────────────────────────────────────
-- 7. Asset status master
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO asset_status (status_name) VALUES
('Active'),
('In Repair'),
('Reserved'),
('Retired'),
('Disposed');

-- ─────────────────────────────────────────────────────────────
-- 8. Product master  (only columns that exist: product_name, manufacturer, model, category, is_active)
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO product_master (product_name, manufacturer, model, category, is_active)
VALUES
('ThinkPad X1 Carbon', 'Lenovo',  'X1C-Gen11',  'Laptop',  1),
('EliteBook 840 G10',  'HP',      '840-G10',     'Laptop',  1),
('Dell XPS 15',        'Dell',    'XPS-9530',    'Laptop',  1),
('UltraSharp 27"',     'Dell',    'U2723DE',     'Monitor', 1),
('Catalyst 9300',      'Cisco',   'C9300-48P',   'Network', 1),
('ProLiant DL380',     'HP',      'DL380-Gen10', 'Server',  1),
('iPhone 15 Pro',      'Apple',   'A3101',       'Mobile',  1),
('Galaxy Tab S9',      'Samsung', 'SM-X710',     'Mobile',  1);

-- ─────────────────────────────────────────────────────────────
-- 9. Assets (20 assets) — correct column names: thisobject2subtype, thisobject2status
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO asset
    (asset_tag, serial_no, make, asset_model, purchase_cost,
     warranty_start, warranty_end, thisobject2subtype, thisobject2status)
VALUES
-- Computing / Laptop-Pro (6 assets)
('ASSET-LAP-001','SN-LAP-A001','Lenovo','ThinkPad X1 Carbon Gen11', 95000.00,'2023-01-15','2026-01-15',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Laptop-Pro' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'              LIMIT 1)),
('ASSET-LAP-002','SN-LAP-A002','HP',    'EliteBook 840 G10',         88000.00,'2023-02-10','2026-02-10',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Laptop-Pro' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'              LIMIT 1)),
('ASSET-LAP-003','SN-LAP-A003','Dell',  'XPS 15 9530',               110000.00,'2023-03-05','2025-03-05',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Laptop-Pro' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='In Repair'           LIMIT 1)),
('ASSET-LAP-004','SN-LAP-A004','Apple', 'MacBook Pro 14 M3',         145000.00,'2023-04-01','2026-04-01',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Laptop-Pro' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'              LIMIT 1)),
('ASSET-LAP-005','SN-LAP-A005','Lenovo','ThinkPad T14 Gen3',          72000.00,'2022-06-20','2025-06-20',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Laptop-Pro' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'              LIMIT 1)),
('ASSET-LAP-006','SN-LAP-A006','HP',    'Pavilion 15',                45000.00,'2021-01-10','2024-01-10',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Laptop-Pro' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Retired'             LIMIT 1)),

-- Computing / Workstation (3 assets)
('ASSET-DSK-001','SN-DSK-B001','Dell',  'OptiPlex 7090',              58000.00,'2023-01-20','2026-01-20',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Workstation' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'               LIMIT 1)),
('ASSET-DSK-002','SN-DSK-B002','HP',    'EliteDesk 800 G6',           54000.00,'2022-07-15','2025-07-15',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Workstation' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Reserved'             LIMIT 1)),
('ASSET-DSK-003','SN-DSK-B003','Lenovo','ThinkCentre M90q',           49000.00,'2023-08-01','2026-08-01',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Workstation' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'               LIMIT 1)),

-- Peripheral / Monitor (3 assets)
('ASSET-MON-001','SN-MON-C001','Dell',   'UltraSharp U2723DE',         35000.00,'2023-02-28','2026-02-28',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Monitor'     LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'               LIMIT 1)),
('ASSET-MON-002','SN-MON-C002','Samsung','Odyssey G7 32"',             42000.00,'2023-03-15','2026-03-15',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Monitor'     LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'               LIMIT 1)),
('ASSET-MON-003','SN-MON-C003','LG',     '27UK850-W 4K',               28000.00,'2021-05-10','2024-05-10',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Monitor'     LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Disposed'             LIMIT 1)),

-- Network (3 assets)
('ASSET-NET-001','SN-NET-D001','Cisco',  'Catalyst 9300-48P',         120000.00,'2023-06-01','2028-06-01',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Switch'      LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'               LIMIT 1)),
('ASSET-NET-002','SN-NET-D002','Cisco',  'ISR 4351 Router',            85000.00,'2022-09-15','2027-09-15',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Router'      LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'               LIMIT 1)),
('ASSET-NET-003','SN-NET-D003','TP-Link','TL-SG3428',                  12000.00,'2023-01-05','2026-01-05',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Switch'      LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='In Repair'            LIMIT 1)),

-- Mobile (3 assets)
('ASSET-MOB-001','SN-MOB-E001','Apple',  'iPhone 15 Pro',              89000.00,'2023-09-25','2024-09-25',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Smartphone'  LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'               LIMIT 1)),
('ASSET-MOB-002','SN-MOB-E002','Samsung','Galaxy Tab S9',              62000.00,'2023-08-10','2024-08-10',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Tablet'      LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'               LIMIT 1)),
('ASSET-MOB-003','SN-MOB-E003','Apple',  'iPad Pro 12.9',              80000.00,'2022-11-01','2023-11-01',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Tablet'      LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Retired'              LIMIT 1)),

-- Server (3 assets)
('ASSET-SRV-001','SN-SRV-F001','HP',     'ProLiant DL380 Gen10',      280000.00,'2023-05-01','2026-05-01',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Rack Server' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'               LIMIT 1)),
('ASSET-SRV-002','SN-SRV-F002','Dell',   'PowerEdge R750',            310000.00,'2023-07-15','2026-07-15',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Rack Server' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Active'               LIMIT 1)),
('ASSET-SRV-003','SN-SRV-F003','IBM',    'System x3650 M5',           195000.00,'2020-03-01','2023-03-01',
  (SELECT internal_id FROM asset_subtype_master WHERE subtype_name='Rack Server' LIMIT 1),
  (SELECT internal_id FROM asset_status WHERE status_name='Retired'              LIMIT 1));

-- ─────────────────────────────────────────────────────────────
-- 10. Purchase Orders  (10 PENDING + 4 FULLY_RECEIVED + 2 CANCELLED = 16 total)
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO purchase_order_header (po_number, po_date, status, thisobject2vendor, total_amount)
VALUES
-- 10 PENDING
('PO2001','2024-01-10','PENDING',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='ABC Suppliers'      LIMIT 1), 95000.00),
('PO2002','2024-01-20','PENDING',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='XYZ Distributors'   LIMIT 1), 128000.00),
('PO2003','2024-02-05','PENDING',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Orion Tech'         LIMIT 1), 75000.00),
('PO2009','2024-05-10','PENDING',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Tech Bazaar'        LIMIT 1), 110000.00),
('PO2011','2024-06-01','PENDING',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Vertex Corp'        LIMIT 1), 88000.00),
('PO2012','2024-06-15','PENDING',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Omni Retail'        LIMIT 1), 67000.00),
('PO2013','2024-07-01','PENDING',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='NextGen Supply'     LIMIT 1), 142000.00),
('PO2014','2024-07-20','PENDING',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Cloud Vendors'      LIMIT 1), 54000.00),
('PO2015','2024-08-05','PENDING',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Smart Supply'       LIMIT 1), 96000.00),
('PO2016','2024-08-20','PENDING',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='ABC Suppliers'      LIMIT 1), 73000.00),
-- 4 FULLY_RECEIVED
('PO2004','2024-02-15','FULLY_RECEIVED',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Delta Traders'      LIMIT 1), 210000.00),
('PO2005','2024-03-01','FULLY_RECEIVED',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Prime Vendors'      LIMIT 1), 165000.00),
('PO2006','2024-03-15','FULLY_RECEIVED',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Nova Supply'        LIMIT 1), 89000.00),
('PO2010','2024-05-25','FULLY_RECEIVED',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Global IT'          LIMIT 1), 245000.00),
-- 2 CANCELLED
('PO2007','2024-04-01','CANCELLED',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Apex Goods'         LIMIT 1), 55000.00),
('PO2008','2024-04-20','CANCELLED',
  (SELECT internal_id FROM vendor_master WHERE vendor_name='Zen Supplies'       LIMIT 1), 32000.00);

-- ─────────────────────────────────────────────────────────────
-- 11. PO Details
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'ThinkPad X1 Carbon Gen11', 5, 17000.00, 15300.00, 100300.00
FROM purchase_order_header poh WHERE poh.po_number='PO2001' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Laptop Bags (set of 5)', 5, 800.00, 720.00, 4720.00
FROM purchase_order_header poh WHERE poh.po_number='PO2001' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Dell UltraSharp U2723DE', 8, 14000.00, 20160.00, 132160.00
FROM purchase_order_header poh WHERE poh.po_number='PO2002' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'HDMI Cables (pack of 10)', 2, 500.00, 180.00, 1180.00
FROM purchase_order_header poh WHERE poh.po_number='PO2002' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Cisco ISR 4351 Router', 1, 68000.00, 12240.00, 80240.00
FROM purchase_order_header poh WHERE poh.po_number='PO2003' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Cat6 Cabling Kit', 3, 600.00, 324.00, 2124.00
FROM purchase_order_header poh WHERE poh.po_number='PO2003' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'HP ProLiant DL380 Gen10', 1, 190000.00, 34200.00, 224200.00
FROM purchase_order_header poh WHERE poh.po_number='PO2004' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, '16GB DDR4 RAM Module', 8, 2500.00, 3600.00, 23600.00
FROM purchase_order_header poh WHERE poh.po_number='PO2004' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Dell PowerEdge R750', 1, 260000.00, 46800.00, 306800.00
FROM purchase_order_header poh WHERE poh.po_number='PO2005' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Rack PDU 30A', 2, 8000.00, 2880.00, 18880.00
FROM purchase_order_header poh WHERE poh.po_number='PO2005' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'iPhone 15 Pro (x5)', 5, 15000.00, 13500.00, 88500.00
FROM purchase_order_header poh WHERE poh.po_number='PO2006' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'MagSafe Charger (x5)', 5, 500.00, 450.00, 2950.00
FROM purchase_order_header poh WHERE poh.po_number='PO2006' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Gaming Chairs (bulk order)', 10, 4500.00, 8100.00, 53100.00
FROM purchase_order_header poh WHERE poh.po_number='PO2007' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Office Webcams', 20, 1500.00, 5400.00, 35400.00
FROM purchase_order_header poh WHERE poh.po_number='PO2008' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'HP EliteBook 840 G10', 4, 22000.00, 15840.00, 103840.00
FROM purchase_order_header poh WHERE poh.po_number='PO2009' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Docking Stations', 4, 2000.00, 1440.00, 9440.00
FROM purchase_order_header poh WHERE poh.po_number='PO2009' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Cisco Catalyst 9300-48P', 2, 98000.00, 35280.00, 231280.00
FROM purchase_order_header poh WHERE poh.po_number='PO2010' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'SFP+ Transceivers (x8)', 8, 1500.00, 2160.00, 14160.00
FROM purchase_order_header poh WHERE poh.po_number='PO2010' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Samsung Odyssey G7 Monitors', 3, 22000.00, 11880.00, 77880.00
FROM purchase_order_header poh WHERE poh.po_number='PO2011' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'USB-C Hubs (x10)', 10, 1000.00, 1800.00, 11800.00
FROM purchase_order_header poh WHERE poh.po_number='PO2011' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Wireless Keyboards (x15)', 15, 2500.00, 6750.00, 44250.00
FROM purchase_order_header poh WHERE poh.po_number='PO2012' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Wireless Mouse (x15)', 15, 1500.00, 4050.00, 26550.00
FROM purchase_order_header poh WHERE poh.po_number='PO2012' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Apple iPad Pro 12.9 (x4)', 4, 28000.00, 20160.00, 132160.00
FROM purchase_order_header poh WHERE poh.po_number='PO2013' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Apple Pencil Gen2 (x4)', 4, 2500.00, 1800.00, 11800.00
FROM purchase_order_header poh WHERE poh.po_number='PO2013' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'TP-Link TL-SG3428 Switch', 3, 12000.00, 6480.00, 42480.00
FROM purchase_order_header poh WHERE poh.po_number='PO2014' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Patch Panel 24-port', 2, 3500.00, 1260.00, 8260.00
FROM purchase_order_header poh WHERE poh.po_number='PO2014' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'HP LaserJet Pro M404dn', 4, 18000.00, 12960.00, 84960.00
FROM purchase_order_header poh WHERE poh.po_number='PO2015' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Printer Toner Cartridges (x8)', 8, 1500.00, 2160.00, 14160.00
FROM purchase_order_header poh WHERE poh.po_number='PO2015' LIMIT 1;

INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'Dell OptiPlex 7090 (x2)', 2, 28000.00, 10080.00, 66080.00
FROM purchase_order_header poh WHERE poh.po_number='PO2016' LIMIT 1;
INSERT IGNORE INTO purchase_order_detail (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT poh.internal_id, 'RAM Upgrade 16GB (x4)', 4, 2500.00, 1800.00, 11800.00
FROM purchase_order_header poh WHERE poh.po_number='PO2016' LIMIT 1;

-- ─────────────────────────────────────────────────────────────
-- 12. Goods Receipt for FULLY_RECEIVED POs
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO goods_receipt_header (grn_date, thisobject2po)
SELECT '2024-03-10', poh.internal_id FROM purchase_order_header poh WHERE poh.po_number='PO2004' LIMIT 1;
INSERT IGNORE INTO goods_receipt_detail (thisobject2grn, thisobject2podetail, qty_received)
SELECT
  (SELECT grh.internal_id FROM goods_receipt_header grh
   JOIN purchase_order_header p ON p.internal_id=grh.thisobject2po
   WHERE p.po_number='PO2004' LIMIT 1),
  pod.internal_id, pod.quantity
FROM purchase_order_detail pod
JOIN purchase_order_header poh ON poh.internal_id=pod.thisobject2po
WHERE poh.po_number='PO2004';

INSERT IGNORE INTO goods_receipt_header (grn_date, thisobject2po)
SELECT '2024-03-25', poh.internal_id FROM purchase_order_header poh WHERE poh.po_number='PO2005' LIMIT 1;
INSERT IGNORE INTO goods_receipt_detail (thisobject2grn, thisobject2podetail, qty_received)
SELECT
  (SELECT grh.internal_id FROM goods_receipt_header grh
   JOIN purchase_order_header p ON p.internal_id=grh.thisobject2po
   WHERE p.po_number='PO2005' LIMIT 1),
  pod.internal_id, pod.quantity
FROM purchase_order_detail pod
JOIN purchase_order_header poh ON poh.internal_id=pod.thisobject2po
WHERE poh.po_number='PO2005';

INSERT IGNORE INTO goods_receipt_header (grn_date, thisobject2po)
SELECT '2024-04-05', poh.internal_id FROM purchase_order_header poh WHERE poh.po_number='PO2006' LIMIT 1;
INSERT IGNORE INTO goods_receipt_detail (thisobject2grn, thisobject2podetail, qty_received)
SELECT
  (SELECT grh.internal_id FROM goods_receipt_header grh
   JOIN purchase_order_header p ON p.internal_id=grh.thisobject2po
   WHERE p.po_number='PO2006' LIMIT 1),
  pod.internal_id, pod.quantity
FROM purchase_order_detail pod
JOIN purchase_order_header poh ON poh.internal_id=pod.thisobject2po
WHERE poh.po_number='PO2006';

INSERT IGNORE INTO goods_receipt_header (grn_date, thisobject2po)
SELECT '2024-06-10', poh.internal_id FROM purchase_order_header poh WHERE poh.po_number='PO2010' LIMIT 1;
INSERT IGNORE INTO goods_receipt_detail (thisobject2grn, thisobject2podetail, qty_received)
SELECT
  (SELECT grh.internal_id FROM goods_receipt_header grh
   JOIN purchase_order_header p ON p.internal_id=grh.thisobject2po
   WHERE p.po_number='PO2010' LIMIT 1),
  pod.internal_id, pod.quantity
FROM purchase_order_detail pod
JOIN purchase_order_header poh ON poh.internal_id=pod.thisobject2po
WHERE poh.po_number='PO2010';

-- ─────────────────────────────────────────────────────────────
-- 13. Asset Allocations
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO asset_allocation
    (thisobject2asset, thisobject2individual, allocation_type, allocated_on,
     expected_return_date, allocation_status)
VALUES
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-LAP-001' LIMIT 1),
 (SELECT i.internal_id FROM individual i WHERE i.email='u1@mail.com'  LIMIT 1),
 'ASSIGNED','2023-02-01','2025-02-01','ACTIVE'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-LAP-002' LIMIT 1),
 (SELECT i.internal_id FROM individual i WHERE i.email='u2@mail.com'  LIMIT 1),
 'ASSIGNED','2023-03-10','2025-03-10','ACTIVE'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-LAP-004' LIMIT 1),
 (SELECT i.internal_id FROM individual i WHERE i.email='u4@mail.com'  LIMIT 1),
 'ASSIGNED','2023-04-20','2025-04-20','ACTIVE'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-MOB-001' LIMIT 1),
 (SELECT i.internal_id FROM individual i WHERE i.email='u5@mail.com'  LIMIT 1),
 'ASSIGNED','2023-10-01','2024-10-01','ACTIVE'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-MON-001' LIMIT 1),
 (SELECT i.internal_id FROM individual i WHERE i.email='u3@mail.com'  LIMIT 1),
 'SHARED','2023-03-15',NULL,'ACTIVE'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-MON-002' LIMIT 1),
 (SELECT i.internal_id FROM individual i WHERE i.email='u8@mail.com'  LIMIT 1),
 'SHARED','2023-05-20',NULL,'ACTIVE'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-MOB-002' LIMIT 1),
 (SELECT i.internal_id FROM individual i WHERE i.email='u9@mail.com'  LIMIT 1),
 'ASSIGNED','2023-09-01','2024-09-01','ACTIVE'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-LAP-005' LIMIT 1),
 (SELECT i.internal_id FROM individual i WHERE i.email='u11@mail.com' LIMIT 1),
 'ASSIGNED','2022-07-01','2024-07-01','RETURNED');

-- ─────────────────────────────────────────────────────────────
-- 14. Maintenance Records — correct column names: maintenance_date, description
-- Dates in next 30 days from 2026-04-25 for dashboard alerts
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO maintenance_record (thisobject2asset, maintenance_date, description, cost, status)
VALUES
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-LAP-003' LIMIT 1),
 '2026-04-28','Battery replacement required',     3500.00,'OPEN'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-NET-003' LIMIT 1),
 '2026-05-05','Port failure on slot 12',           8000.00,'IN_PROGRESS'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-SRV-001' LIMIT 1),
 '2026-05-15','Scheduled firmware update & patch', 0.00,   'OPEN'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-MOB-003' LIMIT 1),
 '2023-11-10','Screen cracked, sent for repair',   4500.00,'COMPLETED'),
((SELECT a.internal_id FROM asset a WHERE a.asset_tag='ASSET-LAP-006' LIMIT 1),
 '2024-01-05','End-of-life check, decommission',   0.00,   'COMPLETED');

-- ─────────────────────────────────────────────────────────────
-- 15. vendor_address_map
-- ─────────────────────────────────────────────────────────────
INSERT IGNORE INTO vendor_address_map (thisobject2vendor, thisobject2address, is_primary)
VALUES
((SELECT v.internal_id FROM vendor_master v WHERE v.vendor_name='ABC Suppliers'    LIMIT 1),
 (SELECT a.internal_id FROM address a WHERE a.building_no='1A' LIMIT 1), 1),
((SELECT v.internal_id FROM vendor_master v WHERE v.vendor_name='XYZ Distributors' LIMIT 1),
 (SELECT a.internal_id FROM address a WHERE a.building_no='2B' LIMIT 1), 1),
((SELECT v.internal_id FROM vendor_master v WHERE v.vendor_name='Delta Traders'    LIMIT 1),
 (SELECT a.internal_id FROM address a WHERE a.building_no='3C' LIMIT 1), 1),
((SELECT v.internal_id FROM vendor_master v WHERE v.vendor_name='Prime Vendors'    LIMIT 1),
 (SELECT a.internal_id FROM address a WHERE a.building_no='4D' LIMIT 1), 1),
((SELECT v.internal_id FROM vendor_master v WHERE v.vendor_name='Nova Supply'      LIMIT 1),
 (SELECT a.internal_id FROM address a WHERE a.building_no='5E' LIMIT 1), 1);

SET FOREIGN_KEY_CHECKS = 1;

-- ─────────────────────────────────────────────────────────────
-- Verification counts
-- ─────────────────────────────────────────────────────────────
SELECT 'asset_type_master'        AS tbl, COUNT(*) AS cnt FROM asset_type_master
UNION ALL SELECT 'asset_subtype_master', COUNT(*) FROM asset_subtype_master
UNION ALL SELECT 'asset_status',         COUNT(*) FROM asset_status
UNION ALL SELECT 'asset',                COUNT(*) FROM asset
UNION ALL SELECT 'purchase_order_header',COUNT(*) FROM purchase_order_header
UNION ALL SELECT 'pending_pos',          COUNT(*) FROM purchase_order_header WHERE status='PENDING'
UNION ALL SELECT 'purchase_order_detail',COUNT(*) FROM purchase_order_detail
UNION ALL SELECT 'goods_receipt_header', COUNT(*) FROM goods_receipt_header
UNION ALL SELECT 'asset_allocation',     COUNT(*) FROM asset_allocation
UNION ALL SELECT 'maintenance_record',   COUNT(*) FROM maintenance_record
UNION ALL SELECT 'department',           COUNT(*) FROM department
UNION ALL SELECT 'product_master',       COUNT(*) FROM product_master;
