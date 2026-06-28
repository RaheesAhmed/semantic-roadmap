CREATE PROCEDURE [spq].[GetShiftPeriodByDepartment]
    @pwDepartment VARCHAR(30)
AS
    BEGIN  
        SELECT  ms.RowID ,
                ms.wDepartmentCd ,
                ms.wName,
                ms.wStatus
        FROM    [dbo].[mShift] ms
        WHERE   ms.wDepartmentCd = @pwDepartment;
    END;