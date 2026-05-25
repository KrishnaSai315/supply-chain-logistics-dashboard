-- ============================================================
-- STEP 3: BULK IMPORT CLEAN CSV INTO STAGING TABLE
-- Why: BULK INSERT loads 180,000 rows in seconds.
--      Much faster than SSMS Import Wizard for large files.
-- ============================================================

USE SupplyChainDB;
GO

BULK INSERT dbo.stg_supplychain
FROM 'D:\AG\Supply chain project\Python\supplychain_clean.csv'
WITH (
    FIRSTROW        = 2,      -- Row 1 is the header, start data from row 2
    FIELDTERMINATOR = ',',    -- Columns are separated by commas
    ROWTERMINATOR   = '\n',   -- Each row ends with a new line
    TABLOCK                   -- Lock the whole table for faster loading
);
GO

-- Immediately verify the import worked
SELECT 
    COUNT(*)                     AS total_rows,
    MIN(order_date)              AS earliest_order,
    MAX(order_date)              AS latest_order,
    COUNT(DISTINCT order_id)     AS unique_orders,
    COUNT(DISTINCT order_region) AS unique_regions
FROM dbo.stg_supplychain;