-- ============================================================
-- STEP 4: VALIDATE DATA LOADED CORRECTLY
-- Why: Confirm KPI flags match Python output exactly.
--      Never build on top of unvalidated data.
-- ============================================================

USE SupplyChainDB;
GO

-- Validation Query 1: KPI Benchmarks (must match Python output)
SELECT
    ROUND(AVG(CAST(is_on_time       AS FLOAT)) * 100, 1) AS otd_rate_pct,
    ROUND(AVG(CAST(is_otif          AS FLOAT)) * 100, 1) AS otif_rate_pct,
    ROUND(AVG(CAST(is_sla_breach    AS FLOAT)) * 100, 1) AS sla_breach_pct,
    ROUND(AVG(CAST(is_perfect_order AS FLOAT)) * 100, 1) AS perfect_order_pct,
    ROUND(AVG(CAST(is_complete      AS FLOAT)) * 100, 1) AS complete_order_pct,
    COUNT(*)                                              AS total_records
FROM dbo.stg_supplychain;

-- Validation Query 2: Year distribution (must match Python)
SELECT
    order_year,
    COUNT(*) AS record_count
FROM dbo.stg_supplychain
GROUP BY order_year
ORDER BY order_year;

-- Validation Query 3: Shipping mode breakdown
SELECT
    shipping_mode,
    COUNT(*)                                             AS total_orders,
    ROUND(AVG(CAST(is_on_time AS FLOAT)) * 100, 1)     AS otd_rate_pct,
    ROUND(AVG(CAST(is_sla_breach AS FLOAT)) * 100, 1)  AS sla_breach_pct
FROM dbo.stg_supplychain
GROUP BY shipping_mode
ORDER BY sla_breach_pct DESC;

-- Validation Query 4: Region breakdown
SELECT
    order_region,
    COUNT(*)                                             AS total_orders,
    ROUND(AVG(CAST(is_on_time AS FLOAT)) * 100, 1)     AS otd_rate_pct
FROM dbo.stg_supplychain
GROUP BY order_region
ORDER BY otd_rate_pct ASC;