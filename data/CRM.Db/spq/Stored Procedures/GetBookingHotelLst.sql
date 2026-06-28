CREATE PROCEDURE [spq].[GetBookingHotelLst]
    @pRefNo VARCHAR(30) ,
    @pRegion VARCHAR(3) ,
    @pDebitCounterRidXML XML ,
    @pDebitAgentCodeIn VARCHAR(14) ,
    @pFromStartDate DATETIME2 ,
    @pToStartDate DATETIME2 ,
    @pFromEndDate DATETIME2 ,
    @pToEndDate DATETIME2 ,
    @pBookingStatus VARCHAR(5) ,
    @pSort VARCHAR(200) ,
    @pPageSize INT ,
    @pPageNum INT ,
    @pLangCd VARCHAR(20)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;  

        DECLARE @vDebitCounterRidCount AS INT;

        DECLARE @vData_DebitCounterRid AS TABLE ( SelectionItem BIGINT );

        IF CAST(@pDebitCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
        BEGIN
            INSERT  INTO @vData_DebitCounterRid ( SelectionItem )
            SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
            FROM    @pDebitCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );
        END;

        SET @vDebitCounterRidCount = ( SELECT   COUNT(1) FROM @vData_DebitCounterRid );
        SET @pRefNo = NULLIF(@pRefNo, '');
        SET @pRegion = NULLIF(@pRegion, '');
        SET @pBookingStatus = NULLIF(@pBookingStatus, '');
        SET @pDebitAgentCodeIn = NULLIF(@pDebitAgentCodeIn, '');
        SET @pFromStartDate = ISNULL(@pFromStartDate, '0001-01-01');
        SET @pToStartDate = ISNULL(@pToStartDate, '9999-12-31');
        SET @pFromEndDate = ISNULL(@pFromEndDate, '0001-01-01');
        SET @pToEndDate = ISNULL(@pToEndDate, '9999-12-31');
        SET @pSort = ISNULL(NULLIF(@pSort, ''), '||');
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);

        WITH tResult AS ( 
            SELECT  ebh.wBookingStatus ,
                    eb.wBookingType ,
                    eb.wRefNo ,
                    eb.wReqDepartment ,
                    wBookingHotelRid = ebh.RowID, -- eBookingHotel.RowID
                    ebh.wBookingRid,  -- eBooking.RowID
                    ebh.wQuantity ,
                    ebh.wRoomInProgress ,
                    ebh.wRoomCompleted ,
                    ebh.wRoomNotArrange ,
                    ebh.wRoomCancelled ,
                    ebh.wRegion ,
                    ebh.wIsAgentHotel ,
                    ebh.wStartDate ,
                    ebh.wEndDate ,
                    ebh.wDayOfStay ,
                    ebh.wBedType ,
                    ebh.wPaymentMethod ,
                    ebh.wReceiptNo ,
                    ebh.wRemark ,
                    ebh.wCrtDt ,
                    ebh.wCrtBy ,
                    ebh.wUpdDt ,
                    ebh.wUpdBy ,
                    ebh.wCounterRid ,
                    hr.wRequestNo ,
                    wHotelRequestRid = hr.RowID ,
                    wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
                    wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END  ,
                    daAgent.wAgentCodeIn ,
                    daAgent.wAgentCode_Display ,
                    wDebitClientName = '' ,
                    wDebitServiceCounterName = sc.wName ,
                    wAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END ,
                    wReqAgentCode_Display = rqAgent.wAgentCode_Display ,
                    wReqAgentCodeByName = CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName ELSE rqAgent.wCName END
            FROM dbo.eBooking eb
            INNER JOIN dbo.eBookingHotel ebh ON ebh.wBookingRid = eb.RowID
            INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
            INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
            LEFT JOIN dbo.eHotelRequest hr ON hr.RowID = ebh.wRequestRid
            LEFT JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
            LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ebh.wUpdBy
            LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ebh.wCrtBy
            LEFT JOIN @vData_DebitCounterRid v ON v.SelectionItem = eb.wDebitCounterRid
            WHERE ( @pRefNo IS NULL OR @pRefNo = eb.wRefNo )
                AND (@pBookingStatus IS NULL OR ebh.wBookingStatus = @pBookingStatus)
                AND ( @pRegion IS NULL OR @pRegion = ebh.wRegion )
                AND ( @vDebitCounterRidCount <= 0 OR v.SelectionItem IS NOT NULL )
                AND ( @pDebitAgentCodeIn IS NULL OR @pDebitAgentCodeIn = eb.wDebitAgentCodeIn )
                AND ( @pFromStartDate <= ebh.wStartDate AND @pToStartDate >= ebh.wEndDate )
                AND ( @pFromEndDate <= ebh.wEndDate AND @pToEndDate >= ebh.wEndDate )
        ),
        tCount AS ( 
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT  tResult.* ,
                wRecordCount
        FROM tResult , tCount
        ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wCrtDt END DESC ,
        CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wRefNo END DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY 
        OPTION(RECOMPILE);
    END;