CREATE PROCEDURE [util].[RecalSequence] ( @pTableName NVARCHAR(2000) = '' )
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sTmp TABLE ( wName VARCHAR(100),
                              wLen INT,
                              wCompNo INT,
                              wTableName VARCHAR(100),
                              wMaxRowID BIGINT,
                              wCurRowIDStr VARCHAR(14),
                              wCurrRowID BIGINT );
    	
        SELECT  IDENTITY( INT ) AS ID,
                *,
                current_value AS NewCurrValue
        INTO    #tmpSequences
        FROM    sys.sequences s
        LEFT JOIN dbo.fnSplit(@pTableName, ',') tbl
        ON      s.name LIKE 'seq' + tbl.item + '%'
                AND tbl.item != ''
        WHERE   @pTableName = ''
                OR tbl.item IS NOT NULL;
	
        DECLARE @sLoopCount INT = ( SELECT COUNT (*) FROM #tmpSequences ),
            @sLoopStart INT = 0,
            @sHasCompNo INT = 1;

        DECLARE @sName VARCHAR(100),
            @sOldCurrValue SQL_VARIANT,
            @sTableName VARCHAR(100),
            @sCompNo INT,
            @sCompNoStr VARCHAR(4),
            @sCurruntValue INT,
            @sCompLen INT = 0,
            @sDynamicSql NVARCHAR(1000),
            @sMaxValue BIGINT;

        WHILE ( @sLoopStart < @sLoopCount )
            BEGIN
                SELECT  @sName = name,
                        @sOldCurrValue = current_value
                FROM    #tmpSequences
                WHERE   ID = @sLoopStart + 1;

                IF ISNUMERIC(SUBSTRING(@sName, LEN(@sName) - 3, 4)) <> 0
                    BEGIN
                        SET @sCompLen = 4;
                        SET @sCompNoStr = SUBSTRING(@sName, LEN(@sName) - 3, 4);
                        SET @sCompNo = CONVERT(INT, @sCompNoStr);
                        SET @sTableName = SUBSTRING(@sName, 4, LEN(@sName) - ( @sCompLen + 3 ));
                    END;
                ELSE
                    IF ISNUMERIC(SUBSTRING(@sName, LEN(@sName) - 2, 3)) <> 0
                        BEGIN
                            SET @sCompLen = 3;
                            SET @sCompNoStr = SUBSTRING(@sName, LEN(@sName) - 2, 3);
                            SET @sCompNo = CONVERT(INT, @sCompNoStr);
                            SET @sTableName = SUBSTRING(@sName, 4, LEN(@sName) - ( @sCompLen + 3 ));
                        END;
                    ELSE
                        IF ISNUMERIC(SUBSTRING(@sName, LEN(@sName) - 1, 2)) <> 0
                            BEGIN
                                SET @sCompLen = 2;
                                SET @sCompNoStr = SUBSTRING(@sName, LEN(@sName) - 1, 2);
                                SET @sCompNo = CONVERT(INT, @sCompNoStr);
                                SET @sTableName = SUBSTRING(@sName, 4, LEN(@sName) - ( @sCompLen + 3 ));
                            END;
                        ELSE
                            BEGIN
                                SET @sCompLen = 0;
                                SET @sTableName = SUBSTRING(@sName, 4, LEN(@sName) - ( @sCompLen + 3 ));
                            END;	
		
                IF ( EXISTS ( SELECT    *
                              FROM      INFORMATION_SCHEMA.TABLES
                              WHERE     TABLE_SCHEMA = 'dbo'
                                        AND TABLE_NAME = @sTableName ) )
                    BEGIN			
                        SET @sDynamicSql = CONCAT('SELECT @sMaxValue = Max(CASE WHEN ', @sCompLen, ' = 2 AND LEN(RowID) = 12 THEN RowID ELSE 
						CASE WHEN ', @sCompLen, ' = 3 AND LEN(RowID) = 13 THEN RowID ELSE
						CASE WHEN ', @sCompLen, ' = 4 AND LEN(RowID) = 14 THEN RowID ELSE 0 END END END) FROM ', @sTableName,
                                                  ' WHERE CONVERT(bigint, SUBSTRING(CONVERT(varchar, RowID), 1, ', @sCompLen, ')) = ', @sCompNo);

                        EXEC sp_executesql
                            @sDynamicSql,
                            N'@sMaxValue bigint output',
                            @sMaxValue OUTPUT;

                        DECLARE @sMaxValueStr VARCHAR(14),
                            @sCurValueStr VARCHAR(14);

                        SET @sMaxValueStr = ( CAST(@sMaxValue AS VARCHAR(14)) );
                        IF ( LEN(@sMaxValueStr) >= 12 )
                            BEGIN
                                SET @sCurValueStr = SUBSTRING(@sMaxValueStr, @sCompLen + 1, LEN(@sMaxValueStr) - @sCompLen);
                                SET @sCurruntValue = CONVERT(INT, @sCurValueStr);

                                UPDATE  #tmpSequences
                                SET     NewCurrValue = @sCurruntValue
                                WHERE   #tmpSequences.ID = @sLoopStart + 1;
                                IF ( @sOldCurrValue <> @sCurruntValue )
                                    BEGIN
                                        SET @sDynamicSql = CONCAT('ALTER SEQUENCE ', @sName, ' RESTART WITH ', @sCurruntValue + 1,
                                                                  ' INCREMENT BY 1 MINVALUE 10000 MAXVALUE 99999999999999');
                                        EXEC sp_executesql
                                            @sDynamicSql;
                                    END;		
                            END; 
                    END;

                SET @sLoopStart = @sLoopStart + 1;
            END;

        SELECT  *
        FROM    #tmpSequences ts;	

		DROP TABLE #tmpSequences;
    END;