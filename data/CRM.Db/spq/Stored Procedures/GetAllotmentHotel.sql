CREATE PROCEDURE [spq].[GetAllotmentHotel]
    (
      @pHotelRid BIGINT ,
      @pRoomRid BIGINT ,
      @pAllotmentGroupRid BIGINT ,
      @pCounterRidXML XML ,
      @pIsSpecialDate CHAR(1) ,
      @pStartDate DATETIME2 ,
      @pwStatus CHAR(1) ,
      @pSort VARCHAR(200) ,
      @pwLangCd VARCHAR(10) ,
      @pPageSize INT ,
      @pPageNum INT
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

        DECLARE @vFromStartDate AS DATETIME2 = '0001-01-01' ,
            @vToStartDate AS DATETIME2 = '9999-12-31' ,
            @vCounterRidCount AS INT;

        DECLARE @vData_CounterRid AS TABLE ( SelectionItem BIGINT );

        IF CAST(@pCounterRidXML AS NVARCHAR(MAX)) != N'<DataSet/>'
            BEGIN
                INSERT  INTO @vData_CounterRid
                        ( SelectionItem
                        )
                        SELECT  tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
                        FROM    @pCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );
            END;

        SET @vCounterRidCount = ( SELECT    COUNT(1)
                                  FROM      @vData_CounterRid
                                );

        SET @pHotelRid = ISNULL(@pHotelRid, 0);
        SET @pRoomRid = ISNULL(@pRoomRid, 0);
        SET @pAllotmentGroupRid = ISNULL(@pAllotmentGroupRid, 0);
        SET @pIsSpecialDate = ISNULL(@pIsSpecialDate, ' ');	  
        IF @pStartDate IS NOT NULL
            BEGIN
                SET @vFromStartDate = @pStartDate;
                SET @vToStartDate = DATEADD(dd, 1, @pStartDate);
            END;
        SET @pwStatus = ISNULL(@pwStatus, ' ');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pwLangCd = LOWER(ISNULL(@pwLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
	
    -- Insert statements for procedure here
	
        WITH    cteAllotmentGroupDtl
                  AS ( SELECT   mrad.wAllotmentGroupRid ,
                                mrad.wCounterRid ,
                                msc.wName
                       FROM     dbo.mAllotmentGroupDtl mrad
                                LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = mrad.wCounterRid
                     ),
                tResult
                  AS ( SELECT   DISTINCT
                                raq.RowID ,
						  mh.wCode wHotelCode ,
                                mh.wName wHotelName ,
                                mhr.wHotelRid ,
                                mhr.wName wRoomName ,
                                mra.wName wRoomAllotmentName ,--房間配額名稱
                                raq.wRoomRid ,
                                raq.wIsSpecialDate ,
                                raq.wStartDate AS wStartDt , -- Do not remove the alias which used for custom query
                                raq.wEndDate AS wEndDt , -- Do not remove the alias which used for custom query
                                raq.wStatus ,
                                raq.wSeqNo ,
                                raq.wCrtDt ,
                                raq.wCrtBy ,
                                raq.wUpdDt ,
                                raq.wUpdBy ,
                                wSunQty = ISNULL(mraqd.wSunQty, 0) ,
                                wMonQty = ISNULL(mraqd.wMonQty, 0) ,
                                wTueQty = ISNULL(mraqd.wTueQty, 0) ,
                                wWedQty = ISNULL(mraqd.wWedQty, 0) ,
                                wThuQty = ISNULL(mraqd.wThuQty, 0) ,
                                wFriQty = ISNULL(mraqd.wFriQty, 0) ,
                                wSatQty = ISNULL(mraqd.wSatQty, 0) ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                STUFF(( SELECT  ', ' + cagd.wName
                                        FROM    cteAllotmentGroupDtl cagd
                                        WHERE   cagd.wAllotmentGroupRid = agd.wAllotmentGroupRid
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, '') AS wCounterRidByName
                       FROM     dbo.eAllotmentHotel raq
                                INNER JOIN mHotelRoom mhr ON mhr.RowID = raq.wRoomRid
                                INNER JOIN mHotel mh ON mh.RowID = mhr.wHotelRid
                                LEFT JOIN dbo.eAllotmentHotelDtl mraqd ON raq.RowID = mraqd.wAllotmentHotelRid
                                LEFT JOIN dbo.mAllotmentGroup mra ON mra.RowID = mraqd.wAllotmentGroupRid--房間配額名稱
                                LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = raq.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = raq.wCrtBy
                                LEFT JOIN cteAllotmentGroupDtl agd ON agd.wAllotmentGroupRid = mra.RowID
                                LEFT JOIN @vData_CounterRid v ON agd.wCounterRid = v.SelectionItem
                       WHERE    ( @pHotelRid = 0
                                  OR @pHotelRid = mhr.wHotelRid
                                )
                                AND ( @pRoomRid = 0
                                      OR @pRoomRid = raq.wRoomRid
                                    )
                                AND ( @pAllotmentGroupRid = 0
                                      OR @pAllotmentGroupRid = mraqd.wAllotmentGroupRid
                                    )
                                AND ( @pIsSpecialDate = ' '
                                      OR @pIsSpecialDate = raq.wIsSpecialDate
                                    )
                                AND ( @vFromStartDate <= raq.wStartDate
                                      AND @vToStartDate >= raq.wStartDate
                                    )
                                AND ( @pwStatus = ' '
                                      OR @pwStatus = raq.wStatus
                                    )
                                AND ( @vCounterRidCount = 0
                                      OR v.SelectionItem IS NOT NULL
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