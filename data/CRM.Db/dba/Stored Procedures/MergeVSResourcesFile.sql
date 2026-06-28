-------------------------
-- Merge VS Resx files
-- remove header of resx, provide simple xml to the parameter
-- duplicated item will be filtered by union operation
-- but is the value are not the same, need to solve manually 
-------------------------

CREATE PROCEDURE [dba].[MergeVSResourcesFile] (
	@pXMLMain XML = N'',
	@pXMLSlave XML = N''
) AS

BEGIN
	SET NOCOUNT ON;

	SELECT 
		t.x.value('@name','NVARCHAR(MAX)') as [Name],
		t.x.value('value[1]','NVARCHAR(MAX)') as [Value]
	FROM 
		@pXMLMain.nodes('/root/data') t(x)
	UNION
	SELECT 
		t.x.value('@name','NVARCHAR(MAX)') as [Name],
		t.x.value('value[1]','NVARCHAR(MAX)') as [Value]
	FROM 
		@pXMLSlave.nodes('/root/data') t(x)
	ORDER BY 
		1;
END