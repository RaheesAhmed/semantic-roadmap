CREATE PROCEDURE [spq].[GetPersonTravelDoc]
    (
      @pwCName NVARCHAR(50) ,
      @pwIDType NVARCHAR(30) ,
      @pwIDNo NVARCHAR(30) ,
      @pwStatus CHAR ,
      @pwLangCd VARCHAR(10) = 'en-GB' ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
        IF ( @pwLangCd = ''
             OR @pwLangCd IS NULL
           )
            SET @pwLangCd = 'en-GB';
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY mpt.RowID ) AS wSeqNo ,
                                mpt.RowID ,
                                mpt.wPersonRID ,
                                mpt.wRefRID ,
                                edoc.wFileData ,
                                edoc.wDocExt ,
                                edoc.wFileDataStreamID ,
                                mp.wAgentCodeIn ,
                                mp.wCName ,
                                mp.wEName ,
                                mpt.wEnglishPinyin ,
                                mpt.wIDType ,
                                mpt.wIDNo ,
                                mpt.wIssueAt ,
                                mpt.wExpiryDate ,
                                mpt.wRemark ,
                                mpt.wStatus ,
                                mpt.wCrtDt ,
                                mpt.wCrtBy ,
                                mpt.wUpdDt ,
                                mpt.wUpdBy ,
                                mdoc.wTitle AS wDocumentName ,
                                doc.wTitle AS wIssueName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     [CRM].[dbo].mPersonTravelDoc mpt
                                INNER JOIN dbo.mPerson mp ON mp.RowID = mpt.wPersonRID                                                             
                                INNER JOIN dbo.mLookUp mdoc ON mdoc.wCode = mpt.wIDType
                                                              AND mdoc.wType = 'ID_TYPE'
                                                              AND mdoc.wLangCd = @pwLangCd
                                LEFT JOIN dbo.mLookUp doc ON doc.wCode = mpt.wIssueAt
                                                             AND doc.wType = 'ID_ISSUE_PLACE'
                                                             AND doc.wLangCd = @pwLangCd
                                LEFT JOIN [CRM_Doc].[dbo].eDocument edoc ON edoc.RowID = mpt.wRefRID
                                                              AND edoc.wStatus = 'A'
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mpt.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mpt.wCrtBy
                       WHERE    ( @pwCName = ''
                                  OR @pwCName IS NULL
                                  OR @pwCName = mp.RowID
                                )
                                AND ( @pwIDType = ''
                                      OR @pwIDType IS NULL
                                      OR @pwIDType = mpt.wIDType
                                    )
                                AND ( @pwIDNo = ''
                                      OR @pwIDNo IS NULL
                                      OR @pwIDNo = mpt.wIDNo
                                    )
                                AND ( @pwStatus = '\0'
                                      OR @pwStatus = ''
                                      OR @pwStatus IS NULL
                                      OR @pwStatus = mpt.wStatus
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