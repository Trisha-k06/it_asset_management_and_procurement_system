-- ============================================================
--  NORMALIZATION DEMONSTRATION — Live Database Manipulation
--  IT Asset & Procurement Management System
--  Uses actual table/column names throughout
-- ============================================================

USE it_asset_mgmt_db;

-- ============================================================
-- STEP 0: Seed prerequisite lookup data
-- (country → province → city chain required by FK constraints)
-- ============================================================

-- Only insert if not already present (idempotent demo)
INSERT IGNORE INTO country (country_code, country_name, currency)
VALUES ('IN', 'India', 'INR');

SET @country_id = (SELECT internal_id FROM country WHERE country_code = 'IN');

INSERT IGNORE INTO province (province_code, province_name, thisobject2country)
VALUES ('KA', 'Karnataka', @country_id);

SET @province_id = (SELECT internal_id FROM province WHERE province_code = 'KA');

INSERT IGNORE INTO city (city_code, city_name, thisobject2province)
VALUES ('BLR', 'Bengaluru', @province_id);

SET @city_id = (SELECT internal_id FROM city WHERE city_code = 'BLR');

-- Seed a company we'll use throughout the demo
INSERT IGNORE INTO company (company_name, gst_no, company_email)
VALUES ('Demo Corp', 'DEMO_GST_001', 'demo@corp.com');

SET @company_id = (SELECT internal_id FROM company WHERE gst_no = 'DEMO_GST_001');

-- ============================================================
-- STEP 1: UNNORMALIZED TABLE SIMULATION
-- ============================================================
-- This flat table mirrors what a poorly designed system looks like
-- before any normalization is applied.
-- Violations present:
--   • phone1, phone2 → repeating group           (1NF violation)
--   • dept_name duplicated per employee           (update anomaly)
--   • company_name duplicated per employee        (transitive dependency via dept)

DROP TEMPORARY TABLE IF EXISTS unnormalized_employee_data;

CREATE TEMPORARY TABLE unnormalized_employee_data (
    emp_id       INT,
    emp_name     VARCHAR(200),
    emp_email    VARCHAR(100),
    dept_code    VARCHAR(20),
    dept_name    VARCHAR(100),   -- ❌ repeated every row — not determined by emp_id alone
    company_name VARCHAR(150),   -- ❌ repeated every row — transitive via dept_code → company
    phone1       VARCHAR(30),    -- ❌ repeating group: phone1, phone2 in same row
    phone2       VARCHAR(30)     -- ❌ NULL when employee has only one number
);

-- Three rows show real-world redundancy:
--   • Rows 1 and 2: same dept_code='HR', same dept_name='Human Resources', same company
--     → dept_name is stored twice — update anomaly waiting to happen
--   • Row 2: phone2 is NULL — wasted column
--   • Row 3: different dept, same company — company_name duplicated again

INSERT INTO unnormalized_employee_data
  (emp_id, emp_name,          emp_email,              dept_code, dept_name,          company_name, phone1,          phone2)
VALUES
  (1,      'Alice Menon',     'alice@demo.com',        'HR',      'Human Resources',  'Demo Corp',  '+919876543210', '+918025551234'),
  (2,      'Bob Sharma',      'bob@demo.com',           'HR',      'Human Resources',  'Demo Corp',  '+919123456789', NULL),
  (3,      'Carol Nair',      'carol@demo.com',         'ENG',     'Engineering',      'Demo Corp',  '+919988776655', '+918044441111');

-- ── Snapshot of the unnormalized data ─────────────────────
SELECT '=== UNNORMALIZED TABLE (before any fix) ===' AS info;
SELECT * FROM unnormalized_employee_data;

-- ============================================================
-- STEP 2: DEMONSTRATE ANOMALIES USING UPDATE / DELETE
-- ============================================================

-- ── 2-A  UPDATE ANOMALY ───────────────────────────────────
-- Business requirement: rename 'Human Resources' → 'HR Operations'
-- In a normalized schema this is ONE update on the department row.
-- In this flat table it must touch EVERY employee in that department.

SELECT '=== UPDATE ANOMALY: renaming dept affects multiple rows ===' AS info;

UPDATE unnormalized_employee_data
SET    dept_name = 'HR Operations'
WHERE  dept_code = 'HR';

-- ROW_COUNT() tells us how many rows were touched.
-- 2 rows updated = 2 redundant copies of the same fact.
-- If we forgot row 2, or a network error interrupted after row 1,
-- the database would contain TWO different names for the same dept.
SELECT ROW_COUNT()                        AS rows_affected,
       'rows_affected > 1 = UPDATE ANOMALY, data was duplicated' AS anomaly_explanation;

