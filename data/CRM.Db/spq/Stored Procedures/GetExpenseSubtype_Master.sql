
CREATE PROCEDURE [spq].[GetExpenseSubtype_Master]
    (
      @pwExpenseTypeId BIGINT ,
      @pwCode NVARCHAR(30) ,
      @pwName NVARCHAR(50) ,
      @pwStatus CHAR(1) ,
      @pSort VARCHAR(200) ,
      @pwLangCd VARCHAR(10) = 'en-GB' ,
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
            SET @pwLangCd = 'en-GB';	
    -- Insert statements for procedure here

        SET @pwExpenseTypeId = ISNULL(@pwExpenseTypeId, 0);
        SET @pwCode = ISNULL(@pwCode, '');
        SET @pwName = ISNULL(@pwName, '');
        SET @pwStatus = ISNULL(@pwStatus, ' ');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pwLangCd = ISNULL(@pwLangCd, 'en-gb');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
	
        WITH    tResult
                  AS ( SELECT   msccv.RowID ,
                                msccv.wCode ,
                                msccv.wName ,
                                msccv.wExpenseTypeId ,
                                met.wName wExpenseTypeName ,
                                msccv.wExpCat wExpCat ,
                                msccv.wGiftType wGiftType ,
                                msccv.wGiftSubtype wGiftSubtype ,
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
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = msccv.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = msccv.wCrtBy
                       WHERE    ( @pwExpenseTypeId = 0
                                  OR @pwExpenseTypeId = msccv.wExpenseTypeId
                                )
                                AND ( @pwCode = ''
                                      OR @pwCode = msccv.wCode
                                    )
                                AND ( @pwName = ''
                                      OR @pwName = msccv.wName
                                    )
                                AND ( @pwStatus = ' '
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
            ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wCrtDt
                     END DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;
    END;