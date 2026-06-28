CREATE PROCEDURE [spq].[GeteVoucher]
    (
       @pwBookingRid  bigint
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
       SELECT  
		v.RowID,
		v.wVoucherRid,
		v.wVoucherNo,
		v.wVoucherType,
		v.wAmount,
		msc.wName AS wServiceCounterName,
		v.wCounterRid wServiceCounterRid,
		v.wBookingRid,
		(CASE WHEN mclg.wLineGrpCompEName <> '' THEN ISNULL(mclg.wLineGrpCompEName,'') ELSE ISNULL(mclg.wLineGrpCompCName,'') END) AS wLineGrp,
		v.wCurrCode,
		v.wRemark,
		v.wTicketType,
		v.wSeqNo,
		v.wStatus,
		v.wCrtDt,
		v.wCrtBy,
		v.wUpdDt,
		v.wUpdBy
        FROM    dbo.eVoucher v         
		inner join dbo.eBooking eb on eb.RowID = v.wBookingRid
		Left join dbo.mVoucher m on m.RowID = v.wVoucherRid
		Left join dbo.mServiceCounter msc on msc.RowID = m.wCounterRID
		LEFT JOIN [RollsMary].[dbo].mCompanyLineGrp mclg ON mclg.RowID =  m.wCorporateRID AND mclg.wExpireYearMth = '' AND mclg.wLineGrp != ''
		WHERE   
		( @pwBookingRid = ''
            OR @pwBookingRid IS NULL
            OR @pwBookingRid = v.wBookingRid
        );

    END;