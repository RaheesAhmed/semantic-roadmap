CREATE PROCEDURE [spq].[GetAirTicketRouteLst]
    @pType VARCHAR(30) ,
    @pTypeRid BIGINT = NULL ,
    @pBookingRid BIGINT = NULL ,
    @pStatus CHAR(1) = NULL ,
    @pLangCd VARCHAR(10) = 'en-gb'
AS
    BEGIN

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;  

-- Get Comman Route details
        SELECT  ABK.[RowID] ,
                ABK.[wType] ,
                ABK.[wTypeRid] ,
                ABK.[wPNRNo] ,
                ABK.[wLine] ,
                ABK.[wFlightType] ,
                ABK.[wAirline] ,
                ABK.[wClassCd] ,
                ABK.[wIsReturn] ,
                ABK.[wDepartFlightNo] ,
                ABK.[wDepartureAirportRid] ,
                ABK.[wArrivalAirportRid] ,
                ABK.[wDepartureTerminal] ,
                ABK.[wArrivalTerminal] ,
                ABK.[wTakeOffDt] ,
                ABK.[wArrivalDt] ,
                ABK.[wStatus] ,
                ABK.[wCrtDt] ,
                ABK.[wCrtBy] ,
                ABK.[wUpdDt] ,
                ABK.[wUpdBy],
				ABK.[wIsWaiting],
				ABK.[wExpiryDt],
                ABK.[wIsDestination]
        FROM    ( SELECT    *
                  FROM      [dbo].[eAirTicketRouteDtl]
                  WHERE     wType = 'AIRTICKET'
                            AND ( @pStatus IS NULL
                                  OR wStatus = @pStatus
                                )
                            AND ( @pTypeRid IS NULL
                                  OR @pTypeRid < 1
                                  OR ( ( @pType = 'AIRTICKET'
                                         AND wTypeRid = @pTypeRid
                                       )
                                       OR @pType != 'AIRTICKET'
                                     )
                                )
                ) ABK
                INNER JOIN ( SELECT *
                             FROM   dbo.eBookingAirTicket
                             WHERE  ( @pBookingRid IS NULL
                                      OR wBookingRid = @pBookingRid
                                    )
                           ) EBK ON EBK.RowID = ABK.wTypeRid
        UNION
	-- Get Passenger Route details using : ePassenger.RowID=eAirTicketRouteDtl.wTypeRid and wType=8(BookingType=Passenger)
        SELECT  AIR.[RowID] ,
                AIR.[wType] ,
                AIR.[wTypeRid] ,
                AIR.[wPNRNo] ,
                AIR.[wLine] ,
                AIR.[wFlightType] ,
                AIR.[wAirline] ,
                AIR.[wClassCd] ,
                AIR.[wIsReturn] ,
                AIR.[wDepartFlightNo] ,
                AIR.[wDepartureAirportRid] ,
                AIR.[wArrivalAirportRid] ,
                AIR.[wDepartureTerminal] ,
                AIR.[wArrivalTerminal] ,
                AIR.[wTakeOffDt] ,
                AIR.[wArrivalDt] ,
                AIR.[wStatus] ,
                AIR.[wCrtDt] ,
                AIR.[wCrtBy] ,
                AIR.[wUpdDt] ,
                AIR.[wUpdBy],
				AIR.[wIsWaiting],
				AIR.[wExpiryDt],
                AIR.[wIsDestination]
        FROM    ( SELECT    *
                  FROM      [dbo].[eAirTicketRouteDtl]
                  WHERE     wType = 'PASSENGER'
                            AND ( @pStatus IS NULL
                                  OR wStatus = @pStatus
                                )
                            AND ( @pTypeRid IS NULL
                                  OR @pTypeRid < 1
                                  OR ( @pType = 'PASSENGER'
                                       AND wTypeRid = @pTypeRid
                                     )
                                )
                ) AIR
                INNER JOIN ( SELECT *
                             FROM   [dbo].[ePassengerDetails]
                             WHERE  ( @pBookingRid IS NULL
                                      OR wBookingRid = @pBookingRid
                                    )
                           ) PASS ON PASS.RowID = AIR.wTypeRid;
    END;