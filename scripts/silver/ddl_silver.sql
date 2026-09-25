/*
=======================================================================
DDL Script: Create Silver Layer Tables
=======================================================================
Script Puspose:
    This script creates tables in the 'silver'schema, dropping existing
    tables if they already exist.
    Run this script to re-define the DDL structure of 'silver' Tables
=======================================================================
*/

-- CRM: Customer Information
DROP TABLE IF EXISTS silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info (
    cst_id             INT,
    cst_key            VARCHAR(50),
    cst_firstname      VARCHAR(50),
    cst_lastname       VARCHAR(50),
    cst_marital_status VARCHAR(50),
    cst_gndr           VARCHAR(50),
    cst_create_date    DATE,
    dwh_create_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- CRM: Product Information
DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id         INT,
    prd_key        VARCHAR(50),
    prd_nm         VARCHAR(100),
    prd_cost       DECIMAL(10, 2),
    prd_line       CHAR(2),
    prd_start_dt   DATE,
    prd_end_dt     DATE,
    dwh_create_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- CRM: Sales Details
DROP TABLE IF EXISTS silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num    VARCHAR(20),
    sls_prd_key    VARCHAR(50),
    sls_cust_id    INT,
    sls_order_dt   VARCHAR(20),
    sls_ship_dt    DATE,
    sls_due_dt     DATE,
    sls_sales      DECIMAL(10, 2),
    sls_quantity   INT,
    sls_price      DECIMAL(10, 2),
    dwh_create_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- ERP: Customer Information
DROP TABLE IF EXISTS silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    cid    VARCHAR(50),
    bdate  DATE,
    gen    VARCHAR(50),
    dwh_create_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- ERP: Location Information
DROP TABLE IF EXISTS silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    cid    VARCHAR(50),
    cntry  VARCHAR(50),
    dwh_create_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- ERP: Product Category Information
DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id           VARCHAR(50),
    cat          VARCHAR(50),
    subcat       VARCHAR(50),
    maintenance  VARCHAR(50),
    dwh_create_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);