CREATE PROCEDURE [spq].[GetAccountRelationshipAnalysisLst]
    (
      @pAgentCodeIn VARCHAR(14) = '',
      @pAgentLevel INT = NULL ,
      @pUpLvlAgentCodeIn VARCHAR(14) = NULL,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
-- Test Case:
-- EXEC [spq].[GetAccountRelationshipAnalysisLst] '', 0, '', 100, 1	
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 
	
		WITH cteIsShareHolder AS (
			SELECT
				wAgentCodeIn
			FROM
				RollsMary.dbo.mAgentBal ab
			WHERE
				ab.wCapitalAmt > 0
			GROUP BY 
				wAgentCodeIn
		), 
        tResult
                  AS ( SELECT   a.wAgentCode_Display ,
                                a.wAgentCodeIn ,
                                a.wAgentCode_Old ,
								a.wCName,
                                a.wCreateDate ,
                                a.wAccountType ,
                                a.wAgentType ,
                                a.wCompNo ,
                                a.wUpLvlAgentCodeIn ,
								wUpLvlAgentCode_Display = aLv.wAgentCode_Display,
                                a.wStatus ,
                                a.wAgentLevel ,
                                wIsShareholder = CASE WHEN sh.wAgentCodeIn IS NULL THEN 'N' ELSE 'Y' END
						FROM
							RollsMary.dbo.mAgent a
						LEFT JOIN
							cteIsShareHolder sh ON a.wAgentCodeIn = sh.wAgentCodeIn
						LEFT JOIN
							RollsMary.dbo.mAgent aLv ON a.wUpLvlAgentCodeIn = aLv.wAgentCodeIn
                        WHERE     
							a.wStatus IN ('A','I') AND a.wAgentLevel >= 3 AND a.wType = 'AGENT'
						AND
							(ISNULL(@pAgentCodeIn, '') = '' OR a.wAgentCodeIn = @pAgentCodeIn)
						AND 
							(ISNULL(@pUpLvlAgentCodeIn, '') = '' OR a.wUpLvlAgentCodeIn = @pUpLvlAgentCodeIn)
						AND 
							(ISNULL(@pAgentLevel, 0) = 0 OR a.wAgentLevel = @pAgentLevel)
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY wStatus
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY
		  OPTION (RECOMPILE)
		  ;

    END;