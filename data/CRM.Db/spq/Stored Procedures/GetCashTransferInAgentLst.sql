
CREATE PROCEDURE [spq].[GetCashTransferInAgentLst]

AS
    BEGIN
        SET NOCOUNT ON;
        
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      
			  
        SELECT  wAgentCode,
                wAgentCodeIn,
                wAgentCode_Old
        FROM    RollsMary.dbo.mAgent
        WHERE   wType IN ('AGENT','STORE','STOREC') 
               AND (wAgentCodeIn ='1000028320' --消1
                OR wAgentCodeIn ='9500026239' --馬消1
                OR wAgentCodeIn ='1000031096' --韓國9
                OR wAgentCodeIn = '1600040933' --VZA86
                OR wAgentCodeIn = '4000028330') --會1  (怕user 改了戶口名，就會找不到這個戶口了，用agentcodein會比較好)
               AND wStatus!='T';
    END;