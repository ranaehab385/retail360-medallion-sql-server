# Retail360 Medallion SQL Server

An end-to-end SQL Server data warehouse built from raw retail CSV data, using **Medallion Architecture (Bronze/Silver/Gold)** and a **Star Schema**.

1. **Extracted** raw data from CSV flat files and loaded it into the Bronze layer.
2. **Transformed and modeled** the data using SQL and dimensional data modeling concepts.
3. **Orchestrated** the ETL pipeline to transform raw data into structured fact and dimension tables.
4. **Cleaned and standardized** the data, resolving inconsistencies and data quality issues.
5. **Built the Gold layer** with a structured dimensional model and consistent relationships.

# Table of Content
Technologies
Data Pipeline Architecture
Date Modeling
Step 1: Cleaning and Transformation
Step 2: Storage
Step 3: ETL / Orchestration
Step 4: Analytics
Step 5: Dashboard

# dataset used 
This project uses a retail dataset containing transactional records covering customers, products, orders, sellers, payments, and geographic information, along with related attributes used for sales and customer analysis.
The dataset was sourced from Kaggle and used as the raw input for the data warehouse and ETL pipeline.



