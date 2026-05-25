-- ============================================================
-- STEP 2: CREATE STAGING TABLE
-- Why: Staging table mirrors the CSV exactly.
--      All columns VARCHAR first — we validate then convert.
--      This is industry standard ETL practice.
-- ============================================================

USE SupplyChainDB;
GO

DROP TABLE IF EXISTS dbo.stg_supplychain;

CREATE TABLE dbo.stg_supplychain (
    payment_type              VARCHAR(50),
    days_shipping_real        INT,
    days_shipping_scheduled   INT,
    late_delivery_risk        INT,
    delivery_status           VARCHAR(50),
    shipping_mode             VARCHAR(50),
    order_region              VARCHAR(100),
    order_status              VARCHAR(50),
    order_id                  INT,
    order_item_id             INT,
    order_qty                 INT,
    unit_price                FLOAT,
    sales                     FLOAT,
    discount                  FLOAT,
    profit                    FLOAT,
    customer_city             VARCHAR(100),
    customer_country          VARCHAR(100),
    customer_segment          VARCHAR(50),
    customer_state            VARCHAR(100),
    product_name              VARCHAR(200),
    category_name             VARCHAR(100),
    department_name           VARCHAR(100),
    market                    VARCHAR(100),
    order_date                DATETIME,
    ship_date                 DATETIME,
    order_year                INT,
    order_month               INT,
    order_quarter             INT,
    order_dow                 VARCHAR(20),
    is_full_year              INT,
    is_on_time                INT,
    is_complete               INT,
    is_qty_fulfilled          INT,
    is_otif                   INT,
    is_sla_breach             INT,
    days_variance             INT,
    is_perfect_order          INT
);
GO

PRINT 'Staging table created — 37 columns ready for import';