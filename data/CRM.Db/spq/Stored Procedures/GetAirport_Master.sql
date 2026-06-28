
CREATE PROCEDURE [spq].[GetAirport_Master]
    (
      @pName NVARCHAR(200) ,
      @pCode VARCHAR(10) ,
      @pCity VARCHAR(10) ,
      @pStatus VARCHAR(2) ,
      @pLangCd VARCHAR(10) = 'en-gb' ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
        IF @@TRANCOUNT = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	
	-- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   ma.RowID ,
                                ma.wCName ,
                                ma.wEName ,
                                ma.wCode ,
                                ma.wCity AS wCityCode ,
                                lup.wTitle AS wCity ,
                                ma.wRemark ,
                                ma.wSeqNo ,
                                ma.wStatus ,
                                ma.wCrtDt ,
                                ma.wCrtBy ,
                                ma.wUpdDt ,
                                ma.wUpdBy ,
                                ( CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                       ELSE usr.wCName
                                  END ) AS wUpdByCName ,
                                ( CASE WHEN @pLangCd = 'en-gb'
                                       THEN crusr.wName
                                       ELSE crusr.wCName
                                  END ) AS wCreatedByCName
                       FROM     [dbo].[mAirport] ma
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ma.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ma.wCrtBy
                                INNER JOIN dbo.mLookUp lup ON lup.wCode = ma.wCity
                                                              AND lup.wType = 'CITY'
                                                              AND lup.wLangCd = @pLangCd
                       WHERE    ( ISNULL(@pName, '') = ''
                                  OR @pName = ma.wCName
                                  OR @pName = ma.wEName
                                )
                                AND ( ISNULL(@pCode, '') = ''
                                      OR @pCode = ma.wCode
                                    )
                                AND ( ISNULL(@pCity, '') = ''
                                      OR @pCity = ma.wCity
                                    )
                                AND ( ISNULL(@pStatus, '') = ''
                                      OR @pStatus = ma.wStatus
                                    )
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(1)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;

    END;