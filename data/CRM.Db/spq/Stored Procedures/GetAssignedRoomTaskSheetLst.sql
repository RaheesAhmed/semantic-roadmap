CREATE PROCEDURE [spq].[GetAssignedRoomTaskSheetLst]
(
    @pCompNo INT ,
	@pHotelRequestRid BIGINT ,
    @pRelatedType VARCHAR(30) ,
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
    
        WITH    
			tHotelRequestDtlRid AS (
				SELECT RowID, wHotelCode FROM dbo.eHotelRequestDtl WHERE wHotelRequestRid = @pHotelRequestRid
			),
			tAssignedRoomTaskSheet AS (
				SELECT * FROM dbo.eTaskSheet WHERE wRelatedType = @pRelatedType
			),
			tResult AS ( 
				SELECT  ts.RowID ,
						ts.wCompNo ,
						ts.wCounterRid ,
						sc.wName AS wServiceCounterName ,
						ts.wDeptCd ,
						ts.wUsrRid ,
						CASE WHEN @pLangCd = 'en-GB' THEN usr.wName ELSE usr.wCName END AS wStaffName ,
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
						ts.wTaskSheetStatus ,
						ht.RowID AS wHotelRid,
						CASE WHEN @pLangCd = 'en-GB' THEN ht.wEname ELSE ht.wName END As wHotelName,
						wTaskTypeTitle = tst.wTitle ,
						wSubTaskTypeTitle = tstSub.wTitle ,
						wDepartment = d.wTitle ,
						CASE WHEN @pLangCd = 'en-GB' THEN u.wName ELSE u.wCName END AS wUpdByCName ,
						CASE WHEN @pLangCd = 'en-GB' THEN cu.wName ELSE cu.wCName END AS wCreatedByCName,
						a_r.wAgentCode_Display AS wRelateAgentCode_Display ,
						CASE WHEN @pLangCd = 'en-gb' THEN a_r.wEName ELSE a_r.wCName END AS wRelateAgentName 
				FROM    tAssignedRoomTaskSheet ts
				INNER JOIN tHotelRequestDtlRid hrd ON hrd.RowID = ts.wRelatedRid
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
												AND ts.wDeptCd = tstSub.wDepartmentCode
				LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ts.wUsrRid
				LEFT JOIN RollsMary.dbo.mAgent a_r ON a_r.wAgentCodeIn = ts.wRelateAgentCodeIn
				LEFT JOIN dbo.mHotel ht ON ht.wCode = hrd.wHotelCode
				WHERE   ( @pCompNo = 0 OR ts.wCompNo = @pCompNo )
						AND ( @pStatus = ' ' OR ts.wStatus = @pStatus)
				),

				tCount AS ( 
					SELECT
						 COUNT(*) AS wRecordCount
					FROM tResult)

				SELECT  tResult.*, tCount.wRecordCount
				FROM    tResult, tCount
				ORDER BY wUpdDt Desc OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
				FETCH NEXT @pPageSize ROWS ONLY
				OPTION  ( RECOMPILE );
    END;