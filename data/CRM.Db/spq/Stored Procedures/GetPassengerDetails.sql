CREATE PROCEDURE [spq].[GetPassengerDetails]
		@pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT 
            RowID, 
            wBookingRid, 
            wCasinoCardRid, 
            wRoomBookingRid, 
            wClientTicketNo,
            wDepartFlightNo, 
            wTakeOffDt,
            wTakeOffDtStr = FORMAT(wTakeOffDt, 'yyyy-MM-dd HH:mm:ss'), 
            wDestination, 
            wRequesterAcc, 
            wPersonRid, 
            wRemark, 
            wStatus, 
            wCrtBy, 
            wCrtDt, 
            wUpdDt, 
            wUpdBy,
            wType, 
            wApplicationType, 
            wApplicationStatus, 
            wAmount, 
            wCost, 
            wPassengerSeqNo = wSeqNo, 
            wCancelDebitDt, 
            wCancelReasonCd, 
            wCancelBy, 
            wCancelDt, 
            wPassengerBookingStatus, 
            wOldPassengerBookingStatus = wPassengerBookingStatus,
            wChangeOrderCount, 
            wIsWaiting, 
            wRouteRid, 
            wOtherReason
        FROM dbo.ePassengerDetails
	    WHERE @pRowID = RowID                                                 
    END;