
CREATE PROCEDURE [spq].[GetExpenseType_Master]
    (
      @pwExpenseCategory VARCHAR(30) ,
      @pwCode NVARCHAR(30) ,
      @pwName NVARCHAR(50) ,
      @pwStatus CHAR(1) ,
      @pwLangCd VARCHAR(10) ,
      @pPageSize INT ,
      @pPageNum INT
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
        	   
        SET @pwExpenseCategory = ISNULL(@pwExpenseCategory, '');
        SET @pwCode = ISNULL(@pwCode, '');
        SET @pwName = ISNULL(@pwName, '');
        SET @pwStatus = ISNULL(@pwStatus, ' ');
        SET @pwLangCd = ISNULL(@pwLangCd, 'en-GB');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);

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
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     [CRM].[dbo].mExpenseType met
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = met.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = met.wCrtBy
                       WHERE    ( @pwExpenseCategory = ''
                                  OR @pwExpenseCategory = met.wExpCat
                                )
                                AND ( @pwCode = ''
                                      OR @pwCode = met.wCode
                                    )
                                AND ( @pwName = ''
                                      OR met.wName LIKE '%' + @pwName + '%'
                                    )
                                AND ( @pwStatus = ' '
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
            ORDER BY tResult.wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;
    END;