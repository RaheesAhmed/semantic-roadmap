--sp_helptext '[spq].[GetPassengerTravelDocs]'

CREATE PROCEDURE [spq].[GetPassengerTravelDocs]
    @pBookingRid BIGINT = NULL ,
    @pPassengerRid BIGINT = NULL ,
    @pRoomBookingRid BIGINT = NULL ,
    @pLangCd VARCHAR(10) = 'en-gb' ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN 
	-- SET NOCOUNT ON added to prevent extra result sets from 
        SET NOCOUNT ON;
        IF @pRoomBookingRid IS NOT NULL
            AND @pRoomBookingRid > 0
            BEGIN
                WITH    tResult
                          AS ( SELECT   PSDT.[RowID] ,
                                        PSDT.[wPassengerDetailsRid] ,
                                        PSDT.[wPersonTravelDocRid] ,
                                        PSDT.[wUpdDt] ,
                                        PSDT.[wUpdBy]
                               FROM     [dbo].[ePassengerTravelDocDetail] (NOLOCK) PSDT
                                        INNER JOIN ( SELECT *
                                                     FROM   dbo.ePassengerDetails (NOLOCK)
                                                     WHERE  ( @pPassengerRid IS NULL
                                                              OR RowID = @pPassengerRid
                                                            )
                                                            AND ( @pRoomBookingRid IS NULL
                                                              OR wRoomBookingRid = @pRoomBookingRid
                                                              )
                                                            AND wStatus = 'A'
                                                   ) PSD ON PSD.RowID = PSDT.wPassengerDetailsRid
                             ),
                        tCount
                          AS ( SELECT   wRecordCount = COUNT(1)
                               FROM     tResult
                             )
                    SELECT  tResult.* ,
                            wRecordCount
                    FROM    tResult ,
                            tCount
                    ORDER BY [wUpdDt] DESC
                            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
		FETCH NEXT @pPageSize ROWS ONLY;  
            END;
        ELSE
            BEGIN
                WITH    tResult
                          AS ( SELECT   PSDT.[RowID] ,
                                        PSDT.[wPassengerDetailsRid] ,
                                        PSDT.[wPersonTravelDocRid] ,
                                        PSDT.[wUpdDt] ,
                                        PSDT.[wUpdBy]
                               FROM     [dbo].[ePassengerTravelDocDetail] (NOLOCK) PSDT
                                        INNER JOIN ( SELECT *
                                                     FROM   dbo.ePassengerDetails (NOLOCK)
                                                     WHERE  ( @pBookingRid IS NULL
                                                              OR wBookingRid = @pBookingRid
                                                            )
                                                            AND ( @pPassengerRid IS NULL
                                                              OR RowID = @pPassengerRid
                                                              )
                                                   ) PSD ON PSD.RowID = PSDT.wPassengerDetailsRid
                                                            AND wStatus = 'A'
                             ),
                        tCount
                          AS ( SELECT   wRecordCount = COUNT(1)
                               FROM     tResult
                             )
                    SELECT  tResult.* ,
                            wRecordCount
                    FROM    tResult ,
                            tCount
                    ORDER BY [wUpdDt] DESC
                            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
		FETCH NEXT @pPageSize ROWS ONLY;
            END;
    END;