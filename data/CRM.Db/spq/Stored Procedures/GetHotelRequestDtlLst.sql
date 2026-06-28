CREATE PROCEDURE [spq].[GetHotelRequestDtlLst]
(
    @pHotelRequestRids NVARCHAR(MAX) ,
    @pLangCd VARCHAR(10) = 'en-GB'
)
AS
    BEGIN
        SET NOCOUNT ON;

		SET @pHotelRequestRids = ISNULL(@pHotelRequestRids, '');
		SET @pLangCd = ISNULL(@pLangCd, 'en-GB');

        WITH 
			tResult AS ( 
				SELECT 
					hrd.RowID ,
					hrd.wHotelRequestRid,
					mh.RowID AS wHotelRid,
					hrd.wHotelCode ,
					hrd.wCounterRid AS wServiceCounter,
					mh.wName AS HotelName ,
					wTotalProvideRoomQty AS AssignedQty ,
					hrd.wSeqNo
				FROM mHotel mh
				INNER JOIN eHotelRequestDtl hrd ON hrd.wHotelCode = mh.wCode
												AND mh.wStatus = 'A'
				INNER JOIN mLookUp lupr ON lupr.wCode = mh.wRegion
											AND lupr.wType = 'REGION'
											AND lupr.wLangCd = @pLangCd
				INNER JOIN mLookUp lupc ON lupc.wCode = mh.wCurrCode
											AND lupc.wType = 'CURRENCY'
											AND lupc.wLangCd = @pLangCd
				WHERE  CAST(hrd.wHotelRequestRid AS VARCHAR) IN (SELECT * FROM dbo.Split(@pHotelRequestRids, ','))),

			tCount AS ( 
				SELECT 
					COUNT(*) AS wRecordCount
				FROM     tResult
				   )

			SELECT  tResult.* ,
					wRecordCount
			FROM    tResult ,
					tCount
			ORDER BY RowID;
    END;