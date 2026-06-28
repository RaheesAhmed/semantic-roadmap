CREATE PROCEDURE [spq].[GetHotel_Share]
    @pStatus CHAR(1) ,
    @pLangCd VARCHAR(10)
AS
    BEGIN
        SET NOCOUNT ON;
	
        SET @pStatus = NULLIF(@pStatus, '');

        WITH tAgentHotel AS (
            SELECT wHotelRid
            FROM dbo.eAllotmentHotel
            GROUP BY wHotelRid
        )

        SELECT  mh.RowID ,
                mh.wCode ,
                mh.wName ,
                CASE WHEN @pLangCd = 'en-gb'
                        THEN ( CASE WHEN LEN(mh.wEname) > 0
                                    THEN mh.wEname
                                    ELSE mh.wName
                            END )
                        WHEN @pLangCd = 'zh-TW' THEN mh.wName
                        WHEN @pLangCd = 'ja-JP'
                        THEN ( CASE WHEN LEN(mh.wJname) > 0
                                    THEN mh.wJname
                                    ELSE mh.wName
                            END )
                        WHEN @pLangCd = 'th-TH'
                        THEN ( CASE WHEN LEN(mh.wThname) > 0
                                    THEN mh.wJname
                                    ELSE mh.wName
                            END )
                        WHEN @pLangCd = 'ko-KR'
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
                mh.wGetKeyMethod,
                mh.wIsSunTrip,
                mh.wDebitServiceCounter,
                mh.wStatus,
                CASE WHEN eah.wHotelRid IS NOT NULL THEN 1 ELSE 0 END AS wIsAgentHotel ,
                CAST(0 AS BIT) AS wIsSelected ,
                CAST(1 AS BIT) AS wIsAllowedForDelete ,
                0 AS wPriority
        FROM dbo.mHotel mh
        INNER JOIN dbo.mLookUp lupr ON lupr.wCode = mh.wRegion AND lupr.wType = 'REGION' AND lupr.wLangCd = @pLangCd
        INNER JOIN dbo.mLookUp lupc ON lupc.wCode = mh.wCurrCode AND lupc.wType = 'CURRENCY' AND lupc.wLangCd = @pLangCd
        LEFT JOIN tAgentHotel eah ON eah.wHotelRid = mh.RowID
        WHERE @pStatus IS NULL OR @pStatus = mh.wStatus;
    END;