-- =============================================================================
-- BigQuery Setup and Validation Script
-- Target: prabha-test.ecommerce_dataset
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. SETUP: Create Dataset and Raw Tables
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `prabha-test.ecommerce_dataset`;

CREATE OR REPLACE TABLE `prabha-test.ecommerce_dataset.raw_customers` (
    id INT64,
    first_name STRING,
    last_name STRING,
    email STRING,
    created_at TIMESTAMP
);

CREATE OR REPLACE TABLE `prabha-test.ecommerce_dataset.raw_orders` (
    id INT64,
    customer_id INT64,
    order_date DATE,
    status STRING,
    amount NUMERIC,
    updated_at TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 2. SEED: Insert Sample Raw Records
-- -----------------------------------------------------------------------------
INSERT INTO `prabha-test.ecommerce_dataset.raw_customers` (id, first_name, last_name, email, created_at)
VALUES
    (1, 'Alice', 'Morgan', 'alice.morgan@example.com', TIMESTAMP('2026-01-15 08:30:00 UTC')),
    (2, 'Bob', 'Smith', 'bob.smith@example.com', TIMESTAMP('2026-01-20 11:15:00 UTC')),
    (3, 'Charlie', 'Davis', 'charlie.davis@example.com', TIMESTAMP('2026-02-05 14:45:00 UTC')),
    (4, 'Diana', 'Prince', 'diana.prince@example.com', TIMESTAMP('2026-02-18 09:00:00 UTC')),
    (5, 'Evan', 'Wright', 'evan.wright@example.com', TIMESTAMP('2026-03-01 16:20:00 UTC')),
    (6, 'Fiona', 'Gallagher', 'fiona.g@example.com', TIMESTAMP('2026-03-10 10:10:00 UTC'));

INSERT INTO `prabha-test.ecommerce_dataset.raw_orders` (id, customer_id, order_date, status, amount, updated_at)
VALUES
    (101, 1, DATE('2026-01-16'), 'COMPLETED', 149.99, TIMESTAMP('2026-01-16 10:00:00 UTC')),
    (102, 1, DATE('2026-02-10'), 'COMPLETED', 89.50, TIMESTAMP('2026-02-10 12:30:00 UTC')),
    (103, 2, DATE('2026-01-22'), 'COMPLETED', 299.00, TIMESTAMP('2026-01-22 15:00:00 UTC')),
    (104, 2, DATE('2026-02-15'), 'CANCELLED', 45.00, TIMESTAMP('2026-02-15 09:15:00 UTC')),
    (105, 3, DATE('2026-02-06'), 'COMPLETED', 420.75, TIMESTAMP('2026-02-06 18:20:00 UTC')),
    (106, 3, DATE('2026-03-02'), 'COMPLETED', 60.00, TIMESTAMP('2026-03-02 11:45:00 UTC')),
    (107, 4, DATE('2026-02-20'), 'PENDING', 125.20, TIMESTAMP('2026-02-20 14:00:00 UTC')),
    (108, 5, DATE('2026-03-05'), 'COMPLETED', 310.40, TIMESTAMP('2026-03-05 16:50:00 UTC')),
    (109, 1, DATE('2026-03-12'), 'COMPLETED', 55.10, TIMESTAMP('2026-03-12 13:10:00 UTC'));

-- -----------------------------------------------------------------------------
-- 3. VALIDATION: Raw Tables & Integrity
-- -----------------------------------------------------------------------------
SELECT * FROM `prabha-test.ecommerce_dataset.raw_customers`;
SELECT * FROM `prabha-test.ecommerce_dataset.raw_orders`;

-- Check for orphan orders (should return 0 rows)
SELECT 
    o.id AS order_id, 
    o.customer_id
FROM `prabha-test.ecommerce_dataset.raw_orders` AS o
LEFT JOIN `prabha-test.ecommerce_dataset.raw_customers` AS c 
    ON o.customer_id = c.id
WHERE c.id IS NULL;

-- -----------------------------------------------------------------------------
-- 4. VALIDATION: Transformed Models (Run After `dbt run`)
-- -----------------------------------------------------------------------------

-- Cleansed staging views
SELECT * FROM `prabha-test.ecommerce_dataset.stg_customers` LIMIT 10;

SELECT 
    order_id, 
    customer_id, 
    order_date, 
    order_status, 
    order_amount_usd
FROM `prabha-test.ecommerce_dataset.stg_orders`;

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
FROM `prabha-test.ecommerce_dataset.dim_customers`
ORDER BY customer_id;

-- Fact: Daily sales aggregations
SELECT 
    sales_date,
    total_orders,
    unique_customers,
    gross_revenue_usd,
    dbt_updated_at
FROM `prabha-test.ecommerce_dataset.fct_daily_sales`
ORDER BY sales_date;

-- Row counts across all layers
SELECT 'raw_customers' AS table_name, COUNT(*) AS row_count FROM `prabha-test.ecommerce_dataset.raw_customers`
UNION ALL
SELECT 'raw_orders', COUNT(*) FROM `prabha-test.ecommerce_dataset.raw_orders`
UNION ALL
SELECT 'stg_customers', COUNT(*) FROM `prabha-test.ecommerce_dataset.stg_customers`
UNION ALL
SELECT 'stg_orders', COUNT(*) FROM `prabha-test.ecommerce_dataset.stg_orders`
UNION ALL
SELECT 'dim_customers', COUNT(*) FROM `prabha-test.ecommerce_dataset.dim_customers`
UNION ALL
SELECT 'fct_daily_sales', COUNT(*) FROM `prabha-test.ecommerce_dataset.fct_daily_sales`;
