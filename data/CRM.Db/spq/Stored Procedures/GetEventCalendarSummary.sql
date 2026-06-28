

CREATE PROCEDURE [spq].[GetEventCalendarSummary]
(
    @pDeptCd VARCHAR(30),
    @pStartDate DATE,
    @pEndDate DATE,
    @pType VARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @pDeptCd = NULLIF(@pDeptCd, '');
    SET @pStartDate = ISNULL(@pStartDate, '0001-01-01'); 
    SET @pEndDate = ISNULL(@pEndDate, '9999-12-31');
    SET @pType = NULLIF(@pType, '');      
	
    SELECT
        me.RowID,
        me.wName ,
        me.wCode,
        me.wStartDate,
        me.wEndDate,
        me.wBookingStartDate,
        me.wBookingEndDate,
        me.wType ,
        me.wColorRGB
    FROM dbo.mEvent me
    WHERE me.wStatus ='A'
        AND (@pType IS NULL OR @pType = me.wType)
        AND (  
               (me.wStartDate BETWEEN @pStartDate AND @pEndDate)
            OR (me.wEndDate BETWEEN @pStartDate AND @pEndDate)
            OR (@pStartDate BETWEEN me.wStartDate AND me.wEndDate)
            OR (@pEndDate BETWEEN me.wStartDate AND me.wEndDate)
        )
END;