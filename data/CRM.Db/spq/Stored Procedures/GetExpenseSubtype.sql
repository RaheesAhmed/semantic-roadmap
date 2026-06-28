CREATE PROCEDURE [spq].[GetExpenseSubtype]
    (
      @pwExpenseTypeId VARCHAR(50) ,
      @pwCode VARCHAR(30) ,
      @pwName NVARCHAR(50) ,
      @pwStatus VARCHAR(1) ,
      @pwLangCd VARCHAR(10) = 'zh-tw' ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1  
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
        IF ( @pwLangCd = ''
             OR @pwLangCd IS NULL
           )
            SET @pwLangCd = 'zh-tw';	
    -- Insert statements for procedure here
	
        WITH    tResult
                  AS ( SELECT   msccv.RowID ,
                                msccv.wCode ,
                                msccv.wName ,
                                msccv.wExpenseTypeId ,
                                met.wName wExpenseTypeName ,
                                msccv.wExpCat wExpCatCode ,
                                lupec.wTitle wExpCat ,
                                msccv.wGiftType wGiftTypeCode ,
                                lupgt.wTitle wGiftType ,
                                msccv.wGiftSubtype wGiftSubtypeCode ,
                                lupgst.wTitle wGiftSubtype ,
                                msccv.wStatus ,
                                msccv.wSeqNo ,
                                msccv.wCrtDt ,
                                msccv.wCrtBy ,
                                msccv.wUpdDt ,
                                msccv.wUpdBy ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     [CRM].[dbo].mExpenseSubtype msccv
                                INNER JOIN dbo.mExpenseType met ON met.RowID = msccv.wExpenseTypeId
                                INNER JOIN dbo.mLookUp lupec ON msccv.wExpCat = lupec.wCode
                                                              AND lupec.wType = 'EXPENSE_CATEGORY'
                                                              AND lupec.wLangCd = @pwLangCd
                                INNER JOIN dbo.mLookUp lupgt ON msccv.wGiftType = lupgt.wCode
                                                              AND lupgt.wType = 'GIFT_TYPE'
                                                              AND lupgt.wLangCd = @pwLangCd
                                INNER JOIN dbo.mLookUp lupgst ON msccv.wGiftSubtype = lupgst.wCode
                                                              AND lupgst.wType = 'GIFT_SUB_TYPE'
                                                              AND lupgst.wLangCd = @pwLangCd
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = msccv.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = msccv.wCrtBy
                       WHERE    ( @pwExpenseTypeId = ''
                                  OR @pwExpenseTypeId IS NULL
                                  OR @pwExpenseTypeId = '0'
                                  OR @pwExpenseTypeId = msccv.wExpenseTypeId
                                )
                                AND ( @pwCode = ''
                                      OR @pwCode IS NULL
                                      OR @pwCode = msccv.wCode
                                    )
                                AND ( @pwName = ''
                                      OR @pwName IS NULL
                                      OR @pwName = msccv.wName
                                    )
                                AND ( @pwStatus = ''
                                      OR @pwStatus IS NULL
                                      OR @pwStatus = msccv.wStatus
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