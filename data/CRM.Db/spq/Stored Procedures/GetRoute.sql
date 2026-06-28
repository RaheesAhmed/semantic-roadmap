CREATE PROCEDURE [spq].[GetRoute]
    (
      @pwRouteFrom NVARCHAR(50) ,
      @pwRouteTo NVARCHAR(50) ,
      @pwVehicle NVARCHAR(5) ,
      @pwStatus VARCHAR(1) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10) = 'en-GB'
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
        IF ( @pwLangCd = ''
             OR @pwLangCd IS NULL
           )
            SET @pwLangCd = 'en-GB';
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   mr.RowID ,
                                mr.wRouteFrom wRouteFromCode ,
                                lpFrom.wTitle wRouteFrom ,
                                mr.wRouteTo wRouteToCode ,
                                CASE WHEN wIsTwoWay = 'Y'
                                     THEN lpFrom.wTitle + '<->' + lpTo.wTitle
                                     ELSE lpFrom.wTitle + '->' + lpTo.wTitle
                                END AS wRouteTitle ,
                                lpTo.wTitle wRouteTo ,
                                wIsTwoWay ,
                                mr.wVehicle ,
                                mr.wSeqNo ,
                                mr.wStatus ,
                                mr.wCrtDt ,
                                mr.wCrtBy ,
                                mr.wUpdDt ,
                                mr.wUpdBy ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     [CRM].[dbo].mRoute mr
                                LEFT JOIN mLookUp lpTo ON lpTo.wCode = mr.wRouteTo
                                                           AND lpTo.wLangCd = @pwLangCd
                                                           AND ( ( mr.wVehicle = 'FERRY'
                                                              AND lpTo.wType = 'FERRY_ROUTE_LOCATION'
                                                              )
                                                              OR ( mr.wVehicle = 'HELI'
                                                              AND lpTo.wType = 'HELICOPTER_ROUTE_LOCATION'
                                                              )
                                                              OR ( mr.wVehicle = 'PLANE'
                                                              AND lpTo.wType = ''
                                                              )
                                                              )
                                LEFT JOIN mLookUp lpFrom ON lpFrom.wCode = mr.wRouteFrom
                                                             AND lpFrom.wLangCd = @pwLangCd
                                                             AND ( ( mr.wVehicle = 'FERRY'
                                                              AND lpFrom.wType = 'FERRY_ROUTE_LOCATION'
                                                              )
                                                              OR ( mr.wVehicle = 'HELI'
                                                              AND lpFrom.wType = 'HELICOPTER_ROUTE_LOCATION'
                                                              )
                                                              OR ( mr.wVehicle = 'PLANE'
                                                              AND lpFrom.wType = ''
                                                              )
                                                              )
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mr.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mr.wCrtBy
                       WHERE    ( @pwRouteFrom = ''
                                  OR @pwRouteFrom IS NULL
                                  OR @pwRouteFrom = mr.wRouteFrom
                                )
                                AND ( @pwRouteTo = ''
                                      OR @pwRouteTo IS NULL
                                      OR @pwRouteTo = mr.wRouteTo
                                    )
                                AND ( @pwVehicle = ''
                                      OR @pwVehicle IS NULL
                                      OR @pwVehicle = mr.wVehicle
                                    )
                                AND ( @pwStatus = ''
                                      OR @pwStatus IS NULL
                                      OR @pwStatus = mr.wStatus
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
            ORDER BY wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;

    END;