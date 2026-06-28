CREATE PROCEDURE [spq].[GetRowID] (
	@pCompNo		INT,
    @pTableName		VARCHAR(50),
    @pReturnRID		BIGINT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;
    
	DECLARE
    	@sRtn				VARCHAR(14),
    	@sSeqName			VARCHAR(100),
        @sSeqExists			INT,
		@sDynamicSql		NVARCHAR(1000),
        @sNextValue			BIGINT,
        @sCompNo			INT
        
	SET @pCompNo = ISNULL(@pCompNo,99)

    IF LEN(@pCompNo) = 2 
    	SET @sCompNo = @pCompNo * 100
    ELSE
    	SET @sCompNo = @pCompNo
        
    SET @sSeqName = CONCAT('[dbo].[seq', @pTableName, @sCompNo, ']');

	SELECT @sSeqExists = COUNT(*)
	FROM sys.objects
	WHERE OBJECT_ID = OBJECT_ID(@sSeqName) AND type = 'SO'
    
    IF @sSeqExists = 0 BEGIN
    	-- CREATE
        SET @sDynamicSql = CONCAT('CREATE SEQUENCE ', @sSeqName, ' START WITH 10000 INCREMENT BY 1 MINVALUE 10000 MAXVALUE 99999999999999');
        EXEC sp_executesql @sDynamicSql;
    END

	SET @sDynamicSql = CONCAT('select @sNextValue = next value for ', @sSeqName);
   	EXEC sp_executesql @sDynamicSql, N'@sNextValue bigint output', @sNextValue OUTPUT;
	
	SET @pReturnRID = CONCAT(@sCompNo, FORMAT(@sNextValue, '0000000000'));
END