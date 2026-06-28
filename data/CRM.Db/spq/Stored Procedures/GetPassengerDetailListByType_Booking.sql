
CREATE PROCEDURE [spq].[GetPassengerDetailListByType_Booking]
    (
      @pwType VARCHAR(10) ,
      @pwStatus VARCHAR(10) ,
      @pwLangCd VARCHAR(10) = 'en-gb' ,
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
                  AS ( SELECT   pd.wChangeOrderCount ,
                                pd.wType ,
                                pd.wSeqNo AS wPassengerSeqNo ,
                                pd.RowID ,
                                pd.wBookingRid ,
                                eb.wRefNo + '-' + RIGHT('000' + CAST(( pd.wSeqNo ) AS VARCHAR(3)),3) AS wBookingRefNo ,
                                eb.wRefNo ,
                                eb.wApprovalAgentCodeIn ,
                                eb.wReqCustomerRid ,
                                CAST(( pd.wRequesterAcc ) AS VARCHAR(15)) AS wDebitAgentCodeIn ,
                                pd.wRouteRid ,
                                pd.wTakeOffDt ,
                                r.wRouteFrom + ' to ' + r.wRouteTo wRoute ,
                                pd.wPassengerBookingStatus wStatusCode ,
                                pd.wApplicationType ,
                                pd.wApplicationStatus ,
                                pd.wAmount ,
                                pd.wCost ,
                                pd.wPersonRid ,
                                pd.wRemark ,
                                pd.wCancelDt ,
                                pd.wCancelDebitDt ,
                                pd.wCancelReasonCd ,
                                pd.wOtherReason ,
                                accAgent.wAgentCode_Display ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN accAgent.wEName ELSE accAgent.wCName END AS wAccount ,
                                p.wCName wClient ,
                                p.wGender ,
                                p.wAgentCodeIn ,
                                luppr.wTitle wClientIdCode ,
                                pd.wPersonRid AS wPersonId ,
                                [dbo].[fnGetDocDetailsByPassengerDetailRid](pd.RowID, 'ID_TYPE', @pwLangCd) wPersonTravelDocType ,
                                [dbo].[fnGetDocDetailsByPassengerDetailRid](pd.RowID, 'ID_NO', @pwLangCd) wPersonTravelDocNo ,
                                --luphts.wTitle wStatus ,
								pd.wStatus,
                                pd.wCrtDt ,
                                pd.wCrtBy ,
                                pd.wUpdDt ,
                                pd.wUpdBy ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END AS wCreatedByCName
                       FROM     [dbo].ePassengerDetails pd
                                INNER JOIN dbo.mPerson p ON p.RowID = pd.wPersonRid
                                                            --AND pd.wStatus = 'A' --刪除后應仍可見
                                INNER JOIN [RollsMary].[dbo].[mAgent] accAgent ON accAgent.wAgentCodeIn = p.wAgentCodeIn
                                INNER JOIN dbo.eBooking eb ON eb.RowID = pd.wBookingRid
                                LEFT JOIN dbo.eBookingPrivatePlane ebpp ON pd.wBookingRid = ebpp.wBookingRid
                                LEFT JOIN dbo.eBookingHeli bh ON bh.wBookingRid = pd.wBookingRid
                                LEFT JOIN dbo.mRoute r ON r.RowID = pd.wRouteRid
                                LEFT JOIN dbo.mLookUp luppr ON luppr.wCode = p.wRole
                                                              AND luppr.wType = 'PERSON_ROLE'
                                                              AND luppr.wLangCd = @pwLangCd
                                --LEFT JOIN dbo.mLookUp luphts ON luphts.wCode = pd.wPassengerBookingStatus
                                --                              AND luphts.wType = 'COMMON_STATUS'
                                --                              AND luphts.wLangCd = @pwLangCd
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = pd.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = pd.wCrtBy
                       WHERE    pd.wType = @pwType
                                AND pd.wType != ''
                                AND ( @pwStatus = ''
                                      OR @pwStatus IS NULL
                                      OR @pwStatus = pd.wPassengerBookingStatus
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