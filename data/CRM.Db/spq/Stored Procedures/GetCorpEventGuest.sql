CREATE PROCEDURE [spq].[GetCorpEventGuest] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

	-- Insert statements for procedure here
	-- PRINT dbo.fnGetAllFieldNameInTable('eCorpEventGuest', 'ceg', 'N', 'N', 'N', '')
        SELECT  ceg.RowID ,
                ceg.wCorpEventRid ,
                ceg.wAgentCodeIn ,
                ceg.wGuestName ,
                ceg.wPersonRid ,
                ceg.wGuestInvited ,
                ceg.wGuestAttend ,
				ceg.wCfmGuestAttend,
                ceg.wRemark ,
                ceg.wStatus ,
                ceg.wCrtDt ,
                ceg.wCrtBy ,
                ceg.wUpdDt ,
                ceg.wUpdBy
        FROM    dbo.eCorpEventGuest ceg
        WHERE   ceg.RowID = @pRowID;
    END;