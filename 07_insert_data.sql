

USE it_asset_mgmt_db;

SET SQL_SAFE_UPDATES = 0;


INSERT INTO country (country_code, country_name, currency)
VALUES
('IN','India','INR'),
('US','United States','USD'),
('UK','United Kingdom','GBP'),
('CA','Canada','CAD'),
('AU','Australia','AUD'),
('DE','Germany','EUR'),
('FR','France','EUR'),
('JP','Japan','JPY'),
('CN','China','CNY'),
('SG','Singapore','SGD'),
('AE','UAE','AED'),
('BR','Brazil','BRL'),
('ZA','South Africa','ZAR'),
('RU','Russia','RUB'),
('KR','South Korea','KRW')
AS new
ON DUPLICATE KEY UPDATE
  country_name = new.country_name,
  currency     = new.currency;


INSERT INTO province (province_code, province_name, thisobject2country)
VALUES
('TN','Tamil Nadu',        (SELECT internal_id FROM country WHERE country_code='IN')),
('KA','Karnataka',         (SELECT internal_id FROM country WHERE country_code='IN')),
('MH','Maharashtra',       (SELECT internal_id FROM country WHERE country_code='IN')),
('DL','Delhi',             (SELECT internal_id FROM country WHERE country_code='IN')),
('GJ','Gujarat',           (SELECT internal_id FROM country WHERE country_code='IN')),
('RJ','Rajasthan',         (SELECT internal_id FROM country WHERE country_code='IN')),
('UP','Uttar Pradesh',     (SELECT internal_id FROM country WHERE country_code='IN')),
('TS','Telangana',         (SELECT internal_id FROM country WHERE country_code='IN')),
('AP','Andhra Pradesh',    (SELECT internal_id FROM country WHERE country_code='IN')),
('KL','Kerala',            (SELECT internal_id FROM country WHERE country_code='IN')),
('PB','Punjab',            (SELECT internal_id FROM country WHERE country_code='IN')),
('HR','Haryana',           (SELECT internal_id FROM country WHERE country_code='IN')),
('MP','Madhya Pradesh',    (SELECT internal_id FROM country WHERE country_code='IN')),
('WB','West Bengal',       (SELECT internal_id FROM country WHERE country_code='IN')),
('OD','Odisha',            (SELECT internal_id FROM country WHERE country_code='IN'))
AS new
ON DUPLICATE KEY UPDATE
  province_name    = new.province_name,
  thisobject2country= new.thisobject2country;


INSERT INTO city (city_code, city_name, thisobject2province)
VALUES
('CHE','Chennai',      (SELECT internal_id FROM province WHERE province_code='TN')),
('BLR','Bangalore',    (SELECT internal_id FROM province WHERE province_code='KA')),
('MUM','Mumbai',       (SELECT internal_id FROM province WHERE province_code='MH')),
('DEL','Delhi',        (SELECT internal_id FROM province WHERE province_code='DL')),
('AMD','Ahmedabad',    (SELECT internal_id FROM province WHERE province_code='GJ')),
('JPR','Jaipur',       (SELECT internal_id FROM province WHERE province_code='RJ')),
('LKO','Lucknow',      (SELECT internal_id FROM province WHERE province_code='UP')),
('HYD','Hyderabad',    (SELECT internal_id FROM province WHERE province_code='TS')),
('VJA','Vijayawada',   (SELECT internal_id FROM province WHERE province_code='AP')),
('KOC','Kochi',        (SELECT internal_id FROM province WHERE province_code='KL')),
('CHD','Chandigarh',   (SELECT internal_id FROM province WHERE province_code='PB')),
('GGN','Gurgaon',      (SELECT internal_id FROM province WHERE province_code='HR')),
('BPL','Bhopal',       (SELECT internal_id FROM province WHERE province_code='MP')),
('KOL','Kolkata',      (SELECT internal_id FROM province WHERE province_code='WB')),
('BBI','Bhubaneswar',  (SELECT internal_id FROM province WHERE province_code='OD'))
AS new
ON DUPLICATE KEY UPDATE
  city_name         = new.city_name,
  thisobject2province= new.thisobject2province;


