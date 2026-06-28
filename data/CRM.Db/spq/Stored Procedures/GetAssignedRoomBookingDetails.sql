CREATE PROCEDURE [spq].[GetAssignedRoomBookingDetails]
    (
      @pHotelRequestID BIGINT = NULL
    )
AS
    BEGIN
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 
        DECLARE @Request TABLE
            (
              wRequestRid BIGINT ,
              wHotelCode VARCHAR(20) ,
              wCounterRid BIGINT ,
              ProvideRoomQty INT ,
              wIsReject CHAR(1) ,
              RowID BIGINT
            );
        DECLARE @Booking TABLE
            (
              RowID BIGINT ,
              wSeqNo INT ,
              wRequestRid BIGINT ,
              wHotelCode VARCHAR(20) ,
              wCounterRid BIGINT ,
              Confirmed INT ,
              wBookingStatus VARCHAR(5) ,
              wHotelBookingRid BIGINT
            );  

        INSERT  INTO @Request
                SELECT  wHotelRequestRid ,
                        wHotelCode ,
                        wCounterRid ,
                        wTotalProvideRoomQty ,
                        wIsReject ,
                        RowID
                FROM    eHotelRequestDtl
                WHERE   wHotelRequestRid = @pHotelRequestID;

        INSERT  INTO @Booking
                SELECT  eb.RowID ,
                        eb.wSeqNo ,
                        wRequestRid ,
                        mHotel.wCode AS wHotelCode ,
                        wCounterRid ,
                        ( CASE WHEN wBookingStatus IN ( 'CL', 'P', 'U', 'RF' )
                               THEN 0
                               ELSE 1
                          END ) AS Confirmed ,
                        wBookingStatus ,
                        eb.wHotelBookingRid
                FROM    eBookingRoom eb
                        INNER JOIN mHotel ON eb.wHotelRid = mHotel.RowID
                WHERE   eb.wRequestRid = @pHotelRequestID
                        AND eb.wStatus = 'A';

        SET NOCOUNT ON;
	
        SELECT  eb.wRefNo AS RoomBookingRefNo ,
                ISNULL(( REPLICATE('0', 3 - LEN(RTRIM(res.RoomSeqNo)))
                         + RTRIM(res.RoomSeqNo) ), 0) AS RoomSeqNo ,
                mHotel.wName AS HotelName ,
				mHotel.RowID AS HotelRid,
                wHotelCode AS wCode ,
                res.wCounterRid AS ServiceCounterRID ,
                sc.wName AS ServiceCounterName ,
                res.RowID AS RowID ,
                ISNULL(ProvideRoomQty, 0) AS QtyApproved ,
                ISNULL(res.RoomBookingRID, 0) AS RoomBookingRID ,
                ISNULL(Confirmed, 0) AS QtyConfirmed ,
                ISNULL(wIsReject, 'N') AS IsRejected ,
                ISNULL(res.wBookingStatus, 'P') AS wStatus ,
                '' AS EmptyString
        FROM    ( SELECT    B.wSeqNo AS RoomSeqNo ,
                            B.RowID AS RoomBookingRID ,
                            ISNULL(R.RowID, 0) AS RowID ,
                            ISNULL(R.wRequestRid, B.wRequestRid) AS wHotelRequestRid ,
                            ISNULL(R.wHotelCode, B.wHotelCode) AS wHotelCode ,
                            ISNULL(R.wCounterRid, B.wCounterRid) AS wCounterRid ,
                            R.ProvideRoomQty ,
                            R.wIsReject ,
                            B.Confirmed ,
                            B.wBookingStatus ,
                            B.wHotelBookingRid
                  FROM      @Request R
                            FULL OUTER JOIN @Booking B ON R.wHotelCode = B.wHotelCode
                                                          AND R.wCounterRid = B.wCounterRid
                ) res
                INNER JOIN mHotel ON mHotel.wCode = res.wHotelCode
                LEFT JOIN eBookingHotel ebh ON ebh.wRequestRid = res.wHotelRequestRid
                                               AND res.wHotelBookingRid = ebh.RowID
                LEFT JOIN eBooking eb ON eb.RowID = ebh.wBookingRid
                INNER JOIN mServiceCounter sc ON sc.RowID = res.wCounterRid;
    END;