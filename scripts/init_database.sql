/*
==================================================
Create Database and Schemas
==================================================

Script Purpose:
    This script creates a new database named 'DataWarehouseKirin' after checking if it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
    within the database: 'bronze', 'silver', and 'gold'.


WARNING:
    Running this script will drop the entire 'DataWarehouseKirin' database if it exists.
    All data in the database will be permanently deleted. Proceed with caution
    and ensure you have proper backups before running this script.

*/

USE master;
GO

-- Drop and recreate the "DataWareHouseKirin" database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = ' DataWarehouseKirin')
BEGIN
  ALTER DATABASE DataWarehouseKirin SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE DateWarehouseKirin;
END
GO

--Creating Datawarehouse
CREATE DATABASE DataWarehouseKirin;
GO

USE DataWarehouseKirin;
GO
  
CREATE SCHEMA bronze;
GO
  
CREATE SCHEMA silver;
GO
  
CREATE SCHEMA gold;
GO
