CREATE PROCEDURE [spq].[GetCashTransferLst]
    (
      @pRefNo VARCHAR(30) ,
      @pInAgentCodeIn VARCHAR(14) ,
      @pCashTransferStatus VARCHAR(5) ,
      @pTranDt AS DATETIME2,
      @pCounterRidXML XML ,
      @pLangCd VARCHAR(10) ,
      @pPageNum INT ,
      @pPageSize INT
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @sTranDt AS DATE,
                @sDebitCounterRidCount AS INT = 0;
        DECLARE @sData_DebitCounterRid AS TABLE (wCounterRid BIGINT PRIMARY KEY);

        SET @pRefNo = ISNULL(@pRefNo, '');
        SET @pInAgentCodeIn = ISNULL(@pInAgentCodeIn, '');
        SET @pCashTransferStatus = ISNULL(@pCashTransferStatus, '');
        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');
        SET @pPageNum = ISNULL(@pPageNum, 1);
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @sTranDt = CAST(@pTranDt AS DATE);

        IF @pCounterRidXML IS NOT NULL
        BEGIN
            INSERT INTO @sData_DebitCounterRid ( wCounterRid )
            SELECT tmp.value('@SelectionItem', 'BIGINT') AS SelectionItem
            FROM @pCounterRidXML.nodes('/DataSet/Record') AS T ( tmp );

            SELECT @sDebitCounterRidCount = COUNT(1) FROM @sData_DebitCounterRid;
        END;

    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   ct.RowID ,
                                ct.wRefNo ,
                                ct.wInCounterRid ,
                                msc.wName AS wInCounterRidByName ,
                                ct.wInAgentCodeIn ,
                                inAgent.wAgentCode_Display AS wInAgentCode_Display ,
                                CASE WHEN @pLangCd = 'en-gb'
                                     THEN inAgent.wEName
                                     ELSE inAgent.wCName
                                END AS wInAgentCodeByName ,
                                ct.wOutAgentCodeIn ,
                                outAgent.wAgentCode_Display AS wOutAgentCode_Display ,
                                CASE WHEN @pLangCd = 'en-gb'
                                     THEN outAgent.wEName
                                     ELSE outAgent.wCName
                                END AS wOutAgentCodeByName ,
                                ct.wIsAuthorized ,
                                ct.wInCurrCd,
                                ct.wOutCurrCd,
                                ct.wInCurrRate,
                                ct.wOutCurrRate,
                                ct.wInAmount,
                                ct.wOutAmount,
                                ct.wIsAutoAdjust,
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
                                ct.wUpdDt ,
                                CAST('N' AS CHAR(1)) AS wIsSelected , -- Pseudo Column, Used By UcRelatedCashTransfer
                                'N' AS RecordState ,
                                wAgentCodeIn = ct.wOutAgentCodeIn
                       FROM     dbo.eCashTransfer ct
                                LEFT JOIN dbo.mServiceCounter msc ON msc.RowID = ct.wInCounterRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ct.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ct.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mAgent] inAgent ON ct.wInAgentCodeIn = inAgent.wAgentCodeIn
                                LEFT JOIN [RollsMary].[dbo].[mAgent] outAgent ON ct.wOutAgentCodeIn = outAgent.wAgentCodeIn
                                LEFT JOIN @sData_DebitCounterRid ddc ON ddc.wCounterRid = ct.wInCounterRid
                       WHERE    ( @pRefNo = ''
                                  OR ct.wRefNo = @pRefNo
                                )
                                AND ( @pInAgentCodeIn = ''
                                      OR ct.wOutAgentCodeIn = @pInAgentCodeIn
                                    )
                                AND ( @pCashTransferStatus = ''
                                      OR ct.wCashTransferStatus = @pCashTransferStatus
                                    )
                                AND (@sTranDt IS NULL OR @sTranDt = CAST(ct.wTranDt AS DATE))
                                AND ( @sDebitCounterRidCount = 0 OR ddc.wCounterRid IS NOT NULL )
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(1)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY tResult.wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
	FETCH NEXT @pPageSize ROWS ONLY;
    END;