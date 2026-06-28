
CREATE PROCEDURE [spq].[GetAgentAuthList_ByAgentCodeInForPassenger_Agent]
    (
      @pAgentCodeIn NVARCHAR(150) ,
      @pwType VARCHAR(10) ,
      @pwStatus CHAR ,
      @pwLangCd VARCHAR(10)
    )
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pwType = ISNULL(@pwType, '')
		SET @pwStatus = ISNULL(@pwStatus, ' ');

        DECLARE @CommaData_Table TABLE
            (
              wAgentCodeIn VARCHAR(20)
            ); 

        INSERT  INTO @CommaData_Table
                SELECT  CAST(splitdata AS VARCHAR(20))
                FROM    dbo.Split(@pAgentCodeIn, ',');  

        SELECT  wAgentCodeIn ,
                wAgentCode_Old AS wAgentCode ,
                CASE WHEN @pwLangCd = 'en-GB' THEN wEName
                     ELSE wCName
                END AS wCName ,
                wCName AS ChName ,
                wSex ,
                wTel
        FROM    RollsMary.dbo.mAgent
        WHERE   ( wAgentCodeIn IN ( SELECT  wAgentCodeIn
                                    FROM    @CommaData_Table ) )
                AND ( @pwType = ''
                      OR wType = @pwType
                    )
                AND ( @pwStatus = ' '                     
                      OR wStatus = @pwStatus                      
                    );
    END;