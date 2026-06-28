CREATE PROCEDURE [spq].[GetSMSHotelChange]
    @pHotelChangeRowId BIGINT ,
    @pGuid VARCHAR(50) ,
    @pLangCd VARCHAR(30)
    
-- TEST case
-- EXEC spq.GetSMSHotelChange 10000000001425, 'x222','zh-TW'
--
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pLangCd = LOWER(ISNULL(NULLIF(@pLangCd, ''), 'zh-tw'));

        DECLARE @vAdditionExpense TABLE (
            wHotelChangeRid     BIGINT,
            wRoomBookingRid     BIGINT,
            wCurrcode           VARCHAR(30),
            wTotalAmt           NUMERIC(18, 4),
            wExpenseSubtype     BIGINT,
            wBookingStatus      VARCHAR(5)
        );

        -- eBookingRoom.RowID
        DECLARE @pBookingRoomRid BIGINT;
        -- eBooking.RowID
        DECLARE @pBookingRid BIGINT;
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

        SET @pBookingRoomRid = ( SELECT TOP(1) wRoomBookingRid
                                 FROM dbo.eHotelChange
                                 WHERE RowID = @pHotelChangeRowId
        );

        SET @pBookingRid = ( SELECT TOP(1) wBookingRid
                                 FROM dbo.eHotelChange
                                 WHERE RowID = @pHotelChangeRowId
        ); 

        INSERT INTO @vAdditionExpense(
            wHotelChangeRid,
            wRoomBookingRid,
            wCurrcode,
            wTotalAmt,
            wExpenseSubtype,
            wBookingStatus
        )
        SELECT TOP 1 @pHotelChangeRowId,			-- Force to join
                     ae.wRoomBookingRid ,
                     ae.wCurrcode ,
                     ae.wTotalAmt ,
                     ae.wExpenseSubtype ,
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
                AND pd.wRoomBookingRid = @pBookingRoomRid
            FOR XML PATH('')), 1, 1, '');

            -- Selecte Result
        SELECT  wIsMDAgent = @sIsMDAgent, -- MD轉介戶口
                wIsMDFollow = @sIsMDFollow, -- 非MD轉介的戶口, 跟進部部門為MD、要求同事為MD / VIP / FRONT
                wHeaderType = CAST(IIF( sc_debit.wCode IN ( 'CR', 'FY-MFM' ), 'SUNTRAVEL', 'SUNGROUP') AS VARCHAR(30)),--"碼頭服務部" 及 "中央訂務部"  --> 顯示 「太陽旅遊溫馨提示：」 ---> SUNTRAVEL  = CR, FY-MFM, AP-MFM (Not Sure)      tp.RowID ,
                hc.RowID ,
                b.wRefNo ,
                b.wReqAgentCodeIn ,
                b.wAsstBooker ,
                b.wAssBookerTel ,
                wUseTravelAgency = br.wUseAgencyAllotment,
                br.wTravelAgencyRid ,
                wCoordinator = IIF(@sIsMDAgent = 'Y' OR @sIsMDFollow = 'Y', ISNULL(@sCoordinator, ''),  b.wCoordinator),
                b.wUser,
                b.wIsUser,
                wReqByName = ISNULL(@sReqByName, '') ,
                wReqAgentName = CASE WHEN @pLangCd = 'en-gb' THEN a_r.wEName ELSE a_r.wCName END ,
                wReqAgentCode_Display = a_r.wAgentCode_Display ,
                wDebitAgentName = CASE WHEN @pLangCd = 'en-gb' THEN a_d.wEName ELSE a_d.wCName END ,
                wDebitAgentCode_Display = a_d.wAgentCode_Display ,
                wApprovalName = CASE WHEN @pLangCd = 'en-gb' THEN a_a.wEName ELSE a_a.wCName END ,
                wApprovalAgentCode_Display = a_a.wAgentCode_Display ,
                wChangeType = CASE WHEN hc.wOriStartDate > hc.wNewStartDate THEN 'EARLY'
                                   WHEN hc.wOriStartDate < hc.wNewStartDate THEN 'LATE'
                                   WHEN hc.wNewStartDate > hc.wOriEndDate   THEN 'EXTEND'
                                   WHEN hc.wNewStartDate < hc.wOriEndDate   THEN 'LEAVE_EARLY'
                                   ELSE '' END , -- 更改類型
                hc.wDayOfStay ,
                hc.wOriStartDate ,
                hc.wOriEndDate ,
                hc.wNewStartDate ,
                hc.wNewEndDate ,
                wNewDayOfStay = DATEDIFF(DAY, hc.wNewStartDate, hc.wNewEndDate) ,
                wDayOfStayChange = DATEDIFF(DAY, 
                              ( CASE hc.wAction WHEN 'C'    THEN hc.wNewStartDate
                                                WHEN 'RF'   THEN hc.wOriStartDate
                                                WHEN 'EX'   THEN hc.wOriEndDate
                                                WHEN 'ECI'  THEN hc.wNewStartDate
                                                WHEN 'LC'   THEN hc.wOriStartDate
                                                WHEN 'ECO'  THEN hc.wNewEndDate
                                                ELSE hc.wNewStartDate END ), 
                              ( CASE hc.wAction WHEN 'C'    THEN hc.wNewEndDate
                                                WHEN 'RF'   THEN hc.wOriEndDate
                                                WHEN 'EX'   THEN hc.wNewEndDate
                                                WHEN 'ECI'  THEN hc.wOriStartDate
                                                WHEN 'LC'   THEN hc.wNewStartDate
                                                WHEN 'ECO'  THEN hc.wOriEndDate
                                                ELSE hc.wNewEndDate END )
                ) ,
                wCheckInDateChange = CASE hc.wAction  WHEN 'C' THEN hc.wNewStartDate
                                                      WHEN 'RF' THEN hc.wOriStartDate
                                                      WHEN 'EX' THEN hc.wOriEndDate
                                                      WHEN 'ECI' THEN hc.wNewStartDate
                                                      WHEN 'LC' THEN hc.wOriStartDate
                                                      WHEN 'ECO' THEN hc.wNewEndDate
                                                      ELSE hc.wNewStartDate END ,		--入住日期變動
                wCheckOutDateChange = CASE hc.wAction WHEN 'C' THEN hc.wNewEndDate
                                                      WHEN 'RF' THEN hc.wOriEndDate
                                                      WHEN 'EX' THEN hc.wNewEndDate
                                                      WHEN 'ECI' THEN hc.wOriStartDate
                                                      WHEN 'LC' THEN hc.wNewStartDate
                                                      WHEN 'ECO' THEN hc.wOriEndDate
                                                      ELSE hc.wNewEndDate END ,		--退房日期變動,					
                hc.wCurrCode ,
                wAmount = ABS(hc.wAmountChange),
                br.wGetKeyPasscode ,
                wRoomName = CASE @pLangCd WHEN 'zh-TW' THEN hr.wName
                                          WHEN 'ja-JP' THEN hr.wJname
                                          WHEN 'ko-KR' THEN hr.wKname
                                          WHEN 'th-TH' THEN hr.wThname
                                          ELSE hr.wEname END ,
                wHotelName = CASE @pLangCd WHEN 'zh-TW' THEN h.wName
                                           WHEN 'ja-JP' THEN h.wJname
                                           WHEN 'ko-KR' THEN h.wKname
                                           WHEN 'th-TH' THEN h.wThname
                                           ELSE h.wEname END ,
                wClientName =  ISNULL(@sPassengerName, '')  ,
                hc.wUpdDt ,
                wUpdByName = CASE WHEN @pLangCd = 'en-gb' THEN u.wName ELSE u.wCName END ,
                wServiceCounterTel = ISNULL(@sServiceCounterTel, '') ,
                wServiceCounterName = sc_debit.wSMSName ,
                br.wRoomNo ,
                h.wSmsRemark ,
                wChargeAmount = ISNULL(cg.wTotalAmt, 0),
				hc.wGetKeyMethod,
                wAdditionExpBookingStatus = cg.wBookingStatus,
                br.wPaymentMethod
        FROM dbo.eHotelChange hc
        INNER JOIN dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID AND br.wStatus = 'A'
        INNER JOIN dbo.eBooking b ON hc.wBookingRid = b.RowID
        LEFT JOIN dbo.mServiceCounter sc_debit ON sc_debit.RowID = b.wDebitCounterRid
        LEFT JOIN dbo.mHotelRoom hr ON hr.RowID = br.wHotelRoomRid
        LEFT JOIN dbo.mHotel h ON h.RowID = br.wHotelRid
        LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = b.wReqAgentCodeIn
        LEFT JOIN RollsMary.dbo.mAgent a_d ON a_d.wAgentCodeIn = b.wDebitAgentCodeIn
        LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = b.wApprovalAgentCodeIn
        LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = hc.wUpdBy
        LEFT JOIN @vAdditionExpense cg ON cg.wHotelChangeRid = hc.RowID
        WHERE hc.RowID = @pHotelChangeRowId;
    END;