-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [spq].[GetAgentAuthListByAgent]
    (
      @pAgentCode NVARCHAR(20) ,
      @pwLangCd VARCHAR(10) = 'en-GB'
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

    -- Insert statements for procedure here
        SELECT  wAgentCodeIn ,
                CASE WHEN @pwLangCd = 'en-GB' THEN wEName
                     ELSE wCName
                END AS wCName ,
                wCName AS ChName ,
                wCageCodeIn ,
                wCompNo ,
                wSex ,
                wTel
        FROM    RollsMary.dbo.mAgent a
        WHERE   a.wAgentCode_Old = @pAgentCode
                AND a.wStatus <> 'T';
    END;