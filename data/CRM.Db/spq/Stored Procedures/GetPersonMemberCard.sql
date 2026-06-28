CREATE PROCEDURE [spq].[GetPersonMemberCard] --'T',10000000010165
    (
      @pwStatus CHAR(1) ,
      @pPersonID BIGINT ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10) = 'en-GB'	
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY mp.RowID ) AS wSeqNo ,
                                mpm.RowID ,
                                mpm.wPersonRID ,
                                mp.wEName AS wPersonEName ,
                                mp.wCName AS wPersonCName ,
                                mpm.wCardType ,
                                mpm.wCardNo ,
                                mpm.wExpiryDate ,
                                mpm.wRemark ,
                                mpm.wStatus ,
                                lps.wTitle AS wStatusName ,
                                mpm.wCrtDt ,
                                mpm.wCrtBy ,
                                mpm.wUpdDt ,
                                mpm.wUpdBy ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     [CRM].[dbo].mPersonMemberCard mpm
                                INNER JOIN mPerson mp ON mp.RowID = mpm.wPersonRID
                                                         --AND mpm.wStatus = 'A'
                                INNER JOIN dbo.mLookUp lps ON lps.wCode = mpm.wStatus
                                                              AND lps.wLangCd = @pwLangCd
                                                              AND lps.wType = 'COMMON_STATUS'
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mpm.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mpm.wCrtBy
                       WHERE    ( @pwStatus = ''
                                  OR @pwStatus IS NULL
                                  OR @pwStatus = mpm.wStatus
                                )
                                AND ( @pPersonID = ''
                                      OR @pPersonID IS NULL
                                      OR @pPersonID = 0
                                      OR @pPersonID = mpm.wPersonRID
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