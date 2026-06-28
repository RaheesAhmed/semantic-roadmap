CREATE PROCEDURE [spq].[GetAdditionalExpenseLst]
    (
      @pOrderNo AS VARCHAR(30) ,
      @pFromDebitDt AS DATETIME2 ,
      @pToDebitDt AS DATETIME2 ,
      @pDebitAgentCodeIn AS VARCHAR(14) ,
      @pDebitCounterRidXML AS XML ,
      @pReqDeptCd AS VARCHAR(30) ,
      @pFollowUpDeptCd AS VARCHAR(30) ,
      @pExpenseType AS BIGINT ,
      @pExpenseSubType AS BIGINT ,
      @pRefNo AS VARCHAR(30) ,
      @pReqAgentCodeIn AS VARCHAR(14) ,
      @pBookingStatusXML AS XML ,
      @pSort AS VARCHAR(200) ,
      @pLangCd AS VARCHAR(10) ,
      @pPageSize AS INT ,
      @pPageNum AS INT      
    )
AS
    BEGIN    
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;		

        DECLARE @vDebitCounterRidCount INT ,
            @vBookingStatusCount INT ,
            @sFromDebitDt DATETIME2 ,
            @sToDebitDt DATETIME2;

        DECLARE @vData_DebitCounterRid AS TABLE ( SelectionItem BIGINT );

        DECLARE @vData_BookingStatus AS TABLE
            (
              SelectionItem VARCHAR(5)
            );

        IF CAST(@pDebitCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_DebitCounterRid
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
                        FROM    @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        IF CAST(@pBookingStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_BookingStatus
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'VARCHAR(5)') AS SelectionItem
                        FROM    @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        SET @vDebitCounterRidCount = ( SELECT   COUNT(1)
                                       FROM     @vData_DebitCounterRid
                                     );

        SET @vBookingStatusCount = ( SELECT COUNT(1)
                                     FROM   @vData_BookingStatus
                                   );

        SET @pOrderNo = ISNULL(@pOrderNo, '');
        SET @sFromDebitDt = ISNULL(@pFromDebitDt, '0001-01-01');
        SET @sToDebitDt = ISNULL(@pToDebitDt, '9999-12-31');
        SET @pDebitAgentCodeIn = ISNULL(@pDebitAgentCodeIn, '');
        SET @pReqDeptCd = ISNULL(@pReqDeptCd, '');
        SET @pFollowUpDeptCd = ISNULL(@pFollowUpDeptCd, '');
        SET @pExpenseType = ISNULL(@pExpenseType, 0);
        SET @pExpenseSubType = ISNULL(@pExpenseSubType, 0);
        SET @pRefNo = ISNULL(@pRefNo, '');
        SET @pReqAgentCodeIn = ISNULL(@pReqAgentCodeIn, '');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pPageSize = ISNULL(@pPageSize, 999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
		
		-- 因為 wDebitDt 變左做 date value, 所以 Translate 一下
        SET @sFromDebitDt = CAST(@sFromDebitDt AS DATE);
        IF @pToDebitDt IS NOT NULL
            SET @sToDebitDt = DATEADD(MICROSECOND, -1, DATEADD(DAY, 1, CAST(CAST(@sToDebitDt AS DATE) AS DATETIME2)));
	    
        WITH    tResult
                  AS ( SELECT   eb.wRefNo ,
                                eb.wDebitDt ,
                                sc.wName AS wDebitServiceCounter ,
                                eb.wReqDepartment ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName
                                     ELSE rqusr.wCName
                                END AS wReqUserRidByCName ,
                                eb.wDeptFollwedCd ,
                                CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName
                                     ELSE sfusr.wCName
                                END AS wStaffFollwedRidByCName ,
                                daAgent.wAgentCode_Display ,
                                rqAgent.wAgentCode_Display AS wReqAgentCode_Display ,
                                eb.wAsstBooker ,
                                ae.wOrderNo ,
                                ae.wCurrcode ,
                                ae.wTotalAmt ,
                                et.wName AS wExpenseTypeName ,
                                est.wName AS wExpenseSubtypeName ,
                                r.wName AS wRestaurantRidByName ,
                                ae.wPaymentMethod ,
                                ae.wRemark ,
                                ae.wBookingStatus ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                ae.wUpdDt ,
                                ae.RowID ,
                                ae.wBookingRid ,
                                ae.wBookingRefRid ,
                                ae.wRoomBookingRid,
                                CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName
                                     ELSE daAgent.wCName
                                END AS wAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName
                                     ELSE rqAgent.wCName
                                END AS wReqAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN mec.wEName
                                     ELSE mec.wCName
                                END AS wEventCodeByName ,
                                b.wRefNo AS wParentRefNo ,
                                wAgentCodeIn = eb.wDebitAgentCodeIn 
                       FROM     dbo.eAdditionalExpense ae
                                INNER JOIN dbo.eBooking eb ON eb.RowID = ae.wBookingRefRid AND ae.wStatus = 'A'
                                LEFT JOIN dbo.eBooking b ON b.RowID = ae.wBookingRid
                                INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
                                INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                                LEFT JOIN dbo.mExpenseType et ON et.RowID = ae.wExpenseType
                                LEFT JOIN dbo.mExpenseSubtype est ON est.RowID = ae.wExpenseSubtype AND est.wExpenseTypeId = et.RowID
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ae.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ae.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] rqusr ON rqusr.RowID = eb.wReqUserRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] sfusr ON sfusr.RowID = eb.wStaffFollwedRid
                                LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
                                LEFT JOIN dbo.mRestaurant r ON r.RowID = ae.wRestaurantRid
                                LEFT JOIN @vData_DebitCounterRid v ON eb.wDebitCounterRid = v.SelectionItem
                                LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = ae.wBookingStatus
                                LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
                       WHERE    ( @pOrderNo = ''
                                  OR @pOrderNo = ae.wOrderNo
                                )
                                AND ( eb.wDebitDt BETWEEN @sFromDebitDt AND @sToDebitDt )
                                AND ( @pDebitAgentCodeIn = ''
                                      OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn
                                    )
                                AND ( @vDebitCounterRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
                                    )
                                AND ( @pReqDeptCd = ''
                                      OR @pReqDeptCd = eb.wReqDepartment
                                    )
                                AND ( @pFollowUpDeptCd = ''
                                      OR @pFollowUpDeptCd = eb.wDeptFollwedCd
                                    )
                                AND ( @pExpenseType <= 0
                                      OR @pExpenseType = ae.wExpenseType
                                    )
                                AND ( @pExpenseSubType <= 0
                                      OR @pExpenseSubType = ae.wExpenseSubtype
                                    )
                                AND ( @pRefNo = ''
                                      OR @pRefNo = eb.wRefNo
                                    )
                                AND ( @pReqAgentCodeIn = ''
                                      OR @pReqAgentCodeIn = eb.wReqAgentCodeIn
                                    )
                                AND ( @vBookingStatusCount <= 0
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
            ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wDebitDt
                     END DESC ,
                    CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wRefNo
                    END DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;