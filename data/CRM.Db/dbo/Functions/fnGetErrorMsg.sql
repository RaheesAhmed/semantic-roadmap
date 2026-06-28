

CREATE FUNCTION [dbo].[fnGetErrorMsg]
(
    @pErrorCd varchar(30),
    @pLangCd VARCHAR(10) = 'zh-TW'
)
RETURNS NVARCHAR(500)
AS
BEGIN
    SET @pLangCd=ISNULL(@pLangCd,'zh-TW');
    DECLARE @vName NVARCHAR(500);

    IF @pLangCd='zh-TW'
    BEGIN
       SET @vName = CASE @pErrorCd

                    --booking
                    WHEN '1001' THEN N'保存失敗！訂單已被修改,請退出後重新操作 '

                    --Stock
                    WHEN '2001' THEN N'保存失敗! 該倉庫沒有採購此產品 '
                    WHEN '2002' THEN N'保存失敗! 不允許做此操作 '
                    WHEN '2003' THEN N'保存失敗! 批次號碼已存在 '
                    WHEN '2004' THEN N'保存失敗! 本批次號碼產品已被使用 '
                    WHEN '2005' THEN N'保存失敗! 該倉庫庫存沒有此產品'
                    WHEN '2006' THEN N'保存失敗! 該單號已存在 '
                    WHEN '2007' THEN N'保存失敗! 倉庫沒有足夠貨品數量 '

                    --master
                    WHEN '3001' THEN N'该房额已被使用，不能做更新或者中止操作 '
                    WHEN '3002' THEN N'该航线已被使用,不能删除或中止'
                    WHEN '3003' THEN N'该貨品類型已被使用,不能删除或中止'
                    WHEN '3004' THEN N'该貨品已被使用,不能删除或中止'
                    WHEN '3005' THEN N'该倉庫已被使用,不能删除或中止'
                    WHEN '3006' THEN N'该服務櫃臺已被使用,不能删除或中止'
                    WHEN '3007' THEN N'该活動代碼已被使用,不能删除或中止'
                    WHEN '3008' THEN N'该類型已被使用,不能删除或中止'
                    WHEN '3009' THEN N'该取票地點已被使用,不能删除或中止'
                    WHEN '3010' THEN N'该機場已被使用,不能删除或中止'
                    WHEN '3011' THEN N'该旅行社已被使用,不能删除或中止'

                    ELSE UPPER(@pErrorCd) END;
    END;
    ELSE
    BEGIN
       SET @vName = CASE @pErrorCd

                    --booking
                    WHEN '1001' THEN 'Save the failure! The order has been modified, please reoperate after exiting '

                    --Stock
                    WHEN '2001' THEN 'Save the failure! No Item purchased to this Warehouse '
                    WHEN '2002' THEN 'Save the failure! process not allowed '
                    WHEN '2003' THEN 'Save the failure! Batch number already exists '
                    WHEN '2004' THEN 'Save the failure! This Batch number goods already used '
                    WHEN '2005' THEN 'Save the failure! No inventory of this item in this Warehouse '
                    WHEN '2006' THEN 'Save the failure! This order number already exists'
                    WHEN '2007' THEN 'Save the failure! There is not enough quantity of goods in the Warehouse '

                    --master
                    WHEN '3001' THEN N'this record has been used, cannot be discontinued '

                    ELSE UPPER(@pErrorCd) END;
    END;

    RETURN @vName;
END