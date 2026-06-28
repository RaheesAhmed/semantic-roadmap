
CREATE PROCEDURE [spq].[GetBirthdayBudget]
    @pXMLAgentCodeIn XML,
    @pDate DATE,
    @pXMLResult XML OUTPUT -- Exec不能用嵌套INSERT INTO，故用OUTPUT
AS
BEGIN
    DECLARE @vRollingAvg TABLE(
        wAgentCodeIn VARCHAR(14), 
        wRollingAvgAmt NUMERIC(18, 4)
    );

    INSERT INTO @vRollingAvg EXEC spq.GetRollingAvgForBirthday @pXMLAgentCodeIn, @pDate;

    SET @pXMLResult = (
        SELECT
            wAgentCodeIn,
            wRollingAvgAmt, -- 平均轉碼
            wTotalBudgetAmt = wRollingAvgAmt / 10000 * 6000 -- 1億有6000預算（平均轉碼以萬為單位）
        FROM @vRollingAvg
        FOR XML RAW('Record'), ROOT('DataSet')
    );
END