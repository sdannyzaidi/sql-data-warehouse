
/*
=======================================================================
Script: Gold Layer - Dimension and Fact Views
=======================================================================
Script Purpose:
    Creates business-ready views in the Gold layer of the Data Warehouse.

    The Gold layer consists of:
    - gold.dim_customers: Customer dimension.
    - gold.dim_products: Product dimension.
    - gold.fact_sales: Sales fact view.

Data Sources:
    Silver Layer

=======================================================================
*/


-- =====================================================================
-- DIMENSION: gold.dim_customers
-- =====================================================================
-- Description:
--     Combines customer information from CRM and ERP sources.
--     Uses CRM as the master source for gender information.
-- =====================================================================

CREATE OR REPLACE VIEW gold.dim_customers AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY ci.cst_id
    ) AS customer_key,

    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    ela.cntry AS country,
    ci.cst_marital_status AS marital_status,

    CASE
        WHEN ci.cst_gndr != 'n/a'
            THEN ci.cst_gndr
        -- CRM is the master source for gender information
        ELSE COALESCE(eca.gen, 'n/a')
    END AS gender,

    ci.cst_create_date AS create_date,
    ci.dwh_create_date,
    eca.bdate AS birthdate

FROM silver.crm_cust_info AS ci

LEFT JOIN silver.erp_cust_az12 AS eca
    ON ci.cst_key = eca.cid

LEFT JOIN silver.erp_loc_a101 AS ela
    ON ci.cst_key = ela.cid;


-- =====================================================================
-- DIMENSION: gold.dim_products
-- =====================================================================
-- Description:
--     Combines CRM product information with ERP product categories.
--     Filters out historical product records by selecting only
--     currently active product records.
-- =====================================================================

CREATE OR REPLACE VIEW gold.dim_products AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            pn.prd_start_dt,
            pn.prd_key
    ) AS product_key,

    pn.prd_id AS product_id,
    pn.prd_key AS product_number,
    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date

FROM silver.crm_prd_info AS pn

LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id

WHERE pn.prd_end_dt IS NULL;


-- =====================================================================
-- FACT: gold.fact_sales
-- =====================================================================
-- Description:
--     Combines sales transaction data with customer and product
--     dimension views.
--     Uses dimension surrogate keys to establish relationships
--     between the fact and dimension views.
-- =====================================================================

CREATE OR REPLACE VIEW gold.fact_sales AS

SELECT
    sd.sls_ord_num AS order_number,
    pr.product_key,
    cu.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price

FROM silver.crm_sales_details AS sd

LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;


-- =====================================================================
-- END OF GOLD LAYER DDL SCRIPT
-- =====================================================================
