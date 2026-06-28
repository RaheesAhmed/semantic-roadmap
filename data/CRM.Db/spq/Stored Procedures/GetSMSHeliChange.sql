
CREATE PROCEDURE [spq].[GetSMSHeliChange]
/*
declare @pBookingRid bigint,
			@pChangeActionXML XML,
			@pGuid VARCHAR(50),
			@pLangCd VARCHAR(30)	='zh-TW'
	set @pChangeActionXML=N'<DataSet><Record RowID="10000000010659" wChangeActionType="RF" /></DataSet>'
	set @pBookingRid =10000000011557
	set @pGuid ='3886719f-3e52-4f40-ae77-14c00cef1e17'
	exec  [spq].[GetSMSHeliChange] @pBookingRid , @pChangeActionXML, @pGuid , @pLangCd


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

        DECLARE @vDataSet_ChangeAction TABLE (
            RowID               BIGINT ,
			wChangeActionType   VARCHAR(30)
        );

        DECLARE @vAdditionExpenses TABLE (
            wBookingRid     BIGINT,
            wCurrcode       VARCHAR(30),
            wExpAmt         NUMERIC(18, 4),
            wExpenseSubtype BIGINT
        );

        IF @pChangeActionXML IS NOT NULL
        BEGIN
            INSERT INTO @vDataSet_ChangeAction
            SELECT RowID = T.tmp.value('@RowID',    'BIGINT'),
                   wChangeActionType = T.tmp.value('@wChangeActionType', 'VARCHAR(30)')
            FROM @pChangeActionXML.nodes('DataSet/Record') T(tmp)
        END

        SET @pLangCd = LOWER(ISNULL(NULLIF(@pLangCd, ''), 'zh-tw'));

		--Handling fee RowID in eExpenseSubtype
        -- 改票
        DECLARE @sChangeTicketFeeRid AS BIGINT;
        -- 退票
        DECLARE @sCancelTicketFeeRid AS BIGINT; 
        -- MD轉介戶口
        DECLARE @sIsMDAgent CHAR(1)='N'; 
        -- MD跟進戶口，要求部門為：MD、VIP、FRONT
        DECLARE @sIsMDFollow CHAR(1) = 'N';
        -- 負責員工
        DECLARE @sReqByName NVARCHAR(100);
        -- 服務櫃檯電話
        DECLARE @sServiceCounterTel NVARCHAR(1000);
        -- 要求人
        DECLARE @sCoordinator NVARCHAR(100);         

        SET @sChangeTicketFeeRid = ( SELECT TOP(1) sub.RowID
                                     FROM dbo.mExpenseSubtype sub
                                     INNER JOIN dbo.mExpensetype t ON sub.wExpenseTypeId =t.RowID  AND t.wCode ='005' AND t.wExpCat = 'TR'
                                     WHERE sub.wCode = '001'
        );

        SET @sCancelTicketFeeRid = ( SELECT TOP(1) sub.RowID
                                     FROM dbo.mExpenseSubtype sub
                                     INNER JOIN dbo.mExpensetype t ON sub.wExpenseTypeId =t.RowID AND t.wCode ='005' AND t.wExpCat = 'TR'
                                     WHERE   sub.wCode = '002'
        );

        INSERT INTO @vAdditionExpenses (  wBookingRid, wCurrcode, wExpAmt, wExpenseSubtype)
        SELECT  ae.wBookingRid ,
                ae.wCurrcode,
                ae.wExpAmt ,
                ae.wExpenseSubtype
        FROM  dbo.eAdditionalExpense ae
        INNER JOIN dbo.eActionAffectedTableLog aatl ON aatl.wRefTableName = 'eAdditionalExpense'
                                                                AND aatl.wNonceToken = @pGuid
                                                                AND ae.RowID = aatl.wRefRid
                                                                AND ae.wBookingStatus = 'C'
                                                                AND aatl.wActionType = 'I'
                                                                AND ae.wStatus = 'A';

        IF EXISTS(  SELECT  1
                    FROM RollsMary.dbo.mAgent ma
                    INNER JOIN RollsMary.dbo.mAgentFollow af ON af.wAgentCodeIn = ma.wAgentCodeIn AND af.wStatus = 'A'
                    INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID AND afd.wStatus = 'A'
                    INNER JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wDeptRid
                    INNER JOIN RollsMary.dbo.mUsr mu ON mu.RowID = afd.wUsrRid
                    INNER JOIN dbo.eBooking eb ON eb.wReqAgentCodeIn = ma.wAgentCodeIn
                    WHERE   NULLIF(md.wUserLineGrp, '') IS NULL
                        AND NULLIF(af.wYearMth, '') IS NULL
                        AND NULLIF(afd.wYearMth, '') IS NULL
                        AND ma.wAgentType = 'GAMBLERS'
                        AND md.wCode = 'DEVELOP'
                        AND eb.RowID =  @pBookingRid) 
        BEGIN
            SET @sIsMDAgent = 'Y'
        END;

        -- 如果不是MD轉介的戶口, 跟進部部門為MD、要求同事為MD / VIP / FRONT ？ 界面的跟進人還是戶口當前跟進人
        IF @sIsMDAgent = 'N' AND EXISTS (   SELECT  1
                                            FROM RollsMary.dbo.mAgent ma
                                            INNER JOIN RollsMary.dbo.mAgentFollow af ON af.wAgentCodeIn = ma.wAgentCodeIn AND af.wStatus = 'A'
                                            INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID AND afd.wStatus = 'A'
                                            INNER JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wDeptRid
                                            INNER JOIN RollsMary.dbo.mUsr mu ON mu.RowID = afd.wUsrRid
                                            INNER JOIN dbo.eBooking eb ON eb.wReqAgentCodeIn = ma.wAgentCodeIn
                                            INNER JOIN RollsMary.dbo.mDepartment rd ON rd.wCode = eb.wReqDepartment AND NULLIF(rd.wUserLineGrp, '') IS NULL
                                            WHERE   NULLIF(md.wUserLineGrp, '') IS NULL
                                                AND NULLIF(af.wYearMth, '') IS NULL
                                                AND NULLIF(afd.wYearMth, '') IS NULL
                                                -- AND md.wCode = 'DEVELOP' -- 跟進部門：市場部
                                                AND rd.wCode IN ('DEVELOP', 'HOUSEKEEPER', 'FRONT') -- 要求部門：MD、VIP、FRONT
                                                AND eb.RowID =  @pBookingRid) 
        BEGIN
            SET @sIsMDFollow = 'Y'
        END;

        IF @sIsMDAgent = 'Y'
        BEGIN
            -- 跟進同事 的英文名+(小名)
            SET @sCoordinator = (
                SELECT CONCAT(mu.wName, IIF(NULLIF(mu.wNickName, '') IS NULL, '', CONCAT('(', mu.wNickName, ')'))) 
                FROM dbo.eBooking eb 
                INNER JOIN RollsMary.dbo.mUsr mu ON mu.RowID = eb.wStaffFollwedRid  -- 跟進同事
                WHERE eb.RowID = @pBookingRid
            );

            -- 如果界面冇填到跟進人，取戶口當前跟進人
            IF NULLIF(@sCoordinator, '') IS NULL
            BEGIN
                SET @sCoordinator = (
                    SELECT TOP(1) CONCAT(mu.wName, IIF(NULLIF(mu.wNickName, '') IS NULL, '', CONCAT('(', mu.wNickName, ')'))) 
                    FROM RollsMary.dbo.mAgent ma
                    INNER JOIN RollsMary.dbo.mAgentFollow af ON af.wAgentCodeIn = ma.wAgentCodeIn AND af.wStatus = 'A'
                    INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID AND afd.wStatus = 'A'
                    INNER JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wDeptRid
                    INNER JOIN RollsMary.dbo.mUsr mu ON mu.RowID = afd.wUsrRid
                    INNER JOIN dbo.eBooking eb ON eb.wReqAgentCodeIn = ma.wAgentCodeIn
                    WHERE   NULLIF(md.wUserLineGrp, '') IS NULL
                        AND NULLIF(af.wYearMth, '') IS NULL
                        AND NULLIF(afd.wYearMth, '') IS NULL
                        AND md.wCode IN ('DEVELOP', 'HOUSEKEEPER', 'FRONT') -- 跟進部門：MD、VIP、FRONT
                        AND eb.RowID =  @pBookingRid 
                    ORDER BY md.wCode ASC, afd.wIsMainInCharge DESC
                );
            END
        END

        IF @sIsMDAgent = 'N' AND @sIsMDFollow = 'Y'
        BEGIN
            -- 要求同事 的英文名+(小名)
            SET @sCoordinator = (
                SELECT CONCAT(mu.wName, IIF(NULLIF(mu.wNickName, '') IS NULL, '', CONCAT('(', mu.wNickName, ')'))) 
                FROM dbo.eBooking eb 
                INNER JOIN RollsMary.dbo.mUsr mu ON mu.RowID = eb.wReqUserRid 
                WHERE eb.RowID = @pBookingRid
            );
        END

        -- 負責員工：MD轉介，跟進同事 + 電話
        IF @sIsMDAgent = 'Y'
        BEGIN
            SELECT @sReqByName = IIF(@pLangCd = 'en-gb', u_fol.wName, u_fol.wCName),
                   @sServiceCounterTel = wStaffTelephone
            FROM   dbo.eBooking b
            LEFT JOIN RollsMary.dbo.mUsr u_fol ON u_fol.RowID = b.wStaffFollwedRid --跟進同事
            WHERE  b.RowID = @pBookingRid; 
        END

        -- 負責員工：大量MD轉介，經手人 + 場館電話
        IF @sIsMDAgent = 'N'
        BEGIN
            SELECT @sReqByName = CASE WHEN @pLangCd = 'en-gb'  THEN ISNULL(mu.wName,'') ELSE ISNULL(mu.wCName,'') END ,
                   @sServiceCounterTel =  STUFF((SELECT CONCAT(',', scc.wTel)  FROM CRM.dbo.mServiceCounterContact scc WHERE scc.wSeriverCounterRid = sc.RowID AND scc.wContactType = 'CSSMS' AND scc.wDepartmentCode = 'ROOM' FOR XML PATH('')), 1, 1, N'')
            FROM   dbo.eBooking b
            LEFT JOIN RollsMary.dbo.mUsr mu ON mu.RowID = b.wUpdBy --經手人
            LEFT JOIN CRM.dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid AND sc.wStatus = 'A'
            WHERE  b.RowID = @pBookingRid;
        END

        ;WITH  cteRtnList AS ( 
            SELECT  wIsMDAgent = @sIsMDAgent, -- MD轉介戶口
                    wIsMDFollow = @sIsMDFollow, -- 非MD轉介的戶口, 跟進部部門為MD、要求同事為MD / VIP / FRONT
                    wHeaderType = CAST(IIF( sc_debit.wCode IN ( 'CR', 'FY-MFM' ), 'SUNTRAVEL', 'SUNGROUP') AS VARCHAR(30)),--"碼頭服務部" 及 "中央訂務部"  --> 顯示 「太陽旅遊溫馨提示：」 ---> SUNTRAVEL  = CR, FY-MFM, AP-MFM (Not Sure),
                    bh.RowID ,
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
                    b.[GUID] ,
                    b.wReqCounterRid ,
                    b.wDebitCounterRid ,
                    b.wReqCustomerRid ,
                    b.wDebitCustomerRid ,
                    b.wReqDepartment ,
                    b.wReqUserRid ,
                    wReqByName = ISNULL(@sReqByName, '') ,
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
                    wCoordinator = IIF(@sIsMDAgent = 'Y' OR @sIsMDFollow = 'Y', ISNULL(@sCoordinator, ''),  b.wCoordinator),
                    b.wUser,
                    b.wIsUser,
                    wReqAgentName = CASE WHEN @pLangCd = 'en-gb' THEN a_r.wEName ELSE a_r.wCName END ,
                    a_r.wAgentCode_Display AS wReqAgentCode_Display ,
                    b.wDebitAgentCodeIn ,
                    wDebitAgentName = CASE WHEN @pLangCd = 'en-gb' THEN a_d.wEName ELSE a_d.wCName END ,
                    a_d.wAgentCode_Display AS wDebitAgentCode_Display ,
                    b.wApprovalAgentCodeIn ,
                    wApprovalName = CASE WHEN @pLangCd = 'en-gb' THEN a_a.wEName ELSE a_a.wCName END ,
                    a_a.wAgentCode_Display AS wApprovalAgentCode_Display ,
                    b.wCrtDt ,
                    b.wCrtBy ,
                    wCrtByName = CASE WHEN @pLangCd = 'en-gb' THEN u_crt.wName ELSE u_crt.wCName END ,
                    wUpdByName = CASE WHEN @pLangCd = 'en-gb' THEN u.wName ELSE u.wCName END ,
                    wPassengerName = CASE WHEN @pLangCd = 'en-gb' THEN p.wEName ELSE p.wCName END ,
                    pd.RowID AS wPassengerBookingRid ,
                    pd.wClientTicketNo AS wPassengerTicketNo ,
                    pd.wTakeOffDt ,
                    pd.wRouteRid ,
                    ae_cancel.wExpAmt AS wCancelHandlingFee ,
                    ae_change.wExpAmt AS wChangeHandlingFee ,
                    wServiceCounterTel = ISNULL(@sServiceCounterTel, '') ,
                    sc_debit.wSMSName AS wServiceCounterName ,
                    chg.wChangeActionType
            FROM     dbo.eBookingHeli bh
            INNER JOIN CRM.dbo.eBooking b ON bh.wBookingRid = b.RowID
            INNER JOIN CRM.dbo.ePassengerDetails pd ON pd.wBookingRid = b.RowID
            INNER JOIN @vDataSet_ChangeAction chg ON chg.RowID = pd.RowID
            LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = b.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr u_crt ON u_crt.RowID = b.wCrtBy
            LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = b.wReqAgentCodeIn
            LEFT JOIN RollsMary.dbo.mAgent a_d ON a_d.wAgentCodeIn = b.wDebitAgentCodeIn
            LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = b.wApprovalAgentCodeIn
            LEFT JOIN CRM.dbo.mRoute r ON r.RowID = pd.wRouteRid
            LEFT JOIN CRM.dbo.mServiceCounter sc_debit ON sc_debit.RowID = b.wDebitCounterRid
            LEFT JOIN @vAdditionExpenses ae_cancel ON ae_cancel.wExpenseSubtype = @sCancelTicketFeeRid AND ae_cancel.wBookingRid = @pBookingRid
            LEFT JOIN @vAdditionExpenses ae_change ON ae_change.wExpenseSubtype = @sChangeTicketFeeRid AND ae_change.wBookingRid = @pBookingRid
            LEFT JOIN mPerson p ON p.RowID = pd.wPersonRid
        ),
        cteCheckCommonRoute AS ( 
            SELECT  e.wBookingRid ,
                    e.wRouteRid ,
                    e.wTakeOffDt
            FROM cteRtnList e
            GROUP BY e.wBookingRid , e.wRouteRid , e.wTakeOffDt
        ),
        cteIsCommonRoute AS ( 
            SELECT   e.wBookingRid ,
                    COUNT(*) AS wCount
            FROM cteCheckCommonRoute e
            GROUP BY e.wBookingRid
        )

        SELECT  rtn.* ,
                wIsCommonRoute = IIF(c.wCount > 1, 'N','Y')
        FROM cteRtnList rtn
        LEFT JOIN cteIsCommonRoute c ON rtn.wBookingRid = c.wBookingRid;
    END;