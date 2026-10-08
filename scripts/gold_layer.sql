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
