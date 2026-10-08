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



