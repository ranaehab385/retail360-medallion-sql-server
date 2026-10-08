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

       
PRINT '>> Truncating Table: silver.customer_rt360';
TRUNCATE TABLE silver.customer_rt360;

PRINT '>> Inserting Data Into: silver.customer_rt360';
SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.customer_rt360';
        TRUNCATE TABLE silver.customer_rt360;
        
        PRINT '>> Inserting Data Into: silver.customer_rt360';
        
        WITH cleansed_data AS (
            SELECT 
                 Order_ID,          
                 Order_Date,
                Customer_ID,
                CONCAT(Customer_ID, '_', LEFT(Customer_Gender, 1), '_', CAST(Customer_Age AS VARCHAR)) AS new_customer_id,
                LOWER(CONVERT(VARCHAR(32), HASHBYTES('MD5', CONCAT(Customer_ID, '_', Customer_Gender, '_', CAST(Customer_Age AS VARCHAR), '_',
			[Membership_Status], '_', [Customer_Segment])), 2)) AS customer_sk,
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
                
                 MAX(Customer_Lifetime_Value) OVER (PARTITION BY customer_sk) AS Max_Customer_Lifetime_Value,
        ROW_NUMBER() OVER (PARTITION BY customer_sk
                           ORDER BY Order_Date DESC, Order_ID DESC) AS rn,    
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
    LOWER(CONVERT(VARCHAR(32), HASHBYTES('MD5', CONCAT(Customer_ID, '_', Customer_Gender, '_', CAST(Customer_Age AS VARCHAR)
	,'_' , [Membership_Status],'_' , [Customer_Segment])), 2)) AS customer_sk,
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
		PRINT 'ERROR OCCURED DURING LOADING silver LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END


