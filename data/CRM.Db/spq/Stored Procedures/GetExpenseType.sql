CREATE PROCEDURE [spq].[GetExpenseType]
    (
      @pwExpenseCategory NVARCHAR(30) ,
      @pwCode NVARCHAR(30) ,
      @pwName NVARCHAR(30) ,
      @pwStatus CHAR(2) ,
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
	
        WITH    tResult
                  AS ( SELECT   met.RowID ,
                                met.wCode ,
                                met.wName ,
                                met.wExpCat wExpenseCategory ,
                                met.wGiftType ,
                                met.wGiftSubtype ,
                                met.wSeqNo ,
                                met.wStatus ,
                                met.wCrtDt ,
                                met.wCrtBy ,
                                met.wUpdDt ,
                                met.wUpdBy ,
                                mdoc.wTitle AS wGiftTypeName ,
                                doc.wTitle AS wSubGiftTypeName ,
                                Edoc.wTitle AS wExpenseTypeName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     [CRM].[dbo].mExpenseType met
                                INNER JOIN dbo.mLookUp mdoc ON mdoc.wCode = met.wGiftType
                                                              AND mdoc.wType = 'GIFT_TYPE'
                                                              AND mdoc.wLangCd = @pwLangCd
                                INNER JOIN dbo.mLookUp doc ON doc.wCode = met.wGiftSubtype
                                                              AND doc.wType = 'GIFT_SUB_TYPE'
                                                              AND doc.wLangCd = @pwLangCd
                                INNER JOIN dbo.mLookUp Edoc ON Edoc.wCode = met.wExpCat
                                                              AND Edoc.wType = 'EXPENSE_CATEGORY'
                                                              AND Edoc.wLangCd = @pwLangCd
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = met.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = met.wCrtBy
                       WHERE    ( @pwExpenseCategory = ''
                                  OR @pwExpenseCategory IS NULL
                                  OR @pwExpenseCategory = met.wExpCat
                                )
                                AND ( @pwCode = ''
                                      OR @pwCode IS NULL
                                      OR @pwCode = met.wCode
                                    )
                                AND ( @pwName = ''
                                      OR @pwName IS NULL
                                      OR @pwName = met.wName
                                    )
                                AND ( @pwStatus = ''
                                      OR @pwStatus = '\0'
                                      OR @pwStatus IS NULL
                                      OR @pwStatus = met.wStatus
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