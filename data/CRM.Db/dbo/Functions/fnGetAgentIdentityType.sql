CREATE FUNCTION [dbo].[fnGetAgentIdentityType](
    @pLangCd    VARCHAR(10) = 'zh-TW'
)
RETURNS @vAgentIdentityType TABLE(
    wCode       VARCHAR(30) PRIMARY KEY,
    wTitle      NVARCHAR(50),
    wBackground CHAR(7),
    wForeground CHAR(7),
    wSeqNo      INT
)
AS
    BEGIN
        INSERT INTO @vAgentIdentityType(wCode, wTitle, wBackground, wForeground, wSeqNo)
        VALUES  ('BLACK_LIST',          N'黑名單',       '#000000',    '#ffffff', 1),
                ('BOSS_SPECIAL',        N'老闆特批',     '#836fff',    '#ffffff', 2),
                ('CELEBRITY',           N'名人',         '#000000',    '#f4eb72', 3),
                ('CHG_LINE_SUSPEND',    N'轉線停用',     '#7f7f7f',    '#ffffff', 4),
                ('COMPANY_ACCT',        N'公司戶口',     '#3493B3',    '#ffffff', 5),
                ('CONTACT_FAIL',        N'通訊失效',     '#7f7f7f',   '#ffffff', 6),
                ('DENY_CONTACT',        N'拒絕接觸',     '#808080',    '#ffffff', 7),
                ('DONT_CONTACT',        N'不打擾接觸',   '#7f7f7f',    '#ffffff', 8),
                ('EXP_BOSS_SPECIAL',    N'消費特批',     '#241535',    '#ffffff', 9),
                ('HEAD',                N'人頭戶',       '#a2445f',    '#ffffff', 10),
                ('HIGHLY_VALUED',       N'高度重視',     '#000000',    '#FABB28', 11),
                ('NORMAL',              N'正常',         '#33cccc',    '#ffffff', 12),
                ('RELATED_USE',         N'關連使用',     '#a2445f',    '#ffffff', 13),
                ('SMALL_CREDIT',        N'小額',         '#ff00ff',    '#ffffff', 14),
                ('SPECIAL_ACCT',        N'特殊戶口',     '#6699ff',    '#ffffff', 15),
                ('STAR',                N'星級',         '#6600ff',    '#ffffff', 16);
        RETURN;
    END