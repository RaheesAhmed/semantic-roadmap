
CREATE FUNCTION [dbo].[fnGetAgentType](
    @pLangCd    VARCHAR(10) = 'zh-TW'
)
RETURNS @vAgentType TABLE(
    wCode       VARCHAR(30) PRIMARY KEY,
    wTitle      NVARCHAR(50),
    wBackground CHAR(7),
    wForeground CHAR(7),
    wSeqNo      INT
)
AS
    BEGIN
        INSERT INTO @vAgentType(wCode, wTitle, wBackground, wForeground, wSeqNo)
        VALUES  ('SHARE',                N'股東',         '#b9a46d',    '#fefefe', 1),
                ('SEC_SHARE',            N'二線股東',     '#b9a46d',    '#fefefe', 2),
                ('AGENT',                N'代理',         '#55b85d',    '#fefefe', 3),
                ('CREDIT_AGENT',         N'批額代理',     '#55b85d',    '#fefefe', 4),
                ('GAMBLERS',             N'玩家',         '#f460b5',    '#fefefe', 5),
                ('CREDIT_GAMBLERS',      N'批額玩家',     '#f460b5',    '#fefefe', 6),
                ('SEC_AGENT',            N'二線代理',     '#39d1db',    '#fefefe', 7),
                ('SEC_CREDIT_AGENT',     N'二線批額代理', '#39d1db',    '#fefefe', 8),
                ('SEC_GAMBLERS',         N'二線玩家',     '#39d1db',    '#fefefe', 9),
                ('SEC_CREDIT_GAMBLERS',  N'二線批額玩家', '#39d1db',    '#fefefe', 10);
        RETURN;
    END