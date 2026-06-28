CREATE PROCEDURE [sch].[SetReCollectionKeyDate]
AS
    BEGIN

-- This is running every day at 04:00 AM to reset Key Date if Reset Key date is today's date.
        SET NOCOUNT ON;

        UPDATE  EBK
        SET     EBK.wBookingStatus = 'C' ,
                EBK.wHasClientGetKey = 'N' ,
                EBK.wHasStaffGetKey = 'N' ,
                EBK.wReGetKeyDate = NULL ,
				-- 客戶說不要自動 gen 取房密碼了.. -- 2017-10-20 navin
                --EBK.wGetKeyPasscode = ( CAST(FLOOR(RAND(CHECKSUM(NEWID()))
                --                                   * ( 999944 - 1000 ) + 1000) AS VARCHAR(6)) ) ,
                EBK.wUpdDt = dbo.fnUTC8Now()
        FROM    dbo.eBookingRoom EBK
        WHERE   EBK.wStatus = 'A'
                AND EBK.wBookingStatus = 'CI'
                AND CAST(EBK.wReGetKeyDate AS DATE) = CAST(dbo.fnUTC8Now() AS DATE);

    END;