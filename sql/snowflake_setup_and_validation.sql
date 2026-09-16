-- =============================================================================
-- Snowflake Setup and Validation Script
-- Context: SYSADMIN / DWH_MIGRATIONS / TOMWALL_DB / TOMWALL_SCHEMA2
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE DWH_MIGRATIONS;
USE DATABASE TOMWALL_DB;
USE SCHEMA TOMWALL_SCHEMA2;

-- -----------------------------------------------------------------------------
-- 1. SETUP: Create Raw Source Tables
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE RAW_CUSTOMERS (
    ID NUMBER(38,0),
    FIRST_NAME VARCHAR(100),
    LAST_NAME VARCHAR(100),
    EMAIL VARCHAR(255),
    CREATED_AT TIMESTAMP_NTZ(9)
);

CREATE OR REPLACE TABLE RAW_ORDERS (
    ID NUMBER(38,0),
    CUSTOMER_ID NUMBER(38,0),
    ORDER_DATE DATE,
    STATUS VARCHAR(50),
    AMOUNT NUMBER(10,2),
    UPDATED_AT TIMESTAMP_NTZ(9)
);

-- -----------------------------------------------------------------------------
-- 2. SEED: Insert Sample Raw Records
-- -----------------------------------------------------------------------------
INSERT INTO RAW_CUSTOMERS (ID, FIRST_NAME, LAST_NAME, EMAIL, CREATED_AT) VALUES
    (1, 'Alice', 'Morgan', 'alice.morgan@example.com', '2026-01-15 08:30:00'),
    (2, 'Bob', 'Smith', 'bob.smith@example.com', '2026-01-20 11:15:00'),
    (3, 'Charlie', 'Davis', 'charlie.davis@example.com', '2026-02-05 14:45:00'),
    (4, 'Diana', 'Prince', 'diana.prince@example.com', '2026-02-18 09:00:00'),
    (5, 'Evan', 'Wright', 'evan.wright@example.com', '2026-03-01 16:20:00'),
    (6, 'Fiona', 'Gallagher', 'fiona.g@example.com', '2026-03-10 10:10:00');

INSERT INTO RAW_ORDERS (ID, CUSTOMER_ID, ORDER_DATE, STATUS, AMOUNT, UPDATED_AT) VALUES
    (101, 1, '2026-01-16', 'COMPLETED', 149.99, '2026-01-16 10:00:00'),
    (102, 1, '2026-02-10', 'COMPLETED', 89.50, '2026-02-10 12:30:00'),
    (103, 2, '2026-01-22', 'COMPLETED', 299.00, '2026-01-22 15:00:00'),
    (104, 2, '2026-02-15', 'CANCELLED', 45.00, '2026-02-15 09:15:00'),
    (105, 3, '2026-02-06', 'COMPLETED', 420.75, '2026-02-06 18:20:00'),
    (106, 3, '2026-03-02', 'COMPLETED', 60.00, '2026-03-02 11:45:00'),
    (107, 4, '2026-02-20', 'PENDING', 125.20, '2026-02-20 14:00:00'),
    (108, 5, '2026-03-05', 'COMPLETED', 310.40, '2026-03-05 16:50:00'),
    (109, 1, '2026-03-12', 'COMPLETED', 55.10, '2026-03-12 13:10:00');

-- -----------------------------------------------------------------------------
-- 3. VALIDATION: Raw Tables
-- -----------------------------------------------------------------------------
SELECT * FROM TOMWALL_DB.TOMWALL_SCHEMA2.RAW_CUSTOMERS;
SELECT * FROM TOMWALL_DB.TOMWALL_SCHEMA2.RAW_ORDERS;

-- Check for orphan orders (should return 0 rows)
SELECT o.id AS order_id, o.customer_id
FROM TOMWALL_DB.TOMWALL_SCHEMA2.RAW_ORDERS o
LEFT JOIN TOMWALL_DB.TOMWALL_SCHEMA2.RAW_CUSTOMERS c ON o.customer_id = c.id
WHERE c.id IS NULL;

-- -----------------------------------------------------------------------------
-- 4. VALIDATION: Transformed Models (Run After `dbt run`)
-- -----------------------------------------------------------------------------

-- Staging orders view
SELECT order_id, customer_id, order_date, order_status, order_amount_usd
FROM TOMWALL_DB.TOMWALL_SCHEMA2.STG_ORDERS;

-- Dimension: Customer 360 & lifetime metrics
SELECT 
    customer_id,
    first_name,
    email_address,
    first_order_date,
    most_recent_order_date,
    total_lifetime_orders,
    total_lifetime_spend_usd,
    is_active_buyer
FROM TOMWALL_DB.TOMWALL_SCHEMA2.DIM_CUSTOMERS
ORDER BY customer_id;

-- Fact: Daily sales aggregations
SELECT 
    sales_date,
    total_orders,
    unique_customers,
    gross_revenue_usd,
    dbt_updated_at
FROM TOMWALL_DB.TOMWALL_SCHEMA2.FCT_DAILY_SALES
ORDER BY sales_date;

-- Row counts across all layers
SELECT 'RAW_CUSTOMERS' AS table_name, COUNT(*) AS row_count FROM TOMWALL_DB.TOMWALL_SCHEMA2.RAW_CUSTOMERS
UNION ALL
SELECT 'RAW_ORDERS', COUNT(*) FROM TOMWALL_DB.TOMWALL_SCHEMA2.RAW_ORDERS
UNION ALL
SELECT 'STG_CUSTOMERS', COUNT(*) FROM TOMWALL_DB.TOMWALL_SCHEMA2.STG_CUSTOMERS
UNION ALL
SELECT 'STG_ORDERS', COUNT(*) FROM TOMWALL_DB.TOMWALL_SCHEMA2.STG_ORDERS
UNION ALL
SELECT 'DIM_CUSTOMERS', COUNT(*) FROM TOMWALL_DB.TOMWALL_SCHEMA2.DIM_CUSTOMERS
UNION ALL
SELECT 'FCT_DAILY_SALES', COUNT(*) FROM TOMWALL_DB.TOMWALL_SCHEMA2.FCT_DAILY_SALES;
