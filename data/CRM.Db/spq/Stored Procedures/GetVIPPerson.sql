CREATE PROCEDURE [spq].[GetVIPPerson]
    @pRowID BIGINT
AS
BEGIN
    SET NOCOUNT ON;        
	
    SELECT 
        RowID,
        wAgentCodeIn, 
        wPersonName, 
        wPersonIdentity, 
        wGender, 
        wAuthorizerAgentCodeIn, 
        wAuthorizerIdentity, 
        wRelationship, 
        wOtherRelationship,
        wBirthDate, 
        wCalendarType, 
        wYear, 
        wMonth, 
        wDay,
        wIsLeapMonth,
        wContactWay, 
        wTelNumber, 
        wWhatsappNumber, 
        wWeChatNumber, 
        wWeChatName, 
        wBudgetRatio, 
        wIsWeChatVerify, 
        wIsPresentGift, 
        wIsAuthorizer, 
        wVIPPersonStatus, 
        wStatusRemark,
        wSource,
        wIsRefusedContact,
        wStatus,
        wCrtBy, 
        wCrtDt, 
        wUpdBy, 
        wUpdDt 
    FROM dbo.mVIPPerson
    WHERE @pRowID = RowID                                                 
END;