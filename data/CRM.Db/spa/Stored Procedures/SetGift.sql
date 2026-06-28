
CREATE PROCEDURE [spa].[SetGift]
    (
      @pXML XML ,
      @pMainCompNo INT ,
      @pTestMode INT = 0 , -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) OUTPUT
    )
/*
-- Test Call
DECLARE @pErrCode INT ,
    @pErrMsg NVARCHAR(200);
EXEC spa.SetGift @pXML = 
	N'<DataSet>
  <Record RowID="10000000001012" wRefBookingRid="123" wRefTableName="" wRefTableRid="0" wOriActionType="" wReqCounterRid="10000000010003" wCompNo="19" wCageCodeIn="" wReqDeptCd="CAGE" wReqStaffRid="1000000380" wReqAgentCodeIn="1000013269" wDate="2017-09-20 00:00:00.000000" wRecipient="Testing......" wCurrCode="HKD" wAmount="10.0000" wType="02" wSubType="0204" wRemark="test" wEventCodeRid="0" wStatus="A" wCrtDt="2017-09-20 16:22:49.658887" wCrtBy="1000000124" wUpdDt="2017-09-20 16:48:46.149520" wUpdBy="1000000124" RecordState="U" />
</DataSet>', -- xml
    @pMainCompNo = 10, -- int
    @pTestMode = 0, -- int
    @pNonceToken = '', -- varchar(64)
    @pReturnResultSet = 'Y', -- char(1)
    @pErrCode = @pErrCode OUTPUT, -- int
    @pErrMsg = @pErrMsg OUTPUT -- nvarchar(200)
SELECT @pErrCode, @pErrMsg
--
*/
AS
    BEGIN
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

		----------result set-----------
		--DECLARE @sResultSet TABLE (
		--  RowID  BIGINT
		--)     
		--SELECT * FROM @sResultSet; RETURN
		---------end result set--------

        DECLARE @sThisTableName VARCHAR(50) = 'eGift' ,
            @sBeginTranCount INT = 0 ,
            @sDocHandle INT ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sNow DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetGift
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
                RowID BIGINT,
                wRefBookingRid BIGINT,
                wRefTableName VARCHAR(50),
                wRefTableRid BIGINT,
                wOriActionType VARCHAR(50),
                wDebitCounterRid BIGINT, -- 扣數櫃台
                wReqCounterRid BIGINT,   -- 要求櫃台
                wCompNo INT,
                wCageCodeIn VARCHAR(14),
                wReqDeptCd VARCHAR(30),
                wReqStaffRid BIGINT,
                wReqAgentCodeIn VARCHAR(14),
                wDate DATE,
                wRecipient NVARCHAR(50),
                wCurrCode VARCHAR(6),
                wAmount NUMERIC(18, 4),
                wType VARCHAR(30),
                wSubType VARCHAR(30),
                wReasonCd VARCHAR(30),
                wIsReceived CHAR(1),
                wRemark NVARCHAR(500),
                wEventCodeRid BIGINT,
                wStatus CHAR(1),
                wCrtDt DATETIME2,
                wCrtBy BIGINT,
                wUpdDt DATETIME2,
                wUpdBy BIGINT,
                RecordState VARCHAR(1),
                wCost NUMERIC(18, 4)
         );
		        
        BEGIN TRY	                
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

			
			-- Validate wRefBookingRid
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetGift tmp
                                LEFT JOIN dbo.eBooking b ON tmp.wRefBookingRid = b.RowID
                        WHERE   ISNULL(tmp.wRefBookingRid, 0) > 0
                                AND b.RowID IS NULL )
                BEGIN
                    ;
                    THROW  50001, 'Booking reference number not exists', 1;				
                END;			

			-- Set Cage Code In
            WITH    cteCageList
                      AS ( SELECT   m.wCompNo ,
                                    MIN(m.wCageCodeIn) AS wCageCodeIn
                           FROM     RollsMary.dbo.mCage m
                                    INNER JOIN #sDataSet_SetGift e ON e.wCompNo = m.wCompNo
                           WHERE    m.wStatus = 'A'
                           GROUP BY m.wCompNo
                         )
                UPDATE  e
                SET     e.wCageCodeIn = cg.wCageCodeIn
                FROM    #sDataSet_SetGift e
                        INNER JOIN cteCageList cg ON e.wCompNo = cg.wCompNo;
			
		
			
        		
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetGift
                        WHERE   RecordState = 'I' )
                BEGIN
					-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetGift
                    SET     RowID = 0
                    WHERE   RecordState = 'I';

                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetGift;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetGift
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
                                    UPDATE  #sDataSet_SetGift
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;
                                END;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;	

                    INSERT  INTO [dbo].[eGift]
                            ( RowID ,
                              wRefBookingRid ,
                              wRefTableName ,
                              wRefTableRid ,
                              wOriActionType ,
                              wDebitCounterRid,
                              wReqCounterRid ,
                              wCompNo ,
                              wCageCodeIn ,
                              wReqDeptCd ,
                              wReqStaffRid ,
                              wReqAgentCodeIn ,
                              wDate ,
                              wRecipient ,
                              wCurrCode ,
                              wAmount ,
                              wType ,
                              wSubType ,
                              wReasonCd ,
                              wIsReceived ,
                              wRemark ,
                              wEventCodeRid ,
                              wStatus ,
                              wCrtDt ,
                              wCrtBy ,
                              wUpdDt ,
                              wUpdBy,
                              wCost
                            )
                            SELECT  RowID ,
                                    wRefBookingRid ,
                                    wRefTableName ,
                                    wRefTableRid ,
                                    wOriActionType ,
                                    wDebitCounterRid,
                                    wReqCounterRid ,
                                    wCompNo ,
                                    wCageCodeIn ,
                                    wReqDeptCd ,
                                    wReqStaffRid ,
                                    wReqAgentCodeIn ,
                                    wDate ,
                                    wRecipient ,
                                    wCurrCode ,
                                    wAmount ,
                                    wType ,
                                    wSubType ,
                                    wReasonCd ,
                                    wIsReceived ,
                                    wRemark ,
                                    wEventCodeRid ,
                                    wStatus ,
                                    wCrtDt ,
                                    wCrtBy ,
                                    wUpdDt ,
                                    wUpdBy,
                                    wCost
                            FROM    #sDataSet_SetGift
                            WHERE   RecordState = 'I';
                END;
			
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetGift
                        WHERE   RecordState = 'U' )
                BEGIN              
				 
                    UPDATE  g_t
                    SET     wRefBookingRid = tmp.wRefBookingRid ,
                            wRefTableName = tmp.wRefTableName ,
                            wRefTableRid = tmp.wRefTableRid ,
                            wOriActionType = tmp.wOriActionType ,
                            wDebitCounterRid = tmp.wDebitCounterRid,
                            wReqCounterRid = tmp.wReqCounterRid ,
                            wCompNo = tmp.wCompNo ,
                            wCageCodeIn = tmp.wCageCodeIn ,
                            wReqDeptCd = tmp.wReqDeptCd ,
                            wReqStaffRid = tmp.wReqStaffRid ,
                            wReqAgentCodeIn = tmp.wReqAgentCodeIn ,
                            wDate = tmp.wDate ,
                            wRecipient = tmp.wRecipient ,
                            wCurrCode = tmp.wCurrCode ,
                            wAmount = tmp.wAmount ,
                            wType = tmp.wType ,
                            wSubType = tmp.wSubType ,
                            wReasonCd = ISNULL(tmp.wReasonCd, '') ,
                            wIsReceived = ISNULL(tmp.wIsReceived, 'N') ,
                            wRemark = tmp.wRemark ,
                            wEventCodeRid = tmp.wEventCodeRid ,
                            wStatus = tmp.wStatus ,
                            wCrtDt = tmp.wCrtDt ,
                            wCrtBy = tmp.wCrtBy ,
                            wUpdDt = @sNow ,
                            wUpdBy = tmp.wUpdBy,
                            wCost = tmp.wCost
                    FROM    [dbo].[eGift] g_t
                            INNER JOIN #sDataSet_SetGift tmp ON g_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;


            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetGift
                        WHERE   RecordState = 'D' )
                BEGIN			
                    --;THROW 70002, 'Deleted operation is not allowed', 1;
                    UPDATE  g_t
                    SET     wStatus = 'T' ,
                            wUpdDt = @sNow
                    FROM    [dbo].[eGift] g_t
                            INNER JOIN #sDataSet_SetGift tmp ON g_t.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'D';
                END;          
			
            -- 【Calendar】-->【Mary】
            IF EXISTS (SELECT 1 FROM #sDataSet_SetGift WHERE ISNULL(RowID, 0) > 0) 
            BEGIN
                DECLARE c_Gift CURSOR FOR SELECT RowID FROM #sDataSet_SetGift WHERE ISNULL(RowID, 0) > 0;
                OPEN c_Gift;
                FETCH NEXT FROM c_Gift INTO @sRowID
                WHILE @@fetch_status = 0
                BEGIN
                    EXEC util.WriteMaryAgentActivitiesApiLog @pBookingRid = @sRowID, @pBookingType = 'eGift';

                    FETCH NEXT FROM c_Gift INTO @sRowID;
                END;
                CLOSE c_Gift;
                DEALLOCATE c_Gift;
            END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    IF @pTestMode = 1
                        ROLLBACK;
                    ELSE
                        COMMIT;
                END;

			-- Return RowID List
            IF @pReturnResultSet = 'Y'
                BEGIN
                    SELECT  RowID
                    FROM    #sDataSet_SetGift;
                END;
        END TRY
        BEGIN CATCH		
            DECLARE @sErrorNum INT ,
                @sCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @sProcedureName VARCHAR(100) ,
                @sRtnCodeLog INT ,
                @sErrMessageLog NVARCHAR(4000);

            SET @sErrorNum = ERROR_NUMBER();
            SET @pErrCode = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @sProcedureName = OBJECT_NAME(@@PROCID);
			
         
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 70001;
                END;

            SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
					
                    -- Write Log
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;             			                              
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;
        IF OBJECT_ID('tempdb..#sDataSet_SetGift') IS NOT NULL
            DROP TABLE #sDataSet_SetGift;
    END;