INSERT INTO address (building_no, address_line1, address_line2, area, zipcode, address_type, thisobject2city)
VALUES
('1A','MG Road',       NULL,'Central',     '600001','Office', (SELECT internal_id FROM city WHERE city_code='CHE')),
('2B','Brigade Rd',    NULL,'CBD',         '560001','Office', (SELECT internal_id FROM city WHERE city_code='BLR')),
('3C','Link Rd',       NULL,'Andheri',     '400001','Office', (SELECT internal_id FROM city WHERE city_code='MUM')),
('4D','CP',            NULL,'Connaught',   '110001','Office', (SELECT internal_id FROM city WHERE city_code='DEL')),
('5E','SG Hwy',        NULL,'Satellite',   '380001','Office', (SELECT internal_id FROM city WHERE city_code='AMD')),
('6F','MI Rd',         NULL,'Pink City',   '302001','Office', (SELECT internal_id FROM city WHERE city_code='JPR')),
('7G','Hazratganj',    NULL,'Downtown',    '226001','Office', (SELECT internal_id FROM city WHERE city_code='LKO')),
('8H','Banjara Hills', NULL,'Central',     '500001','Office', (SELECT internal_id FROM city WHERE city_code='HYD')),
('9I','Ring Rd',       NULL,'Urban',       '520001','Office', (SELECT internal_id FROM city WHERE city_code='VJA')),
('10J','Marine Dr',    NULL,'Coastal',     '682001','Office', (SELECT internal_id FROM city WHERE city_code='KOC')),
('11K','Sector 17',    NULL,'Urban',       '160001','Office', (SELECT internal_id FROM city WHERE city_code='CHD')),
('12L','Cyber Hub',    NULL,'IT Park',     '122001','Office', (SELECT internal_id FROM city WHERE city_code='GGN')),
('13M','Arera',        NULL,'Residential', '462001','Office', (SELECT internal_id FROM city WHERE city_code='BPL')),
('14N','Salt Lake',    NULL,'Sector V',    '700001','Office', (SELECT internal_id FROM city WHERE city_code='KOL')),
('15O','Jaydev Vihar', NULL,'Commercial',  '751001','Office', (SELECT internal_id FROM city WHERE city_code='BBI'))
AS new
ON DUPLICATE KEY UPDATE
  address_line1   = new.address_line1,
  address_line2   = new.address_line2,
  area            = new.area,
  zipcode         = new.zipcode,
  address_type    = new.address_type,
  thisobject2city = new.thisobject2city;


INSERT INTO company (company_name, gst_no, company_email, thisobject2address)
VALUES
('TechNova','33AAAAA1111A1Z1','contact1@technova.com',   (SELECT internal_id FROM address WHERE building_no='1A'  LIMIT 1)),
('InnoCore','33BBBBB2222B2Z2','contact2@innocore.com',   (SELECT internal_id FROM address WHERE building_no='2B'  LIMIT 1)),
('AlphaSys','33CCCCC3333C3Z3','contact3@alphasys.com',   (SELECT internal_id FROM address WHERE building_no='3C'  LIMIT 1)),
('BetaSoft','33DDDDD4444D4Z4','contact4@betasoft.com',   (SELECT internal_id FROM address WHERE building_no='4D'  LIMIT 1)),
('GammaTech','33EEEEE5555E5Z5','contact5@gammatech.com', (SELECT internal_id FROM address WHERE building_no='5E'  LIMIT 1)),
('DeltaWorks','33FFFFF6666F6Z6','contact6@deltaworks.com',(SELECT internal_id FROM address WHERE building_no='6F'  LIMIT 1)),
('OmegaIT','33GGGGG7777G7Z7','contact7@omegait.com',     (SELECT internal_id FROM address WHERE building_no='7G'  LIMIT 1)),
('Zenith','33HHHHH8888H8Z8','contact8@zenith.com',       (SELECT internal_id FROM address WHERE building_no='8H'  LIMIT 1)),
('Vertex','33IIIII9999I9Z9','contact9@vertex.com',       (SELECT internal_id FROM address WHERE building_no='9I'  LIMIT 1)),
('NextGen','33JJJJJ1010J1Z0','contact10@nextgen.com',    (SELECT internal_id FROM address WHERE building_no='10J' LIMIT 1)),
('Cloudify','33KKKKK1112K2Z1','contact11@cloudify.com',  (SELECT internal_id FROM address WHERE building_no='11K' LIMIT 1)),
('DataNest','33LLLLL1313L3Z3','contact12@datanest.com',  (SELECT internal_id FROM address WHERE building_no='12L' LIMIT 1)),
('ByteCorp','33MMMMM1414M4Z4','contact13@bytecorp.com',  (SELECT internal_id FROM address WHERE building_no='13M' LIMIT 1)),
('SoftEdge','33NNNNN1515N5Z5','contact14@softedge.com',  (SELECT internal_id FROM address WHERE building_no='14N' LIMIT 1)),
('CodeWave','33OOOOO1616O6Z6','contact15@codewave.com',  (SELECT internal_id FROM address WHERE building_no='15O' LIMIT 1))
AS new
ON DUPLICATE KEY UPDATE
  gst_no           = new.gst_no,
  company_email    = new.company_email,
  thisobject2address= new.thisobject2address;


