CREATE PROCEDURE [spq].[GetAllotmentTicket]
    (
      @pwBookingRid BIGINT ,
      @pwLangCd VARCHAR(20) = 'en-GB'
    )
AS
    BEGIN

        IF @pwLangCd = ''
            OR @pwLangCd = NULL
            SET @pwLangCd = 'en-GB';

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
        SELECT  at.RowID ,
                at.wTicketNo ,
                at.wCounterRid ,
                at.wExpiryDate ,
                at.wTicketType as TicketTypeCode,
                at.wRouteRid ,
                at.wClassCd wBookingClassCd ,
                at.wAmount ,
                at.wAllotmentStatus wTicketStatus ,
                at.wBookingRid ,
                at.wCrtDt ,
                at.wCrtBy ,
                at.wUpdDt ,
                at.wUpdBy ,
                lpty.wTitle wTicketType ,
                r.wRouteFrom + ' to ' + r.wRouteTo wRoute ,
                lpfc.wTitle wFerryClass ,
                at.wSvCtrCode
        FROM    dbo.eAllotmentTicket at --INNER JOIN dbo.eAllotmentsofFerryRecord afr ON afr.RowID = at.wCounterRid
                INNER JOIN dbo.eBooking eb ON eb.RowID = at.wBookingRid
                                              AND at.wStatus = 'A'
                INNER JOIN dbo.mLookUp lpty ON lpty.wCode = at.wTicketType
                                               AND lpty.wLangCd = @pwLangCd
                                               AND lpty.wType = 'FERRY_TICKET_TYPE'
                LEFT JOIN dbo.mRoute r ON r.RowID = at.wRouteRid
                INNER JOIN dbo.mLookUp lpfc ON lpfc.wCode = at.wClassCd
                                               AND lpfc.wLangCd = @pwLangCd
                                               AND lpfc.wType = 'FERRY_CLASS'
        WHERE   ( @pwBookingRid = ''
                  OR @pwBookingRid IS NULL
                  OR @pwBookingRid = at.wBookingRid
                );

    END;