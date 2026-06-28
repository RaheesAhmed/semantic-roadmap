
CREATE PROCEDURE [spq].[GetBookingRoomByBookingRid]
    @pBookingRid BIGINT ,
    @pBookingRoomRid BIGINT ,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;	

        SET @pBookingRid = ISNULL(@pBookingRid, 0);
        SET @pBookingRoomRid = ISNULL(@pBookingRoomRid, 0);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-GB'));

        WITH tHotelChange AS (
            SELECT
                wRoomBookingRid ,
                wAction
            FROM dbo.eHotelChange
            WHERE wAction = 'EX'
            GROUP BY wRoomBookingRid , wAction
        ),
        tResult AS (
            SELECT 
                ROW_NUMBER() OVER ( ORDER BY br.RowID ) AS wSeqNo ,
                br.RowID ,
                br.wBookingRid ,
                ISNULL(hr.wRequestNo, '') AS wRequestNo ,
                br.wHotelBookingRid ,
                ISNULL(mh.wName, '') AS wHotelName ,
                ISNULL(mhr.wCode, '') AS wHotelRoomCode ,
                ISNULL(mhr.wName, '') AS wHotelRoomName ,
                eb.wRefNo ,
                eb.GUID ,
                br.wSeqNo AS wBookingSeqNo ,
                br.wRequestRid ,
                dbo.fnGetPersonNamesByRoomBookingID(br.RowID, @pLangCd) AS wClient ,
                br.wHotelRid ,
                br.wHotelRoomRid ,
                br.wTravelAgencyRid ,
                ISNULL(ALT.wName, '') AS wAllotmentName ,
                br.wAllotmentGroupRid ,
                br.wOrderNo ,
                br.wStartDate ,
                br.wEndtDate ,
                br.wDayOfStay ,
                br.wReceiptNo ,
                br.wStatus ,
                br.wVoucherNo ,
                br.wConfirmationNo ,
                br.wCashReceiptNo ,
                br.wCashTransferReceiptNo ,
                br.wGetKeyMethod ,
                br.wUseMemberCard ,
                br.wIncludeBreakfast ,
                br.wUseExtraAllotment ,
                br.wUseUpAllotment ,
                br.wTotalAmount ,
                br.wAdditionalFee ,
                br.wActualTotalAmount ,
                br.wTotalCost ,
                br.wRoomNo ,
                br.wGetKeyPasscode ,
                br.wHasStaffGetKey ,
                br.wHasClientGetKey ,
                br.wReGetKeyDate ,
                br.wSmsCount ,
                br.wIsConsigned ,
                br.wSameFloor ,
                br.wRoomExpenseState ,
                br.wCallCustomer ,
                br.wQuickCollectKey ,
                br.wIsCleaning ,
                br.wWarmReminderSMS ,
                br.wNoteRemark ,
                br.wIsConnectedRoom ,
                br.wRemark ,
                br.wCheckoutRemarks ,
                br.wPaymentMethod ,
                br.wCurrCode ,
                br.wBedType ,
                br.wCrtDt ,
                br.wCrtBy ,
                br.wUpdDt ,
                br.wUpdBy ,
                br.wRoomSMSSent ,
                br.wDisplayAgencyHotel ,
                br.wUseAgencyAllotment ,
                br.wBookingStatus ,
                br.wUnqualifiedRid ,
                br.wCounterRid ,
                ISNULL(mh.wIsBase, '') wIsBase ,
                e.wCancelDebitDt ,
                e.wCancelReasonCd ,
                e.wCancelBy ,
                e.wCancelDt ,
                e.wOtherReason ,
                wTravelPkgRid = e.wTravePkgRid ,
                e.wUseTravelPkg ,
                e.wEventCodeRid ,
                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END AS wUpdByCName ,
                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END AS wCreatedByCName ,
                CAST(( CASE WHEN chc.wRoomBookingRid IS NOT NULL THEN 1 ELSE 0 END ) AS BIT) AS wIsExtension ,
                e.wReqCounterRid ,
                e.wReqDepartment ,
                e.wAsstBooker ,
                e.wAssBookerTel ,
                e.wReqUserRid ,
                e.wApprovalAgentCodeIn ,
                e.wAsstBookerEmail ,
                e.wDeptFollwedCd ,
                e.wStaffFollwedRid ,
                e.wStaffTelephone ,
                e.wOwnerAuthTelephone ,
                e.wDebitCounterRid ,
                daAgent.wAgentCode_Display ,
                sc.wName AS wDebitServiceCounterName ,
                rqAgent.wAgentCode_Display AS wReqAgentCode_Display ,
                CASE WHEN @pLangCd = 'en-gb' THEN daAgent.wEName ELSE daAgent.wCName END AS wAgentCodeByName ,
                CASE WHEN @pLangCd = 'en-gb' THEN rqAgent.wEName ELSE rqAgent.wCName END AS wReqAgentCodeByName ,
                CASE WHEN @pLangCd = 'en-gb' THEN rqusr.wName ELSE rqusr.wCName END AS wReqUserRidByCName ,
                CASE WHEN @pLangCd = 'en-gb' THEN sfusr.wName ELSE sfusr.wCName END AS wStaffFollwedRidByCName ,
                CASE WHEN @pLangCd = 'en-gb' THEN mec.wEName ELSE mec.wCName END AS wEventCodeByName,
                br.wIsSmoke,
                br.wIsExtraBed
            FROM dbo.eBookingRoom AS br
            LEFT JOIN dbo.eBooking AS e ON br.wBookingRid = e.RowID
            LEFT JOIN mHotel mh ON mh.RowID = br.wHotelRid
            LEFT JOIN eBookingHotel ebh ON ebh.RowID = br.wHotelBookingRid
            LEFT JOIN eHotelRequest hr ON hr.RowID = ebh.wRequestRid
            LEFT JOIN eBooking eb ON eb.RowID = br.wBookingRid
            LEFT JOIN mHotelRoom mhr ON mhr.RowID = br.wHotelRoomRid
            LEFT JOIN dbo.mAllotmentGroup (NOLOCK) ALT ON ALT.RowID = br.wAllotmentGroupRid
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = br.wUpdBy
            LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = br.wCrtBy
            INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
            INNER JOIN [RollsMary].[dbo].[mAgent] rqAgent ON rqAgent.wAgentCodeIn = eb.wReqAgentCodeIn
            LEFT JOIN [RollsMary].[dbo].[mUsr] rqusr ON rqusr.RowID = eb.wReqUserRid
            LEFT JOIN [RollsMary].[dbo].[mUsr] sfusr ON sfusr.RowID = eb.wStaffFollwedRid
            INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
            LEFT JOIN tHotelChange chc ON chc.wRoomBookingRid = br.RowID
            LEFT JOIN dbo.mEventCode mec ON mec.RowID = eb.wEventCodeRid
            WHERE br.wStatus = 'A'
                AND (@pBookingRid > 0 OR @pBookingRoomRid >0 )
                AND ( @pBookingRid <= 0 OR br.wBookingRid = @pBookingRid )
                AND ( @pBookingRoomRid <= 0 OR br.RowID = @pBookingRoomRid )
            ),
            tCount AS (
                SELECT 
                    wRecordCount = COUNT(*)
                FROM tResult
            )
            
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
    END;