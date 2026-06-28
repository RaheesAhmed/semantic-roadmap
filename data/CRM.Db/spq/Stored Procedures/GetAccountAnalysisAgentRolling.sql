CREATE PROCEDURE [spq].[GetAccountAnalysisAgentRolling]
	@pAgentCodeIn	VARCHAR(14),
	@pYearMth	VARCHAR(6)
AS
BEGIN
	SET NOCOUNT ON;
	IF @@TRANCOUNT = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
		
	DECLARE
		@pYearMthFrom	VARCHAR(6)
 
	SET @pYearMthFrom = dbo.fnAddYearMth(@pYearMth, -6);
	
	WITH cteAgentLevel AS (
		SELECT
			wAgentCodeIn, wLvlAgentCodeIn
		FROM
			Rollsmary.dbo.mAgentLevel al
		WHERE
			al.wLvlAgentCodeIn = @pAgentCodeIn
		AND
			al.wExpireYearMth = ''
	), cteResult AS (    
		SELECT
			wYearMth, wCurrCode,
			wSoleRollingA = ISNULL(SUM(CASE WHEN abrm.wAgentCodeIn = @pAgentCodeIn THEN abrm.wRolling - abrm.wRollingBPlay ELSE 0 END), 0),
			wSoleRollingB = ISNULL(SUM(CASE WHEN abrm.wAgentCodeIn = @pAgentCodeIn THEN abrm.wRollingBPlay ELSE 0 END), 0),
			wLineRollingA = ISNULL(SUM(abrm.wRolling - abrm.wRollingBPlay), 0),
			wLineRollingB = ISNULL(SUM(abrm.wRollingBPlay), 0)
		FROM
			Rollsmary.dbo.mAgentBalRollingMth abrm
		INNER JOIN
			cteAgentLevel al ON abrm.wAgentCodeIn = al.wAgentCodeIn
		WHERE
			abrm.wYearMth BETWEEN @pYearMthFrom AND @pYearMth
		GROUP BY
			wYearMth, wCurrCode
	)
	
	SELECT
		r.*,
		cp.wFxRate
	FROM
		cteResult r
	INNER JOIN
		Rollsmary.dbo.mCurrencyPeriod cp ON cp.wType = 'MONTH' AND cp.wToCurrCode = 'HKD' AND r.wYearMth = cp.wYearMth AND r.wCurrCode = cp.wCurrCode
	ORDER BY
		r.wYearMth DESC, r.wCurrCode
	
END