CREATE PROCEDURE [spq].[GetSMSAdditionalExpensesBooking]
    @pBookingRid BIGINT ,
    @pGuid VARCHAR(50) ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;    
		
        IF ( @pBookingRid = -1 )
            BEGIN
                SELECT TOP 1
                       -- @pBookingRid = ae.wBookingRid
                        @pBookingRid = ae.wBookingRefRid
                FROM    CRM.dbo.eAdditionalExpense ae
                        INNER JOIN CRM.dbo.eActionAffectedTableLog aatl ON aatl.wRefTableName = 'eAdditionalExpense'
                                                                           AND aatl.wNonceToken = @pGuid
                                                                           AND aatl.wRefRid = ae.RowID;
                                                                           
            END;
        

        SET @pLangCd = LOWER(ISNULL(@pLangCd, ''));  

        DECLARE @sGuidRelatedBookingRid AS BIGINT; 

        DECLARE @sIsMD CHAR(1)='N';    
        IF EXISTS(  SELECT  1
                    FROM    RollsMary.dbo.mAgent AS a
                            INNER JOIN RollsMary.dbo.mAgentFollow AS saf ON saf.wAgentCodeIn = a.wAgentCodeIn AND saf.wStatus = 'A'
                            INNER JOIN RollsMary.dbo.mAgentFollowDtl AS safd ON safd.wAgentFollowRid = saf.RowID AND safd.wStatus = 'A'
                            INNER JOIN RollsMary.dbo.mDepartment AS sd ON sd.RowID = saf.wDeptRid
                            INNER JOIN RollsMary.dbo.mUsr AS u ON u.RowID = safd.wUsrRid
                            INNER JOIN dbo.eBooking b ON b.wReqAgentCodeIn = a.wAgentCodeIn
                    WHERE   NULLIF(sd.wUserLineGrp, '') IS NULL
                            AND NULLIF(saf.wYearMth, '') IS NULL
                            AND NULLIF(safd.wYearMth, '') IS NULL
                            AND a.wAgentType = 'GAMBLERS'
                            AND b.RowID =  @pBookingRid
                            AND sd.wCode = 'DEVELOP') 
        BEGIN
            SET @sIsMD = 'Y'
        END;
        
        WITH tmp
            AS(
                   SELECT TOP 1 
                          b.RowID,
                          wReqByName = CASE WHEN @pLangCd = 'en-gb' THEN ISNULL(u_fol.wName, '')
                                       ELSE ISNULL(u_fol.wCName, '')
                                       END ,
                          wServiceCounterTel = ISNULL(wStaffTelephone, '')
                   FROM   dbo.eBooking b
                          INNER JOIN dbo.eAdditionalExpense ae ON ae.wBookingRefRid = b.RowID
                          LEFT JOIN RollsMary.dbo.mUsr u_fol ON u_fol.RowID = b.wStaffFollwedRid --跟進同事
                          LEFT JOIN dbo.mExpenseType met ON ae.wExpenseType = met.RowID
                   WHERE  b.RowID = @pBookingRid AND @sIsMD = 'Y' AND met.wCode !='000' AND met.wCode !='001' 
                   
                   UNION ALL

                   SELECT b.RowID ,
                          wReqByName = CASE WHEN @pLangCd = 'en-gb'  THEN ISNULL(u_crt.wName,'') ELSE ISNULL(u_crt.wCName,'') END ,
                          wServiceCounterTel =   STUFF((SELECT CONCAT(',', scc.wTel)  FROM CRM.dbo.mServiceCounterContact scc WHERE scc.wSeriverCounterRid = sc.RowID AND scc.wContactType = 'CSSMS' AND scc.wDepartmentCode = 'ROOM' FOR XML PATH('')), 1, 1, N'')
                   FROM   dbo.eBooking b
                          INNER JOIN dbo.eAdditionalExpense ae ON ae.wBookingRefRid = b.RowID
                          LEFT JOIN dbo.mExpenseType met ON ae.wExpenseType = met.RowID
                          LEFT JOIN RollsMary.dbo.mUsr u_crt ON u_crt.RowID = b.wUpdBy --經手人
                          LEFT JOIN CRM.dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid AND sc.wStatus = 'A'
                   WHERE  b.RowID = @pBookingRid AND (@sIsMD = 'N' OR met.wCode ='000' OR met.wCode ='001' )
              )

        SELECT  ae.RowID ,
                ae.wOrderNo ,
                ae.wBookingRid ,
                ae.wRoomBookingRid ,
                ae.wExpenseType ,
                et.wCode AS wExpenseTypeCode ,
                et.wName AS wExpenseTypeName ,
                ae.wExpenseSubtype ,
                est.wName AS wExpenseSubtypeName ,
                ae.wPaymentMethod ,
                ae.wReceiptNo ,
                ae.wExpAmt ,
                ae.wTotalAmt ,
                ae.wCost ,
                ae.wCurrcode ,
                ae.wIsUseBlackCard ,
                ae.wRemark ,
                ae.wBookingStatus ,
                ae.wBookingRefRid ,
                b.wBookingType ,
                b.wRefNo ,
                b.GUID ,
                b.wReqCounterRid ,
                b.wDebitCounterRid ,
                b.wReqCustomerRid ,
                b.wDebitCustomerRid ,
                b.wReqDepartment ,
                b.wReqUserRid ,
                tmp.wReqByName ,
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
                ISNULL(rs.wName, ISNULL(s.wName, '')) AS wShopName ,
                b.wCrtDt ,
                b.wCrtBy ,
                CASE WHEN @pLangCd = 'en-gb' THEN u_crt.wName
                     ELSE u_crt.wCName
                END AS wCrtByName ,
                b.wUpdDt ,
                b.wUpdBy ,
                CASE WHEN @pLangCd = 'en-gb' THEN u.wName
                     ELSE u.wCName
                END AS wUpdByName ,
                tmp.wServiceCounterTel ,
                sc_debit.wSMSName AS wServiceCounterName,
                br.wRoomNo
        FROM    dbo.eAdditionalExpense ae
                INNER JOIN dbo.mExpenseType et ON et.RowID = ae.wExpenseType
                LEFT JOIN dbo.mExpenseSubtype est ON est.RowID = ae.wExpenseSubtype
                LEFT JOIN dbo.eBooking b ON ae.wBookingRefRid = b.RowID
                LEFT JOIN dbo.mRestaurant rs ON rs.RowID = ae.wRestaurantRid
                LEFT JOIN dbo.mSpa s ON s.RowID = ae.wSpaRid
                LEFT JOIN dbo.eBookingRoom br ON br.RowID=ae.wRoomBookingRid
                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = b.wUpdBy
                LEFT JOIN RollsMary.dbo.mUsr u_crt ON u_crt.RowID = b.wCrtBy
                LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = b.wReqAgentCodeIn
                LEFT JOIN RollsMary.dbo.mAgent a_d ON a_d.wAgentCodeIn = b.wDebitAgentCodeIn
                LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = b.wApprovalAgentCodeIn
                --LEFT JOIN CRM.dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid
                --                                        AND sc.wStatus = 'A'
                --LEFT JOIN CRM.dbo.mServiceCounterContact scc ON scc.wSeriverCounterRid = sc.RowID
                --                                                AND scc.wContactType = 'CSSMS'
                LEFT JOIN CRM.dbo.mServiceCounter sc_debit ON sc_debit.RowID = b.wDebitCounterRid
                --LEFT JOIN RollsMary.dbo.mUsr u_req ON u_req.RowID = b.wReqUserRid --要求同事
                LEFT JOIN tmp ON tmp.RowID = ae.wBookingRefRid
        WHERE   ae.wBookingRefRid = @pBookingRid;
        --WHERE   ae.wBookingRid = @pBookingRid;
    END;