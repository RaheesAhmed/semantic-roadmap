
CREATE PROCEDURE [spq].[GetUpdateFerryHelicopterTicketsCost]
    (
      @pTicketType VARCHAR(10) ,
      @pStartDate DATETIME2 ,
      @pEndDate DATETIME2 ,
      @pRoute NVARCHAR(50) ,
      @pClassCd VARCHAR(5) ,
      @pStatus CHAR(1) ,
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

        SET @pTicketType = ISNULL(@pTicketType, '');
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
        SET @pRoute = ISNULL(@pRoute, '');
        SET @pClassCd = ISNULL(@pClassCd, '');
        SET @pStatus = ISNULL(@pStatus, ' ');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');

    -- Insert statements for procedure here
        WITH    cteRoute
                  AS ( SELECT   mr.RowID ,
                                mr.wRouteFrom ,
                                mr.wRouteTo ,
                                mr.wIsTwoWay ,
                                mr.wSeqNo
                       FROM     dbo.mRoute mr
                                LEFT JOIN dbo.mLookUp lurf ON lurf.wType = 'FERRY_ROUTE_LOCATION'
                                                              AND lurf.wCode = mr.wRouteFrom
												  AND lurf.wLangCd = @pLangCd
                                LEFT JOIN dbo.mLookUp lurt ON lurt.wType = 'FERRY_ROUTE_LOCATION'
                                                              AND lurt.wCode = mr.wRouteTo
												  AND lurt.wLangCd = @pLangCd
                       WHERE    ( @pRoute = ''
                                  OR mr.wRouteFrom LIKE '%' + @pRoute + '%'
                                  OR mr.wRouteTo LIKE '%' + @pRoute + '%'
                                  OR lurf.wTitle LIKE '%' + @pRoute + '%'
                                  OR lurt.wTitle LIKE '%' + @pRoute + '%'
                                )
                     ),
                tResult
                  AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY tc.RowID ) AS wSeqNo ,
                                tc.RowID ,
                                tc.wRouteID ,
                                tc.wVehicleType ,
                                tc.wStartDate ,
                                tc.wEndDate ,
                                tc.wTicketType wTicType ,
                                tc.wClassCd wFerryClass ,
                                tc.wSellingAmt ,
                                tc.wRate ,
                                tc.wTax ,
                                tc.wPrice ,
								tc.wRebatePrice,
                                tc.wCrtDt ,
                                tc.wCrtBy ,
                                tc.wUpdDt ,
                                tc.wUpdBy ,
                                tc.wStatus ,
                                tc.wCurrCode ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                r.wRouteFrom ,
                                r.wRouteTo ,
                                r.wIsTwoWay ,
                                '' wRoute , -- Used to return a route name in WPF
                                r.wSeqNo AS wRouteSeqNo,
                                tc.wCalculateCostWay
                       FROM     [CRM].[dbo].eUpdateFerryAndHeliCost tc
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = tc.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = tc.wCrtBy
                                LEFT JOIN cteRoute r ON r.RowID = tc.wRouteID --inner
                       WHERE    ( @pTicketType = ''
                                  OR @pTicketType = tc.wTicketType
                                )
                                AND ( @vFromStartDate <= tc.wStartDate
                                      AND @vToStartDate >= tc.wStartDate
                                    )
                                AND ( @vFromEndDate <= tc.wEndDate
                                      AND @vToEndDate >= tc.wEndDate
                                    )
                                AND ( @pClassCd = ''
                                      OR @pClassCd = tc.wClassCd
                                    )
                                AND ( @pRoute = ''
                                      OR r.RowID IS NOT NULL
                                    )
                                AND ( @pStatus = ' '
                                      OR @pStatus = tc.wStatus
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
            ORDER BY tResult.wRouteFrom ,
                    tResult.wRouteTo ,
                    tResult.wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;
    END;