
CREATE PROC [spq].[GetDocumentForVIP]
    @pRefRid BIGINT,
    @pRefTable VARCHAR(100)
AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            RowID,
            wCompNo,
            wCageCodeIn,
            wRefRID,
            wRefTable,
            wFileData,
            wDocName,
            wDocExt,
            wType,
            wCategory,
            wDesc,
            wStatus,
            wSysRemark,
            wUpdBy,
            wUpdDt,
            wSizeType,
            wRecordState = 'U'
        FROM CRM_Doc.dbo.eDocument
        WHERE wRefTable = @pRefTable
            AND wRefRID = @pRefRid
            AND wStatus = 'A'
    END;