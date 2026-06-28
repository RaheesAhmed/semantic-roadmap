CREATE PROCEDURE [spq].[GetHotelChangeDateCheckInByBookingRoomId]
    @pBookingRoomId BIGINT ,
    @pHotelChangeRid BIGINT = 0 ,
    @pLangCd VARCHAR(10) = 'en-GB' ,
    @pIsForChangeCheckIn BIT = 0
AS
    BEGIN
        SET NOCOUNT ON;
        IF @pIsForChangeCheckIn = 1
            BEGIN
                SELECT  BR.[RowID] ,
						BR.wHotelRoomRid AS wBookingRid,
                        BR.[wHotelBookingRid] ,
                        BR.[RowID] AS [wRoomBookingRid] ,
                        BR.[wHotelRid] ,
                        BR.[wHotelRoomRid] ,
                        ALT.wName AS wAllotmentName ,
                        CAST(BR.wAllotmentGroupRid AS BIGINT) AS wAllotmentRid ,
                        BR.wOrderNo ,
                        BR.[wBedType] ,
                        BR.[wStartDate] ,
                        BR.[wEndtDate] ,
                        BR.[wDayOfStay] ,
                        BR.wPaymentMethod ,
                        BR.wCashReceiptNo AS wCashReceiptNo ,
                        BR.[wCashTransferReceiptNo] ,
                        BR.[wGetKeyMethod] ,
                        BR.[wCurrCode] ,
                        LUPC.wTitle AS wCurrency ,
                        BR.[wIncludeBreakfast] ,
                        BR.[wUseExtraAllotment] ,
                        BR.[wUseUpAllotment] ,
                        BR.[wTotalAmount] ,
                        BR.[wTotalCost] ,
                        BR.wIsExtraBed,
                        CONCAT((SELECT TOP 1 splitdata FROM dbo.Split(EBK.wRefNo, '-')), '-',
                               FORMAT(BR.wSeqNo, '000')) AS wRoomBookingRefNo ,
                        BR.wRoomNo ,
                        N'' AS wRemark ,
                        BR.[wUpdDt] ,
                        BR.[wUpdBy] ,
                        CAST(EBK.wReqUserRid AS BIGINT) AS wRequestStaffRid ,
                        CASE WHEN @pLangCd = 'en-gb' THEN USR.wName
                             ELSE USR.wCName
                        END AS wStaffReqForAmendments ,
                        CAST(CAST(GETDATE() AS DATE) AS DATETIME2) AS wDebitDate ,
                        CAST(COALESCE(EBK.wAsstBooker, '') AS NVARCHAR(200)) AS [wAssistanceBookerName] ,
                        EBK.wAssBookerTel AS [wAssistanceBookerPhone] ,
                        BR.[wStartDate] AS wNewStartDate ,
                        BR.[wEndtDate] AS wNewEndDate ,
                        BR.wUseMemberCard AS [UseBlackCard] ,
                        CAST('N' AS CHAR(1)) AS [UpdateCheckInPass] ,
                        '' AS [wAction] ,
                        BR.[wQuickCollectKey] AS wReGetKey ,
                        CAST('N' AS CHAR(1)) AS wIsHotelChangeRecord ,
                        EBK.wReqAgentCodeIn ,
                        EBK.wDebitCounterRid ,
                        EBK.wReqCounterRid ,
                        EBK.wDebitAgentCodeIn ,
                        EBK.wAsstBooker ,
                        EBK.wAssBookerTel ,
                        EBK.wReqCustomerRid ,
                        EBK.wDebitCustomerRid ,
                        EBK.wReqDepartment AS wReqDepartment ,
                        EBK.wReqUserRid ,
                        EBK.wApprovalAgentCodeIn ,
						EBK.wAsstBookerEmail,
						EBK.wDeptFollwedCd,
						EBK.wStaffFollwedRid,
						EBK.wStaffTelephone,
						EBK.wOwnerAuthTelephone,
                        CAST(0 AS NUMERIC(18, 4)) AS wAmountChange,
						CAST(0 AS NUMERIC(18, 4)) AS wCostChange,
						BR.wTotalAmount AS wCurrTotalAmount,
						BR.wTotalCost AS wCurrTotalCost,
						N'' AS wDateChange,
						 BR.[wStartDate] AS wCheckInDateChange,-- 入住日期變動,
						 BR.[wEndtDate] AS wCheckOutDateChange,--退房日期變動,
                         EBK.wCoordinator,
                         EBK.wIsUser,
                         EBK.wUser
                FROM    [dbo].[eBookingRoom] (NOLOCK) BR
                INNER JOIN dbo.eBooking (NOLOCK) EBK ON EBK.RowID = BR.wBookingRid
                LEFT JOIN dbo.mAllotmentGroup (NOLOCK) ALT ON ALT.RowID = BR.wAllotmentGroupRid
                LEFT JOIN RollsMary.dbo.[mUsr] (NOLOCK) USR ON USR.RowID = EBK.wReqUserRid
                LEFT JOIN [dbo].[mLookUp] (NOLOCK) LUPC ON LUPC.wCode = BR.wCurrCode
                                                        AND LUPC.wLangCd = @pLangCd
                                                        AND LUPC.wType = 'CURRENCY'
                WHERE BR.RowID = @pBookingRoomId AND BR.wStatus = 'A'
                ORDER BY BR.[wUpdDt] DESC;
            END;
        ELSE
            BEGIN
                SELECT  CNG.RowID ,
						CNG.wBookingRid,
                        BR.[wHotelBookingRid] ,
                        CNG.wRoomBookingRid ,
                        BR.[wHotelRid] ,
                        BR.[wHotelRoomRid] ,
                        ALT.wName AS wAllotmentName ,
                        CNG.wAllotmentRid ,
                        CNG.[wOrderNo] ,
                        BR.[wBedType] ,
                        CNG.wOriStartDate AS [wStartDate] ,
                        CNG.wOriEndDate AS [wEndtDate] ,
                        CNG.[wDayOfStay] ,
                        BR.wPaymentMethod ,
                        CNG.[wCashReceiptNo] ,
                        CNG.[wCashTransferReceiptNo] ,
                        CNG.[wGetKeyMethod] ,
                        CNG.[wCurrCode] ,
                        LUPC.wTitle AS wCurrency ,
                        BR.[wIncludeBreakfast] ,
                        CNG.[wUseExtraAllotment] ,
                        CNG.[wUseUpAllotment] ,
                        BR.[wTotalAmount] ,
                        BR.[wTotalCost] ,
                        BR.wIsExtraBed,
                        CONCAT((SELECT TOP 1 splitdata FROM dbo.Split(EBK.wRefNo, '-')), '-',
                                FORMAT(BR.wSeqNo, '000')) AS wRoomBookingRefNo ,
                        BR.wRoomNo ,
                        CNG.[wRemark] ,
                        BR.[wUpdDt] ,
                        CNG.[wUpdBy] ,
                        CAST(EBK.wReqUserRid AS BIGINT) AS wRequestStaffRid ,
                        CASE WHEN @pLangCd = 'en-gb' THEN USR.wName
                             ELSE USR.wCName
                        END AS wStaffReqForAmendments ,
                        --CAST(EBK.wDebitDt AS DATETIME2) AS wDebitDate ,
						--房間預訂--> 退款時填入的取消扣數日期，要自動帶入更改入住記錄> 退款記錄> 扣數日期
						CASE WHEN CNG.wAction='RF' THEN CAST(EBK.wCancelDebitDt AS DATETIME2) ELSE  CAST(EBK.wDebitDt AS DATETIME2) END AS wDebitDate ,
                        CAST(COALESCE(EBK.wAsstBooker, '') AS NVARCHAR(200)) AS [wAssistanceBookerName] ,
                        EBK.wAssBookerTel AS [wAssistanceBookerPhone] ,
                        CNG.wNewStartDate ,
                        CNG.wNewEndDate ,
                        CNG.wUseMemeberCard AS [UseBlackCard] ,
                        CNG.wChangeCheckinPwd AS [UpdateCheckInPass] ,
                        CNG.wAction ,
                        CNG.[wReGetKey] ,
                        CAST('Y' AS CHAR(1)) AS wIsHotelChangeRecord ,
                        EBK.wReqAgentCodeIn ,
                        EBK.wDebitCounterRid ,
                        EBK.wReqCounterRid ,
                        EBK.wDebitAgentCodeIn ,
                        EBK.wAsstBooker ,
                        EBK.wAssBookerTel AS wAssBookerTel ,
                        EBK.wReqCustomerRid ,
                        EBK.wDebitCustomerRid ,
                        EBK.wReqDepartment AS wReqDepartment ,
                        EBK.wReqUserRid AS wReqUserRid ,
                        EBK.wApprovalAgentCodeIn ,
						EBK.wAsstBookerEmail,
						EBK.wDeptFollwedCd,
						EBK.wStaffFollwedRid,
						EBK.wStaffTelephone,
						EBK.wOwnerAuthTelephone,
                        CNG.wAmountChange,
						CNG.wCostChange,
						CNG.wTotalAmount AS wCurrTotalAmount,  --更改入住记录后的总值
						CNG.wTotalCost AS wCurrTotalCost,	   --更改入住记录后的总成本
						CNG.wDateChange AS wDateChange,         --變動日期
						CASE CNG.wAction when 'C' THEN CNG.wNewStartDate
							when 'RF' THEN CNG.wOriStartDate
							when 'EX' THEN CNG.wOriEndDate
							when 'ECI' THEN CNG.wNewStartDate
							when 'LC' THEN CNG.wOriStartDate
							when 'ECO' THEN CNG.wNewEndDate
							END AS wCheckInDateChange, --入住日期變動,
						CASE CNG.wAction when 'C' THEN wNewEndDate
							when 'RF' THEN CNG.wOriEndDate
							when 'EX' THEN CNG.wNewEndDate
							when 'ECI' THEN CNG.wOriStartDate
							when 'LC' THEN CNG.wNewStartDate
							when 'ECO' THEN CNG.wOriEndDate
							END AS wCheckOutDateChange,--退房日期變動,
                            EBK.wCoordinator,
                            EBK.wIsUser,
                            EBK.wUser
                FROM    ( SELECT    *
                          FROM      [dbo].[eHotelChange] (NOLOCK)
                          WHERE     wRoomBookingRid = @pBookingRoomId
                                    AND ( @pHotelChangeRid = 0
                                          OR RowID = @pHotelChangeRid
                                        )
                        ) CNG
                        INNER JOIN ( SELECT *
                                     FROM   [dbo].eBookingRoom (NOLOCK)
                                     WHERE  RowID = @pBookingRoomId
                                            AND wStatus = 'A'
                                   ) BR ON BR.RowID = CNG.wRoomBookingRid
                        INNER JOIN dbo.eBooking (NOLOCK) EBK ON EBK.RowID = CNG.wBookingRid
                        LEFT JOIN dbo.mAllotmentGroup (NOLOCK) ALT ON ALT.RowID = BR.wAllotmentGroupRid
                        LEFT JOIN [dbo].[mLookUp] (NOLOCK) LUPC ON LUPC.wCode = BR.wCurrCode
                                                              AND LUPC.wLangCd = @pLangCd
                                                              AND LUPC.wType = 'CURRENCY'
                        LEFT JOIN RollsMary.dbo.[mUsr] (NOLOCK) USR ON USR.RowID = EBK.wReqUserRid
                ORDER BY CNG.[wUpdDt];
            END;
    END;