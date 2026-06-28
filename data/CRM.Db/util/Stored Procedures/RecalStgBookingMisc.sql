CREATE PROCEDURE [util].[RecalStgBookingMisc]
	@pItemCd	VARCHAR(20) -- CUST_NAME
AS
BEGIN
	IF @pItemCd = 'CUST_NAME' BEGIN
		DELETE stg.eBookingMisc WHERE wItemCd = @pItemCd;

--非房間關聯的客戶名稱			
		INSERT INTO 
			[stg].[eBookingMisc] (wBookingRid, wLangCd, wItemCd, wValue)
		SELECT
			pdOut.wBookingRid, l.wLangCd, 
			wItem = @pItemCd, wValue = ISNULL(
			STUFF((
						SELECT ',' + CASE WHEN l.wLangCd = 'zh-TW' THEN p.wCName ELSE p.wEName END
						FROM  ePassengerDetails pd
						INNER JOIN mPerson p ON pd.wPersonRid = p.RowID AND pd.wStatus = 'A'
						WHERE pd.wBookingRid = pdOut.wBookingRid
						ORDER BY pd.wUpdDt
						For XML PATH ('')
					), 1,1,''), '')
		FROM ePassengerDetails pdOut
		CROSS JOIN (SELECT wLangCd = 'en-GB' UNION SELECT 'zh-TW') AS l
        LEFT JOIN eBooking eb ON eb.RowID = pdOut.wBookingRid
        WHERE eb.wBookingType!= 'HOTEL'
		GROUP BY pdOut.wBookingRid, l.wLangCd

--房間關聯的客戶名稱
        INSERT INTO 
			[stg].[eBookingMisc] (wBookingRid, wLangCd, wItemCd, wValue)
		SELECT
			er.wBookingRid, l.wLangCd, 
			wItem = @pItemCd, wValue = ISNULL(
			STUFF((
						SELECT ',' + CASE WHEN l.wLangCd = 'zh-TW' THEN p.wCName ELSE p.wEName END
						FROM  ePassengerDetails pd
						INNER JOIN mPerson p ON pd.wPersonRid = p.RowID AND pd.wStatus = 'A'
                        INNER JOIN eBookingRoom r ON pd.wRoomBookingRid >0 AND pd.wRoomBookingRid = r.RowID
						WHERE
							r.wBookingRid = er.wBookingRid
						ORDER BY pd.wUpdDt
						For XML PATH ('')
					), 1,1,''), '')
		FROM ePassengerDetails pdOut
		CROSS JOIN (SELECT wLangCd = 'en-GB' UNION SELECT 'zh-TW') AS l
        INNER JOIN eBookingRoom er ON pdOut.wRoomBookingRid >0 AND pdOut.wRoomBookingRid = er.RowID
		GROUP BY er.wBookingRid, l.wLangCd
	END
END