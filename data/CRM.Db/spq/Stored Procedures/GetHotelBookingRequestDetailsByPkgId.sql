CREATE PROCEDURE [spq].[GetHotelBookingRequestDetailsByPkgId]
    (
      @pwCounterRid BIGINT = 0 ,
      @pwPackageId BIGINT ,
      @pwTravelPackageStatus VARCHAR(3) ,
      @pwHotelStatus VARCHAR(20) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10) = 'en-GB'	
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
        DECLARE @pwTempStatus VARCHAR(20);
        IF @pwHotelStatus = 'MR'
            OR @pwHotelStatus = 'MA'
            BEGIN
                SET @pwTempStatus = @pwHotelStatus;
                SET @pwHotelStatus = NULL;
            END;
	
        DECLARE @vCompNo AS INT ,
            @vYearMth AS VARCHAR(6);
        SELECT  @vCompNo = wRollexCompNo
        FROM    CRM.dbo.mServiceCounter
        WHERE   RowID = @pwCounterRid;
        SELECT  @vYearMth = CONCAT(wYear, wMonth)
        FROM    RollsMary.dbo.mSettlePeriod
        WHERE   wCompNo = @vCompNo
                AND RollsMary.dbo.fnUTC8Now() BETWEEN wStartDateTime
                                              AND     wEndDateTime

    -- Insert statements for procedure here
	;
        WITH    cteRollingAmt
                  AS ( SELECT   wAgentCodeIn ,
                                wGroupRollingHKD = SUM(wRollingHKD - wRollingInstantSettledHKD) ,
                                wCompRollingHKD = SUM(CASE WHEN wCompNo = @vCompNo THEN wRollingHKD - wRollingInstantSettledHKD
                                                           ELSE 0
                                                      END)
                       FROM     RollsMary.dbo.mAgentBalRollingMth
                       WHERE    wYearMth = @vYearMth
                       GROUP BY wAgentCodeIn
                     ),
                tResult
                  AS ( SELECT DISTINCT
                                0 AS wSeqNo ,
                                ebh.RowID AS wBookingRowID ,
                                ehr.RowID ,
                                0 AS wRequestRID ,
                                eb.wRefNo ,
                                ehr.wTravePkgRid ,
                                ehr.wRequestNo ,
                                ehr.wReqUserRid ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN rq.wEName
                                     ELSE rq.wCName
                                END AS wDebitClientName ,--AS wRequestClient,
                                lr.wTitle wRegion ,
                                wGroupRollingHKD = ISNULL(r.wGroupRollingHKD, 0) ,
                                wCompRollingHKD = ISNULL(r.wCompRollingHKD, 0) ,
                                ehr.wReqAgentCodeIn ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN agnt.wEName
                                     ELSE agnt.wCName
                                END AS wDebitAccountName ,--AS wRequestAccount,
                                ehr.wNumberOfRoom ,
                                ehr.wDayOfStay ,
                                ehr.wStartDate ,
                                ehr.wDebitAgentCodeIn ,
                                ehr.wReqCustomerRid ,
                                ehr.wDebitCustomerRid ,
                                ehr.wReqCounterRid ,
                                ehr.wApprovalAgentCodeIn ,
                                ehr.wDebitCounterRid ,
                                ehr.wReqDepartment ,
                                ehr.wAsstBooker ,
                                ehr.wAssBookerTel ,
                                ehr.wRegion wRegionCode ,
                                ehr.wBedType wBedCode ,
                                ehr.wHotelCodeSCV ,
                                ehr.wEndDate ,
                                ehr.wAsstBookerEmail ,
                                ehr.wDeptFollwedCd ,
                                ehr.wStaffFollwedRid ,
                                ehr.wStaffTelephone ,
                                ehr.wOwnerAuthTelephone ,
                                ( CASE WHEN ( SELECT    COUNT(splitdata)
                                              FROM      dbo.Split(ehr.wHotelCodeSCV, ',')
                                            ) > 4 THEN ( SELECT STUFF(( SELECT  ', ' + wDistrictCd + ' (' + CAST(COUNT(wCode) AS VARCHAR(5)) + ')'
                                                                        FROM    mHotel
                                                                        WHERE   wCode IN ( SELECT   splitdata
                                                                                           FROM     dbo.Split(ehr.wHotelCodeSCV, ',') )
                                                                        GROUP BY wDistrictCd
                                                                      FOR
                                                                        XML PATH('')
                                                                      ), 1, 1, '')
                                                       )
                                       ELSE ( SELECT    STUFF(( SELECT  ', ' + wName
                                                                FROM    mHotel
                                                                WHERE   wCode IN ( SELECT   splitdata
                                                                                   FROM     dbo.Split(ehr.wHotelCodeSCV, ',') )
                                                              FOR
                                                                XML PATH('')
                                                              ), 1, 1, '')
                                            )
                                  END ) AS wHotelRequest ,
                                ehr.wIsAgentHotel ,
                                lbt.wTitle wBedType ,
                                ehr.wRemark ,
                                lhbs.wTitle wStatus ,
                                ehr.wCrtDt ,
                                ehr.wCrtBy ,
                                ehr.wUpdDt ,
                                ehr.wUpdBy ,
                                CAST(( SELECT   ( ehr.wNumberOfRoom - SUM(wTotalProvideRoomQty) )
                                       FROM     eHotelRequestDtl
                                       WHERE    wHotelRequestRid = ehr.RowID
                                     ) AS VARCHAR(5)) + '/' + CAST(ehr.wNumberOfRoom AS VARCHAR(5)) AS wRoomAssigned ,
                                ehr.wLockCounterRid ,
			--CASE WHEN (ehr.wLockCounterRid IS NOT NULL AND ehr.wLockCounterRid <> 0) THEN 'Yes' ELSE 'No' END AS wIsLock,
                                CAST(CASE WHEN ( ehr.wLockCounterRid IS NOT NULL
                                                 AND ehr.wLockCounterRid <> 0
                                               ) THEN 'Y'
                                          ELSE 'N'
                                     END AS CHAR(1)) AS wIsLock ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName ,
                                ehr.wCounterRid AS wCounterRid ,
                                CAST(0 AS BIT) AS wIsSelected ,
			--(dbo.HasServiceCounterAccessToHotel(@pwCounterRid,ehr.wHotelCodeSCV)) AS wHasAccess
                                CAST(1 AS BIT) AS wHasAccess
                       FROM     dbo.eHotelRequest ehr
                                INNER JOIN dbo.mHotel mh ON mh.wCode IN ( SELECT    splitdata
                                                                          FROM      [dbo].[Split](ehr.wHotelCodeSCV, ',') ) --= ehrdtl.wHotelCode 
                                INNER JOIN dbo.mLookUp lr ON lr.wCode = ehr.wRegion
                                                             AND lr.wLangCd = @pwLangCd
                                                             AND lr.wType = 'REGION'
                                INNER JOIN dbo.mLookUp lbt ON lbt.wCode = ehr.wBedType
                                                              AND lbt.wLangCd = @pwLangCd
                                                              AND lbt.wType = 'BED_TYPE'
                                INNER JOIN dbo.mLookUp lhbs ON lhbs.wCode = ehr.wStatus
                                                               AND lhbs.wLangCd = @pwLangCd
                                                               AND lhbs.wType = 'HOTEL_BOOKING_STATUS'
                                INNER JOIN eBookingTravelPackage ebtp ON ebtp.RowID = ehr.wTravePkgRid
                                LEFT JOIN eBookingHotel ebh ON ebh.wRequestRid = ehr.RowID
                                LEFT JOIN eBooking eb ON eb.RowID = ebh.wBookingRid
                                LEFT JOIN cteRollingAmt r ON ehr.wReqAgentCodeIn = r.wAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mAgent rq ON rq.RowID = ehr.wReqCustomerRid
                                LEFT JOIN RollsMary.dbo.mAgent agnt ON agnt.wAgentCodeIn = ehr.wReqAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = ehr.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ehr.wCrtBy
                       WHERE    ( @pwHotelStatus = ''
                                  OR @pwHotelStatus IS NULL
                                  OR @pwHotelStatus = ehr.wStatus
                                )
                                AND ( ISNULL(@pwPackageId, 0) = 0
                                      OR @pwPackageId = ehr.wTravePkgRid
                                    )
                                AND ( ISNULL(@pwTravelPackageStatus, '') = ''
                                      OR @pwTravelPackageStatus = ebtp.wBookingStatus
                                    )
		--ORDER BY ehr.wUpdDt DESC
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            WHERE   ( tResult.wHasAccess = ( CASE WHEN @pwTempStatus = 'MA'
                                                       OR @pwTempStatus = 'MR' THEN ( dbo.HasServiceCounterAccessToHotel(@pwCounterRid, tResult.wHotelCodeSCV) )
                                                  ELSE 1
                                             END )
		   --AND tResult.wCounterRid IN (CASE WHEN @pwTempStatus = 'MR' THEN  
		   --((SELECT @pwCounterRid UNION SELECT tResult.wCounterRid FROM tResult)) ELSE tResult.wCounterRid END)
                      )
		   --WHERE tResult.wCounterRid = @pwCounterRid 
            ORDER BY wUpdDt DESC
		   --ORDER BY tResult.RowID
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		   FETCH NEXT @pPageSize ROWS ONLY;
    END;