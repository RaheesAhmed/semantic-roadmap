
CREATE PROCEDURE [spa].[SetVisaCollection]
    (

      @pXML XML ,
      @pActionType CHAR(1) , -- I/U/D
      @pMainCompNo INT ,
      @pNonceToken VARCHAR(64),
      @pReturnResultSet CHAR(1) = 'N',
      @pBookingRid BigINT,
      @pErrCode INT = 0 OUTPUT,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
	)

AS

    BEGIN

	--SELECT RowID, wBookingRid, wTicCollPoint, wIsCollected, wCollDate, wCollStaff, wCollRemark, wSeqNo, wCrtBy, wCrtDt, wUpdDt, wUpdBy FROM [dbo].[eVisaCollection]

        SET NOCOUNT ON;
	    DECLARE @sThisTableName VARCHAR(50) = 'eVisaCollection' , -- For RowID

            @sBeginTranCount INT = 0 ,

            @sRecCount INT = 0 ,

            @sRuningIndex INT = 1 ,

            @sRowID BIGINT = 0 ,

            @sDocHandle INT;


        DECLARE @sReturnRowID TABLE ( RowID BIGINT );

		SET @sBeginTranCount = @@trancount;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    --  

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
         * INTO    #sDataSet_SetVisaCollection
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (

				RowID BIGINT ,

				wBookingRid BIGINT,

				wTicCollPoint  VARCHAR(10) ,
				wIsCollected VARCHAR(10),
				wCollDate DATETIME2(7),
				wCollStaff NVARCHAR(64),
				wCollRemark NVARCHAR(500),				
				wSeqNo INT ,
				wUpdBy BIGINT ,

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

                    UPDATE  #sDataSet_SetVisaCollection
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetVisaCollection;
                    WHILE @sRuningIndex <= @sRecCount

                        BEGIN

                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,

                                @sRowID OUTPUT;

                            UPDATE  #sDataSet_SetVisaCollection
                            SET     RowID = @sRowID, 
									wBookingRid = @pBookingRid

                            WHERE   wRowNum = @sRuningIndex;



                            SET @sRuningIndex = @sRuningIndex + 1;



                        END;    		        


				-- MAIN Logic here, example here is inserting dataset to eIOUPenalty



                    INSERT  INTO dbo.[eVisaCollection]

                            (
								[RowID],



								[wBookingRid],



								[wTicCollPoint],



								[wIsCollected],



								[wCollDate],



								[wCollStaff],



								[wCollRemark],



								[wSeqNo],						
								[wCrtBy],
								[wCrtDt],
								[wUpdBy],
								[wUpdDt]
							)

                            SELECT
	            	                s.RowID ,
									s.wBookingRid,								
									s.wTicCollPoint,
									s.wIsCollected,
									s.wCollDate,
									s.wCollStaff,
									s.wCollRemark,
									s.wSeqNo,				
									s.wUpdBy,
									dbo.fnUTC8Now(),
									s.wUpdBy,
									dbo.fnUTC8Now()

                            FROM    #sDataSet_SetVisaCollection s;

                END;

				ELSE

                IF @pActionType = 'U'
                    BEGIN
					 -- Delete previous record if exsist. 


					 delete from dbo.eVisaCollection 

					 where wBookingRid = @pBookingRid
					 -- Set RowID by Sequence

					 IF EXISTS(SELECT count(*) FROM #sDataSet_SetVisaCollection s where s.ROWID = 0 OR s.RowID = null)
  BEGIN 
	
                    UPDATE  #sDataSet_SetVisaCollection
                    SET     RowID = 0;
                    SELECT  @sRecCount = COUNT(*)
    FROM    #sDataSet_SetVisaCollection;
                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            EXEC spq.GetRowID @pMainCompNo, @sThisTableName,
                                @sRowID OUTPUT;

                            UPDATE  #sDataSet_SetVisaCollection
                            SET     RowID = @sRowID
                            WHERE   wRowNum = @sRuningIndex;
                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;
  END

                       INSERT  INTO dbo.[eVisaCollection]
                            (
								[RowID],
								[wBookingRid],
								[wTicCollPoint],
								[wIsCollected],
								[wCollDate],
								[wCollStaff],
								[wCollRemark],
								[wSeqNo],						
								[wCrtBy],
								[wCrtDt],
								[wUpdBy],

								[wUpdDt]
							)

                            SELECT
	            	                s.RowID ,
									s.wBookingRid,								
									s.wTicCollPoint,
									s.wIsCollected,
									s.wCollDate,
									s.wCollStaff,
									s.wCollRemark,
									s.wSeqNo,				
									s.wUpdBy,
									dbo.fnUTC8Now(),
									s.wUpdBy,
									dbo.fnUTC8Now()
                            FROM    #sDataSet_SetVisaCollection s;
                    END;

			 IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    COMMIT;
                END; 

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT  RowID
                FROM    #sDataSet_SetVisaCollection;

           RETURN;
        END TRY
        BEGIN CATCH
            DECLARE @vErrorNum INT ,
                @vCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @vProcedureName VARCHAR(100) ,
                @vRtnCodeLog INT ,
                @vErrMessageLog NVARCHAR(4000);
	        
			SET  @vErrorNum = ERROR_NUMBER();
			SET  @vCatchErrorMessage = ERROR_MESSAGE();
			SET  @xstate = XACT_STATE();
			SET  @vProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ',
                                  @vCatchErrorMessage);
			
			IF @sBeginTranCount = 0 BEGIN
				IF @xstate != 0
					ROLLBACK;
	            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
			END
			ELSE
				THROW;

        END CATCH;	

        EXEC sp_xml_removedocument @sDocHandle;	

		 IF OBJECT_ID('tempdb..#sDataSet_SetVisaCollection') IS NOT NULL
			DROP TABLE #sDataSet_SetVisaCollection   
    END;