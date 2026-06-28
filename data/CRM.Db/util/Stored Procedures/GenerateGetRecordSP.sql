CREATE PROCEDURE [util].[GenerateGetRecordSP]
    @pTableName VARCHAR(50) ,
    @pCreate CHAR(1) -- 'Y'/'N' -> 'Y':Create Directly
AS /*
	EXEC [util].[GenerateGetRecordSP] @pTableName='mWarehouse', @pCreate='N'
*/
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   

        DECLARE @sUseAndExecStatment NVARCHAR(MAX) ,
            @sSQLString NVARCHAR(MAX) ,
            @sTableAlias VARCHAR(100) ,
            @sFieldsString VARCHAR(MAX);

        WITH    CTE
                  AS ( SELECT   @pTableName AS oldVal ,
                                1 AS TotalLen ,
                                SUBSTRING(@pTableName, 1, 1) AS newVal ,
                                ASCII(SUBSTRING(@pTableName, 1, 1)) AS AsciVal
                       UNION ALL
                       SELECT   oldVal ,
                                TotalLen + 1 AS TotalLen ,
                                SUBSTRING(@pTableName, TotalLen + 1, 1) AS newVal ,
                                ASCII(SUBSTRING(@pTableName, TotalLen + 1, 1)) AS AsciVal
                       FROM     CTE
                       WHERE    CTE.TotalLen <= LEN(@pTableName)
                     )
            SELECT  @sTableAlias = ISNULL(@sTableAlias, '') + LOWER(newVal)                    
            FROM    CTE
                    INNER JOIN master..spt_values AS m ON CTE.AsciVal = m.number
                                                          AND CTE.AsciVal BETWEEN 65 AND 90;

        SET @sTableAlias = @sTableAlias + '_t';
        SET @sFieldsString = [dbo].[fnGetAllFieldNameInTable](@pTableName,
                                                              @sTableAlias,
                                                              'N', '', '', '');   															  		

        SET @sSQLString = '
	CREATE PROCEDURE [spq].[Get' + SUBSTRING(@pTableName, 2,
                                             LEN(@pTableName) - 1) + ']
		@pRowID BIGINT
	AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT ' + @sFieldsString + ', ''N'' AS RecordState ' + ' FROM dbo.'
            + @pTableName + ' ' + @sTableAlias + '
		WHERE @pRowID = ' + @sTableAlias
            + '.RowID                                                 
    END;';

        IF @pCreate = 'Y'
            BEGIN	    	
                EXEC sp_executesql @sSQLString;
            END;

        PRINT @sSQLString;
    END;