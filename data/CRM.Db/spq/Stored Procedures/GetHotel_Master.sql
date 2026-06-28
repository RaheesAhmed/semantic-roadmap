
CREATE PROCEDURE [spq].[GetHotel_Master]
    (
      @pName AS NVARCHAR(100) ,
      @pEName AS NVARCHAR(100) ,
      @pRegion AS VARCHAR(20) ,
      @pDistrictCd AS VARCHAR(30) ,
      @pIsBase AS CHAR(1) ,
      @pCode AS VARCHAR(20) ,
      @pCurrCode AS VARCHAR(6) ,
      @pStatus CHAR(1) ,
      @pSort VARCHAR(200) ,
      @pLangCd VARCHAR(10) ,
      @pPageSize INT ,
      @pPageNum INT
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;						

        SET @pName = ISNULL(@pName, '');
        SET @pEName = ISNULL(@pEName, '');
        SET @pRegion = ISNULL(@pRegion, '');
        SET @pDistrictCd = ISNULL(@pDistrictCd, '');
        SET @pIsBase = ISNULL(@pIsBase, ' ');
        SET @pCode = ISNULL(@pCode, '');
        SET @pCurrCode = ISNULL(@pCurrCode, '');
        SET @pStatus = ISNULL(@pStatus, ' ');
        SET @pSort = CASE WHEN ISNULL(@pSort, '') = '' THEN '||'
                          ELSE @pSort
                     END;
        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');
        SET @pPageSize = ISNULL(@pPageSize, 9999);
        SET @pPageNum = ISNULL(@pPageNum, 1);
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT DISTINCT
                                mh.RowID ,
                                mh.wCode AS wHotelCode ,
                                mh.wName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN ( CASE WHEN LEN(mh.wEname) > 0 THEN mh.wEname
                                                                         ELSE mh.wName
                                                                    END )
                                     WHEN @pLangCd = 'zh-TW' THEN mh.wName
                                     WHEN @pLangCd = 'ja-JP' THEN ( CASE WHEN LEN(mh.wJname) > 0 THEN mh.wJname
                                                                         ELSE mh.wName
                                                                    END )
                                     WHEN @pLangCd = 'th-TH' THEN ( CASE WHEN LEN(mh.wThname) > 0 THEN mh.wJname
                                                                         ELSE mh.wName
                                                                    END )
                                     WHEN @pLangCd = 'ko-KR' THEN ( CASE WHEN LEN(mh.wKname) > 0 THEN mh.wKname
                                                                         ELSE mh.wName
                                                                    END )
                                     ELSE mh.wName
                                END AS wDisplayName ,
                                mh.wEname AS wHotelEname ,
                                mh.wJname ,
                                mh.wThname ,
                                mh.wKname ,
                                mh.wRegion AS wLocation ,
                                mh.wDistrictCd ,
                                mh.wCurrCode ,
                                mh.wIsBase ,
                                mh.wAddress ,
                                mh.wRemark ,
                                mh.wSmsRemark AS wSMSRemark ,
                                mh.wSeqNo ,
                                mh.wGetKeyMethod,
                                mh.wIsSunTrip,
                                mh.wDebitServiceCounter,
                                mh.wHasWIFI,
                                mh.wNeedEntrancePaper,
                                mh.wEntrancePaperTips,
                                mh.wRoomServiceDesc,
                                mh.wHotelDesktopDesc,
                                mh.wNeedPassengerName,
                                mh.wNeedPassengerID,
                                mh.wNeedPassengerBirthday,
                                mh.wNeedUploadID,
                                mh.wUploadIDType,
                                mh.wStatus ,
                                mh.wCrtDt ,
                                mh.wCrtBy ,
                                mh.wUpdDt ,
                                mh.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                CASE WHEN eah.wHotelRid = mh.RowID THEN 1
                                     ELSE 0
                                END AS wIsAgentHotel ,
                                CAST(0 AS BIT) AS wIsSelected ,
                                CAST(1 AS BIT) AS wIsAllowedForDelete ,
                                0 AS wPriority
                       FROM     dbo.mHotel mh
                       LEFT JOIN dbo.eAllotmentHotel eah ON eah.wHotelRid = mh.RowID
                       LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mh.wUpdBy
                       LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mh.wCrtBy
                       WHERE    ( @pName = ''
                                  OR mh.wName LIKE '%' + @pName + '%'
                                  OR mh.wJname LIKE '%' + @pName + '%'
                                  OR mh.wThname LIKE '%' + @pName + '%'
                                  OR mh.wKname LIKE '%' + @pName + '%'
                                )
                                AND ( @pEName = ''
                                      OR mh.wEname LIKE '%' + @pEName + '%'
                                    )
                                AND ( @pRegion = ''
                                      OR @pRegion = mh.wRegion
                                    )
                                AND ( @pDistrictCd = ''
                                      OR @pDistrictCd = mh.wDistrictCd
                                    )
                                AND ( @pIsBase = ' '
                                      OR @pIsBase = mh.wIsBase
                                    )
                                AND ( @pCode = ''
                                      OR @pCode = mh.wCode
                                    )
                                AND ( @pStatus = ' '
                                      OR @pStatus = mh.wStatus
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
            ORDER BY CASE WHEN CHARINDEX('||', @pSort) = 1 THEN tResult.wCrtDt END DESC
            --OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
            --FETCH NEXT @pPageSize ROWS ONLY;
    END;