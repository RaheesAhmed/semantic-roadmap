CREATE PROCEDURE [spq].[GetPersonAuthByAgentCodeIn]
    (
      /*
		這個sp主要是用於根據戶口搜索客人,參考sp:GetPersonAuth
	*/@pAgentCodeIn VARCHAR(14) ,
      @pCName NVARCHAR(50) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN    
	-- SET NOCOUNT ON added to prevent extra result sets from    
	-- interfering with SELECT statements.    
        SET NOCOUNT ON;
	 
	-- Insert statements for procedure here
        WITH    tTmp
                  AS ( SELECT   mp.RowID ,
                                mp.wRefRID ,
                                ( CASE WHEN mp.wRefRID IS NULL THEN 'N'
                                       ELSE 'Y'
                                  END ) AS wIsAuth ,
                                ( CASE WHEN mp.wRefRID IS NULL
                                       THEN mp.wAgentCodeIn
                                       ELSE auth.wUpLvlAgentCodeIn
                                  END ) AS wAgentCodeIn ,
                                ( CASE WHEN mp.wRefRID IS NULL THEN mp.wCName
                                       ELSE auth.wCName
                                  END ) AS wCName ,
                                mp.wUpdDt
                       FROM     [dbo].mPerson mp --left join dbo.mPersonTravelDoc mpt on mpt.wPersonRID = mp.RowID
                                LEFT JOIN [RollsMary].[dbo].[mAgent] auth ON auth.RowID = mp.wRefRID
                                                              AND auth.wType = 'AUTH'
                                                              AND auth.wAuthIdentity IN (
                                                              'AUTH'/*授權人*/,
                                                              'BOSS'/*幕後老闆*/,
                                                              'OWNER'/*戶主*/,
                                                              'DIRECTOR'/*總監*/,
                                                              'STAFF'/*伙記*/,
                                                              'PARTNER' /*拍檔*/
				)
                                                              AND mp.wStatus = 'A'
                       UNION ALL
                       SELECT   -1 AS RowID ,
                                auth1.RowID AS wRefRID ,
                                'Y' AS wIsAuth ,
                                auth1.wUpLvlAgentCodeIn AS wAgentCodeIn ,
                                auth1.wCName AS wCName ,
                                auth1.wUpdDt AS wUpdDt
                       FROM     [RollsMary].[dbo].[mAgent] auth1
                                LEFT JOIN [dbo].mPerson mp1 ON auth1.RowID = mp1.wRefRID
                       WHERE    auth1.wType = 'AUTH'
                                AND auth1.wAuthIdentity IN ( 'AUTH'/*授權人*/,
                                                             'BOSS'/*幕後老闆*/,
                                                             'OWNER'/*戶主*/,
                                                             'DIRECTOR'/*總監*/,
                                                             'STAFF'/*伙記*/,
                                                             'PARTNER' /*拍檔*/
			)
                                AND mp1.RowID IS NULL
                                AND mp1.wStatus = 'A'
                     ),
                tResult
                  AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY mp.RowID, mp.wAgentCodeIn, mp.wUpdDt ) AS wSeqNo ,
                                mp.RowID ,
                                mp.wRefRID ,
                                mp.wIsAuth ,
                                mp.wAgentCodeIn ,
                                mp.wCName ,
                                mp.wUpdDt
                       FROM     tTmp mp
                       WHERE    ( ISNULL(@pAgentCodeIn, '') = ''
                                  OR @pAgentCodeIn = mp.wAgentCodeIn
                                )
                                AND ( ISNULL(@pCName, '') = ''
                                      OR @pCName = mp.wCName
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
            ORDER BY wSeqNo DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		FETCH NEXT @pPageSize ROWS ONLY;    
    END;
