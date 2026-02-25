USE it_asset_mgmt_db;


ALTER TABLE address
  ADD COLUMN address_line3 VARCHAR(255) NULL AFTER address_line2;


ALTER TABLE phone_number
  ADD COLUMN is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN is_active  BOOLEAN NOT NULL DEFAULT TRUE;


CREATE TABLE IF NOT EXISTS vendor_phone_map (
  internal_id INT AUTO_INCREMENT PRIMARY KEY,
  thisobject2vendor INT NOT NULL,
  thisobject2phone  INT NOT NULL,
  CONSTRAINT fk_vpm_vendor FOREIGN KEY (thisobject2vendor) REFERENCES vendor_master(internal_id),
  CONSTRAINT fk_vpm_phone  FOREIGN KEY (thisobject2phone)  REFERENCES phone_number(internal_id)
) ENGINE=InnoDB;


ALTER TABLE company
  ADD COLUMN thisobject2address INT NULL,
  ADD COLUMN created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE company
  ADD CONSTRAINT fk_company_address
  FOREIGN KEY (thisobject2address) REFERENCES address(internal_id);


ALTER TABLE site DROP FOREIGN KEY fk_site_parent_site;

ALTER TABLE site
  CHANGE parent_site_id thisobject2parentsite INT NULL;

ALTER TABLE site
  ADD COLUMN thisobject2address INT NULL,
  ADD COLUMN thisobject2defaultuser INT NULL;

ALTER TABLE site
  ADD CONSTRAINT fk_site_parent
  FOREIGN KEY (thisobject2parentsite) REFERENCES site(internal_id);

ALTER TABLE site
  ADD CONSTRAINT fk_site_address
  FOREIGN KEY (thisobject2address) REFERENCES address(internal_id);

ALTER TABLE site
  ADD CONSTRAINT fk_site_defaultuser
  FOREIGN KEY (thisobject2defaultuser) REFERENCES user_account(internal_id);


ALTER TABLE department DROP FOREIGN KEY fk_dept_parent_dept;

ALTER TABLE department
  CHANGE parent_dept_id thisobject2parentdepartment INT NULL;


ALTER TABLE department
  ADD COLUMN thisobject2site INT NULL;

ALTER TABLE department
  ADD CONSTRAINT fk_dept_parent
  FOREIGN KEY (thisobject2parentdepartment) REFERENCES department(internal_id);

ALTER TABLE department
  ADD CONSTRAINT fk_dept_site
  FOREIGN KEY (thisobject2site) REFERENCES site(internal_id);


ALTER TABLE individual
  ADD COLUMN id_num VARCHAR(50) NULL,
  ADD COLUMN thisobject2site INT NULL;

ALTER TABLE individual
  ADD CONSTRAINT fk_ind_site
  FOREIGN KEY (thisobject2site) REFERENCES site(internal_id);


ALTER TABLE individual_department_map
  ADD COLUMN start_date DATE NULL,
  ADD COLUMN expected_end_date DATE NULL,
  ADD COLUMN end_date DATE NULL,
  ADD COLUMN deployment_status VARCHAR(30) NULL,
  ADD COLUMN remarks VARCHAR(255) NULL;


ALTER TABLE user_account
  ADD COLUMN thisobject2individual INT NULL;

ALTER TABLE user_account
  ADD CONSTRAINT uq_user_ind UNIQUE (thisobject2individual),
  ADD CONSTRAINT fk_user_ind FOREIGN KEY (thisobject2individual) REFERENCES individual(internal_id);


ALTER TABLE user_account
  CHANGE account_status status VARCHAR(20) NOT NULL;


ALTER TABLE vendor_address_map
  ADD COLUMN address_type VARCHAR(30) NULL;

ALTER TABLE vendor_quotation_scan
  ADD COLUMN quote_received_date DATE NULL,
  ADD COLUMN scan_date DATE NULL,
  ADD COLUMN valid_until DATE NULL,
  ADD COLUMN quotation_document_ref VARCHAR(255) NULL,
  ADD COLUMN remarks VARCHAR(255) NULL;


