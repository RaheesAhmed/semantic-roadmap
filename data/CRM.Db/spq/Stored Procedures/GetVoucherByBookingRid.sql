CREATE PROCEDURE [spq].[GetVoucherByBookingRid]
    @pBookingRid BIGINT
AS
    BEGIN
        SET NOCOUNT ON;
	
        SELECT
            v.RowID ,
            v.wVoucherRid ,
            v.wVoucherNo ,
            v.wVoucherType ,
            v.wAmount ,
            wServiceCounterName = msc.wName ,
            wServiceCounterRid = v.wCounterRid ,
            v.wBookingRid ,
            wLineGrp = ISNULL(ISNULL(NULLIF(mclg.wLineGrpCompEName, ''), mclg.wLineGrpCompCName), ''),
            v.wCurrCode ,
            v.wRemark ,
            v.wTicketType ,
            v.wSeqNo ,
            v.wStatus ,
            v.wCrtDt ,
            v.wCrtBy ,
            v.wUpdDt ,
            v.wUpdBy
        FROM dbo.eVoucher v
        INNER JOIN dbo.eBooking eb ON eb.RowID = v.wBookingRid
        LEFT JOIN dbo.mVoucher m ON m.RowID = v.wVoucherRid
        LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = m.wCounterRID
        LEFT JOIN [RollsMary].[dbo].mCompanyLineGrp mclg ON mclg.RowID = m.wCorporateRID AND mclg.wExpireYearMth = '' AND mclg.wLineGrp != ''
        WHERE @pBookingRid = v.wBookingRid
    END;