
CREATE PROCEDURE [spq].[GetActivityLog] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  al_t.RowID ,
                al_t.wAction ,
                al_t.wReqAgentCodeIn ,
                al_t.wBookingRid ,
                al_t.wCategory ,
                al_t.wRemark ,
                al_t.wIsLatest ,
                al_t.wIsComplete ,
                al_t.wCrtDt ,
                al_t.wCrtBy ,
                al_t.wUpdDt ,
                al_t.wUpdBy ,
                'N' AS RecordState
        FROM    dbo.eActivityLog al_t
        WHERE   @pRowID = al_t.RowID;                                                 
    END;