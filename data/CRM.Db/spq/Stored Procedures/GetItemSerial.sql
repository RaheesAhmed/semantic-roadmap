
CREATE PROCEDURE [spq].[GetItemSerial]
    @pRowID BIGINT ,
    @pLang VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

		SET @pLang = LOWER(@pLang);
	
        SELECT  is_t.RowID ,
                is_t.wItemRid ,
                is_t.wPurchaseRid ,
                is_t.wSerialNo ,
                p.wLotNo ,
                is_t.wStatus ,
                is_t.wCrtBy ,
                is_t.wCrtDt ,
                CASE WHEN @pLang = 'en-gb' THEN u_c.wName
                     ELSE u_c.wCName
                END AS wCrtByName ,
                is_t.wUpdBy ,
                is_t.wUpdDt ,
                CASE WHEN @pLang = 'en-gb' THEN u_u.wName
                     ELSE u_u.wCName
                END AS wUpdByName ,
                'N' AS RecordState
        FROM    dbo.mItemSerial is_t
                LEFT JOIN RollsMary.dbo.mUsr u_c ON u_c.RowID = is_t.wCrtBy
                LEFT JOIN RollsMary.dbo.mUsr u_u ON u_u.RowID = is_t.wUpdBy
                INNER JOIN dbo.ePurchase p ON p.RowID = is_t.wPurchaseRid
        WHERE   @pRowID = is_t.RowID;                                                 
    END;