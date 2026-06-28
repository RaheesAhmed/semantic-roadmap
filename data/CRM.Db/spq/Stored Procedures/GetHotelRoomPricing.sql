CREATE PROCEDURE [spq].[GetHotelRoomPricing]
    (
      @pHotelRid BIGINT ,
      @pHotelRoomRid BIGINT ,
      @pIsSpecialDate CHAR(1) ,
      @pCurrCode VARCHAR(6) ,
      @pStartDate DATE ,
      @pEndDate DATE ,
      @pwStatus CHAR(1) ,
      @pCrtDt DATETIME2 ,
      @pSort AS VARCHAR(200) ,
      @pwLangCd VARCHAR(10) ,
      @pPageSize INT ,
      @pPageNum INT
    )
AS
    BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from

	-- interfering with SELECT statements.

        SET NOCOUNT ON;

        DECLARE @vFromCrtDt DATETIME2 = '0001-01-01' ,
            @vToCrtDt DATETIME2 = '9999-12-31';

        SET @pHotelRid = ISNULL(@pHotelRid, 0);
        SET @pHotelRoomRid = ISNULL(@pHotelRoomRid, 0);
        SET @pIsSpecialDate = ISNULL(@pIsSpecialDate, ' ');
        SET @pCurrCode = ISNULL(@pCurrCode, '');
        SET @pStartDate = ISNULL(@pStartDate, '0001-01-01');
        SET @pEndDate = ISNULL(@pEndDate, '0001-01-01');
        SET @pwStatus = ISNULL(@pwStatus, ' ');
        IF @pCrtDt IS NOT NULL
            BEGIN
                SET @vFromCrtDt = @pCrtDt;
                SET @vToCrtDt = DATEADD(SECOND, -1, DATEADD(dd, 1, @pCrtDt));
            END;
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pwLangCd = LOWER(ISNULL(@pwLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 20);
        SET @pPageNum = ISNULL(@pPageNum, 1);		  	   

    -- Insert statements for procedure here

        WITH    tResult
                  AS ( SELECT   mhrp.RowID ,
                                mhr.wHotelRid ,
                                mhrp.wHotelRoomRid ,
                                mh.wName wHotelName ,
                                mhr.wName AS wHotelRoomName ,
                                mhrp.wIsSpecialDate ,
                                mhrp.wStartDate AS wStartDt ,
                                mhrp.wEndDate AS wEndDt ,
                                mhrp.wCurrCode ,
                                mhrp.wSunRoomPrice ,
                                mhrp.wMonRoomPrice ,
                                mhrp.wTueRoomPrice ,
                                mhrp.wWedRoomPrice ,
                                mhrp.wThuRoomPrice ,
                                mhrp.wFriRoomPrice ,
                                mhrp.wSatRoomPrice ,
                                mhrp.wSunRoomCost ,
                                mhrp.wMonRoomCost ,
                                mhrp.wTueRoomCost ,
                                mhrp.wWedRoomCost ,
                                mhrp.wThuRoomCost ,
                                mhrp.wFriRoomCost ,
                                mhrp.wSatRoomCost ,
                                mhrp.wSunBreakfastPrice ,
                                mhrp.wMonBreakfastPrice ,
                                mhrp.wTueBreakfastPrice ,
                                mhrp.wWedBreakfastPrice ,
                                mhrp.wThuBreakfastPrice ,
                                mhrp.wFriBreakfastPrice ,
                                mhrp.wSatBreakfastPrice ,
                                mhrp.wSeqNo ,
                                mhrp.wCrtDt ,
                                mhrp.wCrtBy ,
                                mhrp.wUpdDt ,
                                mhrp.wUpdBy ,
                                mhrp.wStatus ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName,
                                mhrp.wMonExtraBedPrice,
                                mhrp.wTueExtraBedPrice,
                                mhrp.wWedExtraBedPrice,
                                mhrp.wThuExtraBedPrice,
                                mhrp.wFriExtraBedPrice,
                                mhrp.wSatExtraBedPrice,
                                mhrp.wSunExtraBedPrice
                       FROM     dbo.eHotelRoomPricing mhrp
                                INNER JOIN mHotelRoom mhr ON mhrp.wHotelRoomRid = mhr.RowID
                                                             AND mhr.wStatus = 'A'
                                INNER JOIN mHotel mh ON mh.RowID = mhr.wHotelRid
                                                        AND mh.wStatus = 'A'
                                INNER JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mhrp.wUpdBy
                                INNER JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mhrp.wCrtBy
                       WHERE    ( @pHotelRid = 0
                                  OR @pHotelRid = mhr.wHotelRid
                                )
                                AND ( @pHotelRoomRid = 0
                                      OR @pHotelRoomRid = mhrp.wHotelRoomRid
                                    )
                                AND ( @pIsSpecialDate = ' '
                                      OR @pIsSpecialDate = mhrp.wIsSpecialDate
                                    )
                                AND ( @pCurrCode = ''
                                      OR @pCurrCode = mhrp.wCurrCode
                                    )
                                AND ( @pStartDate = '0001-01-01'
                                      OR @pStartDate = mhrp.wStartDate
                                    )
                                AND ( @pEndDate = '0001-01-01'
                                      OR @pEndDate = mhrp.wEndDate
                                    )
                                AND ( @pwStatus = ' '
                                      OR @pwStatus = mhrp.wStatus
                                    )
                                AND ( @vFromCrtDt <= mhrp.wCrtDt
                                      AND @vToCrtDt >= mhrp.wCrtDt
                                    )
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wCrtDt
                     END DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS

		  FETCH NEXT @pPageSize ROWS ONLY;
    END;