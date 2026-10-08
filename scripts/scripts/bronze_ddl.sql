
/*
===============================================================================
DDL Script: Create Bronze Table
===============================================================================
Purpose:
    Creates the raw bronze table for the Retail360DW project.
    Drops the existing table if it already exists.
===============================================================================
*/

IF OBJECT_ID('bronze.retail_orders_raw', 'U') IS NOT NULL
    DROP TABLE bronze.retail_orders_raw;
GO

CREATE TABLE bronze.retail_orders_raw
(
    Order_ID                    INT,
    Customer_ID                 NVARCHAR(50),
    Order_Date                  DATE,
    [Year]                      INT,
    [Month]                     INT,
    [Day]                       INT,
    Day_Of_Week                 NVARCHAR(50),
    Quarter                     INT,
    Customer_Age                INT,
    Customer_Gender             NVARCHAR(50),
    Country                     NVARCHAR(50),
    City                        NVARCHAR(50),
    Customer_Segment            NVARCHAR(50),

    Product_ID                  NVARCHAR(50),
    Product_Category            NVARCHAR(50),
    Product_Subcategory         NVARCHAR(50),
    Brand                       NVARCHAR(50),

    Unit_Price                  DECIMAL(18,2),
    Quantity                    INT,
    Discount_Percent            DECIMAL(18,2),
    Discount_Amount             DECIMAL(18,2),
    Coupon_Used                 NVARCHAR(50),
    Shipping_Cost               DECIMAL(18,2),
    Tax_Amount                  DECIMAL(18,2),
    Order_Amount                DECIMAL(18,2),

    Payment_Method              NVARCHAR(50),
    Device_Type                 NVARCHAR(50),
    Traffic_Source              NVARCHAR(50),
    Membership_Status           NVARCHAR(50),
    Shipping_Method             NVARCHAR(50),
    Warehouse_Region            NVARCHAR(50),

    Delivery_Days               INT,
    Order_Status                NVARCHAR(50),
    Returned                    NVARCHAR(50),
    Review_Rating               DECIMAL(18,2),

    Customer_Lifetime_Value     DECIMAL(18,2),
    Profit_Margin_Percent       DECIMAL(18,2),
    Profit_Amount               DECIMAL(18,2),

    Season                      NVARCHAR(50),
    Holiday_Season              NVARCHAR(50),
    High_Value_Order            NVARCHAR(50)
);
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN

    DECLARE 
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '================================================';


        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.retail_orders_raw';

        TRUNCATE TABLE bronze.retail_orders_raw;

        PRINT '>> Inserting Data Into: bronze.retail_orders_raw';


BULK INSERT bronze.retail_orders_raw
FROM 'D:\data\ecommerce_orders_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    CODEPAGE = '65001',
    TABLOCK
);

        SET @end_time = GETDATE();


        PRINT '>> Load Duration: ' 
        + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)
        + ' seconds';


        SET @batch_end_time = GETDATE();


        PRINT '==========================================';
        PRINT 'Loading Bronze Layer is Completed';
        PRINT 'Total Load Duration: '
        + CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR)
        + ' seconds';
        PRINT '==========================================';


    END TRY


    BEGIN CATCH

        PRINT '==========================================';
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';

        PRINT 'Error Message: ' + ERROR_MESSAGE();

        PRINT 'Error Number: '
        + CAST(ERROR_NUMBER() AS NVARCHAR);

        PRINT 'Error State: '
        + CAST(ERROR_STATE() AS NVARCHAR);

        PRINT '==========================================';

    END CATCH

END;
GO
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    -- 1. إنشاء Surrogate Key فريد لكل عميل
    ROW_NUMBER() OVER (ORDER BY customer_sk) AS customer_key,
    
  
    customer_sk                              AS customer_sk,
    
    -- 3. الخصائص الديموغرافية والجغرافية
    Customer_Gender                          AS gender,
    Customer_Age                             AS age,
    Country                                  AS country,
    City                                     AS city,
    
    -- 4. تصنيفات وتقسيمات العملاء
    Customer_Segment                         AS customer_segment,
    Membership_Status                        AS membership_status,
  MAX(Customer_Lifetime_Value) OVER (PARTITION BY customer_sk)   as Customer_Lifetime_Value
  
  FROM silver.customer_rt360;