INSERT INTO vendor_master (vendor_name, gst_no, vendor_email)
VALUES
('ABC Suppliers','33AAAAA9999A1Z1','abc@suppliers.com'),
('XYZ Distributors','33BBBBB8888B2Z2','xyz@distributors.com'),
('Delta Traders','33CCCCC7777C3Z3','delta@traders.com'),
('Prime Vendors','33DDDDD6666D4Z4','prime@vendors.com'),
('Nova Supply','33EEEEE5555E5Z5','nova@supply.com'),
('Orion Tech','33FFFFF4444F6Z6','orion@tech.com'),
('Apex Goods','33GGGGG3333G7Z7','apex@goods.com'),
('Zen Supplies','33HHHHH2222H8Z8','zen@supplies.com'),
('Vertex Corp','33IIIII1111I9Z9','vertex@corp.com'),
('Omni Retail','33JJJJJ0000J0Z0','omni@retail.com'),
('NextGen Supply','33KKKKK1212K2Z2','nextgen@supply.com'),
('Cloud Vendors','33LLLLL1313L3Z3','cloud@vendors.com'),
('Tech Bazaar','33MMMMM1414M4Z4','tech@bazaar.com'),
('Global IT','33NNNNN1515N5Z5','global@it.com'),
('Smart Supply','33OOOOO1616O6Z6','smart@supply.com')
AS new
ON DUPLICATE KEY UPDATE
  gst_no      = new.gst_no,
  vendor_email= new.vendor_email;


INSERT INTO individual (first_name, last_name, email, person_type, thisobject2company, id_num, thisobject2site)
VALUES
('Aarav','Shah','u1@mail.com','Employee', (SELECT internal_id FROM company WHERE company_name='TechNova'   LIMIT 1), NULL, NULL),
('Diya','Mehta','u2@mail.com','Employee', (SELECT internal_id FROM company WHERE company_name='InnoCore'   LIMIT 1), NULL, NULL),
('Rohan','Iyer','u3@mail.com','Employee', (SELECT internal_id FROM company WHERE company_name='AlphaSys'   LIMIT 1), NULL, NULL),
('Sneha','Patel','u4@mail.com','Employee',(SELECT internal_id FROM company WHERE company_name='BetaSoft'   LIMIT 1), NULL, NULL),
('Karan','Verma','u5@mail.com','Employee',(SELECT internal_id FROM company WHERE company_name='GammaTech'  LIMIT 1), NULL, NULL),
('Ananya','Rao','u6@mail.com','Employee', (SELECT internal_id FROM company WHERE company_name='DeltaWorks' LIMIT 1), NULL, NULL),
('Vikram','Singh','u7@mail.com','Employee',(SELECT internal_id FROM company WHERE company_name='OmegaIT'   LIMIT 1), NULL, NULL),
('Neha','Gupta','u8@mail.com','Employee', (SELECT internal_id FROM company WHERE company_name='Zenith'     LIMIT 1), NULL, NULL),
('Arjun','Nair','u9@mail.com','Employee', (SELECT internal_id FROM company WHERE company_name='Vertex'     LIMIT 1), NULL, NULL),
('Pooja','Malhotra','u10@mail.com','Employee',(SELECT internal_id FROM company WHERE company_name='NextGen' LIMIT 1), NULL, NULL),
('Rahul','Kapoor','u11@mail.com','Employee',(SELECT internal_id FROM company WHERE company_name='Cloudify'  LIMIT 1), NULL, NULL),
('Isha','Joshi','u12@mail.com','Employee', (SELECT internal_id FROM company WHERE company_name='DataNest'   LIMIT 1), NULL, NULL),
('Amit','Bansal','u13@mail.com','Employee',(SELECT internal_id FROM company WHERE company_name='ByteCorp'   LIMIT 1), NULL, NULL),
('Nidhi','Chopra','u14@mail.com','Employee',(SELECT internal_id FROM company WHERE company_name='SoftEdge'  LIMIT 1), NULL, NULL),
('Siddharth','Das','u15@mail.com','Employee',(SELECT internal_id FROM company WHERE company_name='CodeWave' LIMIT 1), NULL, NULL)
AS new
ON DUPLICATE KEY UPDATE
  first_name      = new.first_name,
  last_name       = new.last_name,
  person_type     = new.person_type,
  thisobject2company= new.thisobject2company,
  id_num          = new.id_num,
  thisobject2site = new.thisobject2site;


