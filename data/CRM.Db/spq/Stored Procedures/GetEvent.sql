
CREATE PROCEDURE [spq].[GetEvent]
(
    @pRowID BIGINT ,
    @pLangCd VARCHAR(30)
)
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pRowID = ISNULL(IIF(@pRowID <= 0, NULL, @pRowID), 0);
        SET @pLangCd = ISNULL(@pLangCd, '');
    	
        SELECT
            me.RowID ,
            me.wName ,
            me.wCode,
            me.wStartDate ,
            me.wEndDate ,
            me.wType ,
            me.wColorRGB,
            me.wStatus ,
            me.wBookingStartDate,
            me.wBookingEndDate,
            me.wSunCRMStartDate,
            me.wSunCRMEndDate,
            me.wCrtDt,
            me.wCrtBy,
            me.wUpdDt,
            me.wUpdBy,
            wUpdByCName=CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
            wCreatedByCName=CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END
        FROM dbo.mEvent me
        LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = me.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = me.wCrtBy
        WHERE @pRowID = me.RowID;                                                 
    END;