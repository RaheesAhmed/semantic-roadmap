CREATE PROCEDURE [spq].[GetComplaintLst]
    (
      @pRefNo VARCHAR(30) ,
      @pDateFrom DATETIME2 ,
      @pDateTo DATETIME2 ,
      @pAgentCodeIn VARCHAR(14) ,
      @pComplainCompNo VARCHAR(30) ,
      @pComplainDeptCd VARCHAR(30) ,
      @pComplaintStatus VARCHAR(30) ,
      @pStatus CHAR(1) ,
      @pLangCd VARCHAR(30) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN
        SET NOCOUNT ON;
        IF @@TRANCOUNT = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pDateFrom = ISNULL(@pDateFrom, '0001-01-01');
        SET @pDateTo = ISNULL(@pDateTo, '9999-12-31');

        WITH    tResult
                  AS ( SELECT
			-- PRINT [dbo].[fnGetAllFieldNameInTable]('eComplaint', 'c', 'N', '', '', '')
                                c.RowID ,
                                c.wTranDt ,
                                c.wRefNo ,
                                c.wAgentCodeIn ,
                                a.wAgentCode_Display ,
                                a.wCName ,
                                c.wComplainantName ,
                                c.wType ,
                                c.wChannel ,
                                c.wReceivedBy ,
                                c.wContent ,
                                c.wComplaintStatus ,
                                c.wCancelRemark ,
                                c.wStatus ,
                                c.wCrtDt ,
                                c.wCrtBy ,
                                c.wUpdDt ,
                                c.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-GB' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     dbo.eComplaint c
                                LEFT JOIN [RollsMary].[dbo].[mAgent] a ON a.wAgentCodeIn = c.wAgentCodeIn
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = c.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = c.wCrtBy
                       WHERE    ( @pRefNo = ''
                                  OR c.wRefNo = @pRefNo
                                )
                                AND ( @pAgentCodeIn = ''
                                      OR c.wAgentCodeIn = @pAgentCodeIn
                                    )
                                AND c.wCrtDt BETWEEN @pDateFrom AND @pDateTo
                                AND ( @pStatus = ' '
                                      OR c.wStatus = @pStatus
                                    )
                                AND ( @pComplaintStatus = ''
                                      OR c.wComplaintStatus = @pComplaintStatus
                                    )
                                AND ( @pComplainCompNo = ''
                                      OR c.wComplainCompNo = @pComplainCompNo
                                    )
                                AND ( @pComplainDeptCd = ''
                                      OR c.wComplainDeptCd = @pComplainDeptCd
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
            ORDER BY tResult.wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );

		
    END;