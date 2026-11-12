# PostgreSQL Data Warehouse Data Catalog

## Project overview

This project builds a PostgreSQL data warehouse from CRM and ERP CSV files. Data is loaded and refined through three schemas:

`bronze` → `silver` → `gold`

The Bronze layer holds source-shaped data, Silver applies cleaning and standardization, and Gold exposes business-facing dimensions and sales facts. The Gold objects described here are views. Exact deployed definitions should be checked against the project SQL before treating this catalog as a schema contract.

## Layers and objects

### Bronze — raw source tables

Bronze tables are loaded from CSV files by `bronze.load_bronze()`. The load process truncates tables before loading; therefore this is a full refresh pattern, not an append or history-preserving load.

| Object | Columns (meaning) |
|---|---|
| `bronze.crm_cust_info` | `cst_id` (CRM customer ID), `cst_key` (customer business key), `cst_firstname`, `cst_lastname`, `cst_marital_status`, `cst_gndr`, `cst_create_date` |
| `bronze.crm_prd_info` | `prd_id` (product ID), `prd_key` (product key), `prd_nm` (product name), `prd_cost`, `prd_line` (source product-line code), `prd_start_dt`, `prd_end_dt` |
| `bronze.crm_sales_details` | `sls_ord_num` (order number), `sls_prd_key` (product key), `sls_cust_id` (customer ID), `sls_order_dt` (source date text), `sls_ship_dt`, `sls_due_dt`, `sls_sales`, `sls_quantity`, `sls_price` |
| `bronze.erp_cust_az12` | `cid` (customer identifier), `bdate` (birth date), `gen` (gender) |
| `bronze.erp_loc_a101` | `cid` (customer identifier), `cntry` (country) |
| `bronze.erp_px_cat_g1v2` | `id` (category/product reference), `cat` (category), `subcat` (subcategory), `maintenance` (maintenance attribute) |

These column descriptions are based on the DDL shared in the conversation. Types are omitted here; confirm the current DDL for exact types. The CRM customer DDL later adds `dwh_create_date` as a warehouse load timestamp, but it is unclear whether that column remains in the current Bronze table.

### Silver — cleaned and standardized tables

The Silver load procedure reads Bronze data, truncates Silver targets, transforms values, and records load timing/progress. The conversation names these six Silver tables. Their column lists below are limited to fields explicitly shown or strongly indicated by the discussed transformations; verify against the current Silver DDL.

| Object | Known columns and meaning |
|---|---|
| `silver.crm_cust_info` | `cst_id`, `cst_key`, `cst_firstname`, `cst_lastname`, `cst_marital_status`, `cst_gndr`, `cst_create_date`; cleaned customer attributes. A warehouse load timestamp may also be present; its Silver inclusion is not established. |
| `silver.crm_prd_info` | `prd_id`, `cat_id` (derived category ID), `prd_key` (product key with category prefix removed), `prd_nm`, `prd_cost`, `prd_line`, `prd_start_dt`, `prd_end_dt` (derived end of validity period where applicable). |
| `silver.crm_sales_details` | Sales/order fields corresponding to the Bronze sales source; the conversation discusses date validation/conversion and consistency among sales, quantity, and price. Exact cleaned column types and final names are not available. |
| `silver.erp_cust_az12` | `cid`, `bdate`, `gen`; customer birth date and gender attributes. Exact cleanup details are not available. |
| `silver.erp_loc_a101` | `cid`, `cntry`; customer country. Country values are standardized (for example, DE/Germany to Germany and US/USA/United States to United States); other explicit mappings include United Kingdom, France, Australia, and Canada. |
| `silver.erp_px_cat_g1v2` | `id`, `cat`, `subcat`, `maintenance`; product category lookup attributes. Exact Silver transformations are not available. |

### Gold — business-facing views

#### `gold.dim_customers`

Combines CRM customer data with ERP customer and location attributes.

