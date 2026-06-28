CREATE PROCEDURE [spq].[GetBookingRestaurantByTravelPkgRid]
(
    @pTravelPkgRid BIGINT ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1 ,
    @pLangCd VARCHAR(10) = 'en-GB'
)
AS
    BEGIN
        SET NOCOUNT ON;  

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 
        
        SET @pTravelPkgRid = ISNULL(IIF(@pTravelPkgRid <= 0, NULL, @pTravelPkgRid), 0);
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'en-GB');
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 999);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);
   
        WITH tResult AS (
            SELECT
                br.RowID ,
                br.wBookingRid ,
                br.wRestaurantRid ,
                br.wNoOfPpl ,
                br.wBookingDt ,
                wBookingDateTime = FORMAT(br.wBookingDt, 'yyyy-MM-dd HH:mm:ss'), -- DateTime類型會有時區問題，此處轉成字符串，Client再轉成DateTime
                br.wDiningArea ,
                br.wRemark ,
                br.wCrtBy ,
                br.wCrtDt ,
                br.wUpdDt ,
                br.wUpdBy ,
                br.wBookingStatus ,
                br.wUnqualifiedRid ,
                eb.wDebitDt ,
                eb.wRefNo ,
                eb.wTravePkgRid ,
                wDebitServiceCounter = eb.wDebitCounterRid ,
                wRequestedDepartment = eb.wReqDepartment,
                wRequestedServiceCounterid = eb.wReqCounterRid,
                eb.wDebitAgentCodeIn wDebitAccount ,
                daAgent.wAgentCode_Display ,
                eb.wDebitCustomerRid wDebitClient ,
                wDebitClientName = '' ,
                eb.wDebitCounterRid ,
                wRestName = mrs.wName ,
                wDebitServiceCounterName = sc.wName ,
                wRequestedServiceCounter = scr.wName ,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END,
                wRequestedAccount = raAgent.wAgentCode_Display ,
                br.wReserveName ,
                br.wReservePhoneNo ,
                br.wIsMinCharge ,
                br.wMinCharge ,
                br.wAcceptBTM ,
                br.wAdditionalExp ,
                br.wTravelAgencyRid,
                br.wCurrCode
            FROM dbo.eBookingRestaurant br
            INNER JOIN dbo.eBooking eb ON eb.RowID = br.wBookingRid
            INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
            LEFT JOIN dbo.mServiceCounter scr ON scr.RowID = eb.wReqCounterRid
            INNER JOIN RollsMary.dbo.mAgent daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn                                
            LEFT JOIN RollsMary.dbo.mAgent raAgent ON raAgent.wAgentCodeIn = eb.wReqAgentCodeIn
            LEFT JOIN dbo.mRestaurant mrs ON mrs.RowID =br.wRestaurantRid
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID =br.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID =br.wCrtBy
            WHERE @pTravelPkgRid = eb.wTravePkgRid
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )
        
        SELECT
            tResult.* ,
            wRecordCount
        FROM tResult , tCount
        ORDER BY wUpdDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY;
    END;