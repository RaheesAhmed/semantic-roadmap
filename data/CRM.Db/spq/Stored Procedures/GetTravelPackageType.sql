CREATE PROCEDURE [spq].[GetTravelPackageType]
    (
	  @pCode NVARCHAR(30) ,
      @pName NVARCHAR(50) ,
      @pStatus CHAR(1) ,
      @pLangCd VARCHAR(10),
      @pPageSize INT ,
      @pPageNum INT
    )
AS
BEGIN  
	SET NOCOUNT ON; 

    SET @pCode = ISNULL(@pCode, '');
    SET @pName = ISNULL(@pName, '');
    SET @pStatus = ISNULL(@pStatus, ' ');
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
			WHERE (@pCode = ''
				 OR @pCode = mec.wCode
			)
			AND (@pName = ''
				OR mec.wName LIKE '%' + @pName + '%'
			)
			AND (@pStatus = ' '
				OR @pStatus = mec.wStatus
			)
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