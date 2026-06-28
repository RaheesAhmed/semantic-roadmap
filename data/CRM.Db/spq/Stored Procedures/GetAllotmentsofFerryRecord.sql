CREATE PROCEDURE [spq].[GetAllotmentsofFerryRecord]
    (
      @pRouteRid BIGINT ,
      @pTicketType VARCHAR(30) ,
      @pStatus VARCHAR(30) ,
      @pIsVisibleCnt BIT ,
      @pCounterRidXML XML ,
      @pTicketNo NVARCHAR(30) ,
      @pInitialsTkt NVARCHAR(20) ,
      @pSort AS VARCHAR(200) ,
      @pLangCd VARCHAR(10) ,
      @pPageSize INT ,
      @pPageNum INT
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;	
    -- Insert statements for procedure here

        DECLARE @vCounterRidCount AS INT;

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

        SET @pRouteRid = ISNULL(@pRouteRid, 0);
        SET @pTicketType = ISNULL(@pTicketType, '');
        SET @pStatus = ISNULL(@pStatus, '');
        SET @pIsVisibleCnt = ISNULL(@pIsVisibleCnt, 0);
        SET @pTicketNo = ISNULL(@pTicketNo, '');
        SET @pInitialsTkt = ISNULL(@pInitialsTkt, '');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);

        WITH    tResult
                  AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY afr.RowID ) AS wSeqNo ,
                                afr.RowID ,
                                afr.wTicketNo AS wAllotmentTicketNo ,
                                mcc.wName AS wCounterCName ,
                                afr.wStatus ,
                                afr.wExpiryDate wValidDate ,
                                afr.wTicketType wTicketTypeCode ,
                                afr.wRouteRid ,
                                afr.wClassCd wFerryClassCode ,
                                afr.wAmount ,
                                afr.wAllotmentStatus wAllotmentStatusCode ,
                                afr.wRemark ,
                                afr.wCurrCode ,
                                afr.wCrtDt ,
                                afr.wCrtBy ,
                                afr.wUpdDt ,
                                afr.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                r.wRouteFrom ,
                                r.wRouteTo ,
                                r.wIsTwoWay ,
                                '' AS wRoute ,
                                CAST(0 AS BIT) AS wIsSelected ,
                                eb.wRefNo ,
                                afr.wBookingRid,
                                afr.wInitialsTkt,
                                afr.wTicketNum
                       FROM     [CRM].[dbo].[eAllotmentTicket] afr
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = afr.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = afr.wCrtBy
                                LEFT JOIN dbo.mRoute r ON r.RowID = afr.wRouteRid
                                LEFT JOIN dbo.eBooking eb ON eb.RowID = afr.wBookingRid
                                LEFT JOIN dbo.mServiceCounter mcc ON mcc.RowID = afr.wCounterRid
                                LEFT JOIN @vData_CounterRid v ON afr.wCounterRid = v.SelectionItem
                       WHERE    ( ( @pIsVisibleCnt = 1
                                    AND afr.wAllotmentStatus NOT IN ( 'T', 'C', 'U' )
                                  )
                                  OR ( @pIsVisibleCnt = 0
                                       AND ( @pStatus = ''
                                             OR @pStatus = afr.wAllotmentStatus
                                           )
                                     )
                                )
                                AND ( @pTicketNo = ''
                                      OR @pTicketNo = afr.wTicketNo
                                    )
                                AND ( @vCounterRidCount = 0
                                      OR v.SelectionItem IS NOT NULL
                                    )
                                AND ( @pInitialsTkt = ''
                                      OR @pInitialsTkt = afr.wInitialsTkt
                                    )
                                AND ( @pTicketType = ''
                                      OR @pTicketType = afr.wTicketType
                                     )
                                AND ( @pRouteRid = 0
                                      OR @pRouteRid = afr.wRouteRid
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
            ORDER BY  wInitialsTkt, wTicketNum DESC -- 舊數據需要Update一下：UPDATE dbo.eAllotmentTicket SET wTicketNum = CAST(REPLACE(wTicketNo, ISNULL(wInitialsTkt, ''), '') AS INT)
            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
            FETCH NEXT @pPageSize ROWS ONLY;
    END;