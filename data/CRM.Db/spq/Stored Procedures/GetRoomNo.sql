CREATE PROCEDURE [spq].[GetRoomNo]
    (
      @pFromDt DATETIME2 ,
      @pToDt DATETIME2 ,    
      @pHotelRid BIGINT ,  
      @pRoomNo NVARCHAR(20),
	  @pBookingRoomId BIGINT
	   
    )
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
				
			SELECT  count(*) as wCount
            FROM dbo.eBookingRoom ebr
			WHERE   (					
					 (
						 @pFromDt < ebr.wStartDate
						AND ebr.wStartDate < @pToDt
					 )					 
					 OR
					 (
						 @pFromDt < ebr.wEndtDate
						AND ebr.wEndtDate < @pToDt
					 )
					 OR
					 (
						ebr.wStartDate <= @pFromDt
						AND ebr.wEndtDate >= @pToDt
					 )
					OR
					 (
						ebr.wStartDate >= @pFromDt
						AND ebr.wEndtDate <= @pToDt
					 )
					)
					AND ( @pHotelRid <= 0
                         OR @pHotelRid = ebr.wHotelRid
                    )                            
                    AND ( @pRoomNo = ''
                          OR @pRoomNo = ebr.wRoomNo
                    ) 
					AND ( wbookingstatus='P' OR wbookingstatus='C' OR 
						  wbookingstatus='CI'  
					)
					AND(
						@pBookingRoomId<=0
						 OR @pBookingRoomId != ebr.RowID
					)                            
    END;