CREATE PROCEDURE [spq].[GetBookingByCashTransfer]
    (
      @pCrtDt DATETIME2 ,
      @pDebitAgentCodeIn VARCHAR(14) ,
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

        DECLARE @vFromDt AS DATETIME2 = '0001-01-01' ,
            @vToDt AS DATETIME2 = '9999-12-31';

        IF @pCrtDt IS NOT NULL AND @pCrtDt NOT IN ('0001-01-01', '9999-12-31')
            BEGIN	
                SET @vFromDt = DATEADD(mm, -1, @pCrtDt);
                SET @vToDt = DATEADD(mm, 1, @pCrtDt);
            END;
        SET @pDebitAgentCodeIn = ISNULL(@pDebitAgentCodeIn, '');
        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');
        SET @pPageNum = ISNULL(@pPageNum, 9999);
        SET @pPageSize = ISNULL(@pPageSize, 1);

        WITH    cteBookingContent
                  AS ( SELECT   ae.RowID ,
                                ae.wBookingRefRid AS wBookingRid ,
                                ae.wOrderNo ,
                                ae.wCurrcode AS wCurrCode ,
                                ae.wTotalAmt ,
                                ae.wBookingStatus
                       FROM     dbo.eAdditionalExpense ae
                       WHERE    ae.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebr.RowID ,
                                ebr.wBookingRid ,
                                ebr.wOrderNo ,
                                ebr.wCurrCode ,
                                ebr.wTotalAmount AS wTotalAmt ,
                                ebr.wBookingStatus
                       FROM     dbo.eBookingRoom ebr
                       WHERE    ebr.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebf.RowID ,
                                ebf.wBookingRid ,
                                ebf.wOrderNo ,
                                ebf.wCurrCode ,
                                ebf.wTotalAmt ,
                                ebf.wBookingStatus
                       FROM     dbo.eBookingFerry ebf
                       WHERE    ebf.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebat.RowID ,
                                ebat.wBookingRid ,
                                ebat.wOrderNo ,
                                ebat.wCurrCode ,
                                ebat.wTotalAmt ,
                                ebat.wBookingStatus
                       FROM     dbo.eBookingAirTicket ebat
                       WHERE    ebat.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebh.RowID ,
                                ebh.wBookingRid ,
                                ebh.wOrderNo ,
                                ebh.wCurrCode ,
                                ebh.wTotalAmt ,
                                ebh.wBookingStatus
                       FROM     dbo.eBookingHeli ebh
                       WHERE    ebh.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebs.RowID ,
                                ebs.wBookingRid ,
                                ebs.wOrderNo ,
                                ebs.wCurrCode ,
                                ebs.wTotalAmt ,
                                ebs.wBookingStatus
                       FROM     dbo.eBookingShow ebs
                       WHERE    ebs.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebpp.RowID ,
                                ebpp.wBookingRid ,
                                ebpp.wOrderNo ,
                                ebpp.wCurrCode ,
                                ebpp.wTotalAmt ,
                                ebpp.wBookingStatus
                       FROM     dbo.eBookingPrivatePlane ebpp
                       WHERE    ebpp.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebcis.RowId ,
                                ebcis.wBookingRid ,
                                ebcis.wOrderNo ,
                                ebcis.wCurrCode ,
                                ebcis.wTotalAmt ,
                                ebcis.wBookingStatus
                       FROM     dbo.eBookingCheckInService ebcis
                       WHERE    ebcis.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebv.RowId ,
                                ebv.wBookingRid ,
                                ebv.wOrderNo ,
                                ebv.wCurrCode ,
                                ebv.wTotalAmt ,
                                ebv.wBookingStatus
                       FROM     dbo.eBookingVisa ebv
                       WHERE    ebv.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebpus.RowID ,
                                ebpus.wBookingRid ,
                                ebpus.wOrderNo ,
                                ebpus.wCurrCode ,
                                ebpus.wTotalAmt ,
                                ebpus.wBookingStatus
                       FROM     dbo.eBookingPickUpService ebpus
                       WHERE    ebpus.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebl.RowID ,
                                ebl.wBookingRid ,
                                ebl.wOrderNo ,
                                ebl.wCurrCode ,
                                ebl.wTotalAmt ,
                                ebl.wBookingStatus
                       FROM     dbo.eBookingLeading ebl
                       WHERE    ebl.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebtg.RowID ,
                                ebtg.wBookingRid ,
                                ebtg.wOrderNo ,
                                ebtg.wCurrCode ,
                                ebtg.wTotalAmt ,
                                ebtg.wBookingStatus
                       FROM     dbo.eBookingTourGuide ebtg
                       WHERE    ebtg.wPaymentMethod = 'DC'
                       UNION
                       SELECT   ebtp.RowID ,
                                ebtp.wBookingRid ,
                                '' AS wOrderNo , -- Will be added later
                                ebtp.wCurrCode ,
                                ebtp.wTotalAmt ,
                                ebtp.wBookingStatus
                       FROM     dbo.eBookingTravelPackage ebtp
                       WHERE    ebtp.wPaymentMethod = 'DC'
                     ),
                tResult
                  AS ( SELECT   eb.RowID ,
                                eb.wRefNo ,
                                eb.wDebitAgentCodeIn ,
                                eb.wDebitCounterRid,
                                eb.wDebitDt ,
                                agent.wAgentCode_Display ,
                                CASE WHEN @pLangCd = 'en-gb' THEN agent.wEName
                                     ELSE agent.wCName
                                END AS wAgentCodeByName ,
                                cbc.wOrderNo ,
                                cbc.wCurrCode ,
                                cbc.wTotalAmt ,
                                cbc.wBookingStatus ,
                                eb.wCrtDt ,
                                eb.wBookingType ,
                                CAST('N' AS CHAR(1)) AS wIsSelected, -- Pseudo Column
                                wAgentCodeIn = eb.wDebitAgentCodeIn
                       FROM     eBooking eb
                                LEFT JOIN [RollsMary].[dbo].[mAgent] agent ON eb.wDebitAgentCodeIn = agent.wAgentCodeIn
                                INNER JOIN cteBookingContent cbc ON eb.RowID = cbc.wBookingRid
                       WHERE    ( @vFromDt <= eb.wDebitDt
                                  AND @vToDt >= eb.wDebitDt
                                )
                                AND ( eb.wDebitAgentCodeIn = @pDebitAgentCodeIn
                                    )
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