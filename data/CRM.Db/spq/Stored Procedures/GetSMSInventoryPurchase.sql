
CREATE PROCEDURE [spq].[GetSMSInventoryPurchase]
(
    @pPurchaseRid BIGINT ,
    @pGuid VARCHAR(50) ,
    @pLangCd VARCHAR(30) = 'zh-TW'
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @@trancount = 0
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      

    SET @pPurchaseRid = ISNULL(IIF(@pPurchaseRid <= 0, NULL, @pPurchaseRid), 0);
    SET @pLangCd = LOWER(ISNULL(NULLIF(@pLangCd, ''), 'zh-TW'));
		
    DECLARE @sAgentCodeIn VARCHAR(14);
    DECLARE @sDeptFollowUsr NVARCHAR(MAX);

    SELECT @sAgentCodeIn = wAgentCodeIn FROM dbo.ePurchase WHERE RowID=@pPurchaseRid;

    WITH tDeptUsr AS (
        SELECT
            raf.wAgentCodeIn,
            wDeptCode = rd.wCode,
            wFollowUsr = STUFF((
                SELECT CONCAT('\r\n','(', t.wName, ')', u.wCName, '(', 'user://', u.wUsrId, ')', IIF(NULLIF(u.wPrivateTel, '') IS NULL, NULL, '\r\n' + IIF(NULLIF(u.wPrivateTelCountryCode, '') IS NULL, NULL, '+' + REPLACE(u.wPrivateTelCountryCode, '+', '') + '-') + u.wPrivateTel), IIF(safd.wIsMainInCharge = 'Y', N'(主)', NULL))
                FROM RollsMary.dbo.mAgentFollow AS saf
                INNER JOIN RollsMary.dbo.mAgentFollowDtl AS safd ON safd.wAgentFollowRid = saf.RowID
                INNER JOIN RollsMary.dbo.mDepartment AS sd ON sd.RowID = saf.wDeptRid
                INNER JOIN RollsMary.dbo.mUsr AS u ON u.RowID = safd.wUsrRid
                INNER JOIN RollsMary.dbo.mTeam AS t ON t.RowId = saf.wTeamRid
                WHERE saf.wStatus = 'A' 
                    AND safd.wStatus = 'A'
                    AND NULLIF(sd.wUserLineGrp, '') IS NULL
                    AND NULLIF(saf.wYearMth, '') IS NULL
                    AND NULLIF(safd.wYearMth, '') IS NULL
                    AND saf.wAgentCodeIn = raf.wAgentCodeIn
                    AND sd.wCode = rd.wCode
                FOR XML PATH('')), 1, 4, N'')
        FROM RollsMary.dbo.mAgentFollow AS raf
        INNER JOIN RollsMary.dbo.mAgentFollowDtl AS rafd ON rafd.wAgentFollowRid = raf.RowID
        INNER JOIN RollsMary.dbo.mDepartment AS rd ON rd.RowID = raf.wDeptRid
        WHERE raf.wStatus = 'A' 
            AND rafd.wStatus = 'A'
            AND NULLIF(rd.wUserLineGrp, '') IS NULL
            AND NULLIF(raf.wYearMth, '') IS NULL
            AND NULLIF(rafd.wYearMth, '') IS NULL
            AND raf.wAgentCodeIn = @sAgentCodeIn 
            AND rd.wCode IN ('DEVELOP', 'HOUSEKEEPER') -- MD、VIP
        GROUP BY raf.wAgentCodeIn, rd.wCode
    )

    SELECT @sDeptFollowUsr = STUFF((SELECT CONCAT('\r\n', CASE wDeptCode WHEN 'DEVELOP' THEN N'MD跟進：\r\n' WHEN 'HOUSEKEEPER' THEN N'VIP-R跟進：\r\n' END, wFollowUsr) FROM tDeptUsr FOR XML PATH('')), 1, 4, N'')
        
    SELECT
        eph.wAgentCodeIn,
        wReqAgentCode_Display = a_r.wAgentCode_Display,
        wReqAgentName = CASE WHEN @pLangCd = 'en-gb' THEN a_r.wEName ELSE a_r.wCName END,
        wServiceCounterName = sc_debit.wName,
        wExpensesType = CASE WHEN @pLangCd = 'en-gb' THEN 'Extra Expenses' ELSE N'外消費' END,
        wItemName = CASE WHEN @pLangCd = 'en-gb' THEN item.wEName ELSE item.wCName END,
        wCategoryName = CASE WHEN @pLangCd = 'en-gb' THEN category.wEName ELSE category.wCName END,
        wQty = dtl.wStockInQty,
        wTotal=Convert(DECIMAL(18,2),dtl.wUnitCost * dtl.wStockInQty),
        wArrivalTime = eph.wUpdDt,
        wFollowByName = @sDeptFollowUsr ,
        wFollowByTel = '',
        wContent = '',
        wTelNo = a_r.wTelSMS,
        wReqlink = 'rollsmary://'+ eph.wAgentCodeIn,
        wFollowlink = ''
    FROM dbo.ePurchase eph
    INNER JOIN dbo.ePurchaseDtl dtl ON eph.RowID = dtl.wPurchaseRid
    LEFT JOIN dbo.mItem item ON item.RowID =dtl.wItemRid
    LEFT JOIN dbo.mItemCategory category ON item.wCategoryRid = category.RowID
    LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = eph.wAgentCodeIn      
    LEFT JOIN dbo.mWarehouse house ON eph.wInWarehouseRid = house.RowID
    LEFT JOIN CRM.dbo.mServiceCounter sc_debit ON sc_debit.RowID = house.wCounterRid
    WHERE eph.RowID = @pPurchaseRid
    
    END;