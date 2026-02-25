USE it_asset_mgmt_db;

CREATE TABLE vendor_master (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_name VARCHAR(150) NOT NULL,
    gst_no VARCHAR(20) UNIQUE,
    vendor_email VARCHAR(100)
);

CREATE TABLE vendor_address_map (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2vendor INT NOT NULL,
    thisobject2address INT NOT NULL,
    is_primary BOOLEAN
);

CREATE TABLE vendor_quotation_scan (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    quotation_number VARCHAR(50) UNIQUE NOT NULL,
    quotation_date DATE,
    quotation_total_value DECIMAL(12,2),
    thisobject2vendor INT NOT NULL
);

CREATE TABLE purchase_order_header (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    po_number VARCHAR(50) UNIQUE NOT NULL,
    po_date DATE,
    status VARCHAR(50),
    thisobject2vendor INT NOT NULL
);

CREATE TABLE purchase_order_detail (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2po INT NOT NULL,
    item_description VARCHAR(255),
    quantity INT,
    unit_price DECIMAL(10,2),
    gst_amount DECIMAL(10,2),
    total_price DECIMAL(12,2)
);

CREATE TABLE goods_receipt_header (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    grn_date DATE,
    thisobject2po INT NOT NULL
);

CREATE TABLE goods_receipt_detail (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2grn INT NOT NULL,
    thisobject2podetail INT NOT NULL,
    qty_received INT
);
