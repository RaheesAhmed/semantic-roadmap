CREATE PROCEDURE [spq].[GetSMSRoomBooking_Reminder]
	/*
		
		exec spq.GetSMSRoomBooking_Reminder '1000044076', '<DataSet><Record wRoomBookingRid="10000000001059" wCheckInDate="2017-09-13"/></DataSet>',  '', 'zh-TW'
	*/
    @pAgentCodeIn VARCHAR(14) ,
    @pBookingRoomRidXML XML ,
    @pGuid VARCHAR(50) ,
    @pLangCd VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;
		-- dbml
		/*
		declare @vRtnList table (
			wCheckInDate DATETIME2(7),
			wHotelRid	BIGINT,
			wHotelName	NVARCHAR(200) NOT null,
			wNoOfRoom   INT,
			wAgentCodeIn VARCHAR(14) NOT NULL,
			wApprovalName NVARCHAR(80),
			wApprovalAgentCode_Display NVARCHAR(60),
			wSmsRemark NVARCHAR(2000)
		)
		Select * from @vRtnList
		return	
		*/

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;  
		
        SET @pLangCd = LOWER(@pLangCd);  
		
        DECLARE @sDocHandle INT;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pBookingRoomRidXML;    
       
        SELECT  *
        INTO    #sData_BookingRoomRid
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (wRoomBookingRid BIGINT, wCheckInDate DATE);     

	    ;
        WITH    cteHotelCheckIn
                  AS ( SELECT   hc.wRoomBookingRid
                       FROM     CRM.dbo.eHotelCheckIn hc
                                INNER JOIN CRM.dbo.eBookingRoom br ON hc.wRoomBookingRid = br.RowID
                                INNER JOIN #sData_BookingRoomRid rm ON rm.wRoomBookingRid = br.RowID
                                                                       AND rm.wCheckInDate = br.wStartDate
                       WHERE    hc.wStatus = 'A'
                                --AND hc.wExtent = 'N'
                                --AND hc.wAgencyRoom = 'N'
                                AND br.wBookingStatus = 'C'
                                AND br.wStatus = 'A'
                       GROUP BY hc.wRoomBookingRid
                     ),
                cteReminderList
                  AS ( SELECT   b.wApprovalAgentCodeIn ,
                                br.wHotelRid ,
                                br.wStartDate ,
                                COUNT(*) AS wNoOfRoom
                       FROM     CRM.dbo.eBookingRoom br
                                INNER JOIN cteHotelCheckIn hc ON hc.wRoomBookingRid = br.RowID
                                INNER JOIN #sData_BookingRoomRid rmbkg ON rmbkg.wRoomBookingRid = br.RowID
                                                                          AND rmbkg.wCheckInDate = br.wStartDate
                                --INNER JOIN eBookingHotel bh ON bh.RowID = br.wHotelBookingRid
                                INNER JOIN eBooking b ON b.RowID = br.wBookingRid
                                LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = b.wApprovalAgentCodeIn
                                LEFT JOIN mHotel h ON h.RowID = br.wHotelRid
                       WHERE    b.wApprovalAgentCodeIn <> ''
                                AND br.wBookingStatus = 'C'
                                AND br.wStatus = 'A'
                       GROUP BY b.wApprovalAgentCodeIn ,
                                br.wHotelRid ,
                                br.wStartDate
                     )
            SELECT  lst.wStartDate AS wCheckInDate ,
                    lst.wHotelRid ,
                    h.wName AS wHotelName ,
                    lst.wNoOfRoom ,
                    a_a.wAgentCodeIn ,
                    CASE WHEN @pLangCd = 'en-gb' THEN a_a.wEName
                         ELSE a_a.wCName
                    END AS wApprovalName ,
                    a_a.wAgentCode_Display AS wApprovalAgentCode_Display ,
                    h.wSmsRemark
            FROM    cteReminderList lst
                    LEFT JOIN RollsMary.dbo.mAgent a_a ON a_a.wAgentCodeIn = lst.wApprovalAgentCodeIn
                    LEFT JOIN mHotel h ON h.RowID = lst.wHotelRid;

        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID('tempdb..#sData_BookingRoomRid') IS NOT NULL
            DROP TABLE #sData_BookingRoomRid;
    END;