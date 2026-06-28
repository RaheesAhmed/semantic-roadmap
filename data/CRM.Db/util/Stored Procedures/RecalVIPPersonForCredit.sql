CREATE PROC [util].[RecalVIPPersonForCredit]
    @pInXML    XML,
    @pOutXML   XML OUTPUT -- INSERT EXEC不能嵌套，用XML返回
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sRecCount     INT = 0 ,
                @sRuningIndex  INT = 1,
                @sAgentCodeIn  VARCHAR(14);

        CREATE TABLE #vAgent (
            RowNum          BIGINT IDENTITY(1,1),
            wAgentCodeIn    VARCHAR(14) PRIMARY KEY,
            wHasCredit      CHAR(1)
        );

        CREATE TABLE #vResult(
            wAgentCodeIn    VARCHAR(14) PRIMARY KEY
        );

        /*
        CREATE TABLE #vResult (
	       wAgentCodeIn			VARCHAR(14),
	       wAgentCode				NVARCHAR(40),
	       wAgentCode_Display		NVARCHAR(60),
	       wCName					NVARCHAR(60),
	       wAgentLevel				INT,
	       wIsDirectCreditAcc		CHAR(1),
	       wUpLvlAgentCodeIn		VARCHAR(14),
	       wUpLvlAgentCode_Display	NVARCHAR(60),
	       wUpLvlCName				NVARCHAR(60),
	       wURemark				VARCHAR(20),
	       wCreditAmt				NUMERIC(18, 4) NOT NULL,
	       wCapitalAmt				NUMERIC(18, 4) NOT NULL,
	       wMthInterestAmt			NUMERIC(18, 4) NOT NULL,
	       wCreditCapitalAmt		NUMERIC(18, 4) NOT NULL,
	       wCashLoanAmt			NUMERIC(18, 4) NOT NULL,
	       wMasterCasinoCreditAmt	NUMERIC(18, 4) NOT NULL,
	       wEXPCreditAmt			NUMERIC(18, 4) NOT NULL,
	       wTTLEXPCreditAmt			NUMERIC(18, 4) NOT NULL,
	       wCreditAmtYellow			NUMERIC(18, 4) NOT NULL,
	       wCreditAmtForeign		NUMERIC(18, 4) NOT NULL,
	       wFreezeAmt				NUMERIC(18, 4) NOT NULL,
	       wTTLFreezeAmt			NUMERIC(18, 4) NOT NULL,
	       --凍M(自己)
	       wIOUFreezeAmt			NUMERIC(18, 4) NOT NULL,
	       wIOUFreezeAmt_OD			NUMERIC(18, 4) NOT NULL,
	       --凍M(下線)
	       wTTLIOUFreezeAmt			NUMERIC(18, 4) NOT NULL,
	       wTTLIOUFreezeAmt_OD		NUMERIC(18, 4) NOT NULL,
	       --個人 未扣凍M 借貸
	       wOutstanding_CAP			NUMERIC(18, 4) NOT NULL,
	       wOutstanding_MTH			NUMERIC(18, 4) NOT NULL,
	       wOutstanding_MASTER		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_CREDIT		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_IOU			NUMERIC(18, 4) NOT NULL,
	       wOutstanding_CIO			NUMERIC(18, 4) NOT NULL,
	       wOutstanding_CH			NUMERIC(18, 4) NOT NULL,
	       wOutstanding_Y			NUMERIC(18, 4) NOT NULL,
	       wOutstanding_Y_loan		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_Y_Store		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_Y_NSettle	NUMERIC(18, 4) NOT NULL,
	       wOutstanding_F			NUMERIC(18, 4) NOT NULL,
	       wOutstanding_F_loan		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_F_Store		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_F_NSettle	NUMERIC(18, 4) NOT NULL,
	       --個人 未扣凍M 借貸 -- 未過期
	       wOutstanding_CAP_N		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_MTH_N		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_MASTER_N		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_CREDIT_N		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_IOU_N		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_CIO_N		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_CH_N		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_Y_N			NUMERIC(18, 4) NOT NULL,
	       wOutstanding_Y_N_loan		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_F_N			NUMERIC(18, 4) NOT NULL,
	       wOutstanding_F_N_loan		NUMERIC(18, 4) NOT NULL,
	       --個人 未扣凍M 借貸 -- 已過期
	       wOutstanding_CAP_OD		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_MTH_OD		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_MASTER_OD	NUMERIC(18, 4) NOT NULL,
	       wOutstanding_CREDIT_OD	NUMERIC(18, 4) NOT NULL,
	       wOutstanding_IOU_OD		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_CIO_OD		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_CH_OD		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_Y_OD		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_Y_OD_loan	NUMERIC(18, 4) NOT NULL,
	       wOutstanding_F_OD		NUMERIC(18, 4) NOT NULL,
	       wOutstanding_F_OD_loan	NUMERIC(18, 4) NOT NULL,
	       --------------------------------------------	--------------------------

	       --連下線 總 借貸
	       wTTLOutstanding_CAP		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_MTH		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_MASTER	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_CREDIT	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_IOU		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_CIO		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_CH		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_Y		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_Y_loan	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_Y_Store	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_Y_NSettle	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_F		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_F_loan	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_F_Store	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_F_NSettle	NUMERIC(18, 4) NOT NULL,
	       --連下線 總 借貸 -- 未過期
	       wTTLOutstanding_CAP_N		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_MTH_N		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_MASTER_N	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_CREDIT_N	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_IOU_N		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_CIO_N		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_CH_N		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_Y_N		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_Y_N_loan	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_F_N		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_F_N_loan	NUMERIC(18, 4) NOT NULL,
	       --連下線 總 借貸 -- 已過期
	       wTTLOutstanding_CAP_OD	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_MTH_OD	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_MASTER_OD	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_CREDIT_OD	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_IOU_OD	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_CIO_OD	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_CH_OD		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_Y_OD		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_Y_OD_loan	NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_F_OD		NUMERIC(18, 4) NOT NULL,
	       wTTLOutstanding_F_OD_loan	NUMERIC(18, 4) NOT NULL,
	       ----------------------------------------------------------------------

	       --連下線 已扣凍M 借貸
	       wRealOutstanding_CAP		NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_MTH		NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_MASTER	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_CREDIT	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_IOU		NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_CIO		NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_CH		NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_Y		NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_F		NUMERIC(18, 4) NOT NULL,
	       --連下線 已扣凍M 借貸 -- 未過期
	       wRealOutstanding_CAP_N	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_MTH_N	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_MASTER_N	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_CREDIT_N	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_IOU_N	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_CIO_N	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_CH_N		NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_Y_N		NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_F_N		NUMERIC(18, 4) NOT NULL,
	       --連下線 已扣凍M 借貸 -- 已過期
	       wRealOutstanding_CAP_OD	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_MTH_OD	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_MASTER_OD NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_CREDIT_OD NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_IOU_OD	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_CIO_OD	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_CH_OD	NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_Y_OD		NUMERIC(18, 4) NOT NULL,
	       wRealOutstanding_F_OD		NUMERIC(18, 4) NOT NULL,
	       --------------------------------------------------------------------

	       --罰息
	       wIOUPenalty				NUMERIC(18, 4) NOT NULL,
	       wIOUPenalty_Y			NUMERIC(18, 4) NOT NULL,
	       wIOUPenalty_F			NUMERIC(18, 4) NOT NULL,
	       wTTLIOUPenalty			NUMERIC(18, 4) NOT NULL,
	       wTTLIOUPenalty_Y			NUMERIC(18, 4) NOT NULL,
	       wTTLIOUPenalty_F			NUMERIC(18, 4) NOT NULL,
	       wDnLvlAgentCodeIn		VARCHAR(14)
        );
        */

        IF @pInXML IS NOT NULL
        BEGIN
            INSERT INTO #vAgent(wAgentCodeIn)
            SELECT DISTINCT wAgentCodeIn = T.tmp.value('@wAgentCodeIn', 'VARCHAR(14)')
            FROM @pInXML.nodes('DataSet/Record') T(tmp)
            WHERE NULLIF(T.tmp.value('@wAgentCodeIn', 'VARCHAR(14)'), '') IS NOT NULL;
        END;
        
        IF EXISTS (SELECT 1 FROM #vAgent)
        BEGIN
            --SET @sRuningIndex = 1;
            --SET @sRecCount = (SELECT COUNT(1) FROM #vAgent);

            --PRINT @sRecCount;
            
            --WHILE @sRuningIndex <= @sRecCount
            --BEGIN
            --    PRINT @sRuningIndex;

            --    SET @sAgentCodeIn = (SELECT TOP(1) wAgentCodeIn FROM #vAgent WHERE RowNum = @sRuningIndex);

            --    INSERT INTO #vResult EXEC [RollsMary].[spq].[GetAgentSummaryCredit_UpLvl_V3] @sAgentCodeIn, 'N', 'A','HKD';

            --    SET @sRuningIndex = @sRuningIndex + 1;
            --END;

            INSERT INTO #vResult(wAgentCodeIn)
            SELECT DISTINCT ct.wAgentCodeIn
            FROM Rollsmary.dbo.eCreditTran ct
            WHERE ct.wStatus = 'O'
                AND (  ct.wCreditAmt > 0
                    OR ct.wCapitalAmt > 0
                    OR ct.wMthInterestAmt > 0
                    OR ct.wCreditCapitalAmt > 0
                    OR ct.wMasterCasinoCreditAmt > 0
                    OR ct.wCreditAmtYellow > 0
                    OR ct.wCreditAmtForeign > 0
                );
        END;

        UPDATE ma
        SET ma.wHasCredit = IIF(r.wAgentCodeIn IS NOT NULL, 'Y', 'N')
        FROM #vAgent ma
        LEFT JOIN #vResult r ON r.wAgentCodeIn = ma.wAgentCodeIn;

        SET @pOutXML = NULL;
        SET @pOutXML = ( SELECT wAgentCodeIn FROM #vAgent WHERE wHasCredit = 'Y' FOR XML RAW('Record'), ROOT('DataSet') );

        IF OBJECT_ID('tempdb..#vAgent') IS NOT NULL
            DROP TABLE #vAgent;
        
        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END;