CREATE PROCEDURE [spq].[GetShiftHandover]
    (
      @pFromShiftDt DATETIME2 ,
      @pToShiftDt DATETIME2 ,
      @pDepartment VARCHAR(30) ,
      @pShiftRid BIGINT ,
      @pCounterRidXML XML ,
      @pStatusXML XML ,
      @pSort AS VARCHAR(200) ,
      @pLangCd AS VARCHAR(30) ,
      @pPageSize AS INT ,
      @pPageNum AS INT
    )
AS
    BEGIN  
        SET NOCOUNT ON;  

        DECLARE @vCounterRidCount AS INT ,
            @vStatusCount AS INT;
        DECLARE @vData_CounterRid AS TABLE ( SelectionItem BIGINT );
        DECLARE @vData_Status AS TABLE
            (
              SelectionItem VARCHAR(30)
            );

        IF CAST(@pCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_CounterRid
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
                        FROM    @pCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        IF CAST(@pStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_Status
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'VARCHAR(30)') AS SelectionItem
                        FROM    @pStatusXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        SET @vCounterRidCount = ( SELECT    COUNT(1)
                                  FROM      @vData_CounterRid
                                );
        SET @vStatusCount = ( SELECT    COUNT(1)
                              FROM      @vData_Status
                            );
        SET @pFromShiftDt = ISNULL(@pFromShiftDt, '0001-01-01');
        SET @pToShiftDt = ISNULL(@pToShiftDt, '9999-12-31');
        SET @pDepartment = ISNULL(@pDepartment, '');
        SET @pShiftRid = ISNULL(@pShiftRid, 0);
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
  
        WITH    tResult
                  AS ( SELECT   ms.RowID ,
                                ms.wShiftDt ,
                                ms.wDepartment ,
                                ms.wShiftRid ,
                                ms.wCounterRid ,
                                ms.wStatus ,
                                ms.wRemark ,
                                ms.wCrtDt ,
                                ms.wUpdDt ,
                                ms.wCrtBy ,
                                ms.wUpdBy ,
                                ms.wSeqNo ,
                                msh.wName AS wShiftPeriod ,
                                sc.wName AS wServiceCounterName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     mShiftHandover AS ms
                                INNER JOIN [CRM].[dbo].[mShift] msh ON msh.RowID = ms.wShiftRid
                                INNER JOIN [CRM].[dbo].[mServiceCounter] sc ON sc.RowID = ms.wCounterRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ms.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ms.wCrtBy
                                LEFT JOIN @vData_CounterRid v ON v.SelectionItem = ms.wCounterRid
                                LEFT JOIN @vData_Status vs ON vs.SelectionItem = ms.wStatus
                       WHERE    ( @pFromShiftDt <= ms.wShiftDt
                                  AND @pToShiftDt >= ms.wShiftDt
                                )
                                AND ( @pDepartment = ''
                                      OR ms.wDepartment = @pDepartment
                                    )
                                AND ( @pShiftRid = 0
                                      OR ms.wShiftRid = @pShiftRid
                                    )
                                AND ( @vCounterRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
                                    )
                                AND ( @vStatusCount <= 0
                                      OR vs.SelectionItem IS NOT NULL
                                    )
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1
                          THEN tResult.wShiftDt
                     END DESC ,
                    CASE WHEN CHARINDEX('||', @pSort) = 1
                         THEN tResult.wCounterRid
                    END DESC ,
                    CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.RowID
                    END DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
    FETCH NEXT @pPageSize ROWS ONLY;  
    END;