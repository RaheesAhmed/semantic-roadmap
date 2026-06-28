
CREATE PROCEDURE [spq].[GetBookingLeadingLst]
    (
      @pRefNo VARCHAR(30) ,
      @pFromDebitDt DATETIME2 ,
      @pToDebitDt DATETIME2 ,
      @pDebitCounterRidXML XML ,
      @pReqDeptCode VARCHAR(30) ,
      @pFollowUpDeptCode VARCHAR(30) ,
      @pDebitAgentCodeIn VARCHAR(14) ,
      @pReqAgentCodeIn VARCHAR(14) ,
      @pTravelAgencyRid AS BIGINT ,
      @pOrderNo VARCHAR(20) ,
      @pPaymentMethod VARCHAR(30) ,
      @pBookingStatusXML AS XML ,
      @pSort VARCHAR(200) ,
      @pLangCd VARCHAR(10) = 'en-GB' ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN  
	-- SET NOCOUNT ON added to prevent extra result sets from  
	-- interfering with SELECT statements.  
        SET NOCOUNT ON;  

        DECLARE @vDebitCounterRidCount AS INT ,
            @vBookingStatusCount AS INT;

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
        SET @pRefNo = ISNULL(@pRefNo, '');
        SET @pFromDebitDt = ISNULL(@pFromDebitDt, '0001-01-01');
        SET @pToDebitDt = ISNULL(@pToDebitDt, '9999-12-31');  
        SET @pReqDeptCode = ISNULL(@pReqDeptCode, '');
        SET @pFollowUpDeptCode = ISNULL(@pFollowUpDeptCode, '');
        SET @pDebitAgentCodeIn = ISNULL(@pDebitAgentCodeIn, '');
        SET @pReqAgentCodeIn = ISNULL(@pReqAgentCodeIn, '');
        SET @pTravelAgencyRid = ISNULL(@pTravelAgencyRid, 0);
        SET @pOrderNo = ISNULL(@pOrderNo, '');
        SET @pPaymentMethod = ISNULL(@pPaymentMethod, '');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
   
	-- Insert statements for procedure here  
        WITH    tResult
                  AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY bt.RowID ) AS wSeqNo ,
                                bt.[RowID] ,
                                bt.[wBookingRid] ,
                                eb.[wRefNo] ,
                                mta.wName AS wAgencyName ,
                                bt.[wOrderNo] ,
                                eb.[wDebitDt] ,
                                bt.[wPaymentMethod] ,
                                bt.[wReceiptNo] ,
                                bt.[wTotalAmt] ,
                                bt.[wCurrCode] ,
                                bt.[wRemark] ,
                                bt.[wStatus] ,
                                bt.[wBookingStatus] ,
                                bt.[wUnqualifiedRid] ,
                                bt.[wUpdDt] ,
                                eb.wReqDepartment ,
                                eb.wReqCounterRid AS requestedServiceCounterid ,
                                wAgentCodeIn = eb.wDebitAgentCodeIn ,
                                msc.wName AS wRequestedServiceCounter ,
                                daAgent.wAgentCode_Display ,
                                '' AS wDebitClientName ,
                                sc.wName AS wDebitServiceCounterName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName
                                     ELSE rqusr.wCName
                                END AS wReqUserRidByCName ,
                                eb.wDeptFollwedCd ,
                                CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName
                                     ELSE sfusr.wCName
                                END AS wStaffFollwedRidByCName ,
                                rqAgent.wAgentCode_Display AS wReqAgentCode_Display ,
                                eb.wAsstBooker ,
                                ta.wName AS wTravelAgencyRidByName ,
                                bt.wNoofPolice ,
                                bt.wStartDt ,
                                eb.wDepositAmt ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName
                                     ELSE daAgent.wCName
                                END AS wAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName
                                     ELSE rqAgent.wCName
                                END AS wReqAgentCodeByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN mec.wEName
                                     ELSE mec.wCName
                                END AS wEventCodeByName
                       FROM     dbo.eBookingLeading bt
                                INNER JOIN dbo.eBooking eb ON eb.RowID = bt.wBookingRid
                                INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
                                LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = eb.wReqCounterRid
                                LEFT JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                                LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
                                LEFT JOIN dbo.mTravelAgency mta ON mta.RowID = bt.wTravelAgencyRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = bt.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = bt.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] rqusr ON rqusr.RowID = eb.wReqUserRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] sfusr ON sfusr.RowID = eb.wStaffFollwedRid
                                LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = bt.wTravelAgencyRid
                                LEFT JOIN @vData_DebitCounterRid v ON v.SelectionItem = eb.wDebitCounterRid
                                LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = bt.wBookingStatus
						  LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
                       WHERE    ( @pRefNo = ''
                                  OR @pRefNo = eb.wRefNo
                                )
                                AND ( @pFromDebitDt <= eb.wDebitDt
                                      AND @pToDebitDt >= eb.wDebitDt
                                    )
                                AND ( @vDebitCounterRidCount <= 0
                                      OR v.SelectionItem IS NOT NULL
                                    )
                                AND ( @pReqDeptCode = ''
                                      OR @pReqDeptCode = eb.wReqDepartment
                                    )
                                AND ( @pFollowUpDeptCode = ''
                                      OR @pFollowUpDeptCode = eb.wDeptFollwedCd
                                    )
                                AND ( @pDebitAgentCodeIn = ''
                                      OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn
                                    )
                                AND ( @pReqAgentCodeIn = ''
                                      OR @pReqAgentCodeIn = eb.wReqAgentCodeIn
                                    )
                                AND ( @pTravelAgencyRid = 0
                                      OR @pTravelAgencyRid = bt.wTravelAgencyRid
                                    )
                                AND ( @pOrderNo = ''
                                      OR @pOrderNo = bt.wOrderNo
                                    )
                                AND ( @pPaymentMethod = ''
                                      OR @pPaymentMethod = bt.wPaymentMethod
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
    OPTION(RECOMPILE);  
    END;