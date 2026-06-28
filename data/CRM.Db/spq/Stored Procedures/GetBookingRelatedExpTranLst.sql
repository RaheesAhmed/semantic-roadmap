-- 各Booking 用的 User Conntrol, 用來顯示番該預訂的相關消費
CREATE PROCEDURE [spq].[GetBookingRelatedExpTranLst]
    @pBookingRid BIGINT,
	@pBookingRoomRid	BIGINT, -- 房間好特別, 唔可以用 wBookingRid 來睇, 客戶要求逐間房睇
    @pLangCd VARCHAR(10),
    @pStatus CHAR(1)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   

		DECLARE @sBookingRidStr AS VARCHAR(40);
		SET @sBookingRidStr = CAST(@pBookingRid AS VARCHAR(40));

        SELECT  et.RowID ,
                et.wDate ,
                et.wCurDateTime ,
                et.wRemark ,
                et.wAmount ,
                et.wIsDeposit ,
                et.wIsDepositDone ,
                et.wUpdDt ,
                a.wAgentCode_Display ,
                a.wAgentCodeIn ,
                wUpdByName = CASE WHEN @pLangCd = 'en-GB' THEN u.wName
                                  ELSE u.wCName
                             END
        FROM    RollsMary.dbo.eExpTran et
                INNER JOIN RollsMary.dbo.mAgent a ON et.wAgentCodeIn = a.wAgentCodeIn
                LEFT JOIN RollsMary.dbo.mUsr u ON et.wUpdBy = u.RowID
        WHERE
				et.wReferId IS NOT NULL 
			AND  
				et.wReferId != '0'
			AND
				et.wReferId = @sBookingRidStr 
			AND 
				@sBookingRidStr != '' AND @sBookingRidStr!='0'
			AND
				(@pBookingRoomRid <= 0 OR et.wRefRid = @pBookingRoomRid)
			AND
				et.wExpGroup IN ('CRM','RCRM')
			ORDER BY 
				et.wCurDateTime DESC
			OPTION (RECOMPILE);
    END;