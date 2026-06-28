CREATE PROC spq.GetCompanyLstForReport
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sToday DATE = CAST(GETDATE() AS DATE);

        SELECT  c.RowID,
		        c.wCompNo,
		        c.wCName,
		        c.wEName,
		        c.wShortName
	    FROM RollsMary.dbo.mCompany c WITH(NOLOCK)
	    INNER JOIN RollsMary.dbo.mCage mc WITH(NOLOCK) ON mc.wCompNo = c.wCompNo
	    WHERE c.wStatus = 'A'
		    AND mc.wStatus = 'A'
            AND (c.wTerminateDate IS NULL OR c.wTerminateDate > @sToday);
    END