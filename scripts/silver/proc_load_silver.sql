/*
=======================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
=======================================================================
Script Purpose:
    This stored procedure loads data into the 'silver' schema from
    the 'bronze' schema.
    It performs the following actions:
    - Truncates the Silver tables before loading.
    - Cleanses and transforms data from the Bronze layer.
    - Handles duplicates, standardizes values, and validates data.
    - Displays progress notices during execution.
    - Records the start time, end time, and total execution duration.

Parameters:
    None. This stored procedure does not accept any parameters or
    return any values.

Use Example:
    CALL silver.load_silver();
=======================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;
BEGIN
    start_time := clock_timestamp();

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Starting Silver Layer Load';
    RAISE NOTICE 'Start Time: %', start_time;
    RAISE NOTICE '==========================================';

    -- ==========================================
    -- 1. CRM Customer Information
    -- ==========================================
    RAISE NOTICE 'Loading silver.crm_cust_info...';

    TRUNCATE TABLE silver.crm_cust_info;

    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END,
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a'
        END,
        cst_create_date
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last
        FROM bronze.crm_cust_info
    ) AS ranked_customers
    WHERE flag_last = 1;

    RAISE NOTICE 'Loaded silver.crm_cust_info.';

    -- ==========================================
    -- 2. CRM Product Information
    -- ==========================================
    RAISE NOTICE 'Loading silver.crm_prd_info...';

    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTR(cpi.prd_key, 1, 5), '-', '_') AS cat_id,
        SUBSTR(cpi.prd_key, 7, LENGTH(cpi.prd_key)) AS prd_key,
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,
        prd_start_dt,
        LEAD(prd_start_dt) OVER (
            PARTITION BY cpi.prd_key
            ORDER BY prd_start_dt
        ) - 1 AS prd_end_dt
    FROM bronze.crm_prd_info AS cpi;

    RAISE NOTICE 'Loaded silver.crm_prd_info.';

    -- ==========================================
    -- 3. CRM Sales Details
    -- ==========================================
    RAISE NOTICE 'Loading silver.crm_sales_details...';

    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE
            WHEN sls_order_dt = '0'
                OR LENGTH(sls_order_dt) <> 8
            THEN NULL
            ELSE TO_DATE(sls_order_dt, 'YYYYMMDD')
        END AS sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        CASE
            WHEN sls_sales IS NULL
                OR sls_sales <= 0
                OR sls_sales <> sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,
        sls_quantity,
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price
    FROM bronze.crm_sales_details;

    RAISE NOTICE 'Loaded silver.crm_sales_details.';

    -- ==========================================
    -- 4. ERP Customer Information
    -- ==========================================
    RAISE NOTICE 'Loading silver.erp_cust_az12...';

    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
            ELSE cid
        END AS cid,
        CASE
            WHEN bdate > CURRENT_DATE THEN NULL
            ELSE bdate
        END AS bdate,
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            ELSE 'n/a'
        END AS gen
    FROM bronze.erp_cust_az12;

    RAISE NOTICE 'Loaded silver.erp_cust_az12.';

    -- ==========================================
    -- 5. ERP Location Information
    -- ==========================================
    RAISE NOTICE 'Loading silver.erp_loc_a101...';

    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        REPLACE(cid, '-', '') AS cid,
        CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
            ELSE TRIM(cntry)
        END AS cleaned_cntry
    FROM bronze.erp_loc_a101;

    RAISE NOTICE 'Loaded silver.erp_loc_a101.';

    -- ==========================================
    -- 6. ERP Product Categories
    -- ==========================================
    RAISE NOTICE 'Loading silver.erp_px_cat_g1v2...';

    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
        id,
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2;

    RAISE NOTICE 'Loaded silver.erp_px_cat_g1v2.';

    -- ==========================================
    -- End of Silver Layer Load
    -- ==========================================
    end_time := clock_timestamp();

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Silver Layer Load Completed';
    RAISE NOTICE 'End Time: %', end_time;
    RAISE NOTICE 'Total Duration: % seconds',
        ROUND(
            EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC,
            2
        );
    RAISE NOTICE '==========================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR during Silver Layer Load: %', SQLERRM;
        RAISE;
END;
$$;

CALL silver.load_silver();