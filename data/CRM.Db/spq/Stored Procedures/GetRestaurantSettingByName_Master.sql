

CREATE PROCEDURE [spq].[GetRestaurantSettingByName_Master]
    (
      @RestaurantName NVARCHAR(100) ,
      @RowId BIGINT ,
      @pwLangCd VARCHAR(10) = 'en-GB'
    )
AS
    BEGIN

        SELECT  rs.[RowID] ,
                rs.[wName] ,
                [wCuisine] ,
                [wLevel] ,
                lupr.wTitle wGrade ,
                [wPhone] ,
                [wHotelRid] ,
                [wAddress] ,
                [wWorkHours] ,
                [wRegion] ,
                [wNoOfSeat] ,
                [wIsSign] ,
                [wIsBtm] ,
                [wMinCharge] ,
                [wMenu] ,
                rs.[wStatus] ,
                rs.[wSeqNo] ,
                rs.[wCrtDt] ,
                rs.[wUpdDt] ,
                rs.[wUpdBy] ,
                rs.[wCrtBy] ,
                rs.wAwards ,
                CASE WHEN @pwLangCd = 'en-gb' THEN usr.wName
                     ELSE usr.wCName
                END AS wUpdByName ,
                CASE WHEN @pwLangCd = 'en-gb' THEN crusr.wName
                     ELSE crusr.wCName
                END AS wCrtByName
        FROM    [CRM].[dbo].[mRestaurant] rs
                LEFT JOIN mLookUp lupr ON lupr.wCode = rs.wLevel
                                          AND lupr.wType = 'RESTAURANT_LEVEL'
                                          AND lupr.wLangCd = @pwLangCd
                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = rs.wUpdBy
                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = rs.wCrtBy
        WHERE   rs.[wName] = @RestaurantName
                OR rs.[RowID] = @RowId;

    END;