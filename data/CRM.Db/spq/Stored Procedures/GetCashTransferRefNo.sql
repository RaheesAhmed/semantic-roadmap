CREATE PROCEDURE [spq].[GetCashTransferRefNo]
    (
      @pRefNo VARCHAR(30) OUTPUT 
    )
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @nextRefNo BIGINT;
        
         IF NOT EXISTS ( SELECT  1 FROM    sys.objects
                            WHERE   object_id = OBJECT_ID('seqeCashTransferRefNo') AND type = 'SO' 
                       )
               BEGIN
                   CREATE SEQUENCE seqeCashTransferRefNo START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999;
               END;

        SET @nextRefNo = NEXT VALUE FOR[dbo].[seqeCashTransferRefNo];

        IF @nextRefNo < 100000
            SET @pRefNo = 'TI'+ FORMAT(@nextRefNo,'000000') 
          ELSE 
              SET @pRefNo = 'TI'+ LTRIM(@nextRefNo) 
    END;