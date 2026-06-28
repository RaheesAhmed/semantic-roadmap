
CREATE PROCEDURE [spa].[SetCashTransferDtl]
    (
      @pXML XML ,
      @pMainCompNo INT ,
      @pTestMode INT = 0 , -- 0: Normal(Non-Test), 1: UnitTest, 2: Scenario Test
      @pNonceToken VARCHAR(64) ,
      @pReturnResultSet CHAR(1) = 'N' ,
      @pCashTransferRid BIGINT OUTPUT ,
      @pErrCode INT = 0 OUTPUT ,
      @pErrMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;

        --SELECT  ctd.* ,
        --        'N' AS RecordState
        --FROM    dbo.eCashTransferDtl ctd; 

        DECLARE @sThisTableName VARCHAR(50) = 'eCashTransferDtl' ,
            @sBeginTranCount INT = 0 ,
            @sDocHandle INT ,
            @sRecCount INT = 0 ,
            @sRuningIndex INT = 1 ,
            @sRowID BIGINT = 0 ,
            @sNow DATETIME2 = dbo.fnUTC8Now();
	   
        SET @pCashTransferRid = ISNULL(@pCashTransferRid, 0);
        SET @sBeginTranCount = @@trancount;
        SELECT  @pErrCode = 0 ,
                @pErrMsg = '';

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetCashTransferDtl
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH ( 
				RowID BIGINT,
				wCashTransferRid BIGINT,
				wBookingRid BIGINT,
				wStatus CHAR(1),
				wCrtBy BIGINT,
				wCrtDt DATETIME2,
				wUpdBy BIGINT,
				wUpdDt DATETIME2,
				RecordState VARCHAR(1)
			);

        BEGIN TRY
            IF @sBeginTranCount = 0
                BEGIN
                    BEGIN TRAN;
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetCashTransferDtl
                        WHERE   RecordState = 'I' )
                BEGIN
                    UPDATE  #sDataSet_SetCashTransferDtl
                    SET     RowID = 0
                    WHERE   RecordState = 'I';

                    SELECT  @sRecCount = COUNT(*)
                    FROM    #sDataSet_SetCashTransferDtl;

                    WHILE @sRuningIndex <= @sRecCount
                        BEGIN
                            IF EXISTS ( SELECT  1
                                        FROM    #sDataSet_SetCashTransferDtl
                                        WHERE   RecordState = 'I'
                                                AND wRowNum = @sRuningIndex )
                                BEGIN
                                    EXEC spq.GetRowID @pMainCompNo,
                                        @sThisTableName, @sRowID OUTPUT;

                                    IF ( @pCashTransferRid != 0 )
                                        BEGIN
                                            UPDATE  #sDataSet_SetCashTransferDtl
                                            SET     wCashTransferRid = @pCashTransferRid
                                            WHERE   wRowNum = @sRuningIndex;							     
                                        END;
                                    UPDATE  #sDataSet_SetCashTransferDtl
                                    SET     RowID = @sRowID
                                    WHERE   wRowNum = @sRuningIndex;	
                                END;

                            SET @sRuningIndex = @sRuningIndex + 1;
                        END;

                    INSERT  INTO [CRM].[dbo].[eCashTransferDtl]
                            ( RowID ,
                              wCashTransferRid ,
                              wBookingRid ,
                              wStatus ,
                              wCrtBy ,
                              wCrtDt ,
                              wUpdBy ,
                              wUpdDt
	                       )
                            SELECT  s.RowID ,
                                    s.wCashTransferRid ,
                                    s.wBookingRid ,
                                    s.wStatus ,
                                    s.wUpdBy ,
                                    @sNow ,
                                    s.wUpdBy ,
                                    @sNow
                            FROM    #sDataSet_SetCashTransferDtl s
                            WHERE   s.RecordState = 'I';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetCashTransferDtl
                        WHERE   RecordState = 'U' )
                BEGIN
                    UPDATE  ect
                    SET     [wCashTransferRid] = tmp.wCashTransferRid ,
                            [wBookingRid] = tmp.wBookingRid ,
                            [wStatus] = tmp.wStatus ,
                            [wUpdBy] = tmp.wUpdBy ,
                            [wUpdDt] = @sNow
                    FROM    [dbo].[eCashTransferDtl] AS ect
                            INNER JOIN #sDataSet_SetCashTransferDtl tmp ON ect.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'U';
                END;

            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetCashTransferDtl
                        WHERE   RecordState = 'D' )
                BEGIN
                    UPDATE  ect
                    SET     [wStatus] = 'T' ,
                            [wUpdBy] = tmp.wUpdBy ,
                            [wUpdDt] = @sNow
                    FROM    [dbo].[eCashTransferDtl] AS ect
                            INNER JOIN #sDataSet_SetCashTransferDtl tmp ON ect.RowID = tmp.RowID
                    WHERE   tmp.RecordState = 'D';
                END;

		  --Update CashTransfer RelatedBookingRefNo
		  --Only Update when RefNo is different
            IF EXISTS ( SELECT  1
                        FROM    #sDataSet_SetCashTransferDtl
                        WHERE   RecordState = 'U'
                                OR RecordState = 'I' )
                BEGIN
                    WITH    cteCashTransferRid
                              AS ( SELECT DISTINCT
                                            sctd.wCashTransferRid
                                   FROM     #sDataSet_SetCashTransferDtl sctd
                                   WHERE    RecordState = 'U'
                                            OR RecordState = 'I'
                                 ),
                            cteBooking
                              AS ( SELECT   ctd.wCashTransferRid ,
                                            eb.wRefNo
                                   FROM     [dbo].[eCashTransferDtl] ctd
                                            LEFT JOIN [dbo].[eBooking] eb ON ( ctd.wBookingRid = eb.RowID )
                                   WHERE    ctd.wStatus = 'A'
                                 ),
                            cteRelatedBookingRefNo
                              AS ( SELECT   ctr.wCashTransferRid ,
                                            ISNULL(STUFF(( SELECT
                                                              ', ' + cb.wRefNo
                                                           FROM
                                                              cteBooking cb
                                                           WHERE
                                                              ctr.wCashTransferRid = cb.wCashTransferRid
                                                         FOR
                                                           XML
                                                              PATH('')
                                                         ), 1, 1, ''), '') AS wRefNo
                                   FROM     cteCashTransferRid ctr
                                 )
                        UPDATE  ct
                        SET     ct.wRelatedBookingRefNo = crbr.wRefNo
                        FROM    [dbo].[eCashTransfer] ct
                                INNER JOIN cteRelatedBookingRefNo crbr ON ( ct.RowID = crbr.wCashTransferRid )
                        WHERE   ct.wRelatedBookingRefNo != crbr.wRefNo;
                END;

            IF @sBeginTranCount = 0
                AND @@trancount > 0
                BEGIN
                    IF @pTestMode = 1
                        ROLLBACK;
                    ELSE
                        COMMIT;
                END;

			-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                BEGIN
                    SELECT  RowID
                    FROM    #sDataSet_SetCashTransferDtl;
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
                    EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo,
                        @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT,
                        @sErrMessageLog OUTPUT;
                END;
            ELSE
                THROW;
        END CATCH;

        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetCashTransferDtl') IS NOT NULL
            DROP TABLE #sDataSet_SetCashTransferDtl;  
    END;