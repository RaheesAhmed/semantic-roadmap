CREATE FUNCTION [dbo].[fnGetAgentAccountType](
    @pLangCd    VARCHAR(10) = 'zh-TW'
)
RETURNS @vAccountType TABLE(
    wCode       VARCHAR(30) PRIMARY KEY,
    wTitle      NVARCHAR(50),
    wBackground CHAR(7),
    wForeground CHAR(7),
    wSeqNo      INT
)
AS
    BEGIN
        INSERT INTO @vAccountType(wCode, wTitle, wBackground, wForeground, wSeqNo)
        VALUES  -- old
                ('1',	N'太陽客戶', '#c3ccd4', '#fefefe',  1),
                ('2',	N'金太陽',   '#55b85d', '#fefefe',  2),
                ('3',	N'卓越',     '#39d1db', '#fefefe',  3),
                ('4',	N'非凡',     '#f460b5', '#fefefe',  4),  
                ('5',	N'奇蹟',     '#e6b856', '#fefefe',  5),
                ('6',	N'傳奇',     '#d55c5c', '#fefefe',  6),  
                ('7',	N'至尊',     '#fefefe', '#b9a46d',  7),
                -- new
                ('S01',	N'尊皇-股東',     '#9d492e', '#ffffff',   8),
                ('S02',	N'尊皇-非凡股東', '#a99563', '#ffffff',   9),
                ('A01',	N'尊盈-太陽',     '#e5b857', '#ffffff',   10),
                ('A02',	N'尊盈-卓越',     '#39d1db', '#ffffff',   11),
                ('A03',	N'尊盈-至尊',     '#d55c5c', '#ffffff',   12),
                ('N01',	N'尊華-尊華會',   '#c3ccd4', '#ffffff',   13),
                ('G01',	N'尊悅-標準',     '#8d2ce3', '#ffffff',   14),
                ('G02',	N'尊悅-星級',     '#f460b5', '#ffffff',   15),
                ('G03',	N'尊悅-王者',     '#55b85d', '#ffffff',   16);
        RETURN;
    END