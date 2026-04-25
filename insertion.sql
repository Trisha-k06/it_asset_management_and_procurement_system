INSERT INTO asset_status (status_name)
VALUES ('Available'), ('Allocated'), ('Under Maintenance');

INSERT INTO asset_type_master (type_name, description)
VALUES ('IT Equipment', 'Technology assets');

INSERT INTO asset_subtype_master (subtype_name, description, thisobject2asset_type)
VALUES ('Laptop', 'Portable device', 1);

INSERT INTO department (dept_code, dept_name, thisobject2company)
VALUES
('IT01', 'IT Department', 1),
('HR01', 'HR Department', 2),
('FN01', 'Finance Department', 3);

INSERT INTO product_master (product_name, manufacturer, model, category, is_active)
VALUES
('Dell Latitude 5440', 'Dell', 'Latitude 5440', 'Laptop', 1),
('HP ProBook 440', 'HP', 'ProBook 440', 'Laptop', 1);

INSERT INTO product_specification (thisobject2product, spec_key, spec_value)
VALUES
(1, 'RAM', '16GB'),
(1, 'Storage', '512GB SSD'),
(2, 'RAM', '8GB'),
(2, 'Storage', '256GB SSD');

INSERT INTO asset (
    asset_tag,
    serial_no,
    make,
    asset_model,
    purchase_cost,
    warranty_start,
    warranty_end,
    thisobject2subtype,
    thisobject2status
)
VALUES
('AST001', 'SN001', 'Dell', 'Latitude 5440', 65000.00, '2025-01-01', '2027-01-01', 1, 1),
('AST002', 'SN002', 'HP', 'ProBook 440', 58000.00, '2025-02-01', '2027-02-01', 1, 2),
('AST003', 'SN003', 'Dell', 'Vostro 3520', 52000.00, '2025-03-01', '2027-03-01', 1, 3);

SELECT internal_id, first_name, last_name, thisobject2company
FROM individual
LIMIT 10;

INSERT INTO individual_department_map (
    thisobject2individual,
    thisobject2department,
    start_date,
    status
)
VALUES
(1, 1, CURDATE(), 'Active'),
(2, 2, CURDATE(), 'Active'),
(3, 3, CURDATE(), 'Active');

INSERT INTO asset_allocation (
    thisobject2asset,
    thisobject2individual,
    allocation_type,
    allocated_on,
    allocation_status,
    thisobject2department,
    custodian_type
)
VALUES
(1, 1, 'Employee Allocation', CURDATE(), 'Allocated', 1, 'INDIVIDUAL'),
(2, 2, 'Employee Allocation', CURDATE(), 'Allocated', 2, 'INDIVIDUAL');

INSERT INTO purchase_order_detail (
    thisobject2po,
    item_description,
    quantity,
    unit_price,
    gst_amount,
    total_price
)
VALUES
(16, 'Dell Latitude 5440 Laptop', 2, 55000.00, 9900.00, 119900.00),
(17, 'HP ProBook 440 Laptop', 1, 50000.00, 9000.00, 59000.00);

INSERT INTO goods_receipt_header (grn_date, thisobject2po)
VALUES
(CURDATE(), 16),
(CURDATE(), 17);

SELECT * FROM goods_receipt_header;
SELECT * FROM purchase_order_detail;

SELECT * FROM goods_receipt_header;

INSERT INTO goods_receipt_detail (thisobject2grn, thisobject2podetail, qty_received)
VALUES
(1, 1, 2),
(2, 2, 1);

SELECT * FROM goods_receipt_detail;

INSERT INTO maintenance_record (
    thisobject2asset,
    maintenance_date,
    description,
    cost,
    status
)
VALUES
(1, CURDATE(), 'Routine service', 1200.00, 'Completed'),
(2, CURDATE(), 'Keyboard replacement', 1800.00, 'Pending');

INSERT INTO role (role_name)
VALUES ('Admin'), ('Manager'), ('Employee');

INSERT INTO user_account (username, password_hash, account_status)
VALUES
('admin1', 'hash_admin1', 'Active'),
('manager1', 'hash_manager1', 'Active'),
('user1', 'hash_user1', 'Active');

SELECT * FROM role;
SELECT * FROM user_account;

INSERT INTO user_role_map (thisobject2user, thisobject2role)
VALUES
(1, 1),
(2, 2),
(3, 3);

SELECT 'asset' AS table_name, COUNT(*) AS total_rows FROM asset
UNION ALL
SELECT 'asset_allocation', COUNT(*) FROM asset_allocation
UNION ALL
SELECT 'asset_status', COUNT(*) FROM asset_status
UNION ALL
SELECT 'asset_subtype_master', COUNT(*) FROM asset_subtype_master
UNION ALL
SELECT 'asset_type_master', COUNT(*) FROM asset_type_master
UNION ALL
SELECT 'department', COUNT(*) FROM department
UNION ALL
SELECT 'goods_receipt_detail', COUNT(*) FROM goods_receipt_detail
UNION ALL
SELECT 'goods_receipt_header', COUNT(*) FROM goods_receipt_header
UNION ALL
SELECT 'individual_department_map', COUNT(*) FROM individual_department_map
UNION ALL
SELECT 'maintenance_record', COUNT(*) FROM maintenance_record
UNION ALL
SELECT 'product_master', COUNT(*) FROM product_master
UNION ALL
SELECT 'product_specification', COUNT(*) FROM product_specification
UNION ALL
SELECT 'purchase_order_detail', COUNT(*) FROM purchase_order_detail
UNION ALL
SELECT 'role', COUNT(*) FROM role
UNION ALL
SELECT 'user_account', COUNT(*) FROM user_account
UNION ALL
SELECT 'user_role_map', COUNT(*) FROM user_role_map;