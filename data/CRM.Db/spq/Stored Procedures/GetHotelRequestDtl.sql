CREATE PROCEDURE [spq].[GetHotelRequestDtl]  --'AUHC','en-GB'
    (
      @pwHotelRequestID BIGINT = NULL ,
      @pwCodes NVARCHAR(MAX) ,
      @pwLangCd VARCHAR(10) = 'en-GB'
    )
AS
    BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from

	-- interfering with SELECT statements.

        SET NOCOUNT ON;

	

    -- Insert statements for procedure here

        WITH    tResult
                  AS ( SELECT   hrd.RowID ,
								mh.RowID AS wHotelRid,
                                hrd.wHotelCode ,
                                hrd.wCounterRid ,
                                mh.wName AS HotelName ,
                                wTotalProvideRoomQty AS AssignedQty ,
                                hrd.wSeqNo ,
                                CONVERT(BIT, 1) AS IsVisible,
								CONVERT(BIT, 1) AS isEnabledReject
                       FROM     mHotel mh
                                INNER JOIN eHotelRequestDtl hrd ON hrd.wHotelCode = mh.wCode
                                                              AND mh.wStatus = 'A'
                                INNER JOIN mLookUp lupr ON lupr.wCode = mh.wRegion
                                                           AND lupr.wType = 'REGION'
                                                           AND lupr.wLangCd = @pwLangCd
                                INNER JOIN mLookUp lupc ON lupc.wCode = mh.wCurrCode
                                                           AND lupc.wType = 'CURRENCY'
                                                           AND lupc.wLangCd = @pwLangCd
                       WHERE    ( ( mh.wCode IN (
                                    SELECT  *
                                    FROM    Split(@pwCodes, ',') ) )
                                  AND ( @pwHotelRequestID IS NULL
                                        OR hrd.wHotelRequestRid = @pwHotelRequestID
                                      )
								  --不管是否拒絕派房都返回要求酒店
                                  --AND ( hrd.wIsReject = 'N' )
                                )
			--AND
			--(	@pwLangCd = '' 
			--	OR  @pwLangCd IS NULL
			--	OR   @pwLangCd = mh.wLangCd
			--)
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY RowID;

    END;