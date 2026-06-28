CREATE PROCEDURE [spq].[GetCashTransferByBooking]
    (
      @pOutAgentCodeIn VARCHAR(14) ,
      @pCrtDt DATETIME2 ,
      @pLangCd VARCHAR(10) ,
      @pPageNum INT ,
      @pPageSize INT
    )
AS
    BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        DECLARE @vFromDt AS DATETIME2 = '0001-01-01' ,
            @vToDt AS DATETIME2 = '9999-12-31';

        IF @pCrtDt IS NOT NULL
            BEGIN	
                SET @vFromDt = DATEADD(mm, -1, @pCrtDt);
                SET @vToDt = DATEADD(mm, 1, @pCrtDt);
            END;  
        SET @pOutAgentCodeIn = ISNULL(@pOutAgentCodeIn, '');
        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');
        SET @pPageNum = ISNULL(@pPageNum, 9999);
        SET @pPageSize = ISNULL(@pPageSize, 1);

        WITH    tResult
                  AS ( SELECT   ct.RowID ,
                                ct.wRefNo ,
                                ct.wOutAgentCodeIn ,
                                outAgent.wAgentCode_Display AS wOutAgentCode_Display ,
                                CASE WHEN @pLangCd = 'en-gb'
                                     THEN outAgent.wEName
                                     ELSE outAgent.wCName
                                END AS wOutAgentCodeByName ,
                                ct.wInAgentCodeIn ,
                                inAgent.wAgentCode_Display AS wInAgentCode_Display ,
                                CASE WHEN @pLangCd = 'en-gb'
                                     THEN inAgent.wEName
                                     ELSE inAgent.wCName
                                END AS wInAgentCodeByName ,
                                ct.wInCurrCd AS wCurrCd ,
                                ct.wInAmount AS wAmount ,
                                ct.wCashTransferStatus ,
                                ct.wRelatedBookingRefNo ,
                                ct.wCrtDt ,
                                CAST('N' AS CHAR(1)) AS wIsSelected, -- Pseudo Column
                                ct.wRemark
                       FROM     dbo.eCashTransfer ct
                                LEFT JOIN [RollsMary].[dbo].[mAgent] inAgent ON ct.wInAgentCodeIn = inAgent.wAgentCodeIn
                                LEFT JOIN [RollsMary].[dbo].[mAgent] outAgent ON ct.wOutAgentCodeIn = outAgent.wAgentCodeIn
                       WHERE    ( @pOutAgentCodeIn = ''
                                  OR ct.wOutAgentCodeIn = @pOutAgentCodeIn
                                )
                                AND ( @vFromDt <= ct.wCrtDt
                                      AND @vToDt >= ct.wCrtDt
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
            ORDER BY tResult.wCrtDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS  
    FETCH NEXT @pPageSize ROWS ONLY;

    END;