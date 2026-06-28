CREATE PROC [spq].[GetAgentPortraitForDeptRoom]
    @pAgentCodeIn VARCHAR(14),
    @pSizeType    CHAR(1)
AS
    BEGIN
        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pSizeType    = NULLIF(@pSizeType, '');

        SELECT TOP(1) wAgentPortrait = wFileData
        FROM RollsMary_Doc.dbo.eDocument
        WHERE wStatus = 'A' 
            AND wType = 'PHOTO' 
            AND wCategory = 'AGENT' 
            AND wRefTable = 'mAgent'
            AND @pAgentCodeIn = wRefRID 
            AND @pSizeType = wSizeType
        ORDER BY wUpdDt DESC;
    END;