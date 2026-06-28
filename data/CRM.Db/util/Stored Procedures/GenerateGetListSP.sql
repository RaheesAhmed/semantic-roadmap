CREATE PROCEDURE [util].[GenerateGetListSP]
    @pTableName VARCHAR(50) ,
    @pCreate CHAR(1) -- 'Y'/'N' -> 'Y':Create Directly
AS /*
	EXEC [util].[GenerateGetListSP] @pTableName='mWarehouse', @pCreate='N'
*/
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   

        DECLARE @sSQLString NVARCHAR(4000) ,
            @sTableAlias VARCHAR(10) ,
            @sFieldsString VARCHAR(500);

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
CREATE PROCEDURE [spq].[Get' + SUBSTRING(@pTableName, 2, LEN(@pTableName) - 1)
            + 'Lst]
    @pStatus CHAR(1) ,
	@pLangCd VARCHAR(10),
	@pPageNum INT = 1,
    @pPageSize INT = 999     
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        WITH    cteData
                  AS ( SELECT   ' + @sFieldsString + ', ''N'' AS RecordState '
            + ' FROM dbo.' + @pTableName + ' ' + @sTableAlias
            + ' WHERE @pStatus = '' ''
                                  OR ' + @sTableAlias
            + '.wStatus = @pStatus                                
                     ),
                cteCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     cteData
                     )
            SELECT  d.* ,
                    c.wRecordCount
            FROM    cteData d ,
                    cteCount c
            ORDER BY d.wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;';

        IF @pCreate = 'Y'
            BEGIN	    	
                EXEC sp_executesql @sSQLString;
            END;

        PRINT @sSQLString;
    END;