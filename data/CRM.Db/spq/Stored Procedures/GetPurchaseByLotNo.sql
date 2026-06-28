
CREATE PROCEDURE [spq].[GetPurchaseByLotNo] 
    @pLotNo VARCHAR(50),
    @pLang VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        SET @pLang = LOWER(ISNULL(@pLang, ''));
	
        SELECT  p_t.RowID ,
                p_t.wLotNo ,
                p_t.wNotifier,
                p_t.wTelephone,
                p_t.wType ,
                l.wTitle AS wTypeName ,
                p_t.wInWarehouseRid ,
                CASE WHEN @pLang = 'en-gb' THEN w_t.wEName
                                     ELSE w_t.wCName
                                END AS wInWarehouseName ,
                p_t.wStoreLocation ,
                p_t.wNoticeRecord ,
                p_t.wRemarks 
        FROM    dbo.ePurchase p_t
                LEFT JOIN dbo.mLookUp l ON p_t.wType = l.wCode AND l.wType = 'PURCHASE_TYPE' AND l.wLangCd = @pLang AND l.wStatus = 'A'
                LEFT JOIN dbo.mWarehouse w_t ON w_t.RowID = p_t.wInWarehouseRid 
        WHERE   @pLotNo = p_t.wLotNo;                                                 
    END;