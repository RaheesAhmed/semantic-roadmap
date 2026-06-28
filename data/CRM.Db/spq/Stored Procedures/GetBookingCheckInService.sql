
CREATE PROCEDURE [spq].[GetBookingCheckInService] 
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        SELECT
            RowID = RowId ,
            wBookingRid ,
            wBookDt ,
            wExpAmt ,
            wTotalAmt ,
            wPaymentMethod ,
            wReceiptNo ,
            wCurrCode ,
            wExtraFee ,
            wRemark ,
            wCrtBy ,
            wCrtDt ,
            wTicketCollectionRid ,
            wBookingDateRid ,
            wServiceCounterRid ,
            wOrderNo ,
            wUpdBy ,
            wUpdDt ,
            wSupplier ,
            wRelatedOrderNo ,
            wArrivalTimeToG15nG16 ,
            wNoOfBaggage ,
            wPassengerName ,
            wPassengerPhoneTel ,
            wVIPRoom ,
            wVIPRoomPrice ,
            wUnitPrice ,
            wQuantity ,
            wCost ,
            wSeatRequest ,
            wAdditionalFee ,
            wCheckInRemarks ,
            wFlightNo ,
            wDepartAirport ,
            wDestination ,
            wDepartDt ,
            wArrivalDt ,
            wUnqualifiedRid ,
            wBookingStatus ,
            wOldBookingStatus = wBookingStatus, -- Update时，Record获取与保存，DB的前后两次状态是否发生变化，如果发生变化，不能Save（可能预订已经被另外一个用户确认过，同时只能有一个用户可以做状态转换保存）
            wStatus
        FROM dbo.eBookingCheckInService
        WHERE @pRowID = RowId;                                                 
    END;