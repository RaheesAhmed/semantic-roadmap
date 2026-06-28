CREATE PROCEDURE [spq].[GetAccountAnalysis]
    (
      @pwAgentCodeIn VARCHAR(14) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10)
    )
AS
    BEGIN    
        SET NOCOUNT ON;
	    
        WITH    tResult
                  AS ( SELECT   *
                       FROM     dbo.eAccountAnalysis
                       WHERE    wAgentCodeIn = @pwAgentCodeIn
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY tResult.RowID
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;