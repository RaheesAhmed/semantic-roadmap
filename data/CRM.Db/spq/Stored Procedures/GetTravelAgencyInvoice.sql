CREATE PROCEDURE [spq].[GetTravelAgencyInvoice]--'1000033257','','',-1,''
(
    @pAgentCodeIn VARCHAR(14) ,
    @pStatus CHAR(1) ,
    @pHotelRid BIGINT = -1 ,
    @pTravelAgencyInvoiceRefNo NVARCHAR(20) = '' ,
    @pHotelBookingRid BIGINT = NULL ,
    @pTravelAgencyInvoiceRid BIGINT = NULL ,
    @pStartDateFrom DATETIME2 = NULL ,
    @pEndDateFrom DATETIME2 = NULL ,
    @pLangCd VARCHAR(10) = 'en-GB' ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
)
AS
    BEGIN  
        -- SET NOCOUNT ON added to prevent extra result sets from  
        -- interfering with SELECT statements.  
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;       
        
        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pStatus = NULLIF(@pStatus, '');
        SET @pHotelRid = IIF(@pHotelRid <= 0, NULL, @pHotelRid);
        SET @pTravelAgencyInvoiceRefNo = NULLIF(@pTravelAgencyInvoiceRefNo, '');
        SET @pHotelBookingRid = IIF(@pHotelBookingRid <= 0, NULL, @pHotelBookingRid);
        SET @pTravelAgencyInvoiceRid = IIF(@pTravelAgencyInvoiceRid <= 0, NULL, @pTravelAgencyInvoiceRid);
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'en-GB');
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 999);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);

        WITH tResult AS (
            SELECT
                ta.RowID ,
                ta.wHotelBookingRid ,
                ta.wInvoiceNo ,
                ta.wTravelAgencyRid ,
                ta.wHotelRid ,
                ta.wStartDate ,
                ta.wEndDate ,
                ta.wDayOfStay ,
                ta.wNumberOfRoom ,
                ta.wRemark ,
                ta.wBedType ,
                ta.wPersonName ,
                ta.wAgentCode ,
                ta.wStatus ,
                ta.wCrtBy ,
                ta.wCrtDt ,
                ta.wUpdDt ,
                ta.wUpdBy ,
                bh.wBookingRid ,
                bh.wQuantity,
                bh.wRegion,
                eb.wRefNo ,
                ma.wAgentCode_Display ,
                wHotelName = h.wName ,
                wHotelRequestRid = bh.wRequestRid,
                wTravelAgencyName = mta.wName ,
                wUpdByName = IIF( @pLangCd = 'en-GB', usr.wName, usr.wCName) ,
                wCrtByName = IIF( @pLangCd = 'en-GB', crusr.wName, crusr.wCName) ,
                ma.wAgentCodeIn
            FROM dbo.eTravelAgencyInvoice ta
            INNER JOIN dbo.eBookingHotel bh ON bh.RowID = ta.wHotelBookingRid
            INNER JOIN dbo.eBooking eb ON eb.RowID = bh.wBookingRid
            INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = ta.wAgentCode
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = ta.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = ta.wCrtBy
            LEFT JOIN dbo.eHotelRequest hr ON hr.RowID = bh.wRequestRid
            LEFT JOIN dbo.mHotel h ON h.RowID = ta.wHotelRid
            LEFT JOIN dbo.mTravelAgency mta ON mta.RowID = ta.wTravelAgencyRid
            WHERE ( @pStatus IS NULL OR @pStatus = ta.wStatus )
                AND ( @pTravelAgencyInvoiceRid IS NULL OR @pTravelAgencyInvoiceRid = ta.RowID )
                AND ( @pHotelBookingRid IS NULL OR @pHotelBookingRid = ta.wHotelBookingRid )
                AND ( @pAgentCodeIn IS NULL OR @pAgentCodeIn = ta.wAgentCode )
                AND ( @pHotelRid IS NULL OR @pHotelRid = ta.wHotelRid )
                AND ( @pTravelAgencyInvoiceRefNo IS NULL OR @pTravelAgencyInvoiceRefNo = ta.wInvoiceNo )
                AND ( @pStartDateFrom IS NULL OR ta.wStartDate >= @pStartDateFrom )
                AND ( @pEndDateFrom IS NULL OR ta.wEndDate >= @pEndDateFrom )
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT
            tResult.* ,
            wRecordCount
        FROM tResult , tCount
        ORDER BY wCrtDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION ( RECOMPILE );  
    END;