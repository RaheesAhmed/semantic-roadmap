
CREATE PROCEDURE [spq].[GetBookingRestaurantLst]
(
    @pRefNo VARCHAR(30) ,
    @pFromDt DATETIME2 ,
    @pToDt DATETIME2 ,
    @pDebitCounterRidXML XML ,
    @pDebitAgentCodeIn VARCHAR(14) ,
    @pDebitDt DATETIME2 ,
    @pReqDeptCd VARCHAR(30) ,
    @pFollowUpDeptCd VARCHAR(30) ,
    @pReqAgentCodeIn AS VARCHAR(14) ,
    @pBookingDt AS DATETIME2 ,
    @pBookingStatusXML AS XML ,
    @pSort VARCHAR(200) ,
    @pLangCd VARCHAR(10) ,
    @pPageSize INT ,
    @pPageNum INT
)
AS
    BEGIN
        SET NOCOUNT ON;
		  
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

        DECLARE @vFromDebitDt DATETIME2 = '0001-01-01' ,
                @vToDebitDt DATETIME2 = '9999-12-31' ,
                @vFromBookingDt DATETIME2 = '0001-01-01' ,
                @vToBookingDt DATETIME2 = '9999-12-31' ,
                @vDebitCounterRidCount INT ,
                @vBookingStatusCount AS INT;

        DECLARE @vData_DebitCounterRid AS TABLE ( wCounterRid BIGINT );
        DECLARE @vData_BookingStatus AS TABLE ( wBookingStatus VARCHAR(5) );

        IF @pDebitCounterRidXML IS NOT NULL AND CAST(@pDebitCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT  INTO @vData_DebitCounterRid ( wCounterRid )
            SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
            FROM    @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        IF @pBookingStatusXML IS NOT NULL AND CAST(@pBookingStatusXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT  INTO @vData_BookingStatus ( wBookingStatus )
            SELECT  tmp.value('@SelectionItem', 'VARCHAR(5)') AS SelectionItem
            FROM    @pBookingStatusXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        SET @vDebitCounterRidCount = ( SELECT COUNT(1) FROM @vData_DebitCounterRid );
        SET @vBookingStatusCount = ( SELECT COUNT(1) FROM @vData_BookingStatus );

        SET @pRefNo = NULLIF(@pRefNo, '');
        SET @pFromDt = ISNULL(CAST(@pFromDt AS DATE), '0001-01-01');
        SET @pToDt = ISNULL(DATEADD(DAY, 1, CAST(@pToDt AS DATE)), '9999-12-31');  		  
        SET @pDebitAgentCodeIn = NULLIF(@pDebitAgentCodeIn, '');
        SET @pReqDeptCd = NULLIF(@pReqDeptCd, '');
        SET @pFollowUpDeptCd = NULLIF(@pFollowUpDeptCd, '');
        SET @pReqAgentCodeIn = NULLIF(@pReqAgentCodeIn, '');
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 999);
        SET @pPageNum = ISNULL(IIF(@pPageNum <=0 , NULL, @pPageNum), 1);
        SET @pSort = ISNULL(NULLIF(@pSort, ''), '||');
          
        IF @pDebitDt IS NOT NULL
        BEGIN
            SET @vFromDebitDt = CAST(@pDebitDt AS DATE);                                    
            SET @vToDebitDt = DATEADD(dd, 1, @vFromDebitDt);                                  
        END;

        IF @pBookingDt IS NOT NULL
        BEGIN
            SET @vFromBookingDt = CAST(@pBookingDt AS DATE);
            SET @vToBookingDt = DATEADD(dd, 1, @vFromBookingDt);
        END;
           
        WITH tResult AS (
            SELECT 
                br.RowID ,
                br.wBookingRid ,
                br.wRestaurantRid ,
                br.wNoOfPpl ,
                br.wCrtBy ,
                br.wCrtDt ,
                br.wUpdDt ,
                br.wUpdBy ,
                br.wBookingStatus ,
                br.wUnqualifiedRid ,
                br.wBookingDt ,
                eb.wDebitDt ,
                eb.wRefNo ,
                wDebitServiceCounter = eb.wDebitCounterRid ,
                eb.wReqDepartment ,
                wRequestedServiceCounterid = eb.wReqCounterRid ,
                daAgent.wAgentCodeIn ,
                daAgent.wAgentCode_Display ,
                wRestName = mrs.wName ,
                wDebitServiceCounterName = sc.wName ,
                wRequestedServiceCounter = scr.wName ,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END ,
                wReqAgentCode_Display = rqAgent.wAgentCode_Display ,
                wReqUserRidByCName = CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName ELSE rqusr.wCName END ,
                eb.wDeptFollwedCd ,
                wStaffFollwedRidByCName = CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName ELSE sfusr.wCName END,
                eb.wAsstBooker ,
                eb.wAssBookerTel ,
                br.wReserveName ,
                br.wReservePhoneNo ,
                br.wDiningArea ,
                br.wIsMinCharge ,
                br.wMinCharge ,
                br.wRemark ,
                wAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END ,
                wReqAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName ELSE rqAgent.wCName END ,
                wEventCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN mec.wEName ELSE mec.wCName END
                FROM dbo.eBookingRestaurant br
                INNER JOIN dbo.eBooking eb ON eb.RowID = br.wBookingRid
                INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
                LEFT JOIN dbo.mServiceCounter scr ON scr.RowID = eb.wReqCounterRid
                INNER JOIN RollsMary.dbo.mAgent daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                INNER JOIN RollsMary.dbo.mAgent rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
                LEFT JOIN dbo.mRestaurant mrs ON mrs.RowID = br.wRestaurantRid
                LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = br.wUpdBy
                LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = br.wCrtBy
                LEFT JOIN RollsMary.dbo.mUsr rqusr ON rqusr.RowID = eb.wReqUserRid
                LEFT JOIN RollsMary.dbo.mUsr sfusr ON sfusr.RowID = eb.wStaffFollwedRid
                LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
                LEFT JOIN @vData_DebitCounterRid v ON v.wCounterRid = eb.wDebitCounterRid
                LEFT JOIN @vData_BookingStatus vs ON vs.wBookingStatus = br.wBookingStatus
                WHERE ( @pRefNo IS NULL OR @pRefNo = eb.wRefNo )
                    AND ( @vFromDebitDt <= eb.wDebitDt AND @vToDebitDt > eb.wDebitDt )
                    AND ( @vDebitCounterRidCount <= 0 OR v.wCounterRid IS NOT NULL )
                    AND ( @pDebitAgentCodeIn IS NULL OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn )
                    AND ( @pReqDeptCd IS NULL OR @pReqDeptCd = eb.wReqDepartment )
                    AND ( @pFollowUpDeptCd IS NULL OR @pFollowUpDeptCd = eb.wDeptFollwedCd )
                    AND ( @vBookingStatusCount <= 0 OR vs.wBookingStatus IS NOT NULL )
                    AND ( @pReqAgentCodeIn IS NULL OR @pReqAgentCodeIn = eb.wReqAgentCodeIn )
                    AND ( @pFromDt <= br.wCrtDt AND @pToDt > br.wCrtDt )
                    AND ( @vFromBookingDt <= br.wBookingDt AND @vToBookingDt > br.wBookingDt )
            ),
            tCount AS (
                SELECT wRecordCount = COUNT(*) FROM tResult
            )
            
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wDebitDt END DESC ,
                     CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wRefNo END DESC
            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
            FETCH NEXT @pPageSize ROWS ONLY
            OPTION  ( RECOMPILE );
    END;