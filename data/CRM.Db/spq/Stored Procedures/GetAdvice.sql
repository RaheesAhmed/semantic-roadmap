CREATE PROCEDURE [spq].[GetAdvice]
    @pRowID BIGINT ,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      
			  
        SELECT  a.RowID ,
                a.wRefNo ,
                a.wAim ,
                a.wDate ,
                a.wAgentCodeIn ,
                ag.wAgentCode_Display ,
                a.wType ,
                a.wSubType ,
                a.wIsHighPriority ,
                a.wReceivedBy ,
                a.wReceivedDeptCd ,                              
                CASE WHEN @pLangCd = 'en-GB' THEN u_rb.wName
                     ELSE u_rb.wCName
                END AS wReceivedByCName ,				
                a.wAdviceStatus ,
                a.wContent ,
                a.wStatus ,
                a.wCrtDt ,
                a.wCrtBy ,
                CASE WHEN @pLangCd = 'en-GB' THEN u_cb.wName
                     ELSE u_cb.wCName
                END AS wCreatedByCName ,
                a.wUpdDt ,
                a.wUpdBy ,              
                CASE WHEN @pLangCd = 'en-GB' THEN u.wName
                     ELSE u.wCName
                END AS wUpdByName
        FROM    dbo.eAdvice a
                LEFT JOIN RollsMary.dbo.mAgent ag ON a.wAgentCodeIn = ag.wAgentCodeIn
                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = a.wUpdBy                
                LEFT JOIN RollsMary.dbo.mUsr u_rb ON u_rb.RowID = a.wReceivedBy                
                LEFT JOIN RollsMary.dbo.mUsr u_cb ON u_cb.RowID = a.wCrtBy
        WHERE   a.RowID = @pRowID;
    END;