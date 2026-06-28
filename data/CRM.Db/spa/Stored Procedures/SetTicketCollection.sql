CREATE PROCEDURE [spa].[SetTicketCollection]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pBookingRid BIGINT ,
      @pTicketCollRId BIGINT = 0 OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT  
    )
AS
    BEGIN
        SET NOCOUNT ON;

	--SELECT * FROM eTicketCollection

        DECLARE @sThisTableName VARCHAR(50) = 'eTicketCollection' , -- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;

        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

        SET @sBeginTranCount = @@trancount;  
	
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetTicketCollection
        FROM    OPENXML (@sDocHandle, 'DataSet/SetTicketCollectionResult', 1)
	WITH (
		RowID BIGINT,
		wBookingRid BIGINT,
		wTicCollPoint  VARCHAR(10),
		wIsCollected VARCHAR(10),
		wCollDate DATETIME2(7),
		wCollStaff NVARCHAR(64),
		wCollRemark NVARCHAR(500),
		wSeqNo INT,
		wUpdBy BIGINT,
		wUpdDt DATETIME2(7)
	);

        BEGIN TRY
			-- Try to make the transaction scope as small as possible to reduce locking
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN
		-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetTicketCollection
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(1)
                    FROM    #sDataSet_SetTicketCollection;
		
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;

                            SET @pTicketCollRId = @sRowID;
					
                            UPDATE  #sDataSet_SetTicketCollection
                            SET     RowID = @sRowID ,
                                    wBookingRid = @pBookingRid
                            WHERE   wRowNum = @sRuningIndex;

                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        

		---- INSERT Logic here, example here is inserting dataset to [eTicketCollection]
                    INSERT  INTO dbo.[eTicketCollection]
                            ( [RowID] ,
                              [wBookingRid] ,
                              [wTicCollPoint] ,
                              [wIsCollected] ,
                              [wCollDate] ,
                              [wCollStaff] ,
                              [wCollRemark] ,
                              [wSeqNo] ,
                              [wCrtBy] ,
                              [wCrtDt] ,
                              [wUpdBy] ,
                              [wUpdDt]
		                    )
                            SELECT  tcDataSet.RowID ,
                                    tcDataSet.wBookingRid ,
                                    tcDataSet.wTicCollPoint ,
                                    tcDataSet.wIsCollected ,
                                    tcDataSet.wCollDate ,
                                    wCollStaff = u.wCName ,
                                    tcDataSet.wCollRemark ,
                                    tcDataSet.wSeqNo ,
                                    tcDataSet.wUpdBy ,
                                    dbo.fnUTC8Now() ,
                                    tcDataSet.wUpdBy ,
                                    dbo.fnUTC8Now()
                            FROM    #sDataSet_SetTicketCollection tcDataSet
                                    LEFT JOIN RollsMary.dbo.mUsr u ON tcDataSet.wUpdBy = u.RowID;
                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN		
                        UPDATE  etc
                        SET     [wTicCollPoint] = tcDataSet.wTicCollPoint ,
                                [wIsCollected] = tcDataSet.wIsCollected ,
                                [wCollDate] = tcDataSet.wCollDate ,
                                [wCollStaff] = u.wCName ,
                                [wCollRemark] = tcDataSet.wCollRemark ,
                                [wSeqNo] = tcDataSet.wSeqNo ,
                                [wUpdBy] = tcDataSet.wUpdBy ,
                                [wUpdDt] = dbo.fnUTC8Now()
                        FROM    dbo.eTicketCollection AS etc
                                INNER JOIN #sDataSet_SetTicketCollection tcDataSet ON ( etc.RowID = tcDataSet.RowID
                                                              AND @pBookingRid <= 0
                                                              )
                                                              OR ( etc.wBookingRid = @pBookingRid
                                                              AND @pBookingRid > 0
                                                              )
                                LEFT JOIN RollsMary.dbo.mUsr u ON tcDataSet.wUpdBy = u.RowID;
                    END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

	-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetTicketCollection;
	 
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
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo,
                        @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT,
                        @vErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;

        END CATCH;
		
        EXEC sp_xml_removedocument @sDocHandle;	

        IF OBJECT_ID('tempdb..#sDataSet_SetTicketCollection') IS NOT NULL
            DROP TABLE #sDataSet_SetTicketCollection;
    END;