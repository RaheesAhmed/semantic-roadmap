--sp_helptext 'spq.GetSMSPrivatePlaneBooking'

CREATE PROCEDURE [spq].[GetSMSPrivatePlaneBooking]
    @pBookingRid BIGINT ,
    @pGuid VARCHAR(50) ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      

        DECLARE @vAdditionExpenses TABLE (
            wBookingRid     BIGINT,
            wCurrcode       VARCHAR(30),
            wExpAmt         NUMERIC(18, 4),
            wExpenseSubtype BIGINT
        );
		
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
        -- 乘客
        DECLARE @sPassengerName NVARCHAR(4000);
        -- 乘客票號
        DECLARE @sPassengerTicketNo NVARCHAR(4000);
        -- 負責員工
        DECLARE @sReqByName NVARCHAR(100);
        -- 服務櫃檯電話
        DECLARE @sServiceCounterTel NVARCHAR(1000);
        -- 要求人
        DECLARE @sCoordinator NVARCHAR(100);


        SET @sChangeTicketFeeRid = ( SELECT TOP(1) sub.RowID
                                     FROM dbo.mExpenseSubtype sub
                                     INNER JOIN dbo.mExpensetype t ON sub.wExpenseTypeId =t.RowID AND t.wCode='008'
                                     WHERE sub.wCode = '006' AND sub.wExpCat ='TR'
        );

        SET @sCancelTicketFeeRid = ( SELECT TOP(1) sub.RowID
                                     FROM dbo.mExpenseSubtype sub
                                     INNER JOIN dbo.mExpensetype t ON sub.wExpenseTypeId =t.RowID AND t.wCode='008'
                                     WHERE sub.wCode = '005' AND sub.wExpCat ='TR'
        );

        INSERT INTO @vAdditionExpenses (  wBookingRid, wCurrcode, wExpAmt, wExpenseSubtype)
        SELECT  ae.wBookingRid ,
                ae.wCurrcode,
                ae.wExpAmt ,
                ae.wExpenseSubtype
        FROM  dbo.eAdditionalExpense ae
        INNER JOIN dbo.eActionAffectedTableLog aatl ON aatl.wRefTableName = 'eAdditionalExpense'
                                                                AND aatl.wNonceToken = @pGuid
                                                                AND ae.wStatus = 'A'
                                                                AND ae.RowID = aatl.wRefRid
                                                                AND ae.wBookingStatus = 'C'
                                                                AND aatl.wActionType = 'I';

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
                   @sServiceCounterTel =  STUFF((SELECT CONCAT(',', scc.wTel)  FROM dbo.mServiceCounterContact scc WHERE scc.wSeriverCounterRid = sc.RowID AND scc.wContactType = 'CSSMS' AND scc.wDepartmentCode = 'ROOM' FOR XML PATH('')), 1, 1, N'')
            FROM   dbo.eBooking b
            LEFT JOIN RollsMary.dbo.mUsr mu ON mu.RowID = b.wUpdBy --經手人
            LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid AND sc.wStatus = 'A'
            WHERE  b.RowID = @pBookingRid;
        END

        -- 乘客
        SET @sPassengerName = STUFF(
            (SELECT CONCAT(',', IIF(@pLangCd = 'en-gb', p.wEName, p.wCName))
            FROM dbo.ePassengerDetails pd
            LEFT JOIN mPerson p ON p.RowID = pd.wPersonRid
            WHERE pd.wStatus='A' 
                AND pd.wBookingRid = @pBookingRid 
            ORDER BY pd.wSeqNo
            FOR XML PATH('')), 1, 1, '');

        -- 乘客票號
        SET @sPassengerTicketNo = STUFF(
            (SELECT wClientTicketNo 
            FROM dbo.ePassengerDetails
            WHERE wStatus='A' 
                AND wBookingRid = @pBookingRid
            ORDER BY wSeqNo
            FOR XML PATH('')), 1, 1, '');
                       
        -- Selecte Result
        SELECT  wIsMDAgent = @sIsMDAgent, -- MD轉介戶口
                wIsMDFollow = @sIsMDFollow, -- 非MD轉介的戶口, 跟進部部門為MD、要求同事為MD / VIP / FRONT
                wHeaderType = CAST(IIF( sc_debit.wCode IN ( 'CR', 'FY-MFM' ), 'SUNTRAVEL', 'SUNGROUP') AS VARCHAR(30)),--"碼頭服務部" 及 "中央訂務部"  --> 顯示 「太陽旅遊溫馨提示：」 ---> SUNTRAVEL  = CR, FY-MFM, AP-MFM (Not Sure),
                bpp.wBookingRid ,
                bpp.wBookingType AS wFlightType ,
                pprd.wCityCd wDepartCity ,
                pprd.wIsReturn ,
                pprd.wCityCd wDestination ,
                pprd.wTakeOffDt wGoDepartTime ,
                pprd.wArrivalDt wGoArrivalTime ,
                pprd.wTakeOffDt wReturnDepartTime ,
                pprd.wArrivalDt wReturnArrivalTime ,
                bpp.wPlaneModel ,
                bpp.wSupplier ,
                bpp.wHotelRid ,
                bpp.wTravelAgencyRid ,
                bpp.wSeatNo ,
                bpp.wOrderNo ,
                bpp.wIsSmoking ,
                bpp.wServiceLang ,
                bpp.wHasWifi ,
                bpp.wNoOfServiceStaff ,
                bpp.wExpAmt ,
                bpp.wTotalAmt ,
                bpp.wPaymentMethod ,
                bpp.wReceiptNo wRecieptNo ,
                bpp.wCurrCode ,
                bpp.wExtraFee ,
                bpp.wConfirmPassengerNo ,
                bpp.wRemark ,
                bpp.wChangeOrderCount ,
                pprd.wStatus wChangeRouteStatus ,
                bpp.wBookingNo ,
                bpp.wCancelDt ,
                bpp.wCancelReason ,
                wGoDepartureCityName = CASE WHEN @pLangCd = 'en-gb' THEN a_go_dep.wEName ELSE a_go_dep.wCName END ,
                a_go_dep.wCity AS wGoDepartureCityCode ,
                wGoArrivalCityName = CASE WHEN @pLangCd = 'en-gb' THEN a_go_arr.wEName ELSE a_go_arr.wCName END ,
                a_go_arr.wCity AS wGoArrivalCityCode ,
                wReturnDepartureCityName = CASE WHEN @pLangCd = 'en-gb' THEN a_rtn_dep.wEName ELSE a_rtn_dep.wCName END ,
                a_rtn_dep.wCity AS wReturnDepartureCityCode ,
                wReturnArrivalCityName = CASE WHEN @pLangCd = 'en-gb' THEN a_rtn_arr.wEName ELSE a_rtn_arr.wCName END ,
                a_rtn_arr.wCity AS wReturnArrivalCityCode ,
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
                tc.wTicCollPoint ,
                tcp.wName AS wTicketCollectionPointName ,
                b.wCrtDt ,
                b.wCrtBy ,
                wCrtByName = CASE WHEN @pLangCd = 'en-gb' THEN u_crt.wName ELSE u_crt.wCName END ,
                b.wUpdDt ,
                b.wUpdBy ,
                wUpdByName = CASE WHEN @pLangCd = 'en-gb' THEN u.wName ELSE u.wCName END ,
                wPassengerName = ISNULL(@sPassengerName, ''),
                wPassengerTicketNo = ISNULL(@sPassengerTicketNo, ''),
                ae_cancel.wExpAmt AS wCancelHandlingFee ,
                ae_change.wExpAmt AS wChangeHandlingFee ,
                wServiceCounterTel = ISNULL(@sServiceCounterTel, '') ,
                sc_debit.wSMSName AS wServiceCounterName
        FROM    dbo.eBookingPrivatePlane bpp
        LEFT JOIN dbo.ePrivatePlaneRouteDtl pprd ON pprd.wBookingPrivatePlaneRid = bpp.RowID AND pprd.wStatus='A'
        LEFT JOIN dbo.eBooking b ON bpp.wBookingRid = b.RowID
        LEFT JOIN dbo.mAirport a_go_dep ON a_go_dep.RowID = pprd.wDepartureAirportRid
        LEFT JOIN dbo.mAirport a_go_arr ON a_go_arr.RowID = pprd.wArrivalAirportRid
        LEFT JOIN dbo.mAirport a_rtn_dep ON a_rtn_dep.RowID = pprd.wDepartureAirportRid AND pprd.wIsReturn = 'Y'
        LEFT JOIN dbo.mAirport a_rtn_arr ON a_rtn_arr.RowID = pprd.wArrivalAirportRid AND pprd.wIsReturn = 'Y'
        LEFT JOIN dbo.eBookingCheckInService cis ON cis.RowId = b.RowID
        LEFT JOIN dbo.eTicketCollection tc ON tc.wBookingRid = cis.wBookingRid
        LEFT JOIN dbo.mTicketCollectionPoint tcp ON tcp.wCode = tc.wTicCollPoint
        LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = b.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr u_crt ON u_crt.RowID = b.wCrtBy
        LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = b.wReqAgentCodeIn
        LEFT JOIN RollsMary.dbo.mAgent a_d ON a_d.wAgentCodeIn = b.wDebitAgentCodeIn
        LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = b.wApprovalAgentCodeIn
        LEFT JOIN @vAdditionExpenses ae_cancel ON ae_cancel.wExpenseSubtype = @sCancelTicketFeeRid AND ae_cancel.wBookingRid = @pBookingRid
        LEFT JOIN @vAdditionExpenses ae_change ON ae_change.wExpenseSubtype = @sChangeTicketFeeRid AND ae_change.wBookingRid = @pBookingRid
        LEFT JOIN dbo.mServiceCounter sc_debit ON sc_debit.RowID = b.wDebitCounterRid
        WHERE   b.RowID = @pBookingRid;
    END;