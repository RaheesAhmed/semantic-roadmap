CREATE PROCEDURE [spa].[SetAllotmentsofFerryRecord]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;
	
	    --SELECT *,'' as wSvCtrName,'' as wRoute,'' AS wBookingClassCd,'' AS wTicketStatus,'' AS IssueLocationName,'' AS wBookingClassCdName, '' as wTicketTypeName,* from eAllotmentTicket
		--select * from eAllotmentTicket

        DECLARE @sThisTableName VARCHAR(50) = 'eAllotmentTicket' , -- For RowID
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
        INTO    #sDataSet_SetAllotmentsofFerryRecord
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
				RowID BIGINT ,				
				wTicketNo VARCHAR(30),
				wSvCtrCode NVARCHAR(15),
				wCounterRid BIGINT,
				wExpiryDate DATE,
				wTicketType VARCHAR(30),
				wRouteRid BIGINT,
				wClassCd VARCHAR(10),
				wAmount NUMERIC(18,4),
				wAllotmentStatus VARCHAR(30),
				wStatus CHAR(1),
				wRemark NVARCHAR(500),
				wBookingRid BIGINT,				
				wUpdBy BIGINT ,
				wUpdDt DATETIME2(7),
				wCurrCode VARCHAR(6),
				wInitialsTkt VARCHAR(20),
				wTicketNum INT
			);


			--- Ferry allotment Required Field Validation Start
        DECLARE @errorMsg VARCHAR(MAX);	
        IF @pActionType IN ( 'I', 'U' )
            BEGIN
                SELECT  @errorMsg = CASE WHEN RTRIM(ISNULL(saf.wSvCtrCode, '')) = '' THEN 'Service counter is Missing'
                                         WHEN RTRIM(ISNULL(saf.wTicketType, '')) = '' THEN 'Ticket type is Missing' 
								  --when saf.wAmount <=0 then 'Ferry amount is Missing' --0也可讓user save
                                         WHEN RTRIM(ISNULL(saf.wCurrCode, '')) = '' THEN 'Currency is Missing'
                                         WHEN RTRIM(ISNULL(saf.wStatus, '')) = ' ' THEN 'Status is Missing'
                                         WHEN RTRIM(ISNULL(saf.wClassCd, '')) = '' THEN 'Ferry class is Missing'
                                    END
                FROM    #sDataSet_SetAllotmentsofFerryRecord saf;
            END;
        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;
			--- Ferry allotment Required Field Validation end


        BEGIN TRY
		    -- Try to make the transaction scope as small as possible to reduce locking
	
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;
            IF @pActionType = 'I'
                BEGIN
				-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetAllotmentsofFerryRecord
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetAllotmentsofFerryRecord;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetAllotmentsofFerryRecord
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    
								        
                    DECLARE @vNow DATETIME2(7)=dbo.fnUTC8Now();
				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty
                    INSERT  INTO dbo.[eAllotmentTicket]
                            ( [RowID] ,
                              [wTicketNo] ,
                              [wSvCtrCode] ,
                              [wCounterRid] ,
                              [wExpiryDate] ,
                              [wTicketType] ,
                              [wRouteRid] ,
                              [wClassCd] ,
                              [wAmount] ,
                              [wRemark] ,
                              [wAllotmentStatus] ,
                              [wStatus] ,
                              [wBookingRid] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt] ,
                              [wCurrCode] ,
                              [wInitialsTkt],
                              [wTicketNum]
							)
                            SELECT  s.RowID ,
                                    s.wTicketNo ,
                                    s.wSvCtrCode ,
                                    s.wCounterRid ,
                                    s.wExpiryDate ,
                                    s.wTicketType ,
                                    s.wRouteRid ,
                                    s.wClassCd ,
                                    s.wAmount ,
                                    s.wRemark ,
                                    s.wAllotmentStatus ,
                                    s.wStatus ,
                                    s.wBookingRid ,
                                    s.wUpdBy ,
                                    @vNow,
                                    s.wUpdBy ,
                                    @vNow ,
                                    wCurrCode ,
                                    wInitialsTkt,
                                    wTicketNum 
                            FROM    #sDataSet_SetAllotmentsofFerryRecord s;


                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN
                        UPDATE  met
                        SET     --met.wStatus = tmp.wStatus,
                                met.wUpdBy = tmp.wUpdBy ,
                                met.wUpdDt = dbo.fnUTC8Now() ,
                                met.wRemark = tmp.wRemark
                        FROM    dbo.eAllotmentTicket AS met
                                INNER JOIN #sDataSet_SetAllotmentsofFerryRecord tmp ON met.RowID = tmp.RowID
                        WHERE   met.RowID = tmp.RowID;
                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN 
                            UPDATE  dbo.eAllotmentTicket
                            SET     wAllotmentStatus = 'C' ,
                                    wStatus = 'T' ,
                                    wUpdDt = dbo.fnUTC8Now()
                            WHERE   RowID IN ( SELECT RowID FROM #sDataSet_SetAllotmentsofFerryRecord );
                        END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetAllotmentsofFerryRecord;
            
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
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0
                AND ( @xstate = 1
                      OR @xstate = -1
                    )
                BEGIN
				-- transaction created within this sp
                    ROLLBACK;
                END;
	        
	        -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetAllotmentsofFerryRecord') IS NOT NULL
            DROP TABLE #sDataSet_SetAllotmentsofFerryRecord;
		
    END;