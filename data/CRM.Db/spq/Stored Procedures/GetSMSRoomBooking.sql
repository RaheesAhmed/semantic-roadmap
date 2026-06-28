CREATE PROCEDURE [spq].[GetSMSRoomBooking]
    @pBookingRoomRowID BIGINT ,
    @pGuid VARCHAR(50) ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @vAdditionExpense TABLE (
            wRoomBookingRid     BIGINT,
            wCurrcode           VARCHAR(30),
            wTotalAmt           NUMERIC(18, 4),
            wExpenseSubtype     BIGINT,
            wBookingStatus      VARCHAR(5)
        );

        DECLARE @pBookingRid BIGINT;

        SET @pLangCd = LOWER(ISNULL(NULLIF(@pLangCd, ''), 'zh-tw'));
        -- MD轉介戶口
        DECLARE @sIsMDAgent CHAR(1)='N'; 
        -- MD跟進戶口，要求部門為：MD、VIP、FRONT
        DECLARE @sIsMDFollow CHAR(1) = 'N';
        -- 乘客
        DECLARE @sPassengerName NVARCHAR(4000);
        -- 負責員工
        DECLARE @sReqByName NVARCHAR(100);
        -- 服務櫃檯電話
        DECLARE @sServiceCounterTel NVARCHAR(1000);
        -- 要求人
        DECLARE @sCoordinator NVARCHAR(100);

        SET @pBookingRid = ( SELECT TOP(1) wBookingRid 
                             FROM dbo.eBookingRoom 
                             WHERE RowID=@pBookingRoomRowID 
        );

        INSERT INTO @vAdditionExpense (
            wRoomBookingRid,
            wCurrcode,
            wTotalAmt,
            wExpenseSubtype,
            wBookingStatus
        )
        SELECT TOP(1) ae.wRoomBookingRid ,
                      ae.wCurrcode ,
                      ae.wTotalAmt ,
                      ae.wExpenseSubtype,
                      ae.wBookingStatus
        FROM dbo.eAdditionalExpense ae
        INNER JOIN dbo.eActionAffectedTableLog aatl ON aatl.wRefTableName = 'eAdditionalExpense'
                                                                AND aatl.wNonceToken = @pGuid
                                                                AND ae.RowID = aatl.wRefRid
        WHERE aatl.wRefRid > 0;

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

        -- 乘客
        SET @sPassengerName = STUFF(
            (SELECT CONCAT(',', IIF(@pLangCd = 'en-gb', p.wEName, p.wCName))
            FROM dbo.ePassengerDetails pd
            LEFT JOIN mPerson p ON p.RowID = pd.wPersonRid
            WHERE pd.wStatus='A' 
                AND pd.wRoomBookingRid = @pBookingRoomRowID
            FOR XML PATH('')), 1, 1, '');

        -- Selecte Result
        SELECT  wIsMDAgent = @sIsMDAgent, -- MD轉介戶口
                wIsMDFollow = @sIsMDFollow, -- 非MD轉介的戶口, 跟進部部門為MD、要求同事為MD / VIP / FRONT
                wHeaderType = CAST(IIF( sc_debit.wCode IN ( 'CR', 'FY-MFM' ), 'SUNTRAVEL', 'SUNGROUP') AS VARCHAR(30)),--"碼頭服務部" 及 "中央訂務部"  --> 顯示 「太陽旅遊溫馨提示：」 ---> SUNTRAVEL  = CR, FY-MFM, AP-MFM (Not Sure)      tp.RowID ,
                bh.RowID ,
                bh.wBookingRid ,
                bh.wRequestRid ,
                wUseTravelAgency = br.wUseAgencyAllotment,
                br.wTravelAgencyRid ,
                bh.wRoomInProgress ,
                bh.wRoomCompleted ,
                bh.wRoomNotArrange ,
                bh.wRoomCancelled ,
                bh.wRoomUnQualified ,
                --bh.wQuantity ,
                CAST(1 AS INT) AS wQuantity ,
                bh.wRegion ,
                bh.wIsAgentHotel ,
                --bh.wStartDate ,
                --bh.wEndDate ,
                br.wStartDate ,
                br.wEndtDate AS wEndDate ,
                --bh.wDayOfStay ,
                br.wDayOfStay ,
                bh.wBedType ,
                br.wPaymentMethod ,
                bh.wReceiptNo ,
                bh.wRemark ,
                br.wQuickCollectKey ,
                br.wGetKeyPasscode ,
                br.wCurrCode ,
                br.wTotalAmount ,
                hr.wName AS wRoomName ,
                wHotelName = CASE WHEN br.wUseAgencyAllotment = 'Y' THEN h_ag.wName ELSE h.wName END,
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
                wReqAgentName = CASE WHEN @pLangCd = 'en-gb' THEN a_r.wEName ELSE a_r.wCName END  ,
                a_r.wAgentCode_Display AS wReqAgentCode_Display ,
                b.wDebitAgentCodeIn ,
                a_d.wCName AS wDebitAgentCName ,
                a_d.wEName AS wDebitAgentEName ,
                a_d.wAgentCode_Display AS wDebitAgentCode_Display ,
                b.wApprovalAgentCodeIn ,
                a_a.wCName AS wApprovalCName ,
                a_a.wEName AS wApprovalEName ,
                a_a.wAgentCode_Display AS wApprovalAgentCode_Display ,
                b.wCrtDt ,
                b.wCrtBy ,
                wCrtByName = CASE WHEN @pLangCd = 'en-gb' THEN u_crt.wName ELSE u_crt.wCName END  ,
                b.wUpdDt ,
                b.wUpdBy ,
                u.wName AS wUpdByEName ,
                u.wCName AS wUpdByCName ,
                wClientName = ISNULL(@sPassengerName, '') ,
                wServiceCounterTel = ISNULL(@sServiceCounterTel, '') ,
                sc_debit.wSMSName AS wServiceCounterName ,
                h.wSmsRemark ,
                wChargeAmount = ISNULL(cg.wTotalAmt, 0) ,
                wAmountChange = ( ISNULL(hc.wAmountChange, 0) * -1 ),
                cg.wBookingStatus AS wAdditionExpBookingStatus
        FROM dbo.eBookingRoom br
        INNER JOIN dbo.eBookingHotel bh ON br.wHotelBookingRid = bh.RowID
        INNER JOIN dbo.eBooking b ON br.wBookingRid = b.RowID
        LEFT JOIN dbo.eHotelChange hc ON hc.wRoomBookingRid = br.RowID AND hc.wAction = 'RF'
        LEFT JOIN dbo.mHotelRoom hr ON hr.RowID = br.wHotelRoomRid
        LEFT JOIN dbo.mHotel h ON h.RowID = hr.wHotelRid
        LEFT JOIN dbo.mHotel h_ag ON h_ag.RowID = br.wHotelRid
        LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = b.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr u_crt ON u_crt.RowID = b.wCrtBy
        LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = b.wReqAgentCodeIn
        LEFT JOIN RollsMary.dbo.mAgent a_d ON a_d.wAgentCodeIn = b.wDebitAgentCodeIn
        LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = b.wApprovalAgentCodeIn
        LEFT JOIN CRM.dbo.mServiceCounter sc_debit ON sc_debit.RowID = b.wDebitCounterRid
        LEFT JOIN @vAdditionExpense cg ON cg.wRoomBookingRid = br.RowID
        WHERE br.RowID = @pBookingRoomRowID;
    END;