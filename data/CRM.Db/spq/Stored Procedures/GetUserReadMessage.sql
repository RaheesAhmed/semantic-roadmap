CREATE PROCEDURE spq.GetUserReadMessage
(
	@pUserRid bigint,
	@pRequestRid bigint
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT me.RowID, wUserRid,wRequestRid,wLastMessageId,usr.wUsrId,r.wRequestNo
	FROM dbo.eUserReadMessage me
        LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = me.wUserRid
        LEFT JOIN dbo.eDeptReqRoom r ON r.RowID = me.wRequestRid
END