| Column | Meaning |
|---|---|
| `customer_key` | Generated row number ordered by CRM `cst_id`; view-generated key, not a persisted surrogate key. |
| `customer_id` | CRM `cst_id`. |
| `customer_number` | CRM `cst_key`. |
| `first_name`, `last_name` | CRM customer names. |
| `country` | ERP location `cntry`. |
| `marital_status` | CRM marital status. |
| `gender` | CRM gender when not `n/a`; otherwise ERP gender, defaulting to `n/a`. |
| `create_date` | CRM customer create date. |
| `dwh_create_date` | Warehouse create/load timestamp if present in the joined CRM Silver source. |
| `birthdate` | ERP customer `bdate`. |

Joins: CRM customer `cst_key` to ERP customer `cid`, and CRM customer `cst_key` to ERP location `cid`; both are left joins.

#### `gold.dim_products`

Shows current product records enriched with category information.

| Column | Meaning |
|---|---|
| `product_key` | Generated row number ordered by product start date and product key. |
| `product_id` | CRM product `prd_id`. |
| `product_number` | CRM product `prd_key`. |
| `product_name` | Product name (`prd_nm`). |
| `category_id` | Product category ID (`cat_id`). |
| `category`, `subcategory` | Category lookup labels from ERP. |
| `maintenance` | Category maintenance attribute. |
| `cost` | Product cost. |
| `product_line` | Product line description. |
| `start_date` | Product validity start date. |

The view left-joins `silver.crm_prd_info` to `silver.erp_px_cat_g1v2` on `cat_id = id` and filters to rows where `prd_end_dt IS NULL`, excluding historical product versions.

#### `gold.fact_sales`

Sales fact view built from `silver.crm_sales_details`, joined to the Gold product and customer dimensions.

Known columns from the shared definition:

| Column | Meaning |
|---|---|
| `order_number` | Source order number (`sls_ord_num`). |
| `product_key` | Matching Gold product dimension key. |
| `customer_key` | Matching Gold customer dimension key. |
| `order_date`, `shipping_date`, `due_date` | Order, ship, and due dates. |
| `sales_amount` | Sales amount (`sls_sales`). |
| `quantity` | Quantity sold (`sls_quantity`). |
| `price` | Source sales price (`sls_price`), if included in the final select. |

The conversation excerpt does not include the complete final SELECT list or join predicates for this view. Confirm the actual SQL for the authoritative column list and relationship keys.

## Transformations and business rules

- Customer rows are de-duplicated using `ROW_NUMBER()` partitioned by `cst_id`, keeping the latest `cst_create_date`.
- Customer names are trimmed. Marital status codes `S` and `M` become Single and Married. Gender codes `F` and `M` become Female and Male; unrecognized values become `n/a`.
- Product `cat_id` is derived from the product key prefix by replacing a hyphen with an underscore; the product key is extracted from the remaining portion.
- Null product costs are replaced with 0. Product-line codes map `M` → Mountain, `R` → Road, `S` → Other Sales, `T` → Touring; other values become `n/a`.
- Product validity end dates are derived using the next `prd_start_dt` within a product-key partition, minus one day. Gold keeps rows with no end date as current.
- Customer gender in Gold prefers CRM when available and falls back to ERP.
- Sales unit price can be calculated as `sls_sales / NULLIF(sls_quantity, 0)`; zero quantity yields NULL for that calculation. It is not established whether this derived value is included in `gold.fact_sales`.
- Source sales order date is stored as text in the Bronze DDL; Silver validation/conversion is discussed, but exact final type and treatment are not confirmed.

## Relationships

- `gold.fact_sales.product_key` is intended to identify a row in `gold.dim_products`.
- `gold.fact_sales.customer_key` is intended to identify a row in `gold.dim_customers`.
- The Gold customer and product keys are generated with `ROW_NUMBER()` in views. Their values can change when source rows or sort order change; they are not documented as stable persisted keys.
- Customer enrichment joins use customer business identifiers (`cst_key` to ERP `cid`).
- Product enrichment joins use category identifiers (`cat_id` to ERP `id`).
