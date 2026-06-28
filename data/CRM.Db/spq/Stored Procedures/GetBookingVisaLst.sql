

CREATE PROCEDURE [spq].[GetBookingVisaLst]
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
      @pApplyDt DATETIME2 ,
      @pPlaceOfIssue VARCHAR(6) ,
      @pPaymentMethod VARCHAR(30) ,
      @pTicketCollectionCdXML AS XML ,
      @pIsTicketCollected AS VARCHAR(10) ,
      @pBookingStatusXML XML ,
      @pSort VARCHAR(200) ,
      @pLangCd VARCHAR(10) ,
      @pPageSize INT ,
      @pPageNum INT ,
      @pBookingRid BIGINT ,
      @pTravelPackageRid BIGINT ,
      @pTravelPackageStatus VARCHAR(3)
    )
AS
    BEGIN 
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        DECLARE @vFromDt AS DATETIME2 = '0001-01-01' ,
            @vToDt AS DATETIME2 = '9999-12-31' ,
            @vDebitCounterRidCount AS INT ,
            @vTicketCollectionCdCount AS INT ,
            @vBookingStatusCount AS INT;

        DECLARE @vData_DebitCounterRid AS TABLE ( SelectionItem BIGINT PRIMARY KEY );

        DECLARE @vData_TicketCollectionCd AS TABLE ( SelectionItem BIGINT PRIMARY KEY );

        DECLARE @vData_BookingStatus AS TABLE ( SelectionItem VARCHAR(5) PRIMARY KEY );

        IF CAST(@pDebitCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT  INTO @vData_DebitCounterRid ( SelectionItem )
            SELECT  DISTINCT T.tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
            FROM    @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp )
            WHERE   T.tmp.value('@SelectionItem', 'BIGINT') > 0;
        END;

        IF CAST(@pTicketCollectionCdXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT  INTO @vData_TicketCollectionCd ( SelectionItem )
            SELECT  DISTINCT tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
            FROM    @pTicketCollectionCdXML.nodes('/DataSet/Record') AS T ( tmp )
            WHERE T.tmp.value('@SelectionItem', 'BIGINT') > 0;
        END;

        IF CAST(@pBookingStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT  INTO @vData_BookingStatus ( SelectionItem )
            SELECT  tmp.value('@SelectionItem', 'VARCHAR(5)') AS SelectionItem
            FROM    @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp )
            WHERE   NULLIF(T.tmp.value('@SelectionItem', 'VARCHAR(5)'), '') IS NOT NULL;
        END;

        SET @vDebitCounterRidCount = ( SELECT   COUNT(1) FROM     @vData_DebitCounterRid );
        SET @vTicketCollectionCdCount = ( SELECT    COUNT(1) FROM      @vData_TicketCollectionCd );
        SET @vBookingStatusCount = ( SELECT COUNT(1) FROM   @vData_BookingStatus );

        SET @pRefNo = ISNULL(@pRefNo, '');
        SET @pFromDebitDt = ISNULL(@pFromDebitDt, '0001-01-01');
        SET @pToDebitDt = ISNULL(@pToDebitDt, '9999-12-31');  
        SET @pReqDeptCode = ISNULL(@pReqDeptCode, '');
        SET @pFollowUpDeptCode = ISNULL(@pFollowUpDeptCode, '');
        SET @pDebitAgentCodeIn = ISNULL(@pDebitAgentCodeIn, '');
        SET @pReqAgentCodeIn = ISNULL(@pReqAgentCodeIn, '');
        SET @pTravelAgencyRid = ISNULL(@pTravelAgencyRid, 0);
        IF @pApplyDt IS NOT NULL
            BEGIN
                SET @vFromDt = @pApplyDt;
                SET @vToDt = DATEADD(dd, 1, @pApplyDt);
            END;
        SET @pPlaceOfIssue = ISNULL(@pPlaceOfIssue, '');
        SET @pPaymentMethod = ISNULL(@pPaymentMethod, '');
        SET @pIsTicketCollected = ISNULL(@pIsTicketCollected, '');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
        SET @pTravelPackageRid = ISNULL(@pTravelPackageRid, 0);
        SET @pTravelPackageStatus = ISNULL(@pTravelPackageStatus, '');
        SET @pBookingRid = ISNULL(@pBookingRid, 0);                       
        SET NOCOUNT ON;
		       
        WITH    tResult
                  AS ( SELECT DISTINCT
                                ebv.RowId ,
                                eb.wRefNo ,
                                eb.wTravePkgRid ,
                                ebv.wBookingRid ,
                                ebv.wOrderNo ,
                                ebv.wUseBlackCard ,
                                ebv.wApplyDt ,
                                ebv.wPlaceOfIssue ,
                                mta.wName AS wAgencyName ,
                                ebv.wCurrCode ,
                                ebv.wExpAmt ,
                                ISNULL(PSDAMT.wAmount, 0) AS wTotalAmt ,
                                ISNULL(PSDAMT.wCost, 0) AS wCost ,
                                ebv.wBookingStatus AS wStatusCode ,
                                ebv.wUnqualifiedRid ,
                                ebv.wStatus ,
                                ebv.wCrtBy ,
                                ebv.wCrtDt ,
                                ebv.wUpdBy ,
                                ebv.wUpdDt ,
                                ebv.wTravelAgencyRid ,
                                ebv.wQuantity ,
                                ebv.wAdditionalExp ,
                                ebv.wRemark ,
                                ebv.wReceiptNo ,
                                wAgentCodeIn = eb.wDebitAgentCodeIn ,
                                eb.wDebitDt ,
                                eb.wDebitCounterRid AS wDebitServiceCounter ,
                                SC.wName AS wDebitServiceCounterName ,
                                daAgent.wAgentCode_Display ,
                                '' AS wDebitClientName ,
                                eb.wReqDepartment ,
                                eb.wReqCounterRid AS wServiceCounter ,
                                ebv.wBookingStatus ,
                                ebv.wPaymentMethod ,
                                msc.wName AS wRequestedServiceCounter ,
                                ta.wName AS wTravelAgencyRidByName ,
                                eb.wDepositAmt ,
                                CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName
                                     ELSE rqusr.wCName
                                END AS wReqUserRidByCName ,
                                eb.wDeptFollwedCd ,
                                CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName
                                     ELSE sfusr.wCName
                                END AS wStaffFollwedRidByCName ,
                                rqAgent.wAgentCode_Display AS wReqAgentCode_Display ,
                                eb.wAsstBooker ,
                                mtc.wName AS wTicCollPointByName ,
                                vc.wIsCollected ,
                                wClient = bm.wValue,
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
                                END AS wReqAgentCodeByName 
                       FROM     [CRM].[dbo].eBookingVisa ebv
                                INNER JOIN dbo.eBooking eb ON eb.RowID = ebv.wBookingRid
                                LEFT JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                                LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
                                LEFT JOIN dbo.eBookingTravelPackage ebtp ON ebtp.RowID = eb.wTravePkgRid
                                LEFT JOIN dbo.mServiceCounter SC ON SC.RowID = eb.wDebitCounterRid
                                LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = eb.wReqCounterRid
                                LEFT JOIN dbo.mTravelAgency mta ON mta.RowID = ebv.wTravelAgencyRid
                                LEFT JOIN ( SELECT  wBookingRid ,
                                                    SUM(wAmount) AS wAmount ,
                                                    SUM(wCost) AS wCost
                                            FROM    dbo.ePassengerDetails (NOLOCK)
                                            WHERE   wStatus = 'A'
                                                    AND wPassengerBookingStatus IN ( 'P', 'C', 'RF' )
                                            GROUP BY wBookingRid
                                          ) PSDAMT ON PSDAMT.wBookingRid = ebv.wBookingRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ebv.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ebv.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] rqusr ON rqusr.RowID = eb.wReqUserRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] sfusr ON sfusr.RowID = eb.wStaffFollwedRid
                                LEFT JOIN dbo.mTravelAgency ta ON ta.RowID = ebv.wTravelAgencyRid
                                LEFT JOIN dbo.eVisaCollection vc ON vc.wBookingRid = ebv.wBookingRid
                                LEFT JOIN dbo.mTicketCollectionPoint mtc ON mtc.wCode = vc.wTicCollPoint
                                LEFT JOIN stg.eBookingMisc bm ON bm.wBookingRid = ebv.wBookingRid AND bm.wLangCd = @pLangCd AND bm.wItemCd = 'CUST_NAME'
                                LEFT JOIN @vData_DebitCounterRid v ON v.SelectionItem = eb.wDebitCounterRid
                                LEFT JOIN @vData_TicketCollectionCd vtc ON mtc.RowID = vtc.SelectionItem
                                LEFT JOIN @vData_BookingStatus vs ON vs.SelectionItem = ebv.wBookingStatus
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
                                      OR @pTravelAgencyRid = ebv.wTravelAgencyRid
                                    )
                                AND ( @vFromDt <= ebv.wApplyDt
                                      AND @vToDt >= ebv.wApplyDt
                                    )
                                AND ( @pPlaceOfIssue = ''
                                      OR @pPlaceOfIssue = ebv.wPlaceOfIssue
                                    )
                                AND ( @pPaymentMethod = ''
                                      OR @pPaymentMethod = ebv.wPaymentMethod
                                    )
                                AND ( @vTicketCollectionCdCount <= 0
                                      OR vtc.SelectionItem IS NOT NULL
                                    )
                                AND ( @pIsTicketCollected = ''
                                      OR @pIsTicketCollected = vc.wIsCollected
                                      OR ( @pIsTicketCollected = 'false'
                                           AND vc.wIsCollected IS NULL
                                         )
                                    )
                                AND ( @vBookingStatusCount <= 0
                                      OR vs.SelectionItem IS NOT NULL
                                    )
                                AND ( @pBookingRid <= 0
                                      OR @pBookingRid = ebv.wBookingRid
                                    )
                                AND ( @pTravelPackageRid <= 0
                                      OR @pTravelPackageRid = ebtp.RowID
                                    )
                                AND ( @pTravelPackageStatus = ''
                                      OR @pTravelPackageStatus IS NULL
                                      OR @pTravelPackageStatus = ebtp.wBookingStatus
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