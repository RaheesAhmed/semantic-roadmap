
CREATE PROCEDURE [spq].[GetPersonTravelDocList] (
      @pPersonRid BIGINT = -1 ,
      @pPassengerRid BIGINT = -1,
      @pStatus CHAR = '' ,
      @pLangCd VARCHAR(10) = 'en-GB'
)
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

		IF @@TRANCOUNT = 0
			SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

		DECLARE @vNow	DATETIME2 = dbo.fnUTC8Now();
	  
      SET @pStatus = NULLIF(@pStatus, '');
      SET @pPersonRid = IIF(@pPersonRid <= 0, NULL, @pPersonRid);
      SET @pPassengerRid = IIF(@pPassengerRid <= 0, NULL, @pPassengerRid);

	  WITH cteIsSelected AS (
		SELECT wPersonTravelDocRid
		FROM dbo.ePassengerTravelDocDetail
		WHERE wPassengerDetailsRid = @pPassengerRid
		GROUP BY wPersonTravelDocRid
	  )

		SELECT 
            mpt.RowID ,
            mpt.wPersonRID ,
            mpt.wRefRID ,
            edoc.wFileData , -- 此列影響性能（文件）
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
            edoc.wDocExt AS wDocExtension ,
            edoc.wType AS wDocType ,
            edoc.wDocName ,
            edoc.wCategory AS wDocCategory ,
            edoc.wDesc ,
            --edoc.wFileData ,--重複查找了
            --edoc.wFileDataStreamID ,--重複查找了
            edoc.RowID AS wDocRid ,
            edoc.wRefTable ,
            wIsValidDateLessThanSixMonth = CASE WHEN DATEDIFF(MONTH, @vNow, ISNULL(mpt.wExpiryDate, @vNow)) < 6 THEN 'Y' ELSE 'N' END, -- Not sure why hard code N, check later
            IsSelected = CASE WHEN s.wPersonTravelDocRid IS NOT NULL THEN 'Y' ELSE 'N' END,
            wUpdByName = CASE WHEN @pLangCd = 'en-GB' THEN usr.wName ELSE usr.wCName END,
            wCreatedByName = CASE WHEN @pLangCd = 'en-GB' THEN crusr.wName ELSE crusr.wCName END
        FROM [dbo].mPersonTravelDoc mpt
		INNER JOIN dbo.mPerson mp ON mp.RowID = mpt.wPersonRID
		LEFT JOIN cteIsSelected s ON s.wPersonTravelDocRid = mpt.RowID
		LEFT JOIN [CRM_Doc].[dbo].eDocument edoc ON edoc.wRefRID = mpt.RowID AND edoc.wStatus='A'
		LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mpt.wUpdBy
		LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mpt.wCrtBy
        WHERE (@pStatus IS NULL OR @pStatus = mpt.wStatus) AND (@pPersonRid IS NULL OR @pPersonRid = mp.RowID)
        ORDER BY mpt.wUpdDt DESC
		OPTION (RECOMPILE);
    END;