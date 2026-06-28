CREATE PROCEDURE [spq].[GetHotelRequestPriorityHotels]
    (
      @pLangCd VARCHAR(10) ,
      @pHotelRequestRid BIGINT
    )
AS
    BEGIN
        SET NOCOUNT ON;
        SELECT  RTDTL.RowID ,
                RTDTL.wHotelCode ,
                RTDTL.wPriority ,
                RTDTL.wCounterRid
        FROM    dbo.eHotelRequestDtl (NOLOCK) RTDTL
        WHERE   wHotelRequestRid = @pHotelRequestRid;
    END;