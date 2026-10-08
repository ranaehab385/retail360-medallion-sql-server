# Retail360 Medallion SQL Server

- An end-to-end SQL Server data warehouse built from raw retail CSV data, using **Medallion Architecture (Bronze/Silver/Gold)** and a **Star Schema**.

1. **Extracted** raw data from CSV flat files and loaded it into the Bronze layer.
2. **Transformed and modeled** the data using SQL and dimensional data modeling concepts.
3. **Orchestrated** the ETL pipeline to transform raw data into structured fact and dimension tables.
4. **Cleaned and standardized** the data, resolving inconsistencies and data quality issues.
5. **Built the Gold layer** with a structured dimensional model and consistent relationships.

# Table of Content
- Dataset Used 
- Technologies
- Data Pipeline Architecture
- Date Modeling
- **Step 1:** Bronze Layer – Raw Data Ingestion  
- **Step 2:** Silver Layer – Data Cleaning & Transformation  
- **Step 3:** Gold Layer – Dimensional Modeling  
- **Step 4:** Analytics & Visualization

# Dataset Used
- This project uses a retail dataset containing transactional records covering customers, products, orders, sellers, payments, and geographic information, along with related attributes used for sales and customer analysis.
The dataset was sourced from Kaggle and used as the raw input for the data warehouse and ETL pipeline.

**Website:** :https://www.kaggle.com/datasets/mmumairkhattak/e-commerce-orders-dataset-2026-scra
**Data Dictionary:** 
**Raw Data (CSV):**

# Technologies

The following technologies are used to build this project:

- **Language:** SQL (T-SQL)
- **Database:** SQL Server
- **Development & ETL:** SQL Server Management Studio (SSMS)
- **Architecture:** Medallion Architecture (Bronze / Silver / Gold)
- **Data Modeling:** Star Schema

# Data Pipeline Architecture

<img width="1362" height="592" alt="Untitled Diagram-Page-1 drawio" src="https://github.com/user-attachments/assets/0b09481f-96a1-4859-a2ea-ea1058e21a16" />


# Data Modeling
- The data warehouse follows a Medallion Architecture, with data progressing through Bronze, Silver, and Gold layers. The Silver layer is used for data preparation and transformation, while the Gold layer contains the final dimensional model for analytics.
<img width="1252" height="372" alt="Untitled Diagram-Page-2 drawio" src="https://github.com/user-attachments/assets/bc05b9c2-1d11-4f9d-a197-f8ca16cb0621" />

The Gold layer is structured using a star schema, with the fact table connected to the relevant dimension tables through consistent keys.


# **Step 1:** Bronze Layer – Raw Data Ingestion  

- Bronze Layer is Source Preservation: Preserved the raw source structure with minimal transformation to maintain data traceability and auditability.
, Used BULK INSERT to efficiently load the CSV data into the Bronze layer.
CSV Handling: Configured the load for CSV format with FIRSTROW = 2 to exclude the header row.
Character Encoding: Used UTF-8 encoding (CODEPAGE = 65001) to correctly handle the source data.

<img width="1022" height="207" alt="Screenshot 2026-10-06 195849" src="https://github.com/user-attachments/assets/ba1e1d22-5af7-4842-a733-502c680380ec" />

**Table Refresh:**
- Used TRUNCATE TABLE before each load to ensure a clean and consistent raw-layer refresh.
Load Monitoring: Captured batch and load durations to monitor the ingestion process.

<img width="1362" height="890" alt="Screenshot 2026-10-06 200037" src="https://github.com/user-attachments/assets/0823343c-cc2b-46b5-abcb-727eb37ade58" />

**Error Handling:**
- Implemented TRY...CATCH to capture and report errors during the loading process.

<img width="1397" height="570" alt="Screenshot 2026-10-06 200022" src="https://github.com/user-attachments/assets/45fe0040-771d-42ec-82d8-5b6372fa3df9" />

# **Step 2:** Silver Layer – Data Cleaning & Transformation 

- The Silver layer handles the main data preparation, addressing source-data inconsistencies and restructuring the flat dataset into Customer, Product, and Order entities.

**Problem:** The 30,000 transaction records contained repeated customer and product information, making the raw identifiers unsuitable for clean entity-level modeling.

**Customer IDs with inconsistent records:** 
- Several records share the same ID with conflicting attributes. The issue should be flagged to the data owner to verify whether it is intentional or a data-entry error before handling it.
- **a. handling by :** Customer Key Generation A deterministic `customer_sk` is generated using an MD5 hash of the customer’s identifying attributes. The same key-generation logic is applied to the Orders data to ensure consistent key matching and referential integrity between the Customer dimension and Order records.

<img width="1430" height="455" alt="Screenshot 2026-10-08 144744" src="https://github.com/user-attachments/assets/80727bdb-f88a-4a2a-83e6-e6ac9966d6a7" />

**Product Uniqueness :** 
- Product combinations were identified from the transactional dataset to distinguish the actual product entities from repeated order-level records.

Problem identification:
- The source data contains 30,000 transaction records, while the actual number of unique products is approximately 320. This indicates that product information is repeated across transactions.

<img width="1440" height="255" alt="Screenshot 2026-10-08 145401" src="https://github.com/user-attachments/assets/c57dda0a-912e-476b-a162-7aa4e84386a5" />

**handling:**
- Unique product combinations were extracted using DISTINCT, and a deterministic product_sk was generated from the product attributes to create a consistent Product dimension.
<img width="1398" height="472" alt="Screenshot 2026-10-08 150149" src="https://github.com/user-attachments/assets/e1901660-ff9a-4c3f-92c2-cea360b71b72" />

**Customer Validation & Deduplication**
- The silver.customer_rt360 table was validated using customer_sk to confirm that each customer is represented once in the dimension, rather than being repeated for each transaction. 30000 rows but in real only 29918 customer and even with the small difference it was discovered

<img width="1392" height="262" alt="Screenshot 2026-10-08 145056" src="https://github.com/user-attachments/assets/cad715a6-67c5-42db-934a-0addd35e0cf0" />

**a. Data Integrity**
- Primary key constraints were applied to the generated Customer and Product keys to enforce uniqueness and protect the integrity of the dimension records.

<img width="1468" height="530" alt="Screenshot 2026-10-08 145508" src="https://github.com/user-attachments/assets/ebdc446d-31dc-449b-8956-9d5b1889bc1e" />

- 🔐 and that followed by changes in load because the error handling query catched the duplications and that resulted in zero rows output in all tables of silver stage

**b. silver load - handling the errors of customers duplication**
- The Silver load procedure consolidates the transformations into a repeatable ETL process, including data cleansing, key generation, deduplication, validation, and loading of the Customer, Product, and Order tables.
- Data Quality Issue – Geographic Inconsistency: City–country mappings contained incorrect values, such as assigning Riyadh to France. The country was standardized based on the associated city.

<img width="1470" height="650" alt="Screenshot 2026-10-08 150805" src="https://github.com/user-attachments/assets/1442b49b-d8fa-4326-a493-6570571e250b" />
<img width="1431" height="880" alt="Screenshot 2026-10-08 151309" src="https://github.com/user-attachments/assets/a4e66369-4dac-48dc-b080-790f36709638" />

















