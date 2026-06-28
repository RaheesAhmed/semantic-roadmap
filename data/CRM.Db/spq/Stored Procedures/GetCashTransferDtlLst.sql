
CREATE PROCEDURE [spq].[GetCashTransferDtlLst]
	-- Add the parameters for the stored procedure here
    (
      @pCashTransferRid BIGINT ,
      @pBookingRid BIGINT ,
      @pStatus CHAR(1) ,
      @pLangCd VARCHAR(10) ,
      @pPageNum INT ,
      @pPageSize INT
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

        SET @pCashTransferRid = ISNULL(@pCashTransferRid, 0);
        SET @pBookingRid = ISNULL(@pBookingRid, 0);
        SET @pStatus = ISNULL(@pStatus, ' ');
        SET @pLangCd = ISNULL(@pLangCd, 'en-gb');
        SET @pPageNum = ISNULL(@pPageNum, 1);
        SET @pPageSize = ISNULL(@pPageSize, 9999);

    -- Insert statements for procedure here
        WITH    tResult
                  AS ( SELECT   ctd.RowID ,
                                ctd.wCashTransferRid ,
                                ctd.wBookingRid ,
                                ctd.wStatus ,
                                ctd.wCrtBy ,
                                ctd.wCrtDt ,
                                ctd.wUpdBy ,
                                ctd.wUpdDt ,
                                'N' AS RecordState
                       FROM     dbo.eCashTransferDtl ctd
                       WHERE    ( @pCashTransferRid = 0
                                  OR ctd.wCashTransferRid = @pCashTransferRid
                                )
                                AND ( @pBookingRid = 0
                                      OR ctd.wBookingRid = @pBookingRid
                                    )
                                AND ( @pStatus = ' '
                                      OR ctd.wStatus = @pStatus
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