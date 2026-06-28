CREATE PROCEDURE [spq].[GetCRMDBLookup] ( @pLangCd VARCHAR(10) )
AS
    BEGIN
        SET NOCOUNT ON;
        
        SELECT  ml.wTitle ,
                ml.wType ,
                ml.wCode ,
                ml.wParentCode ,
                ml.wDescr ,
                ml.wStatus,
                ml.wCanEdit,
                ml.wCanSelect
        FROM    mLookUp ml
        WHERE   ml.wLangCd = IIF(@pLangCd='en-us','en-GB',@pLangCd)
        ORDER BY ml.wType, ml.wSeqNo;
    END;