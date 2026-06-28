-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [spq].[GetShowTicketPriceByShowID]
    (
      @wShowID BIGINT ,
      @pwLangCd VARCHAR(10) = 'en-GB'
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

    -- Insert statements for procedure here
        SELECT  ms.RowID ,
                ms.wShowRid ,
                ms.wTicketType ,
                ms.wAmount ,
                ms.wCost ,
                ms.wCurrCode ,
                ms.wSeqNo ,
                ms.wCrtDt ,
                ms.wCrtBy ,
                ms.wUpdDt ,
                ms.wUpdBy ,
                '' AS ActionType ,
                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                     ELSE usr.wCName
                END AS wUpdByCName ,
                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                     ELSE crusr.wCName
                END AS wCreatedByCName
        FROM    mShowTicketPrice AS ms
                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ms.wUpdBy
                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ms.wCrtBy
        WHERE   ms.wShowRid = @wShowID;
    END;