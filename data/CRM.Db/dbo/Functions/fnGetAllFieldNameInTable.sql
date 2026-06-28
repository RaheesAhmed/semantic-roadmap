CREATE FUNCTION [dbo].[fnGetAllFieldNameInTable] 
(
	@pTableName AS			VARCHAR(100),
    @pTableAlias AS			VARCHAR(100),
    @pWithDataType AS 		CHAR(1) = 'N',
    @pDeclareLocalVar AS	CHAR(1) = 'N',
    @pForUpdate	AS			CHAR(1) = 'N',
    @pForUpdateAlias AS		VARCHAR(100)
)
RETURNS VARCHAR(8000)
AS
BEGIN
    DECLARE @rtn AS VARCHAR(8000) 
    SET @rtn = ''

    SELECT 
         @rtn = 
            @rtn + 
         	CASE WHEN ISNULL(@rtn,'') = '' THEN '' ELSE ', ' END + 
         	CASE WHEN ISNULL(@pTableAlias,'') = '' 
            	THEN '' 
                ELSE @pTableAlias + '.' END + 
            CASE WHEN @pDeclareLocalVar = 'Y' THEN '@' ELSE '' END + 
            COLUMN_NAME + 
            CASE WHEN @pWithDataType = 'Y' 
				THEN space(1) + UPPER(DATA_TYPE) + ISNULL('(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(50)) + ')','') 
            	-- THEN CHAR(9) + UPPER(DATA_TYPE) + ISNULL('(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(50)) + ')','') 
                ELSE '' END + 
            CASE WHEN @pForUpdate = 'Y'
            	THEN ' = ' + @pForUpdateAlias + '.' + COLUMN_NAME
                ELSE ''
            END
    FROM   
      INFORMATION_SCHEMA.COLUMNS 
    WHERE   
      TABLE_NAME = @pTableName
    AND
      TABLE_SCHEMA = 'dbo'
    ORDER BY 
      ORDINAL_POSITION ASC; 
      
    RETURN @rtn
END