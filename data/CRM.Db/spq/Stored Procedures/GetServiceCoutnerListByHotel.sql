-- [spq].[GetServiceCoutnerListByHotel] 'CNSH,SSFB,HSH,SHH,CNJA,AZ,BR'
CREATE PROCEDURE [spq].[GetServiceCoutnerListByHotel]
    (
      @pHotelCodes VARCHAR(MAX)
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
        DECLARE @centalCSID NVARCHAR(50);
        SET @centalCSID = ( SELECT  wValue
                            FROM    RollsMary.dbo.mSysTable
                            WHERE   wItemCode = 'CENTRAL_COUNTER'
                          );

	-- Top to be removed once Agent list size is reduced 
        DECLARE @tempHotelList TABLE ( wHotelCode VARCHAR(20) );
        INSERT  INTO @tempHotelList
                ( wHotelCode
                )
                SELECT  splitdata
                FROM    dbo.Split(@pHotelCodes, ',');
		
        SELECT DISTINCT
                sc.RowID ,
                sc.wCode ,
                sc.wName ,
                h.wName AS wHotelAssigned ,
                0 wQuantityApproved ,
                0 wQuantityConfirmed ,
                'P' AS wStatus ,
                'No' AS wIsRejected ,
                h.wCode AS wHotelCode ,
                h.RowID AS wHotelRowID ,
                ( CASE WHEN sc.RowID = @centalCSID THEN 1
                       ELSE 0
                  END ) AS wIsCentralServiceCounter ,
                '' AS wCrtByCounterRid,
				'' AS wRemark
        FROM    dbo.mServiceCounter sc
                INNER JOIN dbo.mAllotmentGroupDtl agd ON sc.RowID = agd.wCounterRid
                INNER JOIN dbo.mAllotmentGroup ag ON agd.wAllotmentGroupRid = ag.RowID
                INNER JOIN dbo.eAllotmentHotelDtl ahd ON ag.RowID = ahd.wAllotmentGroupRid
                INNER JOIN dbo.eAllotmentHotel ah ON ahd.wAllotmentHotelRid = ah.RowID
                INNER JOIN dbo.mHotel h ON h.RowID = ah.wHotelRid
        WHERE   h.wCode IN ( SELECT wHotelCode
                             FROM   @tempHotelList )
                AND sc.RowID <> @centalCSID;	
    END;