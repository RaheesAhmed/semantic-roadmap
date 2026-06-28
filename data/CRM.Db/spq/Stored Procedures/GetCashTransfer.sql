CREATE PROCEDURE [spq].[GetCashTransfer]
    (
      @pRowID BIGINT ,
      @pLangCd VARCHAR(10)
    )
AS
    BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
          
        SET @pRowID = ISNULL(@pRowID, 0);
        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');

    -- Insert statements for procedure here
        SELECT  ct.RowID ,
                ct.wRefNo ,
                ct.wInCounterRid ,
                ct.wInAgentCodeIn ,
                ct.wOutAgentCodeIn ,
                ct.wIsAuthorized ,
                ct.wInCurrCd,
                ct.wOutCurrCd,
                ct.wInCurrRate,
                ct.wOutCurrRate,
                ct.wInAmount,
                ct.wOutAmount,
                ct.wIsAutoAdjust,
                ct.wIsByPass,
                ct.wIsIVRProcess,
                ct.wTranDt,
                ct.wRollexCompNo,
                ct.wDepositor,
                ct.wRemark ,
                ct.wCashTransferStatus ,
                ct.wTransferGUID ,
                ct.wRelatedBookingRefNo ,
                ct.wStatus ,
                ct.wCrtBy ,
                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                     ELSE crusr.wCName
                END AS wCreatedByCName ,
                ct.wCrtDt ,
                ct.wUpdBy ,
                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                     ELSE usr.wCName
                END AS wUpdByCName ,
                ct.wUpdDt,
                wExchangeFxRate
        FROM    [dbo].[eCashTransfer] ct
                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ct.wUpdBy
                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ct.wCrtBy
        WHERE   ct.RowID = @pRowID;
    END;