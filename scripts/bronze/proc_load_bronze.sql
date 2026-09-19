/*
=======================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
=======================================================================
Script Puspose:
    This stored procedure loads data into the 'bronze' schema from
    external CSV files.
    It performs the following actions:
    - Truncates the tables before loading.
    - Uses the bulk load to load data from csv files to bronze tables.

Parameters:
    None. This stored procedure does not accept any paramters or 
    return any values.

Use Example:
    CALL bronze.load_bronze();
=======================================================================
*/


CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
	start_time TIMESTAMP;
	end_time TIMESTAMP;
BEGIN

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '==========================================';

    RAISE NOTICE '------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------';

	start_time := clock_timestamp();
    -- Load CRM Customer Information
    RAISE NOTICE '>> Truncating Table: bronze.crm_cust_info';

    TRUNCATE TABLE bronze.crm_cust_info;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_cust_info';

    EXECUTE '
        COPY bronze.crm_cust_info
        FROM ''/datasets/source_crm/cust_info.csv''
        WITH (
            FORMAT csv,
            HEADER true,
            DELIMITER '',''
        )
    ';


    -- Load CRM Product Information
    RAISE NOTICE '>> Truncating Table: bronze.crm_prd_info';

    TRUNCATE TABLE bronze.crm_prd_info;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_prd_info';

    EXECUTE '
        COPY bronze.crm_prd_info
        FROM ''/datasets/source_crm/prd_info.csv''
        WITH (
            FORMAT csv,
            HEADER true,
            DELIMITER '',''
        )
    ';


    -- Load CRM Sales Details
    RAISE NOTICE '>> Truncating Table: bronze.crm_sales_details';

    TRUNCATE TABLE bronze.crm_sales_details;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_sales_details';

    EXECUTE '
        COPY bronze.crm_sales_details
        FROM ''/datasets/source_crm/sales_details.csv''
        WITH (
            FORMAT csv,
            HEADER true,
            DELIMITER '',''
        )
    ';


    RAISE NOTICE '------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '------------------------------------------';

    -- Load ERP Customer Information
    RAISE NOTICE '>> Truncating Table: bronze.erp_cust_az12';

    TRUNCATE TABLE bronze.erp_cust_az12;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_cust_az12';

    EXECUTE '
        COPY bronze.erp_cust_az12
        FROM ''/datasets/source_erp/cust_az12.csv''
        WITH (
            FORMAT csv,
            HEADER true,
            DELIMITER '',''
        )
    ';


    -- Load ERP Location Information
    RAISE NOTICE '>> Truncating Table: bronze.erp_loc_a101';

    TRUNCATE TABLE bronze.erp_loc_a101;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_loc_a101';

    EXECUTE '
        COPY bronze.erp_loc_a101
        FROM ''/datasets/source_erp/loc_a101.csv''
        WITH (
            FORMAT csv,
            HEADER true,
            DELIMITER '',''
        )
    ';


    -- Load ERP Product Category Information
    RAISE NOTICE '>> Truncating Table: bronze.erp_px_cat_g1v2';

    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_px_cat_g1v2';

    EXECUTE '
        COPY bronze.erp_px_cat_g1v2
        FROM ''/datasets/source_erp/px_cat_g1v2.csv''
        WITH (
            FORMAT csv,
            HEADER true,
            DELIMITER '',''
        )
    ';


    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Bronze Layer Load Completed';
    RAISE NOTICE '==========================================';

    end_time := clock_timestamp();

	RAISE NOTICE 'Start Time: %', start_time;
    RAISE NOTICE 'End Time: %', end_time;
    RAISE NOTICE 'Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);

EXCEPTION
	WHEN OTHERS THEN

        RAISE NOTICE '==========================================';
        RAISE NOTICE 'ERROR OCCURRED WHILE LOADING BRONZE LAYER';
        RAISE NOTICE '==========================================';

        RAISE NOTICE 'Error: %', SQLERRM;
        RAISE NOTICE 'SQLSTATE: %', SQLSTATE;

        RAISE;

END;
$$;

CALL bronze.load_bronze();