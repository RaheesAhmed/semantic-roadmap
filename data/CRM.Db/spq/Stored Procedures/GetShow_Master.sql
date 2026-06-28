
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [spq].[GetShow_Master]
	-- Add the parameters for the stored procedure here
    (
      @pName NVARCHAR(50) ,
      @pVenue NVARCHAR(50) ,
      @pStartDate DATE ,
      @pEndDate DATE ,
      @pIsFullDay CHAR(1) ,
      @pContent NVARCHAR(500) ,
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

        SET @pName = ISNULL(@pName, '');
        SET @pVenue = ISNULL(@pVenue, '');
        SET @pStartDate = ISNULL(@pStartDate, '0001-01-01');
        SET @pEndDate = ISNULL(@pEndDate, '0001-01-01');
        SET @pIsFullDay = ISNULL(@pIsFullDay, ' ');
        SET @pContent = ISNULL(@pContent, '');
        SET @pStatus = ISNULL(@pStatus, ' ');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');
	
        WITH    tResult
                  AS ( SELECT   ms.RowID ,
                                ms.wName AS wShowName ,
                                ms.wVenue ,
                                ms.wShowCatCode ,
                                ms.wStartDate AS wStartDt ,
                                ms.wEndDate AS wEndDt ,
                                ms.wContent AS wShowContent ,
                                ms.wCrtDt ,
                                ms.wUpdDt ,
                                ms.wCrtBy ,
                                ms.wUpdBy ,
                                ms.wPerformanceDt ,
                                ms.wSeqNo ,
                                ms.wStatus ,
                                ms.wIsExtraName ,
                                ms.wIsFullDay ,
                                ms.wHaveTicket ,
                                ms.wPerformanceArea ,
                                ms.wSupplier ,
                                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
                                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END,
                                wSupplierName = mta.wName
                       FROM     dbo.mShow AS ms
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ms.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ms.wCrtBy
                                LEFT JOIN dbo.mTravelAgency mta on mta.Rowid=ms.wSupplier
                       WHERE    ( @pName = ''
                                  OR ms.wName LIKE '%' + @pName + '%'
                                )
                                AND ( @pVenue = ''
                                      OR @pVenue = ms.wVenue
                                    )
                                AND ( @pStartDate = '0001-01-01'
                                      OR @pStartDate = ms.wStartDate
                                    )
                                AND ( @pEndDate = '0001-01-01'
                                      OR @pEndDate = ms.wEndDate
                                    )
                                AND ( @pIsFullDay = ' '
                                      OR @pIsFullDay = ms.wIsFullDay
                                    )
                                AND ( @pContent = ''
                                      OR @pContent = ms.wContent
                                    )
                                AND ( @pStatus = ' '
                                      OR @pStatus = ms.wStatus
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