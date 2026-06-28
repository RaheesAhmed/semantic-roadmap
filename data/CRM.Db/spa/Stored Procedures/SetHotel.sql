CREATE PROCEDURE [spa].[SetHotel]
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        ------------------------------------------------------------
        -- SELECT * FROM dbo.mHotel;
        ------------------------------------------------------------

        DECLARE @sThisTableName VARCHAR(50) = 'mHotel' , -- For RowID
                @sBeginTranCount INT = 0 ,
                @sRecCount INT = 0 ,
                @sRuningIndex INT = 1 ,
                @sRowID BIGINT = 0 ,
                @sDocHandle INT,
                @sNow DATETIME2(7) = dbo.fnUTC8Now();
	        
        DECLARE @vOldXML XML,
                @vNewXML XML;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	     
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetHotel
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (  RowID BIGINT ,
                wCode  VARCHAR(20) ,
                wName  NVARCHAR(100) ,
                wEname  NVARCHAR(100) ,
                wJname  NVARCHAR(100) ,
                wThname  NVARCHAR(100) ,
                wKname  NVARCHAR(100) ,				
                wRegion VARCHAR(20) ,
                wDistrictCd VARCHAR(30) ,
                wCurrCode VARCHAR(6) ,
                wIsBase CHAR(1) ,
                wIsGroup CHAR(1) ,
                wParentHotelRid BIGINT ,
                wAddress NVARCHAR(1000) ,
                wRemark NVARCHAR(1000) ,
                wSmsRemark NVARCHAR(1000) ,
                wSeqNo INT,
                wGetKeyMethod VARCHAR(5),
                wIsSunTrip CHAR(1),
                wDebitServiceCounter BIGINT,
                wHasWIFI CHAR(1),
                wNeedEntrancePaper CHAR(1),
                wEntrancePaperTips NVARCHAR(1000),
                wRoomServiceDesc NVARCHAR(1000),
                wHotelDesktopDesc NVARCHAR(1000),
                wNeedPassengerName CHAR(1),
                wNeedPassengerID CHAR(1),
                wNeedPassengerBirthday CHAR(1),
                wNeedUploadID CHAR(1),
                wUploadIDType VARCHAR(5),
                wStatus CHAR(1),
                wUpdBy BIGINT ,
                wUpdDt DATETIME2(7)
		);

        SET @vOldXML = (
            SELECT h.*
            FROM dbo.mHotel h WITH(NOLOCK)
            INNER JOIN #sDataSet_SetHotel tmp ON tmp.RowID = h.RowID
            FOR XML RAW('Record'), ROOT('DataSet')
        );

		SET @pErrCode = 0 ;
        SET @pErrMsg = '';
        SET @sBeginTranCount = @@trancount;
        
        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;
	        
            IF @pActionType = 'I'
            BEGIN
                SET @sRuningIndex = 1;
                SET @sRecCount = (SELECT COUNT(1) FROM #sDataSet_SetHotel);

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                    UPDATE  #sDataSet_SetHotel SET RowID = @sRowID WHERE wRowNum = @sRuningIndex;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END;    		        
				
                IF NOT EXISTS ( SELECT 1
                                FROM dbo.mHotel mh
                                INNER JOIN #sDataSet_SetHotel tmp ON tmp.wCode = mh.wCode AND tmp.wStatus = mh.wStatus)
                BEGIN
                    INSERT INTO dbo.mHotel ( 
                        RowID ,
                        wCode ,
                        wName ,
                        wEname ,
                        wJname ,
                        wThname ,
                        wKname ,
                        wRegion ,
                        wDistrictCd ,
                        wCurrCode ,
                        wIsBase ,
                        wAddress ,
                        wRemark ,
                        wSmsRemark ,
                        wSeqNo ,
                        wGetKeyMethod,
                        wIsSunTrip,
                        wDebitServiceCounter,
                        wHasWIFI,
                        wNeedEntrancePaper,
                        wEntrancePaperTips,
                        wRoomServiceDesc,
                        wHotelDesktopDesc,
                        wNeedPassengerName,
                        wNeedPassengerID,
                        wNeedPassengerBirthday,
                        wNeedUploadID,
                        wUploadIDType,
                        wStatus ,
                        wCrtBy ,
                        wCrtDt ,
                        wUpdBy ,
                        wUpdDt
					)
                    SELECT  RowID ,
                            wCode ,
                            wName ,
                            wEname ,
                            wJname ,
                            wThname ,
                            wKname ,
                            wRegion ,
                            wDistrictCd ,
                            wCurrCode ,
                            wIsBase ,
                            wAddress ,
                            wRemark ,
                            wSmsRemark ,
                            wSeqNo ,
                            wGetKeyMethod,
                            wIsSunTrip,
                            wDebitServiceCounter,
                            wHasWIFI,
                            wNeedEntrancePaper,
                            wEntrancePaperTips,
                            wRoomServiceDesc,
                            wHotelDesktopDesc,
                            wNeedPassengerName,
                            wNeedPassengerID,
                            wNeedPassengerBirthday,
                            wNeedUploadID,
                            wUploadIDType,
                            wStatus ,
                            wUpdBy ,
                            @sNow,
                            wUpdBy ,
                            @sNow
                    FROM    #sDataSet_SetHotel;
                END;
                ELSE
                BEGIN
                    SET @pErrMsg = 'Hotel already exist with this code.Use different code to create the hotel.';
                END;
            END;
            
            IF @pActionType = 'U'
            BEGIN
                IF EXISTS (SELECT 1 FROM #sDataSet_SetHotel tmp INNER JOIN CRM.dbo.eBookingRoom br ON br.wHotelRid = tmp.RowID WHERE tmp.wStatus = 'T')
                BEGIN
                    SET @pErrMsg =N'该酒店已被使用,不能删除或终止';	
                END;
                ELSE
                BEGIN
                    UPDATE  mh
                    SET wCode = tmp.wCode ,
                        wName = tmp.wName ,
                        wEname = tmp.wEname ,
                        wJname = tmp.wJname ,
                        wThname = tmp.wThname ,
                        wKname = tmp.wKname ,
                        wRegion = tmp.wRegion ,
                        wDistrictCd = tmp.wDistrictCd ,
                        wCurrCode = tmp.wCurrCode ,
                        wIsBase = tmp.wIsBase ,
                        wAddress = tmp.wAddress ,
                        wRemark = tmp.wRemark ,
                        wSmsRemark = tmp.wSmsRemark ,
                        wSeqNo = tmp.wSeqNo ,
                        wGetKeyMethod = tmp.wGetKeyMethod,
                        wIsSunTrip = tmp.wIsSunTrip,
                        wDebitServiceCounter = tmp.wDebitServiceCounter,
                        wHasWIFI = tmp.wHasWIFI,
                        wNeedEntrancePaper = tmp.wNeedEntrancePaper,
                        wEntrancePaperTips = tmp.wEntrancePaperTips,
                        wRoomServiceDesc = tmp.wRoomServiceDesc,
                        wHotelDesktopDesc = tmp.wHotelDesktopDesc,
                        wNeedPassengerName = tmp.wNeedPassengerName,
                        wNeedPassengerID = tmp.wNeedPassengerID,
                        wNeedPassengerBirthday = tmp.wNeedPassengerBirthday,
                        wNeedUploadID = tmp.wNeedUploadID,
                        wUploadIDType = tmp.wUploadIDType,
                        wStatus = tmp.wStatus ,
                        wUpdBy = tmp.wUpdBy ,
                        wUpdDt = @sNow
                    FROM dbo.mHotel mh
                    INNER JOIN #sDataSet_SetHotel tmp ON tmp.RowID = mh.RowID;
                END;
            END;
                
            IF @pActionType = 'D'
            BEGIN
                IF EXISTS (SELECT 1 FROM #sDataSet_SetHotel tmp INNER JOIN CRM.dbo.eBookingRoom br ON br.wHotelRid = tmp.RowID)
                BEGIN
                    SET @pErrMsg =N'该酒店已被使用,不能删除或终止';	
                END;
                ELSE
                BEGIN
                    UPDATE  mh
                    SET wStatus = 'T' ,
                        wUpdDt = @sNow,
                        wUpdBy = tmp.wUpdBy
                    FROM dbo.mHotel mh
                    INNER JOIN #sDataSet_SetHotel tmp ON tmp.RowID = mh.RowID;
                END;
            END;

            -- 如果數據有修改，Sync到SUNTrip
            ------------------------------------------------------------------------------------------------------
            SET @vNewXML = (SELECT *, RecordState = @pActionType FROM #sDataSet_SetHotel FOR XML RAW('Record'), ROOT('DataSet'));
            
            EXEC spa.SUNTrip_SetHotelChange @pOldXML = @vOldXML,
                                            @pNewXML = @vNewXML;
            ------------------------------------------------------------------------------------------------------

            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID FROM  #sDataSet_SetHotel;
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

            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
            BEGIN
                ROLLBACK;
            END;
	        
	        -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetHotel') IS NOT NULL
            DROP TABLE #sDataSet_SetHotel;
    END;