CREATE PROCEDURE [spq].[GetPersonPreference]
    (
      @pPerferenceSubType VARCHAR(30) ,
      @pPerferenceType VARCHAR(30) ,
      @pPersonId BIGINT ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10) = 'en-GB'	
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   mpp.RowID ,
                                mpp.wPersonRid ,
                                mp.wCName AS wPersonCName ,
                                mp.wEName AS wPersonEName ,
                                mpp.wPerferenceType ,
                                mpt.wName AS wPerferenceTypeName ,
                                mpp.wPerferenceSubType ,
                                mpst.wName AS wPerferenceSubTypeName ,
                                mpp.wRemark ,
                                mpp.wSeqNo ,
                                mpp.wCrtDt ,
                                mpp.wCrtBy ,
                                mpp.wUpdDt ,
                                mpp.wUpdBy ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     [CRM].[dbo].mPersonPerference mpp
                                INNER JOIN mPerson mp ON mp.RowID = mpp.wPersonRid
                                INNER JOIN mPreferenceType mpt ON mpt.RowID = mpp.wPerferenceType
                                INNER JOIN mPreferenceSubtype mpst ON mpst.RowID = mpp.wPerferenceSubType
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mpp.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mpp.wCrtBy
                       WHERE    ( @pPerferenceType = ''
                                  OR @pPerferenceType IS NULL
                                  OR @pPerferenceType = mpp.wPerferenceType
                                )
                                AND ( @pPerferenceSubType = ''
                                      OR @pPerferenceSubType IS NULL
                                      OR @pPerferenceSubType = mpp.wPerferenceSubType
                                    )
                                AND ( @pPersonId = ''
                                      OR @pPersonId IS NULL
                                      OR @pPersonId = 0
                                      OR @pPersonId = mpp.wPersonRid
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
            ORDER BY wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;
    END;