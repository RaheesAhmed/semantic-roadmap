CREATE PROCEDURE [spq].[GetHotelBookingRequest]
(
    @pCrtDt DATETIME2 ,
    @pReqCounterRidXML XML ,
    @pReqAgentCodeIn VARCHAR(14) ,
    @pRegion VARCHAR(3) ,
    @pIsRejected CHAR(1) ,
    @pHotelRequest VARCHAR(20) ,
    @pHotelRequestRid BIGINT,
    @pNumberOfRoom INT ,
    @pStartDate DATETIME2 ,
    @pFromStartDate DATETIME2 ,
    @pToStartDate DATETIME2 ,
    @pCounterRid BIGINT ,
    @pIsAgentHotel CHAR(1) ,
    @pStatusXML XML ,
    @pSort VARCHAR(200) ,
    @pPageSize INT ,
    @pTaskType VARCHAR(10) ,
    @pPageNum INT = 1 ,
    @pLangCd VARCHAR(10)
)
AS
    BEGIN
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        SET NOCOUNT ON;
       
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @vFromCrtDt          DATETIME2 = '0001-01-01' ,
                @vToCrtDt            DATETIME2 = '9999-12-31' ,
                @vCompNo             INT ,
                @vYearMth            VARCHAR(6) ,
                @vReqCounterRidCount INT ,
                @vStatusCount        INT;

        DECLARE @vData_ReqCounterRid TABLE ( wServiceCounterRid BIGINT PRIMARY KEY );
        DECLARE @vData_Status TABLE ( wStatus VARCHAR(3) PRIMARY KEY );
        CREATE TABLE #vMAHotelRequest (wHotelRequestRid BIGINT PRIMARY KEY);

        IF @pReqCounterRidXML IS NOT NULL
        BEGIN
            INSERT INTO @vData_ReqCounterRid ( wServiceCounterRid )
            SELECT DISTINCT T.tmp.value('@SelectionItem', 'BIGINT')
            FROM   @pReqCounterRidXML.nodes('/DataSet/Record') T(tmp)
            WHERE  T.tmp.value('@SelectionItem', 'BIGINT') > 0;
        END;

        IF @pStatusXML IS NOT NULL
        BEGIN
            INSERT INTO @vData_Status ( wStatus )
            SELECT DISTINCT T.tmp.value('@SelectionItem', 'VARCHAR(3)')
            FROM   @pStatusXML.nodes('/DataSet/Record') T(tmp)
            WHERE  NULLIF(tmp.value('@SelectionItem', 'VARCHAR(3)'), '') IS NOT NULL;
        END;

        SET @vReqCounterRidCount = ( SELECT COUNT(1) FROM @vData_ReqCounterRid );
        SET @vStatusCount        = ( SELECT COUNT(1) FROM @vData_Status );
        
        SET @pReqAgentCodeIn= NULLIF(@pReqAgentCodeIn, '');
        SET @pRegion        = NULLIF(@pRegion, '');
        SET @pIsRejected    = NULLIF(@pIsRejected, ' ');
        SET @pHotelRequest  = NULLIF(@pHotelRequest, '');
        SET @pNumberOfRoom  = ISNULL(@pNumberOfRoom, 0);
        SET @pCounterRid    = ISNULL(@pCounterRid, 0);
        SET @pIsAgentHotel  = NULLIF(@pIsAgentHotel, '');
        SET @pSort          = ISNULL(NULLIF(@pSort, ''), '||');
        SET @pLangCd        = LOWER(ISNULL(NULLIF(@pLangCd, ''), 'en-gb'));
        SET @pPageSize      = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 100);
        SET @pPageNum       = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);
        SET @pTaskType      = NULLIF(@pTaskType, '');
        SET @pFromStartDate = ISNULL(@pFromStartDate, '0001-01-01');
        SET @pToStartDate   = ISNULL(@pToStartDate, '9999-12-31');

        IF @pCrtDt IS NOT NULL
        BEGIN
            SET @vFromCrtDt = CAST(@pCrtDt AS DATE);
            SET @vToCrtDt   = DATEADD(dd, 1, @vFromCrtDt);
        END;

        IF @pStartDate IS NOT NULL
        BEGIN
            SET @pFromStartDate = CAST(@pStartDate AS DATE);
            SET @pToStartDate   = DATEADD(dd, 1, @pFromStartDate);
        END;

        SELECT  @vCompNo = wRollexCompNo
        FROM    CRM.dbo.mServiceCounter
        WHERE   RowID = @pCounterRid;

        SET @vCompNo = ISNULL(@vCompNo, 10);
        
        SELECT @vYearMth = CONCAT(wYear, wMonth)
        FROM   RollsMary.dbo.mSettlePeriod
        WHERE  wCompNo = @vCompNo
            AND RollsMary.dbo.fnUTC8Now() BETWEEN wStartDateTime AND wEndDateTime
        
        ;WITH tHotelLst AS ( 
            SELECT DISTINCT
                wHotelRequestRid = A.wHotelRequestRid, 
                wHotelCd = B.wValue
            FROM (
                SELECT wHotelRequestRid = RowID, wValue = CONVERT(xml,'<DataSet><Record>' + REPLACE(REPLACE(wHotelCodeSCV,'&', '&amp;'), ',', '</Record><Record>') + '</Record></DataSet>') FROM dbo.eHotelRequest
            ) A
            OUTER APPLY(
                SELECT wValue = T.tmp.value('.', 'varchar(100)') FROM A.wValue.nodes('DataSet/Record') T(tmp)
            ) B
            WHERE NULLIF(B.wValue, '') IS NOT NULL
        )

        INSERT INTO #vMAHotelRequest
        SELECT DISTINCT hl.wHotelRequestRid
        FROM dbo.mServiceCounter sc
        INNER JOIN dbo.mAllotmentGroupDtl agd ON sc.RowID = agd.wCounterRid
        INNER JOIN dbo.mAllotmentGroup ag ON agd.wAllotmentGroupRid = ag.RowID
        INNER JOIN dbo.eAllotmentHotelDtl ahd ON ag.RowID = ahd.wAllotmentGroupRid
        INNER JOIN dbo.eAllotmentHotel ah ON ahd.wAllotmentHotelRid= ah.RowID
        INNER JOIN	dbo.mHotel h ON h.RowID = ah.wHotelRid
        INNER JOIN tHotelLst hl ON hl.wHotelCd = h.wCode
        WHERE sc.RowID = @pCounterRid;
        
        -- Insert statements for procedure here
        ;WITH tHotelRequestDtl AS (
                SELECT
                    wHotelRequestRid ,
                    wTotalProvideRoomQty_Summary = SUM(wTotalProvideRoomQty) ,
                    wThisCounterAllReject = CASE WHEN SUM(CASE WHEN wIsReject = 'Y' AND wCounterRid = @pCounterRid THEN 1 ELSE 0 END) 
                                                    = SUM(CASE WHEN wCounterRid = @pCounterRid THEN 1 ELSE 0 END)
                                                  AND SUM(CASE WHEN wCounterRid = @pCounterRid THEN 1 ELSE 0 END) > 0 THEN 'Y'
                                                 ELSE 'N'
                                            END ,
                    wRelatedThisCounter = CASE WHEN SUM(CASE WHEN wCounterRid = @pCounterRid THEN 1 ELSE 0 END) > 0 THEN 'Y'
                                               ELSE 'N'
                                          END
                FROM  dbo.eHotelRequestDtl
                GROUP BY wHotelRequestRid
        ),
        tResult AS (
            SELECT
                ehr.wEventCodeRid ,
                wSeqNo = 0 ,
                wBookingRid = CAST(0 AS BIGINT),
                ehr.RowID ,
                wRequestRID = ehr.RowID ,
                wRefNo = '' ,
                ehr.wRequestNo ,
                ehr.wReqUserRid ,
                ehr.wRegion ,
                wAgentCodeIn = ehr.wReqAgentCodeIn ,
                wReqAgentCode_Display = rqAgent.wAgentCode_Display ,
                ehr.wNumberOfRoom ,
                ehr.wDayOfStay ,
                ehr.wStartDate ,
                ehr.wDebitAgentCodeIn ,
                ehr.wReqCustomerRid ,
                ehr.wReqCounterRid ,
                ehr.wApprovalAgentCodeIn ,
                ehr.wDebitCounterRid ,
                ehr.wAsstBookerEmail ,
                ehr.wDeptFollwedCd ,
                ehr.wStaffFollwedRid ,
                ehr.wStaffTelephone ,
                ehr.wOwnerAuthTelephone ,
                ehr.wDebitCustomerRid ,
                ehr.wReqDepartment ,
                ehr.wAsstBooker ,
                ehr.wAssBookerTel ,
                wRegionCode = ehr.wRegion ,
                ehr.wHotelCodeSCV ,
                ehr.wEndDate ,
                wHotelRequest = (SELECT STUFF(( SELECT CONCAT(', ', h.wName, '(', SUM(hrd.wTotalProvideRoomQty), ')')
                                                 FROM dbo.eHotelRequestDtl hrd
                                                 INNER JOIN dbo.mHotel h ON hrd.wHotelCode = h.wCode
                                                 WHERE hrd.wHotelRequestRid = ehr.RowID
                                                 GROUP BY h.wName , hrd.wHotelCode
                                                 FOR XML PATH('')), 1, 2, '')) ,
                wHotelRid = ( SELECT STUFF(( SELECT CONCAT(', ', h.RowID)
                                             FROM dbo.eHotelRequestDtl hrd
                                             INNER JOIN dbo.mHotel h ON hrd.wHotelCode = h.wCode
                                             WHERE   hrd.wHotelRequestRid = ehr.RowID
                                             GROUP BY h.RowID , hrd.wHotelCode
                                             FOR XML PATH('') ), 1, 2, '')) ,
                ehr.wIsAgentHotel ,
                ehr.wIsSelectRoom ,
                ehr.wBedType ,
                ehr.wRemark ,
                ehr.wStatus ,
                ehr.wCrtDt ,
                ehr.wCrtBy ,
                ehr.wUpdDt ,
                ehr.wUpdBy ,
                CAST(ehd.wTotalProvideRoomQty_Summary AS VARCHAR(5)) + '/' + CAST(ehr.wNumberOfRoom AS VARCHAR(5)) AS wRoomAssigned ,
                ehr.wLockCounterRid ,
                wIsLock = CAST(IIF(ISNULL(ehr.wLockCounterRid, 0) <> 0, 'Y', 'N')  AS CHAR(1)),
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END ,
                wCounterRid = ehr.wCounterRid ,
                wIsSelected = CAST(0 AS BIT) ,
                wHasAccess = CAST(( CASE WHEN @pTaskType = 'MA' THEN IIF(mahr.wHotelRequestRid IS NULL, 0, 1)
                                         WHEN @pTaskType = 'MR' THEN IIF( ehr.wCounterRid = @pCounterRid, 1, 0)
                                         ELSE 1
                                    END ) AS BIT) ,
                wIsEligibleForReject = CASE WHEN ehr.wStatus = 'P' AND ehd.wRelatedThisCounter = 'Y' AND ehd.wThisCounterAllReject = 'N' THEN CAST(1 AS BIT)--加上AND ehd.wThisCounterAllReject='N' 已经拒绝派房的CheckBox就不显示了
                                            ELSE CAST(0 AS BIT)
                                       END ,
                wIsRejected = ehd.wThisCounterAllReject ,
                wRequestedServiceCounter = msc.wName ,
                wReqUserRidByCName = CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName ELSE rqusr.wCName END ,
                ehr.wUnqualifiedRid ,
                ehr.wCancelReasonCd ,
                ehr.wOtherReason ,
                ehr.wCancelDt ,
                ehr.wCancelBy ,
                wReqAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName ELSE rqAgent.wCName END,
                ehr.wCoordinator,
                ehr.wIsUser,
                ehr.wUser
            FROM dbo.eHotelRequest ehr
            INNER JOIN RollsMary.dbo.mAgent rqAgent ON rqAgent.wAgentCodeIn = ehr.wReqAgentCodeIn
            INNER JOIN dbo.mServiceCounter msc ON msc.RowID = ehr.wReqCounterRid
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = ehr.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = ehr.wCrtBy
            LEFT JOIN RollsMary.dbo.mUsr rqusr ON rqusr.RowID = ehr.wReqUserRid
            LEFT JOIN tHotelRequestDtl ehd ON ehd.wHotelRequestRid = ehr.RowID
            LEFT JOIN #vMAHotelRequest mahr ON mahr.wHotelRequestRid = ehr.RowID
            LEFT JOIN @vData_ReqCounterRid v ON v.wServiceCounterRid = ehr.wReqCounterRid
            LEFT JOIN @vData_Status vs ON vs.wStatus = ehr.wStatus
            WHERE (   @pTaskType IS NULL 
                  OR (@pTaskType = 'MA' AND mahr.wHotelRequestRid IS NOT NULL)
                  OR (@pTaskType = 'MR' AND ehr.wCounterRid = @pCounterRid)
                )
                AND ehr.wCounterRid > 0
                AND ehr.wCrtDt BETWEEN @vFromCrtDt AND @vToCrtDt
                AND ( @vReqCounterRidCount = 0 OR v.wServiceCounterRid IS NOT NULL )
                AND ( @pReqAgentCodeIn IS NULL OR @pReqAgentCodeIn = ehr.wReqAgentCodeIn )
                AND ( @pRegion IS NULL OR @pRegion = ehr.wRegion )
                AND ( @pIsRejected IS NULL OR @pIsRejected = ehd.wThisCounterAllReject )
                AND ( @pHotelRequest IS NULL OR CHARINDEX(@pHotelRequest, ehr.wHotelCodeSCV) > 0)
                AND ( @pNumberOfRoom = 0 OR @pNumberOfRoom = ehr.wNumberOfRoom )
                AND ( @pStartDate IS NULL
                 OR ( @pFromStartDate <= ehr.wStartDate AND @pToStartDate >= ehr.wStartDate )
                )
                AND ( @pStartDate IS NOT NULL
                 OR ( ehr.wStartDate <= @pToStartDate AND ehr.wEndDate > @pFromStartDate )
                )
                AND ( @pIsAgentHotel IS NULL OR @pIsAgentHotel = ehr.wIsAgentHotel )
                AND ( @vStatusCount = 0 OR vs.wStatus IS NOT NULL )
                AND ( @pHotelRequestRid IS NULL OR @pHotelRequestRid = ehr.RowID )
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT  tResult.* ,
                wRecordCount
        INTO #tResult
        FROM    tResult ,
                tCount
        ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wCrtDt END DESC ,
                 CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wRefNo END DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
        
        ;WITH tTaskSheetHotel AS (
            SELECT
                hrd.wHotelRequestRid, 
                hrd.wCounterRid, 
                wCounterName = sc.wName,
                wResponseRemark = (SELECT CONCAT( h.wName, N': ', x.wRemark)
                                    FROM    dbo.eTaskSheet x
                                    WHERE   x.RowID = MAX(ts.RowID))
            FROM dbo.eTaskSheet ts 
            INNER JOIN dbo.eHotelRequestDtl hrd ON ts.wRelatedRid = hrd.RowID
            INNER JOIN dbo.mHotel h ON hrd.wHotelCode = h.wCode
            INNER JOIN dbo.mServiceCounter sc ON ts.wCounterRid = sc.RowID
            WHERE wRelatedType = 'eHotelRequestDtl'
            GROUP BY hrd.wHotelRequestRid, hrd.wCounterRid, sc.wName, h.wName
        ), 
        tTaskSheetCounter AS (
            SELECT 
                wHotelRequestRid,
                wResponseRemark = cte.wCounterName + '\r\n' +
                    ( SELECT STUFF(( SELECT CONCAT('\r\n' , x.wResponseRemark)
                        FROM tTaskSheetHotel x
                        WHERE	x.wHotelRequestRid = cte.wHotelRequestRid AND x.wCounterRid = cte.wCounterRid
                        FOR XML PATH('')), 1, 4, N''))
            FROM tTaskSheetHotel cte
            GROUP BY cte.wHotelRequestRid, cte.wCounterRid, cte.wCounterName
        ),
        tRequestTaskSheet AS (
            SELECT
                rts.wHotelRequestRid,
                wResponseRemark = (SELECT STUFF((SELECT '\r\n\r\n' + sts.wResponseRemark
                                                 FROM tTaskSheetCounter sts 
                                                 WHERE sts.wHotelRequestRid = rts.wHotelRequestRid
                                                 FOR XML PATH('')), 1, 8, N'' ))
            FROM tTaskSheetCounter AS rts
            GROUP BY rts.wHotelRequestRid
        ),
        tRollingAmt AS (
            SELECT  
                wAgentCodeIn ,
                wGroupRollingHKD = SUM(wRollingAPlayHKD + wRollingBPlayHKD + wRollingInstantSettledAPlayHKD + wRollingInstantSettledBPlayHKD) ,
                wCompRollingHKD = SUM(IIF( wCompNo = @vCompNo, (wRollingAPlayHKD + wRollingBPlayHKD) - (wRollingInstantSettledAPlayHKD + wRollingInstantSettledBPlayHKD), 0))
            FROM RollsMary.dbo.mAgentBalRollingMonth
            WHERE wYearMth = @vYearMth
            GROUP BY wAgentCodeIn
        )

        SELECT
            tr.*,
            wGroupRollingHKD = ISNULL(r.wGroupRollingHKD, 0) ,
            wCompRollingHKD = ISNULL(r.wCompRollingHKD, 0) ,
            wResponseRemark = REPLACE(rts.wResponseRemark, '\r\n', CHAR(10))
        FROM #tResult AS tr
        LEFT JOIN tRollingAmt AS r ON r.wAgentCodeIn = tr.wAgentCodeIn
        LEFT JOIN tRequestTaskSheet AS rts ON rts.wHotelRequestRid = tr.wRequestRID
        OPTION(RECOMPILE);
        
        IF OBJECT_ID('temp..#vMAHotelRequest') IS NOT NULL
            DROP TABLE #vMAHotelRequest;

        IF OBJECT_ID('tempdb..#tResult') IS NOT NULL BEGIN
            DROP TABLE #tResult;
        END
    END;