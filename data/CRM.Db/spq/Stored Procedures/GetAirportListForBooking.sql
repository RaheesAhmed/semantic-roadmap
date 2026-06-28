CREATE PROCEDURE [spq].[GetAirportListForBooking]
(
    @pName NVARCHAR(200) ,
    @pCode VARCHAR(10) ,
    @pCity VARCHAR(10)
)
AS
    BEGIN
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        SET NOCOUNT ON;
        IF @@TRANCOUNT = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
        
        SET @pName = NULLIF(@pName, '');
        SET @pCode = NULLIF(@pName, '');
        SET @pCity = NULLIF(@pCity, '');

        -- Insert statements for procedure here	
        SELECT
            ma.RowID ,
            ma.wCName ,
            ma.wEName ,
            ma.wCode ,
            wCityCode = ma.wCity,
            wCity = lup.wTitle ,
            lup.wLangCd ,
            ma.wRemark ,
            ma.wStatus ,
            ma.wSeqNo ,
            ma.wCrtDt ,
            ma.wCrtBy ,
            ma.wUpdDt ,
            ma.wUpdBy
        FROM dbo.mAirport ma
        INNER JOIN mLookUp lup ON lup.wCode = ma.wCity AND lup.wType = 'CITY'
        WHERE (@pName IS NULL OR @pName = ma.wCName OR @pName = ma.wEName)
            AND (@pCode IS NULL OR @pCode = ma.wCode)
            AND (@pCity IS NULL OR @pCity = ma.wCity)
            --AND ma.wStatus = 'A'
    END;