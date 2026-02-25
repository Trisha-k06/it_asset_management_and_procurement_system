USE it_asset_mgmt_db;


-- LOCATION FKs

ALTER TABLE province
  ADD CONSTRAINT fk_province_country
  FOREIGN KEY (thisobject2country) REFERENCES country(internal_id);

ALTER TABLE city
  ADD CONSTRAINT fk_city_province
  FOREIGN KEY (thisobject2province) REFERENCES province(internal_id);

ALTER TABLE address
  ADD CONSTRAINT fk_address_city
  FOREIGN KEY (thisobject2city) REFERENCES city(internal_id);


-- ORG FKs

ALTER TABLE site
  ADD CONSTRAINT fk_site_company
  FOREIGN KEY (thisobject2company) REFERENCES company(internal_id);

ALTER TABLE site
  ADD CONSTRAINT fk_site_parent_site
  FOREIGN KEY (parent_site_id) REFERENCES site(internal_id);

ALTER TABLE department
  ADD CONSTRAINT fk_dept_company
  FOREIGN KEY (thisobject2company) REFERENCES company(internal_id);

ALTER TABLE department
  ADD CONSTRAINT fk_dept_parent_dept
  FOREIGN KEY (parent_dept_id) REFERENCES department(internal_id);

ALTER TABLE individual
  ADD CONSTRAINT fk_individual_company
  FOREIGN KEY (thisobject2company) REFERENCES company(internal_id);



-- MAP TABLE FKs

ALTER TABLE company_address_map
  ADD CONSTRAINT fk_cam_company
  FOREIGN KEY (thisobject2company) REFERENCES company(internal_id);

ALTER TABLE company_address_map
  ADD CONSTRAINT fk_cam_address
  FOREIGN KEY (thisobject2address) REFERENCES address(internal_id);

ALTER TABLE company_phone_map
  ADD CONSTRAINT fk_cpm_company
  FOREIGN KEY (thisobject2company) REFERENCES company(internal_id);

ALTER TABLE company_phone_map
  ADD CONSTRAINT fk_cpm_phone
  FOREIGN KEY (thisobject2phone) REFERENCES phone_number(internal_id);

ALTER TABLE individual_phone_map
  ADD CONSTRAINT fk_ipm_individual
  FOREIGN KEY (thisobject2individual) REFERENCES individual(internal_id);

ALTER TABLE individual_phone_map
  ADD CONSTRAINT fk_ipm_phone
  FOREIGN KEY (thisobject2phone) REFERENCES phone_number(internal_id);

ALTER TABLE user_role_map
  ADD CONSTRAINT fk_urm_user
  FOREIGN KEY (thisobject2user) REFERENCES user_account(internal_id);

ALTER TABLE user_role_map
  ADD CONSTRAINT fk_urm_role
  FOREIGN KEY (thisobject2role) REFERENCES role(internal_id);

ALTER TABLE individual_department_map
  ADD CONSTRAINT fk_idm_individual
  FOREIGN KEY (thisobject2individual) REFERENCES individual(internal_id);

ALTER TABLE individual_department_map
  ADD CONSTRAINT fk_idm_department
  FOREIGN KEY (thisobject2department) REFERENCES department(internal_id);



-- PROCUREMENT FKs

ALTER TABLE vendor_address_map
  ADD CONSTRAINT fk_vam_vendor
  FOREIGN KEY (thisobject2vendor) REFERENCES vendor_master(internal_id);

ALTER TABLE vendor_address_map
  ADD CONSTRAINT fk_vam_address
  FOREIGN KEY (thisobject2address) REFERENCES address(internal_id);

ALTER TABLE vendor_quotation_scan
  ADD CONSTRAINT fk_vqs_vendor
  FOREIGN KEY (thisobject2vendor) REFERENCES vendor_master(internal_id);

ALTER TABLE purchase_order_header
  ADD CONSTRAINT fk_poh_vendor
  FOREIGN KEY (thisobject2vendor) REFERENCES vendor_master(internal_id);

ALTER TABLE purchase_order_detail
  ADD CONSTRAINT fk_pod_po
  FOREIGN KEY (thisobject2po) REFERENCES purchase_order_header(internal_id);

ALTER TABLE goods_receipt_header
  ADD CONSTRAINT fk_grh_po
  FOREIGN KEY (thisobject2po) REFERENCES purchase_order_header(internal_id);

ALTER TABLE goods_receipt_detail
  ADD CONSTRAINT fk_grd_grn
  FOREIGN KEY (thisobject2grn) REFERENCES goods_receipt_header(internal_id);

ALTER TABLE goods_receipt_detail
  ADD CONSTRAINT fk_grd_podetail
  FOREIGN KEY (thisobject2podetail) REFERENCES purchase_order_detail(internal_id);



-- ASSET / PRODUCT FKs

ALTER TABLE product_specification
  ADD CONSTRAINT fk_ps_product
  FOREIGN KEY (thisobject2product) REFERENCES product_master(internal_id);

ALTER TABLE asset_subtype_master
  ADD CONSTRAINT fk_asm_type
  FOREIGN KEY (thisobject2asset_type) REFERENCES asset_type_master(internal_id);

ALTER TABLE asset
  ADD CONSTRAINT fk_asset_subtype
  FOREIGN KEY (thisobject2subtype) REFERENCES asset_subtype_master(internal_id);

ALTER TABLE asset
  ADD CONSTRAINT fk_asset_status
  FOREIGN KEY (thisobject2status) REFERENCES asset_status(internal_id);

ALTER TABLE asset_allocation
  ADD CONSTRAINT fk_alloc_asset
  FOREIGN KEY (thisobject2asset) REFERENCES asset(internal_id);

ALTER TABLE asset_allocation
  ADD CONSTRAINT fk_alloc_individual
  FOREIGN KEY (thisobject2individual) REFERENCES individual(internal_id);

ALTER TABLE maintenance_record
  ADD CONSTRAINT fk_maint_asset
  FOREIGN KEY (thisobject2asset) REFERENCES asset(internal_id);
