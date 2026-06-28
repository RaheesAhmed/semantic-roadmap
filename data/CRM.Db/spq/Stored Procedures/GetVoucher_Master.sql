
CREATE PROCEDURE [spq].[GetVoucher_Master]
    (
      @pCounterRID BIGINT ,
      @pCorporateRID BIGINT ,
      @pVoucherRefNo BIGINT ,
      @pVoucherType NVARCHAR(50) ,
      @pwStatus CHAR(1) ,
      @pPageSize INT ,
      @pPageNum INT ,
      @pwLangCd VARCHAR(10) ,
      @pFromVoucherRefNo BIGINT ,
      @pToVoucherRefNo BIGINT ,
      @pSort VARCHAR(200)
    )
AS
    BEGIN	
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

        SET @pCounterRID = ISNULL(@pCounterRID, 0);
        SET @pCorporateRID = ISNULL(@pCorporateRID, 0);
        SET @pVoucherRefNo = ISNULL(@pVoucherRefNo, 0);
        SET @pVoucherType = ISNULL(@pVoucherType, '');
        SET @pwStatus = ISNULL(@pwStatus, ' ');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
        SET @pwLangCd = ISNULL(@pwLangCd, 'en-gb');
        SET @pFromVoucherRefNo = ISNULL(@pFromVoucherRefNo, 0);
        SET @pToVoucherRefNo = ISNULL(@pToVoucherRefNo, 0);
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;

    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY mcv.RowID ) AS wSeqNo ,
                                mcv.RowID ,
                                eb.wRefNo ,
                                ecv.wBookingRid ,
		   --ecv.wTicketType,
                                eb.wBookingType ,
                                mcv.wCounterRID ,
                                mcc.wName AS wVoucherCounterCName ,
                                mcv.wCorporateRID ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN mclg.wLineGrpCompEName
                                     ELSE mclg.wLineGrpCompCName
                                END AS wVoucherCorporateCName ,
                                mcv.wVoucherRefNo ,
                                mcv.wVoucherType ,
                                mcv.wVoucherValue ,
                                mcv.wVoucherCurrCode AS wCurrCode ,
                                mcv.wVoucherCurrCode + '$ ' + CAST(CAST(ROUND(mcv.wVoucherValue, 2) AS DECIMAL(18, 2)) AS VARCHAR(20)) AS wVoucherValueStr ,
                                mcv.wRemark ,
                                mcv.wVoucherStatus ,
                                mcv.wStatus ,
                                CAST(0 AS BIT) AS wIsSelected ,
                                mcv.wUpdBy ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN mu.wName
                                     ELSE mu.wCName
                                END AS wUpdByCName ,
                                mcv.wUpdDt
                       FROM     [dbo].mVoucher mcv
                                LEFT JOIN dbo.eVoucher ecv ON mcv.RowID = ecv.wVoucherRid
                                LEFT JOIN dbo.eBooking eb ON eb.RowID = ecv.wBookingRid
                                LEFT JOIN [RollsMary].[dbo].mUsr AS mu ON mu.RowID = mcv.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].mCompanyLineGrp mclg ON mclg.RowID = mcv.wCorporateRID
                                                                                    AND mclg.wExpireYearMth = ''
                                                                                    AND mclg.wLineGrp != ''
                                LEFT JOIN dbo.mServiceCounter mcc ON mcc.RowID = mcv.wCounterRID
                       WHERE    ( @pCounterRID = 0
                                  OR @pCounterRID = mcv.wCounterRID
                                )
                                AND ( @pCorporateRID = 0
                                      OR @pCorporateRID = mcv.wCorporateRID
                                    )
                                AND ( @pVoucherRefNo = 0
                                      OR @pVoucherRefNo IS NULL
                                      OR @pVoucherRefNo = mcv.wVoucherRefNo
                                    )
                                AND ( @pFromVoucherRefNo = 0
                                      OR @pFromVoucherRefNo <= mcv.wVoucherRefNo
                                    )
                                AND ( @pToVoucherRefNo = 0
                                      OR @pToVoucherRefNo >= mcv.wVoucherRefNo
                                    )
                                AND ( @pwStatus = ' '
                                      OR mcv.wVoucherStatus = @pwStatus
                                    )
                                AND ( @pVoucherType = ''
                                      OR @pVoucherType = mcv.wVoucherType
                                    )
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wVoucherRefNo
                     END DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY
		  OPTION (RECOMPILE);
    END;