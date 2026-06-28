CREATE PROCEDURE [spq].[GetSMSAirTicketBooking_Reminder]
	/*
		EXEC CRM.spq.GetSMSAirTicketBooking_Reminder '1000044076', N'<DataSet><Record wPassengerRid="10000000010935" wPassengerName="陳小明、陳大陸" wIsWait="|2_Y||||3_Y"/></DataSet>', '', 'zh-TW'		
	*/
    @pAgentCodeIn VARCHAR(14) ,
    @pPassengerRidXML XML ,
    @pGuid VARCHAR(50) ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;		
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;    
		
        SET @pLangCd = LOWER(@pLangCd);  

        DECLARE @sDocHandle INT;
		
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pPassengerRidXML;    
        SELECT  *
        INTO    #sData_PassengerRid
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (wPassengerRid BIGINT, wPassengerName NVARCHAR(MAX), wIsWait VARCHAR(MAX)); 

        DECLARE @sIsWaitList VARCHAR(MAX);

        SELECT TOP 1
                @sIsWaitList = wIsWait
        FROM    #sData_PassengerRid;
	
        WITH    cteList
                  AS ( SELECT   item
                       FROM     dbo.fnSplit(@sIsWaitList, '|')
                       WHERE    item != ''
                       GROUP BY item
                     )
            SELECT  CAST(REPLACE(item, '_Y', '') AS INT) AS wLineIsWait
            INTO    #sData_WaitLst
            FROM    cteList;

		
        SELECT  CAST(( CASE WHEN sc.wCode IN ( 'CR', 'FY-MFM' ) THEN 'SUNTRAVEL'
                            ELSE 'SUNGROUP'
                       END ) AS VARCHAR(30)) AS wHeaderType ,				--"碼頭服務部" 及 "中央訂務部"  --> 顯示 「太陽旅遊溫馨提示：」 ---> SUNTRAVEL  = CR, FY-MFM, AP-MFM (Not Sure)                
                airt.wFlightType AS wBookingFlightType ,
                airt.wExpiryDt AS wExpiryDate ,
                atrd.wDepartureTerminal ,
                a_dep.wEName AS wDepartureCityName ,
                CASE WHEN @pLangCd = 'en-gb' THEN a_dep.wEName
                     ELSE a_dep.wCName
                END AS wDepartureCityName ,
                a_dep.wCity AS wDepartureCityCode ,
                atrd.wArrivalTerminal ,
                CASE WHEN @pLangCd = 'en-gb' THEN a_arr.wEName
                     ELSE a_arr.wCName
                END AS wArrivalCityName ,
                a_arr.wCity AS wArrivalCityCode ,
                atrd.wClassCd ,
                atrd.wPNRNo ,
                atrd.wLine ,
                atrd.wFlightType ,
                atrd.wAirline ,
                atrd.wClassCd ,
                atrd.wIsReturn ,
                atrd.wDepartFlightNo ,
                atrd.wTakeOffDt AS wTakeOffDateTime ,
                atrd.wArrivalDt AS wArrivalDateTime ,
                CAST(CASE WHEN w.wLineIsWait IS NOT NULL THEN 'Y'
                          ELSE 'N'
                     END AS CHAR(1)) AS wIsWaiting ,
				-- dbml
                --CAST('Y' AS CHAR(1)) AS wIsWaiting ,
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
                b.wUpdDt ,
                b.wUpdBy ,
                CASE WHEN @pLangCd = 'en-gb' THEN u.wName
                     ELSE u.wCName
                END AS wUpdByName ,
				--dbml
                --CAST('' AS NVARCHAR(MAX)) AS wPassengerName ,
                pd.wPassengerName ,
                scc.wTel AS wServiceCounterTel ,
                sc.wSMSName AS wServiceCounterName
        FROM    CRM.dbo.ePassengerDetails pax
                INNER JOIN #sData_PassengerRid pd ON pd.wPassengerRid = pax.RowID
                INNER JOIN CRM.dbo.eBookingAirTicket airt ON airt.wBookingRid = pax.wBookingRid
                INNER JOIN CRM.dbo.eAirTicketRouteDtl atrd ON pax.RowID = atrd.wTypeRid
                                                              AND atrd.wType = 'PASSENGER'
                                                              AND atrd.wStatus = 'A'
                INNER JOIN CRM.dbo.eBooking b ON b.RowID = pax.wBookingRid
                LEFT JOIN CRM.dbo.mPerson p ON p.RowID = pax.wPersonRid
                LEFT JOIN mAirport a_dep ON a_dep.RowID = atrd.wDepartureAirportRid
                LEFT JOIN mAirport a_arr ON a_arr.RowID = atrd.wArrivalAirportRid
                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = b.wUpdBy
                LEFT JOIN RollsMary.dbo.mUsr u_crt ON u_crt.RowID = b.wCrtBy
                LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = b.wReqAgentCodeIn
                LEFT JOIN RollsMary.dbo.mAgent a_d ON a_d.wAgentCodeIn = b.wDebitAgentCodeIn
                LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = b.wApprovalAgentCodeIn
                LEFT JOIN CRM.dbo.mServiceCounter sc ON sc.RowID = b.wDebitCounterRid
                                                        AND sc.wStatus = 'A'
                LEFT JOIN CRM.dbo.mServiceCounterContact scc ON scc.wSeriverCounterRid = sc.RowID
                                                                AND scc.wContactType = 'CSSMS' AND scc.wDepartmentCode = 'ROOM'
                LEFT JOIN #sData_WaitLst w ON w.wLineIsWait = atrd.wLine
        WHERE   b.wApprovalAgentCodeIn = @pAgentCodeIn;
		
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sData_PassengerRid') IS NOT NULL
            DROP TABLE #sData_PassengerRid;

        IF OBJECT_ID('tempdb..#sData_WaitLst') IS NOT NULL
            DROP TABLE #sData_WaitLst;
    END;