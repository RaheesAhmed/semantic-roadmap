CREATE PROCEDURE [util].[InitSequence]
	@pRunUpdate		CHAR(1) = 'N'
AS
BEGIN
	DECLARE 
		@vTableName NVARCHAR(100) = '',
		@vSQL NVARCHAR(MAX) = '';

	DECLARE vendor_cursor CURSOR READ_ONLY FOR
		SELECT 
			t.name AS 'TableName'
		FROM        sys.columns c
		JOIN        sys.tables  t   ON c.object_id = t.object_id
		WHERE       c.name LIKE '%RowId%'
		ORDER BY    TableName;
	OPEN vendor_cursor  

	FETCH NEXT FROM vendor_cursor   
	INTO @vTableName

	WHILE @@FETCH_STATUS = 0 BEGIN
		SELECT 
			@vSQL = @vSQL + CONCAT(
				'CREATE SEQUENCE dbo.seq', 
				@vTableName, 
				CASE LEN(wCompNo) WHEN 1 THEN wCompNo * 1000 WHEN 2 THEN wCompNo * 100 WHEN 3 THEN wCompNo * 10 WHEN 4 THEN wCompNo END,
				' START WITH 1000 MINVALUE 1000 MAXVALUE 99999999999999' + ';'
			)
		FROM 
			RollsMary.dbo.mCompany c
		LEFT JOIN
			sys.objects s ON s.object_id = OBJECT_ID(N'[dbo].[seq' + @vTableName + CAST(CASE LEN(wCompNo) WHEN 1 THEN wCompNo * 1000 WHEN 2 THEN wCompNo * 100 WHEN 3 THEN wCompNo * 10 WHEN 4 THEN wCompNo END AS VARCHAR(4)) + ']') AND s.type = 'SO'
		WHERE 
			c.wStatus = 'A'
		AND
			s.object_id IS NULL

		PRINT @vSQL;

		IF (@pRunUpdate = 'Y') BEGIN
			EXEC (@vSQL);
		END

		SET @vSQL = '';
		FETCH NEXT FROM vendor_cursor INTO @vTableName
	END;
	CLOSE vendor_cursor;  
	DEALLOCATE vendor_cursor; 

END