CREATE PROCEDURE [util].[CheckMissingExpTran] @pDate AS VARCHAR(20)
AS
    BEGIN
;
        SET NOCOUNT ON;	  	
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;             

        WITH    cteExpTran
                  AS ( SELECT   wReferId ,--CAST(ISNULL(wReferId, '0') AS BIGINT) AS wReferId ,
                                'eExpTran' AS wTableName
                       FROM     Rollsmary.dbo.eExpTran
                       WHERE    wDate > @pDate
                                AND wExpDesc = ''
                                AND wExpGroup IN ( 'CRM', 'RCRM' )
                                --AND CHARINDEX('-', wReferId) = 0
                     ),
                cteAdditionalExpense
                  AS ( SELECT  DISTINCT
                                ae.RowID ,
                                'eAdditionalExpense' AS wTableName
                       FROM     CRM.dbo.eAdditionalExpense ae
                                INNER JOIN CRM.dbo.eBooking b ON ae.wBookingRid = b.RowID
                                INNER JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN CRM.dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                       WHERE    ( ( ae.wBookingStatus = 'C'
                                    --AND ISNULL(ae.wBookingStatus, 'P') != 'C'
                                    )
                                  OR ( ae.wBookingStatus = 'RF'
                                       AND ISNULL(ae.wBookingStatus, 'P') != 'RF'
                                     )
                                )
                                AND ae.wStatus = 'A'
                                AND ae.wCrtDt > @pDate
                                AND CAST(ae.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingFerry
                  AS ( SELECT  DISTINCT
                                bf.RowID ,
                                'eBookingFerry' AS wTableName
                       FROM     dbo.eBookingFerry bf
                                LEFT JOIN dbo.eBooking b ON bf.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                       WHERE    bf.wBookingStatus = 'C'
                                --AND ISNULL(bf.wBookingStatus, '') != 'C'
                                AND bf.wPaymentMethod IN ( 'DA' )
                                AND bf.wStatus = 'A'
                                AND bf.wCrtDt > @pDate
                                AND CAST(bf.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingHeli
                  AS ( SELECT  DISTINCT
                                bh.RowID ,
                                'eBookingHeli' AS wTableName
                       FROM     dbo.eBookingHeli bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wIsCharteredFlight = 'Y'
                                AND ( ( bh.wBookingStatus = 'C'
                                        --AND ISNULL(bh.wBookingStatus, 'P') != 'C'
                                        )
                                      OR ( bh.wBookingStatus = 'RF'
                                           AND ISNULL(bh.wBookingStatus, 'P') != 'RF'
                                         )
                                    )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingLeading
                  AS ( SELECT  DISTINCT
                                bh.RowID ,
                                'eBookingLeading' AS wTableName
                       FROM     dbo.eBookingLeading bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'C'
                                --AND ISNULL(bh.wBookingStatus, '') != 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingLeading2
                  AS ( SELECT  DISTINCT
                                bh.RowID ,
                                'cteBookingLeading2' AS wTableName
                       FROM     dbo.eBookingLeading bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'RF'
                                AND bh.wBookingStatus = 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingPickUpService
                  AS ( SELECT DISTINCT
                                bh.RowID ,
                                'eBookingPickUpService' AS wTableName
                       FROM     dbo.eBookingPickUpService bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'C'
                                --AND ISNULL(bh.wBookingStatus, '') != 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingPrivatePlane
                  AS ( SELECT DISTINCT
                                bh.RowID ,
                                'eBookingPrivatePlane' AS wTableName
                       FROM     dbo.eBookingPrivatePlane bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'C'
                                --AND ISNULL(bh.wBookingStatus, '') != 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingPrivatePlane2
                  AS ( SELECT DISTINCT
                                bh.RowID ,
                                'eBookingPrivatePlane2' AS wTableName
                       FROM     dbo.eBookingTourGuide bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'C'
                                --AND ISNULL(bh.wBookingStatus, '') != 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingTourGuide
                  AS ( SELECT DISTINCT
                                bh.RowID ,
                                'eBookingTourGuide' AS wTableName
                       FROM     dbo.eBookingTourGuide bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'RF'
                                AND bh.wBookingStatus = 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingVisa
                  AS ( SELECT DISTINCT
                                bh.RowId ,
                                'eBookingVisa' AS wTableName
                       FROM     dbo.eBookingVisa bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'C'
                                --AND ISNULL(bh.wBookingStatus, '') != 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowId AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingVisa2
                  AS ( SELECT DISTINCT
                                bh.RowId ,
                                'eBookingVisa2' AS wTableName
                       FROM     dbo.eBookingVisa bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'RF'
                                AND bh.wBookingStatus = 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowId AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingCheckInService
                  AS ( SELECT DISTINCT
                                bh.RowId ,
                                'eBookingCheckInService' AS wTableName
                       FROM     dbo.eBookingCheckInService bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'C'
                                --AND ISNULL(bh.wBookingStatus, '') != 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowId AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingCheckInService2
                  AS ( SELECT DISTINCT
                                bh.RowId ,
                                'eBookingCheckInService2' AS wTableName
                       FROM     dbo.eBookingCheckInService bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'RF'
                                AND bh.wBookingStatus = 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowId AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                ctePassengerDetails
                  AS ( SELECT DISTINCT
                                bh.RowID ,
                                'ePassengerDetails' AS wTableName
                       FROM     dbo.ePassengerDetails bh
                                INNER JOIN dbo.mPerson p ON bh.wPersonRid = p.RowID
                                LEFT JOIN dbo.eBookingAirTicket bat ON bh.wBookingRid = bat.wBookingRid
                                INNER JOIN eBooking b ON bh.wBookingRid = b.RowID
                                INNER JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wType = 'AIRTICKET'
                                AND ( bh.wPassengerBookingStatus = 'C'
                                      --AND ISNULL(bh.wPassengerBookingStatus,
                                      --           'P') != 'C'
                                      OR bh.wPassengerBookingStatus = 'RF'
                                      --AND ISNULL(bh.wPassengerBookingStatus,
                                      --           'P') != 'RF'
                                    )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                ctePassengerDetails2
                  AS ( SELECT DISTINCT
                                bh.RowID ,
                                'ePassengerDetails2' AS wTableName
                       FROM     dbo.ePassengerDetails pd
                                INNER JOIN dbo.mPerson p ON pd.wPersonRid = p.RowID
                                LEFT JOIN dbo.eBookingHeli bh ON pd.wBookingRid = bh.wBookingRid
                                INNER JOIN eBooking b ON pd.wBookingRid = b.RowID
                                INNER JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON pd.wUpdBy = u.RowID
                       WHERE    pd.wType = 'HELI'
                                AND bh.wIsCharteredFlight = 'N'
                                AND ( pd.wPassengerBookingStatus = 'C'
                                     -- AND pd.wPassengerBookingStatus != 'C'
                                      OR pd.wPassengerBookingStatus = 'RF'
                                      --AND pd.wPassengerBookingStatus != 'RF'
                                    )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingShow
                  AS ( SELECT DISTINCT
                                bh.RowID ,
                                'eBookingShow' AS wTableName
                       FROM     dbo.eBookingShow bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'C'
                               -- AND ISNULL(bh.wBookingStatus, '') != 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     ),
                cteBookingShow2
                  AS ( SELECT DISTINCT
                                bh.RowID ,
                                'eBookingShow2' AS wTableName
                       FROM     dbo.eBookingShow bh
                                LEFT JOIN dbo.eBooking b ON bh.wBookingRid = b.RowID
                                LEFT JOIN Rollsmary.dbo.mAgent a ON b.wReqAgentCodeIn = a.wAgentCodeIn
                                LEFT JOIN Rollsmary.dbo.mAgent aAuth ON b.wApprovalAgentCodeIn = aAuth.wAgentCodeIn
                                LEFT JOIN dbo.mServiceCounter sc ON b.wReqCounterRid = sc.RowID
                                LEFT JOIN Rollsmary.dbo.mCage c ON c.wCompNo = sc.wRollexCompNo
                                                              AND c.wCageCode = '001'
                                                              AND c.wStatus = 'A'
                                LEFT JOIN Rollsmary.dbo.mUsr u ON bh.wUpdBy = u.RowID
                       WHERE    bh.wBookingStatus = 'RF'
                                AND bh.wBookingStatus = 'C'
                                AND bh.wPaymentMethod IN ( 'DA' )
                                AND bh.wStatus = 'A'
                                AND bh.wCrtDt > @pDate
                                AND CAST(bh.RowID AS VARCHAR(40)) NOT IN (
                                SELECT  wReferId
                                FROM    cteExpTran )
                     )
            SELECT  *
            FROM    cteAdditionalExpense
            UNION ALL
            SELECT  *
            FROM    cteBookingCheckInService
            UNION ALL
            SELECT  *
            FROM    cteBookingCheckInService2
            UNION ALL
            SELECT  *
            FROM    cteBookingFerry
            UNION ALL
            SELECT  *
            FROM    cteBookingHeli
            UNION ALL
            SELECT  *
            FROM    cteBookingLeading
            UNION ALL
            SELECT  *
            FROM    cteBookingLeading2
            UNION ALL
            SELECT  *
            FROM    cteBookingPickUpService
            UNION ALL
            SELECT  *
            FROM    cteBookingPrivatePlane
            UNION ALL
            SELECT  *
            FROM    cteBookingPrivatePlane2
            UNION ALL
            SELECT  *
            FROM    cteBookingShow
            UNION ALL
            SELECT  *
            FROM    cteBookingShow2
            UNION ALL
            SELECT  *
            FROM    cteBookingTourGuide
            UNION ALL
            SELECT  *
            FROM    cteBookingVisa
            UNION ALL
            SELECT  *
            FROM    cteBookingVisa2
            UNION ALL
            SELECT  *
            FROM    ctePassengerDetails
            UNION ALL
            SELECT  *
            FROM    ctePassengerDetails2;
    END;