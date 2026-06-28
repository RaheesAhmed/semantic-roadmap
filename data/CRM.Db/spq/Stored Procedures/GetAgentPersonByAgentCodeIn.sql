
CREATE PROCEDURE [spq].[GetAgentPersonByAgentCodeIn]
    @pAgentCodeIn VARCHAR(14) ,
    @pLang VARCHAR(10)
AS
    BEGIN	
	/*EXEC spq.GetAgentPersonByAgentCodeIn 
		@pAgentCodeIn = '1000010180', -- varchar(14)
	    @pLang = 'zh-TW' -- varchar(10)
	*/
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        DECLARE @sAgentCode_Old AS NVARCHAR(20);

        SET @pLang = LOWER(@pLang);
        SET @sAgentCode_Old = ( SELECT TOP 1
                                        wAgentCode_Old
                                FROM    RollsMary.dbo.mAgent
                                WHERE   wAgentCodeIn = @pAgentCodeIn
                              );
	
        SELECT  CASE WHEN @pLang = 'en-gb' THEN a.wEName
                     ELSE a.wCName
                END AS wName ,
                a.wType ,
                a.wAgentCodeIn,
				'mAgent' AS wRefTable,
				a.RowID AS wRefRid
        FROM    RollsMary.dbo.mAgent a
        WHERE   a.wStatus = 'A'
                AND a.wType = 'AGENT'
                AND a.wAgentCode_Old = @sAgentCode_Old
        UNION ALL
        SELECT  CASE WHEN @pLang = 'en-gb' THEN a.wEName
                     ELSE a.wCName
                END AS wName ,
                a.wType ,
                a.wAgentCodeIn,
				'mAgent' AS wRefTable,
				a.RowID AS wRefRid
        FROM    RollsMary.dbo.mAgent a
        WHERE   a.wStatus = 'A'
                AND a.wType = 'AUTH'
				AND a.wAuthIdentity <> 'OWNER'
                AND a.wAgentCode_Old = @sAgentCode_Old
        UNION ALL
        SELECT  CASE WHEN @pLang = 'en-gb' THEN p.wEName
                     ELSE p.wCName
                END AS wName ,
                'CRM_CUST' AS wType ,
                p.wAgentCodeIn,
				'mPerson' AS wRefTable,
				p.RowID AS wRefRid
        FROM    dbo.mPerson p
        WHERE   p.wStatus = 'A'
                AND p.wAgentCodeIn = @pAgentCodeIn
        UNION ALL
        SELECT  CASE WHEN @pLang = 'en-gb' THEN c.wCustEName
                     ELSE c.wCustCName
                END AS wName ,
                'CUST' AS wType ,
                c.wAgentCodeIn,
				'mCustomer' AS wRefTable,
				c.RowID AS wRefRid
        FROM    RollsMary.dbo.mCustomer c
        WHERE   c.wStatus = 'A'
                AND c.wAgentCodeIn = @pAgentCodeIn;
    END;