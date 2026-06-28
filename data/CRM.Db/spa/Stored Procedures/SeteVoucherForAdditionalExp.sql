CREATE PROCEDURE [spa].[SeteVoucherForAdditionalExp]
(
  @pXML XML ,
  @pActionType CHAR(1) ,-- I/U/D 
  @pMainCompNo INT ,	  
  @pNonceToken VARCHAR(64),
  @pReturnResultSet CHAR(1) = 'N',
  @pOldBookingRid BigINT,
  @pNewBookingRid BigINT,
  @pErrCode INT = 0 OUTPUT ,
  @pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
    BEGIN
        SET NOCOUNT ON;
			  
	    DECLARE @sThisTableName VARCHAR(50) = 'eVoucher' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
			
	        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

		SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

	    EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SeteVoucher
        FROM    OPENXML (@sDocHandle, 'DataSet/SetAdditionalExpVoucherResult', 1)
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
				wStatus CHAR(1) ,				
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7)
			);

			DECLARE @Count int 
			Select @Count = Count(*) From #sDataSet_SeteVoucher

			print @Count

		 --better don't put everything within try, for example
	     --getting mSysTable value
	     --getting currency, period, mCompany ...

		  BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	  
	                    DELETE from #sDataSet_SeteVoucher WHERE wBookingRid != @pOldBookingRid
						
						DELETE FROM dbo.[eVoucher] WHERE wBookingRid = @pOldBookingRid
          
		                SELECT * INTO #sDataSet_SeteVoucher2 
			 FROM (SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ), 
					  RowID,
					  wVoucherRid,
					  wVoucherNo,
					  wVoucherType,
					  wAmount,
					  wServiceCounterName,
					  wServiceCounterRid,
					  wBookingRid,
					  wLineGrp,
					  wCurrCode,
					  wRemark,
					  wTicketType,
					  wSeqNo,
					  wStatus,
					  wUpdBy,
					  wUpdDt
					FROM #sDataSet_SeteVoucher) as temp			  															
																	
						UPDATE  #sDataSet_SeteVoucher2
						SET     RowID = 0, wBookingRid = @pNewBookingRid;
						SELECT  @sRecCount = COUNT(*)
						FROM    #sDataSet_SeteVoucher;
						WHILE @sRuningIndex <= @sRecCount
							BEGIN
								EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
									@sRowID OUTPUT;
					
								UPDATE  #sDataSet_SeteVoucher2
								SET     RowID = @sRowID										
								WHERE   wRowNum = @sRuningIndex;
								SET @sRuningIndex = @sRuningIndex + 1;
							END; 


						SELECT * INTO #tmpDataSet_SeteVoucher
						FROM #sDataSet_SeteVoucher2 tmp WHERE tmp.wStatus <> 'T'	


						INSERT  INTO dbo.[eVoucher]
                             (
								[RowID],
								[wVoucherRid],
								[wVoucherNo],
								[wVoucherType],
								[wAmount],
								[wCounterRid],
								[wBookingRid],
								[wLineGrp],
								[wCurrCode],
								[wRemark],
								[wTicketType],
								[wSeqNo],
								[wStatus],
								[wCrtBy],
								[wCrtDt],
								[wUpdBy],
								[wUpdDt]
							)
                            SELECT
	            	                s.RowID ,
									s.wVoucherRid,
									s.wVoucherNo,
									s.wVoucherType,
									s.wAmount,
									s.wServiceCounterRid,
									s.wBookingRid,
									s.wLineGrp,
									s.wCurrCode,
									s.wRemark,
									s.wTicketType,
									s.wSeqNo ,
									s.wStatus ,
									s.wUpdBy ,
									dbo.fnUTC8Now(),
									s.wUpdBy ,
									dbo.fnUTC8Now()
                            FROM    #tmpDataSet_SeteVoucher s;		
						
						BEGIN
						--Update status for mVoucher as Terminate
							UPDATE  dbo.mVoucher
							SET     wVoucherStatus = 'T' ,
									wUpdBy = tmps.wUpdBy ,
									wUpdDt = dbo.fnUTC8Now()
							FROM    dbo.mVoucher AS mv
									INNER JOIN #sDataSet_SeteVoucher2 tmps ON  mv.RowID = tmps.wVoucherRid
							Where tmps.wStatus = 'T'
							-------			

						--Update status for mVoucher as Used
							UPDATE  dbo.mVoucher
							SET     wVoucherStatus = 'I',
									wUpdBy = tmpv.wUpdBy ,
									wUpdDt = dbo.fnUTC8Now()
							FROM    dbo.mVoucher AS mv
									INNER JOIN #sDataSet_SeteVoucher2 tmpv ON  mv.RowID = tmpv.wVoucherRid
							Where mv.RowID = tmpv.wVoucherRid
							--------
						END;	
						
			IF @sBeginTranCount = 0 AND @@trancount > 0
                BEGIN
                    COMMIT;
                END; 
				
			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SeteVoucher2
				          
            RETURN;										
					
	
        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                @sCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @sProcedureName VARCHAR(100) ,
                @sRtnCodeLog INT ,
                @sErrMessageLog NVARCHAR(4000);
	        
            SELECT  @sErrorNum = ERROR_NUMBER() ,
                    @sCatchErrorMessage = ERROR_MESSAGE() ,
                    @xstate = XACT_STATE() ,
                    @sProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ',
                                  @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                AND ( @xstate = 1
                      OR @xstate = -1
                    )
                BEGIN
				-- transaction created within this sp
                    ROLLBACK;
                END;
	        
	        -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName,
                @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;
		
		IF OBJECT_ID('tempdb..#sDataSet_SeteVoucher') IS NOT NULL
			DROP TABLE #sDataSet_SeteVoucher

		IF OBJECT_ID('tempdb..#sDataSet_SeteVoucher2') IS NOT NULL
			DROP TABLE #sDataSet_SeteVoucher2
			
    END;