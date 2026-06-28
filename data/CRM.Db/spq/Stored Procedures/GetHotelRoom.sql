CREATE PROCEDURE [spq].[GetHotelRoom]
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
                  AS ( SELECT   mhr.RowID ,
                                mh.wName wHotelName ,
                                mhr.wHotelRid ,
                                mhr.wCode ,
                                mhr.wName ,
                                mhr.wEname ,
                                mhr.wJname ,
                                mhr.wThname ,
                                mhr.wKname ,
                                mhr.wRemarks ,
                                mhr.wSeqNo		
		--,lups.wTitle wStatus
                                ,
                                mhr.wStatus ,
                                mhr.wCrtDt ,
                                mhr.wCrtBy ,
                                mhr.wUpdDt ,
                                mhr.wUpdBy ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                CASE WHEN @pwLangCd = 'en-GB'
                                     THEN ( CASE WHEN LEN(mhr.wEname) > 0
                                                 THEN mhr.wEname
                                                 ELSE mhr.wName
                                            END )
                                     WHEN @pwLangCd = 'ja-JP'
                                     THEN ( CASE WHEN LEN(mhr.wJname) > 0
                                                 THEN mhr.wJname
                                                 ELSE mhr.wName
                                            END )
                                     WHEN @pwLangCd = 'ko-KR'
                                     THEN ( CASE WHEN LEN(mhr.wKname) > 0
                                                 THEN mhr.wKname
                                                 ELSE mhr.wName
                                            END )
                                     WHEN @pwLangCd = 'th-TH'
                                     THEN ( CASE WHEN LEN(mhr.wThname) > 0
                                                 THEN mhr.wThname
                                                 ELSE mhr.wName
                                            END )
                                     ELSE mhr.wName
                                END AS wDisplayName
                       FROM     dbo.mHotelRoom mhr
                                INNER JOIN mHotel mh ON mh.RowID = mhr.wHotelRid
                                                        AND mhr.wStatus = 'A'
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mhr.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mhr.wCrtBy
                       WHERE    ( @pwStatus = ''
                                  OR @pwStatus = ' '
                                  OR @pwStatus IS NULL
                                  OR @pwStatus = mhr.wStatus
                                )
		--AND	
		--( @pwLangCd = '' 
		--	OR  @pwLangCd IS NULL
		--	OR   @pwLangCd = mh.wLangCd
		--)	
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;

    END;