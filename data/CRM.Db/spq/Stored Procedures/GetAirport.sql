CREATE PROCEDURE [spq].[GetAirport]
    (
      @pCode VARCHAR(10) ,
      @pCName NVARCHAR(50) ,
      @pEName VARCHAR(200) ,
      @pCity VARCHAR(10) ,
      @pStatus CHAR(1) ,
      @pLangCd VARCHAR(10) ,
      @pPageSize INT ,
      @pPageNum INT
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
        IF @@TRANCOUNT = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pCode = ISNULL(@pCode, '');
        SET @pCName = ISNULL(@pCName, '');
        SET @pEName = ISNULL(@pEName, '');
        SET @pCity = ISNULL(@pCity, '');
        SET @pStatus = ISNULL(@pStatus, ' ');
        SET @pLangCd = ISNULL(@pLangCd, '');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
	
	-- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   ma.RowID ,
                                ma.wCName ,
                                ma.wEName ,
                                ma.wCode ,
                                ma.wCity ,
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
                                ( CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                       ELSE crusr.wCName
                                  END ) AS wCreatedByCName
                       FROM     [dbo].[mAirport] ma
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ma.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ma.wCrtBy
                       WHERE    ( @pCName = ''
                                  OR ma.wCName LIKE '%' + @pCName + '%'
                                )
                                AND ( @pEName = ''
                                      OR @pEName = ma.wEName
                                    )
                                AND ( @pCode = ''
                                      OR @pCode = ma.wCode
                                    )
                                AND ( @pCity = ''
                                      OR @pCity = ma.wCity
                                    )
                                AND ( @pStatus = ' '
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
            ORDER BY tResult.wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;

    END;