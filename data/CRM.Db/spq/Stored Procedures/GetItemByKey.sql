
CREATE PROCEDURE [spq].[GetItemByKey]
    @pBarcode VARCHAR(1000) ,
    @pSerialNum VARCHAR(100)
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
		
        SET @pBarcode = ISNULL(@pBarcode, '');
        SET @pSerialNum = ISNULL(@pSerialNum, '');

        SELECT  i_t.RowID ,
                i_t.wCategoryRid ,
                i_t.wCName ,
                i_t.wEName ,
                i_t.wPrice ,
                i_t.wCurrCode ,
                i_t.wBarcode ,
                i_t.wIsSerialItem ,
                i_t.wCrtDt ,
                i_t.wUpdDt ,
                is_t.wPurchaseRid ,
                is_t.wSerialNo ,
                wLotNo = RIGHT(p.wLotNo, LEN(p.wLotNo) - 7),
                p.wBatchNo,
                wCategoryCName = i_c.wCName,
                wCategoryEName = i_c.wEName
        FROM    dbo.ePurchase p
                RIGHT JOIN dbo.mItemSerial is_t ON is_t.wPurchaseRid = p.RowID
                RIGHT JOIN dbo.mItem i_t ON i_t.RowID = is_t.wItemRid
                LEFT JOIN dbo.mItemCategory i_c ON i_c.RowID = i_t.wCategoryRid
        WHERE   ( @pBarcode = ''
                  OR ( i_t.wBarcode = @pBarcode
                       AND i_t.wStatus = 'A'
                     )
                )
                AND ( @pSerialNum = ''
                      OR ( is_t.wSerialNo = @pSerialNum
                           AND i_t.wStatus = 'A'
                         )
                    );
    END;