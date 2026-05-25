-- ============================================================
-- FIX: REBUILD DIM_Region (23 rows only)
-- + CREATE DIM_Geography (city level detail)
-- Why: A region dimension should have one row per region.
--      City/state detail belongs in a separate geo dimension.
-- ============================================================

USE SupplyChainDB;
GO

-- ─────────────────────────────────────────
-- STEP A: Rebuild DIM_Region correctly
-- Should have exactly 23 rows
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS dbo.DIM_Region;

CREATE TABLE dbo.DIM_Region (
    region_key   INT IDENTITY(1,1) PRIMARY KEY,
    order_region VARCHAR(100) NOT NULL,
    market       VARCHAR(100)
);

INSERT INTO dbo.DIM_Region (order_region, market)
SELECT DISTINCT
    order_region,
    market
FROM dbo.stg_supplychain
ORDER BY order_region;

PRINT ' DIM_Region rebuilt — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO

-- ─────────────────────────────────────────
-- STEP B: Create DIM_Geography (city level)
-- Separate from region for clean modeling
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS dbo.DIM_Geography;

CREATE TABLE dbo.DIM_Geography (
    geo_key          INT IDENTITY(1,1) PRIMARY KEY,
    customer_city    VARCHAR(100),
    customer_state   VARCHAR(100),
    customer_country VARCHAR(100),
    order_region     VARCHAR(100),
    market           VARCHAR(100)
);

INSERT INTO dbo.DIM_Geography (
    customer_city, customer_state, 
    customer_country, order_region, market
)
SELECT DISTINCT
    customer_city,
    customer_state,
    customer_country,
    order_region,
    market
FROM dbo.stg_supplychain
ORDER BY customer_country, customer_state, customer_city;

PRINT ' DIM_Geography created — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO

-- ─────────────────────────────────────────
-- STEP C: Rebuild FACT_Orders with
-- correct region_key and new geo_key
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS dbo.FACT_Orders;

CREATE TABLE dbo.FACT_Orders (
    fact_key                INT IDENTITY(1,1) PRIMARY KEY,
    order_id                INT,
    order_item_id           INT,

    -- Foreign keys
    shipping_key            INT,
    region_key              INT,
    geo_key                 INT,
    product_key             INT,
    customer_key            INT,
    date_key                INT,

    -- Dates
    order_date              DATETIME,
    ship_date               DATETIME,
    order_year              INT,
    order_month             INT,
    order_quarter           INT,
    order_dow               VARCHAR(20),
    is_full_year            INT,

    -- Shipping details
    payment_type            VARCHAR(50),
    days_shipping_real      INT,
    days_shipping_scheduled INT,
    days_variance           INT,
    late_delivery_risk      INT,
    delivery_status         VARCHAR(50),
    order_status            VARCHAR(50),

    -- KPI flags
    is_on_time              INT,
    is_complete             INT,
    is_qty_fulfilled        INT,
    is_otif                 INT,
    is_sla_breach           INT,
    is_perfect_order        INT,

    -- Financial measures
    order_qty               INT,
    unit_price              FLOAT,
    sales                   FLOAT,
    discount                FLOAT,
    profit                  FLOAT
);

INSERT INTO dbo.FACT_Orders (
    order_id, order_item_id,
    shipping_key, region_key, geo_key, product_key, customer_key, date_key,
    order_date, ship_date, order_year, order_month, order_quarter,
    order_dow, is_full_year, payment_type,
    days_shipping_real, days_shipping_scheduled, days_variance,
    late_delivery_risk, delivery_status, order_status,
    is_on_time, is_complete, is_qty_fulfilled,
    is_otif, is_sla_breach, is_perfect_order,
    order_qty, unit_price, sales, discount, profit
)
SELECT
    s.order_id,
    s.order_item_id,
    sh.shipping_key,
    r.region_key,
    g.geo_key,
    p.product_key,
    c.customer_key,
    CAST(FORMAT(CAST(s.order_date AS DATE), 'yyyyMMdd') AS INT),
    s.order_date, s.ship_date,
    s.order_year, s.order_month, s.order_quarter,
    s.order_dow, s.is_full_year, s.payment_type,
    s.days_shipping_real, s.days_shipping_scheduled, s.days_variance,
    s.late_delivery_risk, s.delivery_status, s.order_status,
    s.is_on_time, s.is_complete, s.is_qty_fulfilled,
    s.is_otif, s.is_sla_breach, s.is_perfect_order,
    s.order_qty, s.unit_price, s.sales, s.discount, s.profit

FROM dbo.stg_supplychain s
JOIN dbo.DIM_Shipping  sh ON sh.shipping_mode    = s.shipping_mode
JOIN dbo.DIM_Region    r  ON r.order_region      = s.order_region
                          AND r.market           = s.market
JOIN dbo.DIM_Geography g  ON g.customer_city     = s.customer_city
                          AND g.customer_state   = s.customer_state
                          AND g.customer_country = s.customer_country
JOIN dbo.DIM_Product   p  ON p.product_name      = s.product_name
                          AND p.category_name    = s.category_name
                          AND p.department_name  = s.department_name
JOIN dbo.DIM_Customer  c  ON c.customer_segment  = s.customer_segment;
GO

-- Final verification
SELECT
    COUNT(*)                 AS total_fact_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(SUM(sales), 2)     AS total_revenue,
    ROUND(SUM(profit), 2)    AS total_profit
FROM dbo.FACT_Orders;

PRINT 'FACT_Orders rebuilt with correct keys';