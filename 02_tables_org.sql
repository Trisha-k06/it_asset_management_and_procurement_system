USE it_asset_mgmt_db;

CREATE TABLE company (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    gst_no VARCHAR(20) UNIQUE,
    company_email VARCHAR(100) UNIQUE
);

CREATE TABLE site (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    site_name VARCHAR(100) NOT NULL,
    site_type VARCHAR(50),
    thisobject2company INT NOT NULL,
    parent_site_id INT
);

CREATE TABLE department (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_code VARCHAR(20) UNIQUE NOT NULL,
    dept_name VARCHAR(100) NOT NULL,
    thisobject2company INT NOT NULL,
    parent_dept_id INT
);

CREATE TABLE individual (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    person_type VARCHAR(50),
    thisobject2company INT NOT NULL
);

CREATE TABLE role (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE user_account (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    account_status VARCHAR(20)
);
SHOW TABLES;
