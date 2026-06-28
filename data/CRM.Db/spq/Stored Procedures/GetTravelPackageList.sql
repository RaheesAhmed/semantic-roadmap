CREATE PROCEDURE [spq].[GetTravelPackageList] ( @pwStatus CHAR(1) = NULL )
AS
    BEGIN
        SET NOCOUNT ON;
	
        SELECT  eb.wRefNo ,
                ebtp.RowID
        FROM    eBookingTravelPackage ebtp
                INNER JOIN eBooking eb ON eb.RowID = ebtp.wBookingRid
		--Now Gets All data
        --WHERE   ( @pwStatus = ''
        --          OR @pwStatus IS NULL
        --          OR @pwStatus = ebtp.wBookingStatus
        --        )
        --        AND ebtp.wBookingStatus IN ( 'P', 'C' )
        ORDER BY eb.wRefNo ASC;	
	

    END;