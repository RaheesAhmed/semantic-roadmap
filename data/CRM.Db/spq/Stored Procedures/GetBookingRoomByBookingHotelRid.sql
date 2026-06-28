
CREATE PROCEDURE [spq].[GetBookingRoomByBookingHotelRid]
    @pBookingHotelRid BIGINT ,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pBookingHotelRid = ISNULL(@pBookingHotelRid, 0);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));
		
		SELECT    
		    ROW_NUMBER() OVER ( ORDER BY br.RowID ) AS wSeqNo,
			br.RowID ,
            br.wBookingRid ,
			ISNULL(hr.wRequestNo, '') AS wRequestNo ,
			ISNULL(mh.wName, '') AS wHotelName ,
			ISNULL(mh.wIsBase, '') wIsBase ,
			br.wUseAgencyAllotment ,
			br.wOrderNo ,
			ISNULL(mhr.wName, '') AS wHotelRoomName ,
			br.wRoomNo ,
			br.wCurrCode ,
			br.wGetKeyPasscode ,
			br.wHasClientGetKey ,
			br.wStartDate ,
			br.wEndtDate ,
			br.wDayOfStay ,
			dbo.fnGetPersonNamesByRoomBookingID(br.RowID, @pLangCd) AS wClient ,
			br.wBookingStatus ,
			wUpdByCName= CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
			br.wUpdDt,
			br.wHotelRid,
			br.wSeqNo AS wBookingSeqNo  ,
			br.wTotalAmount ,
            eb.wRefNo ,
			eb.wAsstBooker 
		FROM dbo.eBookingRoom  br
		INNER JOIN dbo.eBookingHotel ebh ON ebh.RowID = br.wHotelBookingRid
		LEFT JOIN dbo.eBooking eb ON eb.RowID = br.wBookingRid
		LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = br.wUpdBy
		LEFT JOIN dbo.mHotel mh ON mh.RowID = br.wHotelRid
		LEFT JOIN dbo.mHotelRoom mhr ON mhr.RowID = br.wHotelRoomRid
		LEFT JOIN dbo.eHotelRequest hr ON hr.RowID = ebh.wRequestRid
		WHERE br.wStatus = 'A'
		    AND br.wHotelBookingRid = @pBookingHotelRid
    END;