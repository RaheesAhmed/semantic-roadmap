CREATE PROCEDURE [spq].[GetServiceCounter]
    (
      @pDefaultHotelCode NVARCHAR(20) ,
      @pRegion NVARCHAR(20) ,
      @pName NVARCHAR(20) ,
      @pStatus CHAR ,
      @pLangCd VARCHAR(10) = 'en-gb' ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   msv.RowID ,
                                msv.wCode ,
                                msv.wName ,
                                msv.wSmsRoomID ,
                                msv.wRollexCompNo ,
                                c.wCName wRollexCompName ,
                                msv.wRegion ,
                                lregion.wTitle AS RegionTitle ,
                                msv.wDefaultHotelCode ,
                                msv.wCollectionPointCd ,
                                msv.wCurrCode ,
                                msv.wRemark ,
                                msv.wStatus ,
                                msv.wSeqNo ,
                                msv.wStoreAgentCodeIn ,
                                stAgent.wAgentCode_Display AS wStoreAgentCodeIn_Display ,
                                msv.wHandlingFee ,
                                msv.wCrtDt ,
                                msv.wCrtBy ,
                                msv.wUpdDt ,
                                msv.wUpdBy ,
                                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END,
                                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END,
                                msv.wAddress ,
                                msv.wSMSName ,
                                msv.wTransferSMSName
                       FROM     [CRM].[dbo].mServiceCounter msv
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = msv.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = msv.wCrtBy
                                LEFT JOIN mLookUp lregion ON lregion.wType = 'REGION'
                                                             AND lregion.wCode = msv.wRegion
                                                             AND lregion.wLangCd = @pLangCd
                                LEFT JOIN [RollsMary].[dbo].mCompany c ON c.wCompNo = msv.wRollexCompNo
						  LEFT JOIN [RollsMary].[dbo].[mAgent] stAgent ON stAgent.wAgentCodeIn = msv.wStoreAgentCodeIn
                       WHERE    ( @pDefaultHotelCode = ''
                                  OR @pDefaultHotelCode IS NULL
                                  OR @pDefaultHotelCode = msv.wDefaultHotelCode
                                )
                                AND ( @pRegion = ''
                                      OR @pRegion IS NULL
                                      OR @pRegion = msv.wRegion
                                    )
                                AND ( @pName = ''
                                      OR @pName IS NULL
                                      OR @pName = msv.wName
                                    )
                                AND ( @pStatus = ''
                                      OR @pStatus IS NULL
                                      OR @pStatus = msv.wStatus
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
            ORDER BY wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		   FETCH NEXT @pPageSize ROWS ONLY;
    END;