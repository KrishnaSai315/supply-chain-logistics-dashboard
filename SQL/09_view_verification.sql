USE SupplyChainDB;
GO

DROP VIEW IF EXISTS dbo.VW_KPI_By_Region;
GO

CREATE VIEW dbo.VW_KPI_By_Region AS
SELECT
    r.order_region,
    r.market,
    f.order_year,
    sh.shipping_mode,          -- ← comes from DIM_Shipping via join
    COUNT(*)                                             AS total_orders,
    ROUND(SUM(f.sales),  2)                              AS total_revenue,
    ROUND(SUM(f.profit), 2)                              AS total_profit,
    ROUND(AVG(CAST(f.is_on_time       AS FLOAT))*100,1) AS otd_rate_pct,
    ROUND(AVG(CAST(f.is_otif          AS FLOAT))*100,1) AS otif_rate_pct,
    ROUND(AVG(CAST(f.is_sla_breach    AS FLOAT))*100,1) AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_perfect_order AS FLOAT))*100,1) AS perfect_order_pct,
    ROUND(AVG(CAST(f.days_shipping_real AS FLOAT)),1)   AS avg_days_to_ship,
    ROUND(AVG(CAST(f.days_variance      AS FLOAT)),1)   AS avg_days_variance,
    RANK() OVER (
        ORDER BY AVG(CAST(f.is_on_time AS FLOAT)) ASC
    )                                                    AS otd_rank_worst_first
FROM dbo.FACT_Orders f
JOIN dbo.DIM_Region   r  ON r.region_key   = f.region_key
JOIN dbo.DIM_Shipping sh ON sh.shipping_key = f.shipping_key  -- ← ADD THIS
GROUP BY 
    r.order_region, 
    r.market, 
    f.order_year, 
    sh.shipping_mode;
GO

-- Verify
SELECT TOP 10 
    order_region, 
    order_year, 
    shipping_mode, 
    total_orders,
    otd_rate_pct
FROM dbo.VW_KPI_By_Region
ORDER BY order_region, order_year, shipping_mode;

PRINT ' VW_KPI_By_Region rebuilt correctly';