CREATE PROCEDURE [spq].[GetCorpEventAgent] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

	-- Insert statements for procedure here
	-- PRINT dbo.fnGetAllFieldNameInTable('eCorpEventAgent', 'cea', 'N', 'N', 'N', '')
        SELECT  cea.RowID ,
                cea.wCorpEventRid ,
                cea.wAgentCodeIn ,
                cea.wResponseType ,
                cea.wGuestInvited ,
                cea.wGuestAttend ,
				cea.wCfmGuestAttend,
                cea.wRemark ,
                cea.wStatus ,
                cea.wCrtDt ,
                cea.wCrtBy ,
                cea.wUpdDt ,
                cea.wUpdBy
        FROM    dbo.eCorpEventAgent cea
        WHERE   cea.RowID = @pRowID;
    END;