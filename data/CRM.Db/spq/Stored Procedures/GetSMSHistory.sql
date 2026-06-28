CREATE PROCEDURE [spq].[GetSMSHistory]
    @pReferRowID BIGINT ,
    @pSMSType VARCHAR(50)
AS
    BEGIN
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        CREATE  TABLE #SMSType_DS ( wType VARCHAR(50) );

        IF @pReferRowID > 0
            BEGIN
                INSERT  INTO #SMSType_DS
                        ( wType 
                        )
                        SELECT  DISTINCT wType
                        FROM    [RollsMary].[dbo].[eSMS] s
                        WHERE   s.wReferRid = @pReferRowID; 
            END;
        ELSE
            BEGIN 
                INSERT  INTO #SMSType_DS
                        ( wType
                        )
                        SELECT DISTINCT
                                wType
                        FROM    [RollsMary].[dbo].[eSMS] s; 
            END;

        WITH    cteSMSFilteredType
                  AS ( SELECT   wType
                       FROM     #SMSType_DS st
                       WHERE    st.wType LIKE @pSMSType + '%'
                                AND st.wType NOT LIKE '%REMINDER'
                     )
            SELECT  sm.RowID ,
                    sm.wRefRowID ,
                    sm.wLang ,
                    sm.wMessage ,
                    s.wType ,
                    s.wSendType ,
                    sd.wTel ,
                    sd.wSendDateTime ,
                    sd.wStatus
            FROM    [RollsMary].[dbo].[eSMS] AS s
                    INNER JOIN cteSMSFilteredType st ON st.wType = s.wType
                    INNER JOIN [RollsMary].[dbo].[eSMSMessage] AS sm ON s.RowID = sm.wRefRowID
                    LEFT JOIN [RollsMary].[dbo].[eSMSDtl] AS sd ON sm.wRefRowID = sd.wRefRowID
                                                                   AND sm.wLang = sd.wLang
            WHERE   s.wReferRid = @pReferRowID;     
			
        IF OBJECT_ID('tempdb..#SMSType_DS') IS NOT NULL
            DROP TABLE #SMSType_DS;              
    END;