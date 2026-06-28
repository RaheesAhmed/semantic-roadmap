
CREATE PROCEDURE [spq].[GetEventLst]
(
    @pName NVARCHAR(100) ,
    @pCode NVARCHAR(30),
    @pStartDate DATETIME2,
    @pEndDate DATETIME2,
    @pStatus VARCHAR(20) ,
    @pLangCd VARCHAR(10),
    @pPageNum INT = 1 ,
    @pPageSize INT = 100
)
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   

        SET @pName = NULLIF(@pName, '');
        SET @pCode = NULLIF(@pCode, '');  
        SET @pStartDate = ISNULL(@pStartDate, '0001-01-01'); 
        SET @pEndDate = ISNULL(@pEndDate, '9999-12-31'); 
        SET @pStatus = NULLIF(@pStatus, '');    
	
        WITH tResult AS (
            SELECT
                me.RowID ,
                me.wName , 
                me.wCode,                              
                me.wStartDate ,
                me.wEndDate ,
                me.wType ,
                me.wColorRGB ,
                me.wStatus ,
                me.wBookingStartDate,
                me.wBookingEndDate,
                me.wSunCRMStartDate,
                me.wSunCRMEndDate,
                me.wCrtDt ,
                me.wCrtBy ,
                me.wUpdDt ,
                me.wUpdBy ,
                wUpdByCName=CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
                wCreatedByCName=CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END
            FROM dbo.mEvent me
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = me.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = me.wCrtBy 
            WHERE (@pStatus IS NULL OR me.wStatus = @pStatus) 
            AND (@pName IS NULL OR me.wName = @pName)
            AND (@pCode IS NULL OR me.wCode = @pCode)
            AND (me.wStartDate BETWEEN @pStartDate AND @pEndDate)
            AND (me.wEndDate BETWEEN @pStartDate AND @pEndDate)
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT
            tResult.* ,
            wRecordCount
        FROM tResult, tCount
        ORDER BY wCrtDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;