CREATE PROCEDURE [spq].[GetTaskSheetLst_Base_Marketing]
    (
      @pCompNo INT ,
      @pRelatedType VARCHAR(30) ,
      @pRelatedRid BIGINT ,
      @pStatus CHAR(1) ,
      @pLangCd VARCHAR(30) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
    
        WITH    cteData
                  AS ( SELECT   ts.RowID ,
                                ts.wCompNo ,
								ts.wCounterRid ,
								sc.wName AS wServiceCounterName ,
                                ts.wDeptCd ,
								ts.wUsrRid ,
								CASE WHEN @pLangCd = 'en-GB' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wStaffName ,
                                ts.wDate ,
                                ts.wTaskType ,
                                ts.wSubTaskType ,
                                ts.wIsInhouse ,
                                ts.wContent ,
                                ts.wRemark ,
                                ts.wRelateAgentCodeIn ,
                                ts.wRelatedType ,
                                ts.wRelatedRid ,
                                ts.wHasDoc ,
                                ts.wStatus ,
                                ts.wCrtDt ,
                                ts.wCrtBy ,
                                ts.wUpdDt ,
                                ts.wUpdBy ,
                                ts.wFollowUpDt ,
                                ts.wFollowUpBy ,
                                wTaskTypeTitle = tst.wTitle ,
                                wSubTaskTypeTitle = tstSub.wTitle ,
                                wDepartment = d.wTitle ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u.wName
                                     ELSE u.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-GB' THEN cu.wName
                                     ELSE cu.wCName
                                END AS wCreatedByCName
                       FROM     dbo.eTaskSheet ts
								LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = ts.wCounterRid
                                LEFT JOIN [RollsMary].[dbo].[mUsr] u ON u.RowID = ts.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] cu ON cu.RowID = ts.wCrtBy
                                LEFT JOIN dbo.mLookUp d ON ts.wDeptCd = d.wCode
                                                           AND d.wLangCd = @pLangCd
                                                           AND d.wType = 'DEPARTMENT'
                                LEFT JOIN dbo.mTaskSheetType tst ON ts.wTaskType = tst.wCode
                                                              AND ts.wDeptCd = tst.wDepartmentCode
                                LEFT JOIN dbo.mTaskSheetType tstSub ON ts.wSubTaskType = tstSub.wCode
                                                              AND tstSub.wParentCode = ts.wTaskType
                                                              AND ts.wDeptCd = tst.wDepartmentCode
								LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ts.wUsrRid
                       WHERE    ( @pCompNo = 0
                                  OR ts.wCompNo = @pCompNo
                                )
                                AND ( @pRelatedType = ''
                                      OR ts.wRelatedType = @pRelatedType
                                    )
                                AND ( @pRelatedRid = 0
                                      OR ts.wRelatedRid = @pRelatedRid
                                    )
                                AND ( @pStatus = ' '
                                      OR ts.wStatus = @pStatus
                                    )
                     ),
                cteCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     cteData
                     )
            SELECT  d.* ,
                    c.wRecordCount
            FROM    cteData d ,
                    cteCount c
            ORDER BY wCrtDt Desc
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
		
    END;