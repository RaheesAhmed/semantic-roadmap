CREATE PROCEDURE [spa].[SetBookingAirTicket]
(
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pBookingRid BIGINT ,
    @pClientTicketId BIGINT OUTPUT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
    BEGIN
        SET NOCOUNT ON;
		
        DECLARE @sThisTableName VARCHAR(50) = 'eBookingAirTicket' , -- For RowID
                @sBeginTranCount INT = 0 ,
                @sRecCount INT = 0 ,
                @sRecCountDtl INT = 0 ,
                @sRuningIndex INT = 1 ,
                @sRuningIndexDtl INT = 1 ,
                @sRowID BIGINT = 0 ,
                @sRowIDDtl BIGINT = 0 ,
                @vNow DATETIME2 = dbo.fnUTC8Now() ,
                @sActionAffectedXML NVARCHAR(MAX) = '' ,
                @vMthEndYearMth VARCHAR(6) ,
                @vDateUsingCRM DATETIME2 ,
                @sDocHandle INT;

        DECLARE @sStatus VARCHAR(3)= '';
        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

        SET @sBeginTranCount = @@trancount;
        SET @vNow = dbo.fnUTC8Now();
	   
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
            *
        INTO    #sDataSet_SetBookingAirTicket
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
            RowID BIGINT,
            wBookingRid BIGINT,
            wOrderNo NVARCHAR(20),
            wSeqNo INT,
            wFlightType VARCHAR(30),
            wTravelAgencyRid BIGINT,
            wExpiryDt DATETIME2(7),
            wQuantity INT,
            wExpAmt NUMERIC(18,4),
            wTotalAmt NUMERIC(18,4),
            wTotalCost NUMERIC(18,4),
            wIsRefund CHAR(1),
            wChangeTicket VARCHAR(10), 
            wPaymentMethod  VARCHAR(30),
            wReceiptNo NVARCHAR(50),
            wCurrCode VARCHAR(10),
            wAdditionalExp NUMERIC(18,4),
            wBookingStatus VARCHAR(5),
            wUnqualifiedRid BIGINT,
            wRemark NVARCHAR(500),
            wUpdBy BIGINT,
            wUpdDt DATETIME2(7),
            wOldBookingStatus VARCHAR(5)
        );
