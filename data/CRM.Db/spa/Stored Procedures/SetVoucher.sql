CREATE PROCEDURE [spa].[SetVoucher]
(
  @pXML XML ,
  @pActionType CHAR(1) , -- I/U/D
  @pMainCompNo INT ,
  @pNonceToken VARCHAR(64) ,
  @pReturnResultSet CHAR(1) = 'N',
  @pErrCode INT = 0 OUTPUT ,
  @pErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
    BEGIN
        SET NOCOUNT ON;	
		--SELECT *FROM [mVoucher]
        DECLARE @sThisTableName VARCHAR(50) = 'mVoucher' , -- For RowID
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
        INTO    #sDataSet_SetVoucher
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
	    	RowID BIGINT ,
              wCounterRID BIGINT ,
              wCorporateRID BIGINT ,
              wVoucherRefNo BIGINT ,
              wVoucherType NVARCHAR(50) ,
              wVoucherValue DECIMAL(18, 4) ,
              wVoucherCurrCode VARCHAR(3),
			  wRemark NVARCHAR(300),
			  wVoucherStatus CHAR(1),
			  wStatus CHAR(1),
			  wUpdBy BIGINT,
			  wUpdDt DATETIME2(7)
	    );	
    
			DECLARE @errorMsg varchar(max);	
			--- Voucher Required Field Validation
			IF  @pActionType IN ('I', 'U') BEGIN
			select @errorMsg = CASE 
									WHEN sv.wCounterRID < 0 THEN 'Service Counter is Missing'
									WHEN RTRIM(ISNULL(sv.wVoucherType,'')) = '' THEN 'Voucher Type is Missing' 
									WHEN RTRIM(ISNULL(sv.wVoucherCurrCode,'')) = '' THEN 'Currency is Missing' 
									WHEN sv.wVoucherValue < 0 THEN 'Voucher Value is Missing'
									WHEN sv.wVoucherRefNo < 0 THEN 'Voucher Number is Missing'
									WHEN RTRIM(ISNULL(sv.wVoucherStatus,'')) = '' THEN 'Voucher Status is Missing'
								END
			from #sDataSet_SetVoucher sv
			END
			IF @errorMsg <> ''
				throw 50001, @errorMsg, 1;	
			--- Voucher Required Field Validation end

			--- Voucher Delete Validation
			ELSE IF @pActionType = 'D' BEGIN
			select @errorMsg = CASE
									WHEN mvr.wVoucherStatus = ('C') THEN 'Voucher can not be deleted if Status Code is '+ mvr.wVoucherStatus
								END
				from mVoucher mvr INNER JOIN
				#sDataSet_SetVoucher mv on mvr.RowID=mv.RowID			   
			END

			IF @errorMsg <> ''
			throw 50001, @errorMsg, 1;
			--- Voucher Delete Validation end

	     --better don't put everything within try,
        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
	        
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetVoucher
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetVoucher;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetVoucher
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
				
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[mVoucher]
                            ( [RowID] ,
                              [wCounterRID] ,
                              [wCorporateRID] ,
                              [wVoucherRefNo] ,
                              [wVoucherType] ,
                              [wVoucherValue] ,
                              [wVoucherCurrCode] ,
                              [wRemark] ,
                              [wVoucherStatus] ,
							  [wStatus],
                              [wUpdBy] ,
                              [wUpdDt]
                            )
                            SELECT	            	
                              s.RowID ,
                              s.wCounterRID ,
                              s.wCorporateRID ,
                              s.wVoucherRefNo ,
                              s.wVoucherType ,
                              s.wVoucherValue ,
                              s.wVoucherCurrCode ,
                              s.wRemark ,
                              s.wVoucherStatus ,
							  s.wStatus,
                              s.wUpdBy ,
                              dbo.fnUTC8Now()
                            FROM #sDataSet_SetVoucher s;
                END;
				ELSE IF @pActionType = 'U'
                    BEGIN
							UPDATE  mcv
							SET    
                                mcv.wCounterRID = tmp.wCounterRID ,
                                mcv.wCorporateRID = tmp.wCorporateRID ,
                                mcv.wVoucherRefNo = tmp.wVoucherRefNo ,
                                mcv.wVoucherType = tmp.wVoucherType ,
                                mcv.wVoucherValue = tmp.wVoucherValue ,
                                mcv.wVoucherCurrCode = tmp.wVoucherCurrCode ,
                                mcv.wRemark = tmp.wRemark ,
                                mcv.wVoucherStatus = tmp.wVoucherStatus ,
								mcv.wStatus=tmp.wStatus,
                                mcv.wUpdBy = tmp.wUpdBy ,
                                mcv.wUpdDt = dbo.fnUTC8Now()
								FROM dbo.mVoucher AS mcv
                                INNER JOIN #sDataSet_SetVoucher tmp ON mcv.RowID = tmp.RowID
								WHERE mcv.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
							UPDATE dbo.[mVoucher] set wVoucherStatus='C',wStatus='T', wUpdDt = dbo.fnUTC8Now()
							WHERE RowID IN (
                                    SELECT  RowID
                                    FROM    #sDataSet_SetVoucher)
                        END;
	
            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetVoucher;
				            
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
		
		IF OBJECT_ID('tempdb..#sDataSet_SetVoucher') IS NOT NULL
			DROP TABLE #sDataSet_SetVoucher

    END;