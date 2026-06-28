CREATE PROCEDURE [spq].[GetLookUp]
    (
      @pwType NVARCHAR(50) ,
      @pwCode NVARCHAR(30) ,
      @pwTitle NVARCHAR(50) ,
      @pwStatus CHAR ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10) = 'en-gb'
	 
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT 
		--ml.RowID,
                                ml.wType ,
                                ml.wCode ,
                                ml.wParentCode ,
                                ml.wLangCd ,
                                ml.wSeqNo ,
                                ml.wTitle ,
                                ml.wDescr ,
                                ml.wStatus ,
                                ml.wCanEdit ,
                                ml.wCanSelect ,
                                ml.wCrtBy ,
                                ml.wCrtDt ,
                                ml.wUpdBy ,
                                ml.wUpdDt ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     [CRM].[dbo].[mLookUp] ml
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ml.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ml.wCrtBy
                       WHERE    ( @pwCode = ''
                                  OR @pwCode IS NULL
                                  OR @pwCode = ml.wCode
                                )
                                AND ( @pwType = ''
                                      OR @pwType IS NULL
                                      OR @pwType = ml.wType
                                    )
                                AND ( @pwTitle = ''
                                      OR @pwTitle IS NULL
                                      OR @pwTitle = ml.wTitle
                                    )
                                AND ( @pwStatus = ''
                                      OR @pwStatus IS NULL
                                      OR @pwStatus = ml.wStatus
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