/*
			IF EXISTS( SELECT * FROM eBookingAirTicket As AirTicket INNER JOIN #sDataSet_SetBookingAirTicket TEMPAIR ON TEMPAIR.wOrderNo = AirTicket.wOrderNo AND TEMPAIR.wBookingRid != AirTicket.wBookingRid WHERE ISNULL(TEMPAIR.wOrderNo, '') != '')
				throw 50001, 'Order Number already exist.', 1;

			DECLARE @errorMsg VARCHAR(MAX)='';

			 IF  @pActionType = 'U' BEGIN
						SELECT  @errorMsg = CASE								
										  When eb.wBookingStatus in ('RF','CL','UQ') AND  eb.wBookingStatus <> sb.wBookingStatus then eb.wBookingStatus + ' status can not be changed to status code ' + sb.wBookingStatus
										  When eb.wBookingStatus in ('C') AND  sb.wBookingStatus in ('P','CL','UQ') then eb.wBookingStatus + ' status can not be changed to status code ' + sb.wBookingStatus
										  When eb.wBookingStatus in ('P') AND  sb.wBookingStatus in ('RF','CO') then eb.wBookingStatus + ' status can not be changed to status code ' + sb.wBookingStatus
										  WHEN ISNULL(sb.wOrderNo,'')= '' THEN 'Order no is required.'
										  WHEN ISNULL(sb.wIsRefund,'')='' THEN 'Refund policy is required.'										  
										  WHEN ISNULL(sb.wChangeTicket,'')='' THEN 'Ticket change Policy is required.'
								 END
					FROM eBookingAirTicket eb inner join
						#sDataSet_SetBookingAirTicket sb ON eb.wBookingRid=sb.wBookingRid 
					INNER JOIN mLookUp lup ON lup.wCode = eb.wBookingStatus AND lup.wType = 'AIR_TICKET_STATUS' and lup.wlangCd='en-GB'			
			END	

			  IF(@errorMsg<>'')
					THROW 51000, @errorMsg, 1;  

					SELECT @errorMsg=CASE 						
						WHEN tmp.wTotalAmt < 0 THEN 'Total Amt cannot be blank'
						WHEN ISNULL(tmp.wPaymentMethod,'')='' THEN 'Paymethod is required.'						
						WHEN ISNULL(tmp.wFlightType,'')='' THEN 'Flight type is required.'
					END
				 FROM 
				#sDataSet_SetBookingAirTicket tmp

				  IF(@errorMsg<>'')
					THROW 51000, @errorMsg, 1;  

*/
        BEGIN TRY
            -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;


            --------------------------------------------------------------------------Checking-----------------------------------------------------------------------------
            DECLARE @sErrorMsg NVARCHAR(MAX);

            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType NOT IN ('I', 'U', 'D')
                SET @sErrorMsg = N'非法操作！';

            IF NULLIF(@sErrorMsg, '') IS NULL AND EXISTS ( SELECT * FROM #sDataSet_SetBookingAirTicket WHERE wBookingStatus = 'C' AND NULLIF(wOrderNo, '') IS NULL )
                SET @sErrorMsg = N'供應商單號不能為空！';

            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType IN ('U', 'D')
            BEGIN
                DECLARE @sBookingType VARCHAR(30) = 'AIRTICKET';
                DECLARE @sCurrentBookingStatus VARCHAR(5); -- DB当前状态
                DECLARE @sOldBookingStatus VARCHAR(5); -- 上一次Get數據時的狀態
                DECLARE @sNewBookingStatus VARCHAR(5); -- Save订单新状态
                DECLARE @sLangCd VARCHAR(10) = 'zh-TW';
                SELECT
                    @sCurrentBookingStatus = ebat.wBookingStatus, 
                    @sOldBookingStatus = sbat.wOldBookingStatus,
                    @sNewBookingStatus = sbat.wBookingStatus
                FROM dbo.eBookingAirTicket AS ebat 
                INNER JOIN #sDataSet_SetBookingAirTicket AS sbat ON sbat.RowID = ebat.RowID AND sbat.wBookingRid = ebat.wBookingRid
                WHERE ebat.wBookingRid = @pBookingRid;

                -- 獲取不到DB預訂當前狀態，訂單不存在（wBookingStatus IS NOT NULL）
                -- 如果已經有錯誤，不再Check
                IF NULLIF(@sErrorMsg, '') IS NULL AND @sCurrentBookingStatus IS NULL
                    SET @sErrorMsg = N'訂單不存在。';

                -- 如果已經有錯誤，不再Check
                IF NULLIF(@sErrorMsg, '') IS NULL
                    SET @sErrorMsg = dbo.fnGetBookingStatusErrorMsg(@pActionType, @sBookingType, @sCurrentBookingStatus, @sOldBookingStatus, @sNewBookingStatus, @sLangCd);
            
            END;

            IF NULLIF(@sErrorMsg, '') IS NOT NULL
                THROW 50001, @sErrorMsg, 1;
            ------------------------------------------------------------------------End Checking----------------------------------------------------------------------------

            IF @pActionType = 'I'
                BEGIN
					-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetBookingAirTicket
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetBookingAirTicket;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;

                            UPDATE  #sDataSet_SetBookingAirTicket
                            SET     RowID = @sRowID ,
                                    wBookingRid = @pBookingRid
                            WHERE   wRowNum = @sRuningIndex;
                            							
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;

					-- Insert Logic here, example here is inserting dataset to eBookingAirTicket Table
                    INSERT  INTO dbo.[eBookingAirTicket]
                            ( [RowID] ,
                              [wBookingRid] ,
                              [wOrderNo] ,
                              [wFlightType] ,
                              [wTravelAgencyRid] ,
                              [wExpiryDt] ,
                              [wQuantity] ,
                              [wExpAmt] ,
                              [wTotalAmt] ,
                              [wTotalCost] ,
                              [wIsRefund] ,
                              [wChangeTicket] ,
                              [wPaymentMethod] ,
                              [wReceiptNo] ,
                              [wCurrCode] ,
                              [wAdditionalExp] ,
                              [wBookingStatus] ,
                              [wUnqualifiedRid] ,
                              [wRemark] ,
                              [wSeqNo] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt]
							)
                            SELECT  batDataSet.RowID ,
                                    batDataSet.wBookingRid ,
                                    batDataSet.wOrderNo ,
                                    batDataSet.wFlightType ,
                                    batDataSet.wTravelAgencyRid ,
                                    batDataSet.wExpiryDt ,
                                    batDataSet.wQuantity ,
                                    batDataSet.wExpAmt ,
                                    batDataSet.wTotalAmt ,
                                    batDataSet.wTotalCost ,
                                    batDataSet.wIsRefund ,
                                    ISNULL(batDataSet.wChangeTicket, '') ,
                                    batDataSet.wPaymentMethod ,
                                    ISNULL(batDataSet.wReceiptNo, '') ,
                                    batDataSet.wCurrCode ,
                                    batDataSet.wAdditionalExp ,
                                    batDataSet.wBookingStatus ,
                                    ISNULL(batDataSet.wUnqualifiedRid, 0) ,
                                    batDataSet.wRemark ,
                                    batDataSet.wSeqNo ,
                                    batDataSet.wUpdBy ,
                                    @vNow ,
                                    batDataSet.wUpdBy ,
                                    @vNow
                            FROM    #sDataSet_SetBookingAirTicket batDataSet;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
					
                        SELECT TOP 1
                                @sStatus = wBookingStatus
                        FROM    #sDataSet_SetBookingAirTicket;
					
                        IF @sStatus <> 'CL'
                            OR @sStatus <> 'RF'
                            BEGIN
						--- Updating data into [eBookingAirTicket] table
                                UPDATE  bat
                                SET     bat.[wOrderNo] = tmp.wOrderNo ,
                                        bat.[wTravelAgencyRid] = tmp.wTravelAgencyRid ,
                                        bat.[wFlightType] = tmp.wFlightType ,
                                        bat.[wExpiryDt] = tmp.wExpiryDt ,
                                        bat.[wQuantity] = tmp.wQuantity ,
                                        bat.[wExpAmt] = tmp.wExpAmt ,
                                        bat.[wTotalAmt] = tmp.wTotalAmt ,
                                        bat.[wTotalCost] = tmp.wTotalCost ,
                                        bat.[wIsRefund] = tmp.wIsRefund ,
                                        bat.[wChangeTicket] = tmp.wChangeTicket ,
                                        bat.[wPaymentMethod] = tmp.wPaymentMethod ,
                                        bat.[wReceiptNo] = ISNULL(tmp.wReceiptNo, '') ,
                                        bat.[wCurrCode] = tmp.wCurrCode ,
                                        bat.[wAdditionalExp] = tmp.wAdditionalExp ,
                                        bat.[wBookingStatus] = tmp.wBookingStatus ,
                                        bat.[wUnqualifiedRid] = ISNULL(tmp.wUnqualifiedRid, 0) ,
                                        bat.[wRemark] = tmp.wRemark ,
                                        bat.[wSeqNo] = tmp.wSeqNo ,
                                        bat.[wUpdBy] = tmp.wUpdBy ,
                                        bat.[wUpdDt] = @vNow
                                FROM    dbo.[eBookingAirTicket] AS bat
                                        INNER JOIN #sDataSet_SetBookingAirTicket tmp ON bat.wBookingRid = tmp.wBookingRid
                                WHERE   bat.wBookingRid = tmp.wBookingRid;
                            END;					
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                            SELECT  @sStatus = wBookingStatus
                            FROM    dbo.[eBookingAirTicket]
                            WHERE   RowID = ( SELECT TOP 1
                                                        RowID
                                              FROM      #sDataSet_SetBookingAirTicket
                                            );
					
					--UPDATE PSD
					--SET PSD.wPassengerBookingStatus= (CASE WHEN (PSD.wPassengerBookingStatus='C' OR PSD.wPassengerBookingStatus='RF') THEN 'RF'
					--									  WHEN (PSD.wPassengerBookingStatus='P' OR PSD.wPassengerBookingStatus='UQ') THEN 'CL'
					--									  ELSE 'CL'
					--									  END),		
					--	PSD.wStatus= 'T',			
					--	PSD.wUpdDt=@vNow,
					--	PSD.wUpdBy=tmp.wUpdBy
					--FROM dbo.ePassengerDetails PSD					
					--INNER JOIN #sDataSet_SetBookingAirTicket tmp ON PSD.wBookingRid = tmp.wBookingRid AND PSD.wStatus='A' AND PSD.wPassengerBookingStatus IN ('P','C');	

                            UPDATE  at
                            SET     at.wBookingStatus = 'DL' ,
                                    at.wStatus = 'T' ,
                                    at.wUpdDt = @vNow ,
                                    at.wUpdBy = tmp.wUpdBy
                            FROM    dbo.eBookingAirTicket at
                                    INNER JOIN #sDataSet_SetBookingAirTicket tmp ON at.RowID = tmp.RowID;

                            DECLARE @BookingRid BIGINT = ( SELECT TOP 1
                                                              wBookingRid
                                                           FROM #sDataSet_SetBookingAirTicket
                                                         );

                            UPDATE  ePassengerDetails
                            SET     wPassengerBookingStatus = 'DL' ,
                                    wStatus = 'T'
                            WHERE   wBookingRid = @BookingRid
                                    AND wPassengerBookingStatus = 'P';
                            DECLARE @sAmount NUMERIC(18, 4)= 0 ,
                                @sCost NUMERIC(18, 4)= 0;
					
                            SELECT  @sCost = SUM(wCost) ,
                                    @sAmount = SUM(wAmount)
                            FROM    dbo.ePassengerDetails
                            WHERE   wBookingRid = ( SELECT TOP 1
                                                            wBookingRid
                                                    FROM    #sDataSet_SetBookingAirTicket
                                                  )
                                    AND wStatus = 'A'
                                    AND ( wPassengerBookingStatus = 'P'
                                          OR wPassengerBookingStatus = 'C'
                                        );

					-------- Update status while action is delete
					--UPDATE ebat
					--	SET 
					--	ebat.wBookingStatus = (CASE WHEN (@sStatus='C' OR @sStatus='RF') THEN 'RF' ELSE 'CL' END),
					--	ebat.wTotalAmt=ISNULL(@sAmount,0),
					--	ebat.wTotalCost=ISNULL(@sCost,0),
					--	ebat.wUpdDt = @vNow,
					--	ebat.wUpdBy = tmp.wUpdBy
					--FROM dbo.[eBookingAirTicket] AS ebat
					--INNER JOIN #sDataSet_SetBookingAirTicket tmp ON ebat.RowID = tmp.RowID;

                        END;

			---------------------------------------------------------------------------------------------
			-- SetActionAffectedTableLog
			---------------------------------------------------------------------------------------------
            SET @sActionAffectedXML = ( SELECT  wActionSp = OBJECT_NAME(@@PROCID) ,
                                                wActionType = @pActionType ,
                                                wNonceToken = @pNonceToken ,
                                                wRefTableName = @sThisTableName ,
                                                wRefRid = tmp.RowID ,
                                                wType = '' ,
                                                wCrtDt = @vNow
                                        FROM    #sDataSet_SetBookingAirTicket tmp
                                      FOR
                                        XML RAW('Record') ,
                                            ROOT('DataSet')
                                      );
            EXEC spa.SetActionAffectedTableLog @sActionAffectedXML, 'I', @pMainCompNo, '', 0, '';


            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetBookingAirTicket;

            RETURN;

        END TRY
        BEGIN CATCH
            DECLARE @vErrorNum INT ,
                @vCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @vProcedureName VARCHAR(100) ,
                @vRtnCodeLog INT ,
                @vErrMessageLog NVARCHAR(4000);
	        
            SET @vErrorNum = ERROR_NUMBER();
            SET @vCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @vProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ', @vCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                BEGIN
                    IF @xstate != 0
                        ROLLBACK;
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetBookingAirTicket') IS NOT NULL
            DROP TABLE #sDataSet_SetBookingAirTicket;
    END;