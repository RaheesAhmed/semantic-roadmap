

CREATE VIEW [vipRpt].[vwServiceCounter]
AS
SELECT RowID,
       wName,
       wRollexCompNo
FROM dbo.mServiceCounter;