SELECT dept_code, dept_name, emp_name
FROM   unnormalized_employee_data
ORDER BY dept_code;

-- ── 2-B  INSERTION ANOMALY ────────────────────────────────
-- We cannot create a new department 'Finance' until at least one
-- employee joins it — there is no other row to hold it.
-- Attempting to insert a dept-only row leaves emp_id, emp_email NULL
-- which violates real-world business rules.
SELECT '=== INSERTION ANOMALY: cannot store a dept without an employee ===' AS info;

INSERT INTO unnormalized_employee_data (emp_id, emp_name, emp_email, dept_code, dept_name, company_name, phone1, phone2)
VALUES (NULL, NULL, NULL, 'FIN', 'Finance', 'Demo Corp', NULL, NULL);
-- Row exists but emp_id=NULL, emp_name=NULL → meaningless / corrupt

SELECT * FROM unnormalized_employee_data WHERE dept_code = 'FIN';

-- Clean up the corrupt row before proceeding
DELETE FROM unnormalized_employee_data WHERE dept_code = 'FIN';

-- ── 2-C  DELETION ANOMALY ────────────────────────────────
-- If Carol (the only Engineering employee) is deleted,
-- the fact that 'Engineering' belongs to 'Demo Corp' is also deleted.
SELECT '=== DELETION ANOMALY: deleting last employee in dept destroys dept info ===' AS info;

-- Save Carol's data first so we can restore her for later steps
SET @carol_id       = 3;
SET @carol_name     = 'Carol Nair';
SET @carol_email    = 'carol@demo.com';
SET @carol_dept     = 'ENG';
SET @carol_deptname = 'Engineering';

DELETE FROM unnormalized_employee_data WHERE emp_id = 3;

-- Engineering department info is now gone from the database
SELECT COUNT(*) AS engineering_rows,
       'Engineering lost — dept info deleted with last employee' AS anomaly_explanation
FROM   unnormalized_employee_data
WHERE  dept_code = 'ENG';

-- Restore Carol for the normalization steps below
INSERT INTO unnormalized_employee_data VALUES
  (3, 'Carol Nair', 'carol@demo.com', 'ENG', 'Engineering', 'Demo Corp', '+919988776655', '+918044441111');

SELECT '=== Restored Carol. Proceeding to normalization. ===' AS info;

-- ============================================================
-- STEP 3: DECOMPOSE TO 1NF
-- Fix: phone1, phone2 (repeating group) → individual rows
--      in phone_number + individual_phone_map
-- ============================================================

SELECT '=== STEP 3: 1NF — flatten repeating phone groups ===' AS info;

-- 3-A: Insert employees into individual (identity only, no phones, no dept)
--      Split emp_name on space to populate first_name / last_name
INSERT INTO individual (first_name, last_name, email, person_type, thisobject2company)
SELECT
    SUBSTRING_INDEX(emp_name, ' ', 1),       -- first_name
    SUBSTRING_INDEX(emp_name, ' ', -1),      -- last_name
    emp_email,
    'EMPLOYEE',
    @company_id
FROM unnormalized_employee_data
ON DUPLICATE KEY UPDATE email = VALUES(email);  -- idempotent re-run safety

-- Capture inserted IDs using a mapping table
CREATE TEMPORARY TABLE IF NOT EXISTS emp_id_map (
    old_emp_id  INT,
    new_ind_id  INT
);
TRUNCATE emp_id_map;

INSERT INTO emp_id_map (old_emp_id, new_ind_id)
SELECT u.emp_id, i.internal_id
FROM   unnormalized_employee_data u
JOIN   individual i ON i.email = u.emp_email;

SELECT '--- individual rows inserted ---' AS info;
SELECT i.internal_id, i.first_name, i.last_name, i.email
FROM   individual i
JOIN   emp_id_map m ON m.new_ind_id = i.internal_id;

-- 3-B: Insert phone1 rows into phone_number (phone1 is always present)
INSERT INTO phone_number (country_dial_code, phone_number, phone_type)
SELECT
    LEFT(phone1, 3),               -- e.g. '+91'
    SUBSTRING(phone1, 4),          -- remaining digits
    'MOBILE'
FROM unnormalized_employee_data
WHERE phone1 IS NOT NULL;

-- 3-C: Insert phone2 rows (only where phone2 is not NULL)
INSERT INTO phone_number (country_dial_code, phone_number, phone_type)
SELECT
    LEFT(phone2, 3),
    SUBSTRING(phone2, 4),
    'OFFICE'
FROM unnormalized_employee_data
WHERE phone2 IS NOT NULL;

