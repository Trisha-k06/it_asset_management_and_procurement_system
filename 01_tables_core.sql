USE it_asset_mgmt_db;

CREATE TABLE country (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    country_code VARCHAR(10) UNIQUE NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    currency VARCHAR(50)
);

CREATE TABLE province (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    province_code VARCHAR(10) UNIQUE NOT NULL,
    province_name VARCHAR(100) NOT NULL,
    thisobject2country INT NOT NULL
);

CREATE TABLE city (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    city_code VARCHAR(10) UNIQUE NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    thisobject2province INT NOT NULL
);

CREATE TABLE address (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    building_no VARCHAR(50),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    area VARCHAR(100),
    zipcode VARCHAR(20),
    address_type VARCHAR(50),
    thisobject2city INT NOT NULL
);
SHOW TABLES;
SHOW TABLES;

