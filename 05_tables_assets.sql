USE it_asset_mgmt_db;

-- PRODUCT TABLES
CREATE TABLE product_master (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE product_specification (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2product INT NOT NULL,
    spec_key VARCHAR(100) NOT NULL,
    spec_value VARCHAR(255) NOT NULL
);

-- ASSET MASTER TABLES
CREATE TABLE asset_type_master (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255)
);

CREATE TABLE asset_subtype_master (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    subtype_name VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    thisobject2asset_type INT NOT NULL
);

CREATE TABLE asset_status (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    status_name VARCHAR(50) UNIQUE NOT NULL
);

-- ASSET CORE
CREATE TABLE asset (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    asset_tag VARCHAR(50) UNIQUE NOT NULL,
    serial_no VARCHAR(50) UNIQUE,
    make VARCHAR(100),
    asset_model VARCHAR(100),
    purchase_cost DECIMAL(12,2),
    warranty_start DATE,
    warranty_end DATE,
    thisobject2subtype INT NOT NULL,
    thisobject2status INT NOT NULL
);

-- ASSET ALLOCATION
CREATE TABLE asset_allocation (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2asset INT NOT NULL,
    thisobject2individual INT,
    allocation_type VARCHAR(50),
    allocated_on DATE,
    expected_return_date DATE,
    actual_return_date DATE,
    allocation_status VARCHAR(50)
);

-- MAINTENANCE
CREATE TABLE maintenance_record (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2asset INT NOT NULL,
    maintenance_date DATE,
    description VARCHAR(255),
    cost DECIMAL(10,2),
    status VARCHAR(50)
);
SHOW TABLES;