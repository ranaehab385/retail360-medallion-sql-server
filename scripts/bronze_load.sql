
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
