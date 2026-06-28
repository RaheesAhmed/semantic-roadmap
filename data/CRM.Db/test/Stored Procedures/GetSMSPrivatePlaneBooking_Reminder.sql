--sp_helptext 'spq.GetSMSPrivatePlaneBooking_Reminder'

CREATE PROCEDURE [test].[GetSMSPrivatePlaneBooking_Reminder]
	/*
		EXEC test.GetSMSPrivatePlaneBooking_Reminder '1000010180', '<DataSet><Record wBookingRid="10000000011554"/></DataSet>', '', 'zh-TW'		
	*/
    @pAgentCodeIn VARCHAR(14) ,
    @pBookingRidXML XML ,
    @pGuid VARCHAR(50) ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      

        SET @pLangCd = LOWER(@pLangCd);  
		
        DECLARE @sDocHandle INT;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pBookingRidXML;    
        SELECT  *
        INTO    #sData_BookingRid
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (wBookingRid BIGINT); 

		 SELECT   pd.wBookingRid ,
                                CASE WHEN @pLangCd = 'en-gb' THEN p.wEName
                                     ELSE p.wCName
                                END AS wName ,
                                pd.wClientTicketNo
                       FROM     dbo.ePassengerDetails pd
                                INNER JOIN #sData_BookingRid bk ON bk.wBookingRid = pd.wBookingRid
                                LEFT JOIN mPerson p ON p.RowID = pd.wPersonRid;

        WITH    ctePassengerData
                  AS ( SELECT   pd.wBookingRid ,
                                CASE WHEN @pLangCd = 'en-gb' THEN p.wEName
                                     ELSE p.wCName
                                END AS wName ,
                                pd.wClientTicketNo
                       FROM     dbo.ePassengerDetails pd
                                INNER JOIN #sData_BookingRid bk ON bk.wBookingRid = pd.wBookingRid
                                LEFT JOIN mPerson p ON p.RowID = pd.wPersonRid
                     )
            SELECT  bpp.wBookingRid ,
                    pprd.wCityCd wDepartCity ,
                    pprd.wIsReturn ,
                    pprd.wCityCd wDestination ,
                    pprd.wTakeOffDt wGoDepartTime ,
                    pprd.wArrivalDt wGoArrivalTime ,
                    pprd.wTakeOffDt wReturnDepartTime ,
                    pprd.wArrivalDt wReturnArrivalTime ,
                    pprd.wLine ,
                    bpp.wPlaneModel ,					
                 --   bpp.wSupplier ,
                 --   bpp.wHotelRid ,
                 --   bpp.wTravelAgencyRid ,
                 --   bpp.wSeatNo ,
                 --   bpp.wOrderNo ,
                 --   bpp.wIsSmoking ,
                 --   bpp.wServiceLang ,
                 --   bpp.wHasWifi ,
                    --bpp.wNoOfServiceStaff ,
                    --bpp.wExpenseAmt ,
                    --bpp.wTotalAmt ,
                    --bpp.wPaymentMethod ,
                    --bpp.wReceiptNo wRecieptNo ,
                    --bpp.wCurrency ,
                    --bpp.wExtraFee ,
                    --bpp.wConfirmPassengerNo ,
                    --bpp.wRemark ,
                    --bpp.wChangeOrderCount ,
                    --pprd.wStatus wChangeRouteStatus ,
                    --bpp.wBookingNo ,
                    --bpp.wCancelDate ,
                    --bpp.wCancelReason ,
                    CASE WHEN @pLangCd = 'en-gb' THEN a_go_dep.wEName
                         ELSE a_go_dep.wCName
                    END AS wGoDepartureCityName ,
                    a_go_dep.wCity AS wGoDepartureCityCode ,
                    CASE WHEN @pLangCd = 'en-gb' THEN a_go_arr.wEName
                         ELSE a_go_arr.wCName
                    END AS wGoArrivalCityName ,
                    a_go_arr.wCity AS wGoArrivalCityCode ,
                    CASE WHEN @pLangCd = 'en-gb' THEN a_rtn_dep.wEName
                         ELSE a_rtn_dep.wCName
                    END AS wReturnDepartureCityName ,
                    a_rtn_dep.wCity AS wReturnDepartureCityCode ,
                    CASE WHEN @pLangCd = 'en-gb' THEN a_rtn_arr.wEName
                         ELSE a_rtn_arr.wCName
                    END AS wReturnArrivalCityName ,
                    a_rtn_arr.wCity AS wReturnArrivalCityCode ,
                    b.wBookingType ,
                    b.wRefNo ,
                    b.GUID ,
                    b.wReqCounterRid ,
                    b.wDebitCounterRid ,
                    b.wReqCustomerRid ,
                    b.wDebitCustomerRid ,
                    b.wReqDepartment ,
                    b.wReqUserRid ,
                    b.wAsstBooker ,
                    b.wAssBookerTel ,
                    --b.wDebitDt ,
                    --b.wExpDt ,
                    --b.wCancelDebitDt ,
                    --b.wCancelReasonCd ,
                    --b.wCancelBy ,
                    --b.wCancelDt ,
                    --b.wTravePkgRid ,
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
                 --   tc.wTicCollPoint ,
                --    tcp.wName AS wTicketCollectionPointName ,
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
                           STUFF(( SELECT  ',' + ctePD.wName
                            FROM    ctePassengerData ctePD
                          FOR
                            XML PATH('')
                          ), 1, 1, '') AS wPassengerName ,
                   STUFF(( SELECT  ',' + ctePD.wClientTicketNo
                            FROM    ctePassengerData ctePD
                          FOR
                            XML PATH('')
                          ), 1, 1, '') AS wPassengerTicketNo ,
                    scc.wTel AS wServiceCounterTel ,
                    sc.wSMSName AS wServiceCounterName
            FROM    dbo.eBookingPrivatePlane bpp
                    INNER JOIN #sData_BookingRid bk ON bk.wBookingRid = bpp.wBookingRid
                    LEFT JOIN ePrivatePlaneRouteDtl pprd ON pprd.wBookingPrivatePlaneRid = bpp.RowID
                    LEFT JOIN CRM.dbo.eBooking b ON bpp.wBookingRid = b.RowID
                    LEFT JOIN mAirport a_go_dep ON a_go_dep.RowID = CAST(pprd.wDepartureAirportRid AS BIGINT)
                    LEFT JOIN mAirport a_go_arr ON a_go_arr.RowID = CAST(pprd.wArrivalAirportRid AS BIGINT)
                    LEFT JOIN mAirport a_rtn_dep ON a_rtn_dep.RowID = CAST(pprd.wDepartureAirportRid AS BIGINT)
                                                    AND pprd.wIsReturn = 'Y'
                    LEFT JOIN mAirport a_rtn_arr ON a_rtn_arr.RowID = CAST(pprd.wArrivalAirportRid AS BIGINT)
                                                    AND pprd.wIsReturn = 'Y'
                   -- LEFT JOIN CRM.dbo.eBookingCheckInService cis ON cis.RowId = b.RowID
                   -- LEFT JOIN CRM.dbo.eTicketCollection tc ON tc.wBookingRid = cis.wBookingRid
                  --  LEFT JOIN CRM.dbo.mTicketCollectionPoint tcp ON tcp.wCode = tc.wTicCollPoint
                    LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = b.wUpdBy
                    LEFT JOIN RollsMary.dbo.mUsr u_crt ON u_crt.RowID = b.wCrtBy
                    LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = b.wReqAgentCodeIn
                    LEFT JOIN RollsMary.dbo.mAgent a_d ON a_d.wAgentCodeIn = b.wDebitAgentCodeIn
                    LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = b.wApprovalAgentCodeIn
                    LEFT JOIN CRM.dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid
                                                            AND sc.wStatus = 'A'
                    LEFT JOIN CRM.dbo.mServiceCounterContact scc ON scc.wSeriverCounterRid = sc.RowID
                                                                    AND scc.wContactType = 'CSSMS' AND scc.wDepartmentCode = 'ROOM'
                   -- LEFT JOIN ctePassengerData ctePD ON ctePD.wBookingRid = bpp.wBookingRid
            WHERE   b.wApprovalAgentCodeIn = @pAgentCodeIn;
		
        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID('tempdb..#sData_BookingRid') IS NOT NULL
            DROP TABLE #sData_BookingRid;
    END;