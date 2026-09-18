/*
===============================================================================
Database Initialization Script
===============================================================================

Purpose:
    Initialize the schemas required for the SQL Data Warehouse project.

Important:
    The database itself is created automatically by Docker Compose when the
    PostgreSQL container is initialized.

    Docker Compose configuration:
        POSTGRES_DB: datawarehouse

    Therefore, this script does NOT create or drop the database.

    Connect to the "datawarehouse" database before running this script.

PostgreSQL Notes:
    - Database selection is handled by the connection/client.
    - Schemas are created only if they do not already exist.
===============================================================================
*/

-- Verify the current database
SELECT current_database() AS current_database;

-- Create Data Warehouse schemas
CREATE SCHEMA IF NOT EXISTS bronze;

CREATE SCHEMA IF NOT EXISTS silver;

CREATE SCHEMA IF NOT EXISTS gold;