ALTER TABLE purchase_order_header
  ADD COLUMN thisobject2quotation INT NULL,
  ADD COLUMN thisobject2company INT NULL,
  ADD COLUMN thisobject2deliverysite INT NULL,
  ADD COLUMN total_amount DECIMAL(12,2) NULL;

ALTER TABLE purchase_order_header
  ADD CONSTRAINT fk_poh_quote
    FOREIGN KEY (thisobject2quotation) REFERENCES vendor_quotation_scan(internal_id),
  ADD CONSTRAINT fk_poh_company
    FOREIGN KEY (thisobject2company) REFERENCES company(internal_id),
  ADD CONSTRAINT fk_poh_site
    FOREIGN KEY (thisobject2deliverysite) REFERENCES site(internal_id);


ALTER TABLE purchase_order_detail
  ADD COLUMN thisobject2product INT NULL,
  ADD COLUMN gst_percent DECIMAL(5,2) NULL;

ALTER TABLE purchase_order_detail
  ADD CONSTRAINT fk_pod_product
  FOREIGN KEY (thisobject2product) REFERENCES product_master(internal_id);


ALTER TABLE goods_receipt_header
  CHANGE grn_date received_date DATE NULL;

ALTER TABLE goods_receipt_header
  ADD COLUMN thisobject2receivedbyuser INT NULL;

ALTER TABLE goods_receipt_header
  ADD CONSTRAINT fk_grn_user
  FOREIGN KEY (thisobject2receivedbyuser) REFERENCES user_account(internal_id);


ALTER TABLE goods_receipt_detail
  CHANGE thisobject2podetail thisobject2poline INT NOT NULL;

ALTER TABLE goods_receipt_detail
  ADD COLUMN remarks VARCHAR(255) NULL;


ALTER TABLE product_master
  ADD COLUMN description VARCHAR(255) NULL,
  ADD COLUMN warranty_months INT NULL,
  ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE product_specification
  ADD CONSTRAINT uq_prod_spec UNIQUE (thisobject2product, spec_key);


ALTER TABLE asset_type_master
  ADD COLUMN description VARCHAR(255) NULL;

ALTER TABLE asset_subtype_master
  ADD COLUMN description VARCHAR(255) NULL;

ALTER TABLE asset
  ADD COLUMN thisobject2product INT NULL,
  ADD COLUMN thisobject2assettype INT NULL,
  ADD COLUMN asset_kind VARCHAR(15) NULL;

ALTER TABLE asset
  ADD CONSTRAINT fk_asset_product
    FOREIGN KEY (thisobject2product) REFERENCES product_master(internal_id),
  ADD CONSTRAINT fk_asset_type
    FOREIGN KEY (thisobject2assettype) REFERENCES asset_type_master(internal_id);


ALTER TABLE asset
  CHANGE thisobject2subtype thisobject2assetsubtype INT NOT NULL;

ALTER TABLE asset
  CHANGE thisobject2status thisobject2assetstatus INT NOT NULL;


ALTER TABLE asset_allocation
  ADD COLUMN custodian_type VARCHAR(15) NULL,
  ADD COLUMN thisobject2department INT NULL,
  ADD COLUMN thisobject2site INT NULL,
  ADD COLUMN expected_deallocation_date DATE NULL,
  ADD COLUMN deallocation_date DATE NULL;

ALTER TABLE asset_allocation
  ADD CONSTRAINT fk_alloc_dept
    FOREIGN KEY (thisobject2department) REFERENCES department(internal_id),
  ADD CONSTRAINT fk_alloc_site
    FOREIGN KEY (thisobject2site) REFERENCES site(internal_id);


ALTER TABLE maintenance_record
  CHANGE maintenance_date opened_on DATE NULL;

ALTER TABLE maintenance_record
  ADD COLUMN closed_on DATE NULL;

ALTER TABLE maintenance_record
  CHANGE description notes VARCHAR(255) NULL;


DROP TABLE IF EXISTS audit_log;

ALTER TABLE purchase_order_header
  ADD COLUMN thisobject2quotation INT NULL,
  ADD COLUMN thisobject2company INT NULL,
  ADD COLUMN thisobject2deliverysite INT NULL,
  ADD COLUMN total_amount DECIMAL(12,2) NULL;