GO

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY product_sk) as   product_key ,
       product_sk              as product_sk,
       [Product_Category]        as Product_Category
      ,[Product_Subcategory]      as Product_Subcategory
      ,[Brand]                     as Brand

  FROM [Retail360DW].[silver].[product_rt360]

  GO



  IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
       gp.product_key     as  product_key,
       gc.customer_key    as customer_key,
       o.[Order_ID]          as order_id
      ,o.[Order_Date]        as order_date 
      ,o.[Year]              as Year
      ,o.[Month]              as month
      ,o.[Day]                 as day
      ,o.[Day_Of_Week]          as day_Of_the_week
      ,o.[Quarter]              as quarter
      ,o.[Unit_Price]           as unit_price 
      ,o.[Quantity]             as quantity
      ,o.[Discount_Percent]      as  discount_percent
      ,o.[Discount_Amount]       as discount_amount 
      ,o.[Coupon_Used]          as coupon_used
      ,o.[Shipping_Cost]        as shipping_cost 
      ,o.[Tax_Amount]            as tax_amount
      ,o.[Order_Amount]          as order_amount
      ,o.[Payment_Method]        as payment_method
      ,o.[Device_Type]            as  device_type
      ,o.[Traffic_Source]          as traffic_source
      ,o.[Shipping_Method]           as shipping_method
      ,o.[Warehouse_Region]         as warehouse_region
      ,o.[Delivery_Days]             as delivery_days
      ,o.[Order_Status]              as order_status
      ,o.[Returned]                  as returned
      ,o.[Review_Rating]             as review_rating
      ,o.[Profit_Margin_Percent]     as profit_margin
      ,o.[Profit_Amount]              as profit_amount
      ,o.[Season]                     as season
      ,o.[Holiday_Season]                 as holiday_season
      ,o.[High_Value_Order]              as high_value_order
      

from Retail360DW.[silver].[order_rt360] o
left join  gold.dim_customers gc
   on o.customer_sk = gc.customer_sk

left join gold.dim_products gp
   on o.product_sk =  gp.product_sk

 go
if object_id('silver.customer_rt360') is not null
   drop table silver.customer_rt360;
GO

CREATE TABLE	 silver.customer_rt360(
    Customer_ID                 NVARCHAR(50),
    new_customer_id             NVARCHAR(50),
    Customer_Age                INT,
    Customer_Gender             NVARCHAR(50),
    Country                     NVARCHAR(50),
    City                        NVARCHAR(50),
    Customer_Segment            NVARCHAR(50),
    Customer_Lifetime_Value     DECIMAL(18,2),
    Membership_Status           NVARCHAR(50),
    customer_sk                 NVARCHAR(50) NOT NULL PRIMARY KEY,   -- اتعدّل مكانه
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
    );
GO

if object_id('silver.product_rt360') is not null
   drop table silver.product_rt360;
GO

CREATE TABLE	 silver.product_rt360(
    product_sk                  NVARCHAR(50) NOT NULL PRIMARY KEY,
    Product_Category            NVARCHAR(50),
    Product_Subcategory         NVARCHAR(50),
    Brand                       NVARCHAR(50),
    dwh_create_date    DATETIME2 DEFAULT GETDATE()

    );
GO




if object_id('silver.order_rt360') is not null
   drop table silver.order_rt360;
GO

