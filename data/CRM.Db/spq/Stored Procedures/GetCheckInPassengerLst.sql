CREATE PROCEDURE [spq].[GetCheckInPassengerLst]
(
    @pType VARCHAR(25) = 'CS' ,
    @pStatus VARCHAR(10) ,
    @pLangCd VARCHAR(10) = 'en-gb' ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1           
)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pType = ISNULL(@pType, '');
        SET @pStatus = NULLIF(@pStatus, '');
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'en-gb');
        SET @pPageSize = IIF(ISNULL(@pPageSize, 0) <= 0, 999, @pPageSize);
        SET @pPageNum = IIF(ISNULL(@pPageNum, 0) <= 0, 1, @pPageNum);

        IF @pType = 'CS'
        BEGIN
            WITH tResult AS (
                SELECT
                    wSeqNo = ROW_NUMBER() OVER ( ORDER BY pd.wCrtDt ) ,
                    wBookingRefNo = eb.wRefNo + '-' + RIGHT('000' + CAST(( pd.wSeqNo ) AS VARCHAR(3)), 3) ,
                    wPassengerSeqNo = pd.wSeqNo ,
                    wCost = ISNULL(pd.wCost, 0) ,
                    wRefNo = eb.wRefNo ,
                    eb.wApprovalAgentCodeIn ,
                    eb.wDebitAgentCodeIn ,
                    eb.wReqCustomerRid ,
                    p.wAgentCodeIn wAccount ,
                    p.wCName ,
                    p.wGender ,
                    wPersonTravelDocNo = [dbo].[fnGetDocDetailsByPassengerDetailRid](pd.RowID, 'ID_NO', @pLangCd)  ,
                    pd.RowID ,
                    pd.wBookingRid ,
                    pd.wClientTicketNo ,
                    wDepartFlightNo = ecis.wFlightNo,
                    pd.wTakeOffDt ,
                    wDestination = CASE @pLangCd WHEN 'en-gb' THEN mA.wCode + ',' + mA.wEName +',' + lup.wTitle
                                                ELSE mA.wCode + ',' + mA.wCName +',' + lup.wTitle END,	
                    wAgentCodeIn = pd.wRequesterAcc ,
                    pd.wPersonRid ,
                    pd.wRemark ,
                    pd.wPassengerBookingStatus,
                    pd.wStatus ,
                    pd.wCrtBy ,
                    pd.wCrtDt ,
                    pd.wUpdDt ,
                    pd.wUpdBy ,
                    pd.wType ,
                    wChangeOrderStatus = eb.wCancelReasonCd ,
                    eb.wReqAgentCodeIn ,
                    p.wNationality ,
                    wIDType = [dbo].[fnGetDocDetailsByPassengerDetailRid](pd.RowID, 'ID_TYPE', @pLangCd) ,
                    etc.wTicCollPoint ,
                    etc.wIsCollected ,
                    wReqDepartment = eb.wReqDepartment ,
                    wServiceCounter = eb.wReqCounterRid ,
                    ecis.wTicketCollectionRid ,
                    ecis.wBookingDateRid ,
                    ecis.wServiceCounterRid ,
                    eb.wDebitDt ,
                    eb.wExpDt ,
                    pd.wCancelDt ,
                    pd.wCancelDebitDt ,
                    pd.wCancelReasonCd ,
                    pd.wOtherReason ,
                    wDebitServiceCounter = eb.wDebitCounterRid ,
                    wDebitServiceCounterName = SC.wName ,
                    daAgent.wAgentCode_Display ,
                    wDebitAccountName = CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END,
                    wDebitClientName = CASE WHEN @pLangCd = 'en-gb' THEN dcAgent.wEName ELSE dcAgent.wCName END,
                    wUpdByUser = CASE WHEN @pLangCd = 'en-gb' THEN mUpdUsr.wName ELSE mUpdUsr.wCName END
                FROM dbo.ePassengerDetails pd
                INNER JOIN dbo.eBooking eb ON eb.RowID = pd.wBookingRid AND pd.wStatus = 'A'
                INNER JOIN dbo.eBookingCheckInService ecis ON ecis.wBookingRid = pd.wBookingRid    
                LEFT JOIN dbo.mPerson p ON p.RowID = pd.wPersonRid
                INNER JOIN dbo.mServiceCounter SC ON SC.RowID = eb.wDebitCounterRid
                INNER JOIN [RollsMary].[dbo].[mAgent] dcAgent ON dcAgent.RowID = pd.wRequesterAcc
                INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.RowID = pd.wRequesterAcc
                LEFT JOIN dbo.eTicketCollection etc ON etc.wBookingRid = pd.wBookingRid
                LEFT JOIN RollsMary.dbo.mUsr mUpdUsr ON mUpdUsr.RowID = pd.wUpdBy
                LEFT JOIN dbo.mAirport mA on mA.RowID= ecis.wDestination
                INNER JOIN mLookUp lup ON lup.wCode = mA.wCity AND lup.wType = 'CITY' AND lup.wLangCd = @pLangCd
                WHERE pd.wType = @pType
                    AND ( @pStatus IS NULL OR @pStatus = pd.wPassengerBookingStatus )
            ),
            tCount AS (
                SELECT wRecordCount = COUNT(*) FROM tResult
            )

            SELECT
                tResult.* ,
                wRecordCount
            FROM tResult , tCount
            ORDER BY wCrtDt DESC
            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS          
            FETCH NEXT @pPageSize ROWS ONLY        
        END;
        ELSE IF @pType = 'PICKUPSERVICE'
        BEGIN
            WITH tResult AS (
                SELECT
                    wSeqNo = ROW_NUMBER() OVER ( ORDER BY pd.wCrtDt ) ,
                    wBookingRefNo = eb.wRefNo + '-' + RIGHT('000' + CAST(( pd.wSeqNo ) AS VARCHAR(3)), 3) ,
                    wPassengerSeqNo = pd.wSeqNo ,
                    wCost = ISNULL(pd.wCost, 0) ,
                    wRefNo = eb.wRefNo ,
                    eb.wApprovalAgentCodeIn ,
                    eb.wDebitAgentCodeIn ,
                    eb.wReqCustomerRid ,
                    p.wAgentCodeIn wAccount ,
                    p.wCName ,
                    p.wGender ,
                    wPersonTravelDocNo = [dbo].[fnGetDocDetailsByPassengerDetailRid](pd.RowID, 'ID_NO', @pLangCd) ,
                    pd.RowID ,
                    pd.wBookingRid ,
                    pd.wClientTicketNo ,
                    pd.wDepartFlightNo ,
                    pd.wTakeOffDt ,
                    pd.wDestination ,
                    wAgentCodeIn = pd.wRequesterAcc ,
                    pd.wPersonRid ,
                    pd.wRemark ,
                    pd.wPassengerBookingStatus ,
                    pd.wStatus ,
                    pd.wCrtBy ,
                    pd.wCrtDt ,
                    pd.wUpdDt ,
                    pd.wUpdBy ,
                    pd.wType ,
                    eb.wCancelReasonCd wChangeOrderStatus ,
                    eb.wReqAgentCodeIn ,
                    p.wNationality ,
                    [dbo].[fnGetDocDetailsByPassengerDetailRid](pd.RowID, 'ID_TYPE', @pLangCd) wIDType ,
                    wTicCollPoint = '' ,
                    wIsCollected = '' ,
                    wReqDepartment = eb.wReqDepartment ,
                    wServiceCounter = eb.wReqCounterRid ,
                    wTicketCollectionRid = CAST(0 AS BIGINT) ,
                    wBookingDateRid = CAST(0 AS BIGINT),
                    wServiceCounterRid = CAST(0 AS BIGINT) ,
                    eb.wDebitDt ,
                    eb.wExpDt ,
                    pd.wCancelDt ,
                    pd.wCancelDebitDt ,
                    pd.wCancelReasonCd ,
                    pd.wOtherReason ,
                    wDebitServiceCounter = eb.wDebitCounterRid ,
                    wDebitServiceCounterName = SC.wName ,
                    daAgent.wAgentCode_Display ,
                    wDebitAccountName = CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END ,
                    wDebitClientName = CASE WHEN @pLangCd = 'en-gb' THEN dcAgent.wEName ELSE dcAgent.wCName END ,
                    wUpdByUser = CASE WHEN @pLangCd = 'en-gb' THEN mUpdUsr.wName ELSE mUpdUsr.wCName END
                FROM dbo.ePassengerDetails pd
                INNER JOIN dbo.eBooking eb ON eb.RowID = pd.wBookingRid AND pd.wStatus = 'A'
                INNER JOIN dbo.eBookingPickUpService ecis ON ecis.wBookingRid = pd.wBookingRid
                LEFT JOIN dbo.mPerson p ON p.RowID = pd.wPersonRid
                INNER JOIN dbo.mServiceCounter SC ON SC.RowID = eb.wDebitCounterRid
                INNER JOIN [RollsMary].[dbo].[mAgent] dcAgent ON dcAgent.RowID = pd.wRequesterAcc
                INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.RowID = pd.wRequesterAcc
                INNER JOIN RollsMary.dbo.[mUsr] (NOLOCK) mUpdUsr ON [mUpdUsr].RowID = pd.[wUpdBy]
                WHERE pd.wType = @pType 
                    AND ( @pStatus IS NULL OR @pStatus = pd.wPassengerBookingStatus )
            ),
            tCount AS (
                SELECT wRecordCount = COUNT(*) FROM tResult
            )

            SELECT tResult.*, wRecordCount
            FROM tResult , tCount
            ORDER BY wCrtDt DESC
            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS          
            FETCH NEXT @pPageSize ROWS ONLY; 
        END;
    END;