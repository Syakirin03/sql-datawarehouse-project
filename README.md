SQL Data Warehouse Project

Building a modern data warehouse with SQL Server, using the Medallion Architecture (Bronze → Silver → Gold) to consolidate CRM and ERP source data into a clean, business-ready analytical model. This is an end-to-end data engineering project covering ETL, data cleansing, data modeling (star schema), and data quality testing.
Overview

Two operational source systems — CRM and ERP — export their data as flat CSV files. This project ingests those files into SQL Server, progressively cleans and standardizes them, and models them into a star schema optimized for reporting, ad-hoc SQL analysis, and machine learning.

Objective: Consolidate sales data from CRM and ERP into a single source of truth that supports analytical reporting and data-driven decision-making, focused on the latest snapshot of the data (no historization required).
Data Architecture
<img width="900" height="501" alt="data_flow_diagram" src="https://github.com/user-attachments/assets/4a1e2f51-ad2e-4463-909d-07dc735b861f" />

The warehouse is built on three layers, each represented by its own SQL Server schema:
Layer	Schema	Purpose	Load Method	Transformation	Data Model
Bronze	bronze	Raw data, as-is from source CSVs	Batch, full load, truncate & insert	None	None
Silver	silver	Cleaned, standardized, business-ready inputs	Batch, full load, truncate & insert	Cleansing, standardization, normalization, derived columns, enrichment	None
Gold	gold	Business-ready data for consumption	Views over Silver	Integration, aggregation, business logic	Star schema, flat/aggregated views

Consumers: BI & reporting tools, ad-hoc SQL queries, and machine learning.
Repository Structure

sql-datawarehouse-project/
│
├── datasets/                          # Raw source CSV files (as delivered by CRM/ERP)
│   ├── source_crm/
│   │   ├── cust_info.csv
│   │   ├── prd_info.csv
│   │   └── sales_details.csv
│   └── source_erp/
│       ├── CUST_AZ12.csv
│       ├── LOC_A101.csv
│       └── PX_CAT_G1V2.csv
│
├── docs/                               # Documentation and diagrams
│   ├── data_architecture_diagram.jpg   # Medallion architecture (this diagram)
│   ├── data_flow_diagram.jpg           # Source-to-gold data flow
│   ├── data_integration_diagram.jpg    # How CRM and ERP entities relate
│   ├── data_mart.jpg                   # Star schema / data mart diagram
│   └── data_catalog.md                 # Field-level catalog for the Gold layer
│
├── scripts/                            # All SQL used to build the warehouse
│   ├── init_database.sql               # Creates the DataWarehouseKirin DB + bronze/silver/gold schemas
│   ├── bronze/
│   │   ├── ddl_bronze.sql              # Table definitions for the Bronze layer
│   │   └── proc_load_bronze.sql        # bronze.load_bronze — bulk-inserts CSVs into Bronze
│   ├── silver/
│   │   ├── ddl_silver.sql              # Table definitions for the Silver layer
│   │   └── proc_load_silver.sql        # silver.load_silver — cleans & loads Bronze → Silver
│   └── gold/
│       └── ddl_gold.sql                # Gold views: dim_customers, dim_products, fact_sales
│
├── tests/
│   └── quality_check_silver.sql        # Data quality checks against the Silver layer
│
├── LICENSE                             # MIT License
└── README.md

Data Flow

CRM/ERP CSVs → Bronze (raw) → Silver (cleansed) → Gold (star schema) → BI / SQL / ML

    Source → Bronze: bronze.load_bronze truncates each Bronze table and bulk-inserts the matching CSV, with no transformation.
    Bronze → Silver: silver.load_silver truncates each Silver table, then re-loads it from Bronze while applying cleansing rules (see below).
    Silver → Gold: ddl_gold.sql creates three views directly over Silver — no physical tables — so Gold always reflects the latest Silver load.

Bronze layer — sources loaded
Source	Table	File
CRM	bronze.crm_cust_info	datasets/source_crm/cust_info.csv
CRM	bronze.crm_prd_info	datasets/source_crm/prd_info.csv
CRM	bronze.crm_sales_details	datasets/source_crm/sales_details.csv
ERP	bronze.erp_cust_az12	datasets/source_erp/CUST_AZ12.csv
ERP	bronze.erp_loc_a101	datasets/source_erp/LOC_A101.csv
ERP	bronze.erp_px_cat_g1v2	datasets/source_erp/PX_CAT_G1V2.csv
Silver layer — key transformations

    crm_cust_info — trims names, maps marital status (S/M → Single/Married) and gender (F/M → Female/Male) to readable values, and keeps only the most recent record per cst_id.
    crm_prd_info — splits prd_key into a cat_id (for joining to ERP categories) and the true product key, defaults missing cost to 0, maps product line codes (M/R/S/T) to full names, and derives prd_end_dt from the next record's start date.
    crm_sales_details — converts integer-encoded dates to DATE (nulling out invalid ones), and recalculates sales/price when the source values are missing or inconsistent with quantity.
    erp_cust_az12 — strips a stray NAS prefix from customer IDs, nulls out future birthdates, and standardizes gender values.
    erp_loc_a101 — strips dashes from customer IDs and maps country codes (DE, US/USA, blank/NULL) to full, readable country names.
    erp_px_cat_g1v2 — passed through unchanged (already clean).

Every Silver table also adds a dwh_create_date column to track when the record was loaded.
Gold layer — star schema
View	Type	Description
gold.dim_customers	Dimension	Customers joined with ERP demographic (birthdate, gender) and location (country) data
gold.dim_products	Dimension	Current products (prd_end_dt IS NULL) joined with ERP category/subcategory/maintenance info
gold.fact_sales	Fact	Sales transactions linked to dim_customers and dim_products via surrogate keys

Full field-level definitions (data types, descriptions, examples) are documented in docs/data_catalog.md.
Data Quality

tests/quality_check_silver.sql validates the Silver layer after each load:

    No NULL or duplicate primary keys (cst_id, prd_id)
    No unwanted leading/trailing spaces in text fields
    Standardized categorical values (marital status, gender, country, product line, maintenance)
    No invalid date ranges (e.g. prd_start_dt > prd_end_dt, order date after ship/due date)
    Sales consistency: sales_amount = quantity * price, with no NULL, zero, or negative values

Requirements

    SQL Server (Express or higher)
    SQL Server Management Studio (SSMS) or another SQL Server client
    The datasets/ CSVs available locally (used by BULK INSERT in proc_load_bronze.sql)

How to Run

    Create the database and schemas:

sql

   -- scripts/init_database.sql
   -- Creates DataWarehouseKirin with bronze, silver, gold schemas

    Build and load Bronze:

sql

   -- scripts/bronze/ddl_bronze.sql
   EXEC bronze.load_bronze;

    Build and load Silver:

sql

   -- scripts/silver/ddl_silver.sql
   EXEC silver.load_silver;

    Build Gold views:

sql

   -- scripts/gold/ddl_gold.sql

    Validate: run tests/quality_check_silver.sql and review any returned rows.
    Consume: query gold.dim_customers, gold.dim_products, and gold.fact_sales directly, or connect a BI tool.

    Note: proc_load_bronze.sql currently points BULK INSERT at a local Windows file path. Update the file paths to match your own environment before running it.

License

This project is licensed under the MIT License.