-- 3-D: Link each individual to their phone1 via individual_phone_map
INSERT INTO individual_phone_map (thisobject2individual, thisobject2phone, is_primary)
SELECT
    m.new_ind_id,
    pn.internal_id,
    TRUE                           -- phone1 is primary
FROM   unnormalized_employee_data  u
JOIN   emp_id_map                  m  ON m.old_emp_id = u.emp_id
JOIN   phone_number                pn ON pn.phone_number = SUBSTRING(u.phone1, 4)
WHERE  u.phone1 IS NOT NULL;

-- 3-E: Link each individual to their phone2 (is_primary = FALSE)
INSERT INTO individual_phone_map (thisobject2individual, thisobject2phone, is_primary)
SELECT
    m.new_ind_id,
    pn.internal_id,
    FALSE
FROM   unnormalized_employee_data  u
JOIN   emp_id_map                  m  ON m.old_emp_id = u.emp_id
JOIN   phone_number                pn ON pn.phone_number = SUBSTRING(u.phone2, 4)
WHERE  u.phone2 IS NOT NULL;

SELECT '--- 1NF achieved: phone_number rows ---' AS info;
SELECT pn.internal_id, pn.country_dial_code, pn.phone_number, pn.phone_type,
       ipm.is_primary,
       CONCAT(i.first_name, ' ', i.last_name) AS belongs_to
FROM   phone_number          pn
JOIN   individual_phone_map  ipm ON ipm.thisobject2phone    = pn.internal_id
JOIN   individual            i   ON i.internal_id           = ipm.thisobject2individual
JOIN   emp_id_map            m   ON m.new_ind_id            = i.internal_id;

-- ============================================================
-- STEP 4: DECOMPOSE TO 2NF
-- Fix: dept_name depends on dept_code alone, not on emp_id
--      → partial dependency removed by inserting into department
-- ============================================================

SELECT '=== STEP 4: 2NF — remove partial dependency: dept_name → department table ===' AS info;

-- dept_code is the natural key for department.
-- dept_name is fully determined by dept_code — not by any employee attribute.
-- INSERT IGNORE prevents duplicates when re-running the script.

INSERT IGNORE INTO department (dept_code, dept_name, thisobject2company)
SELECT DISTINCT
    dept_code,
    dept_name,
    @company_id
FROM unnormalized_employee_data;

SELECT '--- department rows after 2NF decomposition ---' AS info;
SELECT internal_id, dept_code, dept_name, thisobject2company
FROM   department
WHERE  thisobject2company = @company_id;

-- Proof: updating the dept name now touches exactly ONE row
UPDATE department
SET    dept_name = 'HR Operations'
WHERE  dept_code = 'HR'
  AND  thisobject2company = @company_id;

SELECT ROW_COUNT()                                                  AS rows_affected,
       'rows_affected = 1 = update anomaly eliminated by 2NF'       AS result;

-- Revert for cleaner demo state
UPDATE department SET dept_name = 'Human Resources' WHERE dept_code = 'HR' AND thisobject2company = @company_id;

-- ============================================================
-- STEP 5: DECOMPOSE TO 3NF
-- Fix: dept_name was transitively determined via dept_code (a non-key)
--      individual.internal_id → dept_code → dept_name
--      Solution: individual never directly owns dept info.
--      The assignment lives in individual_department_map.
-- ============================================================

SELECT '=== STEP 5: 3NF — remove transitive dependency via individual_department_map ===' AS info;

-- The transitive chain in the flat table was:
--   emp_id → dept_code → dept_name → company_name
--
-- After 3NF:
--   individual stores only personal identity
--   department stores only dept identity
--   individual_department_map records the assignment episode

INSERT INTO individual_department_map (thisobject2individual, thisobject2department, start_date, status)
SELECT
    m.new_ind_id,
    d.internal_id,
    CURDATE(),
    'ACTIVE'
FROM   unnormalized_employee_data u
JOIN   emp_id_map                 m ON m.old_emp_id        = u.emp_id
JOIN   department                 d ON d.dept_code         = u.dept_code
                                   AND d.thisobject2company = @company_id;

SELECT '--- individual_department_map rows after 3NF decomposition ---' AS info;
SELECT
    idm.internal_id,
    CONCAT(i.first_name, ' ', i.last_name) AS employee,
    d.dept_code,
    d.dept_name,
    idm.start_date,
    idm.status
FROM   individual_department_map idm
JOIN   individual                i ON i.internal_id  = idm.thisobject2individual
JOIN   department                d ON d.internal_id  = idm.thisobject2department
JOIN   emp_id_map                m ON m.new_ind_id   = i.internal_id;

