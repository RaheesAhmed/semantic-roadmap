

CREATE PROCEDURE [spq].[GetCompByUser_Other]
    @pUserId VARCHAR(15) ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;        

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pLangCd = LOWER(@pLangCd);

        SELECT  CASE WHEN @pLangCd = 'en-gb' THEN c.wEName
                     ELSE c.wCName
                END AS wCompName,
				c.wCompNo
        FROM    RollsMary.dbo.mCompany c
                INNER JOIN RollsMary.dbo.mUsr u ON c.wCompNo = u.wCompNo
        WHERE   u.wUsrId = @pUserId
                AND u.wStatus = 'Active'
                AND c.wStatus = 'A';
    END;