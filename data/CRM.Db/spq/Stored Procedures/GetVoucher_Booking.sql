
CREATE PROCEDURE [spq].[GetVoucher_Booking]
    (
      @pCounterRID BIGINT ,
      @pCorporateRID BIGINT ,
      @pVoucherRefNo BIGINT ,
      @pVoucherType NVARCHAR(50),
	  @pwStatus  CHAR (1),
	  @pPageSize INT = 999,
	  @pPageNum INT = 1,
	  @pwLangCd Varchar(10) ='en-GB'
	  ,@pFromVoucherRefNo BIGINT = NULL
	  ,@pToVoucherRefNo BIGINT= NULL
    )
AS
    BEGIN	
        SET NOCOUNT ON;

    -- Insert statements for procedure here
       WITH tResult AS (  
       SELECT  
	       ROW_NUMBER() OVER ( ORDER BY  mcv.RowID)  AS wSeqNo,  
		   mcv.RowID ,
		   eb.wRefNo,
		   ecv.wBookingRid,
		   --ecv.wTicketType,
		   eb.wBookingType,
		   mcv.wCounterRID ,
		   mcc.wName AS wCounterCName,
		   mcv.wCorporateRID ,
		   wCorporateCName = CASE WHEN @pwLangCd = 'en-gb' THEN mclg.wLineGrpCompEName ELSE mclg.wLineGrpCompCName END,
		   mcv.wVoucherRefNo ,
		   mcv.wVoucherType ,
		   mcv.wVoucherValue ,
		   mcv.wVoucherCurrCode ,
		   LUPCUR.wTitle AS wCurrencyName ,
		   mcv.wVoucherCurrCode + '$ ' + CAST(CAST(ROUND(mcv.wVoucherValue,2) AS DECIMAL(18,2))AS VARCHAR(20)) AS wVoucherValueStr ,
		   mcv.wRemark,
		   mcv.wVoucherStatus,
		   mcv.wStatus
		   ,CAST(0 AS bit) AS wIsSelected,
		   mcv.wUpdBy
		   ,CASE WHEN @pwLangCd = 'en-gb' THEN mu.wName ELSE mu.wCName END AS wUpdByCName
           ,mcv.wUpdDt
        FROM   [CRM].[dbo].mVoucher mcv
				LEFT JOIN eVoucher ecv on mcv.RowID = ecv.wVoucherRid
				LEFT JOIN eBooking eb on eb.RowID = ecv.wBookingRid
				LEFT JOIN [RollsMary].[dbo].mUsr AS mu ON mu.RowID = mcv.wUpdBy
				LEFT JOIN [RollsMary].[dbo].mCompanyLineGrp mclg ON mclg.RowID =  mcv.wCorporateRID AND mclg.wExpireYearMth = '' AND mclg.wLineGrp != ''
				LEFT JOIN dbo.mServiceCounter mcc ON mcc.RowID = mcv.wCounterRID
				LEFT JOIN dbo.mLookUp LUPCUR ON LUPCUR.wCode = mcv.wVoucherCurrCode AND LUPCUR.wType = 'CURRENCY' AND LUPCUR.wLangCd = @pwLangCd
        WHERE    (mcc.wStatus = 'A')
		                
				AND ( @pCounterRID = 0
                      OR @pCounterRID IS NULL
                      OR @pCounterRID = mcv.wCounterRID
                    )
                AND ( @pCorporateRID = 0
                      OR @pCorporateRID IS NULL
                      OR @pCorporateRID = mcv.wCorporateRID
                    )
                AND ( @pVoucherRefNo = 0
                      OR @pVoucherRefNo IS NULL
                      OR @pVoucherRefNo = mcv.wVoucherRefNo
                    )

					AND ( @pFromVoucherRefNo = 0
                      OR @pFromVoucherRefNo  IS NULL
                      OR @pFromVoucherRefNo <= mcv.wVoucherRefNo
                    )
					AND (@pToVoucherRefNo = 0
                      OR @pToVoucherRefNo IS NULL
                      OR @pToVoucherRefNo >= mcv.wVoucherRefNo
                    )


				AND ( @pwStatus = ''
					OR @pwStatus = ' '
                    OR @pwStatus IS NULL
                    OR mcv.wVoucherStatus = @pwStatus
					)
                AND ( @pVoucherType = ''
                      OR @pVoucherType IS NULL
                      OR @pVoucherType = mcv.wVoucherType
                    )), tCount AS (
		SELECT wRecordCount = COUNT(*) FROM tResult
		)
	SELECT tResult.*, wRecordCount
		FROM tResult,tCount
		  ORDER BY wVoucherRefNo asc
		  OFFSET @pPageSize * (@pPageNum - 1) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;	
    END;