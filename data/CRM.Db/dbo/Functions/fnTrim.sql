CREATE FUNCTION dbo.fnTrim(
    @expression NVARCHAR(MAX),
    @char NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
    BEGIN
        -- 刪掉開頭字符
        WHILE LEN(@expression) > 0 AND CHARINDEX(@char, @expression) = 1
        BEGIN
            SET @expression = SUBSTRING(@expression, LEN(@char) + 1, LEN(@expression));
        END;

        -- 刪掉尾部字符
        DECLARE @len INT;
        SET @len = LEN(@expression);
        WHILE @len > 0 AND SUBSTRING(@expression, @len - LEN(@char) + 1, @len) = @char
        BEGIN
            SET @expression = SUBSTRING(@expression, 1, @len - LEN(@char));
            Set @len = LEN(@expression);
        END;

        RETURN @expression;
    END;