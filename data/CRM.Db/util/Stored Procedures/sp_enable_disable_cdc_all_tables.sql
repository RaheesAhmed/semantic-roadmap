CREATE procedure [util].[sp_enable_disable_cdc_all_tables](@dbname varchar(100), @enable bit)  
as  
  
BEGIN TRY  
DECLARE @source_name varchar(400);  
declare @sql varchar(1000)  
DECLARE the_cursor CURSOR FAST_FORWARD FOR  
SELECT table_name  
FROM INFORMATION_SCHEMA.TABLES where TABLE_CATALOG=@dbname and table_schema='dbo' and table_name != 'systranschemas'  
OPEN the_cursor  
FETCH NEXT FROM the_cursor INTO @source_name  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
if @enable = 1  
  
set @sql =' Use '+ @dbname+ ';EXEC sys.sp_cdc_enable_table  
            @source_schema = N''dbo'',@source_name = '+@source_name+'  
          , @role_name = N'''+'dbo'+''''  
            
else  
set @sql =' Use '+ @dbname+ ';EXEC sys.sp_cdc_disable_table  
            @source_schema = N''dbo'',@source_name = '+@source_name+',  @capture_instance =''all'''  
exec(@sql)  
  
  
  FETCH NEXT FROM the_cursor INTO @source_name  
  
END  
  
CLOSE the_cursor  
DEALLOCATE the_cursor  
  
      
SELECT 'Successful'  
END TRY  
BEGIN CATCH  
CLOSE the_cursor  
DEALLOCATE the_cursor  
  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
        ,ERROR_MESSAGE() AS ErrorMessage;  
END CATCH