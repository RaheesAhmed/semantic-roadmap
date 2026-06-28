-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [spq].[GetShowTicketPriceByBookingShowId] --19000000010029,19000000010038
    (
      @pShowId BIGINT ,
      @pBookingShowId BIGINT = NULL		
	)
AS -- sample call
-- exec [spq].[GetShowTicketPriceByBookingShowId] 90000000001007,90000000001699
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
   
        IF ISNULL(@pBookingShowId, 0) > 0
            BEGIN 
                SELECT
                    mstp.RowID ,
                    mstp.wShowRid ,
                    mstp.wTicketType ,
                    -- mstp.wAmount NUMERIC(18,2)、ebstd.wAmount NUMERIC(18,4) 数据类型不一致，UnitTest失败
                    wAmount = ISNULL(CASE WHEN ebs.wBookingStatus = 'P' THEN (CAST(mstp.wAmount AS NUMERIC(18,4))) ELSE ebstd.wAmount END, 0), -- P狀態下load最新票務，其他狀態load舊票務
                    wCost = ISNULL(CASE WHEN ebs.wBookingStatus = 'P' THEN (CAST(mstp.wCost AS NUMERIC(18,4))) ELSE ebstd.wCost END, 0),
                    mstp.wCurrCode ,
                    wQuantity = ISNULL(ebstd.wQuantity, 0) ,
                    wBookingShowRid = ebs.RowID ,
                    wShowTicketPriceRid = mstp.RowID ,
                    mstp.RowID AS wBookingShowTicketRid ,
                    ISNULL(ebstd.wAmount, 0) AS wUpdatedAmount ,
                    ISNULL(ebstd.wCost, 0) AS wUpdatedCost ,
                    mstp.wSeqNo ,
                    mstp.wCrtDt ,
                    mstp.wCrtBy ,
                    mstp.wUpdDt ,
                    mstp.wUpdBy
                FROM dbo.eBookingShow ebs
                INNER JOIN dbo.mShowTicketPrice mstp ON ebs.wShowRid = mstp.wShowRid
                LEFT JOIN dbo.eBookingShowTicket ebstd ON ebstd.wBookingShowRid = ebs.RowID AND mstp.RowID = ebstd.wShowTicketPriceRid
                WHERE ebs.RowID = @pBookingShowId
            END
        ELSE
            BEGIN
                SELECT
                    mstp.RowID ,
                    mstp.wShowRid ,
                    mstp.wTicketType ,
                    wAmount =CAST(mstp.wAmount AS NUMERIC(18,4)) ,
                    wCost = CAST(mstp.wCost AS NUMERIC(18,4)) ,
                    mstp.wCurrCode ,
                    0 AS wQuantity ,
                    CAST(0 AS BIGINT) AS wBookingShowRid ,
                    mstp.RowID AS wShowTicketPriceRid ,
                    CAST(0 AS BIGINT) AS wBookingShowTicketRid ,
                    wUpdatedAmount = CAST(0 AS NUMERIC(18, 4)) ,
                    wUpdatedCost = CAST(0 AS NUMERIC(18, 4)) ,
                    mstp.wSeqNo ,
                    mstp.wCrtDt ,
                    mstp.wCrtBy ,
                    mstp.wUpdDt ,
                    mstp.wUpdBy
                FROM dbo.mShowTicketPrice mstp
				INNER JOIN dbo.mShow ms ON ms.RowID = mstp.wShowRid
                WHERE mstp.wShowRid = @pShowId
            END
    END