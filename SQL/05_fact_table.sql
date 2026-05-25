USE SupplyChainDB;
GO

-- ─────────────────────────────────────────
-- Drop and recreate FACT_Orders cleanly
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS dbo.FACT_Orders;
GO

CREATE TABLE dbo.FACT_Orders (
    fact_key                INT IDENTITY(1,1) PRIMARY KEY,
    order_id                INT,
    order_item_id           INT,
    shipping_key            INT,
    region_key              INT,
    geo_key                 INT,
    product_key             INT,
    customer_key            INT,
    date_key                INT,
    order_date              DATETIME,
    ship_date               DATETIME,
    order_year              INT,
    order_month             INT,
    order_quarter           INT,
    order_dow               VARCHAR(20),
    is_full_year            INT,
    payment_type            VARCHAR(50),
    days_shipping_real      INT,
    days_shipping_scheduled INT,
    days_variance           INT,
    late_delivery_risk      INT,
    delivery_status         VARCHAR(50),
    order_status            VARCHAR(50),
    is_on_time              INT,
    is_complete             INT,
    is_qty_fulfilled        INT,
    is_otif                 INT,
    is_sla_breach           INT,
    is_perfect_order        INT,
    order_qty               INT,
    unit_price              FLOAT,
    sales                   FLOAT,
    discount                FLOAT,
    profit                  FLOAT
);
GO

-- ─────────────────────────────────────────
-- Insert with CORRECT join conditions
-- Key fix: include order_region + market
-- in the geography join to prevent fan trap
-- ─────────────────────────────────────────
INSERT INTO dbo.FACT_Orders (
    order_id, order_item_id,
    shipping_key, region_key, geo_key,
    product_key, customer_key, date_key,
    order_date, ship_date,
    order_year, order_month, order_quarter,
    order_dow, is_full_year,
    payment_type,
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
    s.order_dow, s.is_full_year,
    s.payment_type,
    s.days_shipping_real, s.days_shipping_scheduled, s.days_variance,
    s.late_delivery_risk, s.delivery_status, s.order_status,
    s.is_on_time, s.is_complete, s.is_qty_fulfilled,
    s.is_otif, s.is_sla_breach, s.is_perfect_order,
    s.order_qty, s.unit_price, s.sales, s.discount, s.profit

FROM dbo.stg_supplychain s

JOIN dbo.DIM_Shipping sh
    ON sh.shipping_mode = s.shipping_mode

JOIN dbo.DIM_Region r
    ON  r.order_region  = s.order_region
    AND r.market        = s.market

JOIN dbo.DIM_Geography g
    ON  g.customer_city     = s.customer_city
    AND g.customer_state    = s.customer_state
    AND g.customer_country  = s.customer_country
    AND g.order_region      = s.order_region    -- ← FAN TRAP FIX
    AND g.market            = s.market          -- ← FAN TRAP FIX

JOIN dbo.DIM_Product p
    ON  p.product_name      = s.product_name
    AND p.category_name     = s.category_name
    AND p.department_name   = s.department_name

JOIN dbo.DIM_Customer c
    ON c.customer_segment = s.customer_segment;
GO

-- ─────────────────────────────────────────
-- Verify — must match original numbers
-- ─────────────────────────────────────────
SELECT
    COUNT(*)                 AS total_fact_rows,   -- Must be: 180,519
    COUNT(DISTINCT order_id) AS unique_orders,     -- Must be:  65,752
    ROUND(SUM(sales),  2)    AS total_revenue,     -- Must be:  36,784,735.01
    ROUND(SUM(profit), 2)    AS total_profit       -- Must be:   3,966,902.97
FROM dbo.FACT_Orders;
GO

PRINT ' FACT_Orders rebuilt — fan trap resolved';