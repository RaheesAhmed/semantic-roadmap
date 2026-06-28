CREATE PROCEDURE [spa].[SetTravelPackageType]
    (
      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT 
	)
AS
    BEGIN
        SET NOCOUNT ON;
		--select * from mTravelPackageType;
        DECLARE @sThisTableName VARCHAR(50) = 'mTravelPackageType' ,-- For RowID
            @sBeginTranCount INT = 0 ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sDocHandle INT;
		     
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';
		        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
	   
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetTravelPackageTypeDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (
			 RowID BIGINT ,
			 wCode NVARCHAR(30),
			 wName NVARCHAR(50),
			 wValidDate DATETIME2(7),
			 wStatus CHAR(1),
             wCrtDt DATETIME2(7),
             wCrtBy  BIGINT ,
             wUpdDt DATETIME2(7),
			 wUpdBy BIGINT  
		  	);

        DECLARE @errorMsg VARCHAR(MAX);	

        IF @pActionType IN ( 'I', 'U' )
            BEGIN
                SELECT  @errorMsg = CASE WHEN RTRIM(ISNULL(sec.wCode, '')) = ''
                                         THEN 'Code is Missing'
                                         WHEN RTRIM(ISNULL(sec.wName, '')) = ''
                                         THEN 'Name is Missing'
                                    END
                FROM    #sDataSet_SetTravelPackageTypeDetails sec;
            END;
        IF @errorMsg <> ''
            THROW 50001, @errorMsg, 1;	

        BEGIN TRY
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF @pActionType = 'I'
                BEGIN

                    IF EXISTS ( SELECT  1
                                FROM    dbo.mTravelPackageType tpy
                                        INNER JOIN #sDataSet_SetTravelPackageTypeDetails temptpy ON tpy.wCode = temptpy.wCode )
                        THROW 50001, 'Code already exist.', 1;

			-- Set RowID by Sequence
                    UPDATE  #sDataSet_SetTravelPackageTypeDetails
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetTravelPackageTypeDetails;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;
					
                            UPDATE  #sDataSet_SetTravelPackageTypeDetails
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;    		        
								
                    INSERT  INTO dbo.[mTravelPackageType]
                            ( [RowID] ,
                              [wCode] ,
                              [wName] ,
                              [wValidDate] ,
                              [wStatus] ,
                              [wCrtDt] ,
                              [wCrtBy] ,
                              [wUpdDt] ,
                              [wUpdBy]
						    )
                            SELECT  s.RowID ,
                                    s.wCode ,
                                    s.wName ,
                                    s.wValidDate ,
                                    s.wStatus ,
                                    s.wCrtDt ,
                                    s.wCrtBy ,
                                    s.wUpdDt ,
                                    s.wUpdBy
                            FROM    #sDataSet_SetTravelPackageTypeDetails s;

                END;
            ELSE
                IF @pActionType = 'U'
                    BEGIN

                        IF EXISTS ( SELECT  1
                                    FROM    dbo.mTravelPackageType tpy
                                            INNER JOIN #sDataSet_SetTravelPackageTypeDetails temptpy ON tpy.wCode = temptpy.wCode
                                                              AND tpy.RowID <> tpy.RowID )
                            THROW 50001, 'Code already exist.', 1;

                        UPDATE  mec
                        SET     
                                mec.wCode = tmp.wCode ,
                                mec.wName = tmp.wName ,
                                mec.wValidDate = tmp.wValidDate ,
                                mec.wStatus = tmp.wStatus ,
                                mec.wUpdDt = tmp.wUpdDt ,
                                mec.wUpdBy = tmp.wUpdBy
                        FROM    dbo.mTravelPackageType AS mec
                                INNER JOIN #sDataSet_SetTravelPackageTypeDetails tmp ON mec.RowID = tmp.RowID
                        WHERE   mec.RowID = tmp.RowID;

                    END;
                ELSE
                    IF @pActionType = 'D'
                        BEGIN
                            UPDATE  tpy
                            SET     tpy.wStatus = 'T' ,
                                    wUpdDt = dbo.fnUTC8Now()
                            FROM    dbo.mTravelPackageType AS tpy
                                    INNER JOIN #sDataSet_SetTravelPackageTypeDetails tmp ON tpy.RowID = tmp.RowID
                            WHERE   tpy.RowID = tmp.RowID;
                        END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END;

		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetTravelPackageTypeDetails;

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

        IF OBJECT_ID('tempdb..#sDataSet_SetTravelPackageTypeDetails') IS NOT NULL
            DROP TABLE #sDataSet_SetTravelPackageTypeDetails;

    END;