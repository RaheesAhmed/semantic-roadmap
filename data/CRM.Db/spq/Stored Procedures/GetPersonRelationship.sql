CREATE PROCEDURE [spq].[GetPersonRelationship]
    (
      @pRelationType VARCHAR(30) ,
      @pPersonId BIGINT ,
      @pLangCd VARCHAR(10) = 'en-GB' ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1	  
    )
AS
    BEGIN 
-- SET NOCOUNT ON added to prevent extra result sets from 
-- interfering with SELECT statements. 
        SET NOCOUNT ON; 
	 
-- Insert statements for procedure here 
    ;
        WITH    tResult
                  AS ( SELECT   mpr.RowID ,
                                mpr.wPersonRid ,
                                mp.wCName AS wPersonCName ,
                                mp.wEName AS wPersonEName ,
                                mpr.wRelatePersonRid ,
                                CAST(( CASE WHEN rp.wRefRID > 0 THEN ma.wCName
                                            ELSE rp.wCName
                                       END ) AS NVARCHAR(50)) AS wRelatedPersonCName ,
                                CAST(( CASE WHEN rp.wRefRID > 0 THEN ma.wEName
                                            ELSE rp.wEName
                                       END ) AS VARCHAR(500)) AS wRelatedPersonEName ,
                                mpr.wRelationType ,
                                mrs.wTitle AS wRelationTypeName ,
                                mpr.wRemark ,
                                mpr.wSeqNo ,
                                mpr.wCrtDt ,
                                mpr.wCrtBy ,
                                mpr.wUpdDt ,
                                mpr.wUpdBy ,
								mpr.wStatus,
                                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                rp.wRefRID ,
                                ( CASE WHEN rp.wRefRID > 0
                                       THEN ma.wUpLvlAgentCodeIn
                                       ELSE rp.wAgentCodeIn
                                  END ) AS wAgentCodeIn
                       FROM     [CRM].[dbo].mPersonRelationship mpr
                                INNER JOIN mPerson mp ON mp.RowID = mpr.wPersonRid
                                INNER JOIN mPerson rp ON rp.RowID = mpr.wRelatePersonRid
                                INNER JOIN mLookUp mrs ON mrs.wCode = mpr.wRelationType
                                                          AND mrs.wType = 'RELATIONSHIP'
                                                          AND mrs.wLangCd = @pLangCd
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mp.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mp.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mAgent] ma ON ma.RowID = rp.wRefRID
                       WHERE    ( ISNULL(@pRelationType, '') = ''
                                  OR @pRelationType = mpr.wRelationType
                                )
                                AND ( ISNULL(@pPersonId, '') = ''
                                      OR @pPersonId = 0
                                      OR @pPersonId = mpr.wPersonRid
                                      OR @pPersonId = mpr.wRelatePersonRid
                                    )
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(1)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS 
			FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;