-- ============================================================
-- VIEW 1: VW_KPI_Summary
-- Purpose: Top-level KPI cards for Power BI dashboard
-- Powers: The 5 KPI cards at top of every dashboard page
-- ============================================================

USE SupplyChainDB;
GO

DROP VIEW IF EXISTS dbo.VW_KPI_Summary;
GO

CREATE VIEW dbo.VW_KPI_Summary AS
SELECT
    -- Volume metrics
    COUNT(*)                                            AS total_line_items,
    COUNT(DISTINCT order_id)                            AS total_orders,
    SUM(order_qty)                                      AS total_units_sold,

    -- Revenue metrics
    ROUND(SUM(sales), 2)                                AS total_revenue,
    ROUND(SUM(profit), 2)                               AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales),0) * 100, 1) AS profit_margin_pct,

    -- KPI rates (full dataset)
    ROUND(AVG(CAST(is_on_time       AS FLOAT))*100, 1) AS otd_rate_pct,
    ROUND(AVG(CAST(is_otif          AS FLOAT))*100, 1) AS otif_rate_pct,
    ROUND(AVG(CAST(is_sla_breach    AS FLOAT))*100, 1) AS sla_breach_pct,
    ROUND(AVG(CAST(is_perfect_order AS FLOAT))*100, 1) AS perfect_order_pct,
    ROUND(AVG(CAST(is_complete      AS FLOAT))*100, 1) AS complete_order_pct,

    -- Shipping efficiency
    ROUND(AVG(CAST(days_shipping_real AS FLOAT)), 1)    AS avg_days_to_ship,
    ROUND(AVG(CAST(days_variance      AS FLOAT)), 1)    AS avg_days_variance

FROM dbo.FACT_Orders;
GO

-- Test it
SELECT * FROM dbo.VW_KPI_Summary;


------------------------------------------------------------------------------------
-- ============================================================
-- VIEW 2: VW_KPI_By_ShippingMode
-- Purpose: Performance breakdown by shipping mode
-- Powers: The "First Class = 100% SLA breach" finding
-- ============================================================

USE SupplyChainDB;
GO

DROP VIEW IF EXISTS dbo.VW_KPI_By_ShippingMode;
GO

CREATE VIEW dbo.VW_KPI_By_ShippingMode AS
SELECT
    sh.shipping_mode,
    COUNT(*)                                             AS total_orders,
    ROUND(SUM(f.sales), 2)                               AS total_revenue,

    -- Core KPIs
    ROUND(AVG(CAST(f.is_on_time       AS FLOAT))*100,1) AS otd_rate_pct,
    ROUND(AVG(CAST(f.is_otif          AS FLOAT))*100,1) AS otif_rate_pct,
    ROUND(AVG(CAST(f.is_sla_breach    AS FLOAT))*100,1) AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_perfect_order AS FLOAT))*100,1) AS perfect_order_pct,

    -- Shipping time analysis
    ROUND(AVG(CAST(f.days_shipping_real      AS FLOAT)),1) AS avg_actual_days,
    ROUND(AVG(CAST(f.days_shipping_scheduled AS FLOAT)),1) AS avg_promised_days,
    ROUND(AVG(CAST(f.days_variance           AS FLOAT)),1) AS avg_days_variance,

    -- Volume split
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)   AS pct_of_total_orders

FROM dbo.FACT_Orders f
JOIN dbo.DIM_Shipping sh ON sh.shipping_key = f.shipping_key
GROUP BY sh.shipping_mode;
GO

-- Test it
SELECT * FROM dbo.VW_KPI_By_ShippingMode
ORDER BY sla_breach_pct DESC;



-----------------------------------------------------------------------------------------

-- ============================================================
-- VIEW 3: VW_KPI_By_Region
-- Purpose: Regional performance — surfaces South of USA story
-- Powers: Regional map and bar chart in Power BI
-- ============================================================

USE SupplyChainDB;
GO

DROP VIEW IF EXISTS dbo.VW_KPI_By_Region;
GO

CREATE VIEW dbo.VW_KPI_By_Region AS
SELECT
    r.order_region,
    r.market,
    COUNT(*)                                             AS total_orders,
    ROUND(SUM(f.sales),  2)                              AS total_revenue,
    ROUND(SUM(f.profit), 2)                              AS total_profit,

    -- Core KPIs
    ROUND(AVG(CAST(f.is_on_time       AS FLOAT))*100,1) AS otd_rate_pct,
    ROUND(AVG(CAST(f.is_otif          AS FLOAT))*100,1) AS otif_rate_pct,
    ROUND(AVG(CAST(f.is_sla_breach    AS FLOAT))*100,1) AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_perfect_order AS FLOAT))*100,1) AS perfect_order_pct,

    -- Shipping time
    ROUND(AVG(CAST(f.days_shipping_real AS FLOAT)),1)   AS avg_days_to_ship,
    ROUND(AVG(CAST(f.days_variance      AS FLOAT)),1)   AS avg_days_variance,

    -- Rank regions by OTD (1 = worst performer)
    RANK() OVER (ORDER BY AVG(CAST(f.is_on_time AS FLOAT)) ASC) AS otd_rank_worst_first

FROM dbo.FACT_Orders f
JOIN dbo.DIM_Region r ON r.region_key = f.region_key
GROUP BY r.order_region, r.market;
GO