ALTER TABLE purchase_order_header
  ADD CONSTRAINT fk_poh_quote
    FOREIGN KEY (thisobject2quotation) REFERENCES vendor_quotation_scan(internal_id),
  ADD CONSTRAINT fk_poh_company
    FOREIGN KEY (thisobject2company) REFERENCES company(internal_id),
  ADD CONSTRAINT fk_poh_site
    FOREIGN KEY (thisobject2deliverysite) REFERENCES site(internal_id);


ALTER TABLE asset_allocation
  ADD COLUMN custodian_type VARCHAR(15) NULL,
  ADD COLUMN thisobject2department INT NULL,
  ADD COLUMN thisobject2site INT NULL,
  ADD COLUMN expected_deallocation_date DATE NULL,
  ADD COLUMN deallocation_date DATE NULL;

ALTER TABLE asset_allocation
  ADD CONSTRAINT fk_alloc_dept
    FOREIGN KEY (thisobject2department) REFERENCES department(internal_id),
  ADD CONSTRAINT fk_alloc_site
    FOREIGN KEY (thisobject2site) REFERENCES site(internal_id);
    
USE it_asset_mgmt_db;
SELECT DATABASE();

ALTER TABLE purchase_order_header
  ADD COLUMN thisobject2quotation INT NULL,
  ADD COLUMN thisobject2company INT NULL,
  ADD COLUMN thisobject2deliverysite INT NULL,
  ADD COLUMN total_amount DECIMAL(12,2) NULL;

ALTER TABLE purchase_order_header
  ADD CONSTRAINT fk_poh_quote
    FOREIGN KEY (thisobject2quotation) REFERENCES vendor_quotation_scan(internal_id),
  ADD CONSTRAINT fk_poh_company
    FOREIGN KEY (thisobject2company) REFERENCES company(internal_id),
  ADD CONSTRAINT fk_poh_site
    FOREIGN KEY (thisobject2deliverysite) REFERENCES site(internal_id);

DESCRIBE purchase_order_header;

ALTER TABLE purchase_order_header
ADD COLUMN thisobject2quotation INT NULL,
ADD COLUMN thisobject2company INT NULL,
ADD COLUMN thisobject2deliverysite INT NULL,
ADD COLUMN total_amount DECIMAL(12,2) NULL;

ALTER TABLE purchase_order_header
ADD CONSTRAINT fk_poh_quote
FOREIGN KEY (thisobject2quotation)
REFERENCES vendor_quotation_scan(internal_id),

ADD CONSTRAINT fk_poh_company
FOREIGN KEY (thisobject2company)
REFERENCES company(internal_id),

ADD CONSTRAINT fk_poh_site
FOREIGN KEY (thisobject2deliverysite)
REFERENCES site(internal_id);

SHOW CREATE TABLE purchase_order_header;
SHOW CREATE TABLE asset_allocation;
SHOW CREATE TABLE department;
SHOW CREATE TABLE site;

ALTER TABLE asset_allocation
  ADD COLUMN custodian_type VARCHAR(15) NULL,
  ADD COLUMN thisobject2department INT NULL,
  ADD COLUMN thisobject2site INT NULL,
  ADD COLUMN expected_deallocation_date DATE NULL,
  ADD COLUMN deallocation_date DATE NULL;


ALTER TABLE asset_allocation
  ADD COLUMN thisobject2department INT NULL,
  ADD COLUMN thisobject2site INT NULL,
  ADD COLUMN custodian_type VARCHAR(15) NULL,
  ADD COLUMN expected_deallocation_date DATE NULL,
  ADD COLUMN deallocation_date DATE NULL;
  
  ALTER TABLE asset_allocation
  ADD CONSTRAINT fk_alloc_dept 
    FOREIGN KEY (thisobject2department) 
    REFERENCES department(internal_id),
  ADD CONSTRAINT fk_alloc_site 
    FOREIGN KEY (thisobject2site) 
    REFERENCES site(internal_id);
    
SHOW CREATE TABLE asset_allocation;






