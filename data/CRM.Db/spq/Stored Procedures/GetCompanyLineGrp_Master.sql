
CREATE PROCEDURE [spq].[GetCompanyLineGrp_Master]
AS
    BEGIN
        SET NOCOUNT ON;

        WITH    tResult
                  AS ( SELECT   clp.RowID ,
                                clp.wLineGrp ,
                                wLineGrpCompCName = MAX(clp.wLineGrpCompCName) ,
                                wLineGrpCompEName = MAX(clp.wLineGrpCompEName)
                       FROM     RollsMary.dbo.mCompanyLineGrp clp
                       WHERE    clp.wExpireYearMth = ''
                                AND clp.wLineGrp != ''
                       GROUP BY clp.wLineGrp ,
                                RowID
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY tResult.wLineGrp;
    END;