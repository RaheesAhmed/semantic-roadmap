CREATE PROC [spq].[GetDeptRoomOptionLst]
    @pLangCd    VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        ------------------------------------------------
        --DECLARE @vResult TABLE (wValue XML);

        --SELECT * FROM @vResult;
        ------------------------------------------------

        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');

        DECLARE @vXML       XML,
                @vResultXML XML;

        SET @vResultXML = N'<OptionLst />';

        -- Agent Account Type
        -------------------------------------------------------------
        SET @vXML = (
            SELECT wCode,
                   wTitle,
                   wBackground,
                   wForeground,
                   wSeqNo 
            FROM dbo.fnGetAgentAccountType(@pLangCd)
            FOR XML RAW ('AccountType'), ROOT('AccountTypeLst')
        );

        IF @vXML IS NOT NULL
            SET @vResultXML.modify('insert sql:variable("@vXML") into (OptionLst)[1]');

        -- Agent Type
        -------------------------------------------------------------
        SET @vXML = (
            SELECT  wCode,
                    wTitle,
                    wBackground,
                    wForeground,
                    wSeqNo
            FROM dbo.fnGetAgentType(@pLangCd) 
            FOR XML RAW('AgentType'), ROOT('AgentTypeLst')
        );

        IF @vXML IS NOT NULL
            SET @vResultXML.modify('insert sql:variable("@vXML") into (OptionLst)[1]');

        -- Agent Identity Type
        -------------------------------------------------------------
        SET @vXML = (
            SELECT wCode,
                   wTitle,
                   wBackground,
                   wForeground,
                   wSeqNo 
            FROM dbo.fnGetAgentIdentityType(@pLangCd) 
            FOR XML RAW('IdentityType'), ROOT('IdentityTypeLst')
        );

        IF @vXML IS NOT NULL
            SET @vResultXML.modify('insert sql:variable("@vXML") into (OptionLst)[1]');
        -------------------------------------------------------------

        SELECT wValue = @vResultXML;
    END