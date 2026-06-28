CREATE PROCEDURE [spa].[SetBirthdaySMSStatus]
(
	@pRowId		BIGINT = 0
)
AS
BEGIN
 
 --select * from  CRM.dbo.eBirthday
    UPDATE CRM.dbo.eBirthday
    SET wSMSStatus='Y'
    WHERE RowID=@pRowId
	
END