CREATE PROCEDURE [spq].[GetAdviceRefNoLst] 
AS
    BEGIN
        SET NOCOUNT ON;
	
        SELECT  a.wRefNo ,
                a.RowID
        FROM    dbo.eAdvice a
        WHERE   a.wRefNo IS NOT NULL AND a.wRefNo!='' AND wStatus='A'
        ORDER BY a.wRefNo ASC;	
	

    END;