CREATE TABLE	 silver.order_rt360(
    Order_ID                    INT,
    new_customer_id             NVARCHAR(50),
    customer_sk                  NVARCHAR(50),
    Customer_ID                 NVARCHAR(50),
    Order_Date                  DATE,
    [Year]                      INT,
    [Month]                     INT,
    [Day]                       INT,
    Day_Of_Week                 NVARCHAR(50),
    Quarter                     INT,
    Product_ID                  NVARCHAR(50),
        product_sk                  NVARCHAR(50) ,

     Unit_Price                  DECIMAL(18,2),
    Quantity                    INT,
    Discount_Percent            DECIMAL(18,2),
    Discount_Amount             DECIMAL(18,2),
    Coupon_Used                 NVARCHAR(50),
    Shipping_Cost               DECIMAL(18,2),
    Tax_Amount                  DECIMAL(18,2),
    Order_Amount                DECIMAL(18,2),

    Payment_Method              NVARCHAR(50),
    Device_Type                 NVARCHAR(50),
    Traffic_Source              NVARCHAR(50),
    Shipping_Method             NVARCHAR(50),
    Warehouse_Region            NVARCHAR(50),

    Delivery_Days               INT,
    Order_Status                NVARCHAR(50),
    Returned                    NVARCHAR(50),
    Review_Rating               DECIMAL(18,2),
    Profit_Margin_Percent       DECIMAL(18,2),
    Profit_Amount               DECIMAL(18,2),

    Season                      NVARCHAR(50),
    Holiday_Season              NVARCHAR(50),
    High_Value_Order            NVARCHAR(50),
    dwh_create_date    DATETIME2 DEFAULT GETDATE()


    );
GO




EXEC silver.load_silver_rt360;


CREATE OR ALTER PROCEDURE silver.load_silver_rt360 AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		-- Loading silver
       SET @start_time = GETDATE();

PRINT '>> Truncating Table: silver.customer_rt360';
TRUNCATE TABLE silver.customer_rt360;

PRINT '>> Inserting Data Into: silver.customer_rt360';
SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.customer_rt360';
        TRUNCATE TABLE silver.customer_rt360;
        
        PRINT '>> Inserting Data Into: silver.customer_rt360';
        
        WITH cleansed_data AS (
            SELECT 
                 Order_ID,          -- جديد
                 Order_Date,
                Customer_ID,
                CONCAT(Customer_ID, '_', LEFT(Customer_Gender, 1), '_', CAST(Customer_Age AS VARCHAR)) AS new_customer_id,
                LOWER(CONVERT(VARCHAR(32), HASHBYTES('MD5', CONCAT(Customer_ID, '_', Customer_Gender, '_', CAST(Customer_Age AS VARCHAR), '_', [Membership_Status], '_', [Customer_Segment])), 2)) AS customer_sk,
                Customer_Gender,
                Customer_Age,
                City,
                CASE City
                    WHEN 'Berlin'    THEN 'Germany'
                    WHEN 'New York'  THEN 'United States'
                    WHEN 'Riyadh'    THEN 'Saudi Arabia'
                    WHEN 'Sydney'    THEN 'Australia'
                    WHEN 'London'    THEN 'United Kingdom'
                    WHEN 'Mumbai'    THEN 'India'
                    WHEN 'Toronto'   THEN 'Canada'
                    WHEN 'Paris'     THEN 'France'
                    WHEN 'Karachi'   THEN 'Pakistan'
                    WHEN 'Dubai'     THEN 'UAE'
                    ELSE Country
                END AS Corrected_Country,
                Customer_Segment,
                Customer_Lifetime_Value,
                Membership_Status
            FROM bronze.retail_orders_raw
        ),
        calculated_clv AS (
            SELECT 
                Customer_ID,
                new_customer_id,
                customer_sk,
                Customer_Gender,
                Customer_Age,
                Corrected_Country AS Country,
                City,
                Customer_Segment,
                -- حساب أقصى قيمة لـ Customer_Lifetime_Value لكل customer_sk
                 MAX(Customer_Lifetime_Value) OVER (PARTITION BY customer_sk) AS Max_Customer_Lifetime_Value,
        ROW_NUMBER() OVER (PARTITION BY customer_sk
                           ORDER BY Order_Date DESC, Order_ID DESC) AS rn,     -- جديد (خدي بالك من الفاصلة في آخره)
        Membership_Status
    FROM cleansed_data
        )
        INSERT INTO silver.customer_rt360 (
            Customer_ID,
            new_customer_id,
            customer_sk,
            Customer_Gender,
            Customer_Age,
            Country,
            City,
            Customer_Segment,
            Customer_Lifetime_Value,
            Membership_Status
        )
        SELECT 
            Customer_ID,
            new_customer_id,
            customer_sk,
            Customer_Gender,
            Customer_Age,
            Country,
            City,
            Customer_Segment,
            Max_Customer_Lifetime_Value,
            Membership_Status
        FROM calculated_clv
         WHERE rn = 1;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';



 SET @start_time = GETDATE();

