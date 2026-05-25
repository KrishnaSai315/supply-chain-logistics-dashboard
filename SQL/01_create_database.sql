-- ============================================================
-- CREATE DATABASE
-- ============================================================

USE master;
GO

-- Drop if exists (clean start)
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'SupplyChainDB')
BEGIN
    ALTER DATABASE SupplyChainDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SupplyChainDB;
END
GO

-- Create fresh database
CREATE DATABASE SupplyChainDB;
GO

-- Switch into it
USE SupplyChainDB;
GO

PRINT ' SupplyChainDB created successfully';