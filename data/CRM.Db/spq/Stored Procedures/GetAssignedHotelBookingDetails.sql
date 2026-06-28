

CREATE PROCEDURE [spq].[GetAssignedHotelBookingDetails]
    (
      @pHotelRequestID BIGINT = NULL ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN
        IF @@TRANCOUNT = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @Booking TABLE
            (
              wRequestRid BIGINT ,
              wHotelCode VARCHAR(10) ,
              wCounterRid BIGINT ,
              Confirmed INT ,
              Cancelled INT ,
              Unqualified INT
            );


        INSERT  INTO @Booking
                SELECT  wRequestRid ,
                        wHotelCode ,
                        wCounterRid ,
                        SUM(Confirmed) ,
                        SUM(Cancelled) ,
                        SUM(Unqualified)
                FROM    ( SELECT    wRequestRid ,
                                    mHotel.wCode AS wHotelCode ,
                                    wCounterRid ,
                                    wBookingStatus ,
                                    ( CASE WHEN wBookingStatus IN ( 'CL', 'P', 'U', 'RF' ) THEN 0
                                           ELSE 1
                                      END ) AS Confirmed ,
                                    ( CASE WHEN wBookingStatus = 'CL' THEN 1
                                           ELSE 0
                                      END ) AS Cancelled ,
                                    ( CASE WHEN wBookingStatus = 'U' THEN 1
                                           ELSE 0
                                      END ) AS Unqualified
                          FROM      eBookingRoom eb
                                    INNER JOIN mHotel ON eb.wHotelRid = mHotel.RowID
                                                         AND eb.wStatus = 'A'
                          WHERE     eb.wRequestRid = @pHotelRequestID
                        ) RoomBooking
                GROUP BY wRequestRid ,
                        wHotelCode ,
                        wCounterRid;

        SET NOCOUNT ON;

        WITH    tHotelRequestDtl
                  AS ( SELECT   R.RowID AS HotelRequestDtlRid ,
                                R.wHotelRequestRid AS wRequestRid ,
                                ISNULL(R.wHotelCode, B.wHotelCode) AS wHotelCode ,
                                R.wLine ,
                                R.wSeqNo ,
                                R.wRemark ,
                                R.wCrtDt ,
                                R.wCrtBy ,
                                R.wUpdBy ,
                                R.wUpdDt ,
                                ISNULL(R.wCounterRid, B.wCounterRid) AS wCounterRid ,
                                R.wTotalProvideRoomQty AS QtyApproved ,
                                R.wIsReject ,
                                R.wCrtByCounterRid ,
                                B.Confirmed ,
                                B.Cancelled ,
                                B.Unqualified ,
                                CASE WHEN ( ISNULL(B.Confirmed, 0) = 0
                                            AND ISNULL(B.Cancelled, 0) = 0
                                            AND ISNULL(B.Unqualified, 0) = 0
                                          ) THEN 'P'
                                     WHEN ( ISNULL(B.Unqualified, 0) > 0
                                            AND ISNULL(B.Unqualified, 0) < R.wTotalProvideRoomQty
                                          ) THEN 'PU'
                                     WHEN ( ISNULL(B.Unqualified, 0) > 0
                                            AND ISNULL(B.Unqualified, 0) = R.wTotalProvideRoomQty
                                          ) THEN 'UQ'
                                     WHEN ( ISNULL(B.Confirmed, 0) > 0
                                            AND ISNULL(B.Confirmed, 0) < R.wTotalProvideRoomQty
                                          ) THEN 'PC'
                                     WHEN ( ISNULL(B.Confirmed, 0) > 0
                                            AND ISNULL(B.Confirmed, 0) = R.wTotalProvideRoomQty
                                          ) THEN 'C'
                                     WHEN ( ISNULL(B.Cancelled, 0) > 0
                                            AND ISNULL(B.Cancelled, 0) = R.wTotalProvideRoomQty
                                          ) THEN 'CL'
                                END AS wStatus
                       FROM     eHotelRequestDtl R
                                LEFT JOIN @Booking B ON R.wHotelCode = B.wHotelCode
                                                        AND R.wCounterRid = B.wCounterRid
                       WHERE    R.wHotelRequestRid = @pHotelRequestID
                     ),
                tResult
                  AS ( SELECT   res.HotelRequestDtlRid AS RowID ,
                                res.wRequestRid ,
                                mHotel.wName AS HotelName ,
                                mHotel.RowID AS HotelRid ,
                                wHotelCode AS wCode ,
                                wCounterRid AS ServiceCounterRID ,
                                sc.wName AS ServiceCounterName ,
                                ISNULL(QtyApproved, 0) AS QtyApproved ,
                                ISNULL(Confirmed, 0) AS QtyConfirmed ,
                                ISNULL(Cancelled, 0) AS QtyCancelled ,
                                ISNULL(Unqualified, 0) AS QtyUnqualified ,
                                ISNULL(wIsReject, ' ') AS IsRejected ,
                                res.wCrtByCounterRid ,
                                res.wLine ,
                                res.wSeqNo ,
                                res.wRemark ,
                                res.wCrtDt ,
                                res.wCrtBy ,
                                res.wUpdBy ,
                                res.wUpdDt ,
                                res.wStatus
                       FROM     tHotelRequestDtl res
                                INNER JOIN mHotel ON mHotel.wCode = res.wHotelCode
                                INNER JOIN mServiceCounter sc ON sc.RowID = res.wCounterRid
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(1)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
FETCH NEXT @pPageSize ROWS ONLY;

    END;