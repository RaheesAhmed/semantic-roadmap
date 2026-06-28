
CREATE PROCEDURE [test].[GetSMSHeliChange]
/*
declare @pBookingRid bigint,
			@pChangeActionXML XML,
			@pGuid VARCHAR(50),
			@pLangCd VARCHAR(30)	='zh-TW'
	set @pChangeActionXML=N'<DataSet><Record RowID="10000000010698" wChangeActionType="CO" /><Record RowID="10000000010699" wChangeActionType="CO" /></DataSet>'
	set @pBookingRid =10000000011617
	set @pGuid ='eab342bc-1141-405b-8eaa-9380e7777262'
	exec  [test].[GetSMSHeliChange] @pBookingRid , @pChangeActionXML, @pGuid , @pLangCd


*/  @pBookingRid BIGINT ,
    @pChangeActionXML XML ,
    @pGuid VARCHAR(50) ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @sDocHandle INT;
		
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;              

        SET @pLangCd = LOWER(@pLangCd);  
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pChangeActionXML;
		
  --      SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
  --              *
  --      INTO    #sDataSet_ChangeActionList
  --      FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		--WITH (
		--		RowID BIGINT ,
		--		wChangeActionType VARCHAR(30)
		--	);

		--Handling fee RowID in eExpenseSubtype
        DECLARE @sChangeTicketFeeRid AS BIGINT;
        DECLARE @sCancelTicketFeeRid AS BIGINT;        

        SELECT  @sChangeTicketFeeRid = RowID
        FROM    dbo.mExpenseSubtype
        WHERE   wCode = '031';

        SELECT  @sCancelTicketFeeRid = RowID
        FROM    dbo.mExpenseSubtype
        WHERE   wCode = '032';

        WITH    cteAdditionExpensesData
                  AS ( SELECT   ae.wCurrcode ,
                                ae.wExpAmt ,
                                ae.wBookingRid ,
                                ae.wExpenseSubtype
                       FROM     dbo.eAdditionalExpense ae
                                INNER JOIN dbo.eActionAffectedTableLog aatl ON aatl.wRefTableName = 'eAdditionalExpense'
                                                                               AND aatl.wNonceToken = @pGuid
                                                                               AND ae.RowID = aatl.wRefRid
                                                                               AND ae.wBookingStatus = 'C'
                                                                               AND aatl.wActionType = 'I'
                     ),
                cteRtnList
                  AS ( SELECT   bh.RowID ,
                                bh.wBookingRid ,
                                bh.wTicketId ,
                                bh.wOrderNo ,
                                bh.wBookingLocation ,
                                bh.wUseBlackCardFlag ,
                                bh.wPaymentMethod ,
                                bh.wReceiptNo ,
                               -- bh.wRouteRid ,
                               -- bh.wDepartDt ,
                                bh.wUnitAmt ,
                                bh.wQuantity ,
                                bh.wCurrCode ,
                                bh.wExpAmt ,
                                bh.wTotalAmt ,
                                bh.wCost ,
                                bh.wAdditionalExp ,
                                bh.wBookingStatus ,
                                bh.wRemark ,
                                bh.wStatus ,
                                bh.wSeqNo ,
                                bh.wUpdDt ,
                                bh.wUpdBy ,
                                bh.wHandlingFee ,
                                bh.wIsCharteredFlight ,
                                r.wRouteFrom ,
                                r.wRouteTo ,
                                b.wBookingType ,
                                b.wRefNo ,
                                b.GUID ,
                                b.wReqCounterRid ,
                                b.wDebitCounterRid ,
                                b.wReqCustomerRid ,
                                b.wDebitCustomerRid ,
                                b.wReqDepartment ,
                                b.wReqUserRid ,
                                CASE WHEN b.wReqDepartment = 'DEVELOP' THEN CASE WHEN @pLangCd = 'en-gb' THEN u_req.wName
                                                                                 ELSE u_req.wCName
                                                                            END
                                     ELSE CASE WHEN @pLangCd = 'en-gb' THEN u_crt.wName
                                               ELSE u_crt.wCName
                                          END
                                END AS wReqByName ,
                                b.wAsstBooker ,
                                b.wAssBookerTel ,
                                b.wDebitDt ,
                                b.wExpDt ,
                                b.wCancelDebitDt ,
                                b.wCancelReasonCd ,
                                b.wCancelBy ,
                                b.wCancelDt ,
                                b.wTravePkgRid ,
                                b.wReqAgentCodeIn ,
                                CASE WHEN @pLangCd = 'en-gb' THEN a_r.wEName
                                     ELSE a_r.wCName
                                END AS wReqAgentName ,
                                a_r.wAgentCode_Display AS wReqAgentCode_Display ,
                                b.wDebitAgentCodeIn ,
                                CASE WHEN @pLangCd = 'en-gb' THEN a_d.wEName
                                     ELSE a_d.wCName
                                END AS wDebitAgentName ,
                                a_d.wAgentCode_Display AS wDebitAgentCode_Display ,
                                b.wApprovalAgentCodeIn ,
                                CASE WHEN @pLangCd = 'en-gb' THEN a_a.wEName
                                     ELSE a_a.wCName
                                END AS wApprovalName ,
                                a_a.wAgentCode_Display AS wApprovalAgentCode_Display ,
                                b.wCrtDt ,
                                b.wCrtBy ,
                                CASE WHEN @pLangCd = 'en-gb' THEN u_crt.wName
                                     ELSE u_crt.wCName
                                END AS wCrtByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN u.wName
                                     ELSE u.wCName
                                END AS wUpdByName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN p.wEName
                                     ELSE p.wCName
                                END AS wPassengerName ,
                                pd.RowID AS wPassengerBookingRid ,
                                pd.wClientTicketNo AS wPassengerTicketNo ,
                                pd.wTakeOffDt ,
                                pd.wRouteRid ,
                                ae_cancel.wExpAmt AS wCancelHandlingFee ,
                                ae_change.wExpAmt AS wChangeHandlingFee ,
                                --scc.wTel AS wServiceCounterTel ,
                                ( CASE WHEN b.wReqDepartment = 'DEVELOP' THEN CASE WHEN ISNULL(u_req.wPrivateTel, '') <> '' THEN '+' + REPLACE(ISNULL(u_req.wPrivateTelCountryCode, ''), '+', '') + '-' + ISNULL(u_req.wPrivateTel, '')
                                                                                   ELSE ''
                                                                              END
                                       ELSE scc.wTel
                                  END ) AS wServiceCounterTel ,
                                sc_debit.wSMSName AS wServiceCounterName ,
                                --chg.wChangeActionType
								-- dbml
								CAST('CO' AS VARCHAR(30)) AS wChangeActionType
                       FROM     dbo.eBookingHeli bh
                                INNER JOIN CRM.dbo.eBooking b ON bh.wBookingRid = b.RowID
                                INNER JOIN CRM.dbo.ePassengerDetails pd ON pd.wBookingRid = b.RowID
                                --INNER JOIN #sDataSet_ChangeActionList chg ON chg.RowID = pd.RowID
                                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = b.wUpdBy
                                LEFT JOIN RollsMary.dbo.mUsr u_crt ON u_crt.RowID = b.wCrtBy
                                LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = b.wReqAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mAgent a_d ON a_d.wAgentCodeIn = b.wDebitAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = b.wApprovalAgentCodeIn
                                LEFT JOIN CRM.dbo.mRoute r ON r.RowID = pd.wRouteRid
                                LEFT JOIN CRM.dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid
                                                                        AND sc.wStatus = 'A'
                                LEFT JOIN CRM.dbo.mServiceCounterContact scc ON scc.wSeriverCounterRid = sc.RowID
                                                                                AND scc.wContactType = 'CSSMS' AND scc.wDepartmentCode = 'ROOM'
                                LEFT JOIN CRM.dbo.mServiceCounter sc_debit ON sc_debit.RowID = b.wDebitCounterRid
                                LEFT JOIN cteAdditionExpensesData ae_cancel ON ae_cancel.wExpenseSubtype = @sCancelTicketFeeRid
                                                                               AND ae_cancel.wBookingRid = @pBookingRid
                                LEFT JOIN cteAdditionExpensesData ae_change ON ae_change.wExpenseSubtype = @sChangeTicketFeeRid
                                                                               AND ae_change.wBookingRid = @pBookingRid
                                LEFT JOIN mPerson p ON p.RowID = pd.wPersonRid
                                LEFT JOIN RollsMary.dbo.mUsr u_req ON u_req.RowID = b.wReqUserRid
                     ),
                cteCheckCommonRoute
                  AS ( SELECT   e.wBookingRid ,
                                e.wRouteRid ,
                                e.wTakeOffDt
                       FROM     cteRtnList e
                       GROUP BY e.wBookingRid ,
                                e.wRouteRid ,
                                e.wTakeOffDt
                     ),
                cteIsCommonRoute
                  AS ( SELECT   e.wBookingRid ,
                                COUNT(*) AS wCount
                       FROM     cteCheckCommonRoute e
                       GROUP BY e.wBookingRid
                     )
            SELECT  rtn.* ,
                    ( CASE WHEN c.wCount > 1 THEN 'N'
                           ELSE 'Y'
                      END ) AS wIsCommonRoute
            FROM    cteRtnList rtn
                    LEFT JOIN cteIsCommonRoute c ON rtn.wBookingRid = c.wBookingRid;
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_ChangeActionList') IS NOT NULL
            DROP TABLE #sDataSet_ChangeActionList;
    END;