USE it_asset_mgmt_db;
SET SQL_SAFE_UPDATES = 0;

INSERT IGNORE INTO country (country_code, country_name, currency)
VALUES ('IN', 'India', 'INR');

SET @country_id = (SELECT internal_id FROM country WHERE country_code = 'IN');

INSERT IGNORE INTO province (province_code, province_name, thisobject2country)
VALUES ('KA', 'Karnataka', @country_id);

SET @province_id = (SELECT internal_id FROM province WHERE province_code = 'KA');

INSERT IGNORE INTO city (city_code, city_name, thisobject2province)
VALUES ('BLR', 'Bengaluru', @province_id);

SET @city_id = (SELECT internal_id FROM city WHERE city_code = 'BLR');


INSERT IGNORE INTO company (company_name, gst_no, company_email)
VALUES ('Demo Corp', 'DEMO_GST_001', 'demo@corp.com');

SET @company_id = (SELECT internal_id FROM company WHERE gst_no = 'DEMO_GST_001');



DROP TEMPORARY TABLE IF EXISTS unnormalized_employee_data;

CREATE TEMPORARY TABLE unnormalized_employee_data (
    emp_id       INT,
    emp_name     VARCHAR(200),
    emp_email    VARCHAR(100),
    dept_code    VARCHAR(20),
    dept_name    VARCHAR(100),   
    company_name VARCHAR(150),   
    phone1       VARCHAR(30),   
    phone2       VARCHAR(30)     
);


INSERT INTO unnormalized_employee_data
  (emp_id, emp_name,          emp_email,              dept_code, dept_name,          company_name, phone1,          phone2)
VALUES
  (1,      'Alice Menon',     'alice@demo.com',        'HR',      'Human Resources',  'Demo Corp',  '+919876543210', '+918025551234'),
  (2,      'Bob Sharma',      'bob@demo.com',           'HR',      'Human Resources',  'Demo Corp',  '+919123456789', NULL),
  (3,      'Carol Nair',      'carol@demo.com',         'ENG',     'Engineering',      'Demo Corp',  '+919988776655', '+918044441111');


SELECT '=== UNNORMALIZED TABLE (before any fix) ===' AS info;
SELECT * FROM unnormalized_employee_data;


--  DEMONSTRATE ANOMALIES USING UPDATE / DELETE


-- 2-A  UPDATE ANOMALY 
-- Business requirement: rename 'Human Resources' → 'HR Operations'
-- In a normalized schema this is ONE update on the department row.
-- In this flat table it must touch EVERY employee in that department.

SELECT '=== UPDATE ANOMALY: renaming dept affects multiple rows ===' AS info;

UPDATE unnormalized_employee_data
SET    dept_name = 'HR Operations'
WHERE  dept_code = 'HR';


SELECT ROW_COUNT()                        AS rows_affected,
       'rows_affected > 1 = UPDATE ANOMALY, data was duplicated' AS anomaly_explanation;

SELECT dept_code, dept_name, emp_name
FROM   unnormalized_employee_data
ORDER BY dept_code;

-- INSERTION ANOMALY 
SELECT '=== INSERTION ANOMALY: cannot store a dept without an employee ===' AS info;

INSERT INTO unnormalized_employee_data (emp_id, emp_name, emp_email, dept_code, dept_name, company_name, phone1, phone2)
VALUES (NULL, NULL, NULL, 'FIN', 'Finance', 'Demo Corp', NULL, NULL);


SELECT * FROM unnormalized_employee_data WHERE dept_code = 'FIN';


DELETE FROM unnormalized_employee_data WHERE dept_code = 'FIN';

-- ── DELETION ANOMALY 
SELECT '=== DELETION ANOMALY: deleting last employee in dept destroys dept info ===' AS info;


SET @carol_id       = 3;
SET @carol_name     = 'Carol Nair';
SET @carol_email    = 'carol@demo.com';
SET @carol_dept     = 'ENG';
SET @carol_deptname = 'Engineering';

DELETE FROM unnormalized_employee_data WHERE emp_id = 3;


SELECT COUNT(*) AS engineering_rows,
       'Engineering lost — dept info deleted with last employee' AS anomaly_explanation
FROM   unnormalized_employee_data
WHERE  dept_code = 'ENG';


INSERT INTO unnormalized_employee_data VALUES
  (3, 'Carol Nair', 'carol@demo.com', 'ENG', 'Engineering', 'Demo Corp', '+919988776655', '+918044441111');

SELECT '=== Restored Carol. Proceeding to normalization. ===' AS info;



SELECT '=== STEP 3: 1NF — flatten repeating phone groups ===' AS info;


INSERT INTO individual (first_name, last_name, email, person_type, thisobject2company)
SELECT
    SUBSTRING_INDEX(emp_name, ' ', 1),      
    SUBSTRING_INDEX(emp_name, ' ', -1),     
    emp_email,
    'EMPLOYEE',
    @company_id
FROM unnormalized_employee_data
ON DUPLICATE KEY UPDATE email = VALUES(email);  

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


INSERT INTO phone_number (country_dial_code, phone_number, phone_type)
SELECT
    LEFT(phone1, 3),               
    SUBSTRING(phone1, 4),          
    'MOBILE'
FROM unnormalized_employee_data
WHERE phone1 IS NOT NULL;


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
    TRUE                          
FROM   unnormalized_employee_data  u
JOIN   emp_id_map                  m  ON m.old_emp_id = u.emp_id
JOIN   phone_number                pn ON pn.phone_number = SUBSTRING(u.phone1, 4)
WHERE  u.phone1 IS NOT NULL;


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


-- DECOMPOSE TO 2NF
--  dept_name depends on dept_code alone, not on emp_id
--      partial dependency removed by inserting into department


SELECT '===  2NF — remove partial dependency: dept_name → department table ===' AS info;

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


UPDATE department
SET    dept_name = 'HR Operations'
WHERE  dept_code = 'HR'
  AND  thisobject2company = @company_id;

SELECT ROW_COUNT()                                                  AS rows_affected,
       'rows_affected = 1 = update anomaly eliminated by 2NF'       AS result;


UPDATE department SET dept_name = 'Human Resources' WHERE dept_code = 'HR' AND thisobject2company = @company_id;

-- DECOMPOSE TO 3NF
-- dept_name was transitively determined via dept_code (a non-key)
--      individual.internal_id → dept_code → dept_name
--      Solution: individual never directly owns dept info.
--      The assignment lives in individual_department_map.


SELECT ' 3NF — remove transitive dependency via individual_department_map ===' AS info;

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


SELECT 'VERIFICATION — reconstructed view matches original ===' AS info;

-- This single SELECT reproduces every column from unnormalized_employee_data
-- by joining the four normalized tables.
-- Two phone rows per employee are collapsed back to phone1/phone2 columns

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


--  Remove demo data inserted above



SELECT '=== CLEANUP: removing demo rows ===' AS info;


DELETE ipm FROM individual_phone_map ipm
JOIN   emp_id_map m ON m.new_ind_id = ipm.thisobject2individual;

DELETE idm FROM individual_department_map idm
JOIN   emp_id_map m ON m.new_ind_id = idm.thisobject2individual;

DELETE pn FROM phone_number pn
JOIN individual_phone_map ipm ON ipm.thisobject2phone = pn.internal_id
JOIN emp_id_map m ON m.new_ind_id = ipm.thisobject2individual;

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

SET SQL_SAFE_UPDATES = 1;