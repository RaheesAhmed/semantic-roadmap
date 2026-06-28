CREATE PROCEDURE [spq].[GetAlterationOfShare]
    (
      @pwStatus CHAR(1) = '' ,
      @pwLangCd VARCHAR(10) = 'en-GB' ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   aos.RowID ,
                                aos.wDate ,
                                aos.wAgentCodeIn ,
                                aos.wRegionCode ,
                                aos.wReasonOfAlteration ,
                                aos.wActionCode ,
                                aos.wCurrCode ,
                                aos.wNumberOfSharesChanged ,
                                aos.wCurrentShares ,
                                aos.wStatus ,
                                aos.wCrtBy ,
                                aos.wUpdBy ,
                                aos.wUpdDt ,
                                aos.wHandler ,
                                lupr.wTitle AS wRegion ,
                                lups.wTitle AS wAction ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN ma.wEName
                                     ELSE ma.wCName
                                END AS wAgentName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName
                       FROM     dbo.eAlterationOfShare aos
                                LEFT JOIN mLookUp lupr ON lupr.wCode = aos.wRegionCode
                                                          AND lupr.wType = 'REGION'
                                                          AND lupr.wLangCd = @pwLangCd
                                INNER JOIN mLookUp lupc ON lupc.wCode = aos.wCurrCode
                                                           AND lupc.wType = 'CURRENCY'
                                                           AND lupc.wLangCd = @pwLangCd
                                LEFT JOIN mLookUp lups ON lups.wCode = aos.wActionCode
                                                          AND lups.wType = 'CHANGE_SHARE_ACTION'
                                                          AND lups.wLangCd = @pwLangCd
                                LEFT JOIN [RollsMary].[dbo].[mAgent] ma ON ma.wAgentCodeIn = aos.wAgentCodeIn
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = aos.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = aos.wCrtBy
                       WHERE    ( @pwStatus = ''
                                  OR @pwStatus IS NULL
                                  OR @pwStatus = aos.wStatus
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

	--select * from mLookUp lupc where  lupc.wType = 'CHANGE_SHARE_ACTION' AND lupcs.wLangCd = 'en-GB'