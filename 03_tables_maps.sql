USE it_asset_mgmt_db;

CREATE TABLE phone_number (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    country_dial_code VARCHAR(10),
    phone_number VARCHAR(20),
    phone_type VARCHAR(20)
);

CREATE TABLE company_phone_map (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2company INT NOT NULL,
    thisobject2phone INT NOT NULL,
    is_primary BOOLEAN
);

CREATE TABLE individual_phone_map (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2individual INT NOT NULL,
    thisobject2phone INT NOT NULL,
    is_primary BOOLEAN
);

CREATE TABLE user_role_map (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2user INT NOT NULL,
    thisobject2role INT NOT NULL
);

CREATE TABLE individual_department_map (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2individual INT NOT NULL,
    thisobject2department INT NOT NULL,
    start_date DATE,
    end_date DATE,
    status VARCHAR(50)
);

CREATE TABLE company_address_map (
    internal_id INT AUTO_INCREMENT PRIMARY KEY,
    thisobject2company INT NOT NULL,
    thisobject2address INT NOT NULL,
    is_primary BOOLEAN
);