-- ============================================================
-- STEP 6: VERIFY — Reconstruct the original unnormalized view
--         via JOIN across normalized tables
--         Proves no data was lost during decomposition
-- ============================================================

SELECT '=== STEP 6: VERIFICATION — reconstructed view matches original ===' AS info;

-- This single SELECT reproduces every column from unnormalized_employee_data
-- by joining the four normalized tables.
-- Two phone rows per employee are collapsed back to phone1/phone2 columns
-- using conditional aggregation.

SELECT
    i.internal_id                               AS emp_id,
    CONCAT(i.first_name, ' ', i.last_name)      AS emp_name,
    i.email                                     AS emp_email,
    d.dept_code,
    d.dept_name,
    c.company_name,
    MAX(CASE WHEN ipm.is_primary = TRUE
             THEN CONCAT(pn.country_dial_code, pn.phone_number)
        END)                                    AS phone1,
    MAX(CASE WHEN ipm.is_primary = FALSE
             THEN CONCAT(pn.country_dial_code, pn.phone_number)
        END)                                    AS phone2
FROM       individual               i
JOIN       emp_id_map               m   ON m.new_ind_id             = i.internal_id
JOIN       company                  c   ON c.internal_id            = i.thisobject2company
JOIN       individual_department_map idm ON idm.thisobject2individual = i.internal_id
JOIN       department               d   ON d.internal_id            = idm.thisobject2department
LEFT JOIN  individual_phone_map     ipm ON ipm.thisobject2individual = i.internal_id
LEFT JOIN  phone_number             pn  ON pn.internal_id           = ipm.thisobject2phone
WHERE      i.thisobject2company = @company_id
GROUP BY   i.internal_id, i.first_name, i.last_name, i.email,
           d.dept_code, d.dept_name, c.company_name
ORDER BY   i.internal_id;

-- Side-by-side comparison: original vs reconstructed
SELECT '--- Original unnormalized rows ---' AS info;
SELECT emp_id, emp_name, emp_email, dept_code, dept_name, company_name, phone1, phone2
FROM   unnormalized_employee_data
ORDER BY emp_id;

-- ============================================================
-- CLEANUP: Remove demo data inserted above
-- (Reverses all inserts in FK-safe order)
-- ============================================================

SELECT '=== CLEANUP: removing demo rows ===' AS info;

-- Remove map entries first (children before parents)
DELETE ipm FROM individual_phone_map ipm
JOIN   emp_id_map m ON m.new_ind_id = ipm.thisobject2individual;

DELETE idm FROM individual_department_map idm
JOIN   emp_id_map m ON m.new_ind_id = idm.thisobject2individual;

-- Remove phone_number rows that were linked to our demo individuals
DELETE pn FROM phone_number pn
WHERE  pn.phone_number IN (
    SELECT SUBSTRING(u.phone1, 4) FROM unnormalized_employee_data u WHERE u.phone1 IS NOT NULL
    UNION
    SELECT SUBSTRING(u.phone2, 4) FROM unnormalized_employee_data u WHERE u.phone2 IS NOT NULL
);

-- Remove individual rows
DELETE i FROM individual i
JOIN   emp_id_map m ON m.new_ind_id = i.internal_id;

-- Remove department rows inserted for this demo
DELETE FROM department
WHERE  thisobject2company = @company_id;

-- Remove company and location data
DELETE FROM company  WHERE internal_id = @company_id;
DELETE FROM city     WHERE city_code   = 'BLR';
DELETE FROM province WHERE province_code = 'KA';
DELETE FROM country  WHERE country_code  = 'IN';

DROP TEMPORARY TABLE IF EXISTS emp_id_map;
DROP TEMPORARY TABLE IF EXISTS unnormalized_employee_data;


-- ============================================================
-- APPENDIX: ADDRESS TABLE — zipcode transitive dependency
-- ============================================================

SELECT '=== APPENDIX: address table — zipcode → city transitive dependency ===' AS info;

-- Current address table schema (from 01_tables_core.sql):
--   address(internal_id, building_no, address_line1, address_line2,
--           area, zipcode, address_type, thisobject2city)
--
-- The real-world FD:
--   zipcode → area, thisobject2city
--
-- This creates a transitive chain:
--   internal_id → zipcode → area
--   internal_id → zipcode → thisobject2city
--
-- Meaning: area and the city FK are not directly determined by internal_id alone —
-- they're determined via the intermediate non-key attribute zipcode.
-- Strict 3NF requires we extract zipcode into its own table.

-- ── Demonstration of the anomaly ──────────────────────────
-- Simulate two address rows sharing zipcode '560001':

