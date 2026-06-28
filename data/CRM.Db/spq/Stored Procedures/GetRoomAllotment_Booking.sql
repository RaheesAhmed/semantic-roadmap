
CREATE PROCEDURE [spq].[GetRoomAllotment_Booking]
    @pwStatus CHAR(1) ,
    @pwServiceCounterRid BIGINT = NULL ,
    @pwLangCd VARCHAR(10) = 'en-GB' ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1 ,
    @pwHotelRid BIGINT = NULL
AS
    BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
        SET NOCOUNT ON;
-- Insert statements for procedure here
        IF @pwHotelRid != NULL
            OR @pwHotelRid > 0
            BEGIN
                WITH    tResult
                          AS ( SELECT DISTINCT
                                        mhr.RowID ,
                                        mhr.wCode ,
                                        mhr.wName ,
                                        mhr.wRemark AS wRemarks ,
                                        mhr.wSeqNo ,
                                        mhr.wStatus ,
                                        mhr.wCrtDt ,
                                        mhr.wCrtBy ,
                                        mhr.wUpdDt ,
                                        mhr.wUpdBy ,
                                        ALLOT.wRoomRid ,
                                        CASE WHEN @pwLangCd = 'en-gb'
                                             THEN usr.wName
                                             ELSE usr.wCName
                                        END AS wUpdByCName ,
                                        CASE WHEN @pwLangCd = 'en-gb'
                                             THEN crusr.wName
                                             ELSE crusr.wCName
                                        END AS wCreatedByCName
                               FROM     dbo.mAllotmentGroup mhr
                                        INNER JOIN ( SELECT DISTINCT
                                                            ALT.wHotelRid ,
                                                            wAllotmentGroupRid ,
                                                            wRoomRid
                                                     FROM   dbo.eAllotmentHotel (NOLOCK) ALT
                                                            INNER JOIN dbo.eAllotmentHotelDtl (NOLOCK) DTL ON DTL.wAllotmentHotelRid = ALT.RowID
                                                     WHERE  ALT.wHotelRid = @pwHotelRid
                                                   ) ALLOT ON ALLOT.wAllotmentGroupRid = mhr.RowID
                                        INNER JOIN ( SELECT  *
                                                    FROM    dbo.mAllotmentGroupDtl (NOLOCK)
                                                  ) ALTDTL ON ALTDTL.wCounterRid = @pwServiceCounterRid
                                                              AND ALTDTL.wAllotmentGroupRid = ALLOT.wAllotmentGroupRid
                                        LEFT JOIN [RollsMary].[dbo].[mUsr] (NOLOCK) usr ON usr.RowID = mhr.wUpdBy
                                        LEFT JOIN [RollsMary].[dbo].[mUsr] (NOLOCK) crusr ON crusr.RowID = mhr.wCrtBy
                             ),
                        tCount
                          AS ( SELECT   wRecordCount = COUNT(*)
                               FROM     tResult
                             )
                    SELECT  tResult.* ,
                            wRecordCount
                    FROM    tResult ,
                            tCount
                    ORDER BY wSeqNo
                            OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY;

            END;
        ELSE
            BEGIN
                WITH    tResult
                          AS ( SELECT   mhr.RowID ,
                                        mhr.wCode ,
                                        mhr.wName ,
                                        mhr.wRemark AS wRemarks ,
                                        mhr.wSeqNo ,
                                        mhr.wStatus ,
                                        mhr.wCrtDt ,
                                        mhr.wCrtBy ,
                                        mhr.wUpdDt ,
                                        mhr.wUpdBy ,
                                        CAST(0 AS BIGINT) AS wRoomRid ,
                                        CASE WHEN @pwLangCd = 'en-gb'
                                             THEN usr.wName
                                             ELSE usr.wCName
                                        END AS wUpdByCName ,
                                        CASE WHEN @pwLangCd = 'en-gb'
                                             THEN crusr.wName
                                             ELSE crusr.wCName
                                        END AS wCreatedByCName
                               FROM     dbo.mAllotmentGroup mhr
                                        INNER JOIN [RollsMary].[dbo].[mUsr] (NOLOCK) usr ON usr.RowID = mhr.wUpdBy
                                        INNER JOIN [RollsMary].[dbo].[mUsr] (NOLOCK) crusr ON crusr.RowID = mhr.wCrtBy
                               WHERE    ( @pwStatus = ''
                                          OR @pwStatus = ' '
                                          OR @pwStatus = '\0'
                                          OR @pwStatus IS NULL
                                          OR @pwStatus = mhr.wStatus
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

    END;