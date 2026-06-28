
CREATE PROCEDURE [spq].[GetHotel_Report]
    (
      @pwStatus CHAR(1) ,
      @pwLangCd VARCHAR(10) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT DISTINCT
                                mh.RowID ,
                                mh.wCode ,
                                mh.wName ,
                                CASE WHEN @pwLangCd = 'en-gb'
                                     THEN ( CASE WHEN LEN(mh.wEname) > 0
                                                 THEN mh.wEname
                                                 ELSE mh.wName
                                            END )
                                     WHEN @pwLangCd = 'zh-TW' THEN mh.wName
                                     WHEN @pwLangCd = 'ja-JP'
                                     THEN ( CASE WHEN LEN(mh.wJname) > 0
                                                 THEN mh.wJname
                                                 ELSE mh.wName
                                            END )
                                     WHEN @pwLangCd = 'th-TH'
                                     THEN ( CASE WHEN LEN(mh.wThname) > 0
                                                 THEN mh.wJname
                                                 ELSE mh.wName
                                            END )
                                     WHEN @pwLangCd = 'ko-KR'
                                     THEN ( CASE WHEN LEN(mh.wKname) > 0
                                                 THEN mh.wKname
                                                 ELSE mh.wName
                                            END )
                                     ELSE mh.wName
                                END AS wDisplayName ,
                                mh.wEname ,
                                mh.wJname ,
                                mh.wThname ,
                                mh.wKname ,
                                mh.wRegion wRegionCode ,
                                lupr.wTitle wRegion ,
                                mh.wDistrictCd ,
                                mh.wCurrCode ,
                                lupc.wTitle wCurrency ,
                                mh.wIsBase ,
                                mh.wAddress ,
                                mh.wRemark ,
                                mh.wSmsRemark ,
                                mh.wSeqNo ,
                                mh.wStatus ,
                                mh.wCrtDt ,
                                mh.wCrtBy ,
                                mh.wUpdDt ,
                                mh.wUpdBy ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                CASE WHEN eah.wHotelRid = mh.RowID THEN 1
                                     ELSE 0
                                END AS wIsAgentHotel ,
                                CAST(0 AS BIT) AS wIsSelected ,
                                CAST(1 AS BIT) AS wIsAllowedForDelete ,
                                0 AS wPriority
                       FROM     dbo.mHotel mh
                                INNER JOIN mLookUp lupr ON lupr.wCode = mh.wRegion
                                                           AND lupr.wType = 'REGION'
                                                           AND lupr.wLangCd = @pwLangCd
                                INNER JOIN mLookUp lupc ON lupc.wCode = mh.wCurrCode
                                                           AND lupc.wType = 'CURRENCY'
                                                           AND lupc.wLangCd = @pwLangCd
                                LEFT JOIN dbo.eAllotmentHotel eah ON eah.wHotelRid = mh.RowID
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mh.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mh.wCrtBy
                       WHERE    ( @pwStatus = ''
                                  OR @pwStatus IS NULL
                                  OR @pwStatus = mh.wStatus
                                )					
			
		--AND
		--( @pwLangCd = '' 
		--	OR  @pwLangCd IS NULL
		--	OR   @pwLangCd = mh.wLangCd)
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY wCrtDt DESC;
    --                OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  --FETCH NEXT @pPageSize ROWS ONLY;

    END;