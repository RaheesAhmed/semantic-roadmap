

CREATE PROCEDURE [spq].[GetRoomKeyPasscode] 
                 @pKeyPasscode VARCHAR(10) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;	  	
		DECLARE @sGetKeyPasscode VARCHAR(10)='';
        		
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
        SET @sGetKeyPasscode =RIGHT(CAST(( RAND() + 1 ) * 1000000 AS INT), 6);
        WHILE @sGetKeyPasscode ='' OR EXISTS(SELECT 1 FROM dbo.[eBookingRoom] WHERE wGetKeyPasscode=@sGetKeyPasscode AND  wCrtDt BETWEEN dateadd(day,-7,dbo.fnUTC8Now()) AND dbo.fnUTC8Now())
		    BEGIN
			    SET @sGetKeyPasscode =RIGHT(CAST(( RAND() + 1 ) * 1000000 AS INT), 6);
			END;
        SET @pKeyPasscode = @sGetKeyPasscode;                                               
    END;