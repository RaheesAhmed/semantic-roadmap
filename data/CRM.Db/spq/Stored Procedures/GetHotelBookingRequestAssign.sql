
CREATE PROCEDURE [spq].[GetHotelBookingRequestAssign]
    (
      @pwStatus VARCHAR(20) ,
      @pPageSize INT = 999 ,
      @pPageNum INT = 1 ,
      @pwLangCd VARCHAR(10) = 'en-GB'	
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY ehr.RowID ) AS wSeqNo ,
                                ehr.RowID ,
                                cstmr.wCName wRequestClient ,--  ehr.wReqCustomerRid, RequestedClientID, Person,
                                '10.91112' mCompanyRolling ,
                                '30.3224' mBaseRolling ,
                                ehr.wReqAgentCodeIn ,
                                agnt.wCName wRequestAccount ,  -- ehr.wAgentCodeIn -- Requested Account/Agent,
                                ehr.wNumberOfRoom ,
                                ehr.wDayOfStay ,
                                ehr.wStartDate ,
                                ehr.wDebitAgentCodeIn ,
                                ehr.wReqCustomerRid ,
                                ehr.wReqDepartment ,
                                ehr.wAsstBooker ,
                                ehr.wAssBookerTel ,
                                ehr.wRegion wRegionCode ,
                                ehr.wBedType wBedCode ,
                                ehr.wHotelCodeSCV ,
                                ehr.wEndDate ,
                                mh.wName wHotelRequest ,
                                lbt.wTitle wBedType ,
                                ehr.wRemark ,
                                lhbs.wTitle wStatus ,
                                ehr.wCrtDt ,
                                ehr.wCrtBy ,
                                ehr.wUpdDt ,
                                ehr.wUpdBy ,
                                '2/3' wRoomAssigned ,
                                usr.wCName AS wUpdByCName
                       FROM     dbo.eHotelRequest ehr
                                INNER JOIN dbo.mPerson p ON p.RowID = ehr.wReqCustomerRid
                                INNER JOIN RollsMary.dbo.mAgent cstmr ON cstmr.wAgentCodeIn = p.wAgentCodeIn
                                INNER JOIN RollsMary.dbo.mAgent agnt ON agnt.wAgentCodeIn = ehr.wReqAgentCodeIn
                                INNER JOIN dbo.eHotelRequestDtl ehrdtl ON ehrdtl.wHotelRequestRid = ehr.RowID
                                INNER JOIN dbo.mHotel mh ON mh.wCode = ehrdtl.wHotelCode
                                INNER JOIN dbo.mLookUp lr ON lr.wCode = ehr.wRegion
                                                             AND lr.wLangCd = @pwLangCd
                                                             AND lr.wType = 'REGION'
                                INNER JOIN dbo.mLookUp lbt ON lbt.wCode = ehr.wBedType
                                                              AND lbt.wLangCd = @pwLangCd
                                                              AND lbt.wType = 'BED_TYPE'
                                INNER JOIN dbo.mLookUp lhbs ON lhbs.wCode = ehr.wStatus
                                                              AND lhbs.wLangCd = @pwLangCd
                                                              AND lhbs.wType = 'HOTEL_BOOKING_STATUS'
                                LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = ehr.wUpdBy
                       WHERE    ( @pwStatus = ''
                                  OR @pwStatus IS NULL
                                  OR @pwStatus = ehr.wStatus
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
            ORDER BY wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
		   FETCH NEXT @pPageSize ROWS ONLY;
    END;