INSERT INTO purchase_order_header
(po_number, po_date, status, thisobject2vendor, thisobject2company, thisobject2deliverysite, total_amount)
VALUES
('PO1001','2025-02-01','APPROVED',
 (SELECT internal_id FROM vendor_master WHERE vendor_name='ABC Suppliers' LIMIT 1),
 (SELECT internal_id FROM company WHERE company_name='TechNova' LIMIT 1),
 NULL, 125000.00),

('PO1002','2025-02-02','APPROVED',
 (SELECT internal_id FROM vendor_master WHERE vendor_name='XYZ Distributors' LIMIT 1),
 (SELECT internal_id FROM company WHERE company_name='InnoCore' LIMIT 1),
 NULL, 98000.00),

('PO1003','2025-02-03','APPROVED',
 (SELECT internal_id FROM vendor_master WHERE vendor_name='Delta Traders' LIMIT 1),
 (SELECT internal_id FROM company WHERE company_name='AlphaSys' LIMIT 1),
 NULL, 156500.00),

('PO1004','2025-02-04','APPROVED',
 (SELECT internal_id FROM vendor_master WHERE vendor_name='Prime Vendors' LIMIT 1),
 (SELECT internal_id FROM company WHERE company_name='BetaSoft' LIMIT 1),
 NULL, 72000.00),

('PO1005','2025-02-05','APPROVED',
 (SELECT internal_id FROM vendor_master WHERE vendor_name='Nova Supply' LIMIT 1),
 (SELECT internal_id FROM company WHERE company_name='GammaTech' LIMIT 1),
 NULL, 45000.00)
AS new
ON DUPLICATE KEY UPDATE
  po_date            = new.po_date,
  status             = new.status,
  thisobject2vendor  = new.thisobject2vendor,
  thisobject2company = new.thisobject2company,
  thisobject2deliverysite = new.thisobject2deliverysite,
  total_amount       = new.total_amount;


SELECT COUNT(*) AS countries  FROM country;
SELECT COUNT(*) AS provinces  FROM province;
SELECT COUNT(*) AS cities     FROM city;
SELECT COUNT(*) AS addresses  FROM address;
SELECT COUNT(*) AS companies  FROM company;
SELECT COUNT(*) AS vendors    FROM vendor_master;
SELECT COUNT(*) AS individuals FROM individual;
SELECT COUNT(*) AS pos        FROM purchase_order_header;

SELECT COUNT(*) FROM country;
SELECT COUNT(*) FROM province;
SELECT COUNT(*) FROM city;
SELECT COUNT(*) FROM address;
SELECT COUNT(*) FROM company;
SELECT COUNT(*) FROM individual;
SELECT COUNT(*) FROM vendor_master;
SELECT COUNT(*) FROM purchase_order_header;
