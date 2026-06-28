CREATE PROCEDURE [spq].[GetHotelBookingsByRequestRid] @pRequestRid BIGINT
AS
    BEGIN  
        SELECT  CONVERT(BIT, 0) AS IsLinkVisible ,
                b.wRefNo ,
                bh.RowID AS BookingHotelRid ,
                bh.wBookingRid ,
                bh.wCounterRid
        FROM    eBookingHotel bh
                INNER JOIN eBooking b ON b.RowID = bh.wBookingRid
                                         AND bh.wStatus = 'A'
                INNER JOIN eHotelRequest hr ON bh.wRequestRid = hr.RowID
        WHERE   bh.wRequestRid = @pRequestRid;
					 
    END;