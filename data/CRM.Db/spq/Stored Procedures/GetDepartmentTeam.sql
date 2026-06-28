CREATE PROCEDURE [spq].[GetDepartmentTeam]
    (
      @pwCode  NVARCHAR (10),
      @pwName  NVARCHAR (20),
      @pwDepartment  NVARCHAR (10),
	  @pwRegion  NVARCHAR (20),
	  @pwStatus  NVARCHAR (20),
	  @pPageSize INT = 999,
	  @pPageNum INT = 1
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	 WITH tResult AS (
       SELECT  
	   dt.RowID,
	   dt.wCode,
	   dt.wName,
	   dt.wDepartment,
	   dt.wRegion,
	   dt.wStatus,
	   dt.wSeqNo,
	   dt.wCrtBy,
	   dt.wCrtDt,
	   dt.wUpdBy,
	   dt.wUpdDt 
	   
        FROM    dbo.mDepartmentTeam dt                
	   WHERE   
		( @pwCode = '' OR @pwCode IS NULL OR @pwCode =dt.wCode) AND
		( @pwName = '' OR @pwName IS NULL OR @pwName =dt.wName) AND
		( @pwDepartment = '' OR @pwDepartment IS NULL OR @pwDepartment =dt.wDepartment) AND
		( @pwRegion = '' OR @pwRegion IS NULL OR @pwRegion =dt.wRegion) AND
		( @pwStatus = '' OR @pwStatus IS NULL OR @pwStatus =dt.wStatus)
		
		),tCount AS (
		SELECT wRecordCount = COUNT(*) FROM tResult
	)
	SELECT tResult.*, wRecordCount
		FROM tResult,tCount
		  ORDER BY wUpdDt Desc
		  OFFSET @pPageSize * (@pPageNum - 1) ROWS
		  FETCH NEXT @pPageSize ROWS ONLY;

    END;