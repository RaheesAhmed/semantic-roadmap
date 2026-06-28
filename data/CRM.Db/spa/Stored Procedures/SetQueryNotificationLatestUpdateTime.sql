
CREATE PROCEDURE [spa].[SetQueryNotificationLatestUpdateTime] @pQueryName VARCHAR(100),
	@pLatestUpdateTime DATETIME2,
	@pErrMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @rCurrRowId BIGINT

	BEGIN TRY
		DECLARE @wStampDate DATETIME = dbo.fnUTC8Now()
		DECLARE @wStampUser VARCHAR(50) = SUSER_SNAME()

		SELECT TOP 1 @rCurrRowId = wLastRowID
		FROM [RollsMary].[dbo].[mQueryNotification]
		WHERE wQueryName = @pQueryName

		SET @pErrMessage = ''

		BEGIN TRANSACTION t1

		UPDATE [RollsMary].[dbo].[mQueryNotification]
		SET wLastestUpdateTime = ISNULL(@pLatestUpdateTime, @wStampDate)
		WHERE wQueryName = @pQueryName

		COMMIT TRANSACTION t1

		SET @pErrMessage = ''

		RETURN 0
	END TRY

	BEGIN CATCH
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

		SELECT @ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE()

		SET @pErrMessage = '<ERR PROC: ' + ERROR_PROCEDURE() + '>' + CHAR(13) + '<Code:' + CONVERT(NVARCHAR, 
				ERROR_NUMBER()) + '>' + CHAR(10) + '<LINE:' + CAST(ERROR_LINE() AS VARCHAR(10)) + '>' + CHAR(13) + 
			CHAR(10) + '<MSG:' + SUBSTRING(ERROR_MESSAGE(), 0, 1500) + '>' + CHAR(13) + CHAR(10) + '<pQueryName:' + 
		    RollsMary.fns.ToString(@pQueryName) + '>' + '<pLatestUpdateTime:' + RollsMary.fns.ToString(@pLatestUpdateTime) + '>'

		RAISERROR (
				@pErrMessage,
				@ErrorSeverity,
				@ErrorState
				)

		RETURN - 1
	END CATCH
END