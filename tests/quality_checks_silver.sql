/*
=======================================================================
Script: Data Quality Checks
=======================================================================
Script Purpose:
    This script performs data quality checks on the Bronze and Silver
    layers of the Data Warehouse.

    The checks include:
    - Identifying duplicate IDs.
    - Checking for unwanted spaces.
    - Validating data standardization and consistency.
    - Checking for invalid dates.
    - Checking consistency between sales, quantity, and price.
    - Identifying out-of-range dates.
    - Checking for unmatched customer records.

Note:
    These queries are intended for data quality validation.

=======================================================================
*/


-- =====================================================================
-- TABLE: bronze.crm_cust_info
-- =====================================================================

-- Remove rows with duplicate IDs

SELECT
    cci.cst_id,
    COUNT(*)
FROM bronze.crm_cust_info cci
GROUP BY cci.cst_id
HAVING COUNT(*) > 1
    OR cci.cst_id IS NULL;


-- Check for unwanted spaces

SELECT
    cci.cst_firstname,
    cci.cst_lastname
FROM bronze.crm_cust_info cci
WHERE cci.cst_firstname != TRIM(cci.cst_firstname)
    OR cci.cst_lastname != TRIM(cci.cst_lastname);


-- Data Standardization and Consistency

SELECT
    cci.cst_gndr,
    COUNT(*)
FROM bronze.crm_cust_info cci
GROUP BY cci.cst_gndr;


-- =====================================================================
-- TABLE: silver.crm_prd_info
-- =====================================================================

-- Quality Checks
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Result

SELECT
    cpi.prd_id,
    COUNT(*)
FROM silver.crm_prd_info cpi
GROUP BY cpi.prd_id
HAVING COUNT(*) > 1
    OR cpi.prd_id IS NULL;


-- Check for unwanted spaces
-- Expectation: No Result

SELECT
    cpi.prd_nm,
    cpi.prd_nm
FROM silver.crm_prd_info cpi
WHERE cpi.prd_nm != TRIM(cpi.prd_nm);


-- Check for NULLs or Negative Numbers
-- Expectation: No Result

SELECT *
FROM silver.crm_prd_info cpi
WHERE cpi.prd_cost < 0
    OR cpi.prd_cost IS NULL;


-- Data Standardization and Consistency

SELECT DISTINCT
    cpi.prd_line
FROM silver.crm_prd_info cpi;


-- Check for Invalid Date Orders

SELECT *
FROM silver.crm_prd_info cpi
WHERE cpi.prd_end_dt < cpi.prd_start_dt;


-- =====================================================================
-- TABLE: bronze.crm_sales_details
-- =====================================================================

-- Check for Invalid Dates

SELECT
    NULLIF(csd.sls_order_dt, '0') AS sls_order_dt
FROM bronze.crm_sales_details AS csd
WHERE csd.sls_order_dt <= '0'
    OR LENGTH(csd.sls_order_dt) != 8
    OR csd.sls_order_dt > '20500101'
    OR csd.sls_order_dt < '19000101';


-- Check Data Consistency: Between Sales, Quantity and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.

SELECT DISTINCT
    sls_sales AS old_sls_sales,
    sls_price AS old_sls_price,
    sls_quantity,
    CASE
        WHEN sls_sales IS NULL
            OR sls_sales <= 0
            OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    CASE
        WHEN sls_price IS NULL
            OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details csd
WHERE sls_sales != sls_quantity * sls_price
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
    OR sls_sales <= 0
    OR sls_quantity <= 0
    OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;


-- =====================================================================
-- TABLE: bronze.erp_cust_az12
-- =====================================================================

-- Identify Out-of-Range Dates

SELECT DISTINCT
    bdate
FROM bronze.erp_cust_az12 eca
WHERE bdate < '1924-01-01'
    OR bdate > CURRENT_DATE;


-- Data Standardization and Consistency

SELECT DISTINCT
    gen,
    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen
FROM bronze.erp_cust_az12 eca;


-- =====================================================================
-- TABLE: bronze.erp_loc_a101
-- =====================================================================

SELECT
    cid,
    cntry
FROM bronze.erp_loc_a101 ela
WHERE REPLACE(cid, '-', '') NOT IN (
    SELECT cst_key
    FROM silver.crm_cust_info cci
);


-- =====================================================================
-- TABLE: bronze.erp_px_cat_g1v2
-- =====================================================================

-- Check for unwanted spaces

SELECT *
FROM bronze.erp_px_cat_g1v2 epcgv
WHERE cat != TRIM(cat)
    OR subcat != TRIM(subcat)
    OR maintenance != TRIM(maintenance);


-- Data Standardization and Consistency

SELECT DISTINCT
    maintenance
FROM bronze.erp_px_cat_g1v2 epcgv;


-- =====================================================================
-- END OF DATA QUALITY CHECKS
-- =====================================================================