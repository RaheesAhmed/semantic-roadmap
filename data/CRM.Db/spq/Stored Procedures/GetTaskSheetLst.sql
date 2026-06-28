CREATE PROCEDURE [spq].[GetTaskSheetLst]
    (
      @pDeptCd AS VARCHAR(30) ,
      @pCounterRidXML AS XML ,
      @pRelatedAgentCodeIn AS VARCHAR(14) ,
      @pFromDate AS DATETIME2 ,
      @pToDate AS DATETIME2 ,
      @pTaskSheetStatusXML AS XML ,
      @pSort AS VARCHAR(200) ,
      @pLangCd AS VARCHAR(30) ,
      @pPageSize AS INT ,
      @pPageNum AS INT
    )
AS
    BEGIN
        SET NOCOUNT ON;
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @vCounterRidCount AS INT ,
            @vTaskSheetStatusCount AS INT;
        DECLARE @vData_CounterRid AS TABLE ( SelectionItem BIGINT );
        DECLARE @vData_TaskSheetStatus AS TABLE
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

        IF CAST(@pTaskSheetStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_TaskSheetStatus
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'VARCHAR(30)') AS SelectionItem
                        FROM    @pTaskSheetStatusXML.nodes('/DataSet/Record')
                                AS T ( tmp );
            END;

        SET @vCounterRidCount = ( SELECT    COUNT(1)
                                  FROM      @vData_CounterRid
                                );
        SET @vTaskSheetStatusCount = ( SELECT   COUNT(1)
                                       FROM     @vData_TaskSheetStatus
                                     );

        SET @pDeptCd = ISNULL(@pDeptCd, '');
        SET @pRelatedAgentCodeIn = ISNULL(@pRelatedAgentCodeIn, '');
        SET @pFromDate = ISNULL(@pFromDate, '0001-01-01');
        SET @pToDate = ISNULL(@pToDate, '9999-12-31');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);

        WITH    tResult
                  AS ( SELECT   ts.RowID ,
                                ts.wCompNo ,
                                ts.wCounterRid ,
                                ts.wDeptCd AS wDepartment , -- Please do not remove this alias which is used for custom query
                                ts.wUsrRid ,
                                ts.wDate ,
                                ts.wTaskType ,
                                ts.wSubTaskType ,
                                ts.wIsInhouse ,
                                ts.wContent ,
                                ts.wRemark ,
                                ts.wRelateAgentCodeIn ,
                                ts.wRelatedType ,
                                ts.wRelatedRid ,
                                ts.wHasDoc ,
                                ts.wStatus ,
                                ts.wCrtDt ,
                                ts.wUpdDt ,
                                wTaskTypeTitle = tst.wTitle ,
                                wSubTaskTypeTitle = tstSub.wTitle ,
                                CASE WHEN @pLangCd = 'en-GB' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-GB' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                ts.wTaskSheetStatus ,
                                sc.wName AS wServiceCounterName ,
                                dbo.fnGetBookingRefNoByRelatedRid(ts.wRelatedType,
                                                              ts.wRelatedRid) AS wRelatedRidByNo ,
                                rAgent.wAgentCode_Display AS wReqAgentCode_Display,
                                mu.wUsrId AS wStaff,
                                mu.wCName AS wStaffName ,
                                wAgentCodeIn = ts.wRelateAgentCodeIn
                       FROM     dbo.eTaskSheet ts
                                LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = ts.wCounterRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ts.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ts.wCrtBy
                                LEFT JOIN dbo.mTaskSheetType tst ON ts.wTaskType = tst.wCode
                                                              AND ts.wDeptCd = tst.wDepartmentCode
                                LEFT JOIN dbo.mTaskSheetType tstSub ON ts.wSubTaskType = tstSub.wCode
                                                              AND tstSub.wParentCode = ts.wTaskType
                                                              AND ts.wDeptCd = tst.wDepartmentCode
															  AND ts.wDeptCd = tstSub.wDepartmentCode
                                LEFT JOIN [RollsMary].[dbo].[mAgent] rAgent ON rAgent.wAgentCodeIn = ts.wRelateAgentCodeIn
                                LEFT JOIN @vData_CounterRid v ON v.SelectionItem = ts.wCounterRid
                                LEFT JOIN @vData_TaskSheetStatus vs ON vs.SelectionItem = ts.wTaskSheetStatus
                                LEFT JOIN RollsMary.dbo.mUsr AS mu ON mu.RowID=ts.wUsrRid AND mu.wStatus = 'ACTIVE'
                       WHERE    ( @pDeptCd = ''
                                  OR ts.wDeptCd = @pDeptCd
                                )
                                AND ( @vCounterRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
                                    )
                                AND ( @pRelatedAgentCodeIn = ''
                                      OR @pRelatedAgentCodeIn = ts.wRelateAgentCodeIn
                                    )
                                AND ( @pFromDate <= ts.wDate
                                      AND @pToDate >= ts.wDate
                                    )
                                AND ( @vTaskSheetStatusCount <= 0
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
            ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wDate
                     END DESC ,
                    CASE WHEN CHARINDEX('||', @pSort) = 1
                         THEN tResult.wCounterRid
                    END DESC ,
                    CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.RowID
                    END DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS FETCH NEXT @pPageSize
                    ROWS ONLY
                    OPTION(RECOMPILE);
    END;