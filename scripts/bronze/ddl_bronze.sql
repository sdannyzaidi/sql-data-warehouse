/*
=======================================================================
DDL Script: Create Bronze Layer Tables
=======================================================================
Script Puspose:
    This script creates tables in the 'bronze'schema, dropping existing
    tables if they already exist.
    Run this script to re-define the DDL structure of 'bronze' Tables
=======================================================================
*/

-- CRM: Customer Information
DROP TABLE IF EXISTS bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info (
    cst_id             INT,
    cst_key            VARCHAR(50),
    cst_firstname      VARCHAR(50),
    cst_lastname       VARCHAR(50),
    cst_marital_status VARCHAR(50),
    cst_gndr           VARCHAR(50),
    cst_create_date    DATE
);


-- CRM: Product Information
DROP TABLE IF EXISTS bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info (
    prd_id         INT,
    prd_key        VARCHAR(50),
    prd_nm         VARCHAR(100),
    prd_cost       DECIMAL(10, 2),
    prd_line       CHAR(2),
    prd_start_dt   DATE,
    prd_end_dt     DATE
);


-- CRM: Sales Details
DROP TABLE IF EXISTS bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num    VARCHAR(20),
    sls_prd_key    VARCHAR(50),
    sls_cust_id    INT,
    sls_order_dt   VARCHAR(20),
    sls_ship_dt    DATE,
    sls_due_dt     DATE,
    sls_sales      DECIMAL(10, 2),
    sls_quantity   INT,
    sls_price      DECIMAL(10, 2)
);


-- ERP: Customer Information
DROP TABLE IF EXISTS bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12 (
    cid    VARCHAR(50),
    bdate  DATE,
    gen    VARCHAR(50)
);


-- ERP: Location Information
DROP TABLE IF EXISTS bronze.erp_loc_a101;

CREATE TABLE bronze.erp_loc_a101 (
    cid    VARCHAR(50),
    cntry  VARCHAR(50)
);


-- ERP: Product Category Information
DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           VARCHAR(50),
    cat          VARCHAR(50),
    subcat       VARCHAR(50),
    maintenance  VARCHAR(50)
);