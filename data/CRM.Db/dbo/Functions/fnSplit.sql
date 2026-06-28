CREATE FUNCTION [dbo].[fnSplit]
    (
      @sInputList NVARCHAR(MAX) ,
      @sDelimiter VARCHAR(8000) = ','
    )
RETURNS @sList TABLE
    (
      RowId INT IDENTITY(1, 1) ,
      item NVARCHAR(4000)
    )
AS
    BEGIN
        DECLARE @sItem AS NVARCHAR(4000);	
        WHILE CHARINDEX(@sDelimiter, @sInputList, 0) <> 0
            BEGIN
                SELECT  @sItem = LTRIM(RTRIM(SUBSTRING(@sInputList, 1,
                                                       ( CHARINDEX(@sDelimiter,
                                                              @sInputList, 0)
                                                         - 1 )))) ,
                        @sInputList = LTRIM(RTRIM(SUBSTRING(@sInputList,
                                                            ( CHARINDEX(@sDelimiter,
                                                              @sInputList, 0)
                                                              + LEN(@sDelimiter) ),
                                                            LEN(@sInputList))));
        --------------------
                INSERT  INTO @sList
                        SELECT  @sItem
                        WHERE   @sItem IS NOT NULL;
            END;
    
        INSERT  INTO @sList
                SELECT  @sInputList
                WHERE   @sInputList IS NOT NULL;
        RETURN;
    END;