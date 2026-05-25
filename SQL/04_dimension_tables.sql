-- ============================================================
-- BUILD STAR SCHEMA — DIMENSION TABLES
-- Why: Splits flat data into organized lookup tables.
--      Power BI connects these to the fact table via keys.
-- ============================================================

USE SupplyChainDB;
GO

-- ─────────────────────────────────────────
-- DIM_Shipping: Shipping mode reference
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS dbo.DIM_Shipping;

CREATE TABLE dbo.DIM_Shipping (
    shipping_key  INT IDENTITY(1,1) PRIMARY KEY,
    shipping_mode VARCHAR(50) NOT NULL
);

INSERT INTO dbo.DIM_Shipping (shipping_mode)
SELECT DISTINCT shipping_mode
FROM dbo.stg_supplychain
ORDER BY shipping_mode;

PRINT ' DIM_Shipping created — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO

-- ─────────────────────────────────────────
-- DIM_Region: Geographic reference
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS dbo.DIM_Region;

CREATE TABLE dbo.DIM_Region (
    region_key       INT IDENTITY(1,1) PRIMARY KEY,
    order_region     VARCHAR(100) NOT NULL,
    market           VARCHAR(100),
    customer_country VARCHAR(100),
    customer_state   VARCHAR(100),
    customer_city    VARCHAR(100)
);

INSERT INTO dbo.DIM_Region (order_region, market, customer_country, customer_state, customer_city)
SELECT DISTINCT
    order_region,
    market,
    customer_country,
    customer_state,
    customer_city
FROM dbo.stg_supplychain
ORDER BY order_region;

PRINT ' DIM_Region created — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO

-- ─────────────────────────────────────────
-- DIM_Product: Product reference
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS dbo.DIM_Product;

CREATE TABLE dbo.DIM_Product (
    product_key     INT IDENTITY(1,1) PRIMARY KEY,
    product_name    VARCHAR(200) NOT NULL,
    category_name   VARCHAR(100),
    department_name VARCHAR(100)
);

INSERT INTO dbo.DIM_Product (product_name, category_name, department_name)
SELECT DISTINCT
    product_name,
    category_name,
    department_name
FROM dbo.stg_supplychain
ORDER BY product_name;

PRINT ' DIM_Product created — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO

-- ─────────────────────────────────────────
-- DIM_Customer: Customer segment reference
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS dbo.DIM_Customer;

CREATE TABLE dbo.DIM_Customer (
    customer_key     INT IDENTITY(1,1) PRIMARY KEY,
    customer_segment VARCHAR(50) NOT NULL
);

INSERT INTO dbo.DIM_Customer (customer_segment)
SELECT DISTINCT customer_segment
FROM dbo.stg_supplychain
ORDER BY customer_segment;

PRINT 'DIM_Customer created — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO

-- ─────────────────────────────────────────
-- DIM_Date: Calendar reference
-- Why: Every BI project needs a date dimension.
--      Enables month/quarter/year filtering in Power BI.
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS dbo.DIM_Date;

CREATE TABLE dbo.DIM_Date (
    date_key        INT PRIMARY KEY,      -- Format: YYYYMMDD (e.g. 20150101)
    full_date       DATE NOT NULL,
    year            INT,
    quarter         INT,
    month           INT,
    month_name      VARCHAR(20),
    week            INT,
    day_of_month    INT,
    day_name        VARCHAR(20),
    is_weekend      INT,
    is_full_year    INT                   -- 0 for 2018 (incomplete)
);

-- Generate one row per date from 2015-01-01 to 2018-02-03
WITH DateSeries AS (
    SELECT CAST('2015-01-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt)
    FROM DateSeries
    WHERE dt < '2018-02-03'
)
INSERT INTO dbo.DIM_Date
SELECT
    CAST(FORMAT(dt, 'yyyyMMdd') AS INT)  AS date_key,
    dt                                    AS full_date,
    YEAR(dt)                              AS year,
    DATEPART(QUARTER, dt)                 AS quarter,
    MONTH(dt)                             AS month,
    DATENAME(MONTH, dt)                   AS month_name,
    DATEPART(WEEK, dt)                    AS week,
    DAY(dt)                               AS day_of_month,
    DATENAME(WEEKDAY, dt)                 AS day_name,
    CASE WHEN DATEPART(WEEKDAY,dt) IN (1,7) THEN 1 ELSE 0 END AS is_weekend,
    CASE WHEN YEAR(dt) IN (2015,2016,2017) THEN 1 ELSE 0 END  AS is_full_year
FROM DateSeries
OPTION (MAXRECURSION 2000);   -- Allow recursion for 3+ years of dates

PRINT ' DIM_Date created — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO