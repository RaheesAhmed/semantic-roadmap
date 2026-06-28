
CREATE VIEW [vipRpt].[vwMLookup]
AS
    SELECT        wType ,
                  wCode ,
                  wLangCd ,
                  wTitle 
	FROM          dbo.mLookUp