CREATE PROCEDURE [spq].[GetCashTransferLst_UserControl]
    (
      @pBookingRid BIGINT ,
      @pLangCd VARCHAR(10)
    )
AS
    BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');

    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   DISTINCT
                                ct.RowID ,
                                ct.wRefNo ,
                                ct.wInAgentCodeIn ,
                                inAgent.wAgentCode_Display AS wInAgentCode_Display ,
                                CASE WHEN @pLangCd = 'en-gb'
                                     THEN inAgent.wEName
                                     ELSE inAgent.wCName
                                END AS wInAgentCodeByName ,
                                ct.wRelatedBookingRefNo ,
                                ct.wOutAgentCodeIn ,
                                outAgent.wAgentCode_Display AS wOutAgentCode_Display ,
                                CASE WHEN @pLangCd = 'en-gb'
                                     THEN outAgent.wEName
                                     ELSE outAgent.wCName
                                END AS wOutAgentCodeByName ,
                                ct.wInCurrCd AS wCurrCd ,
                                ct.wInAmount AS wAmount ,
                                ct.wCashTransferStatus ,
                                ct.wCrtDt,
                                wAgentCodeIn = ct.wOutAgentCodeIn
                       FROM     dbo.eCashTransfer ct
                                INNER JOIN dbo.eCashTransferDtl ctd ON ctd.wCashTransferRid = ct.RowID
                                                              AND ctd.wStatus = 'A' AND ct.wStatus = 'A'
                                LEFT JOIN [RollsMary].[dbo].[mAgent] inAgent ON ct.wInAgentCodeIn = inAgent.wAgentCodeIn
                                LEFT JOIN [RollsMary].[dbo].[mAgent] outAgent ON ct.wOutAgentCodeIn = outAgent.wAgentCodeIn
                       WHERE    ( @pBookingRid = ctd.wBookingRid )
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(1)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY tResult.wCrtDt DESC;
    END;