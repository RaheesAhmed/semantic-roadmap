

CREATE PROCEDURE [spq].[GetPersonList_Booking]
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
	SELECT 
		p.RowID,
		p.wAgentCodeIn wCode,
		cstmr.wCName wTitle
	FROM
	dbo.mPerson p
	INNER JOIN RollsMary.dbo.mAgent cstmr ON cstmr.wAgentCodeIn =p.wAgentCodeIn
	
    END;