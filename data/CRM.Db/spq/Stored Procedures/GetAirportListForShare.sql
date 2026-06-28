
CREATE PROCEDURE [spq].[GetAirportListForShare]
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

	-- Insert statements for procedure here	
        SELECT  ma.RowID ,
                ma.wCName ,
                ma.wEName ,
                ma.wCode ,
                ma.wCity AS wCityCode ,
                lup.wTitle AS wCity ,
                lup.wLangCd ,
                ma.wRemark ,
                ma.wStatus ,
                ma.wSeqNo ,
                ma.wCrtDt ,
                ma.wCrtBy ,
                ma.wUpdDt ,
                ma.wUpdBy
        FROM    dbo.mAirport ma
                INNER JOIN mLookUp lup ON lup.wCode = ma.wCity AND lup.wType = 'CITY'
        WHERE   ( ISNULL(@pName, '') = '' OR @pName = ma.wCName OR @pName = ma.wEName )
                AND ( ISNULL(@pCode, '') = ''  OR @pCode = ma.wCode )
                AND ( ISNULL(@pCity, '') = '' OR @pCity = ma.wCity )
                --AND ma.wStatus = 'A'
        ORDER BY wUpdDt DESC;
    END;