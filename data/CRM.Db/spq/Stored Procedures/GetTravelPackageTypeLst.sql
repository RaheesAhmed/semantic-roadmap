CREATE PROCEDURE [spq].[GetTravelPackageTypeLst]
    (
	  @pStatus CHAR(1),
      @pLangCd VARCHAR(10),
      @pPageSize INT ,
      @pPageNum INT
    )
AS
BEGIN  
	SET NOCOUNT ON; 

    SET @pLangCd = ISNULL(@pLangCd, 'en-gb');
    SET @pPageSize = ISNULL(@pPageSize, 9999);
    SET @pPageNum = ISNULL(@pPageNum, 1);

    WITH tResult AS (
		SELECT
			mec.RowID ,
			mec.wCode ,
			mec.wName ,
			mec.wValidDate ,
			mec.wStatus ,
			mec.wCrtDt ,
			mec.wUpdDt ,
			mec.wCrtBy ,
			mec.wUpdBy ,
			wUpdByCName=CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
			wCreatedByCName=CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END
			FROM dbo.mTravelPackageType AS mec
			LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = mec.wUpdBy
			LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = mec.wCrtBy
			WHERE NULLIF(@pStatus, '') IS NULL 
            OR (mec.wStatus = @pStatus
			   AND (mec.wValidDate>=convert(varchar(10),getdate(),120) OR NULLIF(wValidDate, '0001-01-01 00:00:00.0000000') IS NULL)) -- Usr不填有效時間時為默認時間，也要返回記錄
		),
		tCount AS (
			SELECT wRecordCount = COUNT(*)
			FROM tResult
		)

        SELECT
			tr.* ,
			tc.wRecordCount
        FROM tResult AS tr, tCount AS tc
        ORDER BY tr.wCrtDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
		FETCH NEXT @pPageSize ROWS ONLY;
END