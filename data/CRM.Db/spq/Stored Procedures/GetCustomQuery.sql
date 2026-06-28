
CREATE PROCEDURE [spq].[GetCustomQuery] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
		
        WITH    cteFilter
                  AS ( SELECT   cqf.wCustomQueryRid ,
                                cqf.wFilterCode ,
                                cqf.wIsVisible ,
                                cqf.wDefaultValue
                       FROM     dbo.mCustomQueryFilter cqf
                       WHERE    cqf.wCustomQueryRid = @pRowID
                     ),
                cteColumn
                  AS ( SELECT   cqc.wCustomQueryRid ,
                                cqc.wColumnCode ,
                                cqc.wIsVisible ,
                                cqc.wAllowSelect ,
                                cqc.wAllowSortAcsc ,
                                cqc.wAllowSortDesc
                       FROM     dbo.mCustomQueryColumn cqc
                       WHERE    cqc.wCustomQueryRid = @pRowID
                     )
            SELECT  cq_t.RowID ,
                    cq_t.wQueryCd ,
                    cq_t.wQueryName ,
                    cq_t.wQueryCategory ,                    
                    '|'
                    + STUFF(( SELECT    '|' + c.wColumnCode + ','
                                        + c.wIsVisible + ',' + c.wAllowSelect
                                        + ',' + c.wAllowSortAcsc + ','
                                        + c.wAllowSortDesc
                              FROM      cteColumn c
                            FOR
                              XML PATH('')
                            ), 1, 1, '') + '|' AS wColumnListStr ,
                    '|'
                    + STUFF(( SELECT    '|' + f.wFilterCode + ','
                                        + f.wIsVisible + ',' + f.wDefaultValue
                              FROM      cteFilter f
                            FOR
                              XML PATH('')
                            ), 1, 1, '') + '|' AS wFilterListStr ,
                    cq_t.wStatus ,
                    cq_t.wCrtBy ,
                    cq_t.wCrtDt ,
                    cq_t.wUpdBy ,
                    cq_t.wUpdDt ,
                    'N' AS RecordState
            FROM    dbo.mCustomQuery cq_t
            WHERE   @pRowID = cq_t.RowID;                                                 
    END;