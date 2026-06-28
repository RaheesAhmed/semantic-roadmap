--SELECT * FROM dbo.mHotel (NOLOCK) WHERE wStatus='A' and wregion='HKG'

CREATE PROCEDURE [spq].[GetHotelList] -- 'Y',null,10000000011828,'en-gb',99,1
    @pIsLoadBaseHotel CHAR(1) ,
    @pHotelRequestRid BIGINT = NULL ,
    @pBookingRid BIGINT = NULL ,
    @pLangCd VARCHAR(10) ,
    @pPageSize INT = 9999 ,
    @pPageNum INT = 1
AS
    BEGIN

        SET NOCOUNT ON;
        IF @pBookingRid IS NOT NULL
            AND @pBookingRid > 0
            BEGIN
                WITH    tResult
                          AS ( SELECT DISTINCT
                                        mh.wSeqNo ,
                                        mh.RowID ,
                                        mh.wCode ,
                                        mh.wName ,
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
                                        mh.wUpdDt ,
                                        mh.wUpdBy ,
                                        mh.wStatus,
                                        CASE WHEN @pLangCd = 'en-gb'
                                             THEN usr.wName
                                             ELSE usr.wCName
                                        END AS wUpdByCName ,
                                        CASE WHEN @pLangCd = 'en-gb'
                                             THEN crusr.wName
                                             ELSE crusr.wCName
                                        END AS wCreatedByCName
                               FROM     ( SELECT    *
                                          FROM      dbo.mHotel (NOLOCK)
                                          WHERE     wIsBase = '1'
                                        ) mh
                                        INNER JOIN dbo.mLookUp (NOLOCK) lupr ON lupr.wCode = mh.wRegion
                                                              AND lupr.wType = 'REGION'
                                                              AND lupr.wLangCd = @pLangCd
                                        INNER JOIN dbo.mLookUp (NOLOCK) lupc ON lupc.wCode = mh.wCurrCode
                                                              AND lupc.wType = 'CURRENCY'
                                                              AND lupc.wLangCd = @pLangCd
                                        LEFT JOIN [RollsMary].[dbo].[mUsr] (NOLOCK) usr ON usr.RowID = mh.wUpdBy
                                        LEFT JOIN [RollsMary].[dbo].[mUsr] (NOLOCK) crusr ON crusr.RowID = mh.wCrtBy
                                        INNER JOIN ( SELECT *
                                                     FROM   dbo.eBookingHotel (NOLOCK)
                                                     WHERE  wBookingRid = @pBookingRid
                                                            AND wStatus = 'A'
                                                   ) HRT ON HRT.wRegion = mh.wRegion
                               UNION
                               SELECT DISTINCT
                                        mh.wSeqNo ,
                                        mh.RowID ,
                                        mh.wCode ,
                                        mh.wName ,
                                        mh.wEname ,
                                        mh.wJname ,
                                        mh.wThname ,
                                        mh.wKname ,
                                        ISNULL(mh.wRegion, '') wRegionCode ,
                                        lupr.wTitle wRegion ,
                                        mh.wDistrictCd ,
                                        mh.wCurrCode ,
                                        lupc.wTitle wCurrency ,
                                        mh.wIsBase ,
                                        mh.wUpdDt ,
                                        mh.wUpdBy ,
                                        mh.wStatus,
                                        CASE WHEN @pLangCd = 'en-gb'
                                             THEN usr.wName
                                             ELSE usr.wCName
                                        END AS wUpdByCName ,
                                        CASE WHEN @pLangCd = 'en-gb'
                                             THEN crusr.wName
                                             ELSE crusr.wCName
                                        END AS wCreatedByCName
                               FROM     ( SELECT    *
                                          FROM      dbo.mHotel (NOLOCK)
                                          WHERE     wIsBase <> '1'
                                                    AND ( wIsBase = @pIsLoadBaseHotel )
                                        ) mh
                                        INNER JOIN dbo.mLookUp (NOLOCK) lupr ON lupr.wCode = mh.wRegion
                                                              AND lupr.wType = 'REGION'
                                                              AND lupr.wLangCd = @pLangCd
                                        INNER JOIN dbo.mLookUp (NOLOCK) lupc ON lupc.wCode = mh.wCurrCode
                                                              AND lupc.wType = 'CURRENCY'
                                                              AND lupc.wLangCd = @pLangCd
                                        LEFT JOIN [RollsMary].[dbo].[mUsr] (NOLOCK) usr ON usr.RowID = mh.wUpdBy
                                        LEFT JOIN [RollsMary].[dbo].[mUsr] (NOLOCK) crusr ON crusr.RowID = mh.wCrtBy
                                        INNER JOIN ( SELECT *
                                                     FROM   dbo.eBookingHotel (NOLOCK)
                                                     WHERE  wBookingRid = @pBookingRid
                                                            AND wStatus = 'A'
                                                   ) HRT ON HRT.wRegion = mh.wRegion
                             ),
                        tCount
                          AS ( SELECT   wRecordCount = COUNT(*)
                               FROM     tResult
                             )
                    SELECT  tResult.* ,
                            wRecordCount
                    FROM    tResult ,
                            tCount
                    ORDER BY wSeqNo
                            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY OPTION (RECOMPILE);
            END;
        ELSE
            BEGIN
                WITH    tResult
                          AS ( SELECT DISTINCT
                                        mh.wSeqNo ,
                                        mh.RowID ,
                                        mh.wCode ,
                                        mh.wName ,
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
                                        mh.wUpdDt ,
                                        mh.wUpdBy ,
                                        mh.wStatus,
                                        CASE WHEN @pLangCd = 'en-gb'
                                             THEN usr.wName
                                             ELSE usr.wCName
                                        END AS wUpdByCName ,
                                        CASE WHEN @pLangCd = 'en-gb'
                                             THEN crusr.wName
                                             ELSE crusr.wCName
                                        END AS wCreatedByCName
                               FROM     ( SELECT    *
                                          FROM      dbo.mHotel (NOLOCK)
                                          WHERE     wIsBase = '1'
                                        ) mh
                                        INNER JOIN dbo.mLookUp (NOLOCK) lupr ON lupr.wCode = mh.wRegion
                                                              AND lupr.wType = 'REGION'
                                                              AND lupr.wLangCd = @pLangCd
                                        INNER JOIN dbo.mLookUp (NOLOCK) lupc ON lupc.wCode = mh.wCurrCode
                                                              AND lupc.wType = 'CURRENCY'
                                                              AND lupc.wLangCd = @pLangCd
                                        LEFT JOIN [RollsMary].[dbo].[mUsr] (NOLOCK) usr ON usr.RowID = mh.wUpdBy
                                        LEFT JOIN [RollsMary].[dbo].[mUsr] (NOLOCK) crusr ON crusr.RowID = mh.wCrtBy
                             ),
                        tCount
                          AS ( SELECT   wRecordCount = COUNT(*)
                               FROM     tResult
                             )
                    SELECT  tResult.* ,
                            wRecordCount
                    FROM    tResult ,
                            tCount
                    ORDER BY wUpdDt DESC
                            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY OPTION(RECOMPILE);
            END;
    END;