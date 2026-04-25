

USE it_asset_mgmt_db;




-- 1-A  UNNORMALIZED TABLE



CREATE TABLE individual_unnormalized (
    id            INT PRIMARY KEY,
    first_name    VARCHAR(100),
    last_name     VARCHAR(100),
    email         VARCHAR(100),
    person_type   VARCHAR(50),
    company_id    INT,
    -- Repeating phone group 
    phone1_dial   VARCHAR(10),
    phone1_number VARCHAR(20),
    phone1_type   VARCHAR(20),
    phone2_dial   VARCHAR(10),   
    phone2_number VARCHAR(20),
    phone2_type   VARCHAR(20),
    -- update anomaly if dept is renamed
    dept_id       INT,
    dept_name     VARCHAR(100),   
    dept_start_date DATE
);

INSERT INTO individual_unnormalized VALUES

(1, 'Alice', 'Menon',   'alice@corp.com',   'EMPLOYEE', 10, '+91','9876543210','MOBILE', '+91','08025551234','OFFICE', 2,'Engineering','2023-01-15'),

(2, 'Bob',   'Sharma',  'bob@corp.com',     'EMPLOYEE', 10, '+91','9123456789','MOBILE', NULL, NULL,         NULL,    2,'Engineering','2022-06-01'),

(3, 'Carol', 'Nair',    'carol@corp.com',   'EMPLOYEE', 10, '+91','9988776655','MOBILE', '+91','08044441111','OFFICE', 3,'Human Resources','2021-09-10'),

(4, 'Dave',  'Pillai',  'dave@vendor.com',  'CONTRACTOR',10,'+91','9000011111','MOBILE', NULL, NULL,         NULL,    NULL, NULL, NULL);


-- 1NF violation  : phone1_* and phone2_* are a repeating group.
--                  Adding a third phone requires ALTER TABLE.
--                  Querying "all mobile numbers" needs OR across columns.
--
-- Update anomaly : dept_name='Engineering' appears on rows 1 and 2.
--                  Renaming the department requires updating every employee row.
--
-- Insertion anomaly: Cannot store a new department until an employee joins it.
--
-- Deletion anomaly : Deleting Dave's row loses his phone number permanently
--                    with no way to distinguish "no phone" from "unknown phone".

-- Remove repeating phone columns. Each phone is now one atomic row.


CREATE TABLE phone_number_1nf (
    internal_id       INT AUTO_INCREMENT PRIMARY KEY,
    country_dial_code VARCHAR(10),
    phone_number      VARCHAR(20),
    phone_type        VARCHAR(20)
);

CREATE TABLE individual_1nf (
    internal_id   INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(100),
    last_name     VARCHAR(100),
    email         VARCHAR(100) UNIQUE,
    person_type   VARCHAR(50),
    thisobject2company INT,
 
    dept_id       INT,
    dept_name     VARCHAR(100),
    dept_start_date DATE
);


CREATE TABLE individual_phone_map_1nf (
    internal_id         INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2individual INT NOT NULL,
    thisobject2phone      INT NOT NULL,
    is_primary            BOOLEAN
);


--  Achieve 3NF: extract department assignment
--      dept_name is transitively determined by dept_id (a non-key attribute)
--      internal_id → dept_id → dept_name   ← 3NF violation




CREATE TABLE individual_3nf (
    internal_id        INT AUTO_INCREMENT PRIMARY KEY,
    first_name         VARCHAR(100) NOT NULL,
    last_name          VARCHAR(100),
    email              VARCHAR(100) UNIQUE,
    person_type        VARCHAR(50),
    thisobject2company INT NOT NULL
    
);


CREATE TABLE individual_department_map_3nf (
    internal_id             INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2individual   INT NOT NULL,
    thisobject2department   INT NOT NULL,
    start_date              DATE,
    end_date                DATE,
    status                  VARCHAR(50)
);


INSERT INTO individual_3nf (internal_id, first_name, last_name, email, person_type, thisobject2company)
SELECT id, first_name, last_name, email, person_type, company_id
FROM   individual_unnormalized;

-- Step B: migrate phone1 rows (where phone1 exists)
INSERT INTO phone_number_1nf (country_dial_code, phone_number, phone_type)
SELECT phone1_dial, phone1_number, phone1_type
FROM   individual_unnormalized
WHERE  phone1_number IS NOT NULL;

-- Step C: migrate phone2 rows (where phone2 exists)
INSERT INTO phone_number_1nf (country_dial_code, phone_number, phone_type)
SELECT phone2_dial, phone2_number, phone2_type
FROM   individual_unnormalized
WHERE  phone2_number IS NOT NULL;