INSERT IGNORE INTO city (city_code, city_name, thisobject2province)
SELECT 'BLR2', 'Bengaluru', p.internal_id
FROM   province p WHERE p.province_code = 'KA'
LIMIT 1;

SET @demo_city = (SELECT internal_id FROM city WHERE city_code = 'BLR2');

-- Two address rows, same zipcode — area and city_id are redundant
INSERT INTO address (building_no, address_line1, area, zipcode, address_type, thisobject2city)
VALUES
  ('10',  'MG Road',        'Bangalore Central', '560001', 'OFFICE',  @demo_city),
  ('22',  'Brigade Street', 'Bangalore Central', '560001', 'BILLING', @demo_city);

SELECT 'Addresses sharing zipcode 560001 — area and city_id are duplicated:' AS issue;
SELECT internal_id, building_no, address_line1, area, zipcode, thisobject2city
FROM   address
WHERE  zipcode = '560001';

-- Update anomaly: if postal authority changes area name for zipcode 560001:
UPDATE address SET area = 'Central Bengaluru' WHERE zipcode = '560001';

SELECT ROW_COUNT() AS rows_affected,
       '> 1 means area was stored redundantly — classic 3NF update anomaly' AS explanation;

-- Revert
UPDATE address SET area = 'Bangalore Central' WHERE zipcode = '560001';

-- ── What a 3NF-compliant fix looks like ───────────────────
-- (shown as a definition; we document WHY we do not implement it)

/*
  STRICT 3NF DECOMPOSITION — zipcode_master

  CREATE TABLE zipcode_master (
      zipcode         VARCHAR(20) PRIMARY KEY,
      area            VARCHAR(100),
      thisobject2city INT NOT NULL,
      FOREIGN KEY (thisobject2city) REFERENCES city(internal_id)
  );

  Then address becomes:
  CREATE TABLE address (
      internal_id   INT AUTO_INCREMENT PRIMARY KEY,
      building_no   VARCHAR(50),
      address_line1 VARCHAR(255),
      address_line2 VARCHAR(255),
      address_type  VARCHAR(50),
      zipcode       VARCHAR(20) NOT NULL,
      FOREIGN KEY (zipcode) REFERENCES zipcode_master(zipcode)
      -- area and thisobject2city removed — both live in zipcode_master
  );

  Migration:
  INSERT INTO zipcode_master (zipcode, area, thisobject2city)
  SELECT DISTINCT zipcode, area, thisobject2city
  FROM   address;

  ALTER TABLE address
    DROP COLUMN area,
    DROP COLUMN thisobject2city,
    ADD  CONSTRAINT fk_address_zipcode
         FOREIGN KEY (zipcode) REFERENCES zipcode_master(zipcode);
*/

-- ── Why we kept address DENORMALIZED (design decision) ────
SELECT 'DESIGN DECISION: why zipcode_master was NOT implemented' AS heading;

SELECT
'Reason 1 — Data quality: India has ~19,000 pincodes. A zipcode does not '
 || 'reliably determine one city — postal circles overlap city boundaries. '
 || 'Mapping zipcode → city_id requires a constantly updated authoritative dataset.'
 AS reason_1,
'Reason 2 — Asset system scope: This is an internal IT asset tracker, not a '
 || 'postal or logistics application. Address data is entered manually by admins '
 || 'for a small number of company/vendor locations. The anomaly risk is low '
 || 'because very few addresses share a zipcode in practice.'
 AS reason_2,
'Reason 3 — Query cost: Every address lookup would require an extra JOIN to '
 || 'zipcode_master. The benefit (eliminating a rarely-updated area column) does '
 || 'not justify the join overhead and added schema complexity for this use case.'
 AS reason_3,
'Mitigation applied: The address table is NEVER modified directly by end users. '
 || 'Only admin-level inserts via the procurement module touch it. An application-'
 || 'level UNIQUE check on (zipcode, area, thisobject2city) would catch accidental '
 || 'inconsistencies at insert time without requiring the extra table.'
 AS mitigation;

-- Demonstrate the ALTER TABLE command that WOULD add the column if we chose to:
-- ALTER TABLE address ADD COLUMN zipcode_city_id INT AFTER zipcode;
-- ALTER TABLE address ADD CONSTRAINT fk_addr_zipcode_city
--     FOREIGN KEY (zipcode_city_id) REFERENCES city(internal_id);
-- (Not executed — documented here as the migration path if the decision changes)

-- Cleanup appendix data
DELETE FROM address WHERE zipcode = '560001';
DELETE FROM city    WHERE city_code = 'BLR2';

SELECT '=== Normalization demo complete ===' AS info;
