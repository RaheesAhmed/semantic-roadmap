CREATE PROCEDURE [spq].[GetTicketPricing]
    (
      @pStartDate DATETIME2 ,
      @pEndDate DATETIME2 ,
      @pIsSpecialPeriod CHAR(1) ,
      @pRouteId BIGINT ,
      @pTicketType VARCHAR(10) ,
      @pClassCd VARCHAR(30) ,
      @pVehicleType VARCHAR(5) ,
      @pStatus CHAR(1) ,
	 @pSort VARCHAR(200) ,
      @pPageSize INT ,
      @pPageNum INT ,
      @pLangCd VARCHAR(10)
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;		

        DECLARE @vFromStartDate DATETIME2 = '0001-01-01' ,
            @vToStartDate DATETIME2 = '9999-12-31' ,
            @vFromEndDate DATETIME2 = '0001-01-01' ,
            @vToEndDate DATETIME2 = '9999-12-31';

        IF @pStartDate IS NOT NULL
            BEGIN
                SET @vFromStartDate = @pStartDate;
                SET @vToStartDate = DATEADD(dd, 1, @pStartDate);
            END;

        IF @pEndDate IS NOT NULL
            BEGIN
                SET @vFromEndDate = @pEndDate;
                SET @vToEndDate = DATEADD(dd, 1, @pEndDate);
            END;

        SET @pIsSpecialPeriod = ISNULL(@pIsSpecialPeriod, ' ');
        SET @pRouteId = ISNULL(@pRouteId, 0);
        SET @pTicketType = ISNULL(@pTicketType, '');
        SET @pClassCd = ISNULL(@pClassCd, '');
        SET @pStatus = ISNULL(@pStatus, ' ');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pVehicleType = ISNULL(@pVehicleType, '');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY tp.RowID ) AS wSeqNo ,
                                tp.RowID ,
                                tp.wRouteId ,
                                tp.wTicketType ,
                                tp.wClassCd ,
                                tp.wIsSpecialPeriod ,
                                tp.wCurrCode ,
                                tp.wAmount ,
                                tp.wCost ,
                                tp.wHandlingFee ,
                                tp.wStartDate AS wStartDt , -- Don't remove the alias which is used for custom query
                                tp.wEndDate AS wEndDt , -- Don't remove the alias which is used for custom query
                                tp.wStatus ,
                                tp.wCharteredAmount ,
                                tp.wCharteredCost ,
                                tp.wCharteredHandlingFee ,
                                tp.wCrtDt ,
                                tp.wCrtBy ,
                                tp.wUpdDt ,
                                tp.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                r.wRouteFrom ,
                                r.wRouteTo ,
                                r.wIsTwoWay ,
                                '' wRoute -- Used to return a route name in WPF
                       FROM     [CRM].[dbo].eTicketPricing tp
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = tp.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = tp.wCrtBy
                                INNER JOIN dbo.mRoute r ON r.RowID = tp.wRouteId
                       WHERE    ( @vFromStartDate <= tp.wStartDate
                                  AND @vToStartDate >= tp.wStartDate
                                )
                                AND ( @vFromEndDate <= tp.wEndDate
                                      AND @vToEndDate >= tp.wEndDate
                                    )
                                AND ( @pIsSpecialPeriod = ' '
                                      OR @pIsSpecialPeriod = tp.wIsSpecialPeriod
                                    )
                                AND ( @pRouteId = 0
                                      OR @pRouteId = tp.wRouteId
                                    )
                                AND ( @pTicketType = ''
                                      OR @pTicketType = tp.wTicketType
                                    )
                                AND ( @pClassCd = ''
                                      OR @pClassCd = tp.wClassCd
                                    )
                                AND ( @pVehicleType = ''
                                      OR @pVehicleType = tp.wVehicleType
                                    )
                                AND ( @pStatus = ' '
                                      OR @pStatus = tp.wStatus
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