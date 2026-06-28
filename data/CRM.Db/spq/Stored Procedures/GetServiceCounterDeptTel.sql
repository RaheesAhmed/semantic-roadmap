CREATE PROCEDURE [spq].[GetServiceCounterDeptTel]
    @pRowID BIGINT ,   --獲取服務櫃檯部門電話
    @pDeptCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

       SET @pRowID = ISNULL(@pRowID, 0);
       SET @pDeptCd = ISNULL(@pDeptCd, '');
       
       SELECT  sc.RowID,
               ISNULL(scc.wTel,'') AS wServiceCounterTel,
               scc.wDepartmentCode
       FROM    CRM.dbo.mServiceCounter sc
               LEFT JOIN CRM.dbo.mServiceCounterContact scc ON scc.wSeriverCounterRid = sc.RowID AND scc.wContactType = 'CSSMS' 
       WHERE   (@pRowID = 0 OR sc.RowID = @pRowID) AND (@pDeptCd = '' OR scc.wDepartmentCode = @pDeptCd);

    END;