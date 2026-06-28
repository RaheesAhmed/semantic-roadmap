CREATE PROCEDURE [spq].[GetVoucher]
(
    @pCounterRID BIGINT ,
    @pCorporateRID BIGINT ,
    @pVoucherRefNo BIGINT ,
    @pVoucherType NVARCHAR(50),
    @pStatus  CHAR (1),
    @pPageSize INT = 999,
    @pPageNum INT = 1,
    @pLangCd Varchar(10) ='en-GB',
    @pFromVoucherRefNo BIGINT = NULL,
    @pToVoucherRefNo BIGINT= NULL
)
AS
    BEGIN	
        SET NOCOUNT ON;

        SET @pCounterRID = ISNULL(@pCounterRID, 0);
        SET @pCorporateRID = ISNULL(@pCorporateRID, 0);
        SET @pVoucherRefNo = ISNULL(@pVoucherRefNo, 0);
        SET @pVoucherType = ISNULL(@pVoucherType, '');
        SET @pStatus = ISNULL(@pStatus, ' ');
        SET @pPageSize = ISNULL(@pPageSize, 999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
        SET @pLangCd = NULLIF(@pLangCd, 'en-GB');
        SET @pFromVoucherRefNo = ISNULL(@pFromVoucherRefNo, 0);
        SET @pFromVoucherRefNo = ISNULL(@pFromVoucherRefNo, 0);

        -- Insert statements for procedure here
        WITH tResult AS (  
            SELECT  
                wSeqNo = ROW_NUMBER() OVER ( ORDER BY  mcv.RowID),  
                mcv.RowID ,
                eb.wRefNo,
                ecv.wBookingRid,
                --ecv.wTicketType,
                eb.wBookingType,
                mcv.wCounterRID ,
                wCounterCName = mcc.wName,
                mcv.wCorporateRID ,
                wCorporateCName = CASE WHEN @pLangCd = 'en-GB' THEN mclg.wLineGrpCompEName ELSE mclg.wLineGrpCompCName END,
                mcv.wVoucherRefNo ,
                mcv.wVoucherType ,
                mcv.wVoucherValue ,
                mcv.wVoucherCurrCode ,
                wCurrencyName = LUPCUR.wTitle ,
                wVoucherValueStr = mcv.wVoucherCurrCode + '$ ' + CAST(CAST(ROUND(mcv.wVoucherValue,2) AS DECIMAL(18,2))AS VARCHAR(20)),
                mcv.wRemark,
                mcv.wVoucherStatus,
                mcv.wStatus,
                wIsSelected = CAST(0 AS bit),
                mcv.wUpdBy,
                wUpdByCName = CASE WHEN @pLangCd = 'en-GB' THEN mu.wName ELSE mu.wCName END,
                mcv.wUpdDt
            FROM dbo.mVoucher mcv
            LEFT JOIN eVoucher ecv on mcv.RowID = ecv.wVoucherRid
            LEFT JOIN eBooking eb on eb.RowID = ecv.wBookingRid
            LEFT JOIN [RollsMary].[dbo].mUsr AS mu ON mu.RowID = mcv.wUpdBy
            LEFT JOIN [RollsMary].[dbo].mCompanyLineGrp mclg ON mclg.RowID =  mcv.wCorporateRID AND mclg.wExpireYearMth = '' AND mclg.wLineGrp != ''
            LEFT JOIN dbo.mServiceCounter mcc ON mcc.RowID = mcv.wCounterRID
            LEFT JOIN dbo.mLookUp LUPCUR ON LUPCUR.wCode = mcv.wVoucherCurrCode AND LUPCUR.wType = 'CURRENCY' AND LUPCUR.wLangCd = @pLangCd
            WHERE (mcc.wStatus = 'A') 
                AND ( @pCounterRID = 0 OR @pCounterRID = mcv.wCounterRID )
                AND ( @pCorporateRID = 0 OR @pCorporateRID = mcv.wCorporateRID )
                AND ( @pVoucherRefNo = 0 OR @pVoucherRefNo = mcv.wVoucherRefNo )
                AND ( @pFromVoucherRefNo = 0 OR @pFromVoucherRefNo <= mcv.wVoucherRefNo )
                AND ( @pToVoucherRefNo = 0 OR @pToVoucherRefNo >= mcv.wVoucherRefNo )
                AND ( @pStatus = ' '  OR mcv.wVoucherStatus = @pStatus )
                AND ( @pVoucherType = '' OR @pVoucherType = mcv.wVoucherType)
        ), 
        tCount AS (
            SELECT wRecordCount = COUNT(*) FROM tResult
        )

        SELECT tResult.*, wRecordCount
        FROM tResult,tCount
        ORDER BY wVoucherRefNo asc
        OFFSET @pPageSize * (@pPageNum - 1) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION(RECOMPILE);
    END;