-- Test it
SELECT * FROM dbo.VW_KPI_By_Region
ORDER BY otd_rate_pct ASC;


------------------------------------------------------------------------------------------
-- ============================================================
-- VIEW 4: VW_SLA_Heatmap
-- Purpose: Cross analysis of region vs shipping mode
-- Powers: The heatmap visual in Power BI
-- This is the view that proves the hidden delay story
-- ============================================================

USE SupplyChainDB;
GO

DROP VIEW IF EXISTS dbo.VW_SLA_Heatmap;
GO

CREATE VIEW dbo.VW_SLA_Heatmap AS
SELECT
    r.order_region,
    sh.shipping_mode,
    COUNT(*)                                             AS total_orders,

    -- SLA performance
    ROUND(AVG(CAST(f.is_sla_breach AS FLOAT))*100, 1)  AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_on_time    AS FLOAT))*100, 1)  AS otd_rate_pct,
    ROUND(AVG(CAST(f.days_variance AS FLOAT)),    1)    AS avg_days_late,

    -- Flag worst combinations
    CASE
        WHEN AVG(CAST(f.is_sla_breach AS FLOAT)) >= 0.80 THEN 'Critical'
        WHEN AVG(CAST(f.is_sla_breach AS FLOAT)) >= 0.60 THEN 'High Risk'
        WHEN AVG(CAST(f.is_sla_breach AS FLOAT)) >= 0.40 THEN 'Moderate'
        ELSE 'Acceptable'
    END                                                  AS risk_category

FROM dbo.FACT_Orders f
JOIN dbo.DIM_Region   r  ON r.region_key   = f.region_key
JOIN dbo.DIM_Shipping sh ON sh.shipping_key = f.shipping_key
GROUP BY r.order_region, sh.shipping_mode;
GO

-- Test it
SELECT * FROM dbo.VW_SLA_Heatmap
ORDER BY sla_breach_pct DESC;


----------------------------------------------------------------------------------

-- ============================================================
-- VIEW 5: VW_Monthly_Trend
-- Purpose: Month over month KPI trends
-- Powers: Line charts in Power BI
-- Filter to full years only (exclude 2018)
-- ============================================================

USE SupplyChainDB;
GO

DROP VIEW IF EXISTS dbo.VW_Monthly_Trend;
GO

CREATE VIEW dbo.VW_Monthly_Trend AS
SELECT
    f.order_year,
    f.order_month,
    d.month_name,
    f.order_quarter,

    -- Label for X axis in Power BI
    CAST(f.order_year AS VARCHAR) + '-' +
    RIGHT('0' + CAST(f.order_month AS VARCHAR), 2) AS year_month,

    COUNT(*)                                             AS total_orders,
    ROUND(SUM(f.sales),  2)                              AS total_revenue,
    ROUND(SUM(f.profit), 2)                              AS total_profit,

    -- KPI trends
    ROUND(AVG(CAST(f.is_on_time       AS FLOAT))*100,1) AS otd_rate_pct,
    ROUND(AVG(CAST(f.is_otif          AS FLOAT))*100,1) AS otif_rate_pct,
    ROUND(AVG(CAST(f.is_sla_breach    AS FLOAT))*100,1) AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_perfect_order AS FLOAT))*100,1) AS perfect_order_pct,
    ROUND(AVG(CAST(f.days_variance    AS FLOAT)),    1)  AS avg_days_variance

FROM dbo.FACT_Orders f
JOIN dbo.DIM_Date d ON d.date_key = f.date_key
WHERE f.is_full_year = 1            -- Exclude incomplete 2018
GROUP BY
    f.order_year, f.order_month,
    d.month_name, f.order_quarter;
GO

-- Test it
SELECT * FROM dbo.VW_Monthly_Trend
ORDER BY order_year, order_month;
-------------------------------------------------------------------

-- ============================================================
-- VIEW 6: VW_KPI_By_Category
-- Purpose: Which product categories have worst delivery?
-- Powers: Category breakdown table in Power BI
-- ============================================================

USE SupplyChainDB;
GO

DROP VIEW IF EXISTS dbo.VW_KPI_By_Category;
GO

CREATE VIEW dbo.VW_KPI_By_Category AS
SELECT
    p.department_name,
    p.category_name,
    COUNT(*)                                             AS total_orders,
    SUM(f.order_qty)                                     AS total_units,
    ROUND(SUM(f.sales),  2)                              AS total_revenue,
    ROUND(SUM(f.profit), 2)                              AS total_profit,
    ROUND(SUM(f.profit)/NULLIF(SUM(f.sales),0)*100, 1)  AS margin_pct,

    -- Delivery performance
    ROUND(AVG(CAST(f.is_on_time       AS FLOAT))*100,1) AS otd_rate_pct,
    ROUND(AVG(CAST(f.is_sla_breach    AS FLOAT))*100,1) AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_perfect_order AS FLOAT))*100,1) AS perfect_order_pct

FROM dbo.FACT_Orders f
JOIN dbo.DIM_Product p ON p.product_key = f.product_key
GROUP BY p.department_name, p.category_name;
GO

-- Test it
SELECT * FROM dbo.VW_KPI_By_Category
ORDER BY total_revenue DESC;
------------------------------------------------
