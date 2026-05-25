USE SupplyChainDB;
GO

-- VERIFICATION 1: Confirm all 6 views exist
SELECT 
    TABLE_NAME AS view_name
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME;

-- VERIFICATION 2: Test every view returns data
SELECT 'VW_KPI_Summary'        AS view_name, COUNT(*) AS rows_returned FROM dbo.VW_KPI_Summary
UNION ALL
SELECT 'VW_KPI_By_ShippingMode', COUNT(*) FROM dbo.VW_KPI_By_ShippingMode
UNION ALL
SELECT 'VW_KPI_By_Region',       COUNT(*) FROM dbo.VW_KPI_By_Region
UNION ALL
SELECT 'VW_SLA_Heatmap',         COUNT(*) FROM dbo.VW_SLA_Heatmap
UNION ALL
SELECT 'VW_Monthly_Trend',       COUNT(*) FROM dbo.VW_Monthly_Trend
UNION ALL
SELECT 'VW_KPI_By_Category',     COUNT(*) FROM dbo.VW_KPI_By_Category;