PRINT '>> Truncating Table: silver.product_rt360';
TRUNCATE TABLE silver.product_rt360;

PRINT '>> Inserting Data Into: silver.product_rt360';

INSERT INTO silver.product_rt360
(
    product_sk,
    Product_Category,
    Product_Subcategory,
    Brand
)
SELECT DISTINCT
    LOWER(CONVERT(VARCHAR(32), HASHBYTES('MD5', CONCAT(Product_Category,'|',Product_Subcategory,'|',Brand)), 2)) as product_sk  ,
    Product_Category,
    Product_Subcategory, 
    Brand
FROM bronze.retail_orders_raw;
SET @start_time = GETDATE();

SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

PRINT '>> Truncating Table: silver.order_rt360';
TRUNCATE TABLE silver.order_rt360;

PRINT '>> Inserting Data Into: silver.order_rt360';

INSERT INTO silver.order_rt360
(
    Order_ID,
    customer_sk,
    new_customer_id,
    Customer_ID,
    Order_Date,
    [Year],
    [Month],
    [Day],
    Day_Of_Week,
    Quarter,
    Product_ID,
    product_sk,
    Unit_Price,
    Quantity,
    Discount_Percent,
    Discount_Amount,
    Coupon_Used,
    Shipping_Cost,
    Tax_Amount,
    Order_Amount,
    Payment_Method,
    Device_Type,
    Traffic_Source,
    Shipping_Method,
    Warehouse_Region,
    Delivery_Days,
    Order_Status,
    Returned,
    Review_Rating,
    Profit_Margin_Percent,
    Profit_Amount,
    Season,
    Holiday_Season,
    High_Value_Order
)
SELECT
    Order_ID,
    LOWER(CONVERT(VARCHAR(32), HASHBYTES('MD5', CONCAT(Customer_ID, '_', Customer_Gender, '_', CAST(Customer_Age AS VARCHAR),'_' , [Membership_Status],'_' , [Customer_Segment])), 2)) AS customer_sk,
    CONCAT(Customer_ID, '_', LEFT(Customer_Gender, 1), '_', CAST(Customer_Age AS VARCHAR) ) AS     new_customer_id  ,
    Customer_ID,
    Order_Date,
    [Year],
    [Month],
    [Day],
    Day_Of_Week,
    Quarter,
    Product_ID,
    LOWER(CONVERT(VARCHAR(32), HASHBYTES('MD5' , CONCAT(Product_Category,'|',Product_Subcategory,'|',Brand)), 2)) AS product_sk,
    Unit_Price,
    Quantity,
    Discount_Percent,
    Discount_Amount,
    Coupon_Used,
    Shipping_Cost,
    Tax_Amount,
    Order_Amount,
    Payment_Method,
    Device_Type,
    Traffic_Source,
    Shipping_Method,
    Warehouse_Region,
    Delivery_Days,
    Order_Status,
    Returned,
    Review_Rating,
    Profit_Margin_Percent,
    Profit_Amount,
    Season,
    Holiday_Season,
    High_Value_Order
FROM bronze.retail_orders_raw;



    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
        SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END


