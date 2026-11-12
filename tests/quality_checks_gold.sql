/*
=======================================================================
Script: Gold Layer - Data Quality Checks
=======================================================================
Script Purpose:
    This script performs data quality checks on the Gold layer
    dimension and fact views.

    The checks include:
    - Checking for NULL or duplicate surrogate keys.
    - Validating customer and product information.
    - Checking dimension-to-fact relationships.
    - Identifying unmatched customer and product records.
    - Validating sales, quantity, and price consistency.
    - Checking for unwanted spaces and NULL values.

Expected Results:
    Queries marked "Expectation: No Result" should return no rows
    when the data passes the corresponding quality check.

Note:
    These queries are intended for validation and investigation.
    They do not modify any data.

=======================================================================
*/


-- =====================================================================
-- DIMENSION: gold.dim_customers
-- =====================================================================

-- Check for NULL or Duplicate Customer Keys
-- Expectation: No Result

SELECT
    customer_key,
    COUNT(*)
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1
    OR customer_key IS NULL;


-- Check for NULL or Duplicate Customer IDs
-- Expectation: No Result

SELECT
    customer_id,
    COUNT(*)
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
    OR customer_id IS NULL;


-- Check for unwanted spaces in customer names
-- Expectation: No Result

SELECT
    first_name,
    last_name
FROM gold.dim_customers
WHERE first_name != TRIM(first_name)
    OR last_name != TRIM(last_name);


-- Check for NULL customer information

SELECT *
FROM gold.dim_customers
WHERE customer_number IS NULL
    OR first_name IS NULL
    OR last_name IS NULL;


-- Check data standardization and consistency for gender

SELECT DISTINCT
    gender
FROM gold.dim_customers;


-- =====================================================================
-- DIMENSION: gold.dim_products
-- =====================================================================

-- Check for NULL or Duplicate Product Keys
-- Expectation: No Result

SELECT
    product_key,
    COUNT(*)
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1
    OR product_key IS NULL;


-- Check for NULL or Duplicate Product IDs
-- Expectation: No Result

SELECT
    product_id,
    COUNT(*)
FROM gold.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1
    OR product_id IS NULL;


-- Check for unwanted spaces in product names
-- Expectation: No Result

SELECT
    product_name
FROM gold.dim_products
WHERE product_name != TRIM(product_name);


-- Check for NULL or Negative Product Costs
-- Expectation: No Result

SELECT *
FROM gold.dim_products
WHERE cost < 0
    OR cost IS NULL;


-- Check for NULL Product Information

SELECT *
FROM gold.dim_products
WHERE product_number IS NULL
    OR product_name IS NULL
    OR category IS NULL
    OR subcategory IS NULL;


-- Check data standardization and consistency for product lines

SELECT DISTINCT
    product_line
FROM gold.dim_products;


-- Check for Invalid Product Dates
-- Expectation: No Result

SELECT *
FROM gold.dim_products
WHERE start_date IS NULL;


-- =====================================================================
-- FACT: gold.fact_sales
-- =====================================================================

-- Check for NULL values in order numbers
-- Expectation: No Result

SELECT *
FROM gold.fact_sales
WHERE order_number IS NULL;


-- Check for NULL foreign keys
-- Expectation: No Result

SELECT *
FROM gold.fact_sales
WHERE product_key IS NULL
    OR customer_key IS NULL;


-- Check for unmatched product keys
-- Expectation: No Result

SELECT *
FROM gold.fact_sales
WHERE product_key NOT IN (
    SELECT product_key
    FROM gold.dim_products
);


-- Check for unmatched customer keys
-- Expectation: No Result

SELECT *
FROM gold.fact_sales
WHERE customer_key NOT IN (
    SELECT customer_key
    FROM gold.dim_customers
);

-- Check for NULL or Negative Sales Values
-- Expectation: No Result

SELECT *
FROM gold.fact_sales
WHERE sales_amount IS NULL
    OR sales_amount <= 0
    OR quantity IS NULL
    OR quantity <= 0
    OR sls_price IS NULL
    OR sls_price <= 0;


-- Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Result

SELECT *
FROM gold.fact_sales
WHERE sales_amount != quantity * sls_price;


-- Check for duplicate order, product combinations

SELECT
    order_number,
    product_key,
    COUNT(*)
FROM gold.fact_sales
GROUP BY
    order_number,
    product_key
HAVING COUNT(*) > 1;


-- =====================================================================
-- END OF GOLD LAYER DATA QUALITY CHECKS
-- =====================================================================