-- Step D: migrate department assignments (skip NULLs — contractors with no dept)
INSERT INTO individual_department_map_3nf (thisobject2individual, thisobject2department, start_date, status)
SELECT id, dept_id, dept_start_date, 'ACTIVE'
FROM   individual_unnormalized
WHERE  dept_id IS NOT NULL;

-- Cleanup (demo tables only)
DROP TABLE IF EXISTS individual_unnormalized;
DROP TABLE IF EXISTS individual_1nf;
DROP TABLE IF EXISTS individual_phone_map_1nf;
DROP TABLE IF EXISTS phone_number_1nf;
DROP TABLE IF EXISTS individual_3nf;
DROP TABLE IF EXISTS individual_department_map_3nf;


-- ============================================================
-- SECTION 2: purchase_order_header + purchase_order_detail
-- Problem : one flat table mixed PO header info with line items
--           → 2NF violation (non-key attributes depend on part of a
--             natural composite key, not the full key)
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- 2-A  UNNORMALIZED TABLE
-- ──────────────────────────────────────────────────────────
-- The natural key for a line item would be (po_number, item_seq).
-- po_date, status, vendor_id depend only on po_number — not on item_seq.
-- → Partial dependency → 2NF violation.

CREATE TABLE purchase_order_flat (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    -- PO Header fields (depend only on po_number — not on the line item)
    po_number        VARCHAR(50)  NOT NULL,   -- ❌ repeated per line item
    po_date          DATE,                    -- ❌ repeated per line item
    status           VARCHAR(50),             -- ❌ repeated per line item
    vendor_id        INT,                     -- ❌ repeated per line item
    vendor_name      VARCHAR(150),            -- ❌ repeated + update anomaly
    -- Line-item fields (depend on the full row identity)
    item_description VARCHAR(255),
    quantity         INT,
    unit_price       DECIMAL(10,2),
    gst_amount       DECIMAL(10,2),
    total_price      DECIMAL(12,2)
);

INSERT INTO purchase_order_flat
  (po_number, po_date, status, vendor_id, vendor_name, item_description, quantity, unit_price, gst_amount, total_price)
VALUES
-- PO-001 has two line items; header data is repeated on both rows
('PO-001','2024-01-10','PENDING', 3,'TechSupplies Ltd','Dell Laptop',       10, 75000.00, 13500.00, 763500.00),
('PO-001','2024-01-10','PENDING', 3,'TechSupplies Ltd','USB-C Hub',         10,  8500.00,  1530.00,  86530.00),
-- PO-002 has three line items; vendor_name 'OfficeWorks' duplicated three times
('PO-002','2024-01-15','RECEIVED',5,'OfficeWorks Inc', 'Office Chair',       5, 12000.00,  2160.00,  62160.00),
('PO-002','2024-01-15','RECEIVED',5,'OfficeWorks Inc', 'Standing Desk',      5, 25000.00,  4500.00, 147500.00),
('PO-002','2024-01-15','RECEIVED',5,'OfficeWorks Inc', 'Monitor Arm',       10,  3500.00,   630.00,  41300.00);

-- ══════════════════════════════════════════════════════════
-- VIOLATION ANALYSIS
-- ══════════════════════════════════════════════════════════
-- Natural composite key: (po_number, item_description) or (po_number, id)
--
-- Partial dependencies (2NF violation):
--   po_number → po_date           (po_date does not need item_description)
--   po_number → status            (status tracks the whole PO, not one line)
--   po_number → vendor_id         (vendor is per PO, not per line)
--   po_number → vendor_name       (vendor_name duplicated per line — update anomaly)
--
-- Update anomaly  : Changing PO-001 status to 'APPROVED' requires updating
--                   both rows. If one update fails, status is inconsistent.
-- Insertion anomaly: Cannot create a PO header until at least one item is known.
-- Deletion anomaly : Deleting all line items of PO-002 deletes the PO header too.
-- ══════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────
-- 2-B  DECOMPOSED → 2NF (matches our actual schema)
-- ──────────────────────────────────────────────────────────

CREATE TABLE purchase_order_header_2nf (
    internal_id  INT AUTO_INCREMENT PRIMARY KEY,
    po_number    VARCHAR(50) UNIQUE NOT NULL,
    po_date      DATE,
    status       VARCHAR(50),
    thisobject2vendor INT NOT NULL   -- vendor_name removed; join vendor_master
);

CREATE TABLE purchase_order_detail_2nf (
    internal_id      INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2po    INT NOT NULL,   -- FK → purchase_order_header_2nf
    item_description VARCHAR(255),
    quantity         INT,
    unit_price       DECIMAL(10,2),
    gst_amount       DECIMAL(10,2),
    total_price      DECIMAL(12,2)
);

