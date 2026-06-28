-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [spq].[GetShow]
	-- Add the parameters for the stored procedure here
    (
      @pwName NVARCHAR(50) ,
      @pwStatus VARCHAR(2) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10) = 'en-GB'
	)
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
        WITH    tResult
                  AS ( SELECT   ms.RowID ,
                                ms.wName ,
                                ms.wVenue ,
                                ms.wShowCatCode ,
                                ms.wStartDate ,
                                ms.wEndDate ,
                                ms.wContent ,
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
                                look.wTitle ,
                                ms.wPerformanceArea ,
                                ms.wSupplier ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     mShow AS ms
                                LEFT JOIN [CRM].dbo.[mLookUp] look ON look.wCode = ms.wVenue
                                                              AND look.wLangCd = @pwLangCd
                                                              AND wType = 'REGION'
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ms.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ms.wCrtBy
                       WHERE    ( @pwName = ''
                                  OR @pwName IS NULL
                                  OR @pwName = ms.wName
                                )
                                AND ( @pwStatus = ''
                                      OR @pwStatus IS NULL
                                      OR @pwStatus = ms.wStatus
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
            ORDER BY wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;

    END;