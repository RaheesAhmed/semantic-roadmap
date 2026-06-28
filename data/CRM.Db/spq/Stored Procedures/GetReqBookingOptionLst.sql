CREATE PROC [spq].[GetReqBookingOptionLst]
    @pLangCd    VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        -------------------------------------------------------------
        --DECLARE @vResult TABLE (wValue XML);

        --SELECT * FROM @vResult;
        -------------------------------------------------------------
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        
        DECLARE @vXML       XML,
                @vResultXML XML;

        SET @vResultXML = N'<OptionLst />';

        -- Request Booking Status
        -------------------------------------------------------------
        SET @vXML = (
            SELECT wCode,
                   wTitle,
                   wSeqNo = ROW_NUMBER() OVER (ORDER BY wSeqNo),
                   wIsEnable = wCanSelect,
                   wFontColor = CASE wCode WHEN 'TP'    THEN '#4B8C00'
                                           WHEN 'P'     THEN '#F5A623'
                                           WHEN 'C'     THEN '#347BCC'
                                           WHEN 'RJ'    THEN '#D74153'
                                           WHEN 'CL'    THEN '#D74153'
                                           WHEN 'DL'    THEN '#D74153'
                                           ELSE '#000000' END,
                   wBgColor = ''
            FROM dbo.mLookUp WITH(NOLOCK)
            WHERE wStatus = 'A'
                AND wType = 'REQBOOKING_STATUS' 
                AND @pLangCd = wLangCd
            ORDER BY wSeqNo
            FOR XML RAW('BookingStatus'), ROOT('BookingStatusLst')
        );

        IF @vXML IS NOT NULL
            SET @vResultXML.modify('insert sql:variable("@vXML") into (OptionLst)[1]')
        -------------------------------------------------------------
        
        -- Request Booking Type
        --------------------------------------------------------------
        SET @vXML = (
            SELECT wCode,
                   wTitle,
                   wSeqNo = ROW_NUMBER() OVER (ORDER BY wSeqNo)
            FROM dbo.mLookUp WITH(NOLOCK)
            WHERE wStatus = 'A'
                AND wType = 'REQBOOKING_TYPE' 
                AND @pLangCd = wLangCd
            ORDER BY wSeqNo
            FOR XML RAW('BookingType'), ROOT('BookingTypeLst')
        );


        IF @vXML IS NOT NULL
            SET @vResultXML.modify('insert sql:variable("@vXML") into (OptionLst)[1]')
        -------------------------------------------------------------

        -- Request Booking Department
        -------------------------------------------------------------
        SET @vXML = (
            SELECT wCode,
                   wCode_CRM = wDeptCode_CRM,
                   wName = IIF(@pLangCd = 'en-GB', wEName, wCName),
                   wSeqNo = ROW_NUMBER() OVER (ORDER BY wSeqNo)
            FROM RollsMary.dbo.mDepartment WITH(NOLOCK)
            WHERE wActive = 'A' AND wUserLineGrp = ''
            ORDER BY wSeqNo
            FOR XML RAW('Department'), ROOT('DepartmentLst')
        );


        IF @vXML IS NOT NULL
            SET @vResultXML.modify('insert sql:variable("@vXML") into (OptionLst)[1]')
        -------------------------------------------------------------

        -- Hotel
        -------------------------------------------------------------
        SET @vXML = (
            SELECT  RowID,
                    wCode,
                    wName,
                    wEname,
                    wJname,
                    wThname,
                    wKname,
                    wRegion,
                    wCurrCode,
                    wIsEnable = IIF(wStatus = 'A', 'Y', 'N')
            FROM dbo.mHotel WITH(NOLOCK)
            WHERE wIsBase = '1'
            FOR XML RAW('Hotel'), ROOT('HotelLst')
        );

        IF @vXML IS NOT NULL
            SET @vResultXML.modify('insert sql:variable("@vXML") into (OptionLst)[1]')
        -------------------------------------------------------------

        SELECT wValue = @vResultXML;
    END