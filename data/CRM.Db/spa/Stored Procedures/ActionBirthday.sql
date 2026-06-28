CREATE PROCEDURE [spa].[ActionBirthday]
    @pXMLBirthday           XML = NULL ,
    @pXMLBirthdayGift       XML = NULL ,
    @pXMLBirthdayGiftImg    XML = NULL,
    @pOFile			        VARBINARY(MAX), -- 原圖
    @pMFile                 VARBINARY(MAX), -- 中圖
    @pSFile                 VARBINARY(MAX), -- 小圖
    @pMainCompNo            INT ,
    @pNonceToken            VARCHAR(64) ,
    @pBirthdayRid           BIGINT = 0 OUTPUT ,
    @pErrCode               INT = 0 OUTPUT ,
    @pErrMsg                NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        ---------------------- dbml -----------------------
        --DECLARE @sResult TABLE(RowID BIGINT NOT NULL);
        --SELECT RowID FROM @sResult;
        --------------------end dbml ----------------------

        DECLARE @sBeginTranCount INT = 0,
                @sBirthdayGiftRid BIGINT;

        SET @sBeginTranCount = @@trancount;
        SET @pErrCode = 0;
        SET @pErrMsg = '';

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;
				
            IF NULLIF(@pErrMsg, '') IS NULL
                EXEC spa.SetBirthday @pXMLBirthday, 'U', @pMainCompNo, @pNonceToken, @pBirthdayRid OUTPUT, @pErrCode OUTPUT, @pErrMsg OUTPUT;

            IF NULLIF(@pErrMsg, '') IS NULL
                EXEC spa.SetBirthdayGift @pXMLBirthdayGift, @pBirthdayRid, @pMainCompNo, @pNonceToken, @sBirthdayGiftRid OUTPUT, @pErrCode OUTPUT,  @pErrMsg OUTPUT;

            IF NULLIF(@pErrMsg, '') IS NULL
            BEGIN
                DECLARE @sActionType CHAR(1);
                DECLARE @sDocument TABLE (
                    RowID BIGINT,
                    wCompNo INT,
                    wCageCodeIn VARCHAR(14),
                    wRefTable VARCHAR(50),
                    wRefRID BIGINT,
                    wDocName NVARCHAR(100),
                    wDocExt VARCHAR(5),
                    wType VARCHAR(20), 
                    wCategory VARCHAR(20),
                    wDesc NVARCHAR(100),
                    wUpdBy BIGINT,
	                wUpdDt DATETIME2(7), 
                    wStatus CHAR(1), 
                    wSysRemark NVARCHAR(200)
                );

                IF @pXMLBirthdayGiftImg IS NOT NULL
                BEGIN
                    INSERT INTO @sDocument
                    SELECT
                        RowID       = T.tmp.value('@RowID',         'BIGINT'),
                        wCompNo     = T.tmp.value('@wCompNo',       'INT'),
                        wCageCodeIn = T.tmp.value('@wCageCodeIn',   'VARCHAR(14)'),
                        wRefTable   = 'eBirthdayGift',
                        wRefRID     = @sBirthdayGiftRid,
                        wDocName    = T.tmp.value('@wDocName',      'NVARCHAR(100)'),
                        wDocExt     = T.tmp.value('@wDocExt',       'VARCHAR(5)'),
                        wType       = T.tmp.value('@wType',         'VARCHAR(20)'),
                        wCategory   = T.tmp.value('@wCategory',     'VARCHAR(20)'),
                        wDesc       = T.tmp.value('@wDesc',         'NVARCHAR(100)'),
                        wUpdBy      = T.tmp.value('@wUpdBy',        'BIGINT'),
	                    wUpdDt      = GETDATE(),
                        wStatus     = T.tmp.value('@wStatus',       'CHAR(1)'),
                        wSysRemark  = T.tmp.value('@wSysRemark',    'NVARCHAR(200)')
                    FROM @pXMLBirthdayGiftImg.nodes('DataSet/Record') AS T(tmp)
                    WHERE T.tmp.value('@wRecordState', 'CHAR(1)') = 'I'; -- document只要是replace，不允許update某一條record，因為涉及縮略圖

                    SET @sActionType = 'I';
                END
                ELSE
                BEGIN
                    INSERT INTO @sDocument
                    SELECT
                        RowID       = RowID,
                        wCompNo     = wCompNo,
                        wCageCodeIn = wCageCodeIn,
                        wRefTable   = wRefTable,
                        wRefRID     = wRefRID,
                        wDocName    = wDocName,
                        wDocExt     = wDocExt,
                        wType       = wType,
                        wCategory   = wCategory,
                        wDesc       = wDesc,
                        wUpdBy      = wUpdBy,
	                    wUpdDt      = GETDATE(),
                        wStatus     = 'T',
                        wSysRemark  = wSysRemark
                    FROM CRM_Doc.dbo.eDocument
                    WHERE wRefTable = 'eBirthdayGift'
                        AND wRefRID = @sBirthdayGiftRid;

                    SET @sActionType = 'D';
                END;

                SET @pXMLBirthdayGiftImg = (SELECT * FROM @sDocument FOR XML RAW('Record'), ROOT('DataSet'));

                EXEC CRM_Doc.spa.SetDocumentWithThumbnail @pXMLBirthdayGiftImg, @pOFile, @pMFile, @pSFile, @sActionType, @pMainCompNo, @pNonceToken, @pErrCode OUTPUT,  @pErrMsg OUTPUT;
            END;

            IF NULLIF(@pErrMsg, '') IS NOT NULL
                THROW 50001, @pErrMsg, 1;

            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

            
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
                SET @pErrCode = 70001;
            END;

            IF NULLIF(@pErrMsg, '') IS NULL
                SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
            BEGIN
                ROLLBACK;
            END;
	        
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;

        END CATCH;
    END;