-- ──────────────────────────────────────────────────────────
-- 2-C  DATA MIGRATION from flat → 2NF tables
-- ──────────────────────────────────────────────────────────

-- Step A: one header row per distinct PO number
INSERT INTO purchase_order_header_2nf (po_number, po_date, status, thisobject2vendor)
SELECT DISTINCT po_number, po_date, status, vendor_id
FROM   purchase_order_flat;

-- Step B: migrate line items, replacing po_number with the new FK id
INSERT INTO purchase_order_detail_2nf
  (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
SELECT
    h.internal_id,
    f.item_description,
    f.quantity,
    f.unit_price,
    f.gst_amount,
    f.total_price
FROM  purchase_order_flat      f
JOIN  purchase_order_header_2nf h ON h.po_number = f.po_number;

-- Cleanup
DROP TABLE IF EXISTS purchase_order_flat;
DROP TABLE IF EXISTS purchase_order_header_2nf;
DROP TABLE IF EXISTS purchase_order_detail_2nf;


-- ============================================================
-- SECTION 3: purchase_order_detail — total_price 3NF violation
-- Problem : total_price is fully determined by (quantity, unit_price, gst_amount)
--           those are non-key attributes → transitive dependency → 3NF violation
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- 3-A  VIOLATION DEMONSTRATION
-- ──────────────────────────────────────────────────────────

-- The FD chain that breaks 3NF:
--
--   internal_id → quantity, unit_price, gst_amount    (PK determines these)
--                                     ↓
--                 (quantity, unit_price, gst_amount) → total_price
--                                     ↓
--   internal_id ──(transitively)──────────────────────→ total_price
--
-- This means total_price is a derived / redundant column.
-- Storing it creates an inconsistency risk:

CREATE TABLE purchase_order_detail_3nf_bad (
    internal_id      INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2po    INT  NOT NULL,
    item_description VARCHAR(255),
    quantity         INT,
    unit_price       DECIMAL(10,2),
    gst_amount       DECIMAL(10,2),
    total_price      DECIMAL(12,2)   -- ❌ derived: (qty * unit_price) + gst_amount
);

-- ❌ Inconsistency: total_price doesn't match the formula
INSERT INTO purchase_order_detail_3nf_bad
  (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
VALUES
  (1, 'Dell Laptop',  10, 75000.00, 13500.00, 763500.00),  -- correct
  (1, 'USB-C Hub',    10,  8500.00,  1530.00,  99999.99);  -- ❌ wrong total

-- A SELECT that trusts total_price will return wrong data for row 2.
-- An application recalculating (qty * unit_price + gst_amount) gets a different answer.

-- ══════════════════════════════════════════════════════════
-- OPTION A — Strict 3NF: remove total_price entirely, compute in queries
-- ══════════════════════════════════════════════════════════

CREATE TABLE purchase_order_detail_strict_3nf (
    internal_id      INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2po    INT  NOT NULL,
    item_description VARCHAR(255),
    quantity         INT,
    unit_price       DECIMAL(10,2),
    gst_amount       DECIMAL(10,2)
    -- total_price removed; computed as (quantity * unit_price) + gst_amount in SELECT
);

-- Query replacing stored total_price:
-- SELECT
--     internal_id,
--     item_description,
--     quantity,
--     unit_price,
--     gst_amount,
--     (quantity * unit_price) + gst_amount AS total_price
-- FROM purchase_order_detail_strict_3nf;

-- Migration from bad table → strict 3NF (drop the column):
INSERT INTO purchase_order_detail_strict_3nf
  (internal_id, thisobject2po, item_description, quantity, unit_price, gst_amount)
SELECT internal_id, thisobject2po, item_description, quantity, unit_price, gst_amount
FROM   purchase_order_detail_3nf_bad;

-- ══════════════════════════════════════════════════════════
-- OPTION B — Pragmatic: keep total_price for audit/discount reasons,
--            but enforce consistency with BEFORE INSERT / BEFORE UPDATE triggers
-- ══════════════════════════════════════════════════════════

-- This is the approach we use in the actual schema (purchase_order_detail).

DELIMITER $$

-- Trigger 1: auto-compute total_price on INSERT
-- Ensures the stored value always equals the formula, even if the caller
-- passes a wrong total or omits total_price entirely.
CREATE TRIGGER trg_pod_before_insert
BEFORE INSERT ON purchase_order_detail
FOR EACH ROW
BEGIN
    SET NEW.total_price = (NEW.quantity * NEW.unit_price) + NEW.gst_amount;
END$$

-- Trigger 2: auto-compute total_price on UPDATE
-- Recalculates whenever quantity, unit_price, or gst_amount is changed.
-- Prevents stale total_price after a price correction or quantity adjustment.
CREATE TRIGGER trg_pod_before_update
BEFORE UPDATE ON purchase_order_detail
FOR EACH ROW
BEGIN
    SET NEW.total_price = (NEW.quantity * NEW.unit_price) + NEW.gst_amount;
END$$

DELIMITER ;

-- Verify trigger behaviour:
-- INSERT passes wrong total → trigger overwrites it silently
INSERT INTO purchase_order_detail
  (thisobject2po, item_description, quantity, unit_price, gst_amount, total_price)
VALUES
  (1, 'Dell Laptop',  10, 75000.00, 13500.00, 99999.99);   -- caller passes wrong value
-- SELECT will show total_price = (10 * 75000) + 13500 = 763500.00  ✓

-- UPDATE changes quantity → trigger recomputes total_price automatically
UPDATE purchase_order_detail
SET    quantity = 12
WHERE  item_description = 'Dell Laptop' AND thisobject2po = 1;
-- total_price is now (12 * 75000) + 13500 = 913500.00  ✓

-- Cleanup demo tables
DROP TABLE IF EXISTS purchase_order_detail_3nf_bad;
DROP TABLE IF EXISTS purchase_order_detail_strict_3nf;


-- ============================================================
-- SECTION 4: product_master + product_specification
-- Problem : product specifications stored as fixed columns
--           → NULL-heavy table, requires ALTER TABLE for new spec types
--           → violates the open/closed principle in the schema
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- 4-A  UNNORMALIZED TABLE
-- ──────────────────────────────────────────────────────────
-- Specs are hard-coded columns. A monitor has no RAM; a laptop has no resolution.
-- Every product row carries NULLs for specs it doesn't use.

CREATE TABLE product_master_flat (
    internal_id   INT AUTO_INCREMENT PRIMARY KEY,
    product_name  VARCHAR(150) NOT NULL,
    manufacturer  VARCHAR(100),
    model         VARCHAR(100),
    category      VARCHAR(50),
    is_active     BOOLEAN DEFAULT TRUE,
    -- ❌ Spec columns — most are NULL for most products
    ram_gb        INT,           -- NULL for monitors, chairs, printers
    storage_gb    INT,           -- NULL for monitors, chairs, printers
    processor     VARCHAR(100),  -- NULL for monitors, chairs
    display_inch  DECIMAL(4,1),  -- NULL for laptops (arguably), chairs
    resolution    VARCHAR(20),   -- NULL for laptops, chairs
    weight_kg     DECIMAL(5,2),  -- NULL for most
    os            VARCHAR(50)    -- NULL for monitors, chairs
);

INSERT INTO product_master_flat
  (product_name, manufacturer, model, category, ram_gb, storage_gb, processor, display_inch, resolution, os)
VALUES
-- Laptop: has ram, storage, processor, os — no resolution column used
('Dell Laptop',    'Dell', 'Latitude 5540', 'LAPTOP',  16, 512, 'Intel i7-1365U', 15.6, NULL,       'Windows 11'),
-- Monitor: has display_inch, resolution — no ram, storage, processor, os
('LG Monitor',     'LG',   'UltraWide 34WQ','MONITOR', NULL, NULL, NULL,          34.0, '3440x1440', NULL),
-- Keyboard: none of the spec columns apply
('Logitech KB',    'Logitech','MX Keys',    'PERIPHERAL',NULL,NULL,NULL,          NULL, NULL,        NULL),
-- Server: has ram, storage, processor — no display
('Dell Server',    'Dell', 'PowerEdge R750','SERVER',  256,  8000,'Intel Xeon',   NULL, NULL,       'Linux');

-- ══════════════════════════════════════════════════════════
-- VIOLATION ANALYSIS
-- ══════════════════════════════════════════════════════════
-- • NULL overload  : Each product row is largely NULL — wasted storage and
--                    misleading query results (NULL ≠ "not applicable").
-- • Schema rigidity: Adding "battery_life_hrs" for laptops requires ALTER TABLE
--                    that adds a NULL column to every monitor, chair, server row.
-- • Update anomaly : Intel changes the i7-1365U spec — every product using that
--                    processor string must be individually updated.
-- • 1NF risk       : A product with two storage options (SSD + HDD) would need
--                    a second column or a CSV value, violating atomicity.
-- ══════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────
-- 4-B  DECOMPOSED → EAV design (matches our actual schema)
-- ──────────────────────────────────────────────────────────
-- product_master holds only invariant identity attributes.
-- product_specification holds one row per spec key-value pair.

CREATE TABLE product_master_3nf (
    internal_id   INT AUTO_INCREMENT PRIMARY KEY,
    product_name  VARCHAR(150) NOT NULL,
    manufacturer  VARCHAR(100),
    model         VARCHAR(100),
    category      VARCHAR(50),
    is_active     BOOLEAN DEFAULT TRUE
    -- No spec columns — all moved to product_specification
);

CREATE TABLE product_specification_3nf (
    internal_id         INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2product  INT  NOT NULL,   -- FK → product_master_3nf
    spec_key            VARCHAR(100) NOT NULL,
    spec_value          VARCHAR(255) NOT NULL
    -- Candidate key: (thisobject2product, spec_key)
    -- UNIQUE (thisobject2product, spec_key) ensures one value per spec per product
);

-- ──────────────────────────────────────────────────────────
-- 4-C  DATA MIGRATION from flat → EAV
-- ──────────────────────────────────────────────────────────

-- Step A: copy identity columns (no NULLs problem here)
INSERT INTO product_master_3nf (internal_id, product_name, manufacturer, model, category, is_active)
SELECT internal_id, product_name, manufacturer, model, category, is_active
FROM   product_master_flat;

-- Step B: unpivot spec columns into key-value rows.
--         UNION ALL handles each column; WHERE filters out NULLs
--         so non-applicable specs produce zero rows (not NULL rows).

INSERT INTO product_specification_3nf (thisobject2product, spec_key, spec_value)
SELECT internal_id, 'ram_gb',       CAST(ram_gb AS CHAR)       FROM product_master_flat WHERE ram_gb       IS NOT NULL
UNION ALL
SELECT internal_id, 'storage_gb',   CAST(storage_gb AS CHAR)   FROM product_master_flat WHERE storage_gb   IS NOT NULL
UNION ALL
SELECT internal_id, 'processor',    processor                   FROM product_master_flat WHERE processor     IS NOT NULL
UNION ALL
SELECT internal_id, 'display_inch', CAST(display_inch AS CHAR) FROM product_master_flat WHERE display_inch  IS NOT NULL
UNION ALL
SELECT internal_id, 'resolution',   resolution                  FROM product_master_flat WHERE resolution    IS NOT NULL
UNION ALL
SELECT internal_id, 'weight_kg',    CAST(weight_kg AS CHAR)    FROM product_master_flat WHERE weight_kg     IS NOT NULL
UNION ALL
SELECT internal_id, 'os',           os                          FROM product_master_flat WHERE os            IS NOT NULL;

-- Cleanup
DROP TABLE IF EXISTS product_master_flat;
DROP TABLE IF EXISTS product_master_3nf;
DROP TABLE IF EXISTS product_specification_3nf;


-- ============================================================
-- SECTION 5: asset
-- Problem : allocation status and maintenance data stored as columns on asset
--           → only one allocation and one maintenance could be tracked per asset
--           → historical records were overwritten (deletion anomaly)
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- 5-A  UNNORMALIZED TABLE
-- ──────────────────────────────────────────────────────────
-- One row per asset, with allocation and maintenance bolted on.
-- When an asset is reallocated, the old allocation data is lost.
-- When a second maintenance is done, the first is overwritten.

CREATE TABLE asset_flat (
    internal_id            INT AUTO_INCREMENT PRIMARY KEY,
    asset_tag              VARCHAR(50) UNIQUE NOT NULL,
    serial_no              VARCHAR(50) UNIQUE,
    make                   VARCHAR(100),
    asset_model            VARCHAR(100),
    purchase_cost          DECIMAL(12,2),
    warranty_start         DATE,
    warranty_end           DATE,
    thisobject2subtype     INT NOT NULL,
    thisobject2status      INT NOT NULL,
    -- ❌ Allocation inline — can only represent the CURRENT allocation
    allocated_to_id        INT,         -- individual id
    allocation_type        VARCHAR(50),
    allocated_on           DATE,
    expected_return_date   DATE,
    actual_return_date     DATE,
    allocation_status      VARCHAR(50),
    -- ❌ Maintenance inline — can only represent the LAST maintenance event
    last_maintenance_date  DATE,
    last_maintenance_desc  VARCHAR(255),
    last_maintenance_cost  DECIMAL(10,2),
    last_maintenance_status VARCHAR(50)
);

INSERT INTO asset_flat VALUES
-- Laptop: currently allocated to Alice (id=1). Previous allocation to Bob is gone.
-- Last maintenance only; prior service records are overwritten.
(1,'ASSET-LAP-001','DLLSN001','Dell','Latitude 5540',75000.00,'2024-01-10','2027-01-10',2,1,
 1,'PERMANENT','2024-01-15','2025-01-15',NULL,'ACTIVE',
 '2024-06-01','Battery replacement',2500.00,'COMPLETED'),

-- Monitor: unallocated (NULLs for allocation columns), never maintained
(2,'ASSET-MON-001','LGSN001','LG','UltraWide 34WQ',32000.00,'2024-02-01','2026-02-01',4,1,
 NULL,NULL,NULL,NULL,NULL,NULL,
 NULL,NULL,NULL,NULL),

-- Keyboard: in IT store, had one repair
(3,'ASSET-KEY-001','LGSN002','Logitech','MX Keys',4200.00,'2024-03-01','2025-03-01',5,2,
 NULL,'STORAGE','2024-03-05',NULL,NULL,'INACTIVE',
 '2024-08-10','Key replacement',500.00,'COMPLETED');

-- ══════════════════════════════════════════════════════════
-- VIOLATION ANALYSIS
-- ══════════════════════════════════════════════════════════
-- Mixing concerns: asset identity + allocation episode + maintenance event.
--
-- Deletion anomaly  : Returning an asset (clearing allocated_to_id etc.) destroys
--                     all record of who had it and when.
-- Update anomaly    : Reallocating an asset overwrites the previous allocation.
--                     There is no way to answer "who had ASSET-LAP-001 before Alice?"
-- Insertion anomaly : Cannot record a second maintenance event without a new row,
--                     which would duplicate all asset identity columns.
-- NULL overload     : Unallocated assets carry NULL in 6 allocation columns.
--                     Assets never maintained carry NULL in 4 maintenance columns.
-- ══════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────
-- 5-B  DECOMPOSED → 3NF (matches our actual schema)
-- ──────────────────────────────────────────────────────────

CREATE TABLE asset_3nf (
    internal_id        INT AUTO_INCREMENT PRIMARY KEY,
    asset_tag          VARCHAR(50) UNIQUE NOT NULL,
    serial_no          VARCHAR(50) UNIQUE,
    make               VARCHAR(100),
    asset_model        VARCHAR(100),
    purchase_cost      DECIMAL(12,2),
    warranty_start     DATE,
    warranty_end       DATE,
    thisobject2subtype INT NOT NULL,
    thisobject2status  INT NOT NULL
    -- No allocation or maintenance columns
);

CREATE TABLE asset_allocation_3nf (
    internal_id             INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2asset        INT  NOT NULL,   -- FK → asset_3nf
    thisobject2individual   INT,             -- NULL = allocated to storage/dept, not a person
    allocation_type         VARCHAR(50),
    allocated_on            DATE,
    expected_return_date    DATE,
    actual_return_date      DATE,
    allocation_status       VARCHAR(50)
    -- Multiple rows per asset = full allocation history preserved
);

CREATE TABLE maintenance_record_3nf (
    internal_id      INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2asset INT  NOT NULL,   -- FK → asset_3nf
    maintenance_date DATE,
    description      VARCHAR(255),
    cost             DECIMAL(10,2),
    status           VARCHAR(50)
    -- Multiple rows per asset = full maintenance history preserved
);

-- ──────────────────────────────────────────────────────────
-- 5-C  DATA MIGRATION from flat → 3NF tables
-- ──────────────────────────────────────────────────────────

-- Step A: migrate asset identity (strip allocation & maintenance columns)
INSERT INTO asset_3nf
  (internal_id, asset_tag, serial_no, make, asset_model, purchase_cost,
   warranty_start, warranty_end, thisobject2subtype, thisobject2status)
SELECT
  internal_id, asset_tag, serial_no, make, asset_model, purchase_cost,
  warranty_start, warranty_end, thisobject2subtype, thisobject2status
FROM asset_flat;

-- Step B: migrate current allocation records (skip assets that were never allocated)
INSERT INTO asset_allocation_3nf
  (thisobject2asset, thisobject2individual, allocation_type,
   allocated_on, expected_return_date, actual_return_date, allocation_status)
SELECT
  internal_id,
  allocated_to_id,
  allocation_type,
  allocated_on,
  expected_return_date,
  actual_return_date,
  allocation_status
FROM asset_flat
WHERE allocated_on IS NOT NULL;   -- only rows that had an active allocation

-- Step C: migrate last maintenance record (skip assets never maintained)
INSERT INTO maintenance_record_3nf
  (thisobject2asset, maintenance_date, description, cost, status)
SELECT
  internal_id,
  last_maintenance_date,
  last_maintenance_desc,
  last_maintenance_cost,
  last_maintenance_status
FROM asset_flat
WHERE last_maintenance_date IS NOT NULL;

-- Cleanup
DROP TABLE IF EXISTS asset_flat;
DROP TABLE IF EXISTS asset_3nf;
DROP TABLE IF EXISTS asset_allocation_3nf;
DROP TABLE IF EXISTS maintenance_record_3nf;


-- ============================================================
-- SECTION 6: address (was embedded in company / vendor)
-- Problem : address columns stored directly on company and vendor rows
--           → address data duplicated when multiple companies share a building
--           → update anomaly when an address changes
--           → cannot reuse an address across both company and vendor tables
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- 6-A  UNNORMALIZED TABLES
-- ──────────────────────────────────────────────────────────

CREATE TABLE company_with_address (
    internal_id   INT AUTO_INCREMENT PRIMARY KEY,
    company_name  VARCHAR(150) NOT NULL,
    gst_no        VARCHAR(20)  UNIQUE,
    company_email VARCHAR(100) UNIQUE,
    -- ❌ Address columns inline — duplicated if two companies share a building
    building_no   VARCHAR(50),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    area          VARCHAR(100),
    zipcode       VARCHAR(20),
    address_type  VARCHAR(50),
    city_id       INT           -- FK to city — still requires city table
);

CREATE TABLE vendor_with_address (
    internal_id   INT AUTO_INCREMENT PRIMARY KEY,
    vendor_name   VARCHAR(150) NOT NULL,
    gst_no        VARCHAR(20)  UNIQUE,
    vendor_email  VARCHAR(100),
    -- ❌ Same address columns repeated in a different table
    building_no   VARCHAR(50),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    area          VARCHAR(100),
    zipcode       VARCHAR(20),
    address_type  VARCHAR(50),
    city_id       INT
);

INSERT INTO company_with_address VALUES
(1,'Acme Corp',    'GST001','acme@corp.com',     '10','MG Road','Floor 3',  'Bangalore Central','560001','OFFICE',  1),
(2,'Beta Ltd',     'GST002','beta@corp.com',     '10','MG Road','Floor 5',  'Bangalore Central','560001','OFFICE',  1),
-- ❌ building_no, address_line1, area, zipcode, city_id repeated for two companies at same address
(3,'Gamma Inc',    'GST003','gamma@corp.com',    '45','Residency Rd',NULL,  'Shivajinagar',     '560025','HQ',      2);

INSERT INTO vendor_with_address VALUES
(1,'TechSupplies', 'VGST01','tech@vendor.com',  '10','MG Road','Floor 2',  'Bangalore Central','560001','OFFICE',  1),
-- ❌ '10, MG Road, Bangalore Central, 560001' appears in both tables with no shared reference
(2,'OfficeWorks',  'VGST02','office@vendor.com','78','Church St',NULL,      'Brigade Road',     '560025','BILLING', 2);

-- ══════════════════════════════════════════════════════════
-- VIOLATION ANALYSIS
-- ══════════════════════════════════════════════════════════
-- Update anomaly  : MG Road is renamed "Mahatma Gandhi Road".
--                   company rows 1 & 2 must each be updated.
--                   vendor row 1 must also be updated independently.
--                   Missing any one row leaves the DB in an inconsistent state.
--
-- Duplication     : company rows 1 and 2 share the same physical address
--                   (building 10, MG Road, 560001) — every field is duplicated.
--
-- Cross-table reuse: A vendor at the same address as a company cannot reference
--                    the same address row — each table stores its own copy.
--
-- Insertion anomaly: Cannot store an address that is not yet linked to any company.
--
-- Deletion anomaly : Deleting company row 1 destroys the address record for that
--                    building, even if other companies are at the same location.
-- ══════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────
-- 6-B  DECOMPOSED → 3NF (matches our actual schema)
-- ──────────────────────────────────────────────────────────
-- address is a standalone entity; map tables associate it with company or vendor.
-- The same address row can appear in both company_address_map and vendor_address_map.

CREATE TABLE address_3nf (
    internal_id   INT AUTO_INCREMENT PRIMARY KEY,
    building_no   VARCHAR(50),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    area          VARCHAR(100),
    zipcode       VARCHAR(20),
    address_type  VARCHAR(50),
    thisobject2city INT NOT NULL   -- FK → city
);

CREATE TABLE company_3nf (
    internal_id   INT AUTO_INCREMENT PRIMARY KEY,
    company_name  VARCHAR(150) NOT NULL,
    gst_no        VARCHAR(20)  UNIQUE,
    company_email VARCHAR(100) UNIQUE
    -- No address columns
);

CREATE TABLE vendor_3nf (
    internal_id   INT AUTO_INCREMENT PRIMARY KEY,
    vendor_name   VARCHAR(150) NOT NULL,
    gst_no        VARCHAR(20)  UNIQUE,
    vendor_email  VARCHAR(100)
    -- No address columns
);

CREATE TABLE company_address_map_3nf (
    internal_id         INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2company  INT NOT NULL,   -- FK → company_3nf
    thisobject2address  INT NOT NULL,   -- FK → address_3nf
    is_primary          BOOLEAN
);

CREATE TABLE vendor_address_map_3nf (
    internal_id        INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2vendor  INT NOT NULL,   -- FK → vendor_3nf
    thisobject2address INT NOT NULL,   -- FK → address_3nf
    is_primary         BOOLEAN
);

-- ──────────────────────────────────────────────────────────
-- 6-C  DATA MIGRATION from embedded → 3NF tables
-- ──────────────────────────────────────────────────────────

-- Step A: migrate company identity (strip address columns)
INSERT INTO company_3nf (internal_id, company_name, gst_no, company_email)
SELECT internal_id, company_name, gst_no, company_email
FROM   company_with_address;

-- Step B: migrate vendor identity (strip address columns)
INSERT INTO vendor_3nf (internal_id, vendor_name, gst_no, vendor_email)
SELECT internal_id, vendor_name, gst_no, vendor_email
FROM   vendor_with_address;

-- Step C: extract distinct addresses from company rows
--         DISTINCT prevents duplicate address rows for companies sharing a building.
--         We use a temp-table approach to capture the generated address IDs.

CREATE TEMPORARY TABLE addr_migration_temp (
    source_type    VARCHAR(10),   -- 'COMPANY' or 'VENDOR'
    source_id      INT,
    new_address_id INT
);

-- Insert company addresses and record the mapping
INSERT INTO address_3nf (building_no, address_line1, address_line2, area, zipcode, address_type, thisobject2city)
SELECT DISTINCT building_no, address_line1, address_line2, area, zipcode, address_type, city_id
FROM   company_with_address;

-- Link company → new address rows via map table
-- INNER JOIN on all address fields reconstructs the mapping
INSERT INTO company_address_map_3nf (thisobject2company, thisobject2address, is_primary)
SELECT c.internal_id, a.internal_id, TRUE
FROM   company_with_address c
JOIN   address_3nf          a ON  a.building_no   <=> c.building_no
                               AND a.address_line1 <=> c.address_line1
                               AND a.area          <=> c.area
                               AND a.zipcode       <=> c.zipcode
                               AND a.thisobject2city = c.city_id;

-- Step D: insert vendor addresses (only those not already in address_3nf)
--         <=> is MySQL's NULL-safe equality operator
INSERT INTO address_3nf (building_no, address_line1, address_line2, area, zipcode, address_type, thisobject2city)
SELECT v.building_no, v.address_line1, v.address_line2, v.area, v.zipcode, v.address_type, v.city_id
FROM   vendor_with_address v
WHERE  NOT EXISTS (
    SELECT 1 FROM address_3nf a
    WHERE  a.building_no    <=> v.building_no
      AND  a.address_line1  <=> v.address_line1
      AND  a.area           <=> v.area
      AND  a.zipcode        <=> v.zipcode
      AND  a.thisobject2city = v.city_id
);

-- Link vendor → address via map table
INSERT INTO vendor_address_map_3nf (thisobject2vendor, thisobject2address, is_primary)
SELECT v.internal_id, a.internal_id, TRUE
FROM   vendor_with_address v
JOIN   address_3nf         a ON  a.building_no   <=> v.building_no
                              AND a.address_line1 <=> v.address_line1
                              AND a.area          <=> v.area
                              AND a.zipcode       <=> v.zipcode
                              AND a.thisobject2city = v.city_id;

-- Cleanup
DROP TEMPORARY TABLE IF EXISTS addr_migration_temp;
DROP TABLE IF EXISTS company_with_address;
DROP TABLE IF EXISTS vendor_with_address;
DROP TABLE IF EXISTS address_3nf;
DROP TABLE IF EXISTS company_3nf;
DROP TABLE IF EXISTS vendor_3nf;
DROP TABLE IF EXISTS company_address_map_3nf;
DROP TABLE IF EXISTS vendor_address_map_3nf;


-- ============================================================
-- SUMMARY: Normal Form Achieved per Table After Decomposition
-- ============================================================
--
-- Table                          Before          After   Key fix
-- ─────────────────────────────────────────────────────────────────────
-- individual                     UNF (1NF fail)  3NF     Extracted phones → phone_number + individual_phone_map
--                                                         Extracted dept   → individual_department_map
-- purchase_order (flat)          UNF/2NF fail    3NF     Split into purchase_order_header + purchase_order_detail
-- purchase_order_detail          2NF (3NF fail)  3NF*    Trigger enforces total_price = (qty*price)+gst
-- product_master (flat)          UNF (NULLs)     3NF     Extracted specs → product_specification (EAV)
-- asset (flat)                   UNF             3NF     Extracted allocation → asset_allocation
--                                                         Extracted maintenance → maintenance_record
-- company / vendor (embedded)    UNF             3NF     Extracted address → address + *_address_map
--
-- * total_price kept for audit; 3NF enforced via BEFORE INSERT / BEFORE UPDATE triggers
-- ============================================================
