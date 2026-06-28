CREATE PROCEDURE [spq].[GetCorpEvent] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

	-- Insert statements for procedure here
	-- PRINT dbo.fnGetAllFieldNameInTable('eCorpEvent', 'ce', 'N', 'N', 'N', '')
        SELECT  ce.RowID ,
                ce.wName ,
                ce.wCategory ,
                ce.wSubCategory ,
                ce.wStartDt ,
                ce.wEndDt ,
                ce.wIsCharged ,
                ce.wRemark ,
                ce.wGuestInvited ,
                ce.wGuestAttend ,
				ce.wCfmGuestAttend,
                ce.wStatus ,
                ce.wCrtDt ,
                ce.wCrtBy ,
                ce.wUpdDt ,
                ce.wUpdBy
        FROM    dbo.eCorpEvent ce
        WHERE   ce.RowID = @pRowID;
    END;