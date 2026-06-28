CREATE PROCEDURE [spa].[SeteVoucher]
(
    @pXML XML ,
    @pActionType CHAR(1) ,-- I/U/D   
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pBookingRid BIGINT ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
    BEGIN  
        SET NOCOUNT ON;  
        -- dbml
        /*
        SELECT
            RowID ,
            wVoucherRid ,
            wVoucherNo ,
            wVoucherType ,
            wAmount ,
            '' wServiceCounterName ,
            wCounterRid AS wServiceCounterRid ,
            wBookingRid ,
            wLineGrp ,
            wCurrCode ,
            wRemark ,
            wTicketType ,
            wSeqNo ,
            wStatus ,
            wCrtBy ,
            wCrtDt ,
            wUpdBy ,
            wUpdDt
        FROM    dbo.[eVoucher];  
        */
		         
        DECLARE @sThisTableName VARCHAR(50) = 'eVoucher' , -- For RowID  
                @sBeginTranCount INT = 0 ,
                @sRecCount INT = 0 ,
                @sRuningIndex INT = 1 ,
                @sRowID BIGINT = 0 ,
                @sDocHandle INT;  
     
        SET @sBeginTranCount = @@trancount;

        DECLARE @sReturnRowID TABLE ( RowID BIGINT );  
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;  
   
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
            *
        INTO    #sDataSet_SeteVoucher
        FROM    OPENXML (@sDocHandle, 'DataSet/SeteVoucherResult', 1)  
        WITH (  
            RowID BIGINT,  
            wVoucherRid BIGINT,  
            wVoucherNo VARCHAR(20),  
            wVoucherType NVARCHAR(50),  
            wAmount NUMERIC(18,4),  
            wServiceCounterName NVARCHAR(50),  
            wServiceCounterRid BIGINT,  
            wBookingRid BIGINT,  
            wLineGrp NVARCHAR(10),  
            wCurrCode VARCHAR(6),  
            wRemark NVARCHAR(500),  
            wTicketType VARCHAR(30),  
            wSeqNo INT ,  
            wStatus VARCHAR(3),      
            wUpdBy BIGINT ,  
            wUpdDt DATETIME2(7)  
        );  
       
 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...
	    
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking

			/*-------------------------------------------------------------------------------------------*/
			/*		Checking to prevent dupilicated Settle Vouchers   									*/
			/*-------------------------------------------------------------------------------------------*/
            DECLARE @errorMsg VARCHAR(MAX);
			;
            WITH    cteValidData
                      AS ( SELECT   m.RowID AS wVourcherRid ,
                                    m.wVoucherStatus ,
                                    m.wVoucherRefNo ,
                                    ISNULL(e.wBookingRid, @pBookingRid) AS wBookingRid ,
                                    v.wStatus AS wVoucherStatus_New
                           FROM     #sDataSet_SeteVoucher v
                                    INNER JOIN dbo.mVoucher m ON m.RowID = v.wVoucherRid
                                    LEFT JOIN dbo.eVoucher e ON e.wVoucherRid = m.RowID
                         ),
                    cteErrList
                      AS ( SELECT   ( CASE WHEN ( c.wVoucherStatus = 'I'
                                                  AND c.wVoucherStatus_New = 'I'
                                                  AND wBookingRid != @pBookingRid
                                                )
                                           THEN 'Duplicated settlement:' + CAST(wVoucherRefNo AS VARCHAR)
                                           ELSE 'Invalid Void Other Booking:' + CAST (wVoucherRefNo AS VARCHAR)
                                      END ) AS wErrInfo
                           FROM     cteValidData c
                           WHERE    ( 
						-- not allow to settle the other BookingRid that has already settled before
                                      ( c.wVoucherStatus = 'I'
                                        AND c.wVoucherStatus_New = 'I'
                                        AND wBookingRid != @pBookingRid
                                      )
                                      OR	 		 
						 -- not allow to termainate other BookingRid
                                      ( c.wVoucherStatus = 'I'
                                        AND c.wVoucherStatus_New = 'T'
                                        AND wBookingRid != @pBookingRid
                                      )
                                    )
                         )
                SELECT  @errorMsg = ISNULL(STUFF(( SELECT   ',' + e.wErrInfo
                                                   FROM     cteErrList e
                                                 FOR
                                                   XML PATH('')
                                                 ), 1, 1, ''), '');

            IF @errorMsg <> ''
                THROW 50001, @errorMsg, 1;

			/*---------------------------------------------------------------------------------------------------------------*/



            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

              
            IF @pActionType = 'I'
                BEGIN      
          
    -- Set RowID by Sequence  
                    UPDATE  #sDataSet_SeteVoucher
                    SET     RowID = 0;  
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SeteVoucher;  
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN  
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;  
       
                            UPDATE  #sDataSet_SeteVoucher
                            SET     RowID = @sRowID ,
                                    wBookingRid = @pBookingRid
                            WHERE   wRowNum = @sRuningIndex;  
                            SET @sRuningIndex = @sRuningIndex + 1;  
                        END;  
      
    -- MAIN Logic here, example here is inserting dataset to eIOUPenalty  
                    INSERT  INTO dbo.[eVoucher]
                            ( [RowID] ,
                              [wVoucherRid] ,
                              [wVoucherNo] ,
                              [wVoucherType] ,
                              [wAmount] ,
                              [wCounterRid] ,
                              [wBookingRid] ,
                              [wLineGrp] ,
                              [wCurrCode] ,
                              [wRemark] ,
                              [wTicketType] ,
                              [wSeqNo] ,
                              [wStatus] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt]  
                            )
                            SELECT  s.RowID ,
                                    s.wVoucherRid ,
                                    s.wVoucherNo ,
                                    s.wVoucherType ,
                                    s.wAmount ,
                                    s.wServiceCounterRid ,
                                    s.wBookingRid ,
                                    s.wLineGrp ,
                                    s.wCurrCode ,
                                    s.wRemark ,
                                    s.wTicketType ,
                                    s.wSeqNo ,
                                    s.wStatus ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    s.wUpdBy ,
                                    dbo.fnUTC8Now()
                            FROM    #sDataSet_SeteVoucher s;  
  
                    -- 把預訂相關的消費券設置為【已使用】
                    UPDATE  dbo.mVoucher
                    SET     wVoucherStatus = 'I' ,
                            wUpdBy = tmp.wUpdBy ,
                            wUpdDt = dbo.fnUTC8Now()
                    FROM    dbo.mVoucher AS mv
                    INNER JOIN #sDataSet_SeteVoucher tmp ON mv.RowID = tmp.wVoucherRid;  
                END;  
            ELSE
                IF @pActionType = 'U'
                    BEGIN                         
                        -- 刪除Delete前，先把預訂相關的消費券設置成【未使用】
                        -- 否則 如果不偉VoucherLst過來，消費券退不了
                        UPDATE  mv
                        SET     mv.wVoucherStatus = 'N'
                        FROM    dbo.eVoucher AS ev
                        INNER JOIN dbo.mVoucher AS mv ON mv.RowID = ev.wVoucherRid
                        WHERE  ev.wBookingRid = @pBookingRid

                        -- DELETE  dbo.eVoucher  WHERE wBookingRid IN ( SELECT  wBookingRid FROM #sDataSet_SeteVoucher );                     
                        DELETE  dbo.eVoucher
                        WHERE   wBookingRid = @pBookingRid;                  
                   
                        UPDATE  #sDataSet_SeteVoucher
                        SET     RowID = 0;  
                        SELECT  @sRecCount = COUNT(*)
                        FROM    #sDataSet_SeteVoucher;  
                        WHILE @sRuningIndex <= @sRecCount
                            BEGIN  
                                EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;  
       
                                UPDATE  #sDataSet_SeteVoucher
                                SET     RowID = @sRowID
                                WHERE   wRowNum = @sRuningIndex;  
                                SET @sRuningIndex = @sRuningIndex + 1;  
                            END;   
  
                        SELECT  *
                        INTO    #tmpDataSet_SeteVoucher
                        FROM    #sDataSet_SeteVoucher tmp
                        WHERE   tmp.wStatus <> 'T';   
  
                        INSERT  INTO dbo.[eVoucher]
                                ( [RowID] ,
                                  [wVoucherRid] ,
                                  [wVoucherNo] ,
                                  [wVoucherType] ,
                                  [wAmount] ,
                                  [wCounterRid] ,
                                  [wBookingRid] ,
                                  [wLineGrp] ,
                                  [wCurrCode] ,
                                  [wRemark] ,
                                  [wTicketType] ,
                                  [wSeqNo] ,
                                  [wStatus] ,
                                  [wCrtBy] ,
                                  [wCrtDt] ,
                                  [wUpdBy] ,
                                  [wUpdDt]  
                                )
                                SELECT  s.RowID ,
                                        s.wVoucherRid ,
                                        s.wVoucherNo ,
                                        s.wVoucherType ,
                                        s.wAmount ,
                                        s.wServiceCounterRid ,
                                        s.wBookingRid ,
                                        s.wLineGrp ,
                                        s.wCurrCode ,
                                        s.wRemark ,
                                        s.wTicketType ,
                                        s.wSeqNo ,
                                        s.wStatus ,
                                        s.wUpdBy ,
                                        dbo.fnUTC8Now() ,
                                        s.wUpdBy ,
                                        dbo.fnUTC8Now()
                                FROM    #tmpDataSet_SeteVoucher s;    
        
  
                        -- 把預訂相關的消費券設置為【已使用】
                        UPDATE mv
                        SET     wVoucherStatus = 'I' ,
                                wUpdBy = tmpv.wUpdBy ,
                                wUpdDt = dbo.fnUTC8Now()
                        FROM dbo.mVoucher AS mv
                        INNER JOIN #tmpDataSet_SeteVoucher tmpv ON mv.RowID = tmpv.wVoucherRid
                        WHERE   mv.RowID = tmpv.wVoucherRid;
                    END;    
                ELSE
                    IF @pActionType = 'D'
                    BEGIN      
                        -- 刪除Delete前，先把預訂相關的消費券設置成【未使用】
                        -- 否則 如果不偉VoucherLst過來，消費券退不了
                        UPDATE  mv
                        SET     mv.wVoucherStatus = 'N'
                        FROM    dbo.eVoucher AS ev
                        INNER JOIN dbo.mVoucher AS mv ON mv.RowID = ev.wVoucherRid
                        WHERE  ev.wBookingRid = @pBookingRid

                        -- DELETE  dbo.eVoucher WHERE wBookingRid IN ( SELECT  wBookingRid FROM #sDataSet_SeteVoucher );     
                        DELETE  dbo.eVoucher
                        WHERE   wBookingRid = @pBookingRid;                   
        
                        --Update status for mVoucher as Terminate  
                        UPDATE  mv
                        SET     wVoucherStatus = 'N' ,
                                wUpdBy = tmps.wUpdBy ,
                                wUpdDt = dbo.fnUTC8Now()
                        FROM    dbo.mVoucher AS mv
                        INNER JOIN #sDataSet_SeteVoucher tmps ON mv.RowID = tmps.wVoucherRid
                    END;  
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;
				
			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #tmpDataSet_SeteVoucher;			
					     
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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ',
                                  @vCatchErrorMessage);
			
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
		
        IF OBJECT_ID('tempdb..#sDataSet_SeteVoucher') IS NOT NULL
            DROP TABLE #sDataSet_SeteVoucher; 
     
    END;