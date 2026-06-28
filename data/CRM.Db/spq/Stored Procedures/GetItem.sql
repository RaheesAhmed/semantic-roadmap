
	CREATE PROCEDURE [spq].[GetItem]
		@pRowID BIGINT
	AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT i_t.RowID, i_t.wCategoryRid, i_t.wCName, i_t.wEName, i_t.wPrice, i_t.wCurrCode, i_t.wBarcode, i_t.wIsSerialItem, i_t.wStatus, i_t.wCrtDt, i_t.wUpdDt, 'N' AS RecordState  FROM dbo.mItem i_t
		WHERE @pRowID = i_t.RowID                                                 
    END;