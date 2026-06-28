CREATE PROCEDURE [spq].[GetSpaList] @pStatus VARCHAR(1) = ''
AS
    BEGIN  

        SELECT DISTINCT
                MS.RowID ,
                MS.wName,
                MS.wStatus
        FROM    dbo.mSpa MS
        WHERE   ( @pStatus = ''
                  OR @pStatus IS NULL
                  OR @pStatus = MS.wStatus
                );    
   
  
    END;