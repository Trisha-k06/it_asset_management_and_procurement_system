-- USE it_asset_mgmt_db;
-- SHOW TABLES;
-- SELECT 
--     table_name,
--     column_name,
--     column_type,
--     is_nullable,
--     column_key,
--     extra
-- FROM information_schema.columns
-- WHERE table_schema = DATABASE()
-- ORDER BY table_name, ordinal_position;
 
 USE it_asset_mgmt_db;
-- 10 simple queries
 SELECT * FROM asset;

SELECT * FROM individual;

SELECT * FROM department;

SELECT * FROM vendor_master;

SELECT asset_tag, serial_no, make, asset_model, purchase_cost
FROM asset;

SELECT first_name, last_name, email, person_type
FROM individual;

SELECT dept_code, dept_name
FROM department;

SELECT po_number, po_date, status, total_amount
FROM purchase_order_header;

SELECT product_name, manufacturer, model, category
FROM product_master;

SELECT quotation_number, quotation_date, quotation_total_value
FROM vendor_quotation_scan;
