CREATE PROCEDURE [util].[CompareResourceWithRollsmary]
AS
BEGIN
	SET NOCOUNT ON;

--CREATE TABLE #Rollsmary
--(
--wCode VARCHAR(200) PRIMARY KEY,
--wValue NVARCHAR(MAX)
--)
DECLARE @xmlRollsmary AS NVARCHAR(MAX), @hDocRollsmary AS INT
DECLARE @xmlCRM AS NVARCHAR(MAX), @hDocCRM AS INT
SET @xmlCRM = N'<root>
  <data name="global_msgInformationHeader" xml:space="preserve">
    <value>[系統訊息]-資訊</value>
  </data>
  <data name="global_msgCautionHeader" xml:space="preserve">
    <value>[系統訊息]-注意</value>
  </data>
  <data name="global_msgErrorHeader" xml:space="preserve">
    <value>[系統訊息]-提示</value>
  </data>
  <data name="global_msgError" xml:space="preserve">
    <value>很抱歉，系統出現問題。</value>
  </data>
  <data name="global_msgNoRecord" xml:space="preserve">
    <value>沒有資料</value>
  </data>
  <data name="global_msgNoReservationRecord" xml:space="preserve">
    <value>沒有預約資料</value>
  </data>
  <data name="global_msgMissActionCode" xml:space="preserve">
    <value>請輸入經手人</value>
  </data>
  <data name="global_msgMissActionCodePW" xml:space="preserve">
    <value>請輸入經手人密碼</value>
  </data>
  <data name="global_msgEmptyUsr" xml:space="preserve">
    <value>經手人不存在。</value>
  </data>
  <data name="global_msgUNAUTHORIZED" xml:space="preserve">
    <value>沒有權限。</value>
  </data>
  <data name="global_msgExpired" xml:space="preserve">
    <value>經手人已失效。</value>
  </data>
  <data name="global_msgExpiredActionCode" xml:space="preserve">
    <value>權限已失效。</value>
  </data>
  <data name="global_msgRelogin" xml:space="preserve">
    <value>請重新登入。</value>
  </data>
  <data name="global_msgWrongPassword" xml:space="preserve">
    <value>密碼錯誤。</value>
  </data>
  <data name="global_msgMissAuthActionCode" xml:space="preserve">
    <value>請輸入授權人</value>
  </data>
  <data name="global_msgMissAuthActionCodePW" xml:space="preserve">
    <value>請輸入授權人密碼</value>
  </data>
  <data name="global_msgEmptyAuth" xml:space="preserve">
    <value>授權人不存在。</value>
  </data>
  <data name="global_msgExpiredAuth" xml:space="preserve">
    <value>授權人已失效。</value>
  </data>
  <data name="global_txtActionCode" xml:space="preserve">
    <value>經手人</value>
  </data>
  <data name="global_txtActionCodePw" xml:space="preserve">
    <value>經手人密碼</value>
  </data>
  <data name="global_txtAuthActionCode" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="global_txtAuthActionCodePw" xml:space="preserve">
    <value>授權人密碼</value>
  </data>
  <data name="global_btnEnter" xml:space="preserve">
    <value>確認</value>
  </data>
  <data name="global_btnCancel" xml:space="preserve">
    <value>取消</value>
  </data>
  <data name="global_btnReset" xml:space="preserve">
    <value>重置</value>
  </data>
  <data name="global_btnSearch" xml:space="preserve">
    <value>搜尋</value>
  </data>
  <data name="global_btnAdd" xml:space="preserve">
    <value>新增</value>
  </data>
  <data name="global_btnSave" xml:space="preserve">
    <value>保存</value>
  </data>
  <data name="global_btnSavePrint" xml:space="preserve">
    <value>保存及列印</value>
  </data>
  <data name="global_btnDel" xml:space="preserve">
    <value>刪除</value>
  </data>
  <data name="global_btnPrint" xml:space="preserve">
    <value>列印</value>
  </data>
  <data name="global_btnPreview" xml:space="preserve">
    <value>預覽</value>
  </data>
  <data name="global_btnPreviewNewStatement" xml:space="preserve">
    <value>預覽新糧單</value>
  </data>
  <data name="global_btnExport" xml:space="preserve">
    <value>匯出</value>
  </data>
  <data name="global_btnApprove" xml:space="preserve">
    <value>批核</value>
  </data>
  <data name="global_btnSMS" xml:space="preserve">
    <value>SMS</value>
  </data>
  <data name="global_btnClose" xml:space="preserve">
    <value>退出</value>
  </data>
  <data name="typeAGENT_Core" xml:space="preserve">
    <value>戶口</value>
  </data>
  <data name="typeEXPENSE_Core" xml:space="preserve">
    <value>消費</value>
  </data>
  <data name="typeMARKER_Core" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="typeMARKER_LST_Core" xml:space="preserve">
    <value>貸款管理</value>
  </data>
  <data name="typeOPERATE_Core" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="typeREPORT_Core" xml:space="preserve">
    <value>報表</value>
  </data>
  <data name="typeROLLING_Core" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="typeSETTLEMENT_Core" xml:space="preserve">
    <value>月結</value>
  </data>
  <data name="typeSYSTEM_Core" xml:space="preserve">
    <value>系統</value>
  </data>
  <data name="wAgent" xml:space="preserve">
    <value>代理</value>
  </data>
  <data name="wCompNo" xml:space="preserve">
    <value>公司編號</value>
  </data>
  <data name="wCName" xml:space="preserve">
    <value>中文名字</value>
  </data>
  <data name="wEName" xml:space="preserve">
    <value>英文名字</value>
  </data>
  <data name="wShortName" xml:space="preserve">
    <value>簡稱</value>
  </data>
  <data name="wCurrCode" xml:space="preserve">
    <value>貨幣</value>
  </data>
  <data name="wRoomId" xml:space="preserve">
    <value>訊息公司編號</value>
  </data>
  <data name="wTel" xml:space="preserve">
    <value>電話</value>
  </data>
  <data name="wSmsStaff" xml:space="preserve">
    <value>場面公電</value>
  </data>
  <data name="wEmail" xml:space="preserve">
    <value>電郵</value>
  </data>
  <data name="wSmsStaffCage" xml:space="preserve">
    <value>帳房公電</value>
  </data>
  <data name="wLocation" xml:space="preserve">
    <value>地點</value>
  </data>
  <data name="wStatus" xml:space="preserve">
    <value>狀態</value>
  </data>
  <data name="wTeminateDate" xml:space="preserve">
    <value>終止日期</value>
  </data>
  <data name="wUpdByCName" xml:space="preserve">
    <value>經手人</value>
  </data>
  <data name="txtCompanyLst" xml:space="preserve">
    <value>公司管理</value>
  </data>
  <data name="global_txtAgentSummary" xml:space="preserve">
    <value>查數易</value>
  </data>
  <data name="typeAGENT_SUMMARY_Core" xml:space="preserve">
    <value>查數易</value>
  </data>
  <data name="global_txtActionHistory" xml:space="preserve">
    <value>執行記錄</value>
  </data>
  <data name="global_txtAgentNavigateHistory" xml:space="preserve">
    <value>戶口瀏覽記錄</value>
  </data>
  <data name="global_txtNavigateHistory" xml:space="preserve">
    <value>資料瀏覽記錄</value>
  </data>
  <data name="typeCOMPANYLST_Core" xml:space="preserve">
    <value>公司管理</value>
  </data>
  <data name="global_txtAccountLevel" xml:space="preserve">
    <value>級別</value>
  </data>
  <data name="global_txtAccountTypeUpDnReq" xml:space="preserve">
    <value>級別所需轉碼:
太陽客戶: 無需求
金太陽: 連續 3 個月有轉碼
卓越: 累計轉碼數達1億
非凡: 累計轉碼數達5億
奇蹟: 累計轉碼數達10億
傳奇: 累計轉碼數達15億
至尊: 累計轉碼數達20億
</value>
  </data>
  <data name="global_txtAddress" xml:space="preserve">
    <value>聯絡地址</value>
  </data>
  <data name="global_txtAgent" xml:space="preserve">
    <value>戶口</value>
  </data>
  <data name="global_txtAgentIdentity" xml:space="preserve">
    <value>身份</value>
  </data>
  <data name="global_txtAgentTypeHighDeposit" xml:space="preserve">
    <value>大額</value>
  </data>
  <data name="global_txtAgentTypeNew" xml:space="preserve">
    <value>新開戶</value>
  </data>
  <data name="global_txtAgentTypeShare" xml:space="preserve">
    <value>股東</value>
  </data>
  <data name="global_txtAgentTypeOtherClient" xml:space="preserve">
    <value>其他人數</value>
  </data>
  <data name="global_txtAgentTypeShareInt" xml:space="preserve">
    <value>股息</value>
  </data>
  <data name="global_txtAuthorize" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="global_txtBirthDay" xml:space="preserve">
    <value>出生日期</value>
  </data>
  <data name="global_txtCompNo" xml:space="preserve">
    <value>公司編號</value>
  </data>
  <data name="global_txtFollowGroup" xml:space="preserve">
    <value>跟進組別</value>
  </data>
  <data name="global_txtIDExpireDate" xml:space="preserve">
    <value>證件到期日</value>
  </data>
  <data name="global_txtIDNo" xml:space="preserve">
    <value>證件號碼</value>
  </data>
  <data name="global_txtName" xml:space="preserve">
    <value>姓名</value>
  </data>
  <data name="global_txtPreferLang" xml:space="preserve">
    <value>語言</value>
  </data>
  <data name="global_txtSex" xml:space="preserve">
    <value>性別</value>
  </data>
  <data name="global_txtShowIntroducer" xml:space="preserve">
    <value>介紹人</value>
  </data>
  <data name="global_txtStateCountry" xml:space="preserve">
    <value>國籍 (省/縣)</value>
  </data>
  <data name="global_txtTelNo" xml:space="preserve">
    <value>電話號碼</value>
  </data>
  <data name="global_txtType" xml:space="preserve">
    <value>類別</value>
  </data>
  <data name="global_txtUpperAgent" xml:space="preserve">
    <value>上線</value>
  </data>
  <data name="global_txtAgentEntryStatus" xml:space="preserve">
    <value>入場狀態</value>
  </data>
  <data name="global_txtAgentInfo" xml:space="preserve">
    <value>戶口資料</value>
  </data>
  <data name="global_txtAll" xml:space="preserve">
    <value>所有</value>
  </data>
  <data name="global_txtAmount10k" xml:space="preserve">
    <value>金額(萬)</value>
  </data>
  <data name="global_txtBettingMethod" xml:space="preserve">
    <value>投注方法</value>
  </data>
  <data name="global_txtBorrower" xml:space="preserve">
    <value>借款人</value>
  </data>
  <data name="global_txtCage" xml:space="preserve">
    <value>廳</value>
  </data>
  <data name="global_txtCapitalRemark" xml:space="preserve">
    <value>本金備註</value>
  </data>
  <data name="global_txtCardExp_Ext" xml:space="preserve">
    <value>卡消費(外)</value>
  </data>
  <data name="global_txtCardExp_Int" xml:space="preserve">
    <value>卡消費(內)</value>
  </data>
  <data name="global_txtCardType" xml:space="preserve">
    <value>卡類別</value>
  </data>
  <data name="global_txtChipTranGlobalTotalAmount" xml:space="preserve">
    <value>全球結存</value>
  </data>
  <data name="global_txtCName" xml:space="preserve">
    <value>中文姓名</value>
  </data>
  <data name="global_txtComp" xml:space="preserve">
    <value>公司</value>
  </data>
  <data name="global_txtCreditAmt" xml:space="preserve">
    <value>信貸額(萬)</value>
  </data>
  <data name="global_txtCurDateTime" xml:space="preserve">
    <value>記錄時間</value>
  </data>
  <data name="global_txtCurrency" xml:space="preserve">
    <value>貨幣</value>
  </data>
  <data name="global_txtCustName" xml:space="preserve">
    <value>客人名稱</value>
  </data>
  <data name="global_txtCustWinLoss" xml:space="preserve">
    <value>輸贏數(萬)</value>
  </data>
  <data name="global_txtDirectLoan" xml:space="preserve">
    <value>直接信貸</value>
  </data>
  <data name="global_txtEndTime" xml:space="preserve">
    <value>結束時間</value>
  </data>
  <data name="global_txtExpAutoTransfer" xml:space="preserve">
    <value>消費自動轉帳</value>
  </data>
  <data name="global_txtExpenseTerminated" xml:space="preserve">
    <value>停止消費</value>
  </data>
  <data name="global_txtGroupRemark" xml:space="preserve">
    <value>集團備註</value>
  </data>
  <data name="global_txtHKAmount10k" xml:space="preserve">
    <value>HKD金額(萬)</value>
  </data>
  <data name="global_txtHoldChipAmt" xml:space="preserve">
    <value>凍結存款</value>
  </data>
  <data name="global_txtIOUAmount_10K" xml:space="preserve">
    <value>折萛為港幣已簽貸款(萬)</value>
  </data>
  <data name="global_txtIOUTrace" xml:space="preserve">
    <value>信貸監控</value>
  </data>
  <data name="global_txtIOUTraceIncl_CashIOU" xml:space="preserve">
    <value>個人借貸數</value>
  </data>
  <data name="global_txtIOUTraceIncl_Foreign" xml:space="preserve">
    <value>海外數</value>
  </data>
  <data name="global_txtIOUTraceIncl_IOU" xml:space="preserve">
    <value>M數</value>
  </data>
  <data name="global_txtIOUTraceIncl_Operate" xml:space="preserve">
    <value>營運數</value>
  </data>
  <data name="global_txtIsDirectCreditAcc" xml:space="preserve">
    <value>公司授信戶口</value>
  </data>
  <data name="global_txtLastestWinLoss" xml:space="preserve">
    <value>最近輸贏數</value>
  </data>
  <data name="global_txtLeaveRemark" xml:space="preserve">
    <value>離枱備註</value>
  </data>
  <data name="global_txtMemberCardNo" xml:space="preserve">
    <value>會員卡號碼</value>
  </data>
  <data name="global_txtMonth" xml:space="preserve">
    <value>月</value>
  </data>
  <data name="global_txtNo" xml:space="preserve">
    <value>否</value>
  </data>
  <data name="global_txtNumberOfRecord" xml:space="preserve">
    <value>記錄總數</value>
  </data>
  <data name="global_txtPaymentMethod" xml:space="preserve">
    <value>還款方案</value>
  </data>
  <data name="global_txtPenaltyAmt" xml:space="preserve">
    <value>罰息金額</value>
  </data>
  <data name="global_txtRefNo" xml:space="preserve">
    <value>單號碼</value>
  </data>
  <data name="global_txtRemark" xml:space="preserve">
    <value>備註</value>
  </data>
  <data name="global_txtSearchAgent" xml:space="preserve">
    <value>搜尋戶口</value>
  </data>
  <data name="global_txtSelectAll" xml:space="preserve">
    <value>全選</value>
  </data>
  <data name="global_txtShortenForeign" xml:space="preserve">
    <value>海</value>
  </data>
  <data name="global_txtShortenMarker" xml:space="preserve">
    <value>M</value>
  </data>
  <data name="global_txtShortenOperation" xml:space="preserve">
    <value>營</value>
  </data>
  <data name="global_txtShow2ndShareHolderIOU" xml:space="preserve">
    <value>顯示2線股東(股本)M數</value>
  </data>
  <data name="global_txtShowAgentSummaryAgentIOUStatus" xml:space="preserve">
    <value>結存,凍結,罰息</value>
  </data>
  <data name="global_txtShowAgentSummaryCommPay" xml:space="preserve">
    <value>出佣</value>
  </data>
  <data name="global_txtShowAgentSummaryCompCommDrink" xml:space="preserve">
    <value>佣金,積分</value>
  </data>
  <data name="global_txtShowAgentSummaryCompExp" xml:space="preserve">
    <value>消費,前積分</value>
  </data>
  <data name="global_txtShowAgentSummaryCompRoll" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="global_txtShowAgentSummaryCompStore" xml:space="preserve">
    <value>存單,存卡</value>
  </data>
  <data name="global_txtShowAgentSummaryCreditControl" xml:space="preserve">
    <value>還款方案</value>
  </data>
  <data name="global_txtShowAgentSummaryCreditInfo" xml:space="preserve">
    <value>信貸額資料</value>
  </data>
  <data name="global_txtShowAgentSummaryIOUTrace" xml:space="preserve">
    <value>借貸追蹤</value>
  </data>
  <data name="global_txtShowAgentSummaryMarker" xml:space="preserve">
    <value>出M</value>
  </data>
  <data name="global_txtShowAgentSummaryMemberCard" xml:space="preserve">
    <value>會員卡號</value>
  </data>
  <data name="global_txtShowAgentSummaryOrderService" xml:space="preserve">
    <value>訂務</value>
  </data>
  <data name="global_txtShowAgentSummarySelection" xml:space="preserve">
    <value>查詢明細</value>
  </data>
  <data name="global_txtShowAgentSummaryTransaction" xml:space="preserve">
    <value>存/取/轉帳</value>
  </data>
  <data name="global_txtShowAgentSummaryWinLoss" xml:space="preserve">
    <value>輸贏數</value>
  </data>
  <data name="global_txtShowRefresh" xml:space="preserve">
    <value>顯示/更新</value>
  </data>
  <data name="global_txtStartTime" xml:space="preserve">
    <value>開始時間</value>
  </data>
  <data name="global_txtTel" xml:space="preserve">
    <value>電話</value>
  </data>
  <data name="global_txtTempCreditAmt" xml:space="preserve">
    <value>臨時信用額</value>
  </data>
  <data name="global_txtTenk" xml:space="preserve">
    <value>萬</value>
  </data>
  <data name="global_txtTypeCode" xml:space="preserve">
    <value>類型</value>
  </data>
  <data name="global_txtUpdBy" xml:space="preserve">
    <value>經手人</value>
  </data>
  <data name="global_txtWeek" xml:space="preserve">
    <value>週</value>
  </data>
  <data name="global_txtYear" xml:space="preserve">
    <value>年</value>
  </data>
  <data name="global_txtYes" xml:space="preserve">
    <value>是</value>
  </data>
  <data name="txtShowAgentSummaryCompMarker" xml:space="preserve">
    <value>已簽貸款</value>
  </data>
  <data name="txtCompanyDtl" xml:space="preserve">
    <value>公司記錄</value>
  </data>
  <data name="global_msgMissData" xml:space="preserve">
    <value>請輸入所有資料</value>
  </data>
  <data name="global_msgSuccess" xml:space="preserve">
    <value>保存成功</value>
  </data>
  <data name="global_msgFail" xml:space="preserve">
    <value>保存失敗</value>
  </data>
  <data name="global_fnAuthentication" xml:space="preserve">
    <value>認証</value>
  </data>
  <data name="global_fnEditAgent" xml:space="preserve">
    <value>編輯戶口</value>
  </data>
  <data name="global_fnEditCredit" xml:space="preserve">
    <value>編輯信貸額</value>
  </data>
  <data name="global_fnLatestSalary" xml:space="preserve">
    <value>最近糧單</value>
  </data>
  <data name="global_fnNew2ndShareHolderGroup" xml:space="preserve">
    <value>新增二線股東組</value>
  </data>
  <data name="global_fnNewAuthorize" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="global_fnNewChipTranBook" xml:space="preserve">
    <value>新增存卡</value>
  </data>
  <data name="global_fnNewChipTranCash" xml:space="preserve">
    <value>新增存單</value>
  </data>
  <data name="global_fnNewCustWinLossTran" xml:space="preserve">
    <value>新增上下數</value>
  </data>
  <data name="global_fnNewExp" xml:space="preserve">
    <value>新增消費</value>
  </data>
  <data name="global_fnNewMarker" xml:space="preserve">
    <value>新增貸款</value>
  </data>
  <data name="global_fnNewUnderAgent" xml:space="preserve">
    <value>新增下線</value>
  </data>
  <data name="global_fnNewWinLossTran" xml:space="preserve">
    <value>新增客人</value>
  </data>
  <data name="global_fnSettleTranInstant" xml:space="preserve">
    <value>即出佣金</value>
  </data>
  <data name="global_fnStoreCTransferTo" xml:space="preserve">
    <value>內部轉帳</value>
  </data>
  <data name="global_fnWithdrawChipBook" xml:space="preserve">
    <value>綜合理財</value>
  </data>
  <data name="typeStatus_A" xml:space="preserve">
    <value>有效</value>
  </data>
  <data name="typeStatus_T" xml:space="preserve">
    <value>中止</value>
  </data>
  <data name="global_btnEdit" xml:space="preserve">
    <value>修改</value>
  </data>
  <data name="wDate" xml:space="preserve">
    <value>日期</value>
  </data>
  <data name="global_txtDatePeriod" xml:space="preserve">
    <value>時間段</value>
  </data>
  <data name="global_txtTo" xml:space="preserve">
    <value>至</value>
  </data>
  <data name="global_msgCheckFmDate" xml:space="preserve">
    <value>日期需少於 {0}</value>
  </data>
  <data name="global_msgCheckToDate" xml:space="preserve">
    <value>日期需大於 {0}</value>
  </data>
  <data name="global_txtAuComm" xml:space="preserve">
    <value>取佣</value>
  </data>
  <data name="global_txtAuExp" xml:space="preserve">
    <value>簽單</value>
  </data>
  <data name="global_txtAuIOU" xml:space="preserve">
    <value>簽貸款</value>
  </data>
  <data name="global_txtAuOther" xml:space="preserve">
    <value>其他</value>
  </data>
  <data name="global_txtAuRoom" xml:space="preserve">
    <value>取房</value>
  </data>
  <data name="global_txtAuShopping" xml:space="preserve">
    <value>購物</value>
  </data>
  <data name="global_txtAuStore" xml:space="preserve">
    <value>取存碼</value>
  </data>
  <data name="global_txtAuthIdentity" xml:space="preserve">
    <value>授權人身份</value>
  </data>
  <data name="global_txtAuTicket" xml:space="preserve">
    <value>取飛</value>
  </data>
  <data name="global_txtDateOfBirth" xml:space="preserve">
    <value>出生日期</value>
  </data>
  <data name="global_txtEffectYearMth" xml:space="preserve">
    <value>生效日期</value>
  </data>
  <data name="global_txtGunterPassword" xml:space="preserve">
    <value>密碼</value>
  </data>
  <data name="global_btnDisplayDrinkBalSummary" xml:space="preserve">
    <value>顯示食津餘數</value>
  </data>
  <data name="global_btnShownRead" xml:space="preserve">
    <value>顯示/更新</value>
  </data>
  <data name="global_txtAmountByCage" xml:space="preserve">
    <value>用戶各廳概況</value>
  </data>
  <data name="global_txtBFDrinkAmt" xml:space="preserve">
    <value>食津累數</value>
  </data>
  <data name="global_txtBFExpAmt" xml:space="preserve">
    <value>欠前消費</value>
  </data>
  <data name="global_txtBonusPoint" xml:space="preserve">
    <value>贈送積分</value>
  </data>
  <data name="global_txtCageCName" xml:space="preserve">
    <value>廳名</value>
  </data>
  <data name="global_txtChipTranTypeB" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="global_txtChipTranTypeI" xml:space="preserve">
    <value>存單</value>
  </data>
  <data name="global_txtCommission" xml:space="preserve">
    <value>佣金</value>
  </data>
  <data name="global_txtCountryStatus" xml:space="preserve">
    <value>環球概況</value>
  </data>
  <data name="global_txtDrinkNonShare" xml:space="preserve">
    <value>津貼(不共用)</value>
  </data>
  <data name="global_txtDrinkShare" xml:space="preserve">
    <value>津貼(共用)</value>
  </data>
  <data name="global_txtExpenseAmt" xml:space="preserve">
    <value>消費數</value>
  </data>
  <data name="global_txtIOUAmount" xml:space="preserve">
    <value>已簽貸款</value>
  </data>
  <data name="global_txtRollingAmt" xml:space="preserve">
    <value>轉碼數</value>
  </data>
  <data name="global_txtShowCommDrink" xml:space="preserve">
    <value>顯示佣金與津貼</value>
  </data>
  <data name="typeCompAll" xml:space="preserve">
    <value>集團</value>
  </data>
  <data name="global_btnAdv" xml:space="preserve">
    <value>進階</value>
  </data>
  <data name="global_btnCalRealTime" xml:space="preserve">
    <value>即時運算</value>
  </data>
  <data name="global_msgInfoCreditTotalBal" xml:space="preserve">
    <value>一般借貸結餘 = 信貸額結餘 + Ｕ可簽額結餘 + 個人借貸結餘 + 凍結額
*當海外或營運沒有信貸額，其已簽額亦會於一般借貸結餘扣除。</value>
  </data>
  <data name="global_txtAmount" xml:space="preserve">
    <value>金額</value>
  </data>
  <data name="global_txtBalance" xml:space="preserve">
    <value>結餘</value>
  </data>
  <data name="global_txtCapitalTranM" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="global_txtCash_CH" xml:space="preserve">
    <value>個人借貸</value>
  </data>
  <data name="global_txtCasinoCreditAmt" xml:space="preserve">
    <value>娛樂場額</value>
  </data>
  <data name="global_txtCreditAmtU" xml:space="preserve">
    <value>U可簽額</value>
  </data>
  <data name="global_txtCredited" xml:space="preserve">
    <value>已簽額</value>
  </data>
  <data name="global_txtCreditInfo" xml:space="preserve">
    <value>信貸額資料</value>
  </data>
  <data name="global_txtExpired" xml:space="preserve">
    <value>已過期</value>
  </data>
  <data name="global_txtForeign" xml:space="preserve">
    <value>海外</value>
  </data>
  <data name="global_txtIOUFreeze" xml:space="preserve">
    <value>凍結</value>
  </data>
  <data name="global_txtIOUStore" xml:space="preserve">
    <value>暫存/未取</value>
  </data>
  <data name="global_txtIOUTran_SO" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="global_txtNotExpired" xml:space="preserve">
    <value>未過期</value>
  </data>
  <data name="global_txtOperate" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="global_txtOutstandingGroup" xml:space="preserve">
    <value>已簽額</value>
  </data>
  <data name="global_txtSettleStatusOutstanding" xml:space="preserve">
    <value>未結算</value>
  </data>
  <data name="global_txtShowCreditWholeLineGrp" xml:space="preserve">
    <value>顯示全線借貸狀況</value>
  </data>
  <data name="global_txtSpecialIOULoan" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="global_txtSpecialIOUStore" xml:space="preserve">
    <value>存/未取</value>
  </data>
  <data name="global_txtTotalCredit" xml:space="preserve">
    <value>總信貸額</value>
  </data>
  <data name="global_txtTtlExpireOutstanding" xml:space="preserve">
    <value>過期</value>
  </data>
  <data name="global_txtTtlOverOutstanding" xml:space="preserve">
    <value>已超額</value>
  </data>
  <data name="global_txtAgentCard_Elite" xml:space="preserve">
    <value>尊華會卡</value>
  </data>
  <data name="global_txtAgentCard_EliteEmployee" xml:space="preserve">
    <value>尊華員工卡</value>
  </data>
  <data name="global_txtAgentCard_ElitePotential" xml:space="preserve">
    <value>尊華潛質卡</value>
  </data>
  <data name="global_txtAgentCard_Prepaid" xml:space="preserve">
    <value>預付卡</value>
  </data>
  <data name="global_txtAgentCard_SC" xml:space="preserve">
    <value>太陽城卡</value>
  </data>
  <data name="global_txtAgentCard_SCAdditonal" xml:space="preserve">
    <value>太陽城附屬卡</value>
  </data>
  <data name="global_txtEmptyString" xml:space="preserve">
    <value>(空白)</value>
  </data>
  <data name="global_txtGunnerMachine" xml:space="preserve">
    <value>路址機</value>
  </data>
  <data name="global_txtLive" xml:space="preserve">
    <value>現場</value>
  </data>
  <data name="txtCreditControlLst" xml:space="preserve">
    <value>信貸監控</value>
  </data>
  <data name="txtCreditControlContact" xml:space="preserve">
    <value>信貸監控-聯絡資料</value>
  </data>
  <data name="typeRMARKERLSTRPT_Report" xml:space="preserve">
    <value>借貸現況列表</value>
  </data>
  <data name="typeRMARKERRPT_Report" xml:space="preserve">
    <value>借貸現況表</value>
  </data>
  <data name="typeMARKERRPT_ReportGrp" xml:space="preserve">
    <value>借貸現況表</value>
  </data>
  <data name="typeCREDITCONTROLLST_Core" xml:space="preserve">
    <value>信貸監控</value>
  </data>
  <data name="txtAll" xml:space="preserve">
    <value>全部</value>
  </data>
  <data name="txtNewCase" xml:space="preserve">
    <value>新個案</value>
  </data>
  <data name="txtFollowCase" xml:space="preserve">
    <value>待跟進</value>
  </data>
  <data name="txtBookMarkCase" xml:space="preserve">
    <value>關注戶口</value>
  </data>
  <data name="txtBlackListCase" xml:space="preserve">
    <value>黑名單</value>
  </data>
  <data name="wTotalCreditDebit" xml:space="preserve">
    <value>總借貸</value>
  </data>
  <data name="wAlmostDue" xml:space="preserve">
    <value>到期數</value>
  </data>
  <data name="wTotalCredit" xml:space="preserve">
    <value>總信貸額</value>
  </data>
  <data name="wOverdue" xml:space="preserve">
    <value>已過期</value>
  </data>
  <data name="wPenalty" xml:space="preserve">
    <value>罰息</value>
  </data>
  <data name="txtContactPerson" xml:space="preserve">
    <value>聯絡人</value>
  </data>
  <data name="txtCreditRecord" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="txtAssetsRecord" xml:space="preserve">
    <value>資產</value>
  </data>
  <data name="txtContactRecord" xml:space="preserve">
    <value>聯絡記錄</value>
  </data>
  <data name="txtIntroducer" xml:space="preserve">
    <value>推薦人</value>
  </data>
  <data name="txtCredit" xml:space="preserve">
    <value>信貸額</value>
  </data>
  <data name="txtHistory" xml:space="preserve">
    <value>歷史</value>
  </data>
  <data name="txtOtherCageAppCredit" xml:space="preserve">
    <value>其他賭廳信貸額</value>
  </data>
  <data name="txtSO" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="wMthInterest" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="wHold" xml:space="preserve">
    <value>凍結借貸存款</value>
  </data>
  <data name="wIdentity" xml:space="preserve">
    <value>身份</value>
  </data>
  <data name="wPhoto" xml:space="preserve">
    <value>照片</value>
  </data>
  <data name="wRefNo" xml:space="preserve">
    <value>單號</value>
  </data>
  <data name="wBorrower" xml:space="preserve">
    <value>借款人</value>
  </data>
  <data name="wAmount" xml:space="preserve">
    <value>金額</value>
  </data>
  <data name="wOutStanding" xml:space="preserve">
    <value>倘欠</value>
  </data>
  <data name="wDaysPassed" xml:space="preserve">
    <value>已簽天數</value>
  </data>
  <data name="wLastSettleDate" xml:space="preserve">
    <value>最後還款日期</value>
  </data>
  <data name="wType" xml:space="preserve">
    <value>種類</value>
  </data>
  <data name="wValue" xml:space="preserve">
    <value>價值</value>
  </data>
  <data name="wRemark" xml:space="preserve">
    <value>備註</value>
  </data>
  <data name="wAttachFile" xml:space="preserve">
    <value>附件</value>
  </data>
  <data name="wContactDate" xml:space="preserve">
    <value>聯絡日期</value>
  </data>
  <data name="wContactPerson" xml:space="preserve">
    <value>接洽</value>
  </data>
  <data name="wContactMethod" xml:space="preserve">
    <value>聯絡方式</value>
  </data>
  <data name="wResponse" xml:space="preserve">
    <value>回應</value>
  </data>
  <data name="wSolution" xml:space="preserve">
    <value>方案</value>
  </data>
  <data name="wFollowDateTime" xml:space="preserve">
    <value>跟進日期</value>
  </data>
  <data name="wTotaldue" xml:space="preserve">
    <value>總欠款</value>
  </data>
  <data name="wTotalOverdue" xml:space="preserve">
    <value>總過期欠款</value>
  </data>
  <data name="wTotalPenalty" xml:space="preserve">
    <value>總罰息</value>
  </data>
  <data name="global_txtComplete" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="global_txtCutDateTime" xml:space="preserve">
    <value>截更時間</value>
  </data>
  <data name="global_txtInputDate" xml:space="preserve">
    <value>入數日期</value>
  </data>
  <data name="global_txtShiftNo" xml:space="preserve">
    <value>更期</value>
  </data>
  <data name="global_txtShiftCut" xml:space="preserve">
    <value>截更</value>
  </data>
  <data name="txtUsrLst" xml:space="preserve">
    <value>用戶管理</value>
  </data>
  <data name="typeUSRLST_Core" xml:space="preserve">
    <value>用戶管理</value>
  </data>
  <data name="wRoleCd" xml:space="preserve">
    <value>權限</value>
  </data>
  <data name="txtDept" xml:space="preserve">
    <value>部門</value>
  </data>
  <data name="wDtLastLogin" xml:space="preserve">
    <value>最後登入時間</value>
  </data>
  <data name="wName" xml:space="preserve">
    <value>名稱</value>
  </data>
  <data name="wUpdBy" xml:space="preserve">
    <value>經手人</value>
  </data>
  <data name="wUsrId" xml:space="preserve">
    <value>登入名稱</value>
  </data>
  <data name="txtInterestRateLst" xml:space="preserve">
    <value>存款利息管理</value>
  </data>
  <data name="typeINTERESTRATELST_Core" xml:space="preserve">
    <value>存款利息管理</value>
  </data>
  <data name="wYear" xml:space="preserve">
    <value>年</value>
  </data>
  <data name="txtYear" xml:space="preserve">
    <value>年份</value>
  </data>
  <data name="wCurrCodeName" xml:space="preserve">
    <value>貨幣</value>
  </data>
  <data name="wInterestRate" xml:space="preserve">
    <value>利率</value>
  </data>
  <data name="wMonth" xml:space="preserve">
    <value>月</value>
  </data>
  <data name="wUpdDt" xml:space="preserve">
    <value>經手日期</value>
  </data>
  <data name="txtAgentLst" xml:space="preserve">
    <value>戶口列表</value>
  </data>
  <data name="txtConfirmReservationRec" xml:space="preserve">
    <value>確認預約資料</value>
  </data>
  <data name="txtAgentRemarkHisLst" xml:space="preserve">
    <value>戶口備註管理</value>
  </data>
  <data name="txtCustomerLst" xml:space="preserve">
    <value>客人管理</value>
  </data>
  <data name="txtExpTranCardLst" xml:space="preserve">
    <value>卡消費管理</value>
  </data>
  <data name="txtExpTranLst" xml:space="preserve">
    <value>消費管理</value>
  </data>
  <data name="txtExpTranOtherLst" xml:space="preserve">
    <value>欠前消費管理</value>
  </data>
  <data name="txtNewAgentCodeLst" xml:space="preserve">
    <value>開戶格仔表</value>
  </data>
  <data name="txtRoleLst" xml:space="preserve">
    <value>權限管理</value>
  </data>
  <data name="typeAGENTLST_Core" xml:space="preserve">
    <value>戶口列表</value>
  </data>
  <data name="typeAGENTREMARKHISLST_Core" xml:space="preserve">
    <value>戶口備註管理</value>
  </data>
  <data name="typeCUSTOMERLST_Core" xml:space="preserve">
    <value>客人管理</value>
  </data>
  <data name="typeEXPTRANCARDLST_Core" xml:space="preserve">
    <value>卡消費管理</value>
  </data>
  <data name="typeEXPTRANLST_Core" xml:space="preserve">
    <value>消費管理</value>
  </data>
  <data name="typeEXPTRANOTHERLST_Core" xml:space="preserve">
    <value>欠前消費管理</value>
  </data>
  <data name="typeNEWAGENTCODELST_Core" xml:space="preserve">
    <value>開戶格仔表</value>
  </data>
  <data name="typeROLELST_Core" xml:space="preserve">
    <value>權限管理</value>
  </data>
  <data name="txtInterestRateDtl" xml:space="preserve">
    <value>存款利息</value>
  </data>
  <data name="mAgentCode" xml:space="preserve">
    <value>戶口號碼</value>
  </data>
  <data name="wComp" xml:space="preserve">
    <value>公司</value>
  </data>
  <data name="wExpType" xml:space="preserve">
    <value>消費類型</value>
  </data>
  <data name="wMemberCardNo" xml:space="preserve">
    <value>會員卡號碼</value>
  </data>
  <data name="wShopName" xml:space="preserve">
    <value>商戶名稱</value>
  </data>
  <data name="wSumAmount" xml:space="preserve">
    <value>總額</value>
  </data>
  <data name="wTranNo" xml:space="preserve">
    <value>交易編號</value>
  </data>
  <data name="global_txtNumber" xml:space="preserve">
    <value>第</value>
  </data>
  <data name="global_txtShift" xml:space="preserve">
    <value>更</value>
  </data>
  <data name="global_msgErrCannotBeNegativeOrZero" xml:space="preserve">
    <value>數值不可以是負數或為零</value>
  </data>
  <data name="global_msgErrDuplicateRecordInterestRate" xml:space="preserve">
    <value>不可以新增數據與現有地區,月份及年份相同.</value>
  </data>
  <data name="wYearMth" xml:space="preserve">
    <value>週期</value>
  </data>
  <data name="txtAgentDtl" xml:space="preserve">
    <value>戶口記錄</value>
  </data>
  <data name="txtAgentRemarkHisDtl" xml:space="preserve">
    <value>戶口備註記錄</value>
  </data>
  <data name="txtCustomerDtl" xml:space="preserve">
    <value>客人記錄</value>
  </data>
  <data name="txtExpTranCardDtl" xml:space="preserve">
    <value>卡消費記錄</value>
  </data>
  <data name="txtRoleDtl" xml:space="preserve">
    <value>權限管理</value>
  </data>
  <data name="txtUsrDtl" xml:space="preserve">
    <value>用戶管理</value>
  </data>
  <data name="wAgentCode" xml:space="preserve">
    <value>戶口號碼</value>
  </data>
  <data name="wInExp" xml:space="preserve">
    <value>内消费</value>
  </data>
  <data name="wOutExp" xml:space="preserve">
    <value>外消费</value>
  </data>
  <data name="global_txtLogin" xml:space="preserve">
    <value>用戶登入</value>
  </data>
  <data name="global_txtLoginID" xml:space="preserve">
    <value>名稱</value>
  </data>
  <data name="global_txtLoginPassword" xml:space="preserve">
    <value>密碼</value>
  </data>
  <data name="global_txtFixCurrCode" xml:space="preserve">
    <value>固定貨幣</value>
  </data>
  <data name="global_txtThisIsCounter" xml:space="preserve">
    <value>這是帳房柜面電腦</value>
  </data>
  <data name="global_txtCounter" xml:space="preserve">
    <value>櫃</value>
  </data>
  <data name="global_txtCurrCode" xml:space="preserve">
    <value>貨幣</value>
  </data>
  <data name="global_txtCurrRateDivide" xml:space="preserve">
    <value>兌換率(除)</value>
  </data>
  <data name="global_txtCurrRateProduct" xml:space="preserve">
    <value>兌換率(乘)</value>
  </data>
  <data name="global_txtExchangeCurrCode" xml:space="preserve">
    <value>兌換貨幣</value>
  </data>
  <data name="global_txtYearMth" xml:space="preserve">
    <value>週期</value>
  </data>
  <data name="typeCURRENCY_RATE_LST_Core" xml:space="preserve">
    <value>貨幣匯率管理</value>
  </data>
  <data name="wConfPwd" xml:space="preserve">
    <value>確認新密碼</value>
  </data>
  <data name="wNewPwd" xml:space="preserve">
    <value>新密碼</value>
  </data>
  <data name="wStaffSMS" xml:space="preserve">
    <value>SMS號碼</value>
  </data>
  <data name="wTerminationDate" xml:space="preserve">
    <value>終止日期</value>
  </data>
  <data name="txtInputPeriod" xml:space="preserve">
    <value>輸入期</value>
  </data>
  <data name="txtProcessPeriod" xml:space="preserve">
    <value>執行期</value>
  </data>
  <data name="txtReturnAmount" xml:space="preserve">
    <value>歸還額</value>
  </data>
  <data name="txtBFAmt" xml:space="preserve">
    <value>前欠費</value>
  </data>
  <data name="txtOutstandAmt" xml:space="preserve">
    <value>餘額</value>
  </data>
  <data name="txtAgentCode" xml:space="preserve">
    <value>戶口</value>
  </data>
  <data name="txtBFAmtHKD" xml:space="preserve">
    <value>HKD前欠費</value>
  </data>
  <data name="wCurrRate" xml:space="preserve">
    <value>兌換率</value>
  </data>
  <data name="txtCurrRateDesc" xml:space="preserve">
    <value>換率為匯至港幣換率</value>
  </data>
  <data name="wNickName" xml:space="preserve">
    <value>別名</value>
  </data>
  <data name="wIDNo" xml:space="preserve">
    <value>證件號碼</value>
  </data>
  <data name="wFeatureRemark" xml:space="preserve">
    <value>客人特徵</value>
  </data>
  <data name="wCurDateTime" xml:space="preserve">
    <value>時間</value>
  </data>
  <data name="wHavePic" xml:space="preserve">
    <value>有照片</value>
  </data>
  <data name="wLikeRemark" xml:space="preserve">
    <value>客人喜好</value>
  </data>
  <data name="wCustName" xml:space="preserve">
    <value>客人名稱</value>
  </data>
  <data name="wExpDesc" xml:space="preserve">
    <value>消費</value>
  </data>
  <data name="wExpTypeCode" xml:space="preserve">
    <value>消費項目</value>
  </data>
  <data name="wPrice" xml:space="preserve">
    <value>單價</value>
  </data>
  <data name="wRoomBookDt" xml:space="preserve">
    <value>訂房時間</value>
  </data>
  <data name="wRoomCfmCode" xml:space="preserve">
    <value>確認號碼</value>
  </data>
  <data name="wRoomCheckInDt" xml:space="preserve">
    <value>入住日期</value>
  </data>
  <data name="wRoomDeptDt" xml:space="preserve">
    <value>退房日期</value>
  </data>
  <data name="wRoomExpAmt" xml:space="preserve">
    <value>房消費</value>
  </data>
  <data name="wRoomNo" xml:space="preserve">
    <value>房號</value>
  </data>
  <data name="wUnit" xml:space="preserve">
    <value>數量</value>
  </data>
  <data name="wVoucherDt" xml:space="preserve">
    <value>單日期</value>
  </data>
  <data name="wVoucherNo" xml:space="preserve">
    <value>單編號</value>
  </data>
  <data name="txtLineGrp" xml:space="preserve">
    <value>線組</value>
  </data>
  <data name="txtReadDept" xml:space="preserve">
    <value>顯示部門</value>
  </data>
  <data name="wCrtBy" xml:space="preserve">
    <value>建立者</value>
  </data>
  <data name="wCrtDt" xml:space="preserve">
    <value>建立日期</value>
  </data>
  <data name="wForCompNo" xml:space="preserve">
    <value>顯示公司</value>
  </data>
  <data name="wImportance" xml:space="preserve">
    <value>重要性</value>
  </data>
  <data name="wUpdByLastCName" xml:space="preserve">
    <value>最後經手人</value>
  </data>
  <data name="wEffectYearMth" xml:space="preserve">
    <value>有效日期</value>
  </data>
  <data name="wSex" xml:space="preserve">
    <value>性別</value>
  </data>
  <data name="txtAgentType" xml:space="preserve">
    <value>戶口類型</value>
  </data>
  <data name="txtUnderAgent" xml:space="preserve">
    <value>下線</value>
  </data>
  <data name="txtUpperAgent" xml:space="preserve">
    <value>上線</value>
  </data>
  <data name="wAccountType" xml:space="preserve">
    <value>會員級別</value>
  </data>
  <data name="wAgentLevel" xml:space="preserve">
    <value>層數</value>
  </data>
  <data name="txtExpSite" xml:space="preserve">
    <value>消費場地</value>
  </data>
  <data name="wInputDate" xml:space="preserve">
    <value>入數日期</value>
  </data>
  <data name="wShift" xml:space="preserve">
    <value>更期</value>
  </data>
  <data name="wHotelType" xml:space="preserve">
    <value>酒店類型</value>
  </data>
  <data name="wRoomType" xml:space="preserve">
    <value>房間類型</value>
  </data>
  <data name="wDept" xml:space="preserve">
    <value>部門</value>
  </data>
  <data name="txtRefresh" xml:space="preserve">
    <value>刷新</value>
  </data>
  <data name="txtHKDFxRate" xml:space="preserve">
    <value>港幣兌換率</value>
  </data>
  <data name="txtRMBFxRate" xml:space="preserve">
    <value>人民幣兌換率</value>
  </data>
  <data name="wBirthDate" xml:space="preserve">
    <value>出生日期</value>
  </data>
  <data name="wBirthNationality" xml:space="preserve">
    <value>出生地點</value>
  </data>
  <data name="wNationality" xml:space="preserve">
    <value>國籍</value>
  </data>
  <data name="global_btnClear" xml:space="preserve">
    <value>清除</value>
  </data>
  <data name="global_btnUpload" xml:space="preserve">
    <value>上傳</value>
  </data>
  <data name="txtUploadAppForm" xml:space="preserve">
    <value>申請表</value>
  </data>
  <data name="txtUploadID" xml:space="preserve">
    <value>身份證明文件</value>
  </data>
  <data name="txtUploadPassport" xml:space="preserve">
    <value>護照</value>
  </data>
  <data name="txtUploadPhoto" xml:space="preserve">
    <value>照片</value>
  </data>
  <data name="wAddress" xml:space="preserve">
    <value>聯絡地址</value>
  </data>
  <data name="wIDType" xml:space="preserve">
    <value>證件類型</value>
  </data>
  <data name="wOccupation" xml:space="preserve">
    <value>職業</value>
  </data>
  <data name="wPost" xml:space="preserve">
    <value>職位</value>
  </data>
  <data name="global_msgImportance" xml:space="preserve">
    <value>5為最重要,將會在所有輸入版面顯示</value>
  </data>
  <data name="global_txtDept" xml:space="preserve">
    <value>部門</value>
  </data>
  <data name="global_btnAddOneDay" xml:space="preserve">
    <value>+1 日</value>
  </data>
  <data name="global_btnAddOneMonth" xml:space="preserve">
    <value>+1 月</value>
  </data>
  <data name="global_btnAddOneWeek" xml:space="preserve">
    <value>+1 週</value>
  </data>
  <data name="global_btnNever" xml:space="preserve">
    <value>永不</value>
  </data>
  <data name="global_btnStop" xml:space="preserve">
    <value>停用</value>
  </data>
  <data name="global_txtFilter" xml:space="preserve">
    <value>過濾器</value>
  </data>
  <data name="global_txtLevel" xml:space="preserve">
    <value>層</value>
  </data>
  <data name="global_txtNameHidden" xml:space="preserve">
    <value>包括下線(不顯示下線名)</value>
  </data>
  <data name="global_txtNameShow" xml:space="preserve">
    <value>包括下線(顯示下線名)</value>
  </data>
  <data name="global_txtStanda" xml:space="preserve">
    <value>單一</value>
  </data>
  <data name="global_txtUnSelectAll" xml:space="preserve">
    <value>不選</value>
  </data>
  <data name="typeCreditControl_A" xml:space="preserve">
    <value>待跟進</value>
  </data>
  <data name="typeCreditControl_T" xml:space="preserve">
    <value>已跟進</value>
  </data>
  <data name="txtCutOffDate" xml:space="preserve">
    <value>截數日期</value>
  </data>
  <data name="wIOUType" xml:space="preserve">
    <value>借貸類</value>
  </data>
  <data name="wOverdueDay" xml:space="preserve">
    <value>過期日數</value>
  </data>
  <data name="global_optCashType_CH" xml:space="preserve">
    <value>個人借貸</value>
  </data>
  <data name="global_optCashType_IOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="global_optMarker_C" xml:space="preserve">
    <value>已歸還</value>
  </data>
  <data name="global_optMarker_O" xml:space="preserve">
    <value>未歸還</value>
  </data>
  <data name="txtSearchType" xml:space="preserve">
    <value>搜尋類型</value>
  </data>
  <data name="global_optMarker_M" xml:space="preserve">
    <value>過期M</value>
  </data>
  <data name="txtIncludePartner" xml:space="preserve">
    <value>包括外柜數</value>
  </data>
  <data name="wOtherSocialMedia" xml:space="preserve">
    <value>其它電子聯絡方式</value>
  </data>
  <data name="wPinyin" xml:space="preserve">
    <value>拼音</value>
  </data>
  <data name="wProvince" xml:space="preserve">
    <value>省份</value>
  </data>
  <data name="wQQ" xml:space="preserve">
    <value>QQ</value>
  </data>
  <data name="wShareJoinDate" xml:space="preserve">
    <value>入股日期</value>
  </data>
  <data name="wSMS_Remark" xml:space="preserve">
    <value>短訊</value>
  </data>
  <data name="wStoreLock" xml:space="preserve">
    <value>鎖卡</value>
  </data>
  <data name="wStoreNegative" xml:space="preserve">
    <value>可負數卡</value>
  </data>
  <data name="wStoreNoInt" xml:space="preserve">
    <value>停息</value>
  </data>
  <data name="wTelOther" xml:space="preserve">
    <value>其他電話</value>
  </data>
  <data name="wTelSMS" xml:space="preserve">
    <value>存款號碼</value>
  </data>
  <data name="wTelSMS_Exp" xml:space="preserve">
    <value>消費號碼</value>
  </data>
  <data name="wTelSMS_Foreign" xml:space="preserve">
    <value>海外圍號碼</value>
  </data>
  <data name="wTelSMS_IOU" xml:space="preserve">
    <value>貸款號碼</value>
  </data>
  <data name="wTelSMS_OpIntroducer" xml:space="preserve">
    <value>營運來貨號碼</value>
  </data>
  <data name="wTelSMS_Roll" xml:space="preserve">
    <value>轉碼號碼</value>
  </data>
  <data name="wUpLvlAgent" xml:space="preserve">
    <value>上層代理</value>
  </data>
  <data name="wWeChat" xml:space="preserve">
    <value>微信</value>
  </data>
  <data name="wWhatsapp" xml:space="preserve">
    <value>What''s app</value>
  </data>
  <data name="txtArea" xml:space="preserve">
    <value>地區</value>
  </data>
  <data name="txtExpAutoTransfer" xml:space="preserve">
    <value>消費自動轉賬</value>
  </data>
  <data name="txtExpenseTerminated" xml:space="preserve">
    <value>停止消費</value>
  </data>
  <data name="txtFrequency" xml:space="preserve">
    <value>頻率</value>
  </data>
  <data name="txtIsBindingMobileSunApps" xml:space="preserve">
    <value>綁定太陽城手機應用程式</value>
  </data>
  <data name="txtIsNameCardProvided" xml:space="preserve">
    <value>提供卡片</value>
  </data>
  <data name="txtNumberOfTimes" xml:space="preserve">
    <value>次數</value>
  </data>
  <data name="txtOther" xml:space="preserve">
    <value>其他</value>
  </data>
  <data name="txtOtherCage" xml:space="preserve">
    <value>其他所屬貴賓廳</value>
  </data>
  <data name="txtOtherCageCredit" xml:space="preserve">
    <value>其他貴賓信用額</value>
  </data>
  <data name="txtOtherCageType" xml:space="preserve">
    <value>該貴賓廳之身份</value>
  </data>
  <data name="txtOverseasVIPExp" xml:space="preserve">
    <value>曾經到海外出圍的經驗</value>
  </data>
  <data name="txtRelativesEmployedBySuncityGroup" xml:space="preserve">
    <value>於集團是否有親屬</value>
  </data>
  <data name="txtStatusNo" xml:space="preserve">
    <value>否</value>
  </data>
  <data name="txtStatusYes" xml:space="preserve">
    <value>是</value>
  </data>
  <data name="wAgentCreateAmt" xml:space="preserve">
    <value>開戶金額</value>
  </data>
  <data name="wAssetsReport" xml:space="preserve">
    <value>資產總值(港幣)</value>
  </data>
  <data name="wIntroducerCodeIn1" xml:space="preserve">
    <value>介紹人1</value>
  </data>
  <data name="wIntroducerCodeIn2" xml:space="preserve">
    <value>介紹人2</value>
  </data>
  <data name="wIsDirectCreditAcc" xml:space="preserve">
    <value>公司授信戶口</value>
  </data>
  <data name="txtIsDirectCreditAcc" xml:space="preserve">
    <value>直接授信</value>
  </data>
  <data name="wLang1" xml:space="preserve">
    <value>主語言</value>
  </data>
  <data name="wTelSMS_CHN" xml:space="preserve">
    <value>中國(+86)</value>
  </data>
  <data name="wTelSMS_HK" xml:space="preserve">
    <value>香港(+852)</value>
  </data>
  <data name="wTelSMS_MAC" xml:space="preserve">
    <value>澳門(+853)</value>
  </data>
  <data name="wTerminateDate" xml:space="preserve">
    <value>終止日期</value>
  </data>
  <data name="wWrittenLang" xml:space="preserve">
    <value>文字訊息</value>
  </data>
  <data name="global_txtAddNewCurr" xml:space="preserve">
    <value>新增貨幣</value>
  </data>
  <data name="global_txtCurrCName" xml:space="preserve">
    <value>貨幣中文名</value>
  </data>
  <data name="global_txtCurrEName" xml:space="preserve">
    <value>貨幣英文名</value>
  </data>
  <data name="global_txtCurrencyCode" xml:space="preserve">
    <value>貨幣碼</value>
  </data>
  <data name="global_txtToCurrCode" xml:space="preserve">
    <value>兌換貨幣</value>
  </data>
  <data name="txtChipTranB" xml:space="preserve">
    <value>存卡管理</value>
  </data>
  <data name="typeSTORE_Core" xml:space="preserve">
    <value>存取</value>
  </data>
  <data name="typeCHIPTRAN_B_LST_Core" xml:space="preserve">
    <value>存卡管理</value>
  </data>
  <data name="global_msgInvalidInputData" xml:space="preserve">
    <value>輸入資料不正確</value>
  </data>
  <data name="wDepositor" xml:space="preserve">
    <value>存款人</value>
  </data>
  <data name="wCashChip_Tenk" xml:space="preserve">
    <value>現碼(萬)</value>
  </data>
  <data name="wCashChip_ToNew_Tenk" xml:space="preserve">
    <value>結存(萬)</value>
  </data>
  <data name="wTranType" xml:space="preserve">
    <value>類型</value>
  </data>
  <data name="typeChipTran_CR" xml:space="preserve">
    <value>提取</value>
  </data>
  <data name="typeChipTran_CS" xml:space="preserve">
    <value>存入</value>
  </data>
  <data name="global_txtMissingIVRPwd" xml:space="preserve">
    <value>未設密碼</value>
  </data>
  <data name="global_wStoreLock" xml:space="preserve">
    <value>鎖卡</value>
  </data>
  <data name="typeAGENTFIRSTCHECKINRPT_ReportGrp" xml:space="preserve">
    <value>戶口開場查詢資料列表</value>
  </data>
  <data name="typeAGENTINFORPT_ReportGrp" xml:space="preserve">
    <value>戶口資料表</value>
  </data>
  <data name="typeAGENTLEVELLSTRPT_ReportGrp" xml:space="preserve">
    <value>戶口層級樹列表</value>
  </data>
  <data name="typeAGEXWITHOUTROLSTRPT_ReportGrp" xml:space="preserve">
    <value>消費報表</value>
  </data>
  <data name="typeAGWLYEARMTHRPT_ReportGrp" xml:space="preserve">
    <value>上下數月結總表</value>
  </data>
  <data name="typeCHIPSTORE1RPT_Report" xml:space="preserve">
    <value>存碼細數表</value>
  </data>
  <data name="typeRCHIPTRANRPT_Report" xml:space="preserve">
    <value>存碼出入數表</value>
  </data>
  <data name="typeCOUNTERBALAUDITRPT_ReportGrp" xml:space="preserve">
    <value>賬房銀頭報表</value>
  </data>
  <data name="typeCREDITCONTROLRPT_ReportGrp" xml:space="preserve">
    <value>信用監控列表</value>
  </data>
  <data name="typeCREDITTRANRPT_ReportGrp" xml:space="preserve">
    <value>借貸批額</value>
  </data>
  <data name="typeCRMAGENTRPT_ReportGrp" xml:space="preserve">
    <value>市場部報表</value>
  </data>
  <data name="typeCUSTSTAYINFORPT_ReportGrp" xml:space="preserve">
    <value>戶口留擡時間報表</value>
  </data>
  <data name="typeCUSTWINLOSSRPT_ReportGrp" xml:space="preserve">
    <value>上下數報表</value>
  </data>
  <data name="typeDEPOSITCONDRPT_ReportGrp" xml:space="preserve">
    <value>存碼報表</value>
  </data>
  <data name="typeEXPENSEBFRPT_ReportGrp" xml:space="preserve">
    <value>欠前消費報表</value>
  </data>
  <data name="typeFOODDRINKBFRPT_ReportGrp" xml:space="preserve">
    <value>食津累數報表</value>
  </data>
  <data name="typeFORSPECMARKRPT_ReportGrp" xml:space="preserve">
    <value>海外借貸報表</value>
  </data>
  <data name="typeGAMINGCOMMISSIONRPT_ReportGrp" xml:space="preserve">
    <value>J11及J12博彩佣金報表</value>
  </data>
  <data name="typeINTERESTRATELSTRPT_ReportGrp" xml:space="preserve">
    <value>月結派息總報表</value>
  </data>
  <data name="typeIOUPENALTYSTARPT_ReportGrp" xml:space="preserve">
    <value>罰息現況報表</value>
  </data>
  <data name="typeIOUPENASETTLERPT_ReportGrp" xml:space="preserve">
    <value>罰息歸還報表</value>
  </data>
  <data name="typeMTEADJREPFORACRPT_ReportGrp" xml:space="preserve">
    <value>月結前調整報表</value>
  </data>
  <data name="typeOPERATEEXTERNALRPT_ReportGrp" xml:space="preserve">
    <value>私營報表</value>
  </data>
  <data name="typeRAGENTINFORPT_Report" xml:space="preserve">
    <value>戶口資料表</value>
  </data>
  <data name="typeRAGENTLEVELLSTRPT_Report" xml:space="preserve">
    <value>戶口層級樹列表</value>
  </data>
  <data name="typeRAGEXWITHOUTROLLSTRPT_Report" xml:space="preserve">
    <value>消費報表</value>
  </data>
  <data name="typeRAGFIRCHECKININRPT_Report" xml:space="preserve">
    <value>戶口開場查詢資料列表</value>
  </data>
  <data name="typeRAGWLYEARMTHRPT_Report" xml:space="preserve">
    <value>上下數月結總表</value>
  </data>
  <data name="typeRCOUNTERBALAUDITRPT_Report" xml:space="preserve">
    <value>賬房銀頭報表</value>
  </data>
  <data name="typeRCREDITCONTROLRPT_Report" xml:space="preserve">
    <value>信用監控列表</value>
  </data>
  <data name="typeRCRMAGENTRPT_Report" xml:space="preserve">
    <value>過濾器</value>
  </data>
  <data name="typeRCUSTSTAYINFORPT_Report" xml:space="preserve">
    <value>戶口留擡時間報表</value>
  </data>
  <data name="typeRCUSTWINLOSSRPT_Report" xml:space="preserve">
    <value>上下數報表</value>
  </data>
  <data name="typeREMITTANCERPT_ReportGrp" xml:space="preserve">
    <value>匯款報表</value>
  </data>
  <data name="typeREMOTEOPERATIONRPT_ReportGrp" xml:space="preserve">
    <value>遙距指令報表</value>
  </data>
  <data name="typeREXPENSEBFRPT_Report" xml:space="preserve">
    <value>欠前消費報表</value>
  </data>
  <data name="typeREXPENSEBFSUMRPT_Report" xml:space="preserve">
    <value>下線欠前消費報表</value>
  </data>
  <data name="typeRFOODDRINKBFRPT_Report" xml:space="preserve">
    <value>食津累數報表</value>
  </data>
  <data name="typeRFORSPECIALMARKERRPT_Report" xml:space="preserve">
    <value>借貸現況表</value>
  </data>
  <data name="typeRFORSPECMARKLSTRPT_Report" xml:space="preserve">
    <value>借貸現況列表</value>
  </data>
  <data name="typeRFORSPECMARKTRANRPT_Report" xml:space="preserve">
    <value>借貸提存表</value>
  </data>
  <data name="typeRGAMINGCOMMISRPT_Report" xml:space="preserve">
    <value>J11及J12博彩佣金報表</value>
  </data>
  <data name="typeRINTERESTRATERPT_Report" xml:space="preserve">
    <value>月結派息總報表</value>
  </data>
  <data name="typeRIOUPENALTYSTARPT_Report" xml:space="preserve">
    <value>罰息現況報表</value>
  </data>
  <data name="typeRIOUPENASETTLERPT_Report" xml:space="preserve">
    <value>罰息歸還報表</value>
  </data>
  <data name="typeRMTEADJREPFORACRPT_Report" xml:space="preserve">
    <value>會計部用</value>
  </data>
  <data name="typeROLLING1RPT_Report" xml:space="preserve">
    <value>轉碼總數表</value>
  </data>
  <data name="typeROLLING2RPT_Report" xml:space="preserve">
    <value>轉碼細數表</value>
  </data>
  <data name="typeROLLINGRPT_ReportGrp" xml:space="preserve">
    <value>轉碼報表</value>
  </data>
  <data name="typeROPERATEEXTERNALRPT_Report" xml:space="preserve">
    <value>私營報表</value>
  </data>
  <data name="typeROVERPT_ReportGrp" xml:space="preserve">
    <value>巨額報表</value>
  </data>
  <data name="typeRPTCREDITTRANRPT_Report" xml:space="preserve">
    <value>借貸批額報表</value>
  </data>
  <data name="typeRREMITTANCERPT_Report" xml:space="preserve">
    <value>匯款報表</value>
  </data>
  <data name="typeRREMOTEOPERATIONRPT_Report" xml:space="preserve">
    <value>遙距指令報表</value>
  </data>
  <data name="typeRROLLINGDAILYRPT_Report" xml:space="preserve">
    <value>轉碼日報表</value>
  </data>
  <data name="typeRROLLINGLISTDTLRPT_Report" xml:space="preserve">
    <value>轉碼細數列表</value>
  </data>
  <data name="typeRROVETRANRPT_Report" xml:space="preserve">
    <value>巨額報表</value>
  </data>
  <data name="typeCHIPSTORE2RPT_Report" xml:space="preserve">
    <value>存碼現況總數表</value>
  </data>
  <data name="typeRRPTMTHINTERESTRPT_Report" xml:space="preserve">
    <value>已派月息報表</value>
  </data>
  <data name="typeRSALARYSETTLELSTRPT_Report" xml:space="preserve">
    <value>月結出量總表</value>
  </data>
  <data name="typeRSETTTRANINSLSTRPT_Report" xml:space="preserve">
    <value>即出報表</value>
  </data>
  <data name="typeRSMSTYPERPT_Report" xml:space="preserve">
    <value>戶口SMS類型表</value>
  </data>
  <data name="typeRSPECIALMARKERRPT_Report" xml:space="preserve">
    <value>借貸現況表</value>
  </data>
  <data name="typeRSPECMARKLSTRPT_Report" xml:space="preserve">
    <value>借貸現況列表</value>
  </data>
  <data name="typeRSPECMARKTRANRPT_Report" xml:space="preserve">
    <value>借貸提存表</value>
  </data>
  <data name="typeRSUGTRANSTATRPT_Report" xml:space="preserve">
    <value>客人特徵及部門備註統計表</value>
  </data>
  <data name="typeRTOPVIPROLLTREERPT_Report" xml:space="preserve">
    <value>VIP轉碼報表</value>
  </data>
  <data name="typeRUSERENQUIRYLOGRPT_Report" xml:space="preserve">
    <value>用戶監察表</value>
  </data>
  <data name="typeRVIPINOUTTIMERPT_Report" xml:space="preserve">
    <value>VIP進出時間報表</value>
  </data>
  <data name="typeRVIPUSAGERPT_Report" xml:space="preserve">
    <value>貴賓房使用率報表</value>
  </data>
  <data name="typeSALARYSETTLELSTRPT_ReportGrp" xml:space="preserve">
    <value>月結出量總表</value>
  </data>
  <data name="typeSETTLEINSTANTLSTRPT_ReportGrp" xml:space="preserve">
    <value>即出報表</value>
  </data>
  <data name="typeSMSTYPERPT_ReportGrp" xml:space="preserve">
    <value>戶口SMS類型資料表</value>
  </data>
  <data name="typeSPECIALMARKERRPT_ReportGrp" xml:space="preserve">
    <value>營運借貸報表</value>
  </data>
  <data name="typeSUGTRANSTATRPT_ReportGrp" xml:space="preserve">
    <value>客人特徵及部門備註統計表</value>
  </data>
  <data name="typeTOPVIPROLLTREERPT_ReportGrp" xml:space="preserve">
    <value>VIP轉碼報表</value>
  </data>
  <data name="typeUSERENQUIRYLOGLSTRPT_ReportGrp" xml:space="preserve">
    <value>用戶監察表</value>
  </data>
  <data name="typeVIPINOUTTIMERPT_ReportGrp" xml:space="preserve">
    <value>VIP進出時間報表</value>
  </data>
  <data name="typeVIPUSAGERPT_ReportGrp" xml:space="preserve">
    <value>貴賓房使用率報表</value>
  </data>
  <data name="typeRMARKERLSTTRANRPT_Report" xml:space="preserve">
    <value>借貸還款列表</value>
  </data>
  <data name="typeRMARKERTRANRPT_Report" xml:space="preserve">
    <value>借貸提存表</value>
  </data>
  <data name="typeRMARKRETTYLSTRPT_Report" xml:space="preserve">
    <value>借貸歸還類別報表</value>
  </data>
  <data name="global_txtAgentAccountType1" xml:space="preserve">
    <value>太陽客戶</value>
  </data>
  <data name="global_txtAgentAccountType2" xml:space="preserve">
    <value>金太陽</value>
  </data>
  <data name="global_txtAgentAccountType3" xml:space="preserve">
    <value>卓越</value>
  </data>
  <data name="global_txtAgentAccountType4" xml:space="preserve">
    <value>非凡</value>
  </data>
  <data name="global_txtAgentAccountType5" xml:space="preserve">
    <value>奇蹟</value>
  </data>
  <data name="global_txtAgentAccountType6" xml:space="preserve">
    <value>傳奇</value>
  </data>
  <data name="global_txtAgentAccountType7" xml:space="preserve">
    <value>至尊</value>
  </data>
  <data name="wHoldCommission" xml:space="preserve">
    <value>凍結出佣</value>
  </data>
  <data name="wIsDelay" xml:space="preserve">
    <value>延期歸還</value>
  </data>
  <data name="wReqNotification" xml:space="preserve">
    <value>訊息提醒</value>
  </data>
  <data name="global_btnSameAbove" xml:space="preserve">
    <value>同上</value>
  </data>
  <data name="global_msgInfoTelFormat" xml:space="preserve">
    <value>格式: +(國家號碼)(電話號碼), 例子: +85223456789</value>
  </data>
  <data name="txtAcctFormNumber" xml:space="preserve">
    <value>開戶編號</value>
  </data>
  <data name="txtAgentCodeOld" xml:space="preserve">
    <value>原戶口號碼</value>
  </data>
  <data name="txtCashIOUContractNo" xml:space="preserve">
    <value>個人借貸合同號</value>
  </data>
  <data name="txtIDExpireDate" xml:space="preserve">
    <value>證件到期日</value>
  </data>
  <data name="txtIOUContractNo" xml:space="preserve">
    <value>借貸合同號</value>
  </data>
  <data name="txtSmsTelSingleRoom" xml:space="preserve">
    <value>短訊使用單一號碼</value>
  </data>
  <data name="wAgentCreateDate" xml:space="preserve">
    <value>開戶日期</value>
  </data>
  <data name="wAgentType" xml:space="preserve">
    <value>戶口類型</value>
  </data>
  <data name="wCity" xml:space="preserve">
    <value>城市</value>
  </data>
  <data name="wCounty" xml:space="preserve">
    <value>縣</value>
  </data>
  <data name="wIntroducerStaff" xml:space="preserve">
    <value>員工介紹人</value>
  </data>
  <data name="wIsShareGrp" xml:space="preserve">
    <value>股東組</value>
  </data>
  <data name="wLevelType" xml:space="preserve">
    <value>級別</value>
  </data>
  <data name="wLine" xml:space="preserve">
    <value>Line</value>
  </data>
  <data name="txtDateRange" xml:space="preserve">
    <value>日期範圍</value>
  </data>
  <data name="txtMeeting" xml:space="preserve">
    <value>會面</value>
  </data>
  <data name="txtInstantCommCard" xml:space="preserve">
    <value>即出咭戶口</value>
  </data>
  <data name="txtMinCheckInCapital" xml:space="preserve">
    <value>開場最低金額(萬)</value>
  </data>
  <data name="txtReport" xml:space="preserve">
    <value>報表</value>
  </data>
  <data name="wLineGrp" xml:space="preserve">
    <value>外圍代號</value>
  </data>
  <data name="wUsrName" xml:space="preserve">
    <value>用戶名稱</value>
  </data>
  <data name="txtCreditControlShowAll" xml:space="preserve">
    <value>顯示所有(包括壞賬及凍結)</value>
  </data>
  <data name="txtDateTo" xml:space="preserve">
    <value>至</value>
  </data>
  <data name="txtDirectCreditAcc" xml:space="preserve">
    <value>只顯示公司授信戶口</value>
  </data>
  <data name="txtFunction" xml:space="preserve">
    <value>功能</value>
  </data>
  <data name="txtGift" xml:space="preserve">
    <value>禮品</value>
  </data>
  <data name="txtIncludeTerminalAgent" xml:space="preserve">
    <value>包括已終止戶口</value>
  </data>
  <data name="txtIncludeTerminalHistory" xml:space="preserve">
    <value>包括己終止歷史記錄</value>
  </data>
  <data name="txtOnlyBadDebt" xml:space="preserve">
    <value>只顯示壞賬</value>
  </data>
  <data name="txtOnlyFreeze" xml:space="preserve">
    <value>只顯示凍結</value>
  </data>
  <data name="txtShowCashLoanInt" xml:space="preserve">
    <value>個人借貸(萬)</value>
  </data>
  <data name="txtShowForeignCredit" xml:space="preserve">
    <value>海外借貸(萬)</value>
  </data>
  <data name="txtShowMthInt" xml:space="preserve">
    <value>月息(萬)</value>
  </data>
  <data name="txtShowShareCredit" xml:space="preserve">
    <value>股本(萬)</value>
  </data>
  <data name="txtShowUCredit" xml:space="preserve">
    <value>可簽額(萬)</value>
  </data>
  <data name="txtShowUCredit_Share" xml:space="preserve">
    <value>U可簽額(萬)</value>
  </data>
  <data name="txtShowYellowCredit" xml:space="preserve">
    <value>營運借貸(萬)</value>
  </data>
  <data name="wReturnDayRemind" xml:space="preserve">
    <value>還款日提醒</value>
  </data>
  <data name="txtPhone" xml:space="preserve">
    <value>電話</value>
  </data>
  <data name="global_txtGenerateData" xml:space="preserve">
    <value>生成數據(預視用)</value>
  </data>
  <data name="global_txtInterRate" xml:space="preserve">
    <value>確認此月份派息</value>
  </data>
  <data name="global_txtPreInfo" xml:space="preserve">
    <value>顯示預示材料</value>
  </data>
  <data name="action_EDIT_type" xml:space="preserve">
    <value>修改</value>
  </data>
  <data name="action_EXPORT_type" xml:space="preserve">
    <value>匯出</value>
  </data>
  <data name="action_INSERT_type" xml:space="preserve">
    <value>新增</value>
  </data>
  <data name="action_LOADDATA_type" xml:space="preserve">
    <value>LOADDATA</value>
  </data>
  <data name="action_MENU_type" xml:space="preserve">
    <value>菜單</value>
  </data>
  <data name="action_PRINT_type" xml:space="preserve">
    <value>列印</value>
  </data>
  <data name="action_REFRESH_type" xml:space="preserve">
    <value>重新搜尋</value>
  </data>
  <data name="action_REPORTGRP_type" xml:space="preserve">
    <value>報表GRP</value>
  </data>
  <data name="action_REPORT_type" xml:space="preserve">
    <value>報表</value>
  </data>
  <data name="action_RESET_type" xml:space="preserve">
    <value>重置</value>
  </data>
  <data name="action_SEARCH_type" xml:space="preserve">
    <value>搜尋</value>
  </data>
  <data name="action_UPDATE_type" xml:space="preserve">
    <value>更新</value>
  </data>
  <data name="global_btnAddNewBFExp" xml:space="preserve">
    <value>新增欠費</value>
  </data>
  <data name="global_btnAddNewBFExpRtn" xml:space="preserve">
    <value>新增欠費歸還</value>
  </data>
  <data name="txtAddCapital" xml:space="preserve">
    <value>加彩</value>
  </data>
  <data name="txtChipTranTypeB" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="txtRoll" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="txtRptByDay" xml:space="preserve">
    <value>日表</value>
  </data>
  <data name="txtRptByMonth" xml:space="preserve">
    <value>月表</value>
  </data>
  <data name="txtRptByWeek" xml:space="preserve">
    <value>週表</value>
  </data>
  <data name="txtStore_Marker" xml:space="preserve">
    <value>存M</value>
  </data>
  <data name="wRemittanceDeposit" xml:space="preserve">
    <value>入數</value>
  </data>
  <data name="wRemittanceWithdraw" xml:space="preserve">
    <value>出數</value>
  </data>
  <data name="txtAddAmt" xml:space="preserve">
    <value>加額</value>
  </data>
  <data name="txtCancelCreditTypeStopM" xml:space="preserve">
    <value>解除停M</value>
  </data>
  <data name="txtCreditTypeStopM" xml:space="preserve">
    <value>停M</value>
  </data>
  <data name="txtDecreaseAmt" xml:space="preserve">
    <value>減額</value>
  </data>
  <data name="txtStaff" xml:space="preserve">
    <value>員工</value>
  </data>
  <data name="txtStoreNegative" xml:space="preserve">
    <value>負數卡</value>
  </data>
  <data name="txtStoreNonNegative" xml:space="preserve">
    <value>非負數卡</value>
  </data>
  <data name="wTranName" xml:space="preserve">
    <value>交易項目</value>
  </data>
  <data name="wIsInternalTran" xml:space="preserve">
    <value>內部交易</value>
  </data>
  <data name="txtShowInternalTran" xml:space="preserve">
    <value>顯示內部交易</value>
  </data>
  <data name="type_CR" xml:space="preserve">
    <value>提卡</value>
  </data>
  <data name="type_CS" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="wInternalRemark" xml:space="preserve">
    <value>內部備註</value>
  </data>
  <data name="txtTransferCentre" xml:space="preserve">
    <value>綜合理財</value>
  </data>
  <data name="txtChipTranI" xml:space="preserve">
    <value>存單管理</value>
  </data>
  <data name="global_txtAllCustomer" xml:space="preserve">
    <value>全部客人</value>
  </data>
  <data name="global_txtSearchType" xml:space="preserve">
    <value>搜尋類型</value>
  </data>
  <data name="txtCustCName" xml:space="preserve">
    <value>存/提款人</value>
  </data>
  <data name="txtDisplay" xml:space="preserve">
    <value>顯示</value>
  </data>
  <data name="txtExpireDate" xml:space="preserve">
    <value>到期日</value>
  </data>
  <data name="txtFromDate" xml:space="preserve">
    <value>結算日期</value>
  </data>
  <data name="txtGroupByCardCode" xml:space="preserve">
    <value>以卡號分類</value>
  </data>
  <data name="txtHaveInterestAcctOnly" xml:space="preserve">
    <value>只顯示收息戶口</value>
  </data>
  <data name="txtIsInternal" xml:space="preserve">
    <value>只顯示內部飛數</value>
  </data>
  <data name="txtOperateRefNo" xml:space="preserve">
    <value>營運編號</value>
  </data>
  <data name="txtRollingMoney" xml:space="preserve">
    <value>轉碼超過(萬)</value>
  </data>
  <data name="txtUseCurDateTimeFilter" xml:space="preserve">
    <value>用於輸入借貸日期作篩選</value>
  </data>
  <data name="txtUserType" xml:space="preserve">
    <value>用戶類型</value>
  </data>
  <data name="txtAbroad" xml:space="preserve">
    <value>海外團</value>
  </data>
  <data name="txtArrRemainRecord" xml:space="preserve">
    <value>欠費餘數記錄</value>
  </data>
  <data name="txtComIOU" xml:space="preserve">
    <value>公司IOU</value>
  </data>
  <data name="txtCRM" xml:space="preserve">
    <value>現碼還M</value>
  </data>
  <data name="txtFDeSlip" xml:space="preserve">
    <value>凍結存款單</value>
  </data>
  <data name="txtFMSCard" xml:space="preserve">
    <value>凍M存卡</value>
  </data>
  <data name="txtGRM" xml:space="preserve">
    <value>贏錢回舊M</value>
  </data>
  <data name="txtHSCard" xml:space="preserve">
    <value>股本存卡</value>
  </data>
  <data name="txtInsSave" xml:space="preserve">
    <value>暫存</value>
  </data>
  <data name="txtMRemainderRecord" xml:space="preserve">
    <value>罰息餘數記錄</value>
  </data>
  <data name="txtMReturnRecord" xml:space="preserve">
    <value>罰息歸還記錄</value>
  </data>
  <data name="txtMRM" xml:space="preserve">
    <value>M還M</value>
  </data>
  <data name="txtMSOrder" xml:space="preserve">
    <value>月息存單</value>
  </data>
  <data name="txtNotAbroad" xml:space="preserve">
    <value>非海外團</value>
  </data>
  <data name="txtOpCard" xml:space="preserve">
    <value>運營卡</value>
  </data>
  <data name="txtPreMOfTM" xml:space="preserve">
    <value>預視此月份罰息</value>
  </data>
  <data name="txtReRecord" xml:space="preserve">
    <value>歸還記錄</value>
  </data>
  <data name="txtShowPenaltyIOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="txtSMRM" xml:space="preserve">
    <value>存M還M</value>
  </data>
  <data name="txtTMthRecord" xml:space="preserve">
    <value>此月份記錄</value>
  </data>
  <data name="txtExpOutstanding" xml:space="preserve">
    <value>尚欠費用</value>
  </data>
  <data name="txtAccURecord" xml:space="preserve">
    <value>累數使用記錄</value>
  </data>
  <data name="txtFReRecord" xml:space="preserve">
    <value>食津餘數記錄</value>
  </data>
  <data name="txtAbgCode" xml:space="preserve">
    <value>海外團號碼</value>
  </data>
  <data name="txtDisplayUnSettle" xml:space="preserve">
    <value>顯示未結算</value>
  </data>
  <data name="txtANumber" xml:space="preserve">
    <value>A數</value>
  </data>
  <data name="txtBNumber" xml:space="preserve">
    <value>B數</value>
  </data>
  <data name="txtChipType" xml:space="preserve">
    <value>數類</value>
  </data>
  <data name="txtGoldenAcc" xml:space="preserve">
    <value>金咭戶</value>
  </data>
  <data name="txtHMemberCard" xml:space="preserve">
    <value>尊貴卡</value>
  </data>
  <data name="txtMemberCard" xml:space="preserve">
    <value>會員卡</value>
  </data>
  <data name="txtMonSettle" xml:space="preserve">
    <value>月結即出</value>
  </data>
  <data name="txtNormalAcc" xml:space="preserve">
    <value>基本戶</value>
  </data>
  <data name="txtNotHoldCommission" xml:space="preserve">
    <value>不顯示HOLD佣</value>
  </data>
  <data name="txtNotVIP" xml:space="preserve">
    <value>非會員</value>
  </data>
  <data name="txtpRtnCur" xml:space="preserve">
    <value>以港幣結算</value>
  </data>
  <data name="txtQuickSettle" xml:space="preserve">
    <value>即出</value>
  </data>
  <data name="typeRAGBOOKINGPRORPT_Report" xml:space="preserve">
    <value>業務進步約見名單</value>
  </data>
  <data name="typeRAGCREOV1KROLUNRPT_Report" xml:space="preserve">
    <value>信貸額1千不達標</value>
  </data>
  <data name="typeRAGECHIBOMTHMARRPT_Report" xml:space="preserve">
    <value>每月存款大於過期Marker</value>
  </data>
  <data name="typeRAGECREDAMOURPT_Report" xml:space="preserve">
    <value>批碼金額及戶口</value>
  </data>
  <data name="typeRCREDANDROLLSTRPT_Report" xml:space="preserve">
    <value>已信貸額玩家戶口及轉碼</value>
  </data>
  <data name="typeRDISPLAYOV1MRPT_Report" xml:space="preserve">
    <value>有額超過1個月無用名單</value>
  </data>
  <data name="typeRFOLZZSACCRPT_Report" xml:space="preserve">
    <value>ZZS/OT/OF/OK分析</value>
  </data>
  <data name="typeRLA30DFIRMARKRACCRPT_Report" xml:space="preserve">
    <value>批M首月轉碼</value>
  </data>
  <data name="typeRNEWAGECREDROLRPT_Report" xml:space="preserve">
    <value>新批玩家戶口及轉碼</value>
  </data>
  <data name="typeRNOMARKERLSTRPT_Report" xml:space="preserve">
    <value>停M名單</value>
  </data>
  <data name="typeRRANKTWINLOSSRPT_Report" xml:space="preserve">
    <value>輸贏排名</value>
  </data>
  <data name="txtInterDate" xml:space="preserve">
    <value>應派息日期</value>
  </data>
  <data name="txtMemberAll" xml:space="preserve">
    <value>VVIP及VIP</value>
  </data>
  <data name="txtOperateDate" xml:space="preserve">
    <value>操作日期</value>
  </data>
  <data name="typeAGENTLOCKRPT_ReportGrp" xml:space="preserve">
    <value>二次授權報表</value>
  </data>
  <data name="typeBONUSGIFTRPT_ReportGrp" xml:space="preserve">
    <value>送禮報表</value>
  </data>
  <data name="typeRAGENTLOCKRPT_Report" xml:space="preserve">
    <value>二次授權報表</value>
  </data>
  <data name="typeRBONUSGIFTRPT_Report" xml:space="preserve">
    <value>送禮報表</value>
  </data>
  <data name="global_txtDest" xml:space="preserve">
    <value>目的地</value>
  </data>
  <data name="global_txtExpParentCode" xml:space="preserve">
    <value>消費類型</value>
  </data>
  <data name="global_txtExpSubCode" xml:space="preserve">
    <value>消費分類</value>
  </data>
  <data name="global_txtExpType" xml:space="preserve">
    <value>消費類型</value>
  </data>
  <data name="global_txtMiscSubType" xml:space="preserve">
    <value>雜項分類</value>
  </data>
  <data name="global_txtMiscType" xml:space="preserve">
    <value>雜項類型</value>
  </data>
  <data name="global_txtResturant" xml:space="preserve">
    <value>餐廳</value>
  </data>
  <data name="global_txtRoomType" xml:space="preserve">
    <value>房間類型</value>
  </data>
  <data name="global_txtSitType" xml:space="preserve">
    <value>座位類型</value>
  </data>
  <data name="global_txtVehicleType" xml:space="preserve">
    <value>工具類型</value>
  </data>
  <data name="wIDType_ID" xml:space="preserve">
    <value>身份證</value>
  </data>
  <data name="wIDType_Passport" xml:space="preserve">
    <value>護照</value>
  </data>
  <data name="wIDType_VISA" xml:space="preserve">
    <value>通行證</value>
  </data>
  <data name="action_UPLOAD_type" xml:space="preserve">
    <value>上傳</value>
  </data>
  <data name="txtToHKD" xml:space="preserve">
    <value>折算港幣</value>
  </data>
  <data name="txtRelateIOU" xml:space="preserve">
    <value>相關借貸</value>
  </data>
  <data name="txtCreditHistory" xml:space="preserve">
    <value>信貸額記錄</value>
  </data>
  <data name="txtUCredit" xml:space="preserve">
    <value>U信貸額</value>
  </data>
  <data name="txtCashLoan" xml:space="preserve">
    <value>個人</value>
  </data>
  <data name="type_LongTerm" xml:space="preserve">
    <value>長期</value>
  </data>
  <data name="type_TEMP" xml:space="preserve">
    <value>臨時</value>
  </data>
  <data name="txtFirstPage" xml:space="preserve">
    <value>首頁</value>
  </data>
  <data name="txtPrevPage" xml:space="preserve">
    <value>上頁</value>
  </data>
  <data name="txtNextPage" xml:space="preserve">
    <value>下頁</value>
  </data>
  <data name="txtLastPage" xml:space="preserve">
    <value>末頁</value>
  </data>
  <data name="txtPageSize" xml:space="preserve">
    <value>顯示記錄數</value>
  </data>
  <data name="txtRecordCount" xml:space="preserve">
    <value>記錄數</value>
  </data>
  <data name="global_txtTransferCard" xml:space="preserve">
    <value>過數卡</value>
  </data>
  <data name="global_btnNewAuthorize" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="global_btnNewUnderAgent" xml:space="preserve">
    <value>新增下線</value>
  </data>
  <data name="global_btnNew" xml:space="preserve">
    <value>新增</value>
  </data>
  <data name="txtAgentBasicDetail" xml:space="preserve">
    <value>戶口記錄</value>
  </data>
  <data name="txtAgentContactDetail" xml:space="preserve">
    <value>聯絡資料</value>
  </data>
  <data name="txtAgentOtherDetail" xml:space="preserve">
    <value>其它資料</value>
  </data>
  <data name="type_Shift1" xml:space="preserve">
    <value>早更</value>
  </data>
  <data name="type_Shift2" xml:space="preserve">
    <value>中更</value>
  </data>
  <data name="type_Shift3" xml:space="preserve">
    <value>夜更</value>
  </data>
  <data name="global_txtFilePath" xml:space="preserve">
    <value>文件位置</value>
  </data>
  <data name="global_btnRoomExt" xml:space="preserve">
    <value>續房</value>
  </data>
  <data name="global_btnPrintAllRoom" xml:space="preserve">
    <value>列印全部房間</value>
  </data>
  <data name="txtAlready" xml:space="preserve">
    <value>已</value>
  </data>
  <data name="txtAuthIndentityAgent" xml:space="preserve">
    <value>戶主</value>
  </data>
  <data name="txtHidden" xml:space="preserve">
    <value>不顯示</value>
  </data>
  <data name="txtIOUTranTypeLst" xml:space="preserve">
    <value>客人未取</value>
  </data>
  <data name="txtOperating" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="txtOperation" xml:space="preserve">
    <value>執行</value>
  </data>
  <data name="txtTranGroupI" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="wAgentCodeInRoll" xml:space="preserve">
    <value>轉碼戶口</value>
  </data>
  <data name="wCashBal" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="txtCommRetM" xml:space="preserve">
    <value>佣金回M</value>
  </data>
  <data name="txtGroupByComM" xml:space="preserve">
    <value>以M現金，海外本地現金出碼及數類 分類</value>
  </data>
  <data name="txtRange" xml:space="preserve">
    <value>範圍</value>
  </data>
  <data name="global_btnDownload" xml:space="preserve">
    <value>下載</value>
  </data>
  <data name="global_btnBrowse" xml:space="preserve">
    <value>瀏覽</value>
  </data>
  <data name="txtUploadFile" xml:space="preserve">
    <value>上傳文件</value>
  </data>
  <data name="wExpirePeriod" xml:space="preserve">
    <value>限期</value>
  </data>
  <data name="global_txtAmountHKD" xml:space="preserve">
    <value>港幣金額</value>
  </data>
  <data name="txtVIP" xml:space="preserve">
    <value>VIP</value>
  </data>
  <data name="txtVVIP" xml:space="preserve">
    <value>VVIP</value>
  </data>
  <data name="txtSearchComboEmpty" xml:space="preserve">
    <value>(全部)</value>
  </data>
  <data name="wCName_Last" xml:space="preserve">
    <value>中文姓氏</value>
  </data>
  <data name="wEName_Last" xml:space="preserve">
    <value>英文姓氏</value>
  </data>
  <data name="txtAgentRoveDtl" xml:space="preserve">
    <value>巨額用戶紀錄</value>
  </data>
  <data name="txtIDIssuedCountry" xml:space="preserve">
    <value>證件簽發地點</value>
  </data>
  <data name="txtOtherInflowDesc" xml:space="preserve">
    <value>請註明 :</value>
  </data>
  <data name="txtTransactionCode" xml:space="preserve">
    <value>交易組別</value>
  </data>
  <data name="txtAgentRoveTranLst" xml:space="preserve">
    <value>巨額報表交易記錄</value>
  </data>
  <data name="txtCustomer" xml:space="preserve">
    <value>客人</value>
  </data>
  <data name="txtGuareantor" xml:space="preserve">
    <value>擔保人</value>
  </data>
  <data name="txtStaffNo" xml:space="preserve">
    <value>員工號碼</value>
  </data>
  <data name="txtVIPNumber" xml:space="preserve">
    <value>貴賓卡號</value>
  </data>
  <data name="wIntroducerCodeIn" xml:space="preserve">
    <value>介紹人</value>
  </data>
  <data name="btnReadCard" xml:space="preserve">
    <value>讀卡</value>
  </data>
  <data name="btnRemarkCount" xml:space="preserve">
    <value>戶口重要備註</value>
  </data>
  <data name="btnRemoteMachineInput" xml:space="preserve">
    <value>遙距輸入</value>
  </data>
  <data name="typeStatus_I" xml:space="preserve">
    <value>不活躍</value>
  </data>
  <data name="txtShareJoinDate" xml:space="preserve">
    <value>入股日期</value>
  </data>
  <data name="txtInfoTelFormat" xml:space="preserve">
    <value>格式: +(國家號碼)(電話號碼), 例子: +85223456789</value>
  </data>
  <data name="wTelSMSOpIntroducer" xml:space="preserve">
    <value>營運來貨號碼</value>
  </data>
  <data name="wTelSMSForeign" xml:space="preserve">
    <value>海外團號碼</value>
  </data>
  <data name="txtAgentPercentage" xml:space="preserve">
    <value>%代理</value>
  </data>
  <data name="txtPleaseClarifyPercertage" xml:space="preserve">
    <value>請註明比例</value>
  </data>
  <data name="txtPlayerPercentage" xml:space="preserve">
    <value>%玩家</value>
  </data>
  <data name="txtHoldStoreCashChip" xml:space="preserve">
    <value>Hold存卡數</value>
  </data>
  <data name="txtSpokenLang" xml:space="preserve">
    <value>對話語言</value>
  </data>
  <data name="txtSeason" xml:space="preserve">
    <value>季度</value>
  </data>
  <data name="txtSeason1" xml:space="preserve">
    <value>1-3</value>
  </data>
  <data name="txtSeason2" xml:space="preserve">
    <value>4-6</value>
  </data>
  <data name="txtSeason3" xml:space="preserve">
    <value>7-9</value>
  </data>
  <data name="txtSeason4" xml:space="preserve">
    <value>10-12</value>
  </data>
  <data name="txtIdentify" xml:space="preserve">
    <value>如"有"，請註明</value>
  </data>
  <data name="txtRelation" xml:space="preserve">
    <value>關係</value>
  </data>
  <data name="txtAuthorize" xml:space="preserve">
    <value>授權</value>
  </data>
  <data name="wAuComm" xml:space="preserve">
    <value>取佣</value>
  </data>
  <data name="wAuExp" xml:space="preserve">
    <value>簽單</value>
  </data>
  <data name="wAuIOU" xml:space="preserve">
    <value>簽貸款</value>
  </data>
  <data name="wAuOther" xml:space="preserve">
    <value>其他</value>
  </data>
  <data name="wAuOtherRemark" xml:space="preserve">
    <value>備註</value>
  </data>
  <data name="wAuRoom" xml:space="preserve">
    <value>取房</value>
  </data>
  <data name="wAuShopping" xml:space="preserve">
    <value>購物</value>
  </data>
  <data name="wAuShoppingHint" xml:space="preserve">
    <value>註: 當選取”購物”代表授權人購物HKD 5,000 內不用通知戶主</value>
  </data>
  <data name="wAuStore" xml:space="preserve">
    <value>取存碼</value>
  </data>
  <data name="wAuStoreBook" xml:space="preserve">
    <value>大簿</value>
  </data>
  <data name="wAuthCName" xml:space="preserve">
    <value>授權主管</value>
  </data>
  <data name="wAuthIdentity" xml:space="preserve">
    <value>授權人身份</value>
  </data>
  <data name="wAuthoize" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="wAuthPerson" xml:space="preserve">
    <value>認證戶口</value>
  </data>
  <data name="wAuthUsrId" xml:space="preserve">
    <value>授權主管編號</value>
  </data>
  <data name="wAuTicket" xml:space="preserve">
    <value>取飛</value>
  </data>
  <data name="global_txtCachOut" xml:space="preserve">
    <value>取走現金</value>
  </data>
  <data name="global_txtCashChipOut" xml:space="preserve">
    <value>袋走現金碼</value>
  </data>
  <data name="global_txtReturnIOU" xml:space="preserve">
    <value>贖回借貸</value>
  </data>
  <data name="global_txtTran" xml:space="preserve">
    <value>存款</value>
  </data>
  <data name="typeChip_StoreC" xml:space="preserve">
    <value>存C</value>
  </data>
  <data name="typeChip_Win" xml:space="preserve">
    <value>贏錢</value>
  </data>
  <data name="typeChip_NNChip" xml:space="preserve">
    <value>泥碼</value>
  </data>
  <data name="typeChipService_WITHDRAWAL" xml:space="preserve">
    <value>提款</value>
  </data>
  <data name="typeChipService_DEPOSIT" xml:space="preserve">
    <value>存款</value>
  </data>
  <data name="typeChipService_TRANSFER" xml:space="preserve">
    <value>轉帳</value>
  </data>
  <data name="typeChipTran_CHIPB" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="typeChipTran_CHIPI" xml:space="preserve">
    <value>存單</value>
  </data>
  <data name="typeChipTran_MTHINTEREST" xml:space="preserve">
    <value>月息單</value>
  </data>
  <data name="typeChipTran_CAPITAL" xml:space="preserve">
    <value>股本卡</value>
  </data>
  <data name="typeChipTran_FREEZE" xml:space="preserve">
    <value>凍M卡</value>
  </data>
  <data name="typeChipTran_HOLD" xml:space="preserve">
    <value>凍結存款單</value>
  </data>
  <data name="typeChipAction_CASH" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="typeChipAction_NNCHIP" xml:space="preserve">
    <value>籌碼</value>
  </data>
  <data name="typeChipAction_REPAYMENT" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="typeChipAction_CHIPB" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="typeChipAction_MTHINTEREST" xml:space="preserve">
    <value>存月息</value>
  </data>
  <data name="typeChipAction_CAPITAL" xml:space="preserve">
    <value>存股本</value>
  </data>
  <data name="typeChipAction_FREEZE" xml:space="preserve">
    <value>凍M</value>
  </data>
  <data name="typeAGENTROVELST_Core" xml:space="preserve">
    <value>巨額用戶管理</value>
  </data>
  <data name="typeAGENTROVETRANLST_Core" xml:space="preserve">
    <value>巨額報表交易記錄</value>
  </data>
  <data name="typeROVECUSTOMERLST_Core" xml:space="preserve">
    <value>客人管理(巨額)</value>
  </data>
  <data name="txtBChipStoreType" xml:space="preserve">
    <value>存款類型</value>
  </data>
  <data name="txtInfoSimilarAgentExists" xml:space="preserve">
    <value>相似戶口</value>
  </data>
  <data name="global_btnImport" xml:space="preserve">
    <value>匯入</value>
  </data>
  <data name="txtErrImportData" xml:space="preserve">
    <value>匯入資料錯誤:{0}</value>
  </data>
  <data name="txtSelect" xml:space="preserve">
    <value>選取</value>
  </data>
  <data name="wStaffNo" xml:space="preserve">
    <value>相關員工編號</value>
  </data>
  <data name="wTradeChip" xml:space="preserve">
    <value>交易金額(萬)</value>
  </data>
  <data name="wTradeType" xml:space="preserve">
    <value>交易類別</value>
  </data>
  <data name="global_btnChangeIVRPwd" xml:space="preserve">
    <value>修改戶口認証密碼</value>
  </data>
  <data name="global_btnResetIVRPwd" xml:space="preserve">
    <value>重設戶口認証密碼</value>
  </data>
  <data name="txtAgentRoveLst" xml:space="preserve">
    <value>巨額用戶列表</value>
  </data>
  <data name="global_txtAskConfirm" xml:space="preserve">
    <value>確定</value>
  </data>
  <data name="global_txtAskConfirmCancelIOUContractNo" xml:space="preserve">
    <value>確定取消借貸合同編號?</value>
  </data>
  <data name="global_txtAskConfirmNewIOUContractNo" xml:space="preserve">
    <value>確定新增借貸合同編號?</value>
  </data>
  <data name="global_txtCustomerGroup_Normal" xml:space="preserve">
    <value>一般</value>
  </data>
  <data name="global_txtCustomerGroup_OP" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="global_txtCustomerGroup_ROVE" xml:space="preserve">
    <value>巨額</value>
  </data>
  <data name="global_txtCustomerGroup_ST" xml:space="preserve">
    <value>出佣人</value>
  </data>
  <data name="txtServiceType" xml:space="preserve">
    <value>服務類型</value>
  </data>
  <data name="txtDeviceDtl" xml:space="preserve">
    <value>裝置記錄</value>
  </data>
  <data name="txtDeviceLst" xml:space="preserve">
    <value>裝置管理</value>
  </data>
  <data name="typeDEVICELST_Core" xml:space="preserve">
    <value>裝置管理</value>
  </data>
  <data name="global_msgErrRecordNotFound" xml:space="preserve">
    <value>找不到相關記錄</value>
  </data>
  <data name="global_btnLogin" xml:space="preserve">
    <value>登入</value>
  </data>
  <data name="global_msgPlaceCardForCardReader" xml:space="preserve">
    <value>請將卡放於讀卡器上</value>
  </data>
  <data name="txtBalanceSheet" xml:space="preserve">
    <value>資產負債表</value>
  </data>
  <data name="global_btnReturn" xml:space="preserve">
    <value>歸還</value>
  </data>
  <data name="eCounterBal" xml:space="preserve">
    <value>櫃數表</value>
  </data>
  <data name="txtStoreNegativeAmt" xml:space="preserve">
    <value>可負數卡,限額(只可輸入負數)</value>
  </data>
  <data name="wNoIVR" xml:space="preserve">
    <value>不需要電話認証</value>
  </data>
  <data name="UsageType_RemoteRolling" xml:space="preserve">
    <value>遙距轉碼</value>
  </data>
  <data name="UsageType_TranApps" xml:space="preserve">
    <value>營運Apps</value>
  </data>
  <data name="wDeviceID" xml:space="preserve">
    <value>裝置編號</value>
  </data>
  <data name="wDeviceType" xml:space="preserve">
    <value>裝置型號</value>
  </data>
  <data name="wUsageType" xml:space="preserve">
    <value>種類</value>
  </data>
  <data name="txtAgentManager" xml:space="preserve">
    <value>戶口經理版</value>
  </data>
  <data name="txtInfoIVRAuthSuccess" xml:space="preserve">
    <value>戶口密碼証證成功</value>
  </data>
  <data name="wGunterPassword" xml:space="preserve">
    <value>密碼</value>
  </data>
  <data name="btnTempByPassAgentAuth" xml:space="preserve">
    <value>跳過戶口認証檢查</value>
  </data>
  <data name="txtLivePasswordInput" xml:space="preserve">
    <value>現場輸入戶口認証</value>
  </data>
  <data name="wIVRPwd" xml:space="preserve">
    <value>戶口密碼</value>
  </data>
  <data name="btnCancelLivePassword" xml:space="preserve">
    <value>轉用電話系統認証</value>
  </data>
  <data name="btnCheckIVRAuth" xml:space="preserve">
    <value>檢查戶主密碼</value>
  </data>
  <data name="txtAuthBy" xml:space="preserve">
    <value>認証</value>
  </data>
  <data name="txtCheckIVRAuth" xml:space="preserve">
    <value>檢查戶口</value>
  </data>
  <data name="txtInfoWaitingIVRAuth" xml:space="preserve">
    <value>等候戶主電話認証中 ....</value>
  </data>
  <data name="txtPreferLang" xml:space="preserve">
    <value>語言</value>
  </data>
  <data name="wExt" xml:space="preserve">
    <value>電話線號</value>
  </data>
  <data name="global_AuthIdentityASSISTANT" xml:space="preserve">
    <value>業務發展部助理</value>
  </data>
  <data name="global_AuthIdentityBOSS" xml:space="preserve">
    <value>幕後老闆</value>
  </data>
  <data name="global_AuthIdentityDIRECTOR" xml:space="preserve">
    <value>總監</value>
  </data>
  <data name="global_AuthIdentityFAMILY" xml:space="preserve">
    <value>家人</value>
  </data>
  <data name="global_AuthIdentityMARKET" xml:space="preserve">
    <value>巿場部</value>
  </data>
  <data name="global_AuthIdentityOWNER" xml:space="preserve">
    <value>戶主</value>
  </data>
  <data name="global_AuthIdentityPARTNER" xml:space="preserve">
    <value>拍檔</value>
  </data>
  <data name="global_AuthIdentitySTAFF" xml:space="preserve">
    <value>伙記</value>
  </data>
  <data name="global_AuthIdentityWARRANTOR" xml:space="preserve">
    <value>借貸担保人</value>
  </data>
  <data name="txtBefore" xml:space="preserve">
    <value>之前</value>
  </data>
  <data name="txtCapitalTranTypeH" xml:space="preserve">
    <value>凍結存款單報表</value>
  </data>
  <data name="txtCapitalTranTypeO" xml:space="preserve">
    <value>營運卡報表</value>
  </data>
  <data name="txtCapitalTranTypeY" xml:space="preserve">
    <value>食貨存卡</value>
  </data>
  <data name="txtChipTotal" xml:space="preserve">
    <value>存碼總和</value>
  </data>
  <data name="txtCreditTranStatusC" xml:space="preserve">
    <value>無效</value>
  </data>
  <data name="txtEliteNOBILITY" xml:space="preserve">
    <value>貴族</value>
  </data>
  <data name="txtEliteROYALTY" xml:space="preserve">
    <value>皇族</value>
  </data>
  <data name="txtLatest" xml:space="preserve">
    <value>最新</value>
  </data>
  <data name="txtMonthFilterOptLstPre" xml:space="preserve">
    <value>上月</value>
  </data>
  <data name="txtMonthFilterOptLstThis" xml:space="preserve">
    <value>本月</value>
  </data>
  <data name="txtMsgNoRecord" xml:space="preserve">
    <value>沒有記錄</value>
  </data>
  <data name="txtReturnType_TS" xml:space="preserve">
    <value>取暫存</value>
  </data>
  <data name="txtSexOptF" xml:space="preserve">
    <value>女</value>
  </data>
  <data name="txtSexOptM" xml:space="preserve">
    <value>男</value>
  </data>
  <data name="txtStatusPlsSelect" xml:space="preserve">
    <value>請選擇</value>
  </data>
  <data name="txtTranGroupCWG" xml:space="preserve">
    <value>客人已取</value>
  </data>
  <data name="txtTranGroupReCI" xml:space="preserve">
    <value>歸還公司IOU</value>
  </data>
  <data name="txtTranGroupReI" xml:space="preserve">
    <value>歸還IOU</value>
  </data>
  <data name="txtTranGroupReS" xml:space="preserve">
    <value>歸還股本</value>
  </data>
  <data name="txtWMRM" xml:space="preserve">
    <value>嬴錢回舊M</value>
  </data>
  <data name="txLineTtlMarker" xml:space="preserve">
    <value>全線總簽賬</value>
  </data>
  <data name="txtAProfitAndLossStandard" xml:space="preserve">
    <value>損益表</value>
  </data>
  <data name="txtBFAmount" xml:space="preserve">
    <value>前額</value>
  </data>
  <data name="txtBonusPointStatusA" xml:space="preserve">
    <value>已批</value>
  </data>
  <data name="txtBonusPointStatusN" xml:space="preserve">
    <value>待批</value>
  </data>
  <data name="txtBonusPointStatusR" xml:space="preserve">
    <value>駁回</value>
  </data>
  <data name="txtBPlayCustomer" xml:space="preserve">
    <value>客戶</value>
  </data>
  <data name="txtCapital" xml:space="preserve">
    <value>本金</value>
  </data>
  <data name="txtCapitalTranF" xml:space="preserve">
    <value>凍M</value>
  </data>
  <data name="txtCapLimitN" xml:space="preserve">
    <value>不接受超額</value>
  </data>
  <data name="txtCapLimitY" xml:space="preserve">
    <value>可接受超額</value>
  </data>
  <data name="txtCashToDrinkRate" xml:space="preserve">
    <value>{0}折</value>
  </data>
  <data name="txtConfirmSheet" xml:space="preserve">
    <value>確認表</value>
  </data>
  <data name="txtCurrentAssets" xml:space="preserve">
    <value>流動資產</value>
  </data>
  <data name="txtCurrentLib" xml:space="preserve">
    <value>流動負債</value>
  </data>
  <data name="txtExchangeSimple" xml:space="preserve">
    <value>兌</value>
  </data>
  <data name="txtExpense" xml:space="preserve">
    <value>支出</value>
  </data>
  <data name="txtExpenseFxRate" xml:space="preserve">
    <value>消費匯率</value>
  </data>
  <data name="txtExpenseIs" xml:space="preserve">
    <value>實收消費為</value>
  </data>
  <data name="txtExpStatement" xml:space="preserve">
    <value>**通用積分有效期為兩個月, 餘下積分可作現金回收; 不通用積分可無限期累積, 直至永利酒店另行通知, 當中所涉及的損失, 本公司一概不作承擔**</value>
  </data>
  <data name="txtFixedAssets" xml:space="preserve">
    <value>固定資產</value>
  </data>
  <data name="txtFollowRemark" xml:space="preserve">
    <value>跟進及備註</value>
  </data>
  <data name="txtForeignDetail" xml:space="preserve">
    <value>海外數明細</value>
  </data>
  <data name="txtFr" xml:space="preserve">
    <value>由</value>
  </data>
  <data name="txtGrpExpCommitment" xml:space="preserve">
    <value>承擔集團之費用</value>
  </data>
  <data name="txtInCome" xml:space="preserve">
    <value>收入</value>
  </data>
  <data name="txtInterest" xml:space="preserve">
    <value>利息</value>
  </data>
  <data name="txtIOUTotalAmt" xml:space="preserve">
    <value>借貸總額</value>
  </data>
  <data name="txtMsgCompShareDebt" xml:space="preserve">
    <value>集團旗下各館共同分擔什此數</value>
  </data>
  <data name="txtNetAsset" xml:space="preserve">
    <value>資產淨值</value>
  </data>
  <data name="txtNetProfit" xml:space="preserve">
    <value>純利</value>
  </data>
  <data name="txtOnSite" xml:space="preserve">
    <value>在場</value>
  </data>
  <data name="txtOrgExpenseIs" xml:space="preserve">
    <value>原消費為</value>
  </data>
  <data name="txtOutSite" xml:space="preserve">
    <value>離場</value>
  </data>
  <data name="txtOutstandingTotalAmt" xml:space="preserve">
    <value>未歸還總額</value>
  </data>
  <data name="txtOwn" xml:space="preserve">
    <value>本人</value>
  </data>
  <data name="txtPointUse_InHKD_Real" xml:space="preserve">
    <value>澳門積分使用</value>
  </data>
  <data name="txtPreliminary" xml:space="preserve">
    <value>最初</value>
  </data>
  <data name="txtPrintDate" xml:space="preserve">
    <value>列印日期</value>
  </data>
  <data name="txtPrintLocation" xml:space="preserve">
    <value>列印場所</value>
  </data>
  <data name="txtProfit" xml:space="preserve">
    <value>毛利</value>
  </data>
  <data name="txtProfitAndLossSheet" xml:space="preserve">
    <value>什支表</value>
  </data>
  <data name="txtRBPlayCompWLReport" xml:space="preserve">
    <value>B數公司上/下數報表.</value>
  </data>
  <data name="txtRBPlayCustWLReport" xml:space="preserve">
    <value>B數客人上/下數報表.</value>
  </data>
  <data name="txtRForeignCompWLReport" xml:space="preserve">
    <value>海外公司上/下數報表</value>
  </data>
  <data name="txtRForeignCustWLReport" xml:space="preserve">
    <value>海外客人上/下數報表</value>
  </data>
  <data name="txtRSpecialMarkerRpt_C" xml:space="preserve">
    <value>個人借貸報表</value>
  </data>
  <data name="txtRSpecialMarkerTran_C" xml:space="preserve">
    <value>個人借貸提存表</value>
  </data>
  <data name="txtRSpecialMarkerTran_F" xml:space="preserve">
    <value>海外借貸提存表</value>
  </data>
  <data name="txtRSpecialMarkerTran_Y" xml:space="preserve">
    <value>營運借貸提存表</value>
  </data>
  <data name="txtSetting" xml:space="preserve">
    <value>設定中</value>
  </data>
  <data name="txtSettleStatusSettled" xml:space="preserve">
    <value>已結算</value>
  </data>
  <data name="txtShareCapital" xml:space="preserve">
    <value>股東資金</value>
  </data>
  <data name="txtSite" xml:space="preserve">
    <value>場地</value>
  </data>
  <data name="txtSubLevelBal" xml:space="preserve">
    <value>下線累計數</value>
  </data>
  <data name="txtSum" xml:space="preserve">
    <value>總和</value>
  </data>
  <data name="txtTotal" xml:space="preserve">
    <value>總計</value>
  </data>
  <data name="txtTotalExpense" xml:space="preserve">
    <value>總支出</value>
  </data>
  <data name="txtAccName" xml:space="preserve">
    <value>戶名</value>
  </data>
  <data name="txtAccTypeDn" xml:space="preserve">
    <value>會員降級</value>
  </data>
  <data name="txtAccTypeUp" xml:space="preserve">
    <value>會員升級</value>
  </data>
  <data name="txtAccTypeUpDn_D" xml:space="preserve">
    <value>降</value>
  </data>
  <data name="txtAccTypeUpDn_U" xml:space="preserve">
    <value>升</value>
  </data>
  <data name="txtAgentGetReg" xml:space="preserve">
    <value>每日戶口取房登記表</value>
  </data>
  <data name="txtAgentName" xml:space="preserve">
    <value>代理名稱</value>
  </data>
  <data name="txtAgentNotFound" xml:space="preserve">
    <value>沒有戶口</value>
  </data>
  <data name="txtAgentTotal" xml:space="preserve">
    <value>代理總計</value>
  </data>
  <data name="txtAltogether" xml:space="preserve">
    <value>共</value>
  </data>
  <data name="txtBalAmount" xml:space="preserve">
    <value>結存金額</value>
  </data>
  <data name="txtBFControl_CannotContact" xml:space="preserve">
    <value>未能聯絡</value>
  </data>
  <data name="txtBFControl_ContactAgain" xml:space="preserve">
    <value>要求再次聯絡</value>
  </data>
  <data name="txtBFControl_NoMoreContact" xml:space="preserve">
    <value>不用再通知</value>
  </data>
  <data name="txtBFControl_Purchased" xml:space="preserve">
    <value>已選購貨品</value>
  </data>
  <data name="txtBFNotPaid" xml:space="preserve">
    <value>前欠未收費用</value>
  </data>
  <data name="txtBFPenalty" xml:space="preserve">
    <value>前欠罰息</value>
  </data>
  <data name="txtBookAndGetTime" xml:space="preserve">
    <value>定時間/取時間</value>
  </data>
  <data name="txtBorrower" xml:space="preserve">
    <value>借貸人</value>
  </data>
  <data name="txtCardExp" xml:space="preserve">
    <value>卡消費</value>
  </data>
  <data name="txtCommDiff" xml:space="preserve">
    <value>佣金差額問題</value>
  </data>
  <data name="txtCompanySum" xml:space="preserve">
    <value>公司總和</value>
  </data>
  <data name="txtCompName" xml:space="preserve">
    <value>公司名稱</value>
  </data>
  <data name="txtCompTotalAmt" xml:space="preserve">
    <value>公司總額</value>
  </data>
  <data name="txtCompUnderAgentProfit" xml:space="preserve">
    <value>集團下線收益</value>
  </data>
  <data name="txtCustomerSign" xml:space="preserve">
    <value>客戶簽收</value>
  </data>
  <data name="txtCutoffTotal" xml:space="preserve">
    <value>合計實出</value>
  </data>
  <data name="txtDateTimePeriodOption" xml:space="preserve">
    <value>日期範圍及時間</value>
  </data>
  <data name="txtDeductPenaltyThisMth" xml:space="preserve">
    <value>現本月已扣罰息</value>
  </data>
  <data name="txtDiffRateComm" xml:space="preserve">
    <value>與預設不同差額問題</value>
  </data>
  <data name="txtDisplayTryRun" xml:space="preserve">
    <value>顯示預視資料</value>
  </data>
  <data name="txtDown" xml:space="preserve">
    <value>下</value>
  </data>
  <data name="txtDrink" xml:space="preserve">
    <value>津貼</value>
  </data>
  <data name="txtDrinkBal" xml:space="preserve">
    <value>津貼餘額</value>
  </data>
  <data name="txtDrinkTotal" xml:space="preserve">
    <value>總津貼</value>
  </data>
  <data name="txtEDrinkBFControlLst" xml:space="preserve">
    <value>食津累數跟進</value>
  </data>
  <data name="txtExceedExp" xml:space="preserve">
    <value>超額消費</value>
  </data>
  <data name="txtFDNonShare" xml:space="preserve">
    <value>食津餘額(不共用)</value>
  </data>
  <data name="txtFDNonShareThisMonth" xml:space="preserve">
    <value>當月津貼餘額(不共用)</value>
  </data>
  <data name="txtFDShare" xml:space="preserve">
    <value>食津餘額(共用)</value>
  </data>
  <data name="txtFDShareThisMonth" xml:space="preserve">
    <value>當月津貼餘額(共用)</value>
  </data>
  <data name="txtForPreview" xml:space="preserve">
    <value>預視用</value>
  </data>
  <data name="txtHundredm" xml:space="preserve">
    <value>億</value>
  </data>
  <data name="txtIOUDate2" xml:space="preserve">
    <value>簽帳日期</value>
  </data>
  <data name="txtKnownNotPaidThisMth" xml:space="preserve">
    <value>現本月已知未收費用</value>
  </data>
  <data name="txtLastRollingTime" xml:space="preserve">
    <value>最後轉碼時間</value>
  </data>
  <data name="txtLeftAmount" xml:space="preserve">
    <value>剩餘金額</value>
  </data>
  <data name="txtMainCard" xml:space="preserve">
    <value>主卡</value>
  </data>
  <data name="txtMarkerAmount" xml:space="preserve">
    <value>借貸額</value>
  </data>
  <data name="txtMsgNeedPreviewSMSMessage" xml:space="preserve">
    <value>需要預覽短訊內容嗎？選擇”No”會立即發送！</value>
  </data>
  <data name="txtMsgCannotFindDebitCard" xml:space="preserve">
    <value>找不到存卡</value>
  </data>
  <data name="txtMsgErrFailedLoadingData" xml:space="preserve">
    <value>未能載入資料</value>
  </data>
  <data name="txtMsgInfoPlsInput" xml:space="preserve">
    <value>請輸入</value>
  </data>
  <data name="txtMthRollingBal" xml:space="preserve">
    <value>轉碼月結</value>
  </data>
  <data name="txtOneDayTotal" xml:space="preserve">
    <value>當日總計</value>
  </data>
  <data name="txtRmNoAndRefNo" xml:space="preserve">
    <value>房號及單號</value>
  </data>
  <data name="txtRollingCIOU" xml:space="preserve">
    <value>公司U轉碼</value>
  </data>
  <data name="txtRollingDaily" xml:space="preserve">
    <value>本日轉碼數</value>
  </data>
  <data name="txtRollingIOU" xml:space="preserve">
    <value>IOU轉碼</value>
  </data>
  <data name="txtRollingSO" xml:space="preserve">
    <value>股本轉碼</value>
  </data>
  <data name="txtRollingTotal" xml:space="preserve">
    <value>轉碼總額</value>
  </data>
  <data name="txtRollingWithCash" xml:space="preserve">
    <value>現金轉碼</value>
  </data>
  <data name="txtRollTypeCodeCIOU" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="txtRptAccTypeLst" xml:space="preserve">
    <value>會員每月升跌表</value>
  </data>
  <data name="txtRptAgeExpWithoutRoLst" xml:space="preserve">
    <value>消費報表</value>
  </data>
  <data name="typeCAPITALTRANTMP_Report" xml:space="preserve">
    <value>月息單報表</value>
  </data>
  <data name="typeCAPITALTRANH_Report" xml:space="preserve">
    <value>凍結存款單報表</value>
  </data>
  <data name="txtRptCardExpenseTran" xml:space="preserve">
    <value>卡消費記錄報表</value>
  </data>
  <data name="typeCHIPTRANTMP_Report" xml:space="preserve">
    <value>存單報表</value>
  </data>
  <data name="typeCOUNTERSETTLE_Report" xml:space="preserve">
    <value>三更結算表</value>
  </data>
  <data name="txtRptDailyAgentWinLoss" xml:space="preserve">
    <value>每日場面報表</value>
  </data>
  <data name="txtRptDepositCondTemp" xml:space="preserve">
    <value>存碼狀態查詢</value>
  </data>
  <data name="txtRptExpenseTran" xml:space="preserve">
    <value>消費記錄報表</value>
  </data>
  <data name="txtRptIOU1Temp" xml:space="preserve">
    <value>借貸細數表</value>
  </data>
  <data name="txtRptIOU2Temp" xml:space="preserve">
    <value>借貸總數表</value>
  </data>
  <data name="txtRptIOUPenaltyPreview" xml:space="preserve">
    <value>罰息現況報表(本月預視)</value>
  </data>
  <data name="txtRptIOUWarningList" xml:space="preserve">
    <value>借貸提示表</value>
  </data>
  <data name="txtRptOperateExternalReportWeek" xml:space="preserve">
    <value>每週私營報表</value>
  </data>
  <data name="txtRptRollChkSum" xml:space="preserve">
    <value>轉碼數總計報表</value>
  </data>
  <data name="txtRptRollingPenaltyDayLst" xml:space="preserve">
    <value>轉碼日數表</value>
  </data>
  <data name="txtRptRollingPenaltyMthLst" xml:space="preserve">
    <value>轉碼月數表</value>
  </data>
  <data name="txtRptRollingPenaltyYrLst" xml:space="preserve">
    <value>轉碼年數表</value>
  </data>
  <data name="txtRptSettleItemSet" xml:space="preserve">
    <value>佣金設定表</value>
  </data>
  <data name="txtExpCreditLst" xml:space="preserve">
    <value>消費批額管理</value>
  </data>
  <data name="txtUpLvlExpCreditAmt" xml:space="preserve">
    <value>上線消費批額</value>
  </data>
  <data name="txtRptSpecialMarkerLst_C" xml:space="preserve">
    <value>個人借貸現況列表</value>
  </data>
  <data name="txtRptSpecialMarkerLst_F" xml:space="preserve">
    <value>海外借貸現況列表</value>
  </data>
  <data name="txtRptSpecialMarkerLst_Y" xml:space="preserve">
    <value>營運借貸現況列表</value>
  </data>
  <data name="txtRptVouDtlLst" xml:space="preserve">
    <value>票單查詢報表</value>
  </data>
  <data name="txtRSuggestTranStatistic" xml:space="preserve">
    <value>客人特徵及部門備註統計報表</value>
  </data>
  <data name="txtSalaryTitleEnd" xml:space="preserve">
    <value>月份碼佣</value>
  </data>
  <data name="txtSPIOURefNo" xml:space="preserve">
    <value>營運單號</value>
  </data>
  <data name="txtStaffName" xml:space="preserve">
    <value>員工名稱</value>
  </data>
  <data name="txtStoreAmt" xml:space="preserve">
    <value>存碼額</value>
  </data>
  <data name="txtSubTotal" xml:space="preserve">
    <value>小計</value>
  </data>
  <data name="txtSuggestedReward" xml:space="preserve">
    <value>可送</value>
  </data>
  <data name="txtTotalNum" xml:space="preserve">
    <value>總數</value>
  </data>
  <data name="txtTotalNumHKD" xml:space="preserve">
    <value>總數折萛為港幣</value>
  </data>
  <data name="txtTotalRolling" xml:space="preserve">
    <value>總轉碼</value>
  </data>
  <data name="txtTotalRollingLoss" xml:space="preserve">
    <value>總下</value>
  </data>
  <data name="txtTotalRollingWin" xml:space="preserve">
    <value>總上</value>
  </data>
  <data name="txtUp" xml:space="preserve">
    <value>上</value>
  </data>
  <data name="txtWinLossReward_AirTicket" xml:space="preserve">
    <value>來回機票 {0} 張</value>
  </data>
  <data name="txtWinLossReward_Coupon" xml:space="preserve">
    <value>食飛 ${0}</value>
  </data>
  <data name="txtWinLossReward_RoomReservation" xml:space="preserve">
    <value>酒店房間 {0} 晚</value>
  </data>
  <data name="txtWinLossTable" xml:space="preserve">
    <value>輸嬴數表</value>
  </data>
  <data name="wDay" xml:space="preserve">
    <value>日</value>
  </data>
  <data name="btnNewThisRollTran" xml:space="preserve">
    <value>新增此場</value>
  </data>
  <data name="global_txtRollTypeCodeCaptital" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="global_txtRollTypeCodeCash" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="global_txtRollTypeCodeCashChip" xml:space="preserve">
    <value>M現金</value>
  </data>
  <data name="global_txtRollTypeCodeCIOU" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="global_txtRollTypeCodeIOU" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="global_txtRollTypeCodeMIO" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="txtInfoRollTranHasAdjust" xml:space="preserve">
    <value>本轉碼已完成月調整，故不能作任何轉碼管理操作。如要繼續，請先前往「轉碼月轉換」還原此轉碼之月調整。</value>
  </data>
  <data name="txtRollTranMgmLst" xml:space="preserve">
    <value>轉碼管理</value>
  </data>
  <data name="wCageDailyBal" xml:space="preserve">
    <value>本廳日轉碼</value>
  </data>
  <data name="wCageMthBal" xml:space="preserve">
    <value>本廳月轉碼</value>
  </data>
  <data name="wCapitalAmt" xml:space="preserve">
    <value>股本(萬)</value>
  </data>
  <data name="wCashAmt" xml:space="preserve">
    <value>現金(萬)</value>
  </data>
  <data name="wChipCode" xml:space="preserve">
    <value>籌碼代號</value>
  </data>
  <data name="wCIOUAmt" xml:space="preserve">
    <value>公司U(萬)</value>
  </data>
  <data name="wCustWinLoss" xml:space="preserve">
    <value>輸贏數(萬)</value>
  </data>
  <data name="wInDateTime" xml:space="preserve">
    <value>入場時間</value>
  </data>
  <data name="wIOUAmt" xml:space="preserve">
    <value>IOU(萬)</value>
  </data>
  <data name="wRatio" xml:space="preserve">
    <value>比例(%)</value>
  </data>
  <data name="wRollDateTime" xml:space="preserve">
    <value>轉碼時間</value>
  </data>
  <data name="wRolling_10K" xml:space="preserve">
    <value>轉碼數(萬)</value>
  </data>
  <data name="wRollInput" xml:space="preserve">
    <value>輸入數(萬)</value>
  </data>
  <data name="wRollRatio" xml:space="preserve">
    <value>按比例數(萬)</value>
  </data>
  <data name="wRollShowType" xml:space="preserve">
    <value>數類</value>
  </data>
  <data name="txtTransferCard" xml:space="preserve">
    <value>過數卡</value>
  </data>
  <data name="txtCounterBal" xml:space="preserve">
    <value>櫃數表</value>
  </data>
  <data name="global_btnAddNew" xml:space="preserve">
    <value>新增</value>
  </data>
  <data name="global_btnPrintCounterAllSettle" xml:space="preserve">
    <value>列印三更結算表</value>
  </data>
  <data name="global_btnPrintRollDtl" xml:space="preserve">
    <value>列印轉碼細數表</value>
  </data>
  <data name="wCounterBalAudit" xml:space="preserve">
    <value>帳房日結表</value>
  </data>
  <data name="wNNChipForeignAmt" xml:space="preserve">
    <value>外館碼(萬)</value>
  </data>
  <data name="wPromissoryNoteAmt" xml:space="preserve">
    <value>本票(萬)</value>
  </data>
  <data name="wTotalCardDeposite" xml:space="preserve">
    <value>總大簿</value>
  </data>
  <data name="wtotalCashDeposite" xml:space="preserve">
    <value>總存款</value>
  </data>
  <data name="wTotalIOU" xml:space="preserve">
    <value>總貸款</value>
  </data>
  <data name="txtCounterBalBPlayRemark1" xml:space="preserve">
    <value>轉碼比對= (上更餘數 + 本更買泥碼 - 本更轉碼) - (本更餘泥碼)</value>
  </data>
  <data name="txtCounterBalBPlayRemark1a" xml:space="preserve">
    <value>本月轉碼比對=(上月餘泥碼 + 本月買泥碼 - 本月轉碼數) - (本更餘泥碼)</value>
  </data>
  <data name="txtCounterBalBPlayRemark2" xml:space="preserve">
    <value>銀頭比對= (本更餘泥碼 + 現金籌碼 + 現金) - (櫃面銀頭)</value>
  </data>
  <data name="txtCounterBalBPlayRemark3" xml:space="preserve">
    <value>銀頭結算= (櫃面銀頭)</value>
  </data>
  <data name="txtCounterBalBPlayRemark4" xml:space="preserve">
    <value>可動用銀頭= (櫃面銀頭)</value>
  </data>
  <data name="txtBuyChipCurrMthRpt" xml:space="preserve">
    <value>本月買碼表</value>
  </data>
  <data name="txtCounterBalRemark1" xml:space="preserve">
    <value>轉碼比對= (上更餘數 + 本更買泥碼 - 本更轉碼) - (本更餘泥碼)</value>
  </data>
  <data name="txtCounterBalRemark1a" xml:space="preserve">
    <value>本月轉碼比對=(上月餘泥碼 + 本月買泥碼 - 本月轉碼數) - (本更餘泥碼)</value>
  </data>
  <data name="txtCounterBalRemark2" xml:space="preserve">
    <value>銀頭比對= (本更餘泥碼 + 現金籌碼 + iou借貨 + 個人借貸 + 現金) - (櫃面銀頭 + 對外借用銀頭 + 借入客人存碼)</value>
  </data>
  <data name="txtCounterBalRemark3" xml:space="preserve">
    <value>銀頭結算= (櫃面銀頭 - 對外借入銀頭 - 借入客人存碼)</value>
  </data>
  <data name="txtCounterBalRemark4" xml:space="preserve">
    <value>可動用銀頭(包括借入)= (櫃面銀頭 + 對外借入銀頭 + 借入客人存碼)</value>
  </data>
  <data name="txtSignature" xml:space="preserve">
    <value>簽名</value>
  </data>
  <data name="wBalToBeSettledAmt" xml:space="preserve">
    <value>掛數總數(萬)</value>
  </data>
  <data name="wCashChipAmt" xml:space="preserve">
    <value>現金碼(萬)</value>
  </data>
  <data name="wCountCompCapitalAmt" xml:space="preserve">
    <value>實際銀頭(萬)</value>
  </data>
  <data name="wNNChipAmt" xml:space="preserve">
    <value>泥碼(萬)</value>
  </data>
  <data name="wShiftCapitalInAmt" xml:space="preserve">
    <value>股本存卡總數(萬)</value>
  </data>
  <data name="wShiftCapitalMInAmt" xml:space="preserve">
    <value>月息存單總數(萬)</value>
  </data>
  <data name="wShiftCapitalMOutAmt" xml:space="preserve">
    <value>月息取單總數(萬)</value>
  </data>
  <data name="wShiftCapitalOutAmt" xml:space="preserve">
    <value>股本取卡總數(萬)</value>
  </data>
  <data name="wShiftChipBInAmt" xml:space="preserve">
    <value>存卡總數(萬)</value>
  </data>
  <data name="wShiftChipBOutAmt" xml:space="preserve">
    <value>取卡總數(萬)</value>
  </data>
  <data name="wShiftChipIInAmt" xml:space="preserve">
    <value>存單總數(萬)</value>
  </data>
  <data name="wShiftChipIOutAmt" xml:space="preserve">
    <value>取單總數(萬)</value>
  </data>
  <data name="wShiftFreezeInAmt" xml:space="preserve">
    <value>凍M存卡總數(萬)</value>
  </data>
  <data name="wShiftFreezeOutAmt" xml:space="preserve">
    <value>凍M取卡總數(萬)</value>
  </data>
  <data name="wShiftIOUInAmt" xml:space="preserve">
    <value>出M總數(萬)</value>
  </data>
  <data name="wShiftIOUOutAmt" xml:space="preserve">
    <value>回M總數(萬)</value>
  </data>
  <data name="wShiftRollingAmt" xml:space="preserve">
    <value>轉碼總數(萬)</value>
  </data>
  <data name="wShiftYellowInAmt" xml:space="preserve">
    <value>食貨存卡總數(萬)</value>
  </data>
  <data name="wShiftYellowOutAmt" xml:space="preserve">
    <value>食貨取卡總數(萬)</value>
  </data>
  <data name="wTotalAmount10k" xml:space="preserve">
    <value>總金額(萬)</value>
  </data>
  <data name="wTranCompCapitalAmt" xml:space="preserve">
    <value>應有銀頭(萬)</value>
  </data>
  <data name="txtCanUsedCompCapital" xml:space="preserve">
    <value>可動用銀頭</value>
  </data>
  <data name="txtCash" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="txtCChip_Cur" xml:space="preserve">
    <value>本更餘現金碼</value>
  </data>
  <data name="txtCheque" xml:space="preserve">
    <value>支票/本票</value>
  </data>
  <data name="txtChipTranBShift" xml:space="preserve">
    <value>本更存卡數</value>
  </data>
  <data name="txtCompCapital" xml:space="preserve">
    <value>櫃面銀頭</value>
  </data>
  <data name="txtCompCapital_Lend" xml:space="preserve">
    <value>對外借入銀頭</value>
  </data>
  <data name="txtCounterBalAmt" xml:space="preserve">
    <value>銀頭對比</value>
  </data>
  <data name="txtCounterBalNoIOU" xml:space="preserve">
    <value>銀頭結算</value>
  </data>
  <data name="txtIOU" xml:space="preserve">
    <value>本廳MARKER</value>
  </data>
  <data name="txtMthBuyChipTot" xml:space="preserve">
    <value>本月買碼數</value>
  </data>
  <data name="txtMthRollingTot" xml:space="preserve">
    <value>本月轉碼數</value>
  </data>
  <data name="txtNNChipMth_BF" xml:space="preserve">
    <value>上月餘泥碼</value>
  </data>
  <data name="txtNNChip_BF" xml:space="preserve">
    <value>上更餘泥碼</value>
  </data>
  <data name="txtNNChip_Buy" xml:space="preserve">
    <value>本更買泥碼</value>
  </data>
  <data name="txtNNChip_Cur" xml:space="preserve">
    <value>本更餘泥碼</value>
  </data>
  <data name="txtRollingBalAmt" xml:space="preserve">
    <value>轉碼對比</value>
  </data>
  <data name="txtRollingShift" xml:space="preserve">
    <value>本更轉碼數</value>
  </data>
  <data name="txtSTORECHIP_LEND" xml:space="preserve">
    <value>借入客人存碼</value>
  </data>
  <data name="typeROLLTRANMGMLST_Core" xml:space="preserve">
    <value>轉碼管理</value>
  </data>
  <data name="txtBuyChip" xml:space="preserve">
    <value>買碼</value>
  </data>
  <data name="wCardCode" xml:space="preserve">
    <value>卡號</value>
  </data>
  <data name="wDiffAmt10k" xml:space="preserve">
    <value>差額(萬)</value>
  </data>
  <data name="GroupByCardCode" xml:space="preserve">
    <value>以卡號分類</value>
  </data>
  <data name="txtAction" xml:space="preserve">
    <value>功能鍵</value>
  </data>
  <data name="txtLastRolling" xml:space="preserve">
    <value>最後轉碼</value>
  </data>
  <data name="txtLoadShift" xml:space="preserve">
    <value>開啟更數資料</value>
  </data>
  <data name="txtRptDtl" xml:space="preserve">
    <value>細數表</value>
  </data>
  <data name="txtOperationCounterBal" xml:space="preserve">
    <value>營運櫃數表</value>
  </data>
  <data name="txtDepositTime" xml:space="preserve">
    <value>存取時間</value>
  </data>
  <data name="txtGameSeq" xml:space="preserve">
    <value>局號</value>
  </data>
  <data name="txtGrpPlace_10k" xml:space="preserve">
    <value>上下數(萬)</value>
  </data>
  <data name="txtIOU10k" xml:space="preserve">
    <value>借款(萬)</value>
  </data>
  <data name="txtIOUTime" xml:space="preserve">
    <value>借貸時間</value>
  </data>
  <data name="txtNumOfDay" xml:space="preserve">
    <value>天數</value>
  </data>
  <data name="txtStart" xml:space="preserve">
    <value>開始</value>
  </data>
  <data name="txtStop" xml:space="preserve">
    <value>停止</value>
  </data>
  <data name="txtTotalAmount10k" xml:space="preserve">
    <value>總額(萬)</value>
  </data>
  <data name="txtUpdt" xml:space="preserve">
    <value>更新日期</value>
  </data>
  <data name="wCapital" xml:space="preserve">
    <value>本金(萬)</value>
  </data>
  <data name="wDailyBal" xml:space="preserve">
    <value>本日累計(萬)</value>
  </data>
  <data name="wGameStatus" xml:space="preserve">
    <value>本單狀態</value>
  </data>
  <data name="wIntroducer" xml:space="preserve">
    <value>來貨人</value>
  </data>
  <data name="wMthBal" xml:space="preserve">
    <value>本月累計(萬)</value>
  </data>
  <data name="wMutiplyPercentage" xml:space="preserve">
    <value>拖數(%)</value>
  </data>
  <data name="wNNChip10k" xml:space="preserve">
    <value>特碼(萬)</value>
  </data>
  <data name="wPendingAmount" xml:space="preserve">
    <value>倘欠(萬)</value>
  </data>
  <data name="wRollingAmt" xml:space="preserve">
    <value>轉碼(萬)</value>
  </data>
  <data name="wStatusOperate" xml:space="preserve">
    <value>營運狀態</value>
  </data>
  <data name="wStatusPlace" xml:space="preserve">
    <value>場面狀態</value>
  </data>
  <data name="wTotalPendingAmount" xml:space="preserve">
    <value>未提取餘額(萬)</value>
  </data>
  <data name="global_btnExportAll" xml:space="preserve">
    <value>匯出全部</value>
  </data>
  <data name="msgRptNeedAgentCd" xml:space="preserve">
    <value>戶口必須填寫</value>
  </data>
  <data name="txtAgentRoveTranDtl" xml:space="preserve">
    <value>巨額資料</value>
  </data>
  <data name="txtImportRove" xml:space="preserve">
    <value>匯入巨額資料</value>
  </data>
  <data name="btnSetType" xml:space="preserve">
    <value>加彩</value>
  </data>
  <data name="txtBPlayRefNo2" xml:space="preserve">
    <value>B數編號</value>
  </data>
  <data name="txtBPlayRefNoSample" xml:space="preserve">
    <value>例如: BTA00019, BTA000031</value>
  </data>
  <data name="txtchkIsCash" xml:space="preserve">
    <value>客人提供現金作轉碼？</value>
  </data>
  <data name="txtForeignRefNo2" xml:space="preserve">
    <value>海外編號</value>
  </data>
  <data name="txtForeignRefNoSample" xml:space="preserve">
    <value>例如: FTA00018, FTA000030</value>
  </data>
  <data name="txtIOURecord" xml:space="preserve">
    <value>借貸單</value>
  </data>
  <data name="txtOperateRefNoSample" xml:space="preserve">
    <value>例如: YTA00017, YTA000029</value>
  </data>
  <data name="wAgentStaffName" xml:space="preserve">
    <value>交易人名稱</value>
  </data>
  <data name="wIOUOutstanding" xml:space="preserve">
    <value>倘欠貸款(萬)</value>
  </data>
  <data name="wIOUOutstandingF" xml:space="preserve">
    <value>海外倘欠貸款(萬)</value>
  </data>
  <data name="wIOUOutstandingY" xml:space="preserve">
    <value>營運倘欠貸款(萬)</value>
  </data>
  <data name="wTotMarkerOutstandingAmt" xml:space="preserve">
    <value>總倘欠貸款(萬)</value>
  </data>
  <data name="wIsLocalCapital" xml:space="preserve">
    <value>本地現金</value>
  </data>
  <data name="wIsMthInterestRoll" xml:space="preserve">
    <value>M現金</value>
  </data>
  <data name="wRollCageAmt" xml:space="preserve">
    <value>本廳本日(萬)</value>
  </data>
  <data name="wRollCageMonthlyAmt" xml:space="preserve">
    <value>本廳本月(萬)</value>
  </data>
  <data name="wRollDailyAmt" xml:space="preserve">
    <value>集團本日(萬)</value>
  </data>
  <data name="wRollMothlyAmt" xml:space="preserve">
    <value>集團本月(萬)</value>
  </data>
  <data name="txtDetailInfo" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="msgRegNotMath" xml:space="preserve">
    <value>不符合所屬輸入規則，請把鼠標移到字樣處查看規則</value>
  </data>
  <data name="txtIOURefNo" xml:space="preserve">
    <value>借貸編號</value>
  </data>
  <data name="txtSystem" xml:space="preserve">
    <value>系統</value>
  </data>
  <data name="txtPrevious" xml:space="preserve">
    <value>承前</value>
  </data>
  <data name="typeCAPITALTRANO_Report" xml:space="preserve">
    <value>營運卡報表</value>
  </data>
  <data name="typeCHIPTRANB_Report" xml:space="preserve">
    <value>存卡報表</value>
  </data>
  <data name="txtInfoOnlyAgent" xml:space="preserve">
    <value>只能選擇代理戶口</value>
  </data>
  <data name="global_btnSelect" xml:space="preserve">
    <value>選取</value>
  </data>
  <data name="txtDetail" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="txtForeignTourNo" xml:space="preserve">
    <value>海外團號碼</value>
  </data>
  <data name="txtChipB10k" xml:space="preserve">
    <value>存卡(萬)</value>
  </data>
  <data name="global_txtCreditTranStatusC" xml:space="preserve">
    <value>無效</value>
  </data>
  <data name="global_txtCreditTranStatusO" xml:space="preserve">
    <value>有效</value>
  </data>
  <data name="txtCreditTranDtl" xml:space="preserve">
    <value>代理信貸額記錄</value>
  </data>
  <data name="txtCreditTranLst" xml:space="preserve">
    <value>信貸額管理</value>
  </data>
  <data name="wCashLoanAmt" xml:space="preserve">
    <value>個人信貸額(萬)</value>
  </data>
  <data name="wCreditAmt" xml:space="preserve">
    <value>信貸額(萬)</value>
  </data>
  <data name="wCreditCapitalAmt" xml:space="preserve">
    <value>U可簽額(萬)</value>
  </data>
  <data name="wForeignCapitalAmt" xml:space="preserve">
    <value>海外股本(萬)</value>
  </data>
  <data name="wMasterCasinoCreditAmt" xml:space="preserve">
    <value>娛樂場額(萬)</value>
  </data>
  <data name="wMthInterestAmt" xml:space="preserve">
    <value>月息(萬)</value>
  </data>
  <data name="wURemarkOptCIOU" xml:space="preserve">
    <value>公Ｕ</value>
  </data>
  <data name="wURemarkOptPause" xml:space="preserve">
    <value>停Ｍ</value>
  </data>
  <data name="global_msgDuplicateAgent" xml:space="preserve">
    <value>已有相同戶口</value>
  </data>
  <data name="txtBChipWithDrawalType" xml:space="preserve">
    <value>提款類型</value>
  </data>
  <data name="global_txtChipTranTypeB_10K" xml:space="preserve">
    <value>存卡(萬)</value>
  </data>
  <data name="txtShowAllRecord" xml:space="preserve">
    <value>顯示全部</value>
  </data>
  <data name="global_msgInputAmountError" xml:space="preserve">
    <value>輸入金額不正確</value>
  </data>
  <data name="typeChipRtnType_IOU" xml:space="preserve">
    <value>借貸單</value>
  </data>
  <data name="typeChipRtnType_CH" xml:space="preserve">
    <value>個人借貸單</value>
  </data>
  <data name="typeChipRtnType_Y" xml:space="preserve">
    <value>營運借貸單</value>
  </data>
  <data name="typeChipRtnType_F" xml:space="preserve">
    <value>海外借貸單</value>
  </data>
  <data name="wStatus_S_InterestDist" xml:space="preserve">
    <value>已派息</value>
  </data>
  <data name="wStatus_T_InterestCancel" xml:space="preserve">
    <value>取消派息</value>
  </data>
  <data name="txtCHSCard" xml:space="preserve">
    <value>海外股本存卡</value>
  </data>
  <data name="typeCAPITALTRANC_Report" xml:space="preserve">
    <value>海外股本報表</value>
  </data>
  <data name="typeCAPITALTRANF_Report" xml:space="preserve">
    <value>凍M報表</value>
  </data>
  <data name="typeCAPITALTRANS_Report" xml:space="preserve">
    <value>股本報表</value>
  </data>
  <data name="wLstOverDueDay" xml:space="preserve">
    <value>最長天期</value>
  </data>
  <data name="wPaymentRemark" xml:space="preserve">
    <value>還款備註</value>
  </data>
  <data name="wRemind" xml:space="preserve">
    <value>注意事項</value>
  </data>
  <data name="txtIOUReturn_10K" xml:space="preserve">
    <value>還款(萬)</value>
  </data>
  <data name="txtPenaltyRtnAmount10k" xml:space="preserve">
    <value>歸還罰息(萬)</value>
  </data>
  <data name="global_txtPenaltyAmt10K" xml:space="preserve">
    <value>罰息金額(萬)</value>
  </data>
  <data name="global_txtAgentStaffName" xml:space="preserve">
    <value>交易人名稱</value>
  </data>
  <data name="global_txtBPlayRefNo2" xml:space="preserve">
    <value>B數編號</value>
  </data>
  <data name="global_txtCustRemark" xml:space="preserve">
    <value>客人特徵</value>
  </data>
  <data name="global_txtRolling" xml:space="preserve">
    <value>轉碼數</value>
  </data>
  <data name="global_txtRollingCapital" xml:space="preserve">
    <value>轉碼本金</value>
  </data>
  <data name="global_txtStatus" xml:space="preserve">
    <value>狀態</value>
  </data>
  <data name="typePLACE_Core" xml:space="preserve">
    <value>場面管理</value>
  </data>
  <data name="wWinLossCapital" xml:space="preserve">
    <value>入枱本金(萬)</value>
  </data>
  <data name="global_btnNewWinLossTran" xml:space="preserve">
    <value>新增客人</value>
  </data>
  <data name="global_btnRefresh" xml:space="preserve">
    <value>更新</value>
  </data>
  <data name="global_btnReward" xml:space="preserve">
    <value>獎勵名單</value>
  </data>
  <data name="global_btnStatusAOnly" xml:space="preserve">
    <value>在場</value>
  </data>
  <data name="global_btnToday" xml:space="preserve">
    <value>今日</value>
  </data>
  <data name="global_txtCompanyGroup" xml:space="preserve">
    <value>集團</value>
  </data>
  <data name="global_txtNumberOfCustomer" xml:space="preserve">
    <value>全日人客數</value>
  </data>
  <data name="global_txtPotential" xml:space="preserve">
    <value>潛質</value>
  </data>
  <data name="global_txtRollTranDtlKEY" xml:space="preserve">
    <value>加彩明細</value>
  </data>
  <data name="global_txtThisCage" xml:space="preserve">
    <value>本廳</value>
  </data>
  <data name="global_txtTotalAmount" xml:space="preserve">
    <value>總額</value>
  </data>
  <data name="global_txtUpdated" xml:space="preserve">
    <value>有新的資料, 請更新!</value>
  </data>
  <data name="global_txtWinLoss_10K" xml:space="preserve">
    <value>輸贏數(萬)</value>
  </data>
  <data name="global_txtAgentCardCodeDisplay" xml:space="preserve">
    <value>轉碼卡</value>
  </data>
  <data name="typeCOUNTERROLLING_Core" xml:space="preserve">
    <value>帳房轉碼</value>
  </data>
  <data name="btnWriteTempCard" xml:space="preserve">
    <value>寫入臨時卡</value>
  </data>
  <data name="txtRollTranTenk" xml:space="preserve">
    <value>加彩(萬)</value>
  </data>
  <data name="txtLaonTenk" xml:space="preserve">
    <value>借貸(萬)</value>
  </data>
  <data name="txtRtnAmt10K" xml:space="preserve">
    <value>歸還(萬)</value>
  </data>
  <data name="txtRollTranTime" xml:space="preserve">
    <value>加彩時間</value>
  </data>
  <data name="txtCompGroupRollDailyAmt" xml:space="preserve">
    <value>集團本日(萬)</value>
  </data>
  <data name="txtCompGroupRollMothlyAmt" xml:space="preserve">
    <value>集團本月(萬)</value>
  </data>
  <data name="txtRollCageAmt" xml:space="preserve">
    <value>本廳本日(萬)</value>
  </data>
  <data name="txtRollCageMonthlyAmt" xml:space="preserve">
    <value>本廳本月(萬)</value>
  </data>
  <data name="txtValidRecordOnly" xml:space="preserve">
    <value>只有有效記錄</value>
  </data>
  <data name="global_txtAgentLevelAndType" xml:space="preserve">
    <value>身份與級別</value>
  </data>
  <data name="typeCREDITLST_Core" xml:space="preserve">
    <value>代理信貸額管理</value>
  </data>
  <data name="typeCREDITDTL_Core" xml:space="preserve">
    <value>代理信貸額記錄</value>
  </data>
  <data name="txtCommon" xml:space="preserve">
    <value>通用</value>
  </data>
  <data name="txtSettleAlone" xml:space="preserve">
    <value>獨立結算</value>
  </data>
  <data name="global_btnWithdraw" xml:space="preserve">
    <value>提取</value>
  </data>
  <data name="wCreditDay" xml:space="preserve">
    <value>寬限天數</value>
  </data>
  <data name="wPercent" xml:space="preserve">
    <value>息率(分)</value>
  </data>
  <data name="txtCurrAmt" xml:space="preserve">
    <value>現有</value>
  </data>
  <data name="txtIsAllLine" xml:space="preserve">
    <value>是否查詢所有線</value>
  </data>
  <data name="txtIsViewAll" xml:space="preserve">
    <value>是否查詢所有場資料</value>
  </data>
  <data name="global_btnExit" xml:space="preserve">
    <value>離開</value>
  </data>
  <data name="global_txtTelbDetail" xml:space="preserve">
    <value>電投</value>
  </data>
  <data name="txtRollStatusOptC" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="txtRollStatusOptO" xml:space="preserve">
    <value>在場</value>
  </data>
  <data name="msgRptNeedAgentCd_I" xml:space="preserve">
    <value>即出咭戶口必須填寫</value>
  </data>
  <data name="txtGambling" xml:space="preserve">
    <value>博彩</value>
  </data>
  <data name="typeCAPITALDTL_Core" xml:space="preserve">
    <value>月息存單</value>
  </data>
  <data name="global_btnDelete" xml:space="preserve">
    <value>刪除</value>
  </data>
  <data name="global_txtChip" xml:space="preserve">
    <value>籌碼</value>
  </data>
  <data name="txtAllDepositor" xml:space="preserve">
    <value>全部存款人</value>
  </data>
  <data name="txtFBPlayRefNo" xml:space="preserve">
    <value>海外佔成編號</value>
  </data>
  <data name="txtIsIncludeCredit" xml:space="preserve">
    <value>計入戶口信貸額</value>
  </data>
  <data name="txtIssueInterestDate" xml:space="preserve">
    <value>月息日</value>
  </data>
  <data name="txtMonthRate" xml:space="preserve">
    <value>月息率(%)</value>
  </data>
  <data name="txtWithdrawRecords" xml:space="preserve">
    <value>取碼記錄</value>
  </data>
  <data name="wCapitalMOrgDate" xml:space="preserve">
    <value>存入日期</value>
  </data>
  <data name="global_msgInfoCounterBalAuditHasVarient" xml:space="preserve">
    <value>帳房日結有差額，請確認繼續儲存。</value>
  </data>
  <data name="txtCounterBalAmount" xml:space="preserve">
    <value>買碼數(萬)</value>
  </data>
  <data name="txtCounterBalTime" xml:space="preserve">
    <value>買碼時間</value>
  </data>
  <data name="wCashChip" xml:space="preserve">
    <value>現碼</value>
  </data>
  <data name="txtMsgInfoSameRefNo" xml:space="preserve">
    <value>單號碼已使用，請使用新號碼。</value>
  </data>
  <data name="txtOperateNoAlreadyBind" xml:space="preserve">
    <value>綁單已存在</value>
  </data>
  <data name="txtMsgCannotFind" xml:space="preserve">
    <value>找不到</value>
  </data>
  <data name="txtWithdrawer" xml:space="preserve">
    <value>提款人</value>
  </data>
  <data name="wNewRefNo" xml:space="preserve">
    <value>新存單編號</value>
  </data>
  <data name="wNNChip" xml:space="preserve">
    <value>特碼</value>
  </data>
  <data name="txtCapitalM" xml:space="preserve">
    <value>月息單</value>
  </data>
  <data name="txtMsgInfoCannotEditOtherCompanyData" xml:space="preserve">
    <value>不能修改其他場的數據資料，如有需要，請按右下角經授權的場作出修改。</value>
  </data>
  <data name="global_btnCheckOut" xml:space="preserve">
    <value>離場</value>
  </data>
  <data name="global_btnCustomer" xml:space="preserve">
    <value>選取人客</value>
  </data>
  <data name="global_btnNow" xml:space="preserve">
    <value>現在</value>
  </data>
  <data name="global_btnRouteUsrID" xml:space="preserve">
    <value>連接路址機</value>
  </data>
  <data name="global_btnRouteWinLoss" xml:space="preserve">
    <value>獲取路址機輸贏數</value>
  </data>
  <data name="global_btnUpdate" xml:space="preserve">
    <value>更改</value>
  </data>
  <data name="global_txtCapital10k" xml:space="preserve">
    <value>本金(萬)</value>
  </data>
  <data name="global_txtCapLimitAmt" xml:space="preserve">
    <value>封頂數</value>
  </data>
  <data name="global_txtDetails" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="global_txtElite" xml:space="preserve">
    <value>尊華會</value>
  </data>
  <data name="global_txtLikeRemark" xml:space="preserve">
    <value>客人喜好</value>
  </data>
  <data name="global_txtNotObtained" xml:space="preserve">
    <value>未獲取</value>
  </data>
  <data name="global_txtObtained" xml:space="preserve">
    <value>已獲取</value>
  </data>
  <data name="global_txtOperateExternal" xml:space="preserve">
    <value>私營</value>
  </data>
  <data name="global_txtOperateType" xml:space="preserve">
    <value>營運種類</value>
  </data>
  <data name="global_txtWinLoss10k" xml:space="preserve">
    <value>輸贏數(萬)</value>
  </data>
  <data name="txtConnectedRoute" xml:space="preserve">
    <value>已連接路址機</value>
  </data>
  <data name="txtNotConnectedRoute" xml:space="preserve">
    <value>未連接路址機</value>
  </data>
  <data name="typePLACE_CUST_Core" xml:space="preserve">
    <value>客人</value>
  </data>
  <data name="txtMsgInfoAgentRequired" xml:space="preserve">
    <value>必需選取戶口</value>
  </data>
  <data name="txtMsgInfoBPlayRefNoRequired" xml:space="preserve">
    <value>必需要有B數單</value>
  </data>
  <data name="txtTableBookingStatus_Booked" xml:space="preserve">
    <value>已預訂</value>
  </data>
  <data name="txtTableBookingStatus_Empty" xml:space="preserve">
    <value>閒置</value>
  </data>
  <data name="txtTableBookingStatus_Occupied" xml:space="preserve">
    <value>使用中</value>
  </data>
  <data name="txtVIPRoom" xml:space="preserve">
    <value>貴賓廳</value>
  </data>
  <data name="typeTABLETRANLST_Core" xml:space="preserve">
    <value>貴賓廳賭枱管理</value>
  </data>
  <data name="wBookDateTime" xml:space="preserve">
    <value>預訂時間</value>
  </data>
  <data name="wRoomCName" xml:space="preserve">
    <value>房號</value>
  </data>
  <data name="wTableCName" xml:space="preserve">
    <value>枱號</value>
  </data>
  <data name="wAgentCName" xml:space="preserve">
    <value>戶主</value>
  </data>
  <data name="wPrtPage" xml:space="preserve">
    <value>頁數</value>
  </data>
  <data name="wPrtRow" xml:space="preserve">
    <value>行數</value>
  </data>
  <data name="txtPrintSet" xml:space="preserve">
    <value>列印設定</value>
  </data>
  <data name="txtConfirmOutSide" xml:space="preserve">
    <value>請確認離場</value>
  </data>
  <data name="global_txtAgentType" xml:space="preserve">
    <value>戶口類型</value>
  </data>
  <data name="global_txtPercentageSign" xml:space="preserve">
    <value>佔成(%)</value>
  </data>
  <data name="global_txtRouteUsrID" xml:space="preserve">
    <value>路址用戶ID</value>
  </data>
  <data name="global_txtVIPRoom" xml:space="preserve">
    <value>貴賓廳</value>
  </data>
  <data name="global_btnBook" xml:space="preserve">
    <value>預訂</value>
  </data>
  <data name="typeTABLETRANDTL_Core" xml:space="preserve">
    <value>貴賓房配置記錄</value>
  </data>
  <data name="typeWINLOSE_Core" xml:space="preserve">
    <value>上下數</value>
  </data>
  <data name="txtBalanceToBe" xml:space="preserve">
    <value>掛數</value>
  </data>
  <data name="txtRoom" xml:space="preserve">
    <value>房</value>
  </data>
  <data name="txtTableTranStatusOptC" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="txtTableTranStatusOptO" xml:space="preserve">
    <value>有效</value>
  </data>
  <data name="txtMarkerReturnTypeC" xml:space="preserve">
    <value>現碼還M</value>
  </data>
  <data name="txtMarkerReturnTypeM" xml:space="preserve">
    <value>M還M</value>
  </data>
  <data name="txtMarkerReturnTypeR" xml:space="preserve">
    <value>存M還M</value>
  </data>
  <data name="txtMarkerReturnTypeW" xml:space="preserve">
    <value>嬴錢回舊M</value>
  </data>
  <data name="txtMarkerReturnTypeS" xml:space="preserve">
    <value>佣金回M</value>
  </data>
  <data name="typeChip_StoreM" xml:space="preserve">
    <value>存M</value>
  </data>
  <data name="global_txtHoldChipAmt10K" xml:space="preserve">
    <value>凍結存款(萬)</value>
  </data>
  <data name="wStoreNegativeAmt10K" xml:space="preserve">
    <value>可負數額(萬)</value>
  </data>
  <data name="wAvailableAmt10K" xml:space="preserve">
    <value>可動用結存(萬)</value>
  </data>
  <data name="type_IO" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="type_IR" xml:space="preserve">
    <value>歸還IOU</value>
  </data>
  <data name="type_SO" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="type_SR" xml:space="preserve">
    <value>歸還股本</value>
  </data>
  <data name="type_CIO" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="type_CIR" xml:space="preserve">
    <value>歸還公司U</value>
  </data>
  <data name="type_TSO" xml:space="preserve">
    <value>暫存</value>
  </data>
  <data name="type_TSR" xml:space="preserve">
    <value>取暫存</value>
  </data>
  <data name="type_CWO" xml:space="preserve">
    <value>客人未取</value>
  </data>
  <data name="type_CWR" xml:space="preserve">
    <value>客人已取</value>
  </data>
  <data name="txtTllRtnAmt10K" xml:space="preserve">
    <value>總還款額(萬)</value>
  </data>
  <data name="txtTllRtnPenalty10K" xml:space="preserve">
    <value>總還息額(萬)</value>
  </data>
  <data name="global_txtChipTranTypeI_10K" xml:space="preserve">
    <value>存單金額(萬)</value>
  </data>
  <data name="type_ICR" xml:space="preserve">
    <value>提單</value>
  </data>
  <data name="type_ICS" xml:space="preserve">
    <value>存單</value>
  </data>
  <data name="type_CASHR" xml:space="preserve">
    <value>提款</value>
  </data>
  <data name="type_CASHS" xml:space="preserve">
    <value>存款</value>
  </data>
  <data name="global_msgIOUAmountNoMatch" xml:space="preserve">
    <value>借貸單還款金額不符</value>
  </data>
  <data name="global_msgNoIOURecord" xml:space="preserve">
    <value>沒有對應借貸單</value>
  </data>
  <data name="global_txtLobby" xml:space="preserve">
    <value>大堂</value>
  </data>
  <data name="wGame10K" xml:space="preserve">
    <value>本場累計(萬)</value>
  </data>
  <data name="txtPrintTime" xml:space="preserve">
    <value>列印時間</value>
  </data>
  <data name="txtRollingSummaryPrintTableHeader" xml:space="preserve">
    <value>次序   時間　　轉碼　　本場　　本日</value>
  </data>
  <data name="txtGrpChip" xml:space="preserve">
    <value>存單</value>
  </data>
  <data name="txtGrpMarker" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="txtGrpWinLoss" xml:space="preserve">
    <value>枱面</value>
  </data>
  <data name="wCustCName" xml:space="preserve">
    <value>存款人</value>
  </data>
  <data name="wCustEName" xml:space="preserve">
    <value>客人英文名稱</value>
  </data>
  <data name="wCustRemark" xml:space="preserve">
    <value>客人特徵</value>
  </data>
  <data name="typeLOOKUPCUSTOMER_Core" xml:space="preserve">
    <value>選取客人</value>
  </data>
  <data name="txtChipTypeA" xml:space="preserve">
    <value>A數</value>
  </data>
  <data name="txtChipTypeB" xml:space="preserve">
    <value>B數</value>
  </data>
  <data name="global_txtTransactionValue" xml:space="preserve">
    <value>交易金額</value>
  </data>
  <data name="wCrtCompNo" xml:space="preserve">
    <value>創建公司</value>
  </data>
  <data name="wCrtDept" xml:space="preserve">
    <value>創建部門</value>
  </data>
  <data name="typeCOUNTERBAL_Core" xml:space="preserve">
    <value>櫃數表</value>
  </data>
  <data name="typeOPERATIONCOUNTERBAL_Core" xml:space="preserve">
    <value>營運櫃數表</value>
  </data>
  <data name="txtNumber" xml:space="preserve">
    <value>編號</value>
  </data>
  <data name="global_txtAmountHKD10K" xml:space="preserve">
    <value>港幣金額(萬)</value>
  </data>
  <data name="txtRollingView" xml:space="preserve">
    <value>轉碼記錄</value>
  </data>
  <data name="global_msgUserPasswordRule" xml:space="preserve">
    <value>密碼必需6-10位 (包括最少一個數字, 一個大楷, 一個細楷)</value>
  </data>
  <data name="global_txtEName" xml:space="preserve">
    <value>英文姓名</value>
  </data>
  <data name="btnGenActCode" xml:space="preserve">
    <value>重設行動碼</value>
  </data>
  <data name="txtEliteRoyaltyCard" xml:space="preserve">
    <value>尊貴卡</value>
  </data>
  <data name="txtUploadSignature" xml:space="preserve">
    <value>簽名</value>
  </data>
  <data name="wRelatedAgentCodeIn" xml:space="preserve">
    <value>相關代理</value>
  </data>
  <data name="global_MsgXlsxError" xml:space="preserve">
    <value>導入的文件格式不對，請參照相應的導入模板</value>
  </data>
  <data name="txtGamblingEndTime" xml:space="preserve">
    <value>博彩完成時間</value>
  </data>
  <data name="txtGamblingStartTime" xml:space="preserve">
    <value>博彩開始時間</value>
  </data>
  <data name="txtHotelType" xml:space="preserve">
    <value>酒店類型</value>
  </data>
  <data name="wExpParentCode" xml:space="preserve">
    <value>消費類型</value>
  </data>
  <data name="wExpSubCode" xml:space="preserve">
    <value>消費分類</value>
  </data>
  <data name="txtShowCurrentMth" xml:space="preserve">
    <value>只顯示本月</value>
  </data>
  <data name="txtShowSettle" xml:space="preserve">
    <value>已歸還</value>
  </data>
  <data name="wExpOutstanding" xml:space="preserve">
    <value>尚欠費用</value>
  </data>
  <data name="global_msgPwdNotMatch" xml:space="preserve">
    <value>密碼與確認密碼不一致</value>
  </data>
  <data name="wActionCode" xml:space="preserve">
    <value>行動碼</value>
  </data>
  <data name="typeAGENTDTL_Core" xml:space="preserve">
    <value>戶口記錄</value>
  </data>
  <data name="typeAGENTMANAGER_Core" xml:space="preserve">
    <value>戶口經理版</value>
  </data>
  <data name="typeAGENTREMARKHISDTL_Core" xml:space="preserve">
    <value>戶口備註記錄</value>
  </data>
  <data name="typeAGENTROVEDTL_Core" xml:space="preserve">
    <value>戶口經理版</value>
  </data>
  <data name="typeAGENTROVETRANDTL_Core" xml:space="preserve">
    <value>巨額資料</value>
  </data>
  <data name="typeBUYCHIPCURRMTH_Core" xml:space="preserve">
    <value>本月買碼表</value>
  </data>
  <data name="typeBUYCHIPDTL_Core" xml:space="preserve">
    <value>櫃數表</value>
  </data>
  <data name="typeCOMPANYDTL_Core" xml:space="preserve">
    <value>公司記錄</value>
  </data>
  <data name="typeCREDITCONTROL_CONTACT_Core" xml:space="preserve">
    <value>信貸監控-聯絡資料</value>
  </data>
  <data name="typeCURRENCY_RATE_DTL_Core" xml:space="preserve">
    <value>貨幣匯率管理</value>
  </data>
  <data name="typeCUSTOMERDTL_Core" xml:space="preserve">
    <value>客人記錄</value>
  </data>
  <data name="typeDEVICEDTL_Core" xml:space="preserve">
    <value>裝置記錄</value>
  </data>
  <data name="typeEXPTRANCARDDTL_Core" xml:space="preserve">
    <value>卡消費記錄</value>
  </data>
  <data name="typeFOREIGNITEM_Core" xml:space="preserve">
    <value>海外團詳情</value>
  </data>
  <data name="typeIMPORTROVE_Core" xml:space="preserve">
    <value>匯入巨額資料</value>
  </data>
  <data name="typeAGENTEXT_Core" xml:space="preserve">
    <value>客人其他資訊</value>
  </data>
  <data name="typeINTERESTRATEDTL_Core" xml:space="preserve">
    <value>存款利息</value>
  </data>
  <data name="typeMARKERRPT_Core" xml:space="preserve">
    <value>借貸现况表</value>
  </data>
  <data name="typeROLEDTL_Core" xml:space="preserve">
    <value>權限管理</value>
  </data>
  <data name="typeROLLINGDTL_Core" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="typeROLLING_LST_Core" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="typeROVECUSTOMERDTL_Core" xml:space="preserve">
    <value>客人管理</value>
  </data>
  <data name="typeUSRDTL_Core" xml:space="preserve">
    <value>用戶管理</value>
  </data>
  <data name="typeCOUNTERBALSETTLE_Core" xml:space="preserve">
    <value>三更結算表</value>
  </data>
  <data name="action_DELETE_type" xml:space="preserve">
    <value>刪除</value>
  </data>
  <data name="action_IMPORT_type" xml:space="preserve">
    <value>匯入</value>
  </data>
  <data name="action_NEW_type" xml:space="preserve">
    <value>新增New</value>
  </data>
  <data name="txtAlreadySend" xml:space="preserve">
    <value>已發送</value>
  </data>
  <data name="txtBtnGenIOUWarnSMS" xml:space="preserve">
    <value>生成提示短訊</value>
  </data>
  <data name="txtBtnSendSms" xml:space="preserve">
    <value>發送短訊</value>
  </data>
  <data name="txtNeedNotSend" xml:space="preserve">
    <value>不發送</value>
  </data>
  <data name="txtNonExpiredMarker" xml:space="preserve">
    <value>未過期M</value>
  </data>
  <data name="txtShareGrp" xml:space="preserve">
    <value>戶口組</value>
  </data>
  <data name="txtShareWithDownLine" xml:space="preserve">
    <value>股東(包括下線)</value>
  </data>
  <data name="txtShowSubLevel" xml:space="preserve">
    <value>包下線</value>
  </data>
  <data name="txtSMSContent" xml:space="preserve">
    <value>短訊內容</value>
  </data>
  <data name="txtTestNumber" xml:space="preserve">
    <value>測試號碼</value>
  </data>
  <data name="wSMSDateTime" xml:space="preserve">
    <value>SMS發送時間</value>
  </data>
  <data name="txtRemittanceTranLst" xml:space="preserve">
    <value>匯款管理</value>
  </data>
  <data name="txtTransferredAmt10k" xml:space="preserve">
    <value>兌換金額(萬)</value>
  </data>
  <data name="typeREMITTANCETRANDTL_Core" xml:space="preserve">
    <value>匯率記錄</value>
  </data>
  <data name="typeREMITTANCETRANLST_Core" xml:space="preserve">
    <value>匯款管理</value>
  </data>
  <data name="wDeductedTransferredAmt" xml:space="preserve">
    <value>兌換金額(扣除手續費)</value>
  </data>
  <data name="wExchangeTo" xml:space="preserve">
    <value>兌換成</value>
  </data>
  <data name="wFromCurrCode" xml:space="preserve">
    <value>由貨幣</value>
  </data>
  <data name="wFromFxRate" xml:space="preserve">
    <value>匯率(乘)</value>
  </data>
  <data name="wFromFxRateDiv" xml:space="preserve">
    <value>匯率(除)</value>
  </data>
  <data name="wHandlingAmt" xml:space="preserve">
    <value>手續費</value>
  </data>
  <data name="wHandlingAmt10K" xml:space="preserve">
    <value>手續費(萬)</value>
  </data>
  <data name="wHandlingRate" xml:space="preserve">
    <value>手續費(率)</value>
  </data>
  <data name="wToCurrCode" xml:space="preserve">
    <value>至貨幣</value>
  </data>
  <data name="txtWithDownLv" xml:space="preserve">
    <value>連下線</value>
  </data>
  <data name="global_MsgInfoOverwriteOldRec" xml:space="preserve">
    <value>將覆蓋舊有記錄</value>
  </data>
  <data name="txtIOUWarnLst" xml:space="preserve">
    <value>借貸提示</value>
  </data>
  <data name="wForeignCapitalAmt1" xml:space="preserve">
    <value>海外股本(萬)</value>
  </data>
  <data name="wForeignCapitalAmt_CNY" xml:space="preserve">
    <value>海外股本CNY(萬)</value>
  </data>
  <data name="typeOTHERS_Core" xml:space="preserve">
    <value>其他</value>
  </data>
  <data name="typeIOUWARNLST_Core" xml:space="preserve">
    <value>借貸提示</value>
  </data>
  <data name="typeIOUWARNLST_F_Core" xml:space="preserve">
    <value>借貸提示(海外)</value>
  </data>
  <data name="typeIOUWARNLST_Y_Core" xml:space="preserve">
    <value>借貸提示(營運)</value>
  </data>
  <data name="txtRtnInfo" xml:space="preserve">
    <value>歸還資料</value>
  </data>
  <data name="wBFExpAmount" xml:space="preserve">
    <value>欠前消費</value>
  </data>
  <data name="wBFExpRtnAmount" xml:space="preserve">
    <value>欠費歸還</value>
  </data>
  <data name="txtCommission" xml:space="preserve">
    <value>佣金</value>
  </data>
  <data name="wDtLastFailed" xml:space="preserve">
    <value>最後登入錯誤時間</value>
  </data>
  <data name="msgNeedValue" xml:space="preserve">
    <value>必須填寫</value>
  </data>
  <data name="global_msgInfoAgentRequired" xml:space="preserve">
    <value>必需選取戶口</value>
  </data>
  <data name="global_msgInfoInputMissing" xml:space="preserve">
    <value>仍未輸入所有資料</value>
  </data>
  <data name="global_txtWinLoss" xml:space="preserve">
    <value>輸贏</value>
  </data>
  <data name="txtPenaltyRtnAmountHKD10k" xml:space="preserve">
    <value>港幣歸還罰息(萬)</value>
  </data>
  <data name="global_GroupBy" xml:space="preserve">
    <value>分類</value>
  </data>
  <data name="txtURollingDaily" xml:space="preserve">
    <value>轉碼按場日結</value>
  </data>
  <data name="wDailyBalHKD" xml:space="preserve">
    <value>本日折港幣總累計(萬)</value>
  </data>
  <data name="wMthBalHKD" xml:space="preserve">
    <value>本月折港幣總累計(萬)</value>
  </data>
  <data name="typePLACE_CHECKOUT_Core" xml:space="preserve">
    <value>離場及輸贏</value>
  </data>
  <data name="global_msgErrCannotBeZero" xml:space="preserve">
    <value>數值不能為零</value>
  </data>
  <data name="global_msgErrRtnGreaterOutstanding" xml:space="preserve">
    <value>扣減多於餘額</value>
  </data>
  <data name="global_msgInfoNotCurrCode" xml:space="preserve">
    <value>沒有此貨幣</value>
  </data>
  <data name="msgRptNeedDate" xml:space="preserve">
    <value>請選擇日期範圍</value>
  </data>
  <data name="txtCapitalTranM" xml:space="preserve">
    <value>月息單管理</value>
  </data>
  <data name="txtCapitalTranH" xml:space="preserve">
    <value>凍結存款單管理</value>
  </data>
  <data name="typeCAPITALTRAN_M_LST_Core" xml:space="preserve">
    <value>月息單管理</value>
  </data>
  <data name="typeCAPITALTRAN_H_LST_Core" xml:space="preserve">
    <value>凍結存款單管理</value>
  </data>
  <data name="txtShowStoreOutstanding" xml:space="preserve">
    <value>只顯示未取</value>
  </data>
  <data name="global_txtLanguage" xml:space="preserve">
    <value>語言</value>
  </data>
  <data name="global_txtRecipient" xml:space="preserve">
    <value>收件人</value>
  </data>
  <data name="txtExternalExp" xml:space="preserve">
    <value>外消費</value>
  </data>
  <data name="txtInternalExp" xml:space="preserve">
    <value>內消費</value>
  </data>
  <data name="txtCustChipTranBShift" xml:space="preserve">
    <value>本更電投存卡數</value>
  </data>
  <data name="wShiftCustChipBInAmt" xml:space="preserve">
    <value>電投客人存卡總數(萬)</value>
  </data>
  <data name="wShiftCustChipBOutAmt" xml:space="preserve">
    <value>電投客人取卡總數(萬)</value>
  </data>
  <data name="txtMsgCurrencyExchangeFormula" xml:space="preserve">
    <value>若匯率(乘) 及 (除) 均有數值, 會以匯率(乘) 為準計算
  兌換公式
    使用匯率(乘): 金額 * 匯率(乘) - 手續費
    使用匯率(除): 金額 / 匯率(除) - 手續費
  若手續費欄位為0時, 輸入手續費(率) 會自動計算手續費。</value>
  </data>
  <data name="txtMonthlyInterestWorkList" xml:space="preserve">
    <value>月息派發管理</value>
  </data>
  <data name="txtCompanyReal" xml:space="preserve">
    <value>公司實數</value>
  </data>
  <data name="txtInterestYearMth" xml:space="preserve">
    <value>派息月份</value>
  </data>
  <data name="txtPoint" xml:space="preserve">
    <value>積分</value>
  </data>
  <data name="txtPointHKD" xml:space="preserve">
    <value>積分HKD</value>
  </data>
  <data name="txtTtlCaplitalAmt" xml:space="preserve">
    <value>總月息HKD(萬)</value>
  </data>
  <data name="wBPenaltyInterest" xml:space="preserve">
    <value>尚餘罰息HKD(萬)</value>
  </data>
  <data name="wConfirmInterestAmt" xml:space="preserve">
    <value>確認派息(萬)</value>
  </data>
  <data name="wConfirmPenalty" xml:space="preserve">
    <value>確認罰息(萬)</value>
  </data>
  <data name="wConfirmPoint" xml:space="preserve">
    <value>確認積分HKD</value>
  </data>
  <data name="wDPenaltyInterest" xml:space="preserve">
    <value>扣減罰息HKD</value>
  </data>
  <data name="wDPenaltyInterestOrg" xml:space="preserve">
    <value>扣減罰息</value>
  </data>
  <data name="wInterestAmt" xml:space="preserve">
    <value>利息(萬)</value>
  </data>
  <data name="wInterestDateTime" xml:space="preserve">
    <value>派息日期</value>
  </data>
  <data name="wModifiedDate" xml:space="preserve">
    <value>更新時間</value>
  </data>
  <data name="wMonthlyRefNo" xml:space="preserve">
    <value>月息單號碼</value>
  </data>
  <data name="wMTotalChargeInterest" xml:space="preserve">
    <value>總扣減罰息(港幣)(萬)</value>
  </data>
  <data name="wMTotalChargePenalty" xml:space="preserve">
    <value>總尚餘罰息(港幣)(萬)</value>
  </data>
  <data name="wMTotalInterestCNY" xml:space="preserve">
    <value>總利息(人民幣)(萬)</value>
  </data>
  <data name="wMTotalInterest" xml:space="preserve">
    <value>總利息(港幣)(萬)</value>
  </data>
  <data name="wMTotalMonthPenalty" xml:space="preserve">
    <value>總罰息(港幣)(萬)</value>
  </data>
  <data name="wMTotalRealInterestCNY" xml:space="preserve">
    <value>總實出派息(人民幣)(萬)</value>
  </data>
  <data name="wMTotalRealInterest" xml:space="preserve">
    <value>總實出派息(港幣)(萬)</value>
  </data>
  <data name="wMTotalRealPoint" xml:space="preserve">
    <value>總派息積分(港幣)(萬)</value>
  </data>
  <data name="wOrgDate" xml:space="preserve">
    <value>原單日期</value>
  </data>
  <data name="wPenaltyInterest" xml:space="preserve">
    <value>罰息HKD(萬)</value>
  </data>
  <data name="wRealInterestAmt" xml:space="preserve">
    <value>實出利息(萬)</value>
  </data>
  <data name="typeBCounterBal_Core" xml:space="preserve">
    <value>B數櫃數表</value>
  </data>
  <data name="txtBFShiftCounterBal" xml:space="preserve">
    <value>請檢查上更資料是否已結算.</value>
  </data>
  <data name="txtAgentMonthly" xml:space="preserve">
    <value>客人月息</value>
  </data>
  <data name="txtEmployeeMonthly" xml:space="preserve">
    <value>員工月息</value>
  </data>
  <data name="txtMonthlyType" xml:space="preserve">
    <value>月息類型</value>
  </data>
  <data name="wMOnlyShowTStatus" xml:space="preserve">
    <value>只顯示取消派息</value>
  </data>
  <data name="wRegenMonthlyInterest" xml:space="preserve">
    <value>重新生成月息(只限未派月息)</value>
  </data>
  <data name="wStatusA_NoInterest" xml:space="preserve">
    <value>尚未派息</value>
  </data>
  <data name="wStatusI_MonthlyInterest" xml:space="preserve">
    <value>尚未派息及已派息</value>
  </data>
  <data name="typeMTHINTERWORKLST_Core" xml:space="preserve">
    <value>月息派發管理</value>
  </data>
  <data name="typeROLLINGDAILY_Core" xml:space="preserve">
    <value>轉碼按場日結</value>
  </data>
  <data name="typeCHIPTRAN_I_LST_Core" xml:space="preserve">
    <value>存單管理</value>
  </data>
  <data name="msgErrLoginFailed" xml:space="preserve">
    <value>登入錯誤</value>
  </data>
  <data name="wDomain" xml:space="preserve">
    <value>網域名稱</value>
  </data>
  <data name="wTelbCustomerID" xml:space="preserve">
    <value>電投戶口</value>
  </data>
  <data name="btnPrintRollDtl" xml:space="preserve">
    <value>列印轉碼細數表</value>
  </data>
  <data name="txtCustChipTranTBShift" xml:space="preserve">
    <value>本更電投存卡數</value>
  </data>
  <data name="txtBettingMethod" xml:space="preserve">
    <value>投注方法</value>
  </data>
  <data name="txtNonDoubleIdentity" xml:space="preserve">
    <value>雙重身份</value>
  </data>
  <data name="txtRollChipOpt" xml:space="preserve">
    <value>出碼類</value>
  </data>
  <data name="global_msgConflictAuth" xml:space="preserve">
    <value>授權人與經手人相同。</value>
  </data>
  <data name="btnCancelTelPassword" xml:space="preserve">
    <value>轉用現場認証</value>
  </data>
  <data name="txtInfoIVRAuthByPass" xml:space="preserve">
    <value>已跳過戶口密碼証證</value>
  </data>
  <data name="txtAdjust" xml:space="preserve">
    <value>調整</value>
  </data>
  <data name="global_msgErrBackDayRollingShouldNotBeToday" xml:space="preserve">
    <value>此功能所選之日期，不能大於今天的會計日期</value>
  </data>
  <data name="global_msgInfoAgentNotFound" xml:space="preserve">
    <value>戶口不存在</value>
  </data>
  <data name="global_msgMissingIOURefNo" xml:space="preserve">
    <value>還未選擇借貸單, 繼續嗎 ?</value>
  </data>
  <data name="global_msgTelbPositiveNegativeNotCorrect" xml:space="preserve">
    <value>電投買碼正負值不正確</value>
  </data>
  <data name="txtTelbRecordCannotAddCapital" xml:space="preserve">
    <value>電投紀錄不能加彩</value>
  </data>
  <data name="msgIVRMissingToken" xml:space="preserve">
    <value>內線被佔用,請重新認証</value>
  </data>
  <data name="msgErrIVRAuthFail" xml:space="preserve">
    <value>認証失敗,請重新認証</value>
  </data>
  <data name="msgErrIVRAuthIncorrect" xml:space="preserve">
    <value>未獲得有效認証, 請重新輸入有效的戶口密碼或授權人密碼</value>
  </data>
  <data name="txtIOUDate" xml:space="preserve">
    <value>借貸日期</value>
  </data>
  <data name="txtPenaltyAmtHKD" xml:space="preserve">
    <value>HKD 罰息金額</value>
  </data>
  <data name="txtPenaltyRtnAmount10k_HKD" xml:space="preserve">
    <value>HKD歸還罰息(萬)</value>
  </data>
  <data name="typeSPECIALMARKERLST_F_Core" xml:space="preserve">
    <value>海外貸款管理</value>
  </data>
  <data name="typeSPECIALMARKERLST_Y_Core" xml:space="preserve">
    <value>營運貸款管理</value>
  </data>
  <data name="global_onlyIOUStatusComplete" xml:space="preserve">
    <value>只顯示已清還</value>
  </data>
  <data name="global_onlyIOUStatusOpen" xml:space="preserve">
    <value>只顯示倘有未清還</value>
  </data>
  <data name="txtReturnDateTime" xml:space="preserve">
    <value>還款時間</value>
  </data>
  <data name="txtMarkerAmt" xml:space="preserve">
    <value>貸款額</value>
  </data>
  <data name="txtMarkerRemainAmt" xml:space="preserve">
    <value>貸款餘額</value>
  </data>
  <data name="txtMarkerRtnAmt" xml:space="preserve">
    <value>已還款</value>
  </data>
  <data name="typeMARKERDTL_Core" xml:space="preserve">
    <value>貸款記錄</value>
  </data>
  <data name="typeMARKERLST_Core" xml:space="preserve">
    <value>貸款管理</value>
  </data>
  <data name="global_btnEdt" xml:space="preserve">
    <value>編緝</value>
  </data>
  <data name="txtAllBorrower" xml:space="preserve">
    <value>全部借款人</value>
  </data>
  <data name="txtBadDebt" xml:space="preserve">
    <value>壞賬</value>
  </data>
  <data name="txtContractNo" xml:space="preserve">
    <value>合同編號</value>
  </data>
  <data name="txtIOUMonthlyFreeze" xml:space="preserve">
    <value>月結M凍結</value>
  </data>
  <data name="txtLimit" xml:space="preserve">
    <value>限額</value>
  </data>
  <data name="txtLimitCompany" xml:space="preserve">
    <value>本廳信貸額(萬)</value>
  </data>
  <data name="txtLimitGroup" xml:space="preserve">
    <value>集團信貸額(萬)</value>
  </data>
  <data name="txtLoanCompany" xml:space="preserve">
    <value>本廳已簽額(萬)</value>
  </data>
  <data name="txtLoanGroup" xml:space="preserve">
    <value>集團已簽額(萬)</value>
  </data>
  <data name="txtPhotoExpiry" xml:space="preserve">
    <value>相片已過期</value>
  </data>
  <data name="txtReturnRecords" xml:space="preserve">
    <value>還款記錄</value>
  </data>
  <data name="wAgentStaff" xml:space="preserve">
    <value>伙計</value>
  </data>
  <data name="wConditionType" xml:space="preserve">
    <value>條件類型</value>
  </data>
  <data name="wOutstandingGroup" xml:space="preserve">
    <value>已簽額(萬)</value>
  </data>
  <data name="wPenaltyRate" xml:space="preserve">
    <value>息率(%)</value>
  </data>
  <data name="wReturnType" xml:space="preserve">
    <value>歸還類</value>
  </data>
  <data name="wSettleMan" xml:space="preserve">
    <value>還款人</value>
  </data>
  <data name="wTotalCreditLeftGroup" xml:space="preserve">
    <value>可簽餘額(萬)</value>
  </data>
  <data name="wTotalCredit_10K" xml:space="preserve">
    <value>總信貸額(萬)</value>
  </data>
  <data name="wSalt" xml:space="preserve">
    <value>RollexSamLin</value>
  </data>
  <data name="global_btnSet" xml:space="preserve">
    <value>選擇</value>
  </data>
  <data name="txtChkShowSettled" xml:space="preserve">
    <value>顯示已清還記錄</value>
  </data>
  <data name="txtRelatedIOU" xml:space="preserve">
    <value>相關借貸單</value>
  </data>
  <data name="txtRelatedSIOU" xml:space="preserve">
    <value>相關營運借貸單</value>
  </data>
  <data name="txtCreditTypeMonRate" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="txtPenalty" xml:space="preserve">
    <value>罰息</value>
  </data>
  <data name="wDeduct" xml:space="preserve">
    <value>扣取</value>
  </data>
  <data name="wPayment" xml:space="preserve">
    <value>派發</value>
  </data>
  <data name="wReal" xml:space="preserve">
    <value>實出</value>
  </data>
  <data name="txtIOUHK" xml:space="preserve">
    <value>HKD借款</value>
  </data>
  <data name="txtMarkerCurrency" xml:space="preserve">
    <value>借貸貨幣</value>
  </data>
  <data name="txtMsgInfoMarkerCurrency" xml:space="preserve">
    <value>代理對公司的貨幣</value>
  </data>
  <data name="txtMsgInfoSettleCurrency" xml:space="preserve">
    <value>公司對外地賭場的貨幣</value>
  </data>
  <data name="txtSettleCurrency" xml:space="preserve">
    <value>交易貨幣</value>
  </data>
  <data name="txtShowSettled" xml:space="preserve">
    <value>顯示已清還記錄</value>
  </data>
  <data name="msgErrPWDNotSame" xml:space="preserve">
    <value>確認密碼不相同</value>
  </data>
  <data name="global_txtDataSource" xml:space="preserve">
    <value>數據來源</value>
  </data>
  <data name="global_txtDataSourceName" xml:space="preserve">
    <value>數據名稱</value>
  </data>
  <data name="txtOnlyIOUStatusComplete" xml:space="preserve">
    <value>只顯示已清還</value>
  </data>
  <data name="txtOnlyIOUStatusOpen" xml:space="preserve">
    <value>只顯示倘有未清還</value>
  </data>
  <data name="txtPenaltyRtnAmount_HKD" xml:space="preserve">
    <value>HKD歸還罰息</value>
  </data>
  <data name="txtReturnCurrency" xml:space="preserve">
    <value>還款貨幣</value>
  </data>
  <data name="txtReturnType_CW" xml:space="preserve">
    <value>客人取回</value>
  </data>
  <data name="msgIVRPWDFormat" xml:space="preserve">
    <value>密碼需為全數字及長度為4至6</value>
  </data>
  <data name="global_txt10k" xml:space="preserve">
    <value>萬</value>
  </data>
  <data name="txtCustOnBoard" xml:space="preserve">
    <value>客人正在場面</value>
  </data>
  <data name="txtPenaltyRtnAmount" xml:space="preserve">
    <value>歸還罰息</value>
  </data>
  <data name="txtTotSettleAmount" xml:space="preserve">
    <value>總歸還額</value>
  </data>
  <data name="typeMARKERRETURNDTL_Core" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="wHKAmount" xml:space="preserve">
    <value>HKD總額</value>
  </data>
  <data name="global_msgInfoAgentCreditExists" xml:space="preserve">
    <value>戶口信貸額已存在，請按確定以繼續編輯，按取消重新輸入戶口。</value>
  </data>
  <data name="global_btnSaveAndPrint" xml:space="preserve">
    <value>儲存併列印</value>
  </data>
  <data name="txtIOUReturnHK" xml:space="preserve">
    <value>HKD還款</value>
  </data>
  <data name="txtRelatedMarkerReturn" xml:space="preserve">
    <value>相關還款</value>
  </data>
  <data name="typeMARKERLST_C_Core" xml:space="preserve">
    <value>個人借貸管理</value>
  </data>
  <data name="txtIOUAgent" xml:space="preserve">
    <value>借貸戶口</value>
  </data>
  <data name="typeENQUIRY_Core" xml:space="preserve">
    <value>查詢</value>
  </data>
  <data name="typeTRANLOGENQUIRY_Core" xml:space="preserve">
    <value>資料日誌查詢</value>
  </data>
  <data name="typeMARKERDTL_C_Core" xml:space="preserve">
    <value>個人借貸記錄</value>
  </data>
  <data name="wDataCode" xml:space="preserve">
    <value>檔案類型</value>
  </data>
  <data name="wLogDesc" xml:space="preserve">
    <value>資料</value>
  </data>
  <data name="wOperation" xml:space="preserve">
    <value>行動</value>
  </data>
  <data name="wNewCName" xml:space="preserve">
    <value>新增中文姓名</value>
  </data>
  <data name="wTagetName" xml:space="preserve">
    <value>目標姓名</value>
  </data>
  <data name="global_msgAgentHasTran" xml:space="preserve">
    <value>戶口交易記錄已存在</value>
  </data>
  <data name="global_msgRecordExist" xml:space="preserve">
    <value>記錄已存在</value>
  </data>
  <data name="type_MCR" xml:space="preserve">
    <value>提月息單</value>
  </data>
  <data name="type_MCS" xml:space="preserve">
    <value>存月息單</value>
  </data>
  <data name="type_HCR" xml:space="preserve">
    <value>提凍結單</value>
  </data>
  <data name="type_HCS" xml:space="preserve">
    <value>存凍結單</value>
  </data>
  <data name="global_chkMaster" xml:space="preserve">
    <value>母資料</value>
  </data>
  <data name="global_btnMerger" xml:space="preserve">
    <value>客人合併</value>
  </data>
  <data name="typeCUSTOMERMERGERDTL_Core" xml:space="preserve">
    <value>客人合併</value>
  </data>
  <data name="txtFreezeAmt10K" xml:space="preserve">
    <value>凍結(萬)</value>
  </data>
  <data name="txtMsgInfoRefNoOnlyAlphaNumeric" xml:space="preserve">
    <value>單號只接受英文字母和數目字</value>
  </data>
  <data name="global_msgInfoCannotEditOtherCompanyData" xml:space="preserve">
    <value>不能修改其他場的數據資料，如有需要，請按右下角經授權的場作出修改。</value>
  </data>
  <data name="global_msgDuplicateCustNameC" xml:space="preserve">
    <value>不能輸入重覆中文名</value>
  </data>
  <data name="global_msgDuplicateMaster" xml:space="preserve">
    <value>不能選取多於一個母資料</value>
  </data>
  <data name="global_wMissingTargetName" xml:space="preserve">
    <value>請選擇目標名字</value>
  </data>
  <data name="global_MasterData" xml:space="preserve">
    <value>[母資料]</value>
  </data>
  <data name="global_txtCustomer" xml:space="preserve">
    <value>客人</value>
  </data>
  <data name="global_txtManagement" xml:space="preserve">
    <value>管理層</value>
  </data>
  <data name="global_txtShare" xml:space="preserve">
    <value>股東</value>
  </data>
  <data name="txtIOUReturn" xml:space="preserve">
    <value>贖</value>
  </data>
  <data name="global_msgInfoReturnTypeIsRequired" xml:space="preserve">
    <value>必需選擇歸還類</value>
  </data>
  <data name="typeCashType_CH" xml:space="preserve">
    <value>個人借貸</value>
  </data>
  <data name="typeCashType_IOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="global_MsgAskConfirmDel" xml:space="preserve">
    <value>確定要刪除記錄?</value>
  </data>
  <data name="global_MsgAskConfirmDeleteVoucher" xml:space="preserve">
    <value>確定刪除票據(包括所有明細)？</value>
  </data>
  <data name="global_MsgInfoViodedCannotVoid" xml:space="preserve">
    <value>已刪除的紀錄不能再刪除</value>
  </data>
  <data name="global_msgErrOverSettleAmount" xml:space="preserve">
    <value>還款金額過大</value>
  </data>
  <data name="txtCreditTranURemarkAll" xml:space="preserve">
    <value>停M,公Ｕ</value>
  </data>
  <data name="txtMsgInfoInputMissing" xml:space="preserve">
    <value>仍未輸入所有資料!</value>
  </data>
  <data name="global_msgErrBorrowerRequired" xml:space="preserve">
    <value>必須填上還款人</value>
  </data>
  <data name="txtSettingDesc" xml:space="preserve">
    <value>設定詳述</value>
  </data>
  <data name="txtSettingName" xml:space="preserve">
    <value>設定名稱</value>
  </data>
  <data name="txtSettleItemSetOtherLst" xml:space="preserve">
    <value>月結其他設定記錄</value>
  </data>
  <data name="txtValue" xml:space="preserve">
    <value>數值</value>
  </data>
  <data name="txtDate" xml:space="preserve">
    <value>約見</value>
  </data>
  <data name="txtNoResponse" xml:space="preserve">
    <value>沒有回應</value>
  </data>
  <data name="txtNoSolution" xml:space="preserve">
    <value>沒有方案</value>
  </data>
  <data name="wFailSolution" xml:space="preserve">
    <value>方案不達標</value>
  </data>
  <data name="txtRelateCustomer" xml:space="preserve">
    <value>相關客人</value>
  </data>
  <data name="txtCompAllStatus" xml:space="preserve">
    <value>集團概況</value>
  </data>
  <data name="txtCreditStatus" xml:space="preserve">
    <value>信貸額概況</value>
  </data>
  <data name="txtRemarkContent" xml:space="preserve">
    <value>備注內容</value>
  </data>
  <data name="typeSETTLEITEMLST_Core" xml:space="preserve">
    <value>佣金設定表</value>
  </data>
  <data name="typeSETTLEITEM_Core" xml:space="preserve">
    <value>月結</value>
  </data>
  <data name="txtCommRate" xml:space="preserve">
    <value>佣</value>
  </data>
  <data name="txtDefaulSet" xml:space="preserve">
    <value>預設值</value>
  </data>
  <data name="txtDrinkRate" xml:space="preserve">
    <value>飲</value>
  </data>
  <data name="txtHKD" xml:space="preserve">
    <value>港幣</value>
  </data>
  <data name="txtOtherCodeIn1" xml:space="preserve">
    <value>其他戶口1</value>
  </data>
  <data name="txtSettleCurrCode" xml:space="preserve">
    <value>結算貨幣</value>
  </data>
  <data name="txtSettleRemark" xml:space="preserve">
    <value>佣金備註</value>
  </data>
  <data name="txtUpLvAgent" xml:space="preserve">
    <value>上線代理</value>
  </data>
  <data name="wDrinkToCashRate" xml:space="preserve">
    <value>(股東,代理) 回現金%</value>
  </data>
  <data name="wTopShare" xml:space="preserve">
    <value>大股東</value>
  </data>
  <data name="wTotal" xml:space="preserve">
    <value>合計</value>
  </data>
  <data name="wUpperAgent1" xml:space="preserve">
    <value>上線代理1</value>
  </data>
  <data name="wUpperAgent2" xml:space="preserve">
    <value>上線代理2</value>
  </data>
  <data name="wUpperAgent3" xml:space="preserve">
    <value>上線代理3</value>
  </data>
  <data name="wUpperAgent4" xml:space="preserve">
    <value>上線代理4</value>
  </data>
  <data name="wUpperAgent5" xml:space="preserve">
    <value>上線代理5</value>
  </data>
  <data name="wUpperAgent6" xml:space="preserve">
    <value>上線代理6</value>
  </data>
  <data name="txtHaveRollingOnly" xml:space="preserve">
    <value>本月有轉碼</value>
  </data>
  <data name="txtSettleSetNotConfirm" xml:space="preserve">
    <value>未確認</value>
  </data>
  <data name="wCommRate" xml:space="preserve">
    <value>佣金率</value>
  </data>
  <data name="wComm" xml:space="preserve">
    <value>佣金</value>
  </data>
  <data name="wDrinkRate" xml:space="preserve">
    <value>飲食率</value>
  </data>
  <data name="wDrinkShare" xml:space="preserve">
    <value>共通積分</value>
  </data>
  <data name="wDrinkNonShare" xml:space="preserve">
    <value>永利積分</value>
  </data>
  <data name="wDrinkGrp" xml:space="preserve">
    <value>積分類別</value>
  </data>
  <data name="typeSETTLEITEMSETLST_Core" xml:space="preserve">
    <value>佣金設定表</value>
  </data>
  <data name="global_btnHold" xml:space="preserve">
    <value>待發</value>
  </data>
  <data name="global_btnModify" xml:space="preserve">
    <value>修正</value>
  </data>
  <data name="global_btnResend" xml:space="preserve">
    <value>重發</value>
  </data>
  <data name="global_btnSend" xml:space="preserve">
    <value>發送</value>
  </data>
  <data name="txtExtraNumber" xml:space="preserve">
    <value>短訊號碼</value>
  </data>
  <data name="txtSMSContentUpLv" xml:space="preserve">
    <value>上線內容</value>
  </data>
  <data name="txtSMSRemark" xml:space="preserve">
    <value>訊息備註</value>
  </data>
  <data name="typeSETTLEITEMSETOTHERLST_Core" xml:space="preserve">
    <value>月結其他設定記錄</value>
  </data>
  <data name="txtMsgInfoAgentExisted" xml:space="preserve">
    <value>戶口已存在</value>
  </data>
  <data name="txtMsgInfoCommRateGreatThanDefaultOrNegative" xml:space="preserve">
    <value>''佣金設定'' 大於 ''預設值'' 或 少於零</value>
  </data>
  <data name="txtDisableCurrent" xml:space="preserve">
    <value>本次</value>
  </data>
  <data name="txtDisablePermanent" xml:space="preserve">
    <value>永久</value>
  </data>
  <data name="txtOutstandAmt10K" xml:space="preserve">
    <value>未歸還(萬)</value>
  </data>
  <data name="txtPenaltyAmt" xml:space="preserve">
    <value>罰息金額</value>
  </data>
  <data name="txtPenaltyDate" xml:space="preserve">
    <value>罰息日期</value>
  </data>
  <data name="txtPenaltyInfo" xml:space="preserve">
    <value>罰息資料</value>
  </data>
  <data name="txtPenaltyRtnAmt" xml:space="preserve">
    <value>歸還額</value>
  </data>
  <data name="txtPenaltyRtnInfo" xml:space="preserve">
    <value>罰息歸還</value>
  </data>
  <data name="txtShowRemainPenalty" xml:space="preserve">
    <value>顯示罰息未還</value>
  </data>
  <data name="wDateTime" xml:space="preserve">
    <value>時間</value>
  </data>
  <data name="wPenaltyDay" xml:space="preserve">
    <value>罰息日數</value>
  </data>
  <data name="wRemainPenalty" xml:space="preserve">
    <value>罰息餘額</value>
  </data>
  <data name="wRtnDate" xml:space="preserve">
    <value>歸還日期</value>
  </data>
  <data name="txtCapitalTranFDtl" xml:space="preserve">
    <value>凍結借貸卡管理</value>
  </data>
  <data name="txtCapitalTranFFDtl" xml:space="preserve">
    <value>凍海外借貸卡管理</value>
  </data>
  <data name="txtCapitalTranFYDtl" xml:space="preserve">
    <value>凍營運借貸卡管理</value>
  </data>
  <data name="txtCapitalTranFLst" xml:space="preserve">
    <value>凍結借貸卡管理</value>
  </data>
  <data name="txtCapitalTranFYLst" xml:space="preserve">
    <value>凍營運借貸卡管理</value>
  </data>
  <data name="txtCapitalTranFFLst" xml:space="preserve">
    <value>凍海外借貸卡管理</value>
  </data>
  <data name="txtCreditTypeStopComm" xml:space="preserve">
    <value>停佣</value>
  </data>
  <data name="txtBookMark" xml:space="preserve">
    <value>關注</value>
  </data>
  <data name="txtLatestFiveRecord" xml:space="preserve">
    <value>Latest 5</value>
  </data>
  <data name="txtReturnIOU" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="txtReturnPenalty" xml:space="preserve">
    <value>還息</value>
  </data>
  <data name="txtPaymentProgress" xml:space="preserve">
    <value>還款進度</value>
  </data>
  <data name="wLabel" xml:space="preserve">
    <value>標籤</value>
  </data>
  <data name="txtFreezeAgent" xml:space="preserve">
    <value>凍M戶口</value>
  </data>
  <data name="typeCAPITALTRAN_F_LST_Core" xml:space="preserve">
    <value>凍結借貸卡管理</value>
  </data>
  <data name="wCIOURolling" xml:space="preserve">
    <value>公司U 配置</value>
  </data>
  <data name="wCompleteMonth" xml:space="preserve">
    <value>完成月份</value>
  </data>
  <data name="wCompleteYear" xml:space="preserve">
    <value>完成年份</value>
  </data>
  <data name="wDiffAmt" xml:space="preserve">
    <value>差額</value>
  </data>
  <data name="wIOURolling" xml:space="preserve">
    <value>IOU配置</value>
  </data>
  <data name="wShareRolling" xml:space="preserve">
    <value>股本配置</value>
  </data>
  <data name="txtDrinkPeriod" xml:space="preserve">
    <value>可累積月</value>
  </data>
  <data name="txtDrinkPeriodDef" xml:space="preserve">
    <value>預設可累積月</value>
  </data>
  <data name="txtIndividualSetting" xml:space="preserve">
    <value>個別設定</value>
  </data>
  <data name="typeSETTLEITEMSETDRINKLST_Core" xml:space="preserve">
    <value>積分期限設定表</value>
  </data>
  <data name="global_btnAddNewPenalty" xml:space="preserve">
    <value>新增罰息</value>
  </data>
  <data name="global_btnAddNewPenaltyRtn" xml:space="preserve">
    <value>新增罰息歸還</value>
  </data>
  <data name="PenaltyTypeF" xml:space="preserve">
    <value>海外</value>
  </data>
  <data name="PenaltyTypeIOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="PenaltyTypeY" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="typeCAPITALTRAN_S_LST_Core" xml:space="preserve">
    <value>股本存款管理</value>
  </data>
  <data name="txtCapitalTranSLst" xml:space="preserve">
    <value>股本存款管理</value>
  </data>
  <data name="txtCapitalTranSDtl" xml:space="preserve">
    <value>股本存款管理</value>
  </data>
  <data name="txtCapitalTranCLst" xml:space="preserve">
    <value>海外股本存款管理</value>
  </data>
  <data name="txtCapitalTranCDtl" xml:space="preserve">
    <value>海外股本存款管理</value>
  </data>
  <data name="txtPenaltyOutstanding" xml:space="preserve">
    <value>尚欠罰息</value>
  </data>
  <data name="typeIOUPENALTYADJLST_F_Core" xml:space="preserve">
    <value>罰息調整管理(海外)</value>
  </data>
  <data name="typeIOUPENALTYADJLST_IOU_Core" xml:space="preserve">
    <value>罰息調整管理</value>
  </data>
  <data name="typeIOUPENALTYADJLST_Y_Core" xml:space="preserve">
    <value>罰息調整管理(營運)</value>
  </data>
  <data name="txtCapitalTranYLst" xml:space="preserve">
    <value>食貨存款管理</value>
  </data>
  <data name="txtCapitalTranYDtl" xml:space="preserve">
    <value>食貨存款管理</value>
  </data>
  <data name="txtCapitalTranOLst" xml:space="preserve">
    <value>營運存款管理</value>
  </data>
  <data name="txtCapitalTranODtl" xml:space="preserve">
    <value>營運存款管理</value>
  </data>
  <data name="typeCAPITALTRAN_C_LST_Core" xml:space="preserve">
    <value>海外股本存款管理</value>
  </data>
  <data name="typeCAPITALTRAN_Y_LST_Core" xml:space="preserve">
    <value>食貨存款管理</value>
  </data>
  <data name="typeCAPITALTRAN_O_LST_Core" xml:space="preserve">
    <value>營運存款管理</value>
  </data>
  <data name="IOUBonusStatusA" xml:space="preserve">
    <value>未處理</value>
  </data>
  <data name="IOUBonusStatusC" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="IOUBonusStatusH" xml:space="preserve">
    <value>待付款</value>
  </data>
  <data name="IOUBonusStatusI" xml:space="preserve">
    <value>完成轉C</value>
  </data>
  <data name="IOUBonusStatusP" xml:space="preserve">
    <value>待處理</value>
  </data>
  <data name="typeIOUBONUSLST_Core" xml:space="preserve">
    <value>月結貸款配置管理</value>
  </data>
  <data name="wChipTranICnt" xml:space="preserve">
    <value>存單數目</value>
  </data>
  <data name="wCompleteDatetime" xml:space="preserve">
    <value>完成日期</value>
  </data>
  <data name="wCompleteYearMth" xml:space="preserve">
    <value>完成週期</value>
  </data>
  <data name="wConditionType30Day" xml:space="preserve">
    <value>30天期</value>
  </data>
  <data name="wConditionTypeNormal" xml:space="preserve">
    <value>普通條件</value>
  </data>
  <data name="wHoldAgentCName" xml:space="preserve">
    <value>承擔人名稱</value>
  </data>
  <data name="wHoldAgentCode" xml:space="preserve">
    <value>承擔戶號</value>
  </data>
  <data name="wIOUBonusAmt" xml:space="preserve">
    <value>奬金(萬)</value>
  </data>
  <data name="wIOUBonusAmtImmediate" xml:space="preserve">
    <value>轉Ｃ奬金(萬)</value>
  </data>
  <data name="wIOURefNos" xml:space="preserve">
    <value>相關貸款號碼</value>
  </data>
  <data name="wOutDateTime" xml:space="preserve">
    <value>離場時間</value>
  </data>
  <data name="wRollingWithoutCash" xml:space="preserve">
    <value>非現金轉碼(萬)</value>
  </data>
  <data name="wCashChipTenk" xml:space="preserve">
    <value>現碼（萬）</value>
  </data>
  <data name="wChipTranDtl" xml:space="preserve">
    <value>存單記錄</value>
  </data>
  <data name="wNumNormalMDay" xml:space="preserve">
    <value>顯示天數</value>
  </data>
  <data name="txtCreateDate" xml:space="preserve">
    <value>開單日期</value>
  </data>
  <data name="txtDisableCurrent_L" xml:space="preserve">
    <value>本次不收</value>
  </data>
  <data name="txtDisablePermanent_L" xml:space="preserve">
    <value>永久不收</value>
  </data>
  <data name="txtIOUInfo" xml:space="preserve">
    <value>IOU資料</value>
  </data>
  <data name="txtIOUPenaltyDailyDtl" xml:space="preserve">
    <value>罰息每日明細</value>
  </data>
  <data name="txtOutAmt" xml:space="preserve">
    <value>借款額</value>
  </data>
  <data name="txtOutstandAmt_S" xml:space="preserve">
    <value>未歸還</value>
  </data>
  <data name="txtRtnAmt_S" xml:space="preserve">
    <value>歸還</value>
  </data>
  <data name="txtSettlementDate" xml:space="preserve">
    <value>結算日期</value>
  </data>
  <data name="wRemainIOU" xml:space="preserve">
    <value>IOU餘額</value>
  </data>
  <data name="txtPenaltyRtnAmtHKD" xml:space="preserve">
    <value>HKD 歸還額</value>
  </data>
  <data name="typeRCREDITCONTROL_STATUS_LIST_RPT_Report" xml:space="preserve">
    <value>授信戶口信貸概況報表</value>
  </data>
  <data name="txtDownLineCreditDay" xml:space="preserve">
    <value>下線天數</value>
  </data>
  <data name="txtDownLinePenaltyRate" xml:space="preserve">
    <value>下線息率(分)</value>
  </data>
  <data name="txtDown_Indv_CreditDay" xml:space="preserve">
    <value>下線/個別天數</value>
  </data>
  <data name="txtDown_Indv_PenaltyRate" xml:space="preserve">
    <value>下線/個別息率(分)</value>
  </data>
  <data name="txtIndividualAgent" xml:space="preserve">
    <value>個別戶口</value>
  </data>
  <data name="txtIndividualAgentSetting" xml:space="preserve">
    <value>個別戶口設定</value>
  </data>
  <data name="txtShareCreditDay" xml:space="preserve">
    <value>股東天數</value>
  </data>
  <data name="txtSharePenaltyRate" xml:space="preserve">
    <value>股東息率(分)</value>
  </data>
  <data name="txtUpdIOU_Day_Rate" xml:space="preserve">
    <value>應用借貸天數及息率</value>
  </data>
  <data name="typeIOUPENALTYSETLST_Core" xml:space="preserve">
    <value>罰息設定管理</value>
  </data>
  <data name="txtIndividualCreditDay" xml:space="preserve">
    <value>個別天數</value>
  </data>
  <data name="txtIndividualPenaltyRate" xml:space="preserve">
    <value>個別息率(分)</value>
  </data>
  <data name="txtUpdateInfo" xml:space="preserve">
    <value>更改資料</value>
  </data>
  <data name="txtUpdateScope" xml:space="preserve">
    <value>更改範圍</value>
  </data>
  <data name="global_msgInfoNotFound" xml:space="preserve">
    <value>不存在</value>
  </data>
  <data name="typeCAPITALTRAN_FF_LST_Core" xml:space="preserve">
    <value>凍海外借貸卡管理</value>
  </data>
  <data name="typeCAPITALTRAN_FY_LST_Core" xml:space="preserve">
    <value>凍營運借貸卡管理</value>
  </data>
  <data name="typeCAPITALTRAN_FF_DTL_Core" xml:space="preserve">
    <value>凍海外借貸卡</value>
  </data>
  <data name="typeCAPITALTRAN_FY_DTL_Core" xml:space="preserve">
    <value>凍營運借貸卡</value>
  </data>
  <data name="typeCAPITALTRANWITHDRAW_Core" xml:space="preserve">
    <value>提款</value>
  </data>
  <data name="txtExpCreditAmt" xml:space="preserve">
    <value>消費信用額</value>
  </data>
  <data name="wOverOutstanding_10K" xml:space="preserve">
    <value>剩餘信貸額(萬)</value>
  </data>
  <data name="wExpireOutstanding_10K" xml:space="preserve">
    <value>過期(萬)</value>
  </data>
  <data name="wSettleStatusOutstanding_10K" xml:space="preserve">
    <value>未結算(萬)</value>
  </data>
  <data name="wIOUStore_10K" xml:space="preserve">
    <value>暫存/未取(萬)</value>
  </data>
  <data name="btnCreditUplvOpen" xml:space="preserve">
    <value>開啓上線</value>
  </data>
  <data name="btnCreditUplvClose" xml:space="preserve">
    <value>關閉上線</value>
  </data>
  <data name="txtCreditSummaryDetail" xml:space="preserve">
    <value>詳細信貸額概況</value>
  </data>
  <data name="global_btnAddNewBFDrink" xml:space="preserve">
    <value>新增積分</value>
  </data>
  <data name="global_btnAddNewBFDrinkRtn" xml:space="preserve">
    <value>新增積分扣減</value>
  </data>
  <data name="txtBFDrinkRtnAmt" xml:space="preserve">
    <value>積分使用</value>
  </data>
  <data name="txtDeductInfo" xml:space="preserve">
    <value>扣減資料</value>
  </data>
  <data name="txtIndivdualSettle" xml:space="preserve">
    <value>個別處理</value>
  </data>
  <data name="typeDRINKBFLST_Core" xml:space="preserve">
    <value>積分累數管理</value>
  </data>
  <data name="typeDRINKBFDTL_Core" xml:space="preserve">
    <value>積分累數記錄</value>
  </data>
  <data name="wBFDrinkAmount" xml:space="preserve">
    <value>積分累數</value>
  </data>
  <data name="wBFDrinkRtnAmount" xml:space="preserve">
    <value>積分累數扣減</value>
  </data>
  <data name="global_txtIOU" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="typeCAPITALTRAN_F_DTL_Core" xml:space="preserve">
    <value>凍結借貸卡</value>
  </data>
  <data name="typeCAPITALTRAN_S_DTL_Core" xml:space="preserve">
    <value>股本存款</value>
  </data>
  <data name="typeCAPITALTRAN_C_DTL_Core" xml:space="preserve">
    <value>海外股本存款</value>
  </data>
  <data name="typeCAPITALTRAN_Y_DTL_Core" xml:space="preserve">
    <value>食貨存款</value>
  </data>
  <data name="typeCAPITALTRAN_O_DTL_Core" xml:space="preserve">
    <value>營運存款</value>
  </data>
  <data name="typeCAPITALTRAN_H_DTL_Core" xml:space="preserve">
    <value>凍結存款單</value>
  </data>
  <data name="typeCAPITALTRAN_M_DTL_Core" xml:space="preserve">
    <value>月息單</value>
  </data>
  <data name="txtShowOutstandAmt" xml:space="preserve">
    <value>未使用</value>
  </data>
  <data name="txtShowUsed" xml:space="preserve">
    <value>已使用</value>
  </data>
  <data name="txtSPECIALMARKERLST_FRecord" xml:space="preserve">
    <value>海外貸款記錄</value>
  </data>
  <data name="txtSPECIALMARKERLST_YRecord" xml:space="preserve">
    <value>營運貸款記錄</value>
  </data>
  <data name="global_msgMAmountNotMatchDetail" xml:space="preserve">
    <value>罰息金額與明細不符</value>
  </data>
  <data name="global_msgDelSuccess" xml:space="preserve">
    <value>刪除成功</value>
  </data>
  <data name="global_msgInfoNotAllowToDel" xml:space="preserve">
    <value>不能刪除記錄</value>
  </data>
  <data name="global_msgInfoSettleExisted" xml:space="preserve">
    <value>扣減記錄存在</value>
  </data>
  <data name="btnSearchSMSSeqNo" xml:space="preserve">
    <value>搜尋惟一碼</value>
  </data>
  <data name="txtAccountType" xml:space="preserve">
    <value>戶口級別升降</value>
  </data>
  <data name="txtAgentUpd" xml:space="preserve">
    <value>戶口修改</value>
  </data>
  <data name="txtBecomeHolderSMS" xml:space="preserve">
    <value>成為股東</value>
  </data>
  <data name="txtBfExpTranExpire" xml:space="preserve">
    <value>欠前消費到期</value>
  </data>
  <data name="txtBonusGiftSMS" xml:space="preserve">
    <value>贈送禮物</value>
  </data>
  <data name="txtCapitalTranC" xml:space="preserve">
    <value>海外股本</value>
  </data>
  <data name="txtCapitalTranO" xml:space="preserve">
    <value>營運卡</value>
  </data>
  <data name="txtExpDailyRpt" xml:space="preserve">
    <value>每日集團消費報表</value>
  </data>
  <data name="txtInstantCancelSMS" xml:space="preserve">
    <value>取消即出訊息</value>
  </data>
  <data name="txtInstantSMS" xml:space="preserve">
    <value>即出訊息</value>
  </data>
  <data name="txtIOURtn" xml:space="preserve">
    <value>貸款歸還</value>
  </data>
  <data name="txtLangBig5" xml:space="preserve">
    <value>繁體中文</value>
  </data>
  <data name="txtLangCHN" xml:space="preserve">
    <value>簡體中文</value>
  </data>
  <data name="txtLangEn" xml:space="preserve">
    <value>英文</value>
  </data>
  <data name="txtLangJPN" xml:space="preserve">
    <value>日文</value>
  </data>
  <data name="txtLangKOR" xml:space="preserve">
    <value>韓文</value>
  </data>
  <data name="txtLangTH" xml:space="preserve">
    <value>泰文</value>
  </data>
  <data name="txtMonthEndSettleCanelSMS" xml:space="preserve">
    <value>取消出佣訊息</value>
  </data>
  <data name="txtMonthEndSettleSMS" xml:space="preserve">
    <value>出佣訊息</value>
  </data>
  <data name="txtMonthlyInt" xml:space="preserve">
    <value>回贈</value>
  </data>
  <data name="txtOpenSMS" xml:space="preserve">
    <value>開場訊息</value>
  </data>
  <data name="txtOutSMS" xml:space="preserve">
    <value>離場訊息</value>
  </data>
  <data name="txtRollingDailyRpt" xml:space="preserve">
    <value>每日集團轉碼報表</value>
  </data>
  <data name="txtRollingDailySettle" xml:space="preserve">
    <value>轉碼日結</value>
  </data>
  <data name="txtRollingDailySettleShare" xml:space="preserve">
    <value>轉碼日結(股東組)</value>
  </data>
  <data name="txtRollWinLoss" xml:space="preserve">
    <value>轉碼及上下數</value>
  </data>
  <data name="txtSendFrom" xml:space="preserve">
    <value>發送自</value>
  </data>
  <data name="txtSMSBounsPointsExpire" xml:space="preserve">
    <value>積分到期通知</value>
  </data>
  <data name="txtSMSLang" xml:space="preserve">
    <value>訊息語言</value>
  </data>
  <data name="txtSMSManual" xml:space="preserve">
    <value>手動SMS</value>
  </data>
  <data name="txtSMSStatus_A1" xml:space="preserve">
    <value>已推送</value>
  </data>
  <data name="txtSMSStatus_C1" xml:space="preserve">
    <value>成功</value>
  </data>
  <data name="txtSMSStatus_F" xml:space="preserve">
    <value>失敗</value>
  </data>
  <data name="txtSMSStatus_O" xml:space="preserve">
    <value>排隊發送</value>
  </data>
  <data name="txtSMSStatus_T" xml:space="preserve">
    <value>發送系統故障</value>
  </data>
  <data name="txtStore" xml:space="preserve">
    <value>內部</value>
  </data>
  <data name="txtSubAgentInfo" xml:space="preserve">
    <value>下線資料</value>
  </data>
  <data name="txtUpdMuli" xml:space="preserve">
    <value>批額修改</value>
  </data>
  <data name="typeSMSENQUIRY_Core" xml:space="preserve">
    <value>SMS查詢</value>
  </data>
  <data name="wSMSSeqNo" xml:space="preserve">
    <value>訊息惟一碼</value>
  </data>
  <data name="txtBFDrinkHKDRtnAmt" xml:space="preserve">
    <value>HKD積分使用</value>
  </data>
  <data name="txtClientUpdated" xml:space="preserve">
    <value>有新的版本, 將會更新!</value>
  </data>
  <data name="typeSHIFTAUTHLST_Core" xml:space="preserve">
    <value>授權人管理</value>
  </data>
  <data name="typeSHIFTAUTHDTL_Core" xml:space="preserve">
    <value>授權人記錄</value>
  </data>
  <data name="wDeduct_10K" xml:space="preserve">
    <value>扣取(萬)</value>
  </data>
  <data name="wRealOutStanding_10K" xml:space="preserve">
    <value>扣後尚欠(萬)</value>
  </data>
  <data name="rIOUTranByCageReport" xml:space="preserve">
    <value>貸款報表</value>
  </data>
  <data name="wCashChipHKD" xml:space="preserve">
    <value>HKD現碼</value>
  </data>
  <data name="typeROLLINGMONTHLYADJUSTLST_Core" xml:space="preserve">
    <value>轉碼月轉換</value>
  </data>
  <data name="global_btnUndo" xml:space="preserve">
    <value>還原</value>
  </data>
  <data name="wZCapitalAmt" xml:space="preserve">
    <value>Z卡股本(萬)</value>
  </data>
  <data name="wZCashAmt" xml:space="preserve">
    <value>Z卡現金(萬)</value>
  </data>
  <data name="wZCIOUAmt" xml:space="preserve">
    <value>Z卡公司U(萬)</value>
  </data>
  <data name="wZIOUAmt" xml:space="preserve">
    <value>Z卡IOU(萬)</value>
  </data>
  <data name="txtOneTimeBuyChip" xml:space="preserve">
    <value>一次性買碼</value>
  </data>
  <data name="txtResetPwd" xml:space="preserve">
    <value>重設密碼</value>
  </data>
  <data name="txtResendPwd" xml:space="preserve">
    <value>重發密碼</value>
  </data>
  <data name="txtSMSBpPlayAddCapital" xml:space="preserve">
    <value>B數加彩</value>
  </data>
  <data name="wCapitalAmtHKD" xml:space="preserve">
    <value>股本總值(萬)(港幣)</value>
  </data>
  <data name="wCreditAmtHKD" xml:space="preserve">
    <value>信貸額總值(萬)(港幣)</value>
  </data>
  <data name="txtiouAgentCode" xml:space="preserve">
    <value>IOU戶口</value>
  </data>
  <data name="txtiouAgentName" xml:space="preserve">
    <value>IOU名稱</value>
  </data>
  <data name="wFreezeAmt" xml:space="preserve">
    <value>凍結(萬)</value>
  </data>
  <data name="txtSMSBpPlayClose" xml:space="preserve">
    <value>B數離場</value>
  </data>
  <data name="txtSMSBpPlayCloseCont" xml:space="preserve">
    <value>B數離場(續場)</value>
  </data>
  <data name="txtSMSBpPlayOpen" xml:space="preserve">
    <value>B數開場</value>
  </data>
  <data name="txtSMSBpPlayOpenCont" xml:space="preserve">
    <value>B數開場(續場)</value>
  </data>
  <data name="txtSMSBpPlaySettleCu" xml:space="preserve">
    <value>客人B數結算</value>
  </data>
  <data name="txtSMSFbPlayAddCapital" xml:space="preserve">
    <value>海外佔成加彩</value>
  </data>
  <data name="txtSMSFbPlayClose" xml:space="preserve">
    <value>海外佔成離場</value>
  </data>
  <data name="txtSMSFbPlayCloseCont" xml:space="preserve">
    <value>海外佔成離場(續場)</value>
  </data>
  <data name="txtSMSFbPlayOpen" xml:space="preserve">
    <value>海外佔成開場</value>
  </data>
  <data name="txtSMSFbPlayOpenCont" xml:space="preserve">
    <value>海外佔成開場(續場)</value>
  </data>
  <data name="txtSMSFbPlaySettleCu" xml:space="preserve">
    <value>客人海外佔成結算</value>
  </data>
  <data name="txtSMSForeignAddCapital" xml:space="preserve">
    <value>海外加彩</value>
  </data>
  <data name="txtSMSForeignClose" xml:space="preserve">
    <value>海外離場</value>
  </data>
  <data name="txtSMSForeignCloseCont" xml:space="preserve">
    <value>海外離場(續場)</value>
  </data>
  <data name="txtSMSForeignOpen" xml:space="preserve">
    <value>海外開場</value>
  </data>
  <data name="txtSMSForeignOpenCont" xml:space="preserve">
    <value>海外開場(續場)</value>
  </data>
  <data name="txtSMSForeignSettleCu" xml:space="preserve">
    <value>客人海外結算</value>
  </data>
  <data name="txtSMSOperateAddCapital" xml:space="preserve">
    <value>營運加彩</value>
  </data>
  <data name="txtSMSOperateClose" xml:space="preserve">
    <value>營運離場</value>
  </data>
  <data name="txtSMSOperateCloseCont" xml:space="preserve">
    <value>營運離場(續場)</value>
  </data>
  <data name="txtSMSOperateOpen" xml:space="preserve">
    <value>營運開場</value>
  </data>
  <data name="txtSMSOperateOpenCont" xml:space="preserve">
    <value>營運開場(續場)</value>
  </data>
  <data name="txtSMSOperateSettleCu" xml:space="preserve">
    <value>客人營運結算</value>
  </data>
  <data name="txtSMSTelBAgentLoginPwd" xml:space="preserve">
    <value>代理登入密碼</value>
  </data>
  <data name="typeBPLAYSMSENQUIRY_Core" xml:space="preserve">
    <value>SMS查詢(B數)</value>
  </data>
  <data name="typeTELEBET_ROOT_Core" xml:space="preserve">
    <value>電投</value>
  </data>
  <data name="typeBPLAY_Core" xml:space="preserve">
    <value>B數</value>
  </data>
  <data name="typeFOREIGNSMSENQUIRY_Core" xml:space="preserve">
    <value>SMS查詢(海外)</value>
  </data>
  <data name="typeFOREIGN_Core" xml:space="preserve">
    <value>海外</value>
  </data>
  <data name="typeOPERATESMSENQUIRY_Core" xml:space="preserve">
    <value>SMS查詢(營運)</value>
  </data>
  <data name="typeTELBSMSENQUIRY_Core" xml:space="preserve">
    <value>SMS查詢(電投)</value>
  </data>
  <data name="wMontly" xml:space="preserve">
    <value>月份</value>
  </data>
  <data name="txtOnlyAllowShowBelowLevel2" xml:space="preserve">
    <value>只能顯示第3層或以下</value>
  </data>
  <data name="global_btnNewMthInterest" xml:space="preserve">
    <value>新增月息</value>
  </data>
  <data name="typePLACE_ROOT_Core" xml:space="preserve">
    <value>場面</value>
  </data>
  <data name="whole" xml:space="preserve">
    <value>整</value>
  </data>
  <data name="txtLatestTwoRecord" xml:space="preserve">
    <value>Latest 2</value>
  </data>
  <data name="txtLatestOneRecord" xml:space="preserve">
    <value>Latest 1</value>
  </data>
  <data name="wCashChip_ToNew" xml:space="preserve">
    <value>結存</value>
  </data>
  <data name="global_txtAlready" xml:space="preserve">
    <value>已</value>
  </data>
  <data name="global_txtInvalid" xml:space="preserve">
    <value>不正確</value>
  </data>
  <data name="global_txtSend" xml:space="preserve">
    <value>發出</value>
  </data>
  <data name="global_txtSMS" xml:space="preserve">
    <value>手機短訊</value>
  </data>
  <data name="global_MsgErrAmountDifferent" xml:space="preserve">
    <value>金額不同</value>
  </data>
  <data name="global_MsgNotAllowToUseThisFunction" xml:space="preserve">
    <value>此場不能用有關功能</value>
  </data>
  <data name="global_msgInfoPlsEdit" xml:space="preserve">
    <value>請先編輯要刪除的項</value>
  </data>
  <data name="global_msgErrAgentCodeExists" xml:space="preserve">
    <value>戶口編號已存在</value>
  </data>
  <data name="txtTotalRolling10K" xml:space="preserve">
    <value>總轉碼(萬)</value>
  </data>
  <data name="typeROLLINGENQUIRY_Core" xml:space="preserve">
    <value>轉碼查詢</value>
  </data>
  <data name="txtAgentLevel" xml:space="preserve">
    <value>等級</value>
  </data>
  <data name="txtCreditAmt" xml:space="preserve">
    <value>信用額</value>
  </data>
  <data name="txtLastMonthRolling" xml:space="preserve">
    <value>上月轉碼(萬)(連下線)</value>
  </data>
  <data name="txtthisMonthRolling" xml:space="preserve">
    <value>本月轉碼(萬)(連下線)</value>
  </data>
  <data name="txtthisMonthTotalRollingAmt" xml:space="preserve">
    <value>當月累計轉碼(萬)(連下線)</value>
  </data>
  <data name="txtWk" xml:space="preserve">
    <value>本週(萬)(連下線)</value>
  </data>
  <data name="txtWk1" xml:space="preserve">
    <value>本週-1(萬)(連下線)</value>
  </data>
  <data name="txtWk2" xml:space="preserve">
    <value>本週-2(萬)(連下線)</value>
  </data>
  <data name="txtWk3" xml:space="preserve">
    <value>本週-3(萬)(連下線)</value>
  </data>
  <data name="typePOTEROLLINGAGENENQUIRY_Core" xml:space="preserve">
    <value>潛質會員查詢</value>
  </data>
  <data name="wAgentName" xml:space="preserve">
    <value>戶口姓名</value>
  </data>
  <data name="txtCreditOver1MRollingUnder10MLst" xml:space="preserve">
    <value>批額超過1千萬轉碼不過億名單</value>
  </data>
  <data name="txtNoCreditThisMonthRollingOver10MLst" xml:space="preserve">
    <value>無批額本月轉碼過億名單</value>
  </data>
  <data name="txtNoCreditThisWeekRollingOver10MLst" xml:space="preserve">
    <value>無批額本週轉碼過億名單</value>
  </data>
  <data name="txtRollingUnder10MLst" xml:space="preserve">
    <value>上月轉碼過億今月不過名單</value>
  </data>
  <data name="global_MsgInfoDateMissing" xml:space="preserve">
    <value>請輸入日期</value>
  </data>
  <data name="txtInvalidYearMth" xml:space="preserve">
    <value>不是有效週期</value>
  </data>
  <data name="global_btnSavePos" xml:space="preserve">
    <value>保存坐標</value>
  </data>
  <data name="glabal_msgInvalidTourNoOrCustomerInfo" xml:space="preserve">
    <value>Invalid Tour No or Customer Info</value>
  </data>
  <data name="txtMaxLevelHit" xml:space="preserve">
    <value>已到最大的層數, 不能新增</value>
  </data>
  <data name="txtMsgInfoNoCombineMessage" xml:space="preserve">
    <value>不能發送，缺少贖回Marker的部份訊息。</value>
  </data>
  <data name="txtSendSMSFail" xml:space="preserve">
    <value>發送失敗</value>
  </data>
  <data name="txtSendSMSSuccess" xml:space="preserve">
    <value>發送成功</value>
  </data>
  <data name="txtSMSPressReply" xml:space="preserve">
    <value>如有任何查詢，請致電聯絡我們。</value>
  </data>
  <data name="txtSMSPressReplyHotline" xml:space="preserve">
    <value>如有任何查詢，請致電&lt;wTel&gt;聯絡我們。</value>
  </data>
  <data name="global_txtCompanySet" xml:space="preserve">
    <value>公司預設</value>
  </data>
  <data name="global_txtIndividualAgentSet" xml:space="preserve">
    <value>個別戶口線設定(月結即出)</value>
  </data>
  <data name="global_txtIndividualCageSet" xml:space="preserve">
    <value>個別廳設定</value>
  </data>
  <data name="typeSETTLEINSTANTSETLST_Core" xml:space="preserve">
    <value>即出佣金設定</value>
  </data>
  <data name="global_btnReprint" xml:space="preserve">
    <value>重印</value>
  </data>
  <data name="global_PopUpSettleLocationPeriod" xml:space="preserve">
    <value>出糧批核週期</value>
  </data>
  <data name="global_txtAllCommission" xml:space="preserve">
    <value>佣金總額(萬)</value>
  </data>
  <data name="global_txtIsIncludeFoodDrinkBF" xml:space="preserve">
    <value>積分表</value>
  </data>
  <data name="global_txtIsIncludeMthEndExpense" xml:space="preserve">
    <value>月結消費單</value>
  </data>
  <data name="global_txtIsIncludeSummaryDownDtl" xml:space="preserve">
    <value>下線佣金收益表</value>
  </data>
  <data name="global_txtMonthEndRptUseOldFormat" xml:space="preserve">
    <value>月結單使用舊格式</value>
  </data>
  <data name="global_txtOutstandingCommission" xml:space="preserve">
    <value>未出佣金(萬)</value>
  </data>
  <data name="global_txtPaidByLocal" xml:space="preserve">
    <value>[本地出]</value>
  </data>
  <data name="global_txtPaidByMacau" xml:space="preserve">
    <value>[澳門出]</value>
  </data>
  <data name="global_txtSalarySummaryInclude" xml:space="preserve">
    <value>糧單包括</value>
  </data>
  <data name="global_txtSettledCommission" xml:space="preserve">
    <value>已出佣金(萬)</value>
  </data>
  <data name="typeSETTLETRANLST_Core" xml:space="preserve">
    <value>出糧管理</value>
  </data>
  <data name="global_btnCentralAuth" xml:space="preserve">
    <value>中央信貸部</value>
  </data>
  <data name="wCommissionCutoff10k" xml:space="preserve">
    <value>實出佣(萬)</value>
  </data>
  <data name="wCommissionCutoffHKD10k" xml:space="preserve">
    <value>實出佣HKD(萬)</value>
  </data>
  <data name="txtShowBFExp" xml:space="preserve">
    <value>欠费</value>
  </data>
  <data name="txtShowHaveComm" xml:space="preserve">
    <value>有佣金</value>
  </data>
  <data name="txtShowZeroComm" xml:space="preserve">
    <value>零佣金</value>
  </data>
  <data name="wCentralUpdByCName" xml:space="preserve">
    <value>中央信貸部經手人</value>
  </data>
  <data name="wExpOutstandingHKD" xml:space="preserve">
    <value>尚欠費用HKD</value>
  </data>
  <data name="wIOUOutstandingHKD" xml:space="preserve">
    <value>倘欠貸款HKD(萬)</value>
  </data>
  <data name="wIVRAuthByCName" xml:space="preserve">
    <value>IVR授權人</value>
  </data>
  <data name="wIVRAuthDt" xml:space="preserve">
    <value>IVR授權時間</value>
  </data>
  <data name="wPaidByCName" xml:space="preserve">
    <value>出糧經手人</value>
  </data>
  <data name="wPaidCompCName" xml:space="preserve">
    <value>出糧地點</value>
  </data>
  <data name="wPaidDt" xml:space="preserve">
    <value>出糧時間</value>
  </data>
  <data name="btnLeaveRemarkDeposit" xml:space="preserve">
    <value>存</value>
  </data>
  <data name="btnLeaveRemarkReturn" xml:space="preserve">
    <value>贖</value>
  </data>
  <data name="btnLeaveRemarkTake" xml:space="preserve">
    <value>袋</value>
  </data>
  <data name="global_txtOrder" xml:space="preserve">
    <value>排序</value>
  </data>
  <data name="txtCapitalRemark" xml:space="preserve">
    <value>本金備註</value>
  </data>
  <data name="txtCapitalRemarkType_Work" xml:space="preserve">
    <value>工作碼</value>
  </data>
  <data name="txtCapitalRemarkType_WorkCash" xml:space="preserve">
    <value>工作碼(卡C)</value>
  </data>
  <data name="txtCapitalRemarkType_WorkM" xml:space="preserve">
    <value>工作碼(M)</value>
  </data>
  <data name="txtCapitalRemark_CardC" xml:space="preserve">
    <value>卡C</value>
  </data>
  <data name="txtCapitalRemark_Cash" xml:space="preserve">
    <value>現</value>
  </data>
  <data name="txtCapitalRemark_Chip" xml:space="preserve">
    <value>泥</value>
  </data>
  <data name="txtCapitalRemark_CMM" xml:space="preserve">
    <value>公司MM</value>
  </data>
  <data name="txtCapitalRemark_CreditCard" xml:space="preserve">
    <value>碌卡</value>
  </data>
  <data name="txtCapitalRemark_StoreM" xml:space="preserve">
    <value>存M</value>
  </data>
  <data name="txtCapitalType" xml:space="preserve">
    <value>本金種類</value>
  </data>
  <data name="txtLeaveAction" xml:space="preserve">
    <value>離場動作</value>
  </data>
  <data name="txtLeaveRemarkAction_K" xml:space="preserve">
    <value>取現</value>
  </data>
  <data name="txtLeaveRemarkType_Tip" xml:space="preserve">
    <value>小費</value>
  </data>
  <data name="txtLeaveRemarkType_W" xml:space="preserve">
    <value>舊M</value>
  </data>
  <data name="txtLeaveType" xml:space="preserve">
    <value>離場類型</value>
  </data>
  <data name="txtPlaceShiftDate" xml:space="preserve">
    <value>截更日期</value>
  </data>
  <data name="txtRollingAmtByAgent" xml:space="preserve">
    <value>轉碼概況</value>
  </data>
  <data name="txtRollingTotalByCurrency" xml:space="preserve">
    <value>轉碼總值(萬)</value>
  </data>
  <data name="txtRollingTotal_HKD" xml:space="preserve">
    <value>轉碼總值(萬)(港幣)</value>
  </data>
  <data name="typeIOU_IOENQUIRY_Core" xml:space="preserve">
    <value>借貸出入數查詢</value>
  </data>
  <data name="txtInAmt" xml:space="preserve">
    <value>還款額</value>
  </data>
  <data name="wRtnRefNo" xml:space="preserve">
    <value>歸還(單號)</value>
  </data>
  <data name="txtPopupSMSPreview" xml:space="preserve">
    <value>發送短訊預覽</value>
  </data>
  <data name="txtIndividualAgentSet" xml:space="preserve">
    <value>個別戶口線設定</value>
  </data>
  <data name="typeMonthEndAdjust_Core" xml:space="preserve">
    <value>月結前調整</value>
  </data>
  <data name="wCommissionDisplayType" xml:space="preserve">
    <value>碼類,貨幣,投注類</value>
  </data>
  <data name="global_msgInfoNoChange" xml:space="preserve">
    <value>資料沒有更改</value>
  </data>
  <data name="global_txtData" xml:space="preserve">
    <value>資料</value>
  </data>
  <data name="global_MsgInfoTelbProcessing" xml:space="preserve">
    <value>準備中</value>
  </data>
  <data name="txtCheckIn" xml:space="preserve">
    <value>入場</value>
  </data>
  <data name="txtCustChipTranTypeTB" xml:space="preserve">
    <value>電投客人存卡</value>
  </data>
  <data name="typeCUSTOMERTELBLST_Core" xml:space="preserve">
    <value>電投客人管理</value>
  </data>
  <data name="wTelbCreditType" xml:space="preserve">
    <value>批額類型</value>
  </data>
  <data name="wTelbLoginID" xml:space="preserve">
    <value>電投登入戶口</value>
  </data>
  <data name="wTelbSMS" xml:space="preserve">
    <value>訊息號碼</value>
  </data>
  <data name="wTelebetPhoneNumber" xml:space="preserve">
    <value>電投號碼</value>
  </data>
  <data name="wTelebetDateTime" xml:space="preserve">
    <value>電投時間</value>
  </data>
  <data name="wTelbCreditAvaliable" xml:space="preserve">
    <value>餘額(萬)</value>
  </data>
  <data name="wTelbExpirDate" xml:space="preserve">
    <value>到期日期</value>
  </data>
  <data name="btnReadCardActCode" xml:space="preserve">
    <value>讀取卡行動碼</value>
  </data>
  <data name="wSaltStaffCard" xml:space="preserve">
    <value>RollexCardCode</value>
  </data>
  <data name="typeBPLAY_ROOT_Core" xml:space="preserve">
    <value>B數</value>
  </data>
  <data name="typeBPLAY_LST_Core" xml:space="preserve">
    <value>B數管理</value>
  </data>
  <data name="global_BPLAY_DTL" xml:space="preserve">
    <value>B數記錄</value>
  </data>
  <data name="global_msgInfoYearMthOrAgentRequired" xml:space="preserve">
    <value>必須填上週期或者用戶其中一欄</value>
  </data>
  <data name="global_msgInfoYearMthWrong" xml:space="preserve">
    <value>月份輸入不正確, 請輸入如: 201301, 201302</value>
  </data>
  <data name="global_msgInfoCommissionCardNotExists" xml:space="preserve">
    <value>本月佣金卡不存在, 如2013年1月份佣金卡號碼該為 "13-01"</value>
  </data>
  <data name="typeBPLAY_SETTING_Core" xml:space="preserve">
    <value>B數佣金設定</value>
  </data>
  <data name="txtBPLAYSET_Remark" xml:space="preserve">
    <value>**佣金率 : 代理最後收取 | 海外佣金率 : 海外廳於佣金率當中所佔部份，結算時用作扣除</value>
  </data>
  <data name="txtPointsRate" xml:space="preserve">
    <value>積分率</value>
  </data>
  <data name="txtForeignCommRate" xml:space="preserve">
    <value>海外佣金率</value>
  </data>
  <data name="msgCardDateInvalid" xml:space="preserve">
    <value>資料不正確</value>
  </data>
  <data name="txtCage" xml:space="preserve">
    <value>貴賓廳</value>
  </data>
  <data name="btnReject" xml:space="preserve">
    <value>不批準</value>
  </data>
  <data name="btnCancelAppointment" xml:space="preserve">
    <value>取消預約</value>
  </data>
  <data name="txtCancel" xml:space="preserve">
    <value>取消</value>
  </data>
  <data name="txtFriday" xml:space="preserve">
    <value>週五</value>
  </data>
  <data name="txtMonday" xml:space="preserve">
    <value>週一</value>
  </data>
  <data name="txtSaturday" xml:space="preserve">
    <value>週六</value>
  </data>
  <data name="txtSunday" xml:space="preserve">
    <value>週日</value>
  </data>
  <data name="txtThursday" xml:space="preserve">
    <value>週四</value>
  </data>
  <data name="txtTuesday" xml:space="preserve">
    <value>週二</value>
  </data>
  <data name="txtWednesday" xml:space="preserve">
    <value>週三</value>
  </data>
  <data name="global_msgCannotSeacrhLastMonthlyInterest" xml:space="preserve">
    <value>只可以選擇 201502 後月份 </value>
  </data>
  <data name="global_msgErrDayIssueAfterMth" xml:space="preserve">
    <value>不可選取大於未過月份</value>
  </data>
  <data name="global_msgErrDayIssueMissing" xml:space="preserve">
    <value>請選擇月息日</value>
  </data>
  <data name="txtStatusOperateOpen" xml:space="preserve">
    <value>已開場</value>
  </data>
  <data name="wStatusOperateCancel" xml:space="preserve">
    <value>已取消</value>
  </data>
  <data name="wStatusOperateExit" xml:space="preserve">
    <value>已離場</value>
  </data>
  <data name="wStatusOperateSettle" xml:space="preserve">
    <value>已結算</value>
  </data>
  <data name="wMSummaryTitle" xml:space="preserve">
    <value>總派息資料</value>
  </data>
  <data name="global_MsgErrForWriteUserEnquiryLog" xml:space="preserve">
    <value>保存用戶查詢日誌失敗</value>
  </data>
  <data name="txtButton" xml:space="preserve">
    <value>按鍵</value>
  </data>
  <data name="txtOption" xml:space="preserve">
    <value>選項</value>
  </data>
  <data name="typeSALARYSETTLEMENTLST_Core" xml:space="preserve">
    <value>月結出糧總表</value>
  </data>
  <data name="txtConfirmSettleTran" xml:space="preserve">
    <value>確認此月份碼糧</value>
  </data>
  <data name="txtConfirmSettleTranTryRun" xml:space="preserve">
    <value>確認此月份的預視碼糧</value>
  </data>
  <data name="txtMthEndProcess" xml:space="preserve">
    <value>執行月結</value>
  </data>
  <data name="txtPrintSalaryDtlSummary" xml:space="preserve">
    <value>列印出糧下線細數表</value>
  </data>
  <data name="txtPrintSalarySummary" xml:space="preserve">
    <value>列印出糧總報表</value>
  </data>
  <data name="txtPrintSalarySummaryDetailTryRun" xml:space="preserve">
    <value>列印預視出糧下線細數表</value>
  </data>
  <data name="txtPrintSalarySummaryTryRun" xml:space="preserve">
    <value>列印預視出糧總報表</value>
  </data>
  <data name="wConfirmMthEndUpdBy" xml:space="preserve">
    <value>確認月結經手人</value>
  </data>
  <data name="wConfirmPreviewUpdBy" xml:space="preserve">
    <value>確認預視經手人</value>
  </data>
  <data name="wEndDateTime" xml:space="preserve">
    <value>完成時間</value>
  </data>
  <data name="global_YearMthLengthOnlySix" xml:space="preserve">
    <value>週期只能為6位數</value>
  </data>
  <data name="txtRemoteRolling" xml:space="preserve">
    <value>遙距轉碼</value>
  </data>
  <data name="typeBPlayMethod_Tel" xml:space="preserve">
    <value>電話</value>
  </data>
  <data name="typeBPlayMethod_Live" xml:space="preserve">
    <value>現場</value>
  </data>
  <data name="typeBPlayCapital_CASH" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="typeBPlayCapital_MCASH" xml:space="preserve">
    <value>M現金</value>
  </data>
  <data name="typeBPlayCapital_IOU" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="txtBComp" xml:space="preserve">
    <value>B數公司</value>
  </data>
  <data name="global_msgNoChange" xml:space="preserve">
    <value>記錄沒有修改</value>
  </data>
  <data name="txtRefreshMthEndStatus" xml:space="preserve">
    <value>更新月結狀態</value>
  </data>
  <data name="wCurrRateDivideDaily" xml:space="preserve">
    <value>當日兌換率(除)</value>
  </data>
  <data name="wCurrRateProductDaily" xml:space="preserve">
    <value>當日兌換率(乘)</value>
  </data>
  <data name="global_msgInfoSettleItemSetFxRate" xml:space="preserve">
    <value>匯率的乘及除只可以一個是1或設定匯率為0</value>
  </data>
  <data name="global_msgInfoSettleItemSetNotFinish" xml:space="preserve">
    <value>佣金設定尚未完成</value>
  </data>
  <data name="txtError" xml:space="preserve">
    <value>錯誤</value>
  </data>
  <data name="txtInProgress" xml:space="preserve">
    <value>進行中...</value>
  </data>
  <data name="global_msgInfoCustomerUsed" xml:space="preserve">
    <value>該客人名稱已使用,不能更改</value>
  </data>
  <data name="global_msgInfoPlsInputCustomerName" xml:space="preserve">
    <value>請輸入客人名稱</value>
  </data>
  <data name="global_msgInfoPlsInputCustomerTel" xml:space="preserve">
    <value>請輸入客人電話</value>
  </data>
  <data name="global_msgInfoTranUsed" xml:space="preserve">
    <value>客人已有相關交易,不能更改或刪除</value>
  </data>
  <data name="global_msgErrTelSMSFormatInvalid" xml:space="preserve">
    <value>短訊號碼格式不正確</value>
  </data>
  <data name="typeSETTLETRANINSTANTLST_Core" xml:space="preserve">
    <value>即出佣金紀錄</value>
  </data>
  <data name="wRecByCName" xml:space="preserve">
    <value>出佣人</value>
  </data>
  <data name="txtBPlayStatus" xml:space="preserve">
    <value>B數狀態</value>
  </data>
  <data name="txtBPlayExchangeStatus" xml:space="preserve">
    <value>交易狀態</value>
  </data>
  <data name="txtSMSStatus" xml:space="preserve">
    <value>短訊狀態</value>
  </data>
  <data name="typeStatusBPlay_Setting" xml:space="preserve">
    <value>設定中</value>
  </data>
  <data name="typeStatusBPlay_RequestOpenGame" xml:space="preserve">
    <value>要求開場</value>
  </data>
  <data name="typeStatusBPlay_ReqEdit" xml:space="preserve">
    <value>要求修改</value>
  </data>
  <data name="typeStatusBPlay_ReqCancel" xml:space="preserve">
    <value>要求取消</value>
  </data>
  <data name="typeStatusBPlay_ReqAddCapital" xml:space="preserve">
    <value>要求加彩</value>
  </data>
  <data name="typeStatusBPlay_RequestExit" xml:space="preserve">
    <value>要求離場</value>
  </data>
  <data name="typeStatusBPlay_Cancel" xml:space="preserve">
    <value>已取消</value>
  </data>
  <data name="typeStatusBPlay_Exit" xml:space="preserve">
    <value>已離場</value>
  </data>
  <data name="typeStatusBPlay_Settle" xml:space="preserve">
    <value>已結算</value>
  </data>
  <data name="txtBPlayExchangeStatusNone" xml:space="preserve">
    <value>未交易</value>
  </data>
  <data name="txtBPlayExchangeStatusSuccess" xml:space="preserve">
    <value>交易成功</value>
  </data>
  <data name="txtStatusSMSOpt0" xml:space="preserve">
    <value>全部未發</value>
  </data>
  <data name="txtStatusSMSOpt1" xml:space="preserve">
    <value>已發開場</value>
  </data>
  <data name="txtStatusSMSOpt2" xml:space="preserve">
    <value>已發離場</value>
  </data>
  <data name="txtStatusSMSOpt3" xml:space="preserve">
    <value>已發結算</value>
  </data>
  <data name="wBPlayRatio" xml:space="preserve">
    <value>佔成(%)</value>
  </data>
  <data name="wBPlayShareRatio" xml:space="preserve">
    <value>免佣佔成(%)</value>
  </data>
  <data name="txtTtlGame" xml:space="preserve">
    <value>本場總局數</value>
  </data>
  <data name="txtTtlCapital" xml:space="preserve">
    <value>本場總本金</value>
  </data>
  <data name="txtAgentCommRate" xml:space="preserve">
    <value>代理佣金率</value>
  </data>
  <data name="txtCustCurrCode" xml:space="preserve">
    <value>客人貨幣</value>
  </data>
  <data name="txtCustFxRate" xml:space="preserve">
    <value>客人匯率</value>
  </data>
  <data name="txtCapitalCurrCode" xml:space="preserve">
    <value>本金貨幣</value>
  </data>
  <data name="txtCapitalFxRate" xml:space="preserve">
    <value>本金匯率</value>
  </data>
  <data name="global_txtCompanySetCar" xml:space="preserve">
    <value>公司預設（會員卡）</value>
  </data>
  <data name="global_txtCompanySetManila" xml:space="preserve">
    <value>公司預設(馬尼拉)</value>
  </data>
  <data name="global_txtCompanySetOut" xml:space="preserve">
    <value>公司預設(月結即出)</value>
  </data>
  <data name="global_txtIndividualAgentSetManila" xml:space="preserve">
    <value>個別戶口線設定(馬尼拉)</value>
  </data>
  <data name="global_txtIndividualCageSetCar" xml:space="preserve">
    <value>個別廳設定(會員卡)</value>
  </data>
  <data name="global_txtIndividualCageSetOut" xml:space="preserve">
    <value>個別廳設定(月結即出)</value>
  </data>
  <data name="global_msgInfoPreviewPeriodOnly" xml:space="preserve">
    <value>預視模式可選擇的週期為{0}或以後</value>
  </data>
  <data name="global_eSettleTranStatusOpt_C" xml:space="preserve">
    <value>已出</value>
  </data>
  <data name="global_eSettleTranStatusOpt_O" xml:space="preserve">
    <value>未出</value>
  </data>
  <data name="global_msgPlsEditInfo" xml:space="preserve">
    <value>請先編輯</value>
  </data>
  <data name="wGunterID" xml:space="preserve">
    <value>槍手編號</value>
  </data>
  <data name="wExternalAgentCodeName" xml:space="preserve">
    <value>外線戶口</value>
  </data>
  <data name="wMaxIOUHoldAmt" xml:space="preserve">
    <value>凍結柴金額</value>
  </data>
  <data name="wCapLimitAmt" xml:space="preserve">
    <value>封頂數</value>
  </data>
  <data name="wIsMaxIOU" xml:space="preserve">
    <value>柴</value>
  </data>
  <data name="txtOnTableCapitalAmt" xml:space="preserve">
    <value>出碼本金(萬)</value>
  </data>
  <data name="txtOpenBalanceRemark" xml:space="preserve">
    <value>開場金額備註</value>
  </data>
  <data name="txtIsForeignComm" xml:space="preserve">
    <value>海外廳佣金</value>
  </data>
  <data name="wIsSecretPlay" xml:space="preserve">
    <value>偷食</value>
  </data>
  <data name="txtTtlRolling" xml:space="preserve">
    <value>本場總轉碼</value>
  </data>
  <data name="txtTtlWinLoss" xml:space="preserve">
    <value>本場總輸贏</value>
  </data>
  <data name="txtMarkerAmount10K" xml:space="preserve">
    <value>借貸額(萬)</value>
  </data>
  <data name="btnShowCapitalFxRate" xml:space="preserve">
    <value>如需要輸入第二種貨幣，請按這裡。</value>
  </data>
  <data name="wLocalFxRate" xml:space="preserve">
    <value>自訂匯率</value>
  </data>
  <data name="wFollowStaff" xml:space="preserve">
    <value>跟單員工</value>
  </data>
  <data name="wStartUsr" xml:space="preserve">
    <value>開場員工</value>
  </data>
  <data name="wEndUsr" xml:space="preserve">
    <value>離場員工</value>
  </data>
  <data name="wTableCheckOutAmt" xml:space="preserve">
    <value>離枱數(萬)</value>
  </data>
  <data name="btnImportRolling" xml:space="preserve">
    <value>匯入轉碼</value>
  </data>
  <data name="wIsStoreLocal" xml:space="preserve">
    <value>存本地</value>
  </data>
  <data name="wStoreLocalAmt10K" xml:space="preserve">
    <value>存回金額(萬)</value>
  </data>
  <data name="txtBPlayRatio" xml:space="preserve">
    <value>佔成</value>
  </data>
  <data name="txtBPlayShareRatio" xml:space="preserve">
    <value>免佣佔成</value>
  </data>
  <data name="txtBPlayCashOutLstTitle" xml:space="preserve">
    <value>B數水錢支出列表</value>
  </data>
  <data name="wCustFxRate" xml:space="preserve">
    <value>公對客Ex(乘)</value>
  </data>
  <data name="wCustFxRateDiv" xml:space="preserve">
    <value>公對客Ex(除)</value>
  </data>
  <data name="wCustToForeignSiteFxRate" xml:space="preserve">
    <value>當日Ex(乘)</value>
  </data>
  <data name="wCustToForeignSiteFxRateDiv" xml:space="preserve">
    <value>當日Ex(除)</value>
  </data>
  <data name="txtTableCheckOut" xml:space="preserve">
    <value>離枱數</value>
  </data>
  <data name="txtCommExpense_10k" xml:space="preserve">
    <value>佣金支出(萬)</value>
  </data>
  <data name="txtCommIncome_10k" xml:space="preserve">
    <value>佣金收入(萬)</value>
  </data>
  <data name="wNetAmt_10K" xml:space="preserve">
    <value>實出金額(萬)</value>
  </data>
  <data name="wPoints_10K" xml:space="preserve">
    <value>積分(萬)</value>
  </data>
  <data name="txtTtlCapital10K" xml:space="preserve">
    <value>本場總本金(萬)</value>
  </data>
  <data name="txtTtlRolling10K" xml:space="preserve">
    <value>本場總轉碼(萬)</value>
  </data>
  <data name="txtTtlWinLoss10K" xml:space="preserve">
    <value>本場總輸贏(萬)</value>
  </data>
  <data name="txtSettle" xml:space="preserve">
    <value>結算</value>
  </data>
  <data name="wAgentComm" xml:space="preserve">
    <value>代理佣金</value>
  </data>
  <data name="wAgentSalary" xml:space="preserve">
    <value>代理實出</value>
  </data>
  <data name="wTIPS" xml:space="preserve">
    <value>水錢</value>
  </data>
  <data name="txtPaidByMacau" xml:space="preserve">
    <value>[澳門出]</value>
  </data>
  <data name="global_msgInfoInvalidPeriod" xml:space="preserve">
    <value>月結不存在</value>
  </data>
  <data name="global_optCashType_F" xml:space="preserve">
    <value>海外借貸</value>
  </data>
  <data name="global_optCashType_O" xml:space="preserve">
    <value>營運借貸</value>
  </data>
  <data name="global_msgDoCentralAuthorizeFirst" xml:space="preserve">
    <value>請先由中央信貸部授權才可進行出糧動作</value>
  </data>
  <data name="global_btnConfirmCancelPayoff" xml:space="preserve">
    <value>取消此次出佣</value>
  </data>
  <data name="global_msgErrorAuthFailed" xml:space="preserve">
    <value>{0}授權失敗</value>
  </data>
  <data name="typeCUSTOMERTELBDTL_Core" xml:space="preserve">
    <value>客人記錄</value>
  </data>
  <data name="global_msgMissingFxRate" xml:space="preserve">
    <value>找不到此貨幣兌換港元的匯率</value>
  </data>
  <data name="global_msgMthEndPrepare" xml:space="preserve">
    <value>月結 仍在準備中</value>
  </data>
  <data name="global_PopUpSettleRemark" xml:space="preserve">
    <value>出糧備註</value>
  </data>
  <data name="global_PopUpSettleTranInstantRemark" xml:space="preserve">
    <value>即出備註</value>
  </data>
  <data name="global_msgIVRAuthSuccess" xml:space="preserve">
    <value>IVR授權成功; 請於30分鐘內出糧</value>
  </data>
  <data name="global_msgErrIVRAuthExpired" xml:space="preserve">
    <value>IVR操作逾時; 請重新授權</value>
  </data>
  <data name="global_msgWarnHasOverdueAmt" xml:space="preserve">
    <value>此戶口過期M {0} 萬</value>
  </data>
  <data name="wSaltAgentWebPassword" xml:space="preserve">
    <value>RollexWebPassword</value>
  </data>
  <data name="global_txtCustomerAcc" xml:space="preserve">
    <value>客人戶口</value>
  </data>
  <data name="btnSettleTranInstant" xml:space="preserve">
    <value>即出佣金</value>
  </data>
  <data name="txtLocalTable" xml:space="preserve">
    <value>本地枱</value>
  </data>
  <data name="msgEliteMemberCalcDrinkRate" xml:space="preserve">
    <value>尊貴卡積分計算方法: 本金 X (佣金率 + 0.1%)</value>
  </data>
  <data name="msgInfoIncludeCashRollngOnly" xml:space="preserve">
    <value>只包括現金/月息轉碼數</value>
  </data>
  <data name="txtRollingAPlay_10K" xml:space="preserve">
    <value>A數轉碼(萬)</value>
  </data>
  <data name="txtRollingBPlay_10K" xml:space="preserve">
    <value>B數轉碼(萬)</value>
  </data>
  <data name="txtTableCurrency" xml:space="preserve">
    <value>賭枱貨幣</value>
  </data>
  <data name="txtBFDrinkAmt" xml:space="preserve">
    <value>食津累數</value>
  </data>
  <data name="txtExpAmount" xml:space="preserve">
    <value>消費數</value>
  </data>
  <data name="global_msgErrHasNoDataToPrint" xml:space="preserve">
    <value>沒有數據可列印</value>
  </data>
  <data name="txtCannotVoid" xml:space="preserve">
    <value>不可取消</value>
  </data>
  <data name="txtSettlementExists" xml:space="preserve">
    <value>月結已存在</value>
  </data>
  <data name="global_btnTransfer" xml:space="preserve">
    <value>轉帳</value>
  </data>
  <data name="txtfrmSettle" xml:space="preserve">
    <value>出</value>
  </data>
  <data name="txtIsSettle" xml:space="preserve">
    <value>的糧</value>
  </data>
  <data name="txtTo" xml:space="preserve">
    <value>至</value>
  </data>
  <data name="wCommissionCutoff" xml:space="preserve">
    <value>實出佣</value>
  </data>
  <data name="global_IOUPenaltyStatus" xml:space="preserve">
    <value>結算罰息</value>
  </data>
  <data name="txtConfirmCurPenalty" xml:space="preserve">
    <value>確認此月份罰息</value>
  </data>
  <data name="txtCustomerCode" xml:space="preserve">
    <value>客人號碼</value>
  </data>
  <data name="txtShowDisable" xml:space="preserve">
    <value>顯示不收</value>
  </data>
  <data name="typeCUSTOMERCHIPTRANBLST_Core" xml:space="preserve">
    <value>電投客人存款及明細</value>
  </data>
  <data name="txtOutstandingCommission" xml:space="preserve">
    <value>未出佣</value>
  </data>
  <data name="txt60DaysWithoutRtn" xml:space="preserve">
    <value>60日或以上沒有還款記錄</value>
  </data>
  <data name="txtOutStandingPenalty" xml:space="preserve">
    <value>倘欠罰息戶口</value>
  </data>
  <data name="txtDaysExp" xml:space="preserve">
    <value>過期天數</value>
  </data>
  <data name="txtTtl" xml:space="preserve">
    <value>總</value>
  </data>
  <data name="wOverdueAmt" xml:space="preserve">
    <value>過期數</value>
  </data>
  <data name="txtInstantCardBPlay" xml:space="preserve">
    <value>B數即出咭戶口</value>
  </data>
  <data name="typeCUSTOMERCHIPTRANBDTL_Core" xml:space="preserve">
    <value>電投存卡紀錄</value>
  </data>
  <data name="txtWin" xml:space="preserve">
    <value>羸錢</value>
  </data>
  <data name="wSettleTypeI" xml:space="preserve">
    <value>即出</value>
  </data>
  <data name="txtday" xml:space="preserve">
    <value>天</value>
  </data>
  <data name="typePLACE_FLOOR_PLAN_Core" xml:space="preserve">
    <value>場面平面圖</value>
  </data>
  <data name="typeCHIPTRANWITHDRAW_Core" xml:space="preserve">
    <value>提取</value>
  </data>
  <data name="txtAlreadyConfirmedInterestRate" xml:space="preserve">
    <value>已確認此月份派息</value>
  </data>
  <data name="txtConfirmInterestRate" xml:space="preserve">
    <value>確認此月份派息</value>
  </data>
  <data name="txtGenerateData" xml:space="preserve">
    <value>生成數據</value>
  </data>
  <data name="wInterested" xml:space="preserve">
    <value>已派回贈</value>
  </data>
  <data name="wBAmount_10k" xml:space="preserve">
    <value>存卡(萬)</value>
  </data>
  <data name="wCurrCName_AgentSummary" xml:space="preserve">
    <value>項目</value>
  </data>
  <data name="wExpAmount_10k" xml:space="preserve">
    <value>本月消費(萬)</value>
  </data>
  <data name="wHoldChipAmt_10k" xml:space="preserve">
    <value>凍結存卡(萬)</value>
  </data>
  <data name="wIAmount_10k" xml:space="preserve">
    <value>存單(萬)</value>
  </data>
  <data name="wIOUAmount_10k" xml:space="preserve">
    <value>借貸(萬)</value>
  </data>
  <data name="wRollingAmount_10k" xml:space="preserve">
    <value>本月轉碼(萬)</value>
  </data>
  <data name="typeSETTLEINTERESTRATELST_Core" xml:space="preserve">
    <value>回贈</value>
  </data>
  <data name="txtFollowing" xml:space="preserve">
    <value>跟進中</value>
  </data>
  <data name="txtRealLocate" xml:space="preserve">
    <value>資產處置中</value>
  </data>
  <data name="txtStopM" xml:space="preserve">
    <value>停止借貸</value>
  </data>
  <data name="txtHoldComm" xml:space="preserve">
    <value>HOLD佣</value>
  </data>
  <data name="txtLostContact" xml:space="preserve">
    <value>失聯</value>
  </data>
  <data name="typeRMARKRETTYOLSTRPT_Report" xml:space="preserve">
    <value>借貸歸還類別報表</value>
  </data>
  <data name="typeRMARKRETTYFLSTRPT_Report" xml:space="preserve">
    <value>借貸歸還類別報表</value>
  </data>
  <data name="global_msgErrAmountSmallerThanZero" xml:space="preserve">
    <value>金額必需大於 0</value>
  </data>
  <data name="global_msgErrHasNoRefNo" xml:space="preserve">
    <value>必需填入單號碼</value>
  </data>
  <data name="global_msgErrNewRefNoRequired" xml:space="preserve">
    <value>部份提單必需要填入新單號碼</value>
  </data>
  <data name="global_msgErrUpdByEqualAuthBy" xml:space="preserve">
    <value>授權人與經手人或跳過戶口認證授權人與經手人不能相同</value>
  </data>
  <data name="global_msgErrWrongAuthBy" xml:space="preserve">
    <value>授權人錯誤</value>
  </data>
  <data name="global_msgInfoPlsWaitForChecking" xml:space="preserve">
    <value>請稍候... ...系統正在覆核資料 ...</value>
  </data>
  <data name="txtMsgInvalidData" xml:space="preserve">
    <value>資料未能符合要求</value>
  </data>
  <data name="typeIOUPENALTYSTATUS_Core" xml:space="preserve">
    <value>結算罰息</value>
  </data>
  <data name="wPrice_10k" xml:space="preserve">
    <value>單價(萬)</value>
  </data>
  <data name="wRoomExpAmt_10k" xml:space="preserve">
    <value>房消費(萬)</value>
  </data>
  <data name="wCashRollC_10k" xml:space="preserve">
    <value>現金(萬)</value>
  </data>
  <data name="wCashRollS_10k" xml:space="preserve">
    <value>股本(萬)</value>
  </data>
  <data name="wCIOURoll_10k" xml:space="preserve">
    <value>公司U(萬)</value>
  </data>
  <data name="wIOURoll_10k" xml:space="preserve">
    <value>IOU(萬)</value>
  </data>
  <data name="wTotRollAmt_10k" xml:space="preserve">
    <value>總轉碼(萬)</value>
  </data>
  <data name="global_InterestRateInProgress" xml:space="preserve">
    <value>存款月利息計算中, 請於5至10分鐘後回來檢察狀態</value>
  </data>
  <data name="global_msgErrInterestMonthNotCompleted" xml:space="preserve">
    <value>回贈月份不能為未結束之月份</value>
  </data>
  <data name="global_msgInterestIsDividend" xml:space="preserve">
    <value>這個月份利息已計數</value>
  </data>
  <data name="ROLL" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="ROLL_C" xml:space="preserve">
    <value>加彩</value>
  </data>
  <data name="wRemarkColon" xml:space="preserve">
    <value>備註:</value>
  </data>
  <data name="txtSearchPanelFilter" xml:space="preserve">
    <value>過濾器設定</value>
  </data>
  <data name="wAppointmentDate" xml:space="preserve">
    <value>約見日期</value>
  </data>
  <data name="txtHasAppointment" xml:space="preserve">
    <value>有約見日期</value>
  </data>
  <data name="txtONLYOVERDUE" xml:space="preserve">
    <value>已過期單</value>
  </data>
  <data name="txtCreditExpDay" xml:space="preserve">
    <value>批額過期日數</value>
  </data>
  <data name="txtNoReturnDay" xml:space="preserve">
    <value>無還款天數</value>
  </data>
  <data name="txtAppointmentCount" xml:space="preserve">
    <value>約見次數</value>
  </data>
  <data name="txtDisConnectCount" xml:space="preserve">
    <value>失聯次數</value>
  </data>
  <data name="txtFailSolutionCount" xml:space="preserve">
    <value>約見方案不達標次數</value>
  </data>
  <data name="txtOverdueOrderpercent" xml:space="preserve">
    <value>過期單比例</value>
  </data>
  <data name="txtOverdueAmtpercent" xml:space="preserve">
    <value>過期數比例</value>
  </data>
  <data name="typeCOUNTERBAL_B_Core" xml:space="preserve">
    <value>B數櫃數表</value>
  </data>
  <data name="wDrinkOutstanding" xml:space="preserve">
    <value>尚餘積分</value>
  </data>
  <data name="wBFExpOutstanding" xml:space="preserve">
    <value>尚餘欠費</value>
  </data>
  <data name="wBFDrinkAmountHKD" xml:space="preserve">
    <value>HKD積分累數</value>
  </data>
  <data name="typeCREDITCONTROL_ROOT_Core" xml:space="preserve">
    <value>信貸</value>
  </data>
  <data name="wSolutionExpDate" xml:space="preserve">
    <value>方案到期日</value>
  </data>
  <data name="txtComingExpire" xml:space="preserve">
    <value>即將到期</value>
  </data>
  <data name="txtExpire" xml:space="preserve">
    <value>已到期</value>
  </data>
  <data name="txtFollowDate" xml:space="preserve">
    <value>跟進日期</value>
  </data>
  <data name="txtSolutionExpire" xml:space="preserve">
    <value>方案到期</value>
  </data>
  <data name="txtNotShowHoldComm" xml:space="preserve">
    <value>不顯示HOLD佣</value>
  </data>
  <data name="global_msgExpireYearMthNoLargerPeriodCodeIn_Process" xml:space="preserve">
    <value>限期不能小于執行期</value>
  </data>
  <data name="global_msgYearMthNoLargerPeriodCodeIn_Process" xml:space="preserve">
    <value>輸入期不能小于執行期</value>
  </data>
  <data name="global_msgSelectedMaster" xml:space="preserve">
    <value>選取或母資料並未選取</value>
  </data>
  <data name="global_txtNumberOfRoom" xml:space="preserve">
    <value>房數</value>
  </data>
  <data name="global_txtNumberOfTable" xml:space="preserve">
    <value>枱數</value>
  </data>
  <data name="global_txtRouteMachine" xml:space="preserve">
    <value>路紙機</value>
  </data>
  <data name="global_msgSystemDataCannotAmend" xml:space="preserve">
    <value>不能修改系統資料</value>
  </data>
  <data name="global_txtAmt" xml:space="preserve">
    <value>額</value>
  </data>
  <data name="global_txtCapital" xml:space="preserve">
    <value>本金</value>
  </data>
  <data name="global_txtLarge" xml:space="preserve">
    <value>大</value>
  </data>
  <data name="global_txtNormal" xml:space="preserve">
    <value>普通</value>
  </data>
  <data name="global_txtSmall" xml:space="preserve">
    <value>小</value>
  </data>
  <data name="global_txtBNumber_X" xml:space="preserve">
    <value>偷食</value>
  </data>
  <data name="global_txtBooked" xml:space="preserve">
    <value>已預留</value>
  </data>
  <data name="global_txtNotSpecified" xml:space="preserve">
    <value>未定義</value>
  </data>
  <data name="btnConfirm" xml:space="preserve">
    <value>確定</value>
  </data>
  <data name="cbConfirmSettleTran" xml:space="preserve">
    <value>確認此月份碼糧</value>
  </data>
  <data name="CompanyGroup" xml:space="preserve">
    <value>集團</value>
  </data>
  <data name="GrpOperate" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="IOU10k" xml:space="preserve">
    <value>借款(萬)</value>
  </data>
  <data name="mAgent" xml:space="preserve">
    <value>戶口</value>
  </data>
  <data name="month" xml:space="preserve">
    <value>月</value>
  </data>
  <data name="msgErrAmountSmallerThanZero" xml:space="preserve">
    <value>金額必需大於 0</value>
  </data>
  <data name="msgErrFail" xml:space="preserve">
    <value>失敗</value>
  </data>
  <data name="msgErrNotSufficient" xml:space="preserve">
    <value>不足夠</value>
  </data>
  <data name="msgInfoSettleItemSetFxRate" xml:space="preserve">
    <value>匯率的乘及除只可以一個是1或設定匯率為0</value>
  </data>
  <data name="RollStatusOptC" xml:space="preserve">
    <value>離場</value>
  </data>
  <data name="statusPlsSelect" xml:space="preserve">
    <value>請選擇</value>
  </data>
  <data name="txtCurrencyCode" xml:space="preserve">
    <value>貨幣碼</value>
  </data>
  <data name="txtCustomerCurrency" xml:space="preserve">
    <value>客人兌換貨幣</value>
  </data>
  <data name="txtCustomInstantCard" xml:space="preserve">
    <value>自訂即出咭戶口</value>
  </data>
  <data name="txtEarlyInstant" xml:space="preserve">
    <value>提前即出佣金</value>
  </data>
  <data name="txtExchangeCurrCode" xml:space="preserve">
    <value>兌換貨幣</value>
  </data>
  <data name="txtForeign" xml:space="preserve">
    <value>海外</value>
  </data>
  <data name="txtForeignInstantPaidAtMacau" xml:space="preserve">
    <value>在澳門支付佣金</value>
  </data>
  <data name="txtGlobalPointFxRate" xml:space="preserve">
    <value>澳門積分兌換率</value>
  </data>
  <data name="txtInstantBFExpCard" xml:space="preserve">
    <value>即出欠前消費咭戶口</value>
  </data>
  <data name="txtInstantExpCard2" xml:space="preserve">
    <value>即出會員消費咭戶口</value>
  </data>
  <data name="txtIou_ForeignInstantPaid" xml:space="preserve">
    <value>本次借貸(萬)</value>
  </data>
  <data name="txtNoSettingWithCurrency" xml:space="preserve">
    <value>未設有關貨幣表</value>
  </data>
  <data name="txtSalaryPaidByHKD" xml:space="preserve">
    <value>以港幣支付佣金</value>
  </data>
  <data name="year" xml:space="preserve">
    <value>年</value>
  </data>
  <data name="AccTypeDn" xml:space="preserve">
    <value>會員降級</value>
  </data>
  <data name="AccTypeExtend" xml:space="preserve">
    <value>延期</value>
  </data>
  <data name="AccTypeUp" xml:space="preserve">
    <value>會員升級</value>
  </data>
  <data name="All" xml:space="preserve">
    <value>所有</value>
  </data>
  <data name="Amount" xml:space="preserve">
    <value>金額</value>
  </data>
  <data name="AuthIdentityASSISTANT" xml:space="preserve">
    <value>業務發展部助理</value>
  </data>
  <data name="AuthIdentityAUTH" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="AuthIdentityBOSS" xml:space="preserve">
    <value>幕後老闆</value>
  </data>
  <data name="AuthIdentityCLIENT" xml:space="preserve">
    <value>客人</value>
  </data>
  <data name="AuthIdentityDIRECTOR" xml:space="preserve">
    <value>總監</value>
  </data>
  <data name="AuthIdentityFAMILY" xml:space="preserve">
    <value>家人</value>
  </data>
  <data name="AuthIdentityMARKETING" xml:space="preserve">
    <value>市場部</value>
  </data>
  <data name="AuthIdentityOWNER" xml:space="preserve">
    <value>戶主</value>
  </data>
  <data name="AuthIdentityPARTNER" xml:space="preserve">
    <value>拍檔</value>
  </data>
  <data name="AuthIdentitySTAFF" xml:space="preserve">
    <value>伙記</value>
  </data>
  <data name="AuthIdentityWARRANTOR" xml:space="preserve">
    <value>借貸担保人</value>
  </data>
  <data name="btnDontSend" xml:space="preserve">
    <value>不發送</value>
  </data>
  <data name="btnSelAll" xml:space="preserve">
    <value>全選</value>
  </data>
  <data name="btnShowAll" xml:space="preserve">
    <value>顯示所有</value>
  </data>
  <data name="CancelCreditTypeStopM" xml:space="preserve">
    <value>解除停M</value>
  </data>
  <data name="Capital" xml:space="preserve">
    <value>本金</value>
  </data>
  <data name="CashTypeCH" xml:space="preserve">
    <value>個人借貸</value>
  </data>
  <data name="CashTypeIOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="cbShowBalance" xml:space="preserve">
    <value>顯示結存</value>
  </data>
  <data name="cent" xml:space="preserve">
    <value>分</value>
  </data>
  <data name="ChipTranTranTypeCR" xml:space="preserve">
    <value>提取</value>
  </data>
  <data name="ChipTranTranTypeCS" xml:space="preserve">
    <value>存入</value>
  </data>
  <data name="ChipTranTypeB" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="CreditTypeLongTerm" xml:space="preserve">
    <value>長期</value>
  </data>
  <data name="CreditTypeMonRate" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="CreditTypeOnce" xml:space="preserve">
    <value>一次</value>
  </data>
  <data name="CreditTypeStopM" xml:space="preserve">
    <value>停M</value>
  </data>
  <data name="CurrentAssets" xml:space="preserve">
    <value>流動資產</value>
  </data>
  <data name="CurrentLib" xml:space="preserve">
    <value>流動負債</value>
  </data>
  <data name="dollar" xml:space="preserve">
    <value>圓</value>
  </data>
  <data name="dollarWhole" xml:space="preserve">
    <value>圓整</value>
  </data>
  <data name="eight" xml:space="preserve">
    <value>捌</value>
  </data>
  <data name="emptyString" xml:space="preserve">
    <value>(空白)</value>
  </data>
  <data name="eSettleTranStatusOpt_C" xml:space="preserve">
    <value>已出</value>
  </data>
  <data name="eSettleTranStatusOpt_O" xml:space="preserve">
    <value>未出</value>
  </data>
  <data name="ExpenseCateF" xml:space="preserve">
    <value>食單</value>
  </data>
  <data name="ExpenseCateH" xml:space="preserve">
    <value>酒店</value>
  </data>
  <data name="ExpenseCateO" xml:space="preserve">
    <value>其它</value>
  </data>
  <data name="ExpenseCateS" xml:space="preserve">
    <value>船票</value>
  </data>
  <data name="ExpenseCateTC" xml:space="preserve">
    <value>直升機/車</value>
  </data>
  <data name="five" xml:space="preserve">
    <value>伍</value>
  </data>
  <data name="FixedAssets" xml:space="preserve">
    <value>固定資產</value>
  </data>
  <data name="four" xml:space="preserve">
    <value>肆</value>
  </data>
  <data name="GeneralExpense" xml:space="preserve">
    <value>通常開支</value>
  </data>
  <data name="GrpMarker" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="GrpWinLoss" xml:space="preserve">
    <value>枱面</value>
  </data>
  <data name="hidden" xml:space="preserve">
    <value>不顯示</value>
  </data>
  <data name="hundred" xml:space="preserve">
    <value>佰</value>
  </data>
  <data name="hundredm" xml:space="preserve">
    <value>億</value>
  </data>
  <data name="lblMainIntroduce" xml:space="preserve">
    <value>主要來貨</value>
  </data>
  <data name="lblOthersIntroduce" xml:space="preserve">
    <value>其他來貨</value>
  </data>
  <data name="ManufacturingAcc" xml:space="preserve">
    <value>工業賬目</value>
  </data>
  <data name="MarkerReportSearchType_Completed" xml:space="preserve">
    <value>已歸還</value>
  </data>
  <data name="MarkerReportSearchType_Outstanding" xml:space="preserve">
    <value>未歸還</value>
  </data>
  <data name="mExpense" xml:space="preserve">
    <value>消費</value>
  </data>
  <data name="msgAskConfirm" xml:space="preserve">
    <value>請確認</value>
  </data>
  <data name="msgAskConfirmChipTranB" xml:space="preserve">
    <value>確認完成此項存卡？</value>
  </data>
  <data name="msgAskConfirmPerformRollingAction" xml:space="preserve">
    <value>確認並執行此項轉碼？</value>
  </data>
  <data name="msgAskConfirmRollCompleted" xml:space="preserve">
    <value>確認完成此項轉碼？</value>
  </data>
  <data name="msgAskConfirmStoreMarker" xml:space="preserve">
    <value>確認完成此項存M？</value>
  </data>
  <data name="msgAskRejectRoll" xml:space="preserve">
    <value>確認不允許此項轉碼？</value>
  </data>
  <data name="msgInfoPlsInput" xml:space="preserve">
    <value>請輸入</value>
  </data>
  <data name="msgInvalidData" xml:space="preserve">
    <value>資料未能符合要求</value>
  </data>
  <data name="msgNeedAddCapitalBeforeRolling" xml:space="preserve">
    <value>轉碼執行前必須加彩</value>
  </data>
  <data name="msgNotPositiveNumber" xml:space="preserve">
    <value>輸入的不是正數字！</value>
  </data>
  <data name="msgNumTooLarge" xml:space="preserve">
    <value>數字太大，無法換算，請輸入一萬億元以下的金額</value>
  </data>
  <data name="msgPlsWaitUntilPerviousActionEnded" xml:space="preserve">
    <value>請等待完成上一項動作</value>
  </data>
  <data name="Negative" xml:space="preserve">
    <value>負</value>
  </data>
  <data name="nine" xml:space="preserve">
    <value>玖</value>
  </data>
  <data name="one" xml:space="preserve">
    <value>壹</value>
  </data>
  <data name="PrintPreview" xml:space="preserve">
    <value>預覽列印</value>
  </data>
  <data name="ProvisionForTaxation" xml:space="preserve">
    <value>預繳稅金</value>
  </data>
  <data name="rAgentBookingProgressive" xml:space="preserve">
    <value>業務進步約見名單</value>
  </data>
  <data name="rAgentChipBookMoreThanMarker" xml:space="preserve">
    <value>每月存款大於過期Marker</value>
  </data>
  <data name="rAgentCreditAmount" xml:space="preserve">
    <value>批碼金額及戶口</value>
  </data>
  <data name="rAgentCreditOver100KRollUnder1M" xml:space="preserve">
    <value>批額1千不達標</value>
  </data>
  <data name="rAgentWinLossTop20" xml:space="preserve">
    <value>輸贏排名</value>
  </data>
  <data name="rCreditAndRollingList" xml:space="preserve">
    <value>已批額玩家戶口及轉碼</value>
  </data>
  <data name="RemoteOperation" xml:space="preserve">
    <value>遙距指令</value>
  </data>
  <data name="ReturnType_C" xml:space="preserve">
    <value>現碼還M</value>
  </data>
  <data name="ReturnType_M" xml:space="preserve">
    <value>M還M</value>
  </data>
  <data name="ReturnType_R" xml:space="preserve">
    <value>存M還M</value>
  </data>
  <data name="ReturnType_W" xml:space="preserve">
    <value>贏M回舊M</value>
  </data>
  <data name="rFollowZZSAccount" xml:space="preserve">
    <value>ZZS/OT/OF/OK分析</value>
  </data>
  <data name="rLatest30DaysFirstMarkerAccount" xml:space="preserve">
    <value>批M首月轉碼</value>
  </data>
  <data name="rNewAgentCreditRolling" xml:space="preserve">
    <value>新批玩家戶口及轉碼</value>
  </data>
  <data name="rNoMarkerList" xml:space="preserve">
    <value>停M名單</value>
  </data>
  <data name="RollStatusOptO" xml:space="preserve">
    <value>在場</value>
  </data>
  <data name="txtRollTypeCode" xml:space="preserve">
    <value>轉碼類型</value>
  </data>
  <data name="RollTypeCodeCaptital" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="RollTypeCodeCash" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="RollTypeCodeCIOU" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="RollTypeCodeIOU" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="rSubstandardAgentCreditOver1M" xml:space="preserve">
    <value>有額超過1個月無用名單</value>
  </data>
  <data name="SettleSetConfirm" xml:space="preserve">
    <value>確認</value>
  </data>
  <data name="SettleSetNotConfirm" xml:space="preserve">
    <value>未確認</value>
  </data>
  <data name="seven" xml:space="preserve">
    <value>柒</value>
  </data>
  <data name="Shift1" xml:space="preserve">
    <value>早更</value>
  </data>
  <data name="Shift2" xml:space="preserve">
    <value>中更</value>
  </data>
  <data name="Shift3" xml:space="preserve">
    <value>夜更</value>
  </data>
  <data name="six" xml:space="preserve">
    <value>陸</value>
  </data>
  <data name="SMSStatus_A1" xml:space="preserve">
    <value>已推送</value>
  </data>
  <data name="SMSStatus_C1" xml:space="preserve">
    <value>成功</value>
  </data>
  <data name="SMSStatus_F" xml:space="preserve">
    <value>失敗</value>
  </data>
  <data name="SMSStatus_O" xml:space="preserve">
    <value>排隊發送</value>
  </data>
  <data name="SMSStatus_T" xml:space="preserve">
    <value>發送系統故障</value>
  </data>
  <data name="SMS_ACCOUNTTYPE" xml:space="preserve">
    <value>戶口級別升降</value>
  </data>
  <data name="SMS_AGENTUPD" xml:space="preserve">
    <value>戶口修改</value>
  </data>
  <data name="SMS_CREDIT" xml:space="preserve">
    <value>批額修改</value>
  </data>
  <data name="SMS_DAIROLLRPT" xml:space="preserve">
    <value>每日集團轉碼報表</value>
  </data>
  <data name="SMS_EXPDAILY" xml:space="preserve">
    <value>每日集團消費報表</value>
  </data>
  <data name="SMS_FOREIGN_ADDCAPITAL" xml:space="preserve">
    <value>海外加彩</value>
  </data>
  <data name="SMS_FOREIGN_CLOSE" xml:space="preserve">
    <value>海外離場</value>
  </data>
  <data name="SMS_FOREIGN_CLOSECONT" xml:space="preserve">
    <value>海外離場(續場)</value>
  </data>
  <data name="SMS_FOREIGN_OPEN" xml:space="preserve">
    <value>海外開場</value>
  </data>
  <data name="SMS_FOREIGN_OPENCONT" xml:space="preserve">
    <value>海外開場(續場)</value>
  </data>
  <data name="SMS_FOREIGN_SETTLE_CU" xml:space="preserve">
    <value>客人海外結算</value>
  </data>
  <data name="SMS_OPERATE_ADDCAPITAL" xml:space="preserve">
    <value>營運加彩</value>
  </data>
  <data name="SMS_OPERATE_CLOSE" xml:space="preserve">
    <value>營運離場</value>
  </data>
  <data name="SMS_OPERATE_CLOSECONT" xml:space="preserve">
    <value>營運離場(續場)</value>
  </data>
  <data name="SMS_OPERATE_OPEN" xml:space="preserve">
    <value>營運開場</value>
  </data>
  <data name="SMS_OPERATE_OPENCONT" xml:space="preserve">
    <value>營運開場(續場)</value>
  </data>
  <data name="SMS_OPERATE_SETTLE_CU" xml:space="preserve">
    <value>客人營運結算</value>
  </data>
  <data name="SMS_ROLLDAILY" xml:space="preserve">
    <value>轉碼日結</value>
  </data>
  <data name="SMS_ROLLDAILYSHARE" xml:space="preserve">
    <value>轉碼日結(股東組)</value>
  </data>
  <data name="SMS_SUBAGENT_INFO" xml:space="preserve">
    <value>下線資料</value>
  </data>
  <data name="TableBookingStatus_Booked" xml:space="preserve">
    <value>已預訂</value>
  </data>
  <data name="TableBookingStatus_Empty" xml:space="preserve">
    <value>閒置</value>
  </data>
  <data name="TableBookingStatus_Occupied" xml:space="preserve">
    <value>使用中</value>
  </data>
  <data name="TableTranStatusOptC" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="TableTranStatusOptO" xml:space="preserve">
    <value>有效</value>
  </data>
  <data name="tAssetsProcess" xml:space="preserve">
    <value>資產處理中</value>
  </data>
  <data name="tBlackList" xml:space="preserve">
    <value>黑名單</value>
  </data>
  <data name="tCannotConnect" xml:space="preserve">
    <value>無法接通</value>
  </data>
  <data name="tDelayPaid" xml:space="preserve">
    <value>延期還款</value>
  </data>
  <data name="tEmptyNo" xml:space="preserve">
    <value>空號</value>
  </data>
  <data name="ten" xml:space="preserve">
    <value>拾</value>
  </data>
  <data name="tenCent" xml:space="preserve">
    <value>角</value>
  </data>
  <data name="tenk" xml:space="preserve">
    <value>萬</value>
  </data>
  <data name="tenZero" xml:space="preserve">
    <value>拾零</value>
  </data>
  <data name="tExpectPaid" xml:space="preserve">
    <value>預期還款</value>
  </data>
  <data name="thousand" xml:space="preserve">
    <value>仟</value>
  </data>
  <data name="three" xml:space="preserve">
    <value>叁</value>
  </data>
  <data name="tInstallments" xml:space="preserve">
    <value>分期還款</value>
  </data>
  <data name="tNoReceiveCall" xml:space="preserve">
    <value>無人接聽</value>
  </data>
  <data name="tNotConfrimPaidDate" xml:space="preserve">
    <value>沒法落實時間</value>
  </data>
  <data name="tOtherPplReceiveCall" xml:space="preserve">
    <value>其它人接聽</value>
  </data>
  <data name="tProcessing" xml:space="preserve">
    <value>跟進中</value>
  </data>
  <data name="TradingAccount" xml:space="preserve">
    <value>貿易賬目</value>
  </data>
  <data name="tReceiveCall" xml:space="preserve">
    <value>本人接聽</value>
  </data>
  <data name="tReceiveNotStable" xml:space="preserve">
    <value>接聽次數不穩定</value>
  </data>
  <data name="tRepeatedlyDelay" xml:space="preserve">
    <value>多次延期</value>
  </data>
  <data name="tSeekInterest" xml:space="preserve">
    <value>追收利息</value>
  </data>
  <data name="tShutDown" xml:space="preserve">
    <value>關機</value>
  </data>
  <data name="two" xml:space="preserve">
    <value>貳</value>
  </data>
  <data name="txtAgentAccountType1" xml:space="preserve">
    <value>太陽客戶</value>
  </data>
  <data name="txtAgentAccountType2" xml:space="preserve">
    <value>金太陽</value>
  </data>
  <data name="txtAgentAccountType3" xml:space="preserve">
    <value>卓越</value>
  </data>
  <data name="txtAgentAccountType4" xml:space="preserve">
    <value>非凡</value>
  </data>
  <data name="txtAgentAccountType5" xml:space="preserve">
    <value>奇蹟</value>
  </data>
  <data name="txtAgentAccountType6" xml:space="preserve">
    <value>傳奇</value>
  </data>
  <data name="txtAgentAccountType7" xml:space="preserve">
    <value>至尊</value>
  </data>
  <data name="txtAgentTypeGolden" xml:space="preserve">
    <value>金咭戶</value>
  </data>
  <data name="txtAgentTypeNew" xml:space="preserve">
    <value>新開戶</value>
  </data>
  <data name="txtAgentTypeNormal" xml:space="preserve">
    <value>基本戶</value>
  </data>
  <data name="txtAgentTypeVIP" xml:space="preserve">
    <value>VIP</value>
  </data>
  <data name="txtAgentTypeVVIP" xml:space="preserve">
    <value>VVIP</value>
  </data>
  <data name="txtCapitalTranS" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="txtCapitalTranY" xml:space="preserve">
    <value>食貨</value>
  </data>
  <data name="txtCashIOU" xml:space="preserve">
    <value>現金借貸單</value>
  </data>
  <data name="txtCasinoCreditAmt" xml:space="preserve">
    <value>娛樂場額</value>
  </data>
  <data name="txtChipTranCompanyTotalAmount" xml:space="preserve">
    <value>集團結存</value>
  </data>
  <data name="txtCreditAmtU" xml:space="preserve">
    <value>U可簽額</value>
  </data>
  <data name="txtDateOption" xml:space="preserve">
    <value>日期</value>
  </data>
  <data name="txtDatePeriodOption" xml:space="preserve">
    <value>日期範圍</value>
  </data>
  <data name="txtDept_Cage" xml:space="preserve">
    <value>賬房</value>
  </data>
  <data name="txtDept_CustRelate" xml:space="preserve">
    <value>業務發展部</value>
  </data>
  <data name="txtDept_Develop" xml:space="preserve">
    <value>市場拓展部</value>
  </data>
  <data name="txtDept_Front" xml:space="preserve">
    <value>市場及貴賓部</value>
  </data>
  <data name="txtDept_Member" xml:space="preserve">
    <value>會籍部</value>
  </data>
  <data name="txtDept_Room" xml:space="preserve">
    <value>客戶服務部</value>
  </data>
  <data name="txtDept_Vehicle" xml:space="preserve">
    <value>車務部</value>
  </data>
  <data name="txtFalse" xml:space="preserve">
    <value>否</value>
  </data>
  <data name="txtForeignCapitalCheckInType" xml:space="preserve">
    <value>出碼數計算佣金</value>
  </data>
  <data name="txtForeignCapitalCheckIn_WLType" xml:space="preserve">
    <value>出碼及下數計算佣金</value>
  </data>
  <data name="txtForeignCapitalRollingType" xml:space="preserve">
    <value>轉碼數倍數佣金</value>
  </data>
  <data name="txtForeignCashOut" xml:space="preserve">
    <value>現金支出</value>
  </data>
  <data name="txtForeignExpense" xml:space="preserve">
    <value>支出</value>
  </data>
  <data name="txtForeignIOU" xml:space="preserve">
    <value>海外借貸單</value>
  </data>
  <data name="txtForeignTour" xml:space="preserve">
    <value>外來團</value>
  </data>
  <data name="txtInterestDateOpt" xml:space="preserve">
    <value>應派息日期</value>
  </data>
  <data name="txtIOUFreeze" xml:space="preserve">
    <value>凍結</value>
  </data>
  <data name="txtLocalTour" xml:space="preserve">
    <value>本地團</value>
  </data>
  <data name="txtNNChip" xml:space="preserve">
    <value>泥碼</value>
  </data>
  <data name="txtOneMonth" xml:space="preserve">
    <value>一月</value>
  </data>
  <data name="txtOneWeek" xml:space="preserve">
    <value>一週</value>
  </data>
  <data name="txtOneYear" xml:space="preserve">
    <value>一年</value>
  </data>
  <data name="txtOperateExternal" xml:space="preserve">
    <value>私營</value>
  </data>
  <data name="txtOperateIOU" xml:space="preserve">
    <value>營運借貸單</value>
  </data>
  <data name="txtOutStanding" xml:space="preserve">
    <value>欠款</value>
  </data>
  <data name="txtOutStandingPartPrint" xml:space="preserve">
    <value>是次部分</value>
  </data>
  <data name="txtOutStandingPrint" xml:space="preserve">
    <value>尚欠</value>
  </data>
  <data name="txtPay" xml:space="preserve">
    <value>出糧</value>
  </data>
  <data name="txtPersonal" xml:space="preserve">
    <value>個人</value>
  </data>
  <data name="txtRollingPeriod_DAY" xml:space="preserve">
    <value>日數</value>
  </data>
  <data name="txtRollingPeriod_MTH" xml:space="preserve">
    <value>月數</value>
  </data>
  <data name="txtRollingPeriod_YER" xml:space="preserve">
    <value>年數</value>
  </data>
  <data name="txtSettleStatusOutstanding" xml:space="preserve">
    <value>未結算</value>
  </data>
  <data name="txtSMS_EXIT" xml:space="preserve">
    <value>離場訊息</value>
  </data>
  <data name="txtSMS_MONTH_END_SETTLE" xml:space="preserve">
    <value>出佣訊息</value>
  </data>
  <data name="txtSMS_OPEN" xml:space="preserve">
    <value>開場訊息</value>
  </data>
  <data name="txtStore_Cash" xml:space="preserve">
    <value>存C</value>
  </data>
  <data name="txtTrue" xml:space="preserve">
    <value>是</value>
  </data>
  <data name="txtUpdtOpt" xml:space="preserve">
    <value>操作日期</value>
  </data>
  <data name="txtYearMonthOption" xml:space="preserve">
    <value>年月份</value>
  </data>
  <data name="txtYearOption" xml:space="preserve">
    <value>年份</value>
  </data>
  <data name="uIOUWarnLst" xml:space="preserve">
    <value>貸款提示</value>
  </data>
  <data name="visible" xml:space="preserve">
    <value>顯示</value>
  </data>
  <data name="zero" xml:space="preserve">
    <value>零</value>
  </data>
  <data name="zeroCent" xml:space="preserve">
    <value>零分</value>
  </data>
  <data name="zeroHundred" xml:space="preserve">
    <value>零佰</value>
  </data>
  <data name="zeroHundredm" xml:space="preserve">
    <value>零億</value>
  </data>
  <data name="zeroTen" xml:space="preserve">
    <value>零拾</value>
  </data>
  <data name="zeroTenCent" xml:space="preserve">
    <value>零角</value>
  </data>
  <data name="zeroTenk" xml:space="preserve">
    <value>零萬</value>
  </data>
  <data name="zeroThousand" xml:space="preserve">
    <value>零仟</value>
  </data>
  <data name="zeroZero" xml:space="preserve">
    <value>零零</value>
  </data>
  <data name="msgInfoCardReaderReadFailed" xml:space="preserve">
    <value>讀卡錯誤</value>
  </data>
  <data name="msgInfoCardReaderWriteFailed" xml:space="preserve">
    <value>寫卡錯誤</value>
  </data>
  <data name="msgInfoNoSmartCardDetected" xml:space="preserve">
    <value>請放上智能卡</value>
  </data>
  <data name="msgInfoSuccess" xml:space="preserve">
    <value>成功</value>
  </data>
  <data name="txtElite" xml:space="preserve">
    <value>尊華會</value>
  </data>
  <data name="txtYearMth" xml:space="preserve">
    <value>週期</value>
  </data>
  <data name="txtTranAmt10k" xml:space="preserve">
    <value>交易金額(萬)</value>
  </data>
  <data name="typeOPERATECOMPLST_Core" xml:space="preserve">
    <value>營運公司管理</value>
  </data>
  <data name="txtManagement" xml:space="preserve">
    <value>管理層</value>
  </data>
  <data name="txtOperateCompCredit" xml:space="preserve">
    <value>保證金</value>
  </data>
  <data name="txtOperateCompCreditBal" xml:space="preserve">
    <value>保證金存額</value>
  </data>
  <data name="txtOperateCompTitle" xml:space="preserve">
    <value>公司列表</value>
  </data>
  <data name="txtShare" xml:space="preserve">
    <value>股份</value>
  </data>
  <data name="txtShareListTitle" xml:space="preserve">
    <value>股東列表</value>
  </data>
  <data name="txtSMS" xml:space="preserve">
    <value>短訊</value>
  </data>
  <data name="statusActive" xml:space="preserve">
    <value>有效</value>
  </data>
  <data name="statusSuspend" xml:space="preserve">
    <value>停用</value>
  </data>
  <data name="txtTransactionValue10K" xml:space="preserve">
    <value>交易金額(萬)</value>
  </data>
  <data name="eOperateCompLst" xml:space="preserve">
    <value>營運公司管理</value>
  </data>
  <data name="txtRelateAgent" xml:space="preserve">
    <value>相關戶口</value>
  </data>
  <data name="ePopupOperateCompDtl" xml:space="preserve">
    <value>營運公司記錄</value>
  </data>
  <data name="txtStatus" xml:space="preserve">
    <value>狀態</value>
  </data>
  <data name="txtStatusTerminateDate" xml:space="preserve">
    <value>中止日期</value>
  </data>
  <data name="wAppBidTakeRest" xml:space="preserve">
    <value>以手機應用程式食貨如超額認購，自動認購系統當時的餘額佔成</value>
  </data>
  <data name="wCreditHoldMultiple" xml:space="preserve">
    <value>凍結倍數</value>
  </data>
  <data name="wIsCheckCredit" xml:space="preserve">
    <value>佔成時檢查保証金</value>
  </data>
  <data name="wIsCheckCreditAddCapital" xml:space="preserve">
    <value>加彩時檢查保証金</value>
  </data>
  <data name="wIsMainComp" xml:space="preserve">
    <value>主公司</value>
  </data>
  <data name="ePopupOperateCompShareDtl" xml:space="preserve">
    <value>營運公司股東記錄</value>
  </data>
  <data name="lblAppsNewBidPassword" xml:space="preserve">
    <value>手機程式食貨密碼</value>
  </data>
  <data name="lblAppsNewPassword" xml:space="preserve">
    <value>新手機程式密碼</value>
  </data>
  <data name="txtCustName" xml:space="preserve">
    <value>名稱</value>
  </data>
  <data name="txtSharePercent" xml:space="preserve">
    <value>股份數量</value>
  </data>
  <data name="txtTelSMS" xml:space="preserve">
    <value>短訊號碼</value>
  </data>
  <data name="txtShiftRolling" xml:space="preserve">
    <value>本更轉碼</value>
  </data>
  <data name="txtLineGrp_Ext" xml:space="preserve">
    <value>(A-Z)</value>
  </data>
  <data name="msgInfoOperateCompAgentAdded" xml:space="preserve">
    <value>股東已加入</value>
  </data>
  <data name="txtNoData" xml:space="preserve">
    <value>沒有數據</value>
  </data>
  <data name="global_btnGenCardActCode" xml:space="preserve">
    <value>設置卡行動碼</value>
  </data>
  <data name="global_msgErrStaffCardActionCodeEmpty" xml:space="preserve">
    <value>必須設置卡行動碼</value>
  </data>
  <data name="global_RegenCardActCode" xml:space="preserve">
    <value>重設卡行動碼</value>
  </data>
  <data name="msgErrPwdNotMatch" xml:space="preserve">
    <value>新密碼及確認密碼必須相同</value>
  </data>
  <data name="eOperateCompCreditDtl" xml:space="preserve">
    <value>營運公司保證金記錄</value>
  </data>
  <data name="txtOperateCompany" xml:space="preserve">
    <value>營運公司</value>
  </data>
  <data name="typeOPERATECOMPCREDIT_Core" xml:space="preserve">
    <value>營運公司保證金管理</value>
  </data>
  <data name="action_BOOKMARK_type" xml:space="preserve">
    <value>關注</value>
  </data>
  <data name="action_BYPASS_type" xml:space="preserve">
    <value>By Pass</value>
  </data>
  <data name="action_COMPALLSTATUS_type" xml:space="preserve">
    <value>集團概況</value>
  </data>
  <data name="action_CREDITCONTROL_type" xml:space="preserve">
    <value>信貸監控</value>
  </data>
  <data name="action_CREDITSTATUS_type" xml:space="preserve">
    <value>信貸額概況</value>
  </data>
  <data name="action_CUSTOMER_type" xml:space="preserve">
    <value>相關客人</value>
  </data>
  <data name="action_FIRST_SET_PWD_type" xml:space="preserve">
    <value>FirstSetPwd</value>
  </data>
  <data name="action_LASTESTWINLOSS_type" xml:space="preserve">
    <value>最近輸贏數</value>
  </data>
  <data name="action_MEMBERCARD_type" xml:space="preserve">
    <value>會員卡</value>
  </data>
  <data name="action_PREVIEW_type" xml:space="preserve">
    <value>列印預覽</value>
  </data>
  <data name="action_RESET_PWD_type" xml:space="preserve">
    <value>重置密碼</value>
  </data>
  <data name="action_ROLLINGAMT_type" xml:space="preserve">
    <value>轉碼概況</value>
  </data>
  <data name="action_SAVE_type" xml:space="preserve">
    <value>儲存Save</value>
  </data>
  <data name="action_SMS_type" xml:space="preserve">
    <value>SMS</value>
  </data>
  <data name="action_UPDATEPRINT_type" xml:space="preserve">
    <value>儲存並列印</value>
  </data>
  <data name="typeCOMP_SHIFTCUT_Core" xml:space="preserve">
    <value>換更</value>
  </data>
  <data name="typeSEARCHPANELCONFIG_Core" xml:space="preserve">
    <value>過濾器設定</value>
  </data>
  <data name="typeRCREDITCONTROL_AGENT_TRACE_RPT_Report" xml:space="preserve">
    <value>信貸監控個人報表</value>
  </data>
  <data name="txtSettleByCode" xml:space="preserve">
    <value>港幣結算</value>
  </data>
  <data name="txtSettleByRMB" xml:space="preserve">
    <value>人民幣結算</value>
  </data>
  <data name="typeBPLAY_DTL_Core" xml:space="preserve">
    <value>B數記錄</value>
  </data>
  <data name="typeFINANCIAL_CENTRE_Core" xml:space="preserve">
    <value>綜合理財</value>
  </data>
  <data name="typeIOUPENALTYADJDTL_F_Core" xml:space="preserve">
    <value>罰息調整記錄海外)</value>
  </data>
  <data name="typeIOUPENALTYADJDTL_IOU_Core" xml:space="preserve">
    <value>罰息調整記錄</value>
  </data>
  <data name="typeIOUPENALTYADJDTL_Y_Core" xml:space="preserve">
    <value>罰息調整記錄(營運)</value>
  </data>
  <data name="typeIOUPENALTYSETDTL_Core" xml:space="preserve">
    <value>罰息設定記錄</value>
  </data>
  <data name="typeIOUPENALTYSETUPD_Core" xml:space="preserve">
    <value>更改借貸天數及息率</value>
  </data>
  <data name="typeOPERATECOMPCREDITDTL_Core" xml:space="preserve">
    <value>營運公司保證金記錄</value>
  </data>
  <data name="typePOPUPUPLOADFILE_Core" xml:space="preserve">
    <value>上傳文件</value>
  </data>
  <data name="typeREMOTEOPERATIONLST_Core" xml:space="preserve">
    <value>遙距指令</value>
  </data>
  <data name="typeREPORTSUMMARY_Core" xml:space="preserve">
    <value>報表</value>
  </data>
  <data name="typeSETTLEINSTANT_Core" xml:space="preserve">
    <value>即出佣金</value>
  </data>
  <data name="typeSETTLELOCATIONPERIODDTL_Core" xml:space="preserve">
    <value>出糧批核週期</value>
  </data>
  <data name="typeSETTLEREMARKDTL_Core" xml:space="preserve">
    <value>出糧備註</value>
  </data>
  <data name="typeSPECIALMARKERDTL_F_Core" xml:space="preserve">
    <value>海外貸款記錄</value>
  </data>
  <data name="typeSPECIALMARKERDTL_Y_Core" xml:space="preserve">
    <value>營運貸款記錄</value>
  </data>
  <data name="typeSPECIALMARKERRETURN_F_Core" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="typeCOUNTERROLLOUTSIDE_Core" xml:space="preserve">
    <value>離場</value>
  </data>
  <data name="typeMARKERRETURNDTL_C_Core" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="typePLACE_IOU_Core" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="typeROLLINGEDITREFNO_Core" xml:space="preserve">
    <value>聯絡記錄</value>
  </data>
  <data name="typeSETTLEITEMSETOTHERDTL_Core" xml:space="preserve">
    <value>月結其他設定記錄</value>
  </data>
  <data name="typeSPECIALMARKERRETURN_Y_Core" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="typeOPERATECOMPDTL_Core" xml:space="preserve">
    <value>營運公司記錄</value>
  </data>
  <data name="typeOPERATECOMPSHAREDTL_Core" xml:space="preserve">
    <value>營運公司股東記錄</value>
  </data>
  <data name="txtCheckUserActionMode" xml:space="preserve">
    <value>認證方法</value>
  </data>
  <data name="typeBOUNDSGIFTRPT_ReportGrp" xml:space="preserve">
    <value>送禮報表</value>
  </data>
  <data name="txtOperateCompWLReport" xml:space="preserve">
    <value>營運公司上/下數報表</value>
  </data>
  <data name="txtPlsInputRoleCode" xml:space="preserve">
    <value>請輸入權限編碼</value>
  </data>
  <data name="txtPlsInputRoleName" xml:space="preserve">
    <value>請輸入權限名稱</value>
  </data>
  <data name="txtRoleCode" xml:space="preserve">
    <value>權限編號</value>
  </data>
  <data name="txtRoleName" xml:space="preserve">
    <value>權限名稱</value>
  </data>
  <data name="typeBOUNDSGIFTRPT_Core" xml:space="preserve">
    <value>送禮報表</value>
  </data>
  <data name="typeIVR_Core" xml:space="preserve">
    <value>IVR</value>
  </data>
  <data name="typePLACE_REMARK_Core" xml:space="preserve">
    <value>場面備註</value>
  </data>
  <data name="typePLACE_SHIFTCUT_Core" xml:space="preserve">
    <value>場面截更</value>
  </data>
  <data name="typeROLEPROGCLONE_Core" xml:space="preserve">
    <value>權限複製</value>
  </data>
  <data name="txtOperateCustWLReport" xml:space="preserve">
    <value>營運客人上/下數報表</value>
  </data>
  <data name="btnChgComp" xml:space="preserve">
    <value>轉場</value>
  </data>
  <data name="txtCompany" xml:space="preserve">
    <value>公司</value>
  </data>
  <data name="txtMsgCannotSave" xml:space="preserve">
    <value>不能保存</value>
  </data>
  <data name="txtTelbDetail" xml:space="preserve">
    <value>電投</value>
  </data>
  <data name="btnRegister" xml:space="preserve">
    <value>系統登錄</value>
  </data>
  <data name="wRSDate" xml:space="preserve">
    <value>入數日期</value>
  </data>
  <data name="typeOPERATETRANSMSLST_Core" xml:space="preserve">
    <value>營運每日訊息表</value>
  </data>
  <data name="txtIncludeCompany" xml:space="preserve">
    <value>資料包括</value>
  </data>
  <data name="txtShowCompWinLoss" xml:space="preserve">
    <value>顯示公司上/下數</value>
  </data>
  <data name="typeOPERATERPT_ReportGrp" xml:space="preserve">
    <value>營運報表</value>
  </data>
  <data name="typeROPERATECOMPWLRPT_Report" xml:space="preserve">
    <value>營運公司上/下數報表</value>
  </data>
  <data name="typeROPERATECUSTWLRPT_Report" xml:space="preserve">
    <value>營運客人上/下數報表</value>
  </data>
  <data name="typeTELBONETIME_Core" xml:space="preserve">
    <value>一次性買碼確定</value>
  </data>
  <data name="txtBuyChip10k" xml:space="preserve">
    <value>買碼(萬)</value>
  </data>
  <data name="global_txtSeat" xml:space="preserve">
    <value>座位</value>
  </data>
  <data name="txtLate" xml:space="preserve">
    <value>逾期還款</value>
  </data>
  <data name="txtChangeSolution" xml:space="preserve">
    <value>方案不相符</value>
  </data>
  <data name="txtFailMeeting" xml:space="preserve">
    <value>約見不成功</value>
  </data>
  <data name="txtCommRtn" xml:space="preserve">
    <value>佣金回數</value>
  </data>
  <data name="txtCurrRateRemark" xml:space="preserve">
    <value>換率為匯至港幣換率</value>
  </data>
  <data name="txtDebuctMthInt" xml:space="preserve">
    <value>扣減月息</value>
  </data>
  <data name="txtDebuctDLCapital" xml:space="preserve">
    <value>扣減下線股本</value>
  </data>
  <data name="typeFOREIGNTOURLST_Core" xml:space="preserve">
    <value>海外團管理</value>
  </data>
  <data name="txtForeignCustExtID" xml:space="preserve">
    <value>客人帳號</value>
  </data>
  <data name="txtForeignStartDate" xml:space="preserve">
    <value>起程日期</value>
  </data>
  <data name="txtForeignTourDtl" xml:space="preserve">
    <value>海外團名單記錄</value>
  </data>
  <data name="txtForeignTourLst" xml:space="preserve">
    <value>海外團列表</value>
  </data>
  <data name="txtForeignTourNameLstTitle" xml:space="preserve">
    <value>海外團名單列表</value>
  </data>
  <data name="txtForeignTourRecord" xml:space="preserve">
    <value>海外團記錄</value>
  </data>
  <data name="txtGameSiteName" xml:space="preserve">
    <value>賭場名稱</value>
  </data>
  <data name="txtTourType" xml:space="preserve">
    <value>團種類</value>
  </data>
  <data name="typeFOREIGNRPT_ReportGrp" xml:space="preserve">
    <value>海外報表</value>
  </data>
  <data name="typeRFOREIGNCOMPWLRPT_REPORT" xml:space="preserve">
    <value>海外公司上/下數報表</value>
  </data>
  <data name="typeRFOREIGNCUSTWLRPT_REPORT" xml:space="preserve">
    <value>海外客人上/下數報表</value>
  </data>
  <data name="txtBonusPoints" xml:space="preserve">
    <value>贈送積分(萬)</value>
  </data>
  <data name="wRolling_100M" xml:space="preserve">
    <value>全線轉碼數(億)</value>
  </data>
  <data name="typeBONUSPOINTSLST_Core" xml:space="preserve">
    <value>贈送積分管理</value>
  </data>
  <data name="wExpireMth" xml:space="preserve">
    <value>過期月數</value>
  </data>
  <data name="typeFOREIGNGAMESITELST_Core" xml:space="preserve">
    <value>海外賭場管理</value>
  </data>
  <data name="txtForeignGameSiteTitle" xml:space="preserve">
    <value>海外賭場列表</value>
  </data>
  <data name="txtForeignGameSiteName" xml:space="preserve">
    <value>海外賭場</value>
  </data>
  <data name="wCreateDate" xml:space="preserve">
    <value>建立日期</value>
  </data>
  <data name="global_msgDelFail" xml:space="preserve">
    <value>刪除失敗</value>
  </data>
  <data name="txtMsgInfoRecExisted" xml:space="preserve">
    <value>檔案已存在</value>
  </data>
  <data name="txtForeignCommRateCash_S" xml:space="preserve">
    <value>現/股佣金(%)</value>
  </data>
  <data name="txtForeignCommRateIOU_S" xml:space="preserve">
    <value>M佣金(%)</value>
  </data>
  <data name="txtForeignDiscountRebateRate" xml:space="preserve">
    <value>折扣回贈(%)</value>
  </data>
  <data name="txtForeignDrinkRateCash_S" xml:space="preserve">
    <value>現/股積分(%)</value>
  </data>
  <data name="txtForeignDrinkRateIOU_S" xml:space="preserve">
    <value>M積分(%)</value>
  </data>
  <data name="txtForeignExtraCommRate" xml:space="preserve">
    <value>額外佣金(%)</value>
  </data>
  <data name="txtForeignExtraCondCreditDay" xml:space="preserve">
    <value>還款天數</value>
  </data>
  <data name="txtForeignExtraDiscountRebateRate" xml:space="preserve">
    <value>還款回贈(%)</value>
  </data>
  <data name="txtForeignExtraRollTime" xml:space="preserve">
    <value>轉碼倍數</value>
  </data>
  <data name="txtGameSiteCommissionTitle" xml:space="preserve">
    <value>海外佣金設定列表</value>
  </data>
  <data name="txtGameType" xml:space="preserve">
    <value>玩法種類</value>
  </data>
  <data name="wCurrRateProduct" xml:space="preserve">
    <value>兌換率(乘)</value>
  </data>
  <data name="txtForeignExtraCondLoss_tenk" xml:space="preserve">
    <value>實際下數(回贈) (萬)</value>
  </data>
  <data name="txtForeignTotalLoss_tenk" xml:space="preserve">
    <value>實際下數 (萬)</value>
  </data>
  <data name="wCurrRateDivide" xml:space="preserve">
    <value>兌換率(除)</value>
  </data>
  <data name="typeFOREIGNGAMESITE_Core" xml:space="preserve">
    <value>海外賭場記錄</value>
  </data>
  <data name="typeFOREIGNGAMESITEDTL_Core" xml:space="preserve">
    <value>海外佣金設定記錄</value>
  </data>
  <data name="action_VIEW_type" xml:space="preserve">
    <value>檢視</value>
  </data>
  <data name="global_txtCopy" xml:space="preserve">
    <value>複製</value>
  </data>
  <data name="txtForeignCommRateCash" xml:space="preserve">
    <value>現/股佣金(%)</value>
  </data>
  <data name="txtForeignCommRateIOU" xml:space="preserve">
    <value>M佣金(%)</value>
  </data>
  <data name="txtForeignDrinkRateCash" xml:space="preserve">
    <value>現/股積分(%)</value>
  </data>
  <data name="txtForeignDrinkRateIOU" xml:space="preserve">
    <value>M積分(%)</value>
  </data>
  <data name="txtForeignExtraCondLoss" xml:space="preserve">
    <value>實際下數(回贈)</value>
  </data>
  <data name="txtForeignExtraTitle" xml:space="preserve">
    <value>額外條件</value>
  </data>
  <data name="txtForeignGameValue" xml:space="preserve">
    <value>出碼/轉碼</value>
  </data>
  <data name="txtForeignTotalLoss" xml:space="preserve">
    <value>實際下數</value>
  </data>
  <data name="txtForeignGameValue_tenk" xml:space="preserve">
    <value>出碼/轉碼 (萬)</value>
  </data>
  <data name="typeBONUSPOINTSWORKLST_Core" xml:space="preserve">
    <value>贈送積分批核</value>
  </data>
  <data name="BonusPointStatusA" xml:space="preserve">
    <value>已批</value>
  </data>
  <data name="BonusPointStatusN" xml:space="preserve">
    <value>待批</value>
  </data>
  <data name="btnExport" xml:space="preserve">
    <value>匯出</value>
  </data>
  <data name="btnGenBonusPoints" xml:space="preserve">
    <value>生成贈送積分</value>
  </data>
  <data name="txtApprove" xml:space="preserve">
    <value>批核</value>
  </data>
  <data name="txtApprovePerson" xml:space="preserve">
    <value>批核人</value>
  </data>
  <data name="txtBonusPointsRealReceive" xml:space="preserve">
    <value>實取積分(萬)</value>
  </data>
  <data name="txtBonusPointsReceive" xml:space="preserve">
    <value>獲取積分(萬)</value>
  </data>
  <data name="txtBonusPointsSubReceive" xml:space="preserve">
    <value>下線獲取積分(萬)</value>
  </data>
  <data name="txtUpdateStatus" xml:space="preserve">
    <value>更改狀態</value>
  </data>
  <data name="wSelfRolling_100M" xml:space="preserve">
    <value>個人轉碼數(億)</value>
  </data>
  <data name="BonusPointStatusR" xml:space="preserve">
    <value>駁回</value>
  </data>
  <data name="btnApprove" xml:space="preserve">
    <value>確認</value>
  </data>
  <data name="typeTELBAPPROVALDTL_Core" xml:space="preserve">
    <value>電投確定</value>
  </data>
  <data name="global_btnReject" xml:space="preserve">
    <value>不批準</value>
  </data>
  <data name="txtTelbReservationData" xml:space="preserve">
    <value>預約資料</value>
  </data>
  <data name="txtTelbReservationDateTime" xml:space="preserve">
    <value>預約時間</value>
  </data>
  <data name="txtApproveData" xml:space="preserve">
    <value>批准資料</value>
  </data>
  <data name="txtCheckInData" xml:space="preserve">
    <value>在場資料</value>
  </data>
  <data name="txtTelbCName" xml:space="preserve">
    <value>客人姓名</value>
  </data>
  <data name="wExtNo" xml:space="preserve">
    <value>內線號碼</value>
  </data>
  <data name="wFunctionCd" xml:space="preserve">
    <value>權限號碼</value>
  </data>
  <data name="txtLoginExit" xml:space="preserve">
    <value>登出</value>
  </data>
  <data name="txtProfile" xml:space="preserve">
    <value>我的賬戶</value>
  </data>
  <data name="wOldPwd" xml:space="preserve">
    <value>舊密碼</value>
  </data>
  <data name="global_msgErrCustAlreadyExit" xml:space="preserve">
    <value>客人已離場，不能買碼</value>
  </data>
  <data name="global_msgAskSelectRolling" xml:space="preserve">
    <value>是否選取B數管理</value>
  </data>
  <data name="global_msgInfoManualTelbFix" xml:space="preserve">
    <value>是否已自行解凍結存款單,還借貸單及B數單</value>
  </data>
  <data name="global_msgInfoPrinterSettingNotFound" xml:space="preserve">
    <value>找不到相關的打印機設定</value>
  </data>
  <data name="msgInfoRecUpdated" xml:space="preserve">
    <value>記錄已更改</value>
  </data>
  <data name="typeBONUSPOINTSLOGDTL_Core" xml:space="preserve">
    <value>贈送積分管理</value>
  </data>
  <data name="typeROLEFUNCTIONITEM_Core" xml:space="preserve">
    <value>權限記錄</value>
  </data>
  <data name="txtAddRoleName" xml:space="preserve">
    <value>增加角色名稱</value>
  </data>
  <data name="txtSelectedRoleName" xml:space="preserve">
    <value>已選角色列表</value>
  </data>
  <data name="txtPwdMatchError" xml:space="preserve">
    <value>舊密碼不對</value>
  </data>
  <data name="global_msgInfoNorecord" xml:space="preserve">
    <value>沒有符合的資料</value>
  </data>
  <data name="global_txtTable" xml:space="preserve">
    <value>枱</value>
  </data>
  <data name="txtCopyRoleFunction" xml:space="preserve">
    <value>複製權限</value>
  </data>
  <data name="global_txtAskConfirmCloneRole" xml:space="preserve">
    <value>注意，此複製將會從角色{0}複製所有權限到角色{1}</value>
  </data>
  <data name="typeBONUSPOINTSAPPROVE_Core" xml:space="preserve">
    <value>贈送積分批核</value>
  </data>
  <data name="txtApproveStatus" xml:space="preserve">
    <value>批核狀態</value>
  </data>
  <data name="txtNotYetSend" xml:space="preserve">
    <value>未發送</value>
  </data>
  <data name="txtNumberOfRecord" xml:space="preserve">
    <value>記錄總數：</value>
  </data>
  <data name="typeROLEACTIONITEM_Core" xml:space="preserve">
    <value>權限動作記錄</value>
  </data>
  <data name="wActionType" xml:space="preserve">
    <value>動作號碼</value>
  </data>
  <data name="wActionTypeTitle" xml:space="preserve">
    <value>動作</value>
  </data>
  <data name="global_msgErrMissingOverdueDay" xml:space="preserve">
    <value>必須填上過期日數</value>
  </data>
  <data name="global_txtStartDate" xml:space="preserve">
    <value>開始日期</value>
  </data>
  <data name="txtOnlyShowSelected" xml:space="preserve">
    <value>僅顯示已選</value>
  </data>
  <data name="txtOtherCodeIn" xml:space="preserve">
    <value>其他戶口</value>
  </data>
  <data name="wChkAuthStaffCard" xml:space="preserve">
    <value>檢視授權人</value>
  </data>
  <data name="wChkIVR" xml:space="preserve">
    <value>檢視IVR</value>
  </data>
  <data name="wChkStaffCard" xml:space="preserve">
    <value>檢視經手人</value>
  </data>
  <data name="txtDocument" xml:space="preserve">
    <value>文件</value>
  </data>
  <data name="txtIncludeActionType" xml:space="preserve">
    <value>行動包含</value>
  </data>
  <data name="txtRoleRoot" xml:space="preserve">
    <value>權限目錄</value>
  </data>
  <data name="txtTotalWinLoss" xml:space="preserve">
    <value>總輸贏</value>
  </data>
  <data name="txtCreditControlAssess" xml:space="preserve">
    <value>信貸監控-評估及意見</value>
  </data>
  <data name="txtAgentAssess" xml:space="preserve">
    <value>評估及意見</value>
  </data>
  <data name="txtAgentFormat" xml:space="preserve">
    <value>{0}戶口號為：{1}</value>
  </data>
  <data name="type_ccAppStatus_NONE" xml:space="preserve">
    <value>未安排</value>
  </data>
  <data name="type_ccAppStatus_SUGGEST" xml:space="preserve">
    <value>建議</value>
  </data>
  <data name="type_ccAppStatus_INPROGRESS" xml:space="preserve">
    <value>安排中</value>
  </data>
  <data name="type_ccAppStatus_FAIL" xml:space="preserve">
    <value>不成功</value>
  </data>
  <data name="type_ccAppStatus_SUCCESS" xml:space="preserve">
    <value>已安排</value>
  </data>
  <data name="wAppointmentStatus" xml:space="preserve">
    <value>約見狀態</value>
  </data>
  <data name="wDelayDays" xml:space="preserve">
    <value>延期天數</value>
  </data>
  <data name="global_txtMTypeIOU" xml:space="preserve">
    <value>一般</value>
  </data>
  <data name="txtCapitalMType" xml:space="preserve">
    <value>借貸類型</value>
  </data>
  <data name="txtSuggestStopM" xml:space="preserve">
    <value>建議停M</value>
  </data>
  <data name="txtInterestProblem" xml:space="preserve">
    <value>利息問題</value>
  </data>
  <data name="txtMthIntreLate" xml:space="preserve">
    <value>月息綑綁</value>
  </data>
  <data name="action_UPDATEPOINT_type" xml:space="preserve">
    <value>保存坐標</value>
  </data>
  <data name="typeAGENTRELATION_Core" xml:space="preserve">
    <value>相關戶口</value>
  </data>
  <data name="typeAGENTREMARK_Core" xml:space="preserve">
    <value>戶口備註記錄</value>
  </data>
  <data name="typeCREDITCONTROL_Core" xml:space="preserve">
    <value>借貸追蹤</value>
  </data>
  <data name="typeLASTESTWINLOSS_Core" xml:space="preserve">
    <value>最近輸贏數</value>
  </data>
  <data name="typePRINTOUTBASE_Core" xml:space="preserve">
    <value>存卡/借貸單 列印座標設定</value>
  </data>
  <data name="typeROLLINGAMT_Core" xml:space="preserve">
    <value>轉碼概況</value>
  </data>
  <data name="txtAgentSpecialLabel" xml:space="preserve">
    <value>特別設定</value>
  </data>
  <data name="typeBPLAY_SETTLE_Core" xml:space="preserve">
    <value>B數結算</value>
  </data>
  <data name="action_SHIFTCUT_type" xml:space="preserve">
    <value>截更</value>
  </data>
  <data name="global_txtTelB" xml:space="preserve">
    <value>電投</value>
  </data>
  <data name="global_txtContinue" xml:space="preserve">
    <value>續場</value>
  </data>
  <data name="txtBasicInfo" xml:space="preserve">
    <value>基本資料</value>
  </data>
  <data name="msgNotAllowToSelectBoth" xml:space="preserve">
    <value>不能同時選取</value>
  </data>
  <data name="global_msgInfoExportColumnsZero" xml:space="preserve">
    <value>匯出的列數量為0或用了Template取不到列的值.</value>
  </data>
  <data name="typeBPlay_Exchange_Core" xml:space="preserve">
    <value>B數交易</value>
  </data>
  <data name="typeEXPTRANOTHERDTL_Core" xml:space="preserve">
    <value>欠前消費記錄</value>
  </data>
  <data name="txtRelatedRefNo" xml:space="preserve">
    <value>相關單號</value>
  </data>
  <data name="txtMthEndExpense" xml:space="preserve">
    <value>應付金額: </value>
  </data>
  <data name="txtMthEndForeignShare" xml:space="preserve">
    <value>積分結餘: </value>
  </data>
  <data name="txtMthEndInstantDtl" xml:space="preserve">
    <value>即出/月結明細</value>
  </data>
  <data name="txtMthEndNonShare" xml:space="preserve">
    <value>永利積分結餘: </value>
  </data>
  <data name="txtSharePoint" xml:space="preserve">
    <value>積分</value>
  </data>
  <data name="txtNonSharePoint" xml:space="preserve">
    <value>永利積分</value>
  </data>
  <data name="txtMthEndRptDetail" xml:space="preserve">
    <value>列印出糧下線細數表</value>
  </data>
  <data name="txtMthEndRptDetail_TryRun" xml:space="preserve">
    <value>列印預視出糧下線細數表</value>
  </data>
  <data name="txtMthEndShare" xml:space="preserve">
    <value>共通積分結餘: </value>
  </data>
  <data name="msgNotAllowToUseThisFunction" xml:space="preserve">
    <value>此場不能用有關能力</value>
  </data>
  <data name="msgInfoInputMissing" xml:space="preserve">
    <value>仍未輸入所有資料!</value>
  </data>
  <data name="global_txtCard" xml:space="preserve">
    <value>卡</value>
  </data>
  <data name="typeCREDITCONTROLLST_CONTACT_Core" xml:space="preserve">
    <value>新增聯絡</value>
  </data>
  <data name="typeCREDITCONTROLLST_ASSESS_Core" xml:space="preserve">
    <value>新增評估及意見</value>
  </data>
  <data name="typeCREDITCONTROL_ASSESS_Core" xml:space="preserve">
    <value>信貸監控-評估及意見</value>
  </data>
  <data name="global_txtRemarkForFunc" xml:space="preserve">
    <value>相關操作</value>
  </data>
  <data name="txtIdentityAndLevel" xml:space="preserve">
    <value>身份 / 級別</value>
  </data>
  <data name="txtShortFormAgent" xml:space="preserve">
    <value>代</value>
  </data>
  <data name="txtShortFormPlayer" xml:space="preserve">
    <value>玩</value>
  </data>
  <data name="txtMsgInvalidLangInput" xml:space="preserve">
    <value>不能為中文</value>
  </data>
  <data name="global_txtCannotAchieve" xml:space="preserve">
    <value>不到</value>
  </data>
  <data name="global_txtDetect" xml:space="preserve">
    <value>偵測</value>
  </data>
  <data name="typeAUTHORSOURCE_Core" xml:space="preserve">
    <value>歸屬地管理</value>
  </data>
  <data name="txtMenuList" xml:space="preserve">
    <value>二級菜單</value>
  </data>
  <data name="txtRootList" xml:space="preserve">
    <value>一級菜單</value>
  </data>
  <data name="txtSelectedMenu" xml:space="preserve">
    <value>選中菜單</value>
  </data>
  <data name="wRollTranStatus" xml:space="preserve">
    <value>帳房狀況</value>
  </data>
  <data name="txtSettleAtMacau" xml:space="preserve">
    <value>澳門結算</value>
  </data>
  <data name="global_txtLineGrp" xml:space="preserve">
    <value>組別</value>
  </data>
  <data name="global_txtOutstanding" xml:space="preserve">
    <value>未歸還額</value>
  </data>
  <data name="txtAccAmount10K" xml:space="preserve">
    <value>累計數(萬)</value>
  </data>
  <data name="txtAgent" xml:space="preserve">
    <value>會員賬號</value>
  </data>
  <data name="txtAgentCName" xml:space="preserve">
    <value>戶口名稱</value>
  </data>
  <data name="txtDueDate" xml:space="preserve">
    <value>到期日</value>
  </data>
  <data name="txtMarkTime" xml:space="preserve">
    <value>貸款時間</value>
  </data>
  <data name="txtOutstandingAmt" xml:space="preserve">
    <value>尚欠金額</value>
  </data>
  <data name="txtRptPrintLocation" xml:space="preserve">
    <value>列印地點</value>
  </data>
  <data name="txtTotSetAmt10K" xml:space="preserve">
    <value>歸還額(萬)</value>
  </data>
  <data name="txtUse10KBased" xml:space="preserve">
    <value>銀碼以(萬)為單位</value>
  </data>
  <data name="txtAddTime" xml:space="preserve">
    <value>新增時間</value>
  </data>
  <data name="txtBorrowerAmt" xml:space="preserve">
    <value>貸款金額</value>
  </data>
  <data name="txtBorrowerDate" xml:space="preserve">
    <value>貸款日期</value>
  </data>
  <data name="txtReturnDate" xml:space="preserve">
    <value>還款日期</value>
  </data>
  <data name="txtTotSetAmt" xml:space="preserve">
    <value>還款金額</value>
  </data>
  <data name="txtTypeGrp" xml:space="preserve">
    <value>類別(團)</value>
  </data>
  <data name="txtUplvlAgent" xml:space="preserve">
    <value>擔保戶口</value>
  </data>
  <data name="wRptBorrower" xml:space="preserve">
    <value>貸款人</value>
  </data>
  <data name="txtSubTotal_Agent" xml:space="preserve">
    <value>代理總計</value>
  </data>
  <data name="txtSubTotal_Card" xml:space="preserve">
    <value>卡類總計</value>
  </data>
  <data name="txtSubTotal_Day" xml:space="preserve">
    <value>日總計</value>
  </data>
  <data name="wCardType" xml:space="preserve">
    <value>卡類</value>
  </data>
  <data name="wTotalAmt10k" xml:space="preserve">
    <value>總計(萬)</value>
  </data>
  <data name="global_txtAgentCode" xml:space="preserve">
    <value>代理號碼</value>
  </data>
  <data name="txtChinsesName" xml:space="preserve">
    <value>中文名稱</value>
  </data>
  <data name="txtDailyRolling_10k" xml:space="preserve">
    <value>日轉碼(萬)</value>
  </data>
  <data name="txtDepositeDate" xml:space="preserve">
    <value>存款日期</value>
  </data>
  <data name="txtIOUNo" xml:space="preserve">
    <value>借貸單No</value>
  </data>
  <data name="txtMember" xml:space="preserve">
    <value>會員</value>
  </data>
  <data name="txtMonthlyRolling_10k" xml:space="preserve">
    <value>月轉碼(萬)</value>
  </data>
  <data name="txtMonthlyTranDate" xml:space="preserve">
    <value>每月過數日期</value>
  </data>
  <data name="txtRefNo" xml:space="preserve">
    <value>存單編號</value>
  </data>
  <data name="txtRptIOUAgentCode" xml:space="preserve">
    <value>借貸單代理號碼</value>
  </data>
  <data name="txtRptIOUAgentName" xml:space="preserve">
    <value>借貸單代理名稱</value>
  </data>
  <data name="txtTotalDeposite10k" xml:space="preserve">
    <value>總存碼(萬)</value>
  </data>
  <data name="wCIOURoll" xml:space="preserve">
    <value>公司IOU(萬)</value>
  </data>
  <data name="btnWriteUserID" xml:space="preserve">
    <value>寫入員工號碼</value>
  </data>
  <data name="txtHasPeriodUpdate" xml:space="preserve">
    <value>未更新週期</value>
  </data>
  <data name="txtNoRolling" xml:space="preserve">
    <value>沒有轉碼數</value>
  </data>
  <data name="txtProcessFailed" xml:space="preserve">
    <value>執行失敗</value>
  </data>
  <data name="txtFinished" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="txtMonetaryUnit" xml:space="preserve">
    <value>金額單位</value>
  </data>
  <data name="txtMsgOverSpentExpRem" xml:space="preserve">
    <value>*超額消費會在月息扣除</value>
  </data>
  <data name="typerMthEndExpenseTran_Core" xml:space="preserve">
    <value>戶口消費總結</value>
  </data>
  <data name="wCageBalance" xml:space="preserve">
    <value>廳結存</value>
  </data>
  <data name="global_txtUpdateRollsClient" xml:space="preserve">
    <value>系統更新</value>
  </data>
  <data name="global_txtAllowInputActionCode" xml:space="preserve">
    <value>允許輸入經手人</value>
  </data>
  <data name="txtRptMultiLang" xml:space="preserve">
    <value>報表語言</value>
  </data>
  <data name="global_msgStaffCardCheckSuccess" xml:space="preserve">
    <value>成功認證</value>
  </data>
  <data name="global_txtSuccess" xml:space="preserve">
    <value>成功</value>
  </data>
  <data name="typeCHANGECOMP_Core" xml:space="preserve">
    <value>轉場</value>
  </data>
  <data name="txtActionCodeChecking_Card" xml:space="preserve">
    <value>員工卡</value>
  </data>
  <data name="txtActionCodeChecking_Input" xml:space="preserve">
    <value>輸入經手人</value>
  </data>
  <data name="txtActionCodeChecking_RoleSettings" xml:space="preserve">
    <value>跟隨權限組別設定</value>
  </data>
  <data name="txtPersonalActionCodeSettings" xml:space="preserve">
    <value>經手人設定</value>
  </data>
  <data name="txtAgentCardLst" xml:space="preserve">
    <value>會員卡管理</value>
  </data>
  <data name="txtHolderCName" xml:space="preserve">
    <value>持卡人姓名</value>
  </data>
  <data name="txtCountryCode" xml:space="preserve">
    <value>國家碼</value>
  </data>
  <data name="txtCreditType" xml:space="preserve">
    <value>信用額方式</value>
  </data>
  <data name="typeAGENTCARDLST_Core" xml:space="preserve">
    <value>會員卡管理</value>
  </data>
  <data name="txtBdgroupStaff" xml:space="preserve">
    <value>業務發展部跟進同事</value>
  </data>
  <data name="txtMainStaff" xml:space="preserve">
    <value>主要跟進同事</value>
  </data>
  <data name="txtMarketStaff" xml:space="preserve">
    <value>市場部跟進同事</value>
  </data>
  <data name="txtOverseaStaff" xml:space="preserve">
    <value>海外部跟進同事</value>
  </data>
  <data name="txtRptDeposit" xml:space="preserve">
    <value>存(萬)</value>
  </data>
  <data name="txtRptWithdraw" xml:space="preserve">
    <value>提(萬)</value>
  </data>
  <data name="global_msgUpdateCountMessage" xml:space="preserve">
    <value>資訊更新</value>
  </data>
  <data name="global_txtAgentRollTran" xml:space="preserve">
    <value>潛質</value>
  </data>
  <data name="global_txtCounterRolling" xml:space="preserve">
    <value>櫃枱轉碼</value>
  </data>
  <data name="global_txtCustInOut" xml:space="preserve">
    <value>客人進/出場</value>
  </data>
  <data name="global_txtCustInOutDtl" xml:space="preserve">
    <value>客人進/出場</value>
  </data>
  <data name="global_txtCustTelB" xml:space="preserve">
    <value>電投</value>
  </data>
  <data name="global_txtFloorPlan" xml:space="preserve">
    <value>場面平面圖</value>
  </data>
  <data name="global_txtOperateTran" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="global_txtRollTran" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="global_txtTableTran" xml:space="preserve">
    <value>預約枱</value>
  </data>
  <data name="gobal_txtRemoteOperation" xml:space="preserve">
    <value>遙距指令</value>
  </data>
  <data name="txtRolltranDtl" xml:space="preserve">
    <value>轉碼明細</value>
  </data>
  <data name="global_txtPlace" xml:space="preserve">
    <value>場面</value>
  </data>
  <data name="txtAgentCardDtl" xml:space="preserve">
    <value>會員卡記錄</value>
  </data>
  <data name="wCardNo" xml:space="preserve">
    <value>卡號</value>
  </data>
  <data name="wAgentCardType" xml:space="preserve">
    <value>分類</value>
  </data>
  <data name="wAgentCardCreditTypeNone" xml:space="preserve">
    <value>沒有</value>
  </data>
  <data name="wAgentCardCreditTypeShare" xml:space="preserve">
    <value>共用</value>
  </data>
  <data name="wAgentCardCreditTypeSole" xml:space="preserve">
    <value>獨立</value>
  </data>
  <data name="wRecMembCard" xml:space="preserve">
    <value>已領取此咭</value>
  </data>
  <data name="wShowIOU_DnLv" xml:space="preserve">
    <value>IOU(下線)</value>
  </data>
  <data name="wShowRoll_DnLv" xml:space="preserve">
    <value>轉碼(下線)</value>
  </data>
  <data name="wShowDrink" xml:space="preserve">
    <value>食額</value>
  </data>
  <data name="global_msgPlaceShiftCutMessage" xml:space="preserve">
    <value>場面截更更新</value>
  </data>
  <data name="global_msgShiftCutMessage" xml:space="preserve">
    <value>截更更新</value>
  </data>
  <data name="txtDesc" xml:space="preserve">
    <value>描述</value>
  </data>
  <data name="txtExtName" xml:space="preserve">
    <value>格式</value>
  </data>
  <data name="txtOptionComp" xml:space="preserve">
    <value>可選公司</value>
  </data>
  <data name="txtPhotoName" xml:space="preserve">
    <value>圖片名</value>
  </data>
  <data name="typeMonitorPhotoLst_Core" xml:space="preserve">
    <value>帳房櫃檯廣告圖片管理</value>
  </data>
  <data name="txtMonitorPhoto" xml:space="preserve">
    <value>帳房櫃檯廣告圖片</value>
  </data>
  <data name="txtSMSTypeSet" xml:space="preserve">
    <value>訊息設定</value>
  </data>
  <data name="txtApp" xml:space="preserve">
    <value>App</value>
  </data>
  <data name="type_SMS_GRP_ACCOUNT" xml:space="preserve">
    <value>戶口訊息</value>
  </data>
  <data name="type_SMS_GRP_COMMISSION" xml:space="preserve">
    <value>佣金與即出</value>
  </data>
  <data name="type_SMS_GRP_EXPENSE" xml:space="preserve">
    <value>消費與積分</value>
  </data>
  <data name="type_SMS_GRP_IOU" xml:space="preserve">
    <value>信貸訊息</value>
  </data>
  <data name="type_SMS_GRP_OTHER" xml:space="preserve">
    <value>其他</value>
  </data>
  <data name="type_SMS_GRP_ROLLING" xml:space="preserve">
    <value>轉碼及上下數</value>
  </data>
  <data name="type_SMS_GRP_STORE" xml:space="preserve">
    <value>存取與利息</value>
  </data>
  <data name="type_SMS_GRP_TELEBET" xml:space="preserve">
    <value>電投訊息</value>
  </data>
  <data name="type_SMS_GRP_PROMO" xml:space="preserve">
    <value>推廣訊息</value>
  </data>
  <data name="txtSetCredit" xml:space="preserve">
    <value>設定信用額</value>
  </data>
  <data name="typeAGENTCARDCASHTRAN_Core" xml:space="preserve">
    <value>現金充值</value>
  </data>
  <data name="typeAGENTCARDCREDITTRAN_Core" xml:space="preserve">
    <value>會員卡臨時信用額</value>
  </data>
  <data name="global_txtCurrNumberOfCustomer" xml:space="preserve">
    <value>在場人客數</value>
  </data>
  <data name="txtMsgPhotoError" xml:space="preserve">
    <value>圖片還沒有上傳</value>
  </data>
  <data name="txtMsgIncorrectRollCombo" xml:space="preserve">
    <value>轉碼組合不存在</value>
  </data>
  <data name="global_txtPlaceAgent" xml:space="preserve">
    <value>在場代理</value>
  </data>
  <data name="txtStatusForeign" xml:space="preserve">
    <value>海外狀態</value>
  </data>
  <data name="txtStatusSMS" xml:space="preserve">
    <value>短訊狀態</value>
  </data>
  <data name="typeFOREIGNTRANLST_Core" xml:space="preserve">
    <value>海外管理</value>
  </data>
  <data name="txtTotalGameRolling" xml:space="preserve">
    <value>本場總轉碼</value>
  </data>
  <data name="txtTotalForeignGameWinLose" xml:space="preserve">
    <value>本場總上下</value>
  </data>
  <data name="action_SEARCH_ALL_type" xml:space="preserve">
    <value>搜尋所有</value>
  </data>
  <data name="wBindingType" xml:space="preserve">
    <value>綁定類型</value>
  </data>
  <data name="btnNewAssess" xml:space="preserve">
    <value>新增評估</value>
  </data>
  <data name="btnNewContacts" xml:space="preserve">
    <value>新增聯絡</value>
  </data>
  <data name="btnCheckUserID" xml:space="preserve">
    <value>檢查卡員工編號</value>
  </data>
  <data name="global_txtUserID" xml:space="preserve">
    <value>員工編號</value>
  </data>
  <data name="rOutstandingCommission" xml:space="preserve">
    <value>未出糧報表</value>
  </data>
  <data name="typeSETTLEMENTRPT_ReportGrp" xml:space="preserve">
    <value>月結報表</value>
  </data>
  <data name="typeROUTSTANDINGCOMMISSIONRPT_Report" xml:space="preserve">
    <value>未出糧報表</value>
  </data>
  <data name="txtNon_Assess" xml:space="preserve">
    <value>未評估戶口</value>
  </data>
  <data name="txtSummary" xml:space="preserve">
    <value>總結</value>
  </data>
  <data name="txtSearchDeposit" xml:space="preserve">
    <value>搜尋存單</value>
  </data>
  <data name="txtSearchMarker" xml:space="preserve">
    <value>搜尋借貸</value>
  </data>
  <data name="txtErrSearchChipI" xml:space="preserve">
    <value>沒找到存單</value>
  </data>
  <data name="txtErrSearchMarker" xml:space="preserve">
    <value>沒有找到借貸</value>
  </data>
  <data name="txtPenaltyM" xml:space="preserve">
    <value>罰息</value>
  </data>
  <data name="txtBeforeSettleLevelText" xml:space="preserve">
    <value>戶主是其</value>
  </data>
  <data name="txtSettleLevel98Text" xml:space="preserve">
    <value>獎金</value>
  </data>
  <data name="msgRptNeedCustomerName" xml:space="preserve">
    <value>客人必須填寫</value>
  </data>
  <data name="typeTABLETRAN_Core" xml:space="preserve">
    <value>貴賓廳管理</value>
  </data>
  <data name="wTableStatus" xml:space="preserve">
    <value>枱狀態</value>
  </data>
  <data name="wUsagedStatus" xml:space="preserve">
    <value>使用狀態</value>
  </data>
  <data name="txtShowBalance" xml:space="preserve">
    <value>顯示結存</value>
  </data>
  <data name="txtErrorRoomCName" xml:space="preserve">
    <value>房號不能為空！</value>
  </data>
  <data name="txtErrorTableCName" xml:space="preserve">
    <value>枱號不能為空！</value>
  </data>
  <data name="global_txtCapitalTranH" xml:space="preserve">
    <value>凍結存款單</value>
  </data>
  <data name="wOutstandAmountHKD" xml:space="preserve">
    <value>倘欠HKD(萬)</value>
  </data>
  <data name="typeFOREIGNTRANDTL_Core" xml:space="preserve">
    <value>海外記錄</value>
  </data>
  <data name="txtForeignWLDiscountRebateRate" xml:space="preserve">
    <value>下數回贈率</value>
  </data>
  <data name="txtForeignAirTicketRebate" xml:space="preserve">
    <value>機票回贈額</value>
  </data>
  <data name="txtReturnDay" xml:space="preserve">
    <value>還款天期</value>
  </data>
  <data name="txtGetRollingAndWinLoss" xml:space="preserve">
    <value>匯入轉碼及上下數</value>
  </data>
  <data name="txtTotalPoint" xml:space="preserve">
    <value>累積當地積分</value>
  </data>
  <data name="txtForeignTranDtlAllTourNoInfo" xml:space="preserve">
    <value>本團客人狀況</value>
  </data>
  <data name="txtForeignTranDtlCashOutLstTitle" xml:space="preserve">
    <value>海外現金支出列表</value>
  </data>
  <data name="txtForeignTranDtlExpOutLstTitle" xml:space="preserve">
    <value>海外消費列表</value>
  </data>
  <data name="txtForeignPerson" xml:space="preserve">
    <value>個別客戶開單</value>
  </data>
  <data name="txtForeignWholeTour" xml:space="preserve">
    <value>全團客戶開單</value>
  </data>
  <data name="txtForeignSettle" xml:space="preserve">
    <value>海外結算</value>
  </data>
  <data name="msgAskConfirmAddWholeTourOpening" xml:space="preserve">
    <value>此團第一次開場, 是否自動新增 ''全團開場'' 記錄?</value>
  </data>
  <data name="msgInfoMissingSite" xml:space="preserve">
    <value>需要揀選場地</value>
  </data>
  <data name="txtForeignGame" xml:space="preserve">
    <value>本單狀況</value>
  </data>
  <data name="global_ConfirmedInterestRateInProgress" xml:space="preserve">
    <value>存款月利息正在確認中, 並且發送訊息, 請於5至10分鐘後回來檢察狀態</value>
  </data>
  <data name="wOverdueExcludeFrozenAmtHKD" xml:space="preserve">
    <value>實際過期數</value>
  </data>
  <data name="global_txtCash_short" xml:space="preserve">
    <value>現</value>
  </data>
  <data name="txt_DAY" xml:space="preserve">
    <value>日數</value>
  </data>
  <data name="txtCutOffDate_Preview" xml:space="preserve">
    <value>截數日期(預視功能)</value>
  </data>
  <data name="txtShowDisable_Preview" xml:space="preserve">
    <value>顯示不收(預視功能)</value>
  </data>
  <data name="txtShowRemainPenalty_Preview" xml:space="preserve">
    <value>顯示罰息未還(預視功能)</value>
  </data>
  <data name="txtNonBPlayGameSite" xml:space="preserve">
    <value>此場地不能新增B數單</value>
  </data>
  <data name="global_txtSecondAuth" xml:space="preserve">
    <value>二次授權</value>
  </data>
  <data name="global_msgConnectTimeOut" xml:space="preserve">
    <value>[連接失敗]-未能成功連接系統</value>
  </data>
  <data name="global_txtInProgress" xml:space="preserve">
    <value>處理中</value>
  </data>
  <data name="global_txtProgressFinished" xml:space="preserve">
    <value>處理完成</value>
  </data>
  <data name="global_msgReconnect" xml:space="preserve">
    <value>重新連線</value>
  </data>
  <data name="txtUploadDate" xml:space="preserve">
    <value>上載日期</value>
  </data>
  <data name="txtUploadID2" xml:space="preserve">
    <value>證件</value>
  </data>
  <data name="txtAgentDoc" xml:space="preserve">
    <value>戶口文件</value>
  </data>
  <data name="typeAGENTDOC_Core" xml:space="preserve">
    <value>戶口文件</value>
  </data>
  <data name="global_txtReOption" xml:space="preserve">
    <value>重新選項</value>
  </data>
  <data name="rRollingDesc" xml:space="preserve">
    <value>各股東線轉碼數</value>
  </data>
  <data name="wCageDailyBal_10k" xml:space="preserve">
    <value>本場日轉碼(萬)</value>
  </data>
  <data name="txtOtherLineGrp" xml:space="preserve">
    <value>外線</value>
  </data>
  <data name="txtOtherMixLineGrp" xml:space="preserve">
    <value>雜線</value>
  </data>
  <data name="txtManila" xml:space="preserve">
    <value>馬尼拉</value>
  </data>
  <data name="txtRollingDate" xml:space="preserve">
    <value>轉碼日期</value>
  </data>
  <data name="typeRROLLINGSHARERPT_Report" xml:space="preserve">
    <value>股東轉碼報表</value>
  </data>
  <data name="txtPrevPhoto" xml:space="preserve">
    <value>上一張</value>
  </data>
  <data name="txtNextPhoto" xml:space="preserve">
    <value>下一張</value>
  </data>
  <data name="msgMissingIOURefNo" xml:space="preserve">
    <value>還未選擇借貸單, 繼續嗎 ?</value>
  </data>
  <data name="global_txtAlreadySent" xml:space="preserve">
    <value>已發出</value>
  </data>
  <data name="global_txtCanPreview" xml:space="preserve">
    <value>可預視</value>
  </data>
  <data name="global_txtPreparing" xml:space="preserve">
    <value>預備中</value>
  </data>
  <data name="global_msgDepositorChanged" xml:space="preserve">
    <value>存款人已更改</value>
  </data>
  <data name="txtCashFlow" xml:space="preserve">
    <value>資金流</value>
  </data>
  <data name="txtLocal" xml:space="preserve">
    <value>本地</value>
  </data>
  <data name="txtOverSea" xml:space="preserve">
    <value>跨區</value>
  </data>
  <data name="txtCurrCodeExchangeRemark" xml:space="preserve">
    <value>貨幣兌換</value>
  </data>
  <data name="txtTransferRemark" xml:space="preserve">
    <value>跨貨幣轉帳</value>
  </data>
  <data name="global_msgInfoRefNoOnlyAlphaNumeric" xml:space="preserve">
    <value>單號只接受英文字母和數目字</value>
  </data>
  <data name="global_msgCompanyNotMatch" xml:space="preserve">
    <value>不能修改其他公司</value>
  </data>
  <data name="wStoreType" xml:space="preserve">
    <value>存款類型</value>
  </data>
  <data name="global_txtAmountInvalid" xml:space="preserve">
    <value>數值不正確</value>
  </data>
  <data name="wTotalWithDraw_ChipB" xml:space="preserve">
    <value>存卡提款額</value>
  </data>
  <data name="wTotalWithDraw_ChipI" xml:space="preserve">
    <value>存單提款額</value>
  </data>
  <data name="global_msgErrFieldCannotBeZero" xml:space="preserve">
    <value>{0}不能爲零</value>
  </data>
  <data name="global_msgInfoFieldInputMissing" xml:space="preserve">
    <value>必需填入{0}</value>
  </data>
  <data name="global_msgInfoFieldSelectMissing" xml:space="preserve">
    <value>必需選取{0}</value>
  </data>
  <data name="msgInfoPlsWaitForChecking" xml:space="preserve">
    <value>請稍候... ...系統正在覆核資料 ...</value>
  </data>
  <data name="txtCashLoanAmt" xml:space="preserve">
    <value>個人借貸額(萬)</value>
  </data>
  <data name="txtMasterCasinoCreditAmt" xml:space="preserve">
    <value>Credit額(萬)</value>
  </data>
  <data name="wCreditAmt_10k" xml:space="preserve">
    <value>批額(萬)</value>
  </data>
  <data name="global_msgMissingFxRate_All" xml:space="preserve">
    <value>找不到此貨幣兌換匯率</value>
  </data>
  <data name="txt_ChipIData" xml:space="preserve">
    <value>存單資料</value>
  </data>
  <data name="txt_ChipBCageBalance" xml:space="preserve">
    <value>存卡各廳結存</value>
  </data>
  <data name="txt_IOUData" xml:space="preserve">
    <value>借貸單資料</value>
  </data>
  <data name="txt_MthInterestData" xml:space="preserve">
    <value>月息單資料</value>
  </data>
  <data name="txt_CapitalData" xml:space="preserve">
    <value>股本資料</value>
  </data>
  <data name="txt_FreezeData" xml:space="preserve">
    <value>凍M資料</value>
  </data>
  <data name="txt_HoldData" xml:space="preserve">
    <value>凍結存款資料</value>
  </data>
  <data name="txtWithDrawAmt_10K" xml:space="preserve">
    <value>提款額(萬)</value>
  </data>
  <data name="txtAllowFreeze" xml:space="preserve">
    <value>下線可凍借貸</value>
  </data>
  <data name="txtTotalFreezeAmt10K" xml:space="preserve">
    <value>凍結總額(萬)</value>
  </data>
  <data name="txtRepaymentType" xml:space="preserve">
    <value>還款類型</value>
  </data>
  <data name="txtStore_Cash10K" xml:space="preserve">
    <value>存C(萬)</value>
  </data>
  <data name="txtStore_Win10K" xml:space="preserve">
    <value>羸錢(萬)</value>
  </data>
  <data name="txtCheckingUpdate" xml:space="preserve">
    <value>檢查更新...</value>
  </data>
  <data name="txtProcessUpdate" xml:space="preserve">
    <value>正在更新...</value>
  </data>
  <data name="txtUpdated" xml:space="preserve">
    <value>已更新</value>
  </data>
  <data name="txtShowAllComm" xml:space="preserve">
    <value>所有正負佣金</value>
  </data>
  <data name="txtShowPositiveComm" xml:space="preserve">
    <value>只包括正佣金</value>
  </data>
  <data name="txtShowNegativeComm" xml:space="preserve">
    <value>只包括負佣金</value>
  </data>
  <data name="typeSETTLETRANCOMPLEXLST_Core" xml:space="preserve">
    <value>綜合出糧管理</value>
  </data>
  <data name="global_txtInput" xml:space="preserve">
    <value>輸入</value>
  </data>
  <data name="global_txtRemoteMachineInput" xml:space="preserve">
    <value>遙距輸入</value>
  </data>
  <data name="global_txtRemoteMachineInputPassword" xml:space="preserve">
    <value>遙距輸入</value>
  </data>
  <data name="txtPlease" xml:space="preserve">
    <value>請</value>
  </data>
  <data name="txtRetry" xml:space="preserve">
    <value>重新嘗試</value>
  </data>
  <data name="txtTimeExceedWaitPeriod" xml:space="preserve">
    <value>超過等候時間</value>
  </data>
  <data name="txtCashType" xml:space="preserve">
    <value>電投出碼類型</value>
  </data>
  <data name="txtTelNotify" xml:space="preserve">
    <value>電話通知</value>
  </data>
  <data name="wTelbBPlayRatio" xml:space="preserve">
    <value>代理B數佔成(%)</value>
  </data>
  <data name="global_msgNoPreview" xml:space="preserve">
    <value>文案沒有預覽功能</value>
  </data>
  <data name="global_PopUpSettleComplexRemark" xml:space="preserve">
    <value>綜合出糧備註</value>
  </data>
  <data name="global_txtNotFound" xml:space="preserve">
    <value>找不到</value>
  </data>
  <data name="global_txtPage" xml:space="preserve">
    <value>頁面</value>
  </data>
  <data name="typeTRANSFERCENTRE_Core" xml:space="preserve">
    <value>綜合理財確認</value>
  </data>
  <data name="wJoinDate" xml:space="preserve">
    <value>加入時間</value>
  </data>
  <data name="global_txtAgentJunket" xml:space="preserve">
    <value>加入記錄</value>
  </data>
  <data name="global_txtAgentJunketSales" xml:space="preserve">
    <value>每月轉碼</value>
  </data>
  <data name="wJunketCName" xml:space="preserve">
    <value>貴賓廳中文名</value>
  </data>
  <data name="wWinLossAmt" xml:space="preserve">
    <value>上下數(萬)</value>
  </data>
  <data name="txtStoreSettle" xml:space="preserve">
    <value>月結存回</value>
  </data>
  <data name="typeOTHERJUNKETLST_Core" xml:space="preserve">
    <value>其他貴賓廳管理</value>
  </data>
  <data name="wJunketCode" xml:space="preserve">
    <value>代號</value>
  </data>
  <data name="wJunket" xml:space="preserve">
    <value>貴賓廳</value>
  </data>
  <data name="typeOTHERJUNKETDTL_Core" xml:space="preserve">
    <value>其他貴賓廳管理</value>
  </data>
  <data name="txtAgentSummaryDetail" xml:space="preserve">
    <value>明細</value>
  </data>
  <data name="wAmountPoint" xml:space="preserve">
    <value>點數(萬)</value>
  </data>
  <data name="btnBPlayApprove" xml:space="preserve">
    <value>B數確認</value>
  </data>
  <data name="txtStoreMethod" xml:space="preserve">
    <value>存回方法</value>
  </data>
  <data name="txtIsStoreOther" xml:space="preserve">
    <value>存指定</value>
  </data>
  <data name="txtStoreLocal" xml:space="preserve">
    <value>存回當地</value>
  </data>
  <data name="txtStoreSettleCard" xml:space="preserve">
    <value>存回即出卡</value>
  </data>
  <data name="typeSettleRemarkComplexDtl_Core" xml:space="preserve">
    <value>綜合出糧備註</value>
  </data>
  <data name="txtAmountCanFreeze" xml:space="preserve">
    <value>可凍結金額(萬)</value>
  </data>
  <data name="txtCashType_Credit" xml:space="preserve">
    <value>批額</value>
  </data>
  <data name="eChipTranBDtl" xml:space="preserve">
    <value>存卡記錄</value>
  </data>
  <data name="typeCHIPTRAN_B_DTL_Core" xml:space="preserve">
    <value>存卡記錄</value>
  </data>
  <data name="typeCHIPTRAN_I_DTL_Core" xml:space="preserve">
    <value>存單記錄</value>
  </data>
  <data name="global_txtChipWin" xml:space="preserve">
    <value>贏錢</value>
  </data>
  <data name="txtPlayer" xml:space="preserve">
    <value>玩家</value>
  </data>
  <data name="typeSettleTranComplexPreview_Core" xml:space="preserve">
    <value>出糧預覽</value>
  </data>
  <data name="wIOUNonOutstandingExpire" xml:space="preserve">
    <value>未過(M)</value>
  </data>
  <data name="wIOUOutstandingExpire" xml:space="preserve">
    <value>已過(M)</value>
  </data>
  <data name="wOperationNonOutstandingExpire" xml:space="preserve">
    <value>未過(營)</value>
  </data>
  <data name="wOperationOutstandingExpire" xml:space="preserve">
    <value>已過(營)</value>
  </data>
  <data name="wForeignNonOutstandingExpire" xml:space="preserve">
    <value>未過(海)</value>
  </data>
  <data name="wForeignOutstandingExpire" xml:space="preserve">
    <value>已過(海)</value>
  </data>
  <data name="wRollSource" xml:space="preserve">
    <value>借貸來源</value>
  </data>
  <data name="global_txtCustomer_SHORT" xml:space="preserve">
    <value>客</value>
  </data>
  <data name="txtAssCurMonCommission" xml:space="preserve">
    <value>調配當月佣金</value>
  </data>
  <data name="txtAssCurMonPoint" xml:space="preserve">
    <value>調配當月積分</value>
  </data>
  <data name="txtAustralia" xml:space="preserve">
    <value>澳洲</value>
  </data>
  <data name="txtAutoAdjust" xml:space="preserve">
    <value>自動判斷</value>
  </data>
  <data name="txtBFExpense" xml:space="preserve">
    <value>前累欠費</value>
  </data>
  <data name="txtBF_Card_Expense" xml:space="preserve">
    <value>前累卡欠費</value>
  </data>
  <data name="txtBFPoint" xml:space="preserve">
    <value>前累積分</value>
  </data>
  <data name="txtMthIntDrink" xml:space="preserve">
    <value>月息積分</value>
  </data>
  <data name="txtCardExpenseInCurMon" xml:space="preserve">
    <value>當月卡消費(內)</value>
  </data>
  <data name="txtCardExpenseOutCurMon" xml:space="preserve">
    <value>當月卡消費(外)</value>
  </data>
  <data name="txtDiffBetCommPoint" xml:space="preserve">
    <value>佣金減去積分結餘</value>
  </data>
  <data name="txtExpenseCurMon" xml:space="preserve">
    <value>當月消費</value>
  </data>
  <data name="txtFreezeRefNo" xml:space="preserve">
    <value>凍結借貸單號</value>
  </data>
  <data name="txtFrom" xml:space="preserve">
    <value>從</value>
  </data>
  <data name="txtKorea" xml:space="preserve">
    <value>韓國</value>
  </data>
  <data name="txtMacau" xml:space="preserve">
    <value>澳門</value>
  </data>
  <data name="txtPhilippines" xml:space="preserve">
    <value>菲律賓</value>
  </data>
  <data name="txtPointCurMon" xml:space="preserve">
    <value>本月積分</value>
  </data>
  <data name="txtPointsStatus" xml:space="preserve">
    <value>積分概況</value>
  </data>
  <data name="txtRelease" xml:space="preserve">
    <value>解除</value>
  </data>
  <data name="txtTotalPointSettle" xml:space="preserve">
    <value>合計現有積分結餘</value>
  </data>
  <data name="txtTransferIn" xml:space="preserve">
    <value>轉入</value>
  </data>
  <data name="txtUnCommon" xml:space="preserve">
    <value>不通用</value>
  </data>
  <data name="txtWithDrawAmt_10K_Store" xml:space="preserve">
    <value>存C提款額(萬)</value>
  </data>
  <data name="txtWithDrawAmt_10K_Win" xml:space="preserve">
    <value>贏錢提款額(萬)</value>
  </data>
  <data name="typeAGENTJUNKETDTL_Core" xml:space="preserve">
    <value>加入記錄管理</value>
  </data>
  <data name="typeAGENTJUNKETLST_Core" xml:space="preserve">
    <value>加入記錄</value>
  </data>
  <data name="typeAGENTJUNKETSALESDTL_Core" xml:space="preserve">
    <value>每月轉碼管理</value>
  </data>
  <data name="typeAGENTJUNKETSALESLST_Core" xml:space="preserve">
    <value>每月轉碼</value>
  </data>
  <data name="txtResetTelbCust_PWD" xml:space="preserve">
    <value>重設客人戶口密碼</value>
  </data>
  <data name="txtResetTelbShadow_PWD" xml:space="preserve">
    <value>重設關注戶口密碼</value>
  </data>
  <data name="btnClose" xml:space="preserve">
    <value>關閉</value>
  </data>
  <data name="msgActCodeChangeRequired" xml:space="preserve">
    <value>你的行動碼已經過期，必須先重設行動碼才能繼續使用。</value>
  </data>
  <data name="txtSettleDelete" xml:space="preserve">
    <value>刪除此結算</value>
  </data>
  <data name="typeAGENTSPECIAL_Core" xml:space="preserve">
    <value>特別設定</value>
  </data>
  <data name="typeBONUSPOINTSDTL_Core" xml:space="preserve">
    <value>贈送積分管理</value>
  </data>
  <data name="typeMONITORPHOTODTL_Core" xml:space="preserve">
    <value>帳房櫃檯廣告圖片管理</value>
  </data>
  <data name="typePROFILE_Core" xml:space="preserve">
    <value>我的賬戶</value>
  </data>
  <data name="txtProcess" xml:space="preserve">
    <value>進行</value>
  </data>
  <data name="txtUpdate" xml:space="preserve">
    <value>更新</value>
  </data>
  <data name="txtWill" xml:space="preserve">
    <value>將</value>
  </data>
  <data name="global_btnApply" xml:space="preserve">
    <value>應用</value>
  </data>
  <data name="txtPenaltyInterest" xml:space="preserve">
    <value>罰息(萬)</value>
  </data>
  <data name="btnImport" xml:space="preserve">
    <value>匯入</value>
  </data>
  <data name="txtCurrency" xml:space="preserve">
    <value>貨幣</value>
  </data>
  <data name="txtSameAgentTransfer" xml:space="preserve">
    <value>同館同戶口不能轉帳</value>
  </data>
  <data name="txtSameCurrCodeTransfer" xml:space="preserve">
    <value>相同貨幣不能轉帳</value>
  </data>
  <data name="global_txtRead" xml:space="preserve">
    <value>讀取</value>
  </data>
  <data name="txtShowInternal" xml:space="preserve">
    <value>顯示內部飛數</value>
  </data>
  <data name="txtCurrentSettleAmt_MthEnd_Inst" xml:space="preserve">
    <value>本月月結/即出扣除</value>
  </data>
  <data name="global_msgInfoSameAgent" xml:space="preserve">
    <value>戶口相同</value>
  </data>
  <data name="typePOPUPSTORECTRANSFERTO_Core" xml:space="preserve">
    <value>內部轉帳</value>
  </data>
  <data name="msgSystemBusy" xml:space="preserve">
    <value>系統繁忙中，請稍後再嘗試。</value>
  </data>
  <data name="msgRequestInProgress" xml:space="preserve">
    <value>該出碼要求已經正在進行中...</value>
  </data>
  <data name="msgDifferentUpdBy" xml:space="preserve">
    <value>經手人已不同，需要原本進行確認的經手人才可繼續。</value>
  </data>
  <data name="txtBFExpenseWithDnAgent" xml:space="preserve">
    <value>欠前消費(包下線)</value>
  </data>
  <data name="wCurExpRemain" xml:space="preserve">
    <value>當月新增欠費</value>
  </data>
  <data name="wTotExpRemain" xml:space="preserve">
    <value>欠費總數</value>
  </data>
  <data name="wBFExpByMth" xml:space="preserve">
    <value>欠費月份</value>
  </data>
  <data name="txtWarningExpense" xml:space="preserve">
    <value>**下線消費欠款必需由上線承擔</value>
  </data>
  <data name="msgInfoAgentHasNoIVRPwd" xml:space="preserve">
    <value>戶口未設定驗証密碼</value>
  </data>
  <data name="typeEXPENDCARDINOROUTSIDE_Core" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="wExpenseDate" xml:space="preserve">
    <value>消費日期</value>
  </data>
  <data name="wAmountActual_CRM" xml:space="preserve">
    <value>總值</value>
  </data>
  <data name="wExpAmount" xml:space="preserve">
    <value>消費額</value>
  </data>
  <data name="txtNotifyAgent_EveryTime" xml:space="preserve">
    <value>每次通知</value>
  </data>
  <data name="txtNotifyAgent_NoNeed" xml:space="preserve">
    <value>不用通知</value>
  </data>
  <data name="txtTelbBPlayRatio_0" xml:space="preserve">
    <value>零佔</value>
  </data>
  <data name="txtTelbBPlayRatio_50" xml:space="preserve">
    <value>半佔</value>
  </data>
  <data name="txtTelbBPlayRatio_100" xml:space="preserve">
    <value>全佔</value>
  </data>
  <data name="msgSCMCustExitYet" xml:space="preserve">
    <value>SCM 客人還未完成離場</value>
  </data>
  <data name="action_VOID_INTEREST_type" xml:space="preserve">
    <value>取消月息</value>
  </data>
  <data name="txtOwner" xml:space="preserve">
    <value>負責人</value>
  </data>
  <data name="txtTelbStartBet" xml:space="preserve">
    <value>第一口電投訊息</value>
  </data>
  <data name="txtCashShort" xml:space="preserve">
    <value>現</value>
  </data>
  <data name="txtCiouShort" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="txtTelbWebPassword" xml:space="preserve">
    <value>電投管理網密碼</value>
  </data>
  <data name="btnSetPassword" xml:space="preserve">
    <value>設置密碼</value>
  </data>
  <data name="txtAgentTelbCurrency" xml:space="preserve">
    <value>代理電投貨幣</value>
  </data>
  <data name="glabal_msgSecurityCardRead" xml:space="preserve">
    <value>為保安理由, 請把員工卡放在卡機上進行確認</value>
  </data>
  <data name="glabal_msgMultipleCardReaderDetected_FAIL" xml:space="preserve">
    <value>員工卡設定未能成功，請檢查設定並按(Ctrl + R)重新進行</value>
  </data>
  <data name="typeRBPLAYCUSTWLRPT_Report" xml:space="preserve">
    <value>B數上下數報表</value>
  </data>
  <data name="txtBPlayCompSummary" xml:space="preserve">
    <value>來貨人總表</value>
  </data>
  <data name="txtCustChipTranB" xml:space="preserve">
    <value>電投存卡</value>
  </data>
  <data name="action_SMS_MANUAL_type" xml:space="preserve">
    <value>手動SMS</value>
  </data>
  <data name="glabal_msgOneCardReaderDetected" xml:space="preserve">
    <value>偵測到一部讀卡器，將此讀卡器定義為員工讀卡器？(若選否，將會定義為戶口讀卡器)</value>
  </data>
  <data name="msgDiffCustCurrCode" xml:space="preserve">
    <value>貨幣與客人貨幣不同</value>
  </data>
  <data name="global_txtCardReader" xml:space="preserve">
    <value>讀卡器</value>
  </data>
  <data name="global_CurrentIVR" xml:space="preserve">
    <value>當前IVR戶口</value>
  </data>
  <data name="txtSMSSendType" xml:space="preserve">
    <value>發送組別</value>
  </data>
  <data name="typeRAGENTSUMMARYCREDITINFORPT_Core" xml:space="preserve">
    <value>信貸額況列表</value>
  </data>
  <data name="typeRAGENTSUMMARYCREDITINFORPT_Report" xml:space="preserve">
    <value>信貸額況列表</value>
  </data>
  <data name="global_txtGambleTable" xml:space="preserve">
    <value>賭枱</value>
  </data>
  <data name="glabal_msgMultipleCardReaderDetected" xml:space="preserve">
    <value>偵測到多於一部讀卡器，現將進行員工讀卡器設定(一次性)，請將員工卡放到員工讀卡器上。確定進行？.</value>
  </data>
  <data name="global_txtCorrect" xml:space="preserve">
    <value>正確</value>
  </data>
  <data name="global_txtIsBusy" xml:space="preserve">
    <value>繁忙中</value>
  </data>
  <data name="global_txtNotSupport" xml:space="preserve">
    <value>數據不支持</value>
  </data>
  <data name="txtPlaceDate" xml:space="preserve">
    <value>場面日期</value>
  </data>
  <data name="msgErrIVRAgentNotFound" xml:space="preserve">
    <value>未設定認証戶口，請聯系資訊科技部解決。</value>
  </data>
  <data name="global_txtDepositor" xml:space="preserve">
    <value>存/取款人</value>
  </data>
  <data name="global_Salary" xml:space="preserve">
    <value>糧單</value>
  </data>
  <data name="wIDType_HKID" xml:space="preserve">
    <value>香港居民身份証</value>
  </data>
  <data name="wIDType_CNID" xml:space="preserve">
    <value>中國居民身份証</value>
  </data>
  <data name="wIDType_MOID" xml:space="preserve">
    <value>澳門居民身份証</value>
  </data>
  <data name="global_msgInfoIsNotAgentRove" xml:space="preserve">
    <value>該戶口不是巨額用戶,不能添加巨額客人</value>
  </data>
  <data name="txtSignalRConnected" xml:space="preserve">
    <value>推播資訊已連接</value>
  </data>
  <data name="txtSignalRDisconnected" xml:space="preserve">
    <value>連接不到推播資訊</value>
  </data>
  <data name="global_txtSystemRemark" xml:space="preserve">
    <value>系統備註</value>
  </data>
  <data name="txtMonthEndSettleComplexSMS" xml:space="preserve">
    <value>綜合出佣訊息</value>
  </data>
  <data name="txtMonthEndSettleCancelComplexSMS" xml:space="preserve">
    <value>取消綜合出佣訊息</value>
  </data>
  <data name="typeAGENTEXPCREDIT_LST_Core" xml:space="preserve">
    <value>消費批額管理</value>
  </data>
  <data name="txtAgentExpCredit" xml:space="preserve">
    <value>消費批額</value>
  </data>
  <data name="typePOPUPSMSPREVIEW_Core" xml:space="preserve">
    <value>發送短訊預覽</value>
  </data>
  <data name="txtShowRemark" xml:space="preserve">
    <value>顯示備註</value>
  </data>
  <data name="txtAllHoldChipAmt10K" xml:space="preserve">
    <value>全球凍結存款(萬)</value>
  </data>
  <data name="txtConfirmNotDeductExpense" xml:space="preserve">
    <value>確認不扣除消費嗎</value>
  </data>
  <data name="global_btnRegister" xml:space="preserve">
    <value>注冊</value>
  </data>
  <data name="global_btnResetRegister" xml:space="preserve">
    <value>重置注冊</value>
  </data>
  <data name="msgInfoIVRMissingTelExt" xml:space="preserve">
    <value>請設定有效的電話短號</value>
  </data>
  <data name="global_txtValue" xml:space="preserve">
    <value>設定</value>
  </data>
  <data name="typeSYSTABLELST_Core" xml:space="preserve">
    <value>系統管理</value>
  </data>
  <data name="wDesc" xml:space="preserve">
    <value>詳述</value>
  </data>
  <data name="global_txtSave" xml:space="preserve">
    <value>儲存</value>
  </data>
  <data name="txtNotInclude" xml:space="preserve">
    <value>不包括</value>
  </data>
  <data name="txtCancelExchange" xml:space="preserve">
    <value>取消交易</value>
  </data>
  <data name="typeTRANSFERALLTRAN_Core" xml:space="preserve">
    <value>綜合詳情</value>
  </data>
  <data name="txtCanEditByUser" xml:space="preserve">
    <value>可修改</value>
  </data>
  <data name="txtCannotEditByUser" xml:space="preserve">
    <value>不可修改</value>
  </data>
  <data name="txtIsEditByUser" xml:space="preserve">
    <value>是否可修改</value>
  </data>
  <data name="txtDelRemark" xml:space="preserve">
    <value>刪除備註</value>
  </data>
  <data name="global_msgWinLossInputAmountError" xml:space="preserve">
    <value>輸入輸贏數金額不正確</value>
  </data>
  <data name="global_msgInfoHasIOUBonusI" xml:space="preserve">
    <value>不能修改，本轉轉碼設有即贖獎金，請聯繫相關會計同事作出修改。</value>
  </data>
  <data name="global_msgInfoHasSettleInstant" xml:space="preserve">
    <value>此轉碼已即出，不能修改。</value>
  </data>
  <data name="type_CounterChipCode_AUD" xml:space="preserve">
    <value>澳幣</value>
  </data>
  <data name="type_CounterChipCode_HKD" xml:space="preserve">
    <value>港幣</value>
  </data>
  <data name="type_CounterChipCode_KRW" xml:space="preserve">
    <value>韓幣</value>
  </data>
  <data name="type_CounterChipCode_HKDA" xml:space="preserve">
    <value>港幣A</value>
  </data>
  <data name="type_CounterChipCode_HKDB" xml:space="preserve">
    <value>港幣B</value>
  </data>
  <data name="type_CounterChipCode_CNYA" xml:space="preserve">
    <value>人民幣A</value>
  </data>
  <data name="type_CounterChipCode_CNYB" xml:space="preserve">
    <value>人民幣B</value>
  </data>
  <data name="type_CounterChipCode_HKDCNYA" xml:space="preserve">
    <value>港/人A</value>
  </data>
  <data name="type_CounterChipCode_HKDCNYB" xml:space="preserve">
    <value>港/人B</value>
  </data>
  <data name="type_CounterChipCode_PHPA" xml:space="preserve">
    <value>披索A</value>
  </data>
  <data name="type_CounterChipCode_PHPB" xml:space="preserve">
    <value>披索B</value>
  </data>
  <data name="wCompanyRemark" xml:space="preserve">
    <value>本廳備註</value>
  </data>
  <data name="wDayIssueInterest" xml:space="preserve">
    <value>月息日</value>
  </data>
  <data name="wExpireDatetime" xml:space="preserve">
    <value>有效日期</value>
  </data>
  <data name="wGroupRemark" xml:space="preserve">
    <value>集團備註</value>
  </data>
  <data name="wIsIncludeCredit" xml:space="preserve">
    <value>計入戶口批額</value>
  </data>
  <data name="wNight" xml:space="preserve">
    <value>晚</value>
  </data>
  <data name="wRate" xml:space="preserve">
    <value>月息率(%)</value>
  </data>
  <data name="wRolling" xml:space="preserve">
    <value>轉碼數</value>
  </data>
  <data name="wStatusSMS" xml:space="preserve">
    <value>短訊狀態</value>
  </data>
  <data name="wWinLoss" xml:space="preserve">
    <value>輸贏數(萬)</value>
  </data>
  <data name="global_msgPlaceShiftTwentyHourOnce" xml:space="preserve">
    <value>場面截更20小時內只能截一次</value>
  </data>
  <data name="txtLessThanProcessPeriod" xml:space="preserve">
    <value>執行期小於等於</value>
  </data>
  <data name="txtChipSum" xml:space="preserve">
    <value>存碼總和</value>
  </data>
  <data name="msgInfoCapitalThisGame" xml:space="preserve">
    <value>本場本金用於讀場訊息</value>
  </data>
  <data name="msgInfoFollowStaffTelExmaple" xml:space="preserve">
    <value>需輸入區號, 格式為 +85395124578 </value>
  </data>
  <data name="wCapitalThisGame" xml:space="preserve">
    <value>本場本金(萬)</value>
  </data>
  <data name="wFollowStaffTel" xml:space="preserve">
    <value>查詢電話</value>
  </data>
  <data name="txtCommReturnIOU" xml:space="preserve">
    <value>出佣回M</value>
  </data>
  <data name="txtSendUpLevel" xml:space="preserve">
    <value>訊息同時發給上線</value>
  </data>
  <data name="txtRequestNotSend" xml:space="preserve">
    <value>特別不發送</value>
  </data>
  <data name="String1" xml:space="preserve">
    <value />
  </data>
  <data name="txtCapitalTranMBal" xml:space="preserve">
    <value>月息結餘</value>
  </data>
  <data name="txtCustCurrency" xml:space="preserve">
    <value>客人貨幣</value>
  </data>
  <data name="txtForeign_CompCommRate" xml:space="preserve">
    <value>海外佣金率</value>
  </data>
  <data name="txtOperate_CompCommRate" xml:space="preserve">
    <value>營運佣金率</value>
  </data>
  <data name="txtSyndicationBal" xml:space="preserve">
    <value>集團結餘</value>
  </data>
  <data name="wBorrowDateTime" xml:space="preserve">
    <value>借款時間</value>
  </data>
  <data name="wCapitalTempRemark" xml:space="preserve">
    <value>臺面數備註</value>
  </data>
  <data name="wGameSite" xml:space="preserve">
    <value>場地</value>
  </data>
  <data name="wTableName" xml:space="preserve">
    <value>枱名</value>
  </data>
  <data name="wWithdrawDate" xml:space="preserve">
    <value>提數日期</value>
  </data>
  <data name="txtCommNotEnoughPaidExpense" xml:space="preserve">
    <value>佣金不足以支付消費</value>
  </data>
  <data name="txtPayWay" xml:space="preserve">
    <value>付款方式</value>
  </data>
  <data name="wCashIOUContractNo" xml:space="preserve">
    <value>個人借貸合同號</value>
  </data>
  <data name="wIOUContractNo" xml:space="preserve">
    <value>借貸合同號</value>
  </data>
  <data name="typeOPERATINGAPPROVAL_Core" xml:space="preserve">
    <value>營運確認</value>
  </data>
  <data name="typeACCOUNTRPT_ReportGrp" xml:space="preserve">
    <value>會員報表</value>
  </data>
  <data name="typeRACCTYPEUPDNRPT_Report" xml:space="preserve">
    <value>會員每月升跌表</value>
  </data>
  <data name="wAssessors" xml:space="preserve">
    <value>評估人</value>
  </data>
  <data name="txtMemberCardLst" xml:space="preserve">
    <value>會員白卡列表</value>
  </data>
  <data name="wIsConfirmSelect" xml:space="preserve">
    <value>確認選擇</value>
  </data>
  <data name="global_SMSInProgress" xml:space="preserve">
    <value>發送訊息, 請於5至10分鐘後回來檢察狀態</value>
  </data>
  <data name="txtBTMCreateCardSuccess" xml:space="preserve">
    <value>BTM開卡成功</value>
  </data>
  <data name="txtSummaryLst" xml:space="preserve">
    <value>總表</value>
  </data>
  <data name="typeSETCREDIT_Core" xml:space="preserve">
    <value>設定信用額</value>
  </data>
  <data name="txtCreditControlLstV2" xml:space="preserve">
    <value>信貸監控V2</value>
  </data>
  <data name="txtPersonalData" xml:space="preserve">
    <value>個人資料</value>
  </data>
  <data name="typeCREDITCONTROLLSTV2_Core" xml:space="preserve">
    <value>信貸監控V2</value>
  </data>
  <data name="typeCREDITCONTROLLSTV3_Core" xml:space="preserve">
    <value>集團信貸</value>
  </data>
  <data name="btnShowIVRResult" xml:space="preserve">
    <value>顯示結果</value>
  </data>
  <data name="txtMsgCustStatusTerminated" xml:space="preserve">
    <value>客人狀態已終止</value>
  </data>
  <data name="global_txtPokerKingCard" xml:space="preserve">
    <value>Poker King卡</value>
  </data>
  <data name="wEmptyMemberCardNo" xml:space="preserve">
    <value>會員卡號碼(空白)</value>
  </data>
  <data name="txtBTM_CardType" xml:space="preserve">
    <value>卡類型</value>
  </data>
  <data name="txtBTM_MainCard" xml:space="preserve">
    <value>主卡</value>
  </data>
  <data name="txtBTM_SubCard" xml:space="preserve">
    <value>附屬卡</value>
  </data>
  <data name="txtBTM_ConsumptionMethod" xml:space="preserve">
    <value>消費方式</value>
  </data>
  <data name="txtBTM_NotAllowExpense" xml:space="preserve">
    <value>不能消費</value>
  </data>
  <data name="txtBTM_ShareCredit" xml:space="preserve">
    <value>共用信用額</value>
  </data>
  <data name="txtBTM_NonShareCredit" xml:space="preserve">
    <value>獨立信用額</value>
  </data>
  <data name="txtBTM_TelCountryCode" xml:space="preserve">
    <value>電話區號</value>
  </data>
  <data name="txtBTM_IsSMSSend" xml:space="preserve">
    <value>主卡是否接收附屬卡消費訊息</value>
  </data>
  <data name="txtBTM_IsActive" xml:space="preserve">
    <value>是否立即取卡</value>
  </data>
  <data name="txtBTM_TakeCardLater" xml:space="preserve">
    <value>稍後取卡</value>
  </data>
  <data name="txtBTM_TakeCardNow" xml:space="preserve">
    <value>立即取卡</value>
  </data>
  <data name="txtBTM_SelectedCardNo" xml:space="preserve">
    <value>已選會員卡編號</value>
  </data>
  <data name="txtSending" xml:space="preserve">
    <value>發送中</value>
  </data>
  <data name="txtSendSMSToQueProcs" xml:space="preserve">
    <value>正在發送短信，請半個小時後再查看</value>
  </data>
  <data name="txtCreditInfo" xml:space="preserve">
    <value>批額資料</value>
  </data>
  <data name="txtBackgroundDataAndContract" xml:space="preserve">
    <value>背景資料及合同</value>
  </data>
  <data name="global_txtShowRollingWholeLineGrp" xml:space="preserve">
    <value>顯示全線轉碼狀況</value>
  </data>
  <data name="typeNEWMEMBERCARDLST_Core" xml:space="preserve">
    <value>會員開卡</value>
  </data>
  <data name="global_fnEditAgentExt" xml:space="preserve">
    <value>編輯資訊</value>
  </data>
  <data name="txtMarketLevel" xml:space="preserve">
    <value>市場星級</value>
  </data>
  <data name="txtRollTranYearMth" xml:space="preserve">
    <value>月結結算週期</value>
  </data>
  <data name="txtExpUnlimitedCredit" xml:space="preserve">
    <value>消費無限額</value>
  </data>
  <data name="global_txtIsForeignGrp" xml:space="preserve">
    <value>是否外團數</value>
  </data>
  <data name="global_txtIsInternal" xml:space="preserve">
    <value>是否內部飛數</value>
  </data>
  <data name="txtIsForeignGrp" xml:space="preserve">
    <value>顯示外團數</value>
  </data>
  <data name="typeRAGENTLEVELINFORPT_Report" xml:space="preserve">
    <value>戶口身份級別報表</value>
  </data>
  <data name="wReturMarker" xml:space="preserve">
    <value>還本</value>
  </data>
  <data name="wPaidAmt" xml:space="preserve">
    <value>還款總數</value>
  </data>
  <data name="txtCutoff" xml:space="preserve">
    <value>截至</value>
  </data>
  <data name="txtTtlCount" xml:space="preserve">
    <value>紀錄總數</value>
  </data>
  <data name="txtBTMCreateCard" xml:space="preserve">
    <value>開BTM卡</value>
  </data>
  <data name="global_msgDuplicateCustomer" xml:space="preserve">
    <value>已有相同客人</value>
  </data>
  <data name="global_txtLastWinLoss" xml:space="preserve">
    <value>前更輸贏</value>
  </data>
  <data name="global_txtThisWinLoss" xml:space="preserve">
    <value>本更輸贏</value>
  </data>
  <data name="typeSYSSMSLST_Core" xml:space="preserve">
    <value>系統SMS管理</value>
  </data>
  <data name="typeSYSSMSEDIT_Core" xml:space="preserve">
    <value>系統SMS修改</value>
  </data>
  <data name="global_txtDayRate" xml:space="preserve">
    <value>即日匯率</value>
  </data>
  <data name="global_txtMonthRate" xml:space="preserve">
    <value>公司匯率</value>
  </data>
  <data name="txtRate" xml:space="preserve">
    <value>匯率</value>
  </data>
  <data name="txtSendEmaiFail" xml:space="preserve">
    <value>Email發送失敗</value>
  </data>
  <data name="typeRAGENTNAGSTORERPT_Report" xml:space="preserve">
    <value>可負數戶口報表</value>
  </data>
  <data name="txtNotSend" xml:space="preserve">
    <value>不發送</value>
  </data>
  <data name="txtDataAnalysis" xml:space="preserve">
    <value>數據分析</value>
  </data>
  <data name="txtReturnMarkerAnalysis" xml:space="preserve">
    <value>還款分析</value>
  </data>
  <data name="wCreditBlackList" xml:space="preserve">
    <value>信貸黑名單</value>
  </data>
  <data name="wExpAutoPay" xml:space="preserve">
    <value>消費自動付款</value>
  </data>
  <data name="wIntroducerCredit" xml:space="preserve">
    <value>介紹信貸</value>
  </data>
  <data name="wMarketLevelType" xml:space="preserve">
    <value>星級</value>
  </data>
  <data name="wShopSettleTran" xml:space="preserve">
    <value>停佣</value>
  </data>
  <data name="wStopExt" xml:space="preserve">
    <value>停止消費</value>
  </data>
  <data name="wStopM" xml:space="preserve">
    <value>停止借貸</value>
  </data>
  <data name="txtAccountTotal" xml:space="preserve">
    <value>戶口總額</value>
  </data>
  <data name="txtExpenseTotal" xml:space="preserve">
    <value>消費總額</value>
  </data>
  <data name="wOneToThirty" xml:space="preserve">
    <value>1-30天 </value>
  </data>
  <data name="wThirtyoneToSixty" xml:space="preserve">
    <value>31-60天 </value>
  </data>
  <data name="wSixtyoneToNinety" xml:space="preserve">
    <value>61-90天 </value>
  </data>
  <data name="wNinety" xml:space="preserve">
    <value>90天以上 </value>
  </data>
  <data name="txtReturnProportionDtlChart" xml:space="preserve">
    <value>回款過期比例圖</value>
  </data>
  <data name="txtReturnProportionChart" xml:space="preserve">
    <value>回款比例圖</value>
  </data>
  <data name="txtNameNotAllowNumericOnly" xml:space="preserve">
    <value>中英文(姓氏/名字), 不含有數字組合</value>
  </data>
  <data name="txtDepartmentLst" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="wDeptCode" xml:space="preserve">
    <value>部門編號</value>
  </data>
  <data name="wDeptName" xml:space="preserve">
    <value>部門名稱</value>
  </data>
  <data name="wRateType" xml:space="preserve">
    <value>匯率類型</value>
  </data>
  <data name="txtDisplayExpired" xml:space="preserve">
    <value>顯示已過期</value>
  </data>
  <data name="typeCHARTOFACC_Core" xml:space="preserve">
    <value>帳項資料圖</value>
  </data>
  <data name="global_txtBalanceSheet" xml:space="preserve">
    <value>資產負責表</value>
  </data>
  <data name="txtAccountGroup" xml:space="preserve">
    <value>帳項組</value>
  </data>
  <data name="txtAccountingCredit" xml:space="preserve">
    <value>貸項</value>
  </data>
  <data name="txtAccountingDebit" xml:space="preserve">
    <value>借項</value>
  </data>
  <data name="txtAccountName" xml:space="preserve">
    <value>帳項名稱</value>
  </data>
  <data name="txtAccountSeq" xml:space="preserve">
    <value>帳項排序</value>
  </data>
  <data name="txtDebitCredit" xml:space="preserve">
    <value>借/貸</value>
  </data>
  <data name="txtManufacturingAcc" xml:space="preserve">
    <value>工業帳目</value>
  </data>
  <data name="txtTradingAccount" xml:space="preserve">
    <value>貿易帳目</value>
  </data>
  <data name="txtUpperAccountCode" xml:space="preserve">
    <value>上線帳項碼</value>
  </data>
  <data name="typeACCOUNTING_Core" xml:space="preserve">
    <value>會計</value>
  </data>
  <data name="global_msgAccountingCodeInvalid" xml:space="preserve">
    <value>帳項碼及上線帳項碼必須正確</value>
  </data>
  <data name="txtEventCode" xml:space="preserve">
    <value>事項碼</value>
  </data>
  <data name="txtVouCreditAmt" xml:space="preserve">
    <value>貸項額</value>
  </data>
  <data name="txtVouDebitAmt" xml:space="preserve">
    <value>借項額</value>
  </data>
  <data name="typeVOUDTLLSTENQUIRY_Core" xml:space="preserve">
    <value>票單查詢</value>
  </data>
  <data name="wVouId" xml:space="preserve">
    <value>票單編號</value>
  </data>
  <data name="txtWithOutAccountingRole" xml:space="preserve">
    <value>沒有會計權限</value>
  </data>
  <data name="txtImageManage" xml:space="preserve">
    <value>圖像管理</value>
  </data>
  <data name="txtImportRollexSummaryValues" xml:space="preserve">
    <value>匯入RollsMary系統數</value>
  </data>
  <data name="txtReview" xml:space="preserve">
    <value>覆核</value>
  </data>
  <data name="wVouPrefix" xml:space="preserve">
    <value>字首</value>
  </data>
  <data name="wVouYearMth" xml:space="preserve">
    <value>年月</value>
  </data>
  <data name="txtAccountCode" xml:space="preserve">
    <value>帳項碼</value>
  </data>
  <data name="typeFXRATELST_Core" xml:space="preserve">
    <value>匯率管理</value>
  </data>
  <data name="typeVOULST_Core" xml:space="preserve">
    <value>票單管理</value>
  </data>
  <data name="typeCOMPEXPSHARELST_Core" xml:space="preserve">
    <value>公司比例設定</value>
  </data>
  <data name="wCompGrp" xml:space="preserve">
    <value>公司組</value>
  </data>
  <data name="wShareRate" xml:space="preserve">
    <value>比例</value>
  </data>
  <data name="txtDepartmentDtl" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="typeDEPARTMENTDTL_Core" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="typeDEPARTMENTLST_Core" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="String2" xml:space="preserve">
    <value />
  </data>
  <data name="wExpireYearMth" xml:space="preserve">
    <value>到期時間</value>
  </data>
  <data name="wYearMthEffective" xml:space="preserve">
    <value>生效月份</value>
  </data>
  <data name="wYearMthExpire" xml:space="preserve">
    <value>到期月份</value>
  </data>
  <data name="txtAlreadyReviewed" xml:space="preserve">
    <value>已覆核</value>
  </data>
  <data name="txtAutoGenVoucher" xml:space="preserve">
    <value>自動票單</value>
  </data>
  <data name="txtInputVoucherCOA" xml:space="preserve">
    <value>輸入票單所屬帳項碼</value>
  </data>
  <data name="txtInputVoucherComp" xml:space="preserve">
    <value>輸入票單所屬公司</value>
  </data>
  <data name="txtNumOfRecords" xml:space="preserve">
    <value>筆記錄</value>
  </data>
  <data name="txtVoucherNo" xml:space="preserve">
    <value>票據編號</value>
  </data>
  <data name="txtVoucherSumEach" xml:space="preserve">
    <value>各項總數</value>
  </data>
  <data name="typeVOUDTL_Core" xml:space="preserve">
    <value>票單記錄</value>
  </data>
  <data name="txtAccountingYear" xml:space="preserve">
    <value>會計年度</value>
  </data>
  <data name="txtAccountingYearMth" xml:space="preserve">
    <value>會計週期</value>
  </data>
  <data name="typePROFITANDLOSS_Core" xml:space="preserve">
    <value>什支表</value>
  </data>
  <data name="txtCHIPTRAN_CONVERT" xml:space="preserve">
    <value>存卡類轉互</value>
  </data>
  <data name="type_C_TO_W" xml:space="preserve">
    <value>存C 轉換成 羸錢</value>
  </data>
  <data name="type_W_TO_C" xml:space="preserve">
    <value>羸錢 轉換成 存C</value>
  </data>
  <data name="wResponseStatus" xml:space="preserve">
    <value>接聽狀態</value>
  </data>
  <data name="txtCEO" xml:space="preserve">
    <value>總裁</value>
  </data>
  <data name="txtCEO_CENTRAL" xml:space="preserve">
    <value>總裁+信貸</value>
  </data>
  <data name="txtTEXTREPLAY" xml:space="preserve">
    <value>訊息回覆</value>
  </data>
  <data name="txtVoiceMessage" xml:space="preserve">
    <value>留言信箱</value>
  </data>
  <data name="txtStartCannotContact" xml:space="preserve">
    <value>開始聯絡不上</value>
  </data>
  <data name="txtStartAppointment" xml:space="preserve">
    <value>開始通知約見</value>
  </data>
  <data name="txtReject" xml:space="preserve">
    <value>拒絕</value>
  </data>
  <data name="txtNotice" xml:space="preserve">
    <value>提示</value>
  </data>
  <data name="txtInputTotal" xml:space="preserve">
    <value>所輸入總數</value>
  </data>
  <data name="global_msgBothCreditDebitZeroh" xml:space="preserve">
    <value>借項額和貸項額同時為零</value>
  </data>
  <data name="global_msgDebitCreditMistmatch" xml:space="preserve">
    <value>借項額需與貸項額相同 (如全部票單都是借項或貸項的其中一種，系統會自動計算所需差額票單)</value>
  </data>
  <data name="global_msgDebitCreditMistmatchRollexImport" xml:space="preserve">
    <value>借項額需與貸項額相同</value>
  </data>
  <data name="global_msgMoreThanOneCurrency" xml:space="preserve">
    <value>不能輸入多於一個貨幣</value>
  </data>
  <data name="txtAuStoreBookCustomer" xml:space="preserve">
    <value>大薄(客戶)</value>
  </data>
  <data name="txtAuStoreBookStore" xml:space="preserve">
    <value>大薄(內部)</value>
  </data>
  <data name="txtCashTypeCC" xml:space="preserve">
    <value>現金碼</value>
  </data>
  <data name="txtCasinoCredit" xml:space="preserve">
    <value>賭場CREDIT</value>
  </data>
  <data name="txtNNChipForeign" xml:space="preserve">
    <value>外館碼</value>
  </data>
  <data name="typeBALANCESHEET_Core" xml:space="preserve">
    <value>資產負債表</value>
  </data>
  <data name="wPromissoryNote" xml:space="preserve">
    <value>本票</value>
  </data>
  <data name="global_btnDeleteVoucher" xml:space="preserve">
    <value>刪除票據(包括所有明細)</value>
  </data>
  <data name="typePROFITANDLOSSSTANDARD_Core" xml:space="preserve">
    <value>損益表</value>
  </data>
  <data name="txtSolutionCount" xml:space="preserve">
    <value>約見方案達標次數</value>
  </data>
  <data name="txtFailSolution" xml:space="preserve">
    <value>不達標</value>
  </data>
  <data name="txtCreditControlPenaltyProblem" xml:space="preserve">
    <value>信貸監控-利息問題</value>
  </data>
  <data name="txtPenaltyProblem" xml:space="preserve">
    <value>利息問題</value>
  </data>
  <data name="typeCREDITCONTROLLSTV2_PENALTYPROBLEM_Core" xml:space="preserve">
    <value>新增利息問題</value>
  </data>
  <data name="typeCREDITCONTROLLSTV2_NOTICE_Core" xml:space="preserve">
    <value>新增通報機制</value>
  </data>
  <data name="typeCREDITCONTROLLSTV2_TMPCREDIT_Core" xml:space="preserve">
    <value>新增臨時額</value>
  </data>
  <data name="typeCREDITCONTROL_TMPCREDIT_Core" xml:space="preserve">
    <value>信貸監控-臨時額</value>
  </data>
  <data name="typeCREDITCONTROL_PENALTYPROBLEM_Core" xml:space="preserve">
    <value>信貸監控-利息問題</value>
  </data>
  <data name="typeCREDITCONTROL_NOTICE_Core" xml:space="preserve">
    <value>信貸監控-通報機制</value>
  </data>
  <data name="txtCreditControlNotice" xml:space="preserve">
    <value>通報機制</value>
  </data>
  <data name="txtNoticeList" xml:space="preserve">
    <value>通報紀錄</value>
  </data>
  <data name="txtWavePenalty" xml:space="preserve">
    <value>免息金額</value>
  </data>
  <data name="wTmpCreditAmt" xml:space="preserve">
    <value>額度</value>
  </data>
  <data name="wCreditDate" xml:space="preserve">
    <value>批額日期</value>
  </data>
  <data name="wLastReturn" xml:space="preserve">
    <value>最近回數(萬)</value>
  </data>
  <data name="wLastReturnAmt" xml:space="preserve">
    <value>最近回數</value>
  </data>
  <data name="wCenterRemark" xml:space="preserve">
    <value>信貸部建議</value>
  </data>
  <data name="wCEORemark" xml:space="preserve">
    <value>總裁致電後回覆</value>
  </data>
  <data name="wNoticeDate" xml:space="preserve">
    <value>通知日期</value>
  </data>
  <data name="wCreditTmpAmt" xml:space="preserve">
    <value>現時臨時額(萬)</value>
  </data>
  <data name="wCreditLimitDate" xml:space="preserve">
    <value>期限</value>
  </data>
  <data name="wCreditMarker" xml:space="preserve">
    <value>可簽大數(萬)</value>
  </data>
  <data name="txtMethordAndMeeting" xml:space="preserve">
    <value>方案及約見紀錄</value>
  </data>
  <data name="txtHKDToCNY" xml:space="preserve">
    <value>港幣兌人民幣</value>
  </data>
  <data name="txtCNYToHKD" xml:space="preserve">
    <value>人民幣兌港幣</value>
  </data>
  <data name="txt60Return" xml:space="preserve">
    <value>60天無回款</value>
  </data>
  <data name="wCreditOver" xml:space="preserve">
    <value>額度屆滿</value>
  </data>
  <data name="wCreditLimt" xml:space="preserve">
    <value>額度</value>
  </data>
  <data name="txtNewResponseOnResponse" xml:space="preserve">
    <value>最新情況/不達標原因</value>
  </data>
  <data name="txtRollingAnalysis" xml:space="preserve">
    <value>轉碼分析</value>
  </data>
  <data name="txtContactAnalysis" xml:space="preserve">
    <value>聯絡分析</value>
  </data>
  <data name="txtAppointmentAnalysis" xml:space="preserve">
    <value>約見分析</value>
  </data>
  <data name="txtContactChart" xml:space="preserve">
    <value>接聽狀態比例圖</value>
  </data>
  <data name="txtNoContantAnalysis" xml:space="preserve">
    <value>聯絡不上紀錄</value>
  </data>
  <data name="wAppointmentCount" xml:space="preserve">
    <value>約見次數</value>
  </data>
  <data name="txtLastAppointmentDate" xml:space="preserve">
    <value>距離上次約見時間</value>
  </data>
  <data name="txtCanContact" xml:space="preserve">
    <value>聯絡上</value>
  </data>
  <data name="txtCannotContact" xml:space="preserve">
    <value>聯絡不上</value>
  </data>
  <data name="global_msgInputAccCode" xml:space="preserve">
    <value>必須輸入帳項碼</value>
  </data>
  <data name="global_msgInputComp" xml:space="preserve">
    <value>必須輸入公司</value>
  </data>
  <data name="global_msgInputCurrCode" xml:space="preserve">
    <value>必須輸入貨幣</value>
  </data>
  <data name="global_msgReviewDifUpdby" xml:space="preserve">
    <value>覆核經手人需要與經手人不同</value>
  </data>
  <data name="txtAutoGeneratedVoucher" xml:space="preserve">
    <value>**此單是因為借貸項不相等而自動產生的票單</value>
  </data>
  <data name="typeACTIONVOUDTL_Core" xml:space="preserve">
    <value>票單管理</value>
  </data>
  <data name="typePOPUPLIST_Core" xml:space="preserve">
    <value>详情</value>
  </data>
  <data name="global_msgBlock_CWO_TSO" xml:space="preserve">
    <value>暫存/未取 請使用綜合理財</value>
  </data>
  <data name="txtContactProportion" xml:space="preserve">
    <value>已接聽比例</value>
  </data>
  <data name="txtNonContactProportion" xml:space="preserve">
    <value>未接聽比例</value>
  </data>
  <data name="txtRateDtl" xml:space="preserve">
    <value>匯率詳情</value>
  </data>
  <data name="global_msgPhotoUploaded" xml:space="preserve">
    <value>圖片已上載</value>
  </data>
  <data name="typeCRMSETTING_Core" xml:space="preserve">
    <value>CRM設定</value>
  </data>
  <data name="typeTEAMMEMBERLST_Core" xml:space="preserve">
    <value>部門組別管理</value>
  </data>
  <data name="txtTeamMemberLst" xml:space="preserve">
    <value>部門組別管理</value>
  </data>
  <data name="txtCRMDept" xml:space="preserve">
    <value>部門</value>
  </data>
  <data name="txtCRMDeptCode" xml:space="preserve">
    <value>部門編碼</value>
  </data>
  <data name="txtCRMPlace" xml:space="preserve">
    <value>場館</value>
  </data>
  <data name="txtCRMSMSOption" xml:space="preserve">
    <value>SMS選項</value>
  </data>
  <data name="txtCRMStaffCode" xml:space="preserve">
    <value>員工號碼</value>
  </data>
  <data name="txtCRMTeam" xml:space="preserve">
    <value>組別名稱</value>
  </data>
  <data name="txtCRMTeamCrtDate" xml:space="preserve">
    <value>建立時間</value>
  </data>
  <data name="txtCRMTeamStatus" xml:space="preserve">
    <value>狀態原因</value>
  </data>
  <data name="txtCRMUsrDisplayName" xml:space="preserve">
    <value>顯示名稱</value>
  </data>
  <data name="txtCRMUsrFullName" xml:space="preserve">
    <value>全名</value>
  </data>
  <data name="txtCRMPrivateTel" xml:space="preserve">
    <value>個人電話</value>
  </data>
  <data name="txtCRMSMSTel" xml:space="preserve">
    <value>SMS電話</value>
  </data>
  <data name="typeTEAMMEMBERDTL_Core" xml:space="preserve">
    <value>部門組別管理</value>
  </data>
  <data name="txtCRMCountry" xml:space="preserve">
    <value>地區</value>
  </data>
  <data name="txtCRMNormal" xml:space="preserve">
    <value>一般</value>
  </data>
  <data name="txtCRMOtherMembers" xml:space="preserve">
    <value>其他人員</value>
  </data>
  <data name="txtCRMTeamMembers" xml:space="preserve">
    <value>組別人員</value>
  </data>
  <data name="txtPointType" xml:space="preserve">
    <value>積分類</value>
  </data>
  <data name="txtCRMActivate" xml:space="preserve">
    <value>使用中</value>
  </data>
  <data name="txtCRMSuspend" xml:space="preserve">
    <value>暫停使用</value>
  </data>
  <data name="wGame" xml:space="preserve">
    <value>遊戲</value>
  </data>
  <data name="txtMarkerAndCreditAnalysis" xml:space="preserve">
    <value>簽碼及批額分析</value>
  </data>
  <data name="txtMarkerDayAndProportion" xml:space="preserve">
    <value>過期次數及比例%</value>
  </data>
  <data name="txtAvgExpireDay" xml:space="preserve">
    <value>平均過期天數</value>
  </data>
  <data name="txtAvgExpireAmtProportion" xml:space="preserve">
    <value>過期金額比例%</value>
  </data>
  <data name="txtAvgExpireMaxMumberDay" xml:space="preserve">
    <value>過期最長天數</value>
  </data>
  <data name="txtLstMarkerDayAndAmt" xml:space="preserve">
    <value>最後開工時間及金額</value>
  </data>
  <data name="txtHaveCreditNoUseDay" xml:space="preserve">
    <value>有額度而無用的天數</value>
  </data>
  <data name="txtOneMth" xml:space="preserve">
    <value>一個月</value>
  </data>
  <data name="txtThreeMth" xml:space="preserve">
    <value>三個月</value>
  </data>
  <data name="txtSixMth" xml:space="preserve">
    <value>六個月</value>
  </data>
  <data name="txtTotalMarkerAmt" xml:space="preserve">
    <value>累計簽碼金額</value>
  </data>
  <data name="txtGameType1" xml:space="preserve">
    <value>百家樂</value>
  </data>
  <data name="RollSourceType_CAPITAL" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="RollSourceType_CAPITAL_M" xml:space="preserve">
    <value>股本M</value>
  </data>
  <data name="RollSourceType_CREDIT" xml:space="preserve">
    <value>批額</value>
  </data>
  <data name="RollSourceType_HOLD_COMM" xml:space="preserve">
    <value>HOLD佣出M</value>
  </data>
  <data name="RollSourceType_CIO" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="RollSourceType_IOU" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="RollSourceType_HOLD_STORE" xml:space="preserve">
    <value>凍咭</value>
  </data>
  <data name="RollSourceType_MTHINT" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="RollSourceType_MTHINT_M" xml:space="preserve">
    <value>月息M</value>
  </data>
  <data name="RollSourceType_MASTER" xml:space="preserve">
    <value>娛樂場額</value>
  </data>
  <data name="global_msgFieldACannotMatchFieldB" xml:space="preserve">
    <value>{0}不能與{1}相同</value>
  </data>
  <data name="txtPrintAppForm" xml:space="preserve">
    <value>開戶申請表</value>
  </data>
  <data name="wIsAttention" xml:space="preserve">
    <value>專案</value>
  </data>
  <data name="action_ATTENTION_type" xml:space="preserve">
    <value>專案</value>
  </data>
  <data name="typeCOMPCREDITDASHBOARD_Core" xml:space="preserve">
    <value>集團信貸Dashboard</value>
  </data>
  <data name="Place_txtBirthday" xml:space="preserve">
    <value>生日</value>
  </data>
  <data name="txtCashNotify" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="typePLACE_NOTIFYAPPROVAL_Core" xml:space="preserve">
    <value>現金確認</value>
  </data>
  <data name="action_APPROVEDATA_type" xml:space="preserve">
    <value>確認</value>
  </data>
  <data name="typeCOMPEXPSHAREDTL_Core" xml:space="preserve">
    <value>公司比例記錄</value>
  </data>
  <data name="typeFXRATEDTL_Core" xml:space="preserve">
    <value>匯率記錄</value>
  </data>
  <data name="typeBALANCESHEET_Report" xml:space="preserve">
    <value>資產負債表</value>
  </data>
  <data name="typeCHARTOFACCDTL_Core" xml:space="preserve">
    <value>帳項資料圖</value>
  </data>
  <data name="typePROFITANDLOSSSTANDARD_Report" xml:space="preserve">
    <value>損益表</value>
  </data>
  <data name="typePROFITANDLOSS_Report" xml:space="preserve">
    <value>什支表</value>
  </data>
  <data name="typerVouDtlLst_Report" xml:space="preserve">
    <value>票單查詢報表</value>
  </data>
  <data name="msgCustCurrCodeMismatch" xml:space="preserve">
    <value>客人貨幣與出碼貨幣不相符。</value>
  </data>
  <data name="typeSHIFTUSERLST_Core" xml:space="preserve">
    <value>當值員工管理</value>
  </data>
  <data name="typeSHIFTUSERDTL_Core" xml:space="preserve">
    <value>當值員工記錄</value>
  </data>
  <data name="typeACCOUNTING_DEPARTMENTDTL_Core" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="typeACCOUNTING_DEPARTMENTLST_Core" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="txtOverCreditMarker" xml:space="preserve">
    <value>半年內每月最高峰總簽大數</value>
  </data>
  <data name="txtMaxCreditMarker" xml:space="preserve">
    <value>半年內簽過額</value>
  </data>
  <data name="txtC_TO_W" xml:space="preserve">
    <value>存C轉WINC</value>
  </data>
  <data name="txtW_TO_C" xml:space="preserve">
    <value>WINC轉存C</value>
  </data>
  <data name="typeSTORETYPETRANLSTRPT_Report" xml:space="preserve">
    <value>存卡類轉換報表</value>
  </data>
  <data name="wTime" xml:space="preserve">
    <value>時間</value>
  </data>
  <data name="txtRefreshMthEndFxRate" xml:space="preserve">
    <value>更新兌換率</value>
  </data>
  <data name="txtPopBFDrinkTitle" xml:space="preserve">
    <value>積分概況詳情 - 未做月結前</value>
  </data>
  <data name="txtSignatureSample" xml:space="preserve">
    <value>簽署式樣 Signature Sample</value>
  </data>
  <data name="txtBossStr" xml:space="preserve">
    <value>帳戶利益最終歸屬者</value>
  </data>
  <data name="txtAuthActionCodeEName" xml:space="preserve">
    <value>Authorized Representative</value>
  </data>
  <data name="txtBossEName" xml:space="preserve">
    <value>Ultimate Account Owner</value>
  </data>
  <data name="txtAcctType" xml:space="preserve">
    <value>申請類型</value>
  </data>
  <data name="txtAppliedBy" xml:space="preserve">
    <value>申請人身份</value>
  </data>
  <data name="msgRepaymentMorethan15" xml:space="preserve">
    <value>單次還款單數不能多於15單。</value>
  </data>
  <data name="typePLACE_FOLLOWSTAFF_Core" xml:space="preserve">
    <value>跟單員工</value>
  </data>
  <data name="action_REJECT_type" xml:space="preserve">
    <value>不批準</value>
  </data>
  <data name="global_txtShiftCutAlready" xml:space="preserve">
    <value>已截更</value>
  </data>
  <data name="global_txtHasPeddingFollowStaff" xml:space="preserve">
    <value>已有未確認的跟單員工</value>
  </data>
  <data name="global_txtNoFollowStaff" xml:space="preserve">
    <value>未有跟單員工</value>
  </data>
  <data name="global_txtNoFollowStaff_SwitchShift" xml:space="preserve">
    <value>請設定截更之跟單員工</value>
  </data>
  <data name="txtCreditStatus_V2" xml:space="preserve">
    <value>信貸額概況V2</value>
  </data>
  <data name="action_CREDITSTATUS_V2_type" xml:space="preserve">
    <value>信貸額概況V2</value>
  </data>
  <data name="txtOutstanding_CAP" xml:space="preserve">
    <value>股本已簽額(萬)</value>
  </data>
  <data name="txtOutstanding_IO" xml:space="preserve">
    <value>U已簽額(萬)</value>
  </data>
  <data name="txtOutstanding_Y" xml:space="preserve">
    <value>營運已簽額(萬)</value>
  </data>
  <data name="txtOutstanding_F" xml:space="preserve">
    <value>海外已簽額(萬)</value>
  </data>
  <data name="txtOutstanding_CH" xml:space="preserve">
    <value>個人已簽額(萬)</value>
  </data>
  <data name="wMIOURolling" xml:space="preserve">
    <value>月息配置</value>
  </data>
  <data name="wZMIOUAmt" xml:space="preserve">
    <value>Z卡月息(萬)</value>
  </data>
  <data name="txtIsCreditContract" xml:space="preserve">
    <value>信貸合同</value>
  </data>
  <data name="txtIsCashCheckNotice" xml:space="preserve">
    <value>本票責任聲明書</value>
  </data>
  <data name="txtIsCheckNotice" xml:space="preserve">
    <value>支票責任聲明書</value>
  </data>
  <data name="txtIsPromissoryNote" xml:space="preserve">
    <value>Promissory Note</value>
  </data>
  <data name="txtIsCheck" xml:space="preserve">
    <value>支票</value>
  </data>
  <data name="wSmallAmount" xml:space="preserve">
    <value>小額</value>
  </data>
  <data name="txtNonNotice" xml:space="preserve">
    <value>未通報戶口</value>
  </data>
  <data name="txtCreditFull" xml:space="preserve">
    <value>額度屆滿</value>
  </data>
  <data name="txtFirstCreditMarkerExpire" xml:space="preserve">
    <value>首次批額簽碼過期</value>
  </data>
  <data name="txtDisConnectDay" xml:space="preserve">
    <value>失聯天數</value>
  </data>
  <data name="txtMeetingSuccessCount" xml:space="preserve">
    <value>約見逹標次數</value>
  </data>
  <data name="msgWarnCreditControl" xml:space="preserve">
    <value>如戶主出現於各館,或白咭存取等任何動作,請立即聯絡中央信貸部同事跟進,謝謝</value>
  </data>
  <data name="txtRollingAPlay_MI_10K" xml:space="preserve">
    <value>A數[月息]轉碼(萬)</value>
  </data>
  <data name="txtRollingBPlay_MI_10K" xml:space="preserve">
    <value>B數[月息]轉碼(萬)</value>
  </data>
  <data name="txtRollingMIOU" xml:space="preserve">
    <value>月息轉碼</value>
  </data>
  <data name="wCommRate_MI" xml:space="preserve">
    <value>佣金率(月息)</value>
  </data>
  <data name="wExchangeCurrCode" xml:space="preserve">
    <value>存澳門貨幣</value>
  </data>
  <data name="txtCNY" xml:space="preserve">
    <value>人民幣</value>
  </data>
  <data name="txtAccountEName" xml:space="preserve">
    <value>帳項英文名稱</value>
  </data>
  <data name="wDeptEName" xml:space="preserve">
    <value>部門英文名稱</value>
  </data>
  <data name="txtCRMPickUpPlaceSetting" xml:space="preserve">
    <value>取票地點管理</value>
  </data>
  <data name="txtCRMPickUpPlace" xml:space="preserve">
    <value>取票地點</value>
  </data>
  <data name="typePICKUPPLACELST_Core" xml:space="preserve">
    <value>取票地點管理</value>
  </data>
  <data name="txtSearchKey" xml:space="preserve">
    <value>尋找字眼</value>
  </data>
  <data name="txtSortSeqNo" xml:space="preserve">
    <value>排序號</value>
  </data>
  <data name="wShipTicket" xml:space="preserve">
    <value>船票</value>
  </data>
  <data name="wAirTicket" xml:space="preserve">
    <value>飛機票</value>
  </data>
  <data name="wFlightBoarding" xml:space="preserve">
    <value>登機服務</value>
  </data>
  <data name="wEntranceTicket" xml:space="preserve">
    <value>門票</value>
  </data>
  <data name="typePICKUPPLACEDTL_Core" xml:space="preserve">
    <value>取票地點管理</value>
  </data>
  <data name="txtAccecptNumericOnly" xml:space="preserve">
    <value>只接受為數字</value>
  </data>
  <data name="wCreditExpiryDate" xml:space="preserve">
    <value>批額到期日</value>
  </data>
  <data name="wCreditExpire" xml:space="preserve">
    <value>批額到期</value>
  </data>
  <data name="global_btnManage" xml:space="preserve">
    <value>管理</value>
  </data>
  <data name="typeSETTLETRANADMINMODE_Core" xml:space="preserve">
    <value>手動出糧</value>
  </data>
  <data name="txtCRMHotelSetting" xml:space="preserve">
    <value>酒店管理</value>
  </data>
  <data name="typeHOTELLST_Core" xml:space="preserve">
    <value>酒店管理</value>
  </data>
  <data name="txtHotelName" xml:space="preserve">
    <value>酒店名稱</value>
  </data>
  <data name="txtCRMHotelCName" xml:space="preserve">
    <value>酒店名稱(中)</value>
  </data>
  <data name="txtCRMHotelEName" xml:space="preserve">
    <value>酒店名稱(英)</value>
  </data>
  <data name="txtCRMHotelJapanName" xml:space="preserve">
    <value>酒店名稱(日)</value>
  </data>
  <data name="txtCRMHotelKoreaName" xml:space="preserve">
    <value>酒店名稱(韓)</value>
  </data>
  <data name="txtCRMHotelThaiName" xml:space="preserve">
    <value>酒店名稱(泰)</value>
  </data>
  <data name="txtLocation" xml:space="preserve">
    <value>地區</value>
  </data>
  <data name="txtExternalHotel" xml:space="preserve">
    <value>外館酒店</value>
  </data>
  <data name="typeHOTELDTL_Core" xml:space="preserve">
    <value>酒店設定</value>
  </data>
  <data name="typeROOMALLOTMENTLST_Core" xml:space="preserve">
    <value>房間分配</value>
  </data>
  <data name="txtParentHotelName" xml:space="preserve">
    <value>母系酒店</value>
  </data>
  <data name="txtInvalidParentHotelRID" xml:space="preserve">
    <value>母系酒店不可與酒店相同</value>
  </data>
  <data name="txtAllFiles" xml:space="preserve">
    <value>全部文件</value>
  </data>
  <data name="typeACCOUNTING_SYSRPT_Core" xml:space="preserve">
    <value>會計系統</value>
  </data>
  <data name="typeOPERATE_SYSRPT_Core" xml:space="preserve">
    <value>營運系統</value>
  </data>
  <data name="typeROLLING_SYSRPT_Core" xml:space="preserve">
    <value>轉碼系統</value>
  </data>
  <data name="typeROPERATECAPITALTRANMRPT_Report" xml:space="preserve">
    <value>股東個人交貨月報表</value>
  </data>
  <data name="typeRFREEZESTATUSRPT_Report" xml:space="preserve">
    <value>凍M拆息現況報表</value>
  </data>
  <data name="typeRFREEZESETTLERPT_Report" xml:space="preserve">
    <value>凍M拆息歸還報表</value>
  </data>
  <data name="typeFREEZEPENALTYRPT_ReportGrp" xml:space="preserve">
    <value>凍M拆息報表</value>
  </data>
  <data name="wPendFollowStaff" xml:space="preserve">
    <value>待跟單員工</value>
  </data>
  <data name="txtFollowEnd" xml:space="preserve">
    <value>結束</value>
  </data>
  <data name="global_msgNoAvaibleFollower" xml:space="preserve">
    <value>沒有可用跟單員工</value>
  </data>
  <data name="typeDigit10K" xml:space="preserve">
    <value>萬位</value>
  </data>
  <data name="typeDigitK" xml:space="preserve">
    <value>千位</value>
  </data>
  <data name="typeDigitH" xml:space="preserve">
    <value>百位</value>
  </data>
  <data name="wIOURtnDigit" xml:space="preserve">
    <value>Marker回至</value>
  </data>
  <data name="typeOPERATETRANLST_Core" xml:space="preserve">
    <value>營運管理</value>
  </data>
  <data name="txtOutsideOperate" xml:space="preserve">
    <value>外來</value>
  </data>
  <data name="txtOutsideRefNo" xml:space="preserve">
    <value>派貨單號碼</value>
  </data>
  <data name="wOccupiedPercentage" xml:space="preserve">
    <value>已食貨(%)</value>
  </data>
  <data name="txtAddCapitalSMS" xml:space="preserve">
    <value>加彩訊息</value>
  </data>
  <data name="txtStartSMS" xml:space="preserve">
    <value>開局訊息</value>
  </data>
  <data name="typeACCOUNTINGRPT_ReportGrp" xml:space="preserve">
    <value>會計報表</value>
  </data>
  <data name="typeRBALANCESHEETSTANDARDREPORT_Report" xml:space="preserve">
    <value>資產負債表</value>
  </data>
  <data name="typeRPROFITANDLOSSREPORTSTANDARDREPORT_Report" xml:space="preserve">
    <value>損益表</value>
  </data>
  <data name="typeRPROFITANDLOSSREPORT_Report" xml:space="preserve">
    <value>什支表</value>
  </data>
  <data name="txtIsSummary" xml:space="preserve">
    <value>只顯示統計</value>
  </data>
  <data name="msgReadCardAgentChange" xml:space="preserve">
    <value>拍卡轉戶口</value>
  </data>
  <data name="txtRollingSMSUnderAgent" xml:space="preserve">
    <value>收下線訊息(轉碼及上下數)</value>
  </data>
  <data name="msgCreditExpire" xml:space="preserve">
    <value>信貸批額已到期</value>
  </data>
  <data name="typeAGENTCREDITEXPIRE_Core" xml:space="preserve">
    <value>信貸批額到期</value>
  </data>
  <data name="typeCREDITISDIRECTACCEXPIRERPT_Report" xml:space="preserve">
    <value>直接授信批額過期</value>
  </data>
  <data name="txtCRMGiftSetting" xml:space="preserve">
    <value>送禮/特批管理</value>
  </data>
  <data name="typeGIFTLST_Core" xml:space="preserve">
    <value>送禮/特批管理</value>
  </data>
  <data name="txtCRMGiftName" xml:space="preserve">
    <value>送禮/特批名稱</value>
  </data>
  <data name="typeGIFTDTL_Core" xml:space="preserve">
    <value>送禮/特批管理</value>
  </data>
  <data name="global_btnGameResult" xml:space="preserve">
    <value>結果訊息</value>
  </data>
  <data name="global_btnSearchAndAdd" xml:space="preserve">
    <value>搜尋及新增</value>
  </data>
  <data name="txtAdminMode" xml:space="preserve">
    <value>管理員模式</value>
  </data>
  <data name="txtBettingDate" xml:space="preserve">
    <value>投注日期</value>
  </data>
  <data name="txtCustRecentGameRefNo" xml:space="preserve">
    <value>客人最近5場記錄</value>
  </data>
  <data name="txtDrag" xml:space="preserve">
    <value>拖數</value>
  </data>
  <data name="txtGame" xml:space="preserve">
    <value>場次</value>
  </data>
  <data name="txtIsBPlayCutOff" xml:space="preserve">
    <value>B仔數(計到十位)</value>
  </data>
  <data name="txtNo" xml:space="preserve">
    <value>没有</value>
  </data>
  <data name="txtOperateSettleInfo_HKD" xml:space="preserve">
    <value>結算資料 (HKD)</value>
  </data>
  <data name="txtRouteList" xml:space="preserve">
    <value>路址</value>
  </data>
  <data name="txtSettleAmount" xml:space="preserve">
    <value>結算金額</value>
  </data>
  <data name="txtTax" xml:space="preserve">
    <value>稅</value>
  </data>
  <data name="txtYes" xml:space="preserve">
    <value>有</value>
  </data>
  <data name="typeOPERATETRANDTL_Core" xml:space="preserve">
    <value>營運記錄</value>
  </data>
  <data name="wCustBetRemark" xml:space="preserve">
    <value>投注特徵</value>
  </data>
  <data name="wGameSet" xml:space="preserve">
    <value>靴</value>
  </data>
  <data name="wIsAllowSubmitRatio" xml:space="preserve">
    <value>放置於手機應用程式派貨</value>
  </data>
  <data name="wIsMainIntroduce" xml:space="preserve">
    <value>計入公司來貨</value>
  </data>
  <data name="global_msgEmptyGameSetOrTableName" xml:space="preserve">
    <value>路址圖必須填上檯號及靴數</value>
  </data>
  <data name="global_msgErrOccupiedRatioLargerThanMultiply" xml:space="preserve">
    <value>佔成數不能大於拖數</value>
  </data>
  <data name="global_msgInfoHistoryRecoedIsFive" xml:space="preserve">
    <value>最多只可輸入5條記錄</value>
  </data>
  <data name="global_msgInfoMissingGunter" xml:space="preserve">
    <value>沒有輸入槍手資料</value>
  </data>
  <data name="global_msgInfoOperateMissingSite" xml:space="preserve">
    <value>需要揀選場地或輸入新場地名稱</value>
  </data>
  <data name="txtAddNewSite" xml:space="preserve">
    <value>新增場地</value>
  </data>
  <data name="wCreditBalance" xml:space="preserve">
    <value>額度結餘</value>
  </data>
  <data name="wIsOutside" xml:space="preserve">
    <value>派貨公司</value>
  </data>
  <data name="global_msgHelpIsAllowSubmitRatio" xml:space="preserve">
    <value>一經放於應用程式掛貨, 本地將不容許作出佔成修改。
如果應用程式未能處理所有貨量, 需要包底開場, 
請修改營運狀態為開場, 配置剩餘貨量予包底公司。</value>
  </data>
  <data name="txtOperateDelete" xml:space="preserve">
    <value>刪除營運結算</value>
  </data>
  <data name="txtOperateReSettle" xml:space="preserve">
    <value>營運重新結算</value>
  </data>
  <data name="txtOperateSettle" xml:space="preserve">
    <value>營運結算</value>
  </data>
  <data name="global_msgErrOperateSettleDateMustBeInput" xml:space="preserve">
    <value>結算日期必須輸入</value>
  </data>
  <data name="global_msgErrOperateStatusMustBeLeave" xml:space="preserve">
    <value>請確認有關場次已離場 或 已取消(未開場之場次必需取消)</value>
  </data>
  <data name="txtCRMGiftDtlSetting" xml:space="preserve">
    <value>送禮/特批副類型管理</value>
  </data>
  <data name="typeGIFTSUBLST_Core" xml:space="preserve">
    <value>送禮/特批副類型管理</value>
  </data>
  <data name="txtCRMGiftDtlName" xml:space="preserve">
    <value>送禮/特批副類型名稱</value>
  </data>
  <data name="typeGIFTSUBDTL_Core" xml:space="preserve">
    <value>送禮/特批副類型管理</value>
  </data>
  <data name="global_msgHasTranNotAllowToDel" xml:space="preserve">
    <value>因已被相關交易使用, 不可刪除</value>
  </data>
  <data name="txtCRMExpenseSetting" xml:space="preserve">
    <value>消費類型管理</value>
  </data>
  <data name="txtCRMExpenseDtlSetting" xml:space="preserve">
    <value>消費副類型管理</value>
  </data>
  <data name="txtCRMExpenseName" xml:space="preserve">
    <value>消費類型名稱</value>
  </data>
  <data name="txtCRMExpenseDtlName" xml:space="preserve">
    <value>消費副類型名稱</value>
  </data>
  <data name="typeEXPENSELST_Core" xml:space="preserve">
    <value>消費類型管理</value>
  </data>
  <data name="typeEXPENSEDTL_Core" xml:space="preserve">
    <value>消費類型管理</value>
  </data>
  <data name="typeCOUNTERDTL_Core" xml:space="preserve">
    <value>場館部門聯絡資料管理</value>
  </data>
  <data name="typeCOUNTERMAIN_Core" xml:space="preserve">
    <value>工作場所管理</value>
  </data>
  <data name="typeCOUNTER_Core" xml:space="preserve">
    <value>場館資料管理</value>
  </data>
  <data name="wChineseName" xml:space="preserve">
    <value>名稱(中)</value>
  </data>
  <data name="wContactType" xml:space="preserve">
    <value>聯絡類型</value>
  </data>
  <data name="wCounterCode" xml:space="preserve">
    <value>場館編號</value>
  </data>
  <data name="wDefaultHotel" xml:space="preserve">
    <value>預設酒店</value>
  </data>
  <data name="wEnglishName" xml:space="preserve">
    <value>名稱(英)</value>
  </data>
  <data name="wJapaneseName" xml:space="preserve">
    <value>名稱(日)</value>
  </data>
  <data name="wThaiName" xml:space="preserve">
    <value>名稱(泰)</value>
  </data>
  <data name="wKoreanName" xml:space="preserve">
    <value>名稱(韓)</value>
  </data>
  <data name="wTelOrEmail" xml:space="preserve">
    <value>電話號碼/電郵</value>
  </data>
  <data name="typeEXPENSESUBLST_Core" xml:space="preserve">
    <value>消費副類型管理</value>
  </data>
  <data name="typeEXPENSESUBDTL_Core" xml:space="preserve">
    <value>消費副類型管理</value>
  </data>
  <data name="global_msgRollTranRIDUsed" xml:space="preserve">
    <value>轉碼卡已經被使用了，使用者是</value>
  </data>
  <data name="txtRptComplex" xml:space="preserve">
    <value>綜合</value>
  </data>
  <data name="typeRFOLLOWERRPT_Report" xml:space="preserve">
    <value>跟單人報表</value>
  </data>
  <data name="typeFOLLOWERRPT_ReportGrp" xml:space="preserve">
    <value>跟單人報表</value>
  </data>
  <data name="txtSMSRoomID" xml:space="preserve">
    <value>短訊使用編號</value>
  </data>
  <data name="txtUnitedStates" xml:space="preserve">
    <value>美國</value>
  </data>
  <data name="txtItaly" xml:space="preserve">
    <value>意大利</value>
  </data>
  <data name="txtCambodia" xml:space="preserve">
    <value>柬埔寨</value>
  </data>
  <data name="txtMalaysia" xml:space="preserve">
    <value>馬來西亞</value>
  </data>
  <data name="txtVietnam" xml:space="preserve">
    <value>越南</value>
  </data>
  <data name="txtSingapore" xml:space="preserve">
    <value>新加坡</value>
  </data>
  <data name="txtCzechRepublic" xml:space="preserve">
    <value>捷克</value>
  </data>
  <data name="typePASSPORTISSUEDCOUNTRYDTL_Core" xml:space="preserve">
    <value>證件簽發地設定</value>
  </data>
  <data name="typePASSPORTISSUEDCOUNTRYLST_Core" xml:space="preserve">
    <value>證件簽發地管理</value>
  </data>
  <data name="typeCRMDASHBOARD_Core" xml:space="preserve">
    <value>CRM Dashboard</value>
  </data>
  <data name="txtToolTip_TotalCredit" xml:space="preserve">
    <value>總信貸額:
股本 + 月息 + 娛樂場額 + 信貨額 + U可簽額</value>
  </data>
  <data name="txtToolTip_TotalRealOutstanding" xml:space="preserve">
    <value>已簽額:
下線 扣後尚欠(對減 股本,月息,凍M) 累加至上線 
  
股本已簽額 + U已簽額 + 個人借貸 + 營運已簽額 + 海外已簽額
  
(*不包括* 營運/海外 - 未結算,暫存/未取)
  </value>
  </data>
  <data name="txtToolTip_TotalRealOutstanding_SO" xml:space="preserve">
    <value>股本已簽額:
  股本 + 股本M + 批額 +  凍結柴出M + 月息 + 月息M
  </value>
  </data>
  <data name="txtToolTip_TotalRealOutstanding_IO" xml:space="preserve">
    <value>U已簽額:
公司U + IOU
  </value>
  </data>
  <data name="txtToolTip_TotalRealOutstanding_Y" xml:space="preserve">
    <value>營運已簽額:
*不包括* 未結算,暫存/未取
  </value>
  </data>
  <data name="txtToolTip_TotalRealOutstanding_F" xml:space="preserve">
    <value>海外已簽額:
*不包括* 未結算,暫存/未取
  </value>
  </data>
  <data name="txtToolTip_EXPCREDITAMT" xml:space="preserve">
    <value>消費信用額:
1. 當沒有Marker的時候：股本ｘ５％ ＋ 當月未提取月息利息ｘ１００％ + 批額ｘ２％
2. 當有Marker [已用月息轉碼]但沒有過期M的時候：股本ｘ５％＋批額ｘ２％+當月未提取月息利息ｘ１００％
3. 當有過期M的時候: (批額＋股本＋月息存款－過期M-U可簽M)ｘ２％
註明：批額包括Ｕ額＋營運額
  </value>
  </data>
  <data name="global_msgOperateSettleDeleted" xml:space="preserve">
    <value>營運結算已刪除</value>
  </data>
  <data name="global_msgOperateSettleSuccess" xml:space="preserve">
    <value>營運結算完成</value>
  </data>
  <data name="global_msgCantUseAdminModeWhenUseApps" xml:space="preserve">
    <value>不能修改已經手機掛貨的單。</value>
  </data>
  <data name="global_msgErrRollAmtCantLessThanlossAmt" xml:space="preserve">
    <value>客下，轉碼數不能少於客下數</value>
  </data>
  <data name="wFirstGameTranDate" xml:space="preserve">
    <value>首場時間</value>
  </data>
  <data name="wLastGameTranDate" xml:space="preserve">
    <value>尾場時間</value>
  </data>
  <data name="typeLOOKUPLST_RELATE_Core" xml:space="preserve">
    <value>關係類別管理</value>
  </data>
  <data name="typeLOOKUPDTL_RELATE_Core" xml:space="preserve">
    <value>關係類別管理</value>
  </data>
  <data name="typeDEPTSHIFTLST_Core" xml:space="preserve">
    <value>部門更期管理</value>
  </data>
  <data name="typeDEPTSHIFTDTL_Core" xml:space="preserve">
    <value>部門更期管理</value>
  </data>
  <data name="txtDeptShift" xml:space="preserve">
    <value>部門更期管理</value>
  </data>
  <data name="txtWarnMsgInstantBPlay" xml:space="preserve">
    <value>B數碼存在, 是否使用預設 - 即出咭</value>
  </data>
  <data name="typeMarkerDtlV2_Core" xml:space="preserve">
    <value>綜合借貸</value>
  </data>
  <data name="typeMarkerActionType_IOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="typeMarkerActionType_HOLDSTORE" xml:space="preserve">
    <value>凍結卡錢</value>
  </data>
  <data name="typeMarkerActionType_HOLDCOMM" xml:space="preserve">
    <value>凍結佣金</value>
  </data>
  <data name="typeMarkerActionType_HOLDMAXIOU" xml:space="preserve">
    <value>凍M出M</value>
  </data>
  <data name="txtHoldAmount" xml:space="preserve">
    <value>凍結金額</value>
  </data>
  <data name="wHoldStoreRate" xml:space="preserve">
    <value>凍卡出M 匯率</value>
  </data>
  <data name="wAvailableAmt" xml:space="preserve">
    <value>可動用結存</value>
  </data>
  <data name="txtBookAndSMS" xml:space="preserve">
    <value>訂務及訊息</value>
  </data>
  <data name="txtBookingSMS" xml:space="preserve">
    <value>訂務訊息</value>
  </data>
  <data name="txtStopAllBookingSMS" xml:space="preserve">
    <value>所有訂務停發</value>
  </data>
  <data name="typeAGENTSMSDTL_Core" xml:space="preserve">
    <value>訊息及訂務設定</value>
  </data>
  <data name="typeAGENTSMSLST_Core" xml:space="preserve">
    <value>訊息及訂務管理</value>
  </data>
  <data name="wCheckIn" xml:space="preserve">
    <value>登機服務</value>
  </data>
  <data name="wHelicopter" xml:space="preserve">
    <value>直升機</value>
  </data>
  <data name="wHotel" xml:space="preserve">
    <value>酒店/房間</value>
  </data>
  <data name="wOtherExp" xml:space="preserve">
    <value>其他消費</value>
  </data>
  <data name="wPlane" xml:space="preserve">
    <value>飛機票</value>
  </data>
  <data name="wRestaurant" xml:space="preserve">
    <value>餐廳</value>
  </data>
  <data name="wRoomExp" xml:space="preserve">
    <value>房間消費</value>
  </data>
  <data name="wRoomKey" xml:space="preserve">
    <value>房間取匙</value>
  </data>
  <data name="wShip" xml:space="preserve">
    <value>船票</value>
  </data>
  <data name="wTicket" xml:space="preserve">
    <value>門票</value>
  </data>
  <data name="wVehicle" xml:space="preserve">
    <value>車務</value>
  </data>
  <data name="wWarmRemind" xml:space="preserve">
    <value>温馨提示</value>
  </data>
  <data name="txtAchievements" xml:space="preserve">
    <value>業績</value>
  </data>
  <data name="txtRollCountRank" xml:space="preserve">
    <value>入場次數排名</value>
  </data>
  <data name="txtCustCountRank" xml:space="preserve">
    <value>入場客量排名</value>
  </data>
  <data name="txtTopPlaceCapitalHKD" xml:space="preserve">
    <value>最高入場金額HKD</value>
  </data>
  <data name="txtAverageCapitalHKD" xml:space="preserve">
    <value>平均入場金額HKD</value>
  </data>
  <data name="txtAveragePlaceStayTime" xml:space="preserve">
    <value>平均留枱時間</value>
  </data>
  <data name="typeLOOKUPDTL_PASSPORTTYPE_Core" xml:space="preserve">
    <value>證件類別設定</value>
  </data>
  <data name="typeLOOKUPDTL_SUPPLIER_Core" xml:space="preserve">
    <value>供應商設定</value>
  </data>
  <data name="typeLOOKUPLST_PASSPORTTYPE_Core" xml:space="preserve">
    <value>證件類別管理</value>
  </data>
  <data name="typeLOOKUPLST_SUPPLIER_Core" xml:space="preserve">
    <value>供應商管理</value>
  </data>
  <data name="global_msgErrOperateQuitBeforeStart" xml:space="preserve">
    <value>營運單未發開場訊息, 不能離場, 請聯絡營運同事</value>
  </data>
  <data name="typeAGENTFOLLOWUPLST_Core" xml:space="preserve">
    <value>戶口跟進組別管理</value>
  </data>
  <data name="typeAGENTFOLLOWUPDTL_Core" xml:space="preserve">
    <value>戶口跟進組別管理</value>
  </data>
  <data name="txtAgentFollowUp" xml:space="preserve">
    <value>戶口跟進組別管理</value>
  </data>
  <data name="wIsDenyContact" xml:space="preserve">
    <value>拒絕聯絡</value>
  </data>
  <data name="typePARENTCHILDDTL_HABIT_Core" xml:space="preserve">
    <value>喜好類別設定</value>
  </data>
  <data name="typePARENTCHILDLST_HABIT_Core" xml:space="preserve">
    <value>喜好類別管理</value>
  </data>
  <data name="wChildType" xml:space="preserve">
    <value>副類型</value>
  </data>
  <data name="wHabit" xml:space="preserve">
    <value>喜好</value>
  </data>
  <data name="typeLOOKUPDTL_CUISINE_Core" xml:space="preserve">
    <value>菜式類型設定</value>
  </data>
  <data name="typeLOOKUPLST_CUISINE_Core" xml:space="preserve">
    <value>菜式類型管理</value>
  </data>
  <data name="typeLOOKUPDTL_COUNTERDAILY_Core" xml:space="preserve">
    <value>場館日誌類別設定</value>
  </data>
  <data name="typeLOOKUPLST_COUNTERDAILY_Core" xml:space="preserve">
    <value>場館日誌類別管理</value>
  </data>
  <data name="typeLOOKUPDTL_MESSAGEMETHOD_Core" xml:space="preserve">
    <value>接收訊息方式設定</value>
  </data>
  <data name="typeLOOKUPLST_MESSAGEMETHOD_Core" xml:space="preserve">
    <value>接收訊息方式管理</value>
  </data>
  <data name="txtNumberOfTimesShort" xml:space="preserve">
    <value>次</value>
  </data>
  <data name="typeSHOPLST_RESTAURANT_Core" xml:space="preserve">
    <value>餐廳資料管理</value>
  </data>
  <data name="typeSHOPDTL_RESTAURANT_Core" xml:space="preserve">
    <value>餐廳資料管理</value>
  </data>
  <data name="typeSHOPLST_SPA_Core" xml:space="preserve">
    <value>SPA資料管理</value>
  </data>
  <data name="typeSHOPDTL_SPA_Core" xml:space="preserve">
    <value>SPA資料管理</value>
  </data>
  <data name="wOpenHour" xml:space="preserve">
    <value>營業時間</value>
  </data>
  <data name="wClass" xml:space="preserve">
    <value>級別</value>
  </data>
  <data name="wMenu" xml:space="preserve">
    <value>菜單</value>
  </data>
  <data name="wIsBTM" xml:space="preserve">
    <value>BTM</value>
  </data>
  <data name="wIsCreditPay" xml:space="preserve">
    <value>簽單</value>
  </data>
  <data name="wSeat" xml:space="preserve">
    <value>坐位數</value>
  </data>
  <data name="wMinCharge" xml:space="preserve">
    <value>最低消費</value>
  </data>
  <data name="txtMealStyle" xml:space="preserve">
    <value>菜式</value>
  </data>
  <data name="global_txtAmount100000k" xml:space="preserve">
    <value>金額(億)</value>
  </data>
  <data name="typeLOOKUPLST_CASINOCARD_Core" xml:space="preserve">
    <value>賭場卡類別管理</value>
  </data>
  <data name="typeLOOKUPDTL_CASINOCARD_Core" xml:space="preserve">
    <value>賭場卡類別管理</value>
  </data>
  <data name="txtPhoneResposeDate" xml:space="preserve">
    <value>回電日期</value>
  </data>
  <data name="txtAppointmentDate" xml:space="preserve">
    <value>約見日期</value>
  </data>
  <data name="txtSolutionExpDate" xml:space="preserve">
    <value>方案到期日</value>
  </data>
  <data name="wMaxIOULoanDay" xml:space="preserve">
    <value>天期</value>
  </data>
  <data name="wTotIOULoanAmount" xml:space="preserve">
    <value>金額</value>
  </data>
  <data name="typePARENTCHILDDTL_DAILYTASK_Core" xml:space="preserve">
    <value>工作日誌類型設定</value>
  </data>
  <data name="typePARENTCHILDDTL_INCOMPLIANCEREASON_Core" xml:space="preserve">
    <value>不達標原因設定</value>
  </data>
  <data name="typePARENTCHILDLST_DAILYTASK_Core" xml:space="preserve">
    <value>工作日誌類型管理</value>
  </data>
  <data name="typePARENTCHILDLST_INCOMPLIANCEREASON_Core" xml:space="preserve">
    <value>不達標原因管理</value>
  </data>
  <data name="wDailyTask" xml:space="preserve">
    <value>工作日誌</value>
  </data>
  <data name="wIncomplianceReason" xml:space="preserve">
    <value>不達標原因</value>
  </data>
  <data name="wParentType" xml:space="preserve">
    <value>類型</value>
  </data>
  <data name="typeCASINOCARDLST_Core" xml:space="preserve">
    <value>賭場卡管理</value>
  </data>
  <data name="typeCASINOCARDDTL_Core" xml:space="preserve">
    <value>賭場卡管理</value>
  </data>
  <data name="txtCasinoCardName" xml:space="preserve">
    <value>賭場卡類別</value>
  </data>
  <data name="txtCustAuthName" xml:space="preserve">
    <value>客人/受權人名稱</value>
  </data>
  <data name="txtProcesSuccess" xml:space="preserve">
    <value>處理成功</value>
  </data>
  <data name="txtFailPlan" xml:space="preserve">
    <value>方案失敗</value>
  </data>
  <data name="txtOnlyInterest" xml:space="preserve">
    <value>只有利息戶口顯示</value>
  </data>
  <data name="txtSpending" xml:space="preserve">
    <value>簽賬</value>
  </data>
  <data name="txtSpendingC" xml:space="preserve">
    <value>簽賬(公U)</value>
  </data>
  <data name="txtShortFormCapital" xml:space="preserve">
    <value>股</value>
  </data>
  <data name="txtShortFormMthInt" xml:space="preserve">
    <value>月</value>
  </data>
  <data name="txtShortFormCash" xml:space="preserve">
    <value>現</value>
  </data>
  <data name="txtShortFormCredit" xml:space="preserve">
    <value>批</value>
  </data>
  <data name="txtUsed" xml:space="preserve">
    <value>已用</value>
  </data>
  <data name="txtRemain" xml:space="preserve">
    <value>未用</value>
  </data>
  <data name="txtSettleTranInstant" xml:space="preserve">
    <value>即出數</value>
  </data>
  <data name="txtRollCapitalRank" xml:space="preserve">
    <value>轉碼排名</value>
  </data>
  <data name="txtRollCapitalFlow" xml:space="preserve">
    <value>轉碼走勢</value>
  </data>
  <data name="txtRollingProportion" xml:space="preserve">
    <value>類型分佈</value>
  </data>
  <data name="txtCRMFollowList" xml:space="preserve">
    <value>跟進事項</value>
  </data>
  <data name="txtCRMAgentActivity" xml:space="preserve">
    <value>互動紀錄</value>
  </data>
  <data name="txtCRMAgentAnalyze" xml:space="preserve">
    <value>戶口分析</value>
  </data>
  <data name="txtCRMTotalCredit" xml:space="preserve">
    <value>總批額</value>
  </data>
  <data name="txtCRMAvaibleCredit" xml:space="preserve">
    <value>可用批額</value>
  </data>
  <data name="txtCRMOutstandingAmt" xml:space="preserve">
    <value>已借之金額</value>
  </data>
  <data name="txtCRMOverdueOutstandingAmt" xml:space="preserve">
    <value>已過期之金額</value>
  </data>
  <data name="txtCRMFreezeAmt" xml:space="preserve">
    <value>已凍結之金額</value>
  </data>
  <data name="txtCRMLastIOUDate" xml:space="preserve">
    <value>最近借貸日期</value>
  </data>
  <data name="txtCRMLastOverdueDate" xml:space="preserve">
    <value>最近過期日期</value>
  </data>
  <data name="txtCRMFreezeDay" xml:space="preserve">
    <value>已凍結天數</value>
  </data>
  <data name="txtCRMOverduePercentage" xml:space="preserve">
    <value>過期次數比例</value>
  </data>
  <data name="txtCRMAvgOverdueDay" xml:space="preserve">
    <value>平均過期天數</value>
  </data>
  <data name="txtCRMMaxOverdueDay" xml:space="preserve">
    <value>最長過期天數</value>
  </data>
  <data name="txtCRMCreditInfo" xml:space="preserve">
    <value>信貸</value>
  </data>
  <data name="txtCRMRollingA" xml:space="preserve">
    <value>A</value>
  </data>
  <data name="txtCRMRollingB" xml:space="preserve">
    <value>B</value>
  </data>
  <data name="txtCRMRollingTelB" xml:space="preserve">
    <value>電</value>
  </data>
  <data name="txtCRMOperate" xml:space="preserve">
    <value>營</value>
  </data>
  <data name="txtCRMForeign" xml:space="preserve">
    <value>海</value>
  </data>
  <data name="txtCRMAgentAndSubLine" xml:space="preserve">
    <value>戶口 + 下線</value>
  </data>
  <data name="txtCRMAgentRollingFlow" xml:space="preserve">
    <value>6個月轉碼走勢</value>
  </data>
  <data name="txt_msgSelectError" xml:space="preserve">
    <value>方案達標與不達標, 不能同時選擇</value>
  </data>
  <data name="txtCompliance" xml:space="preserve">
    <value>達標</value>
  </data>
  <data name="typeCOUNTERSHIFTDTL_Core" xml:space="preserve">
    <value>交更記錄</value>
  </data>
  <data name="typeCOUNTERSHIFTLST_Core" xml:space="preserve">
    <value>交更記錄</value>
  </data>
  <data name="txtCRMCounterName" xml:space="preserve">
    <value>場館名稱</value>
  </data>
  <data name="global_msgNotAcceptMessage" xml:space="preserve">
    <value>不可接受</value>
  </data>
  <data name="global_msgErrOperateSettleFail" xml:space="preserve">
    <value>營運結算失敗</value>
  </data>
  <data name="global_msgErrOperateWrongRatio" xml:space="preserve">
    <value>拖數與佔成數不符</value>
  </data>
  <data name="global_msgPlsInputSettleRollingAndWinLossAmt" xml:space="preserve">
    <value>請輸入計算轉碼及輸贏數</value>
  </data>
  <data name="typePOPUPOPERATECOMPSHARELST_Core" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="typePOPUPROUTELST_Core" xml:space="preserve">
    <value>路址</value>
  </data>
  <data name="typeAUTHCUSTHABITDTL_Core" xml:space="preserve">
    <value>客人/授權人喜好表記錄設定</value>
  </data>
  <data name="typeAUTHCUSTHABITLST_Core" xml:space="preserve">
    <value>客人/授權人喜好表記錄管理</value>
  </data>
  <data name="wCounterDiaryType" xml:space="preserve">
    <value>場館日誌類別管理</value>
  </data>
  <data name="Place_txtShareGame" xml:space="preserve">
    <value>股東自賭</value>
  </data>
  <data name="Place_txtGambleTableUp" xml:space="preserve">
    <value>賭枱升紅</value>
  </data>
  <data name="global_txtCentroidPersonCheck" xml:space="preserve">
    <value>博彩信貸資料庫資料</value>
  </data>
  <data name="typeDIARYLST_COUNTER_Core" xml:space="preserve">
    <value>場館日誌管理</value>
  </data>
  <data name="typeDIARYDTL_COUNTER_Core" xml:space="preserve">
    <value>場館日誌設定</value>
  </data>
  <data name="wCounterDiary" xml:space="preserve">
    <value>場館日誌</value>
  </data>
  <data name="wCreateCName" xml:space="preserve">
    <value>建立人</value>
  </data>
  <data name="txtContent" xml:space="preserve">
    <value>內容</value>
  </data>
  <data name="txtUnHandle" xml:space="preserve">
    <value>未處理</value>
  </data>
  <data name="txtHandled" xml:space="preserve">
    <value>已處理</value>
  </data>
  <data name="wCaseDate" xml:space="preserve">
    <value>發案時間</value>
  </data>
  <data name="wIsHighPriority" xml:space="preserve">
    <value>高度重視事件</value>
  </data>
  <data name="txtCRMClosed" xml:space="preserve">
    <value>已關閉</value>
  </data>
  <data name="global_msgInfoNotAllow" xml:space="preserve">
    <value>禁止 {0}</value>
  </data>
  <data name="typeCRMMASTER_Core" xml:space="preserve">
    <value>基本管理</value>
  </data>
  <data name="typeCRMBOOKING_Core" xml:space="preserve">
    <value>票務管理</value>
  </data>
  <data name="typeCRMREPORT_Core" xml:space="preserve">
    <value>報表</value>
  </data>
  <data name="typeCRMMARKETING_Core" xml:space="preserve">
    <value>市場及推廣管理</value>
  </data>
  <data name="typeCRMOTHER_Core" xml:space="preserve">
    <value>其他管理</value>
  </data>
  <data name="txtNoPlan" xml:space="preserve">
    <value>沒有方案</value>
  </data>
  <data name="txtHasPlan" xml:space="preserve">
    <value>有方案</value>
  </data>
  <data name="typeLOOKUPLST_POINTTYPE_Core" xml:space="preserve">
    <value>積分類型管理</value>
  </data>
  <data name="typeLOOKUPDTL_POINTTYPE_Core" xml:space="preserve">
    <value>積分類型管理</value>
  </data>
  <data name="typeLOOKUPLST_APPOINTTYPE_Core" xml:space="preserve">
    <value>約會類別管理</value>
  </data>
  <data name="typeLOOKUPDTL_APPOINTTYPE_Core" xml:space="preserve">
    <value>約會類別管理</value>
  </data>
  <data name="typeLOOKUPLST_APPOINTISSUE_Core" xml:space="preserve">
    <value>約會議題類型管理</value>
  </data>
  <data name="typeLOOKUPDTL_APPOINTISSUE_Core" xml:space="preserve">
    <value>約會議題類型管理</value>
  </data>
  <data name="wTitle" xml:space="preserve">
    <value>標題</value>
  </data>
  <data name="wRelateToName" xml:space="preserve">
    <value>涉及人物</value>
  </data>
  <data name="Agent_txtCapitalType" xml:space="preserve">
    <value>本</value>
  </data>
  <data name="Agent_txtGameType" xml:space="preserve">
    <value>場</value>
  </data>
  <data name="Agent_txtCapitalPlayer" xml:space="preserve">
    <value>玩家本金</value>
  </data>
  <data name="Agent_txtCapitalAgent" xml:space="preserve">
    <value>代理本金</value>
  </data>
  <data name="Agent_txtGamePlayer" xml:space="preserve">
    <value>玩家場次</value>
  </data>
  <data name="Agent_txtGameAgent" xml:space="preserve">
    <value>代理場次</value>
  </data>
  <data name="typeOPERATESETTLE_Core" xml:space="preserve">
    <value>營運結算</value>
  </data>
  <data name="typePOPUPBYOPERATEITEM_Core" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="Agent_txtCreditRollRatio" xml:space="preserve">
    <value>轉碼/批額比率</value>
  </data>
  <data name="typeAGENTREQUESTSETLST_Core" xml:space="preserve">
    <value>股東上/下線服務管理</value>
  </data>
  <data name="typeAGENTREQUESTSETDTL_Core" xml:space="preserve">
    <value>股東上/下線服務管理</value>
  </data>
  <data name="txtCRM_ServiceNeeded" xml:space="preserve">
    <value>選擇提供之服務</value>
  </data>
  <data name="txtCRM_ServiceProvidedByBusiness" xml:space="preserve">
    <value>選擇提供予下線之服務</value>
  </data>
  <data name="txtCRM_ServiceProvidedByDesignatedAccount" xml:space="preserve">
    <value>選擇提供予特別戶口之服務</value>
  </data>
  <data name="txtCRM_NoticeMethod" xml:space="preserve">
    <value>選擇通知之方式</value>
  </data>
  <data name="wIsAppointmentAlert" xml:space="preserve">
    <value>提示下線之要求約見老闆</value>
  </data>
  <data name="wIsDOBAlert" xml:space="preserve">
    <value>提示下線生日</value>
  </data>
  <data name="wIsJoinEventAlert" xml:space="preserve">
    <value>提示下線所參加之活動</value>
  </data>
  <data name="wIsEntertainmentAlert" xml:space="preserve">
    <value>提示下線將獲邀之應酬</value>
  </data>
  <data name="wIsBenefitAlert" xml:space="preserve">
    <value>提示下線所獲得之禮遇 </value>
  </data>
  <data name="wIsPerformanceRpt" xml:space="preserve">
    <value>提供下線之業績報表</value>
  </data>
  <data name="wIsConsumptionRpt" xml:space="preserve">
    <value>提供下線之消費報表</value>
  </data>
  <data name="wIsRepaymentStatus" xml:space="preserve">
    <value>提供下線之還款狀況</value>
  </data>
  <data name="wIsDinnerParty" xml:space="preserve">
    <value>安排生日飯局及生日禮物 </value>
  </data>
  <data name="wIsGift" xml:space="preserve">
    <value>業績達標送禮（包括積分/長房/禮品等）</value>
  </data>
  <data name="CRM_ByAgent" xml:space="preserve">
    <value>您的名義</value>
  </data>
  <data name="CRM_ByComp" xml:space="preserve">
    <value>公司名義</value>
  </data>
  <data name="wIsEventInvitation" xml:space="preserve">
    <value>活動邀請</value>
  </data>
  <data name="wIs24HrsAssistant" xml:space="preserve">
    <value>24 小時助理團隊（卓越以上客戶）</value>
  </data>
  <data name="wIsLimoService" xml:space="preserve">
    <value>勞斯萊斯接送服務</value>
  </data>
  <data name="txtSpecAgent" xml:space="preserve">
    <value>特別戶口</value>
  </data>
  <data name="typeAGENTMEMBERSHIPINFODTL_Core" xml:space="preserve">
    <value>戶口會藉部相關資料設定</value>
  </data>
  <data name="typeAGENTMEMBERSHIPINFOLST_Core" xml:space="preserve">
    <value>戶口會藉部相關資料管理</value>
  </data>
  <data name="wAutoPayAuthLetter" xml:space="preserve">
    <value>自動轉帳授權書</value>
  </data>
  <data name="wCardValidFrom" xml:space="preserve">
    <value>換卡日期</value>
  </data>
  <data name="wDoNotDistrubList" xml:space="preserve">
    <value>不打擾名單</value>
  </data>
  <data name="wDownloadSunCityApp" xml:space="preserve">
    <value>下載太陽城APP</value>
  </data>
  <data name="wFirstChoiceMessage" xml:space="preserve">
    <value>首選收訊息方式</value>
  </data>
  <data name="wIntroSunChat" xml:space="preserve">
    <value>介紹SUN CHAT</value>
  </data>
  <data name="wMembershipClubRemark" xml:space="preserve">
    <value>會藉部備註</value>
  </data>
  <data name="wSubscribeSunCity" xml:space="preserve">
    <value>關注太陽城訂閱號</value>
  </data>
  <data name="typePARENTCHILDLST_PROGRAMMETYPE_Core" xml:space="preserve">
    <value>節目類型管理</value>
  </data>
  <data name="wProgramme" xml:space="preserve">
    <value>節目</value>
  </data>
  <data name="typePARENTCHILDDTL_PROGRAMMETYPE_Core" xml:space="preserve">
    <value>節目類型設定</value>
  </data>
  <data name="typePARENTCHILDDTL_GROUPOPINIONTYPE_Core" xml:space="preserve">
    <value>集團意見類型設定</value>
  </data>
  <data name="typePARENTCHILDLST_GROUPOPINIONTYPE_Core" xml:space="preserve">
    <value>集團意見類型管理</value>
  </data>
  <data name="wGroupOpinion" xml:space="preserve">
    <value>集團意見</value>
  </data>
  <data name="msgMustMatchUpLevelGroupNo" xml:space="preserve">
    <value>戶口組號(開始格式), 必須與上線相同{0}</value>
  </data>
  <data name="msgMustAlpha_AfterUpLevelGroupNo" xml:space="preserve">
    <value>戶口組號(開始格式)尾後一個位, 必須是英文字</value>
  </data>
  <data name="wCasinoWinLossAmt" xml:space="preserve">
    <value>公務數(萬)</value>
  </data>
  <data name="wTelBRollingAmt" xml:space="preserve">
    <value>電投轉碼數(萬)</value>
  </data>
  <data name="typeCOMPWINLOSSTRANLST_Core" xml:space="preserve">
    <value>賭場上下數管理</value>
  </data>
  <data name="typeCOMPWINLOSSTRANDTL_Core" xml:space="preserve">
    <value>賭場上下數詳細</value>
  </data>
  <data name="SMS_EXPDAILY_COMPLEX" xml:space="preserve">
    <value>(新)每日集團消費報表</value>
  </data>
  <data name="msgBeginAgentNoMustBeAlpha" xml:space="preserve">
    <value>[下線編號]開始必須是英文字</value>
  </data>
  <data name="global_msgErrOverSettlePenaltyAmount" xml:space="preserve">
    <value>還息金額過大</value>
  </data>
  <data name="typeWORKDIARYDTL_Core" xml:space="preserve">
    <value>工作日誌設定</value>
  </data>
  <data name="typeWORKDIARYLST_Core" xml:space="preserve">
    <value>工作日誌管理</value>
  </data>
  <data name="wWorkDiary" xml:space="preserve">
    <value>工作日誌</value>
  </data>
  <data name="wBusinessContent" xml:space="preserve">
    <value>業務內容</value>
  </data>
  <data name="wBusinessContentDetail" xml:space="preserve">
    <value>業務內容詳細資料</value>
  </data>
  <data name="wCounterAgent" xml:space="preserve">
    <value>場館及戶口</value>
  </data>
  <data name="wJobDescription" xml:space="preserve">
    <value>工作描述</value>
  </data>
  <data name="wResident" xml:space="preserve">
    <value>駐場</value>
  </data>
  <data name="typeAUTHCUSTRELATIONSHIPDTL_Core" xml:space="preserve">
    <value>客人/授權人之間的關係記錄設定</value>
  </data>
  <data name="typeAUTHCUSTRELATIONSHIPLST_Core" xml:space="preserve">
    <value>客人/授權人之間的關係記錄管理</value>
  </data>
  <data name="wAgentOrCust1" xml:space="preserve">
    <value>客人/授權人1</value>
  </data>
  <data name="wAgentOrCust2" xml:space="preserve">
    <value>客人/授權人2</value>
  </data>
  <data name="wHoldIOUAmount_10K" xml:space="preserve">
    <value>凍柴(萬)</value>
  </data>
  <data name="wHoldIOUOutstanding_10K" xml:space="preserve">
    <value>凍柴倘欠(萬)</value>
  </data>
  <data name="typeCOMPWINLOSSRPT_ReportGrp" xml:space="preserve">
    <value>賭場上下數報表</value>
  </data>
  <data name="txt_DailyCompWinLossReport" xml:space="preserve">
    <value>貴賓會每天上下水數表</value>
  </data>
  <data name="typeRCOMPWINLOSSRPT_Report" xml:space="preserve">
    <value>賭場上下數報表</value>
  </data>
  <data name="txtCRMPier" xml:space="preserve">
    <value>船票航線地點管理</value>
  </data>
  <data name="typePIERLST_Core" xml:space="preserve">
    <value>船票航線地點管理</value>
  </data>
  <data name="typePIERDTL_Core" xml:space="preserve">
    <value>船票航線地點管理</value>
  </data>
  <data name="txtCRMChiName" xml:space="preserve">
    <value>名稱(中)</value>
  </data>
  <data name="txtCRMEngName" xml:space="preserve">
    <value>名稱(英)</value>
  </data>
  <data name="txtCRMJpnName" xml:space="preserve">
    <value>名稱(日)</value>
  </data>
  <data name="txtCRMKorName" xml:space="preserve">
    <value>名稱(韓)</value>
  </data>
  <data name="txtCRMThaName" xml:space="preserve">
    <value>名稱(泰)</value>
  </data>
  <data name="global_msgErrOpCompCreditSmallerThanZero" xml:space="preserve">
    <value>保證金額必須大於零</value>
  </data>
  <data name="typeOPERATINGPLACEAPPROVAL_Core" xml:space="preserve">
    <value>營運確認(New Db Flow)</value>
  </data>
  <data name="typeLOOKUPLST_SHIP_TICKETTYPE_Core" xml:space="preserve">
    <value>船票票類管理</value>
  </data>
  <data name="typeLOOKUPDTL_SHIP_TICKETTYPE_Core" xml:space="preserve">
    <value>船票票類管理</value>
  </data>
  <data name="wCountry" xml:space="preserve">
    <value>國家</value>
  </data>
  <data name="typeAUTHCUSTPASSPORTDTL_Core" xml:space="preserve">
    <value>客人/授權人等旅遊證件記錄設定</value>
  </data>
  <data name="typeAUTHCUSTPASSPORTLST_Core" xml:space="preserve">
    <value>客人/授權人等旅遊證件記錄管理</value>
  </data>
  <data name="wPassportType" xml:space="preserve">
    <value>證件類別</value>
  </data>
  <data name="wENamePinYin" xml:space="preserve">
    <value>英文名字拼音</value>
  </data>
  <data name="wIssuedLocation" xml:space="preserve">
    <value>簽發地</value>
  </data>
  <data name="wValidUntil" xml:space="preserve">
    <value>有效期至</value>
  </data>
  <data name="typeUCPHOTOENLARGE_Core" xml:space="preserve">
    <value>圖片管理</value>
  </data>
  <data name="txtCRMShipRoute" xml:space="preserve">
    <value>船票航線管理</value>
  </data>
  <data name="typeSHIPROUTELST_Core" xml:space="preserve">
    <value>船票航線管理</value>
  </data>
  <data name="typeSHIPROUTEDTL_Core" xml:space="preserve">
    <value>船票航線管理</value>
  </data>
  <data name="txtSingleWay" xml:space="preserve">
    <value>單程</value>
  </data>
  <data name="txtRoundTrip" xml:space="preserve">
    <value>來回</value>
  </data>
  <data name="txtCRMRouteName" xml:space="preserve">
    <value>航線</value>
  </data>
  <data name="txtCRMDepartName" xml:space="preserve">
    <value>出發地</value>
  </data>
  <data name="txtCRMArriveName" xml:space="preserve">
    <value>目的地</value>
  </data>
  <data name="msgNotAllowInSame" xml:space="preserve">
    <value>不可相同</value>
  </data>
  <data name="msgDuplicatedRec" xml:space="preserve">
    <value>已有相同紀錄</value>
  </data>
  <data name="txtTickTypeName" xml:space="preserve">
    <value>價目類</value>
  </data>
  <data name="txtTickPrice" xml:space="preserve">
    <value>票價</value>
  </data>
  <data name="typeSHIPTICKPRICELST_Core" xml:space="preserve">
    <value>船票航線票價管理</value>
  </data>
  <data name="typeSHIPTICKPRICEDTL_Core" xml:space="preserve">
    <value>船票航線票價管理</value>
  </data>
  <data name="msgNotAllowLessThanZero" xml:space="preserve">
    <value>不可少於零</value>
  </data>
  <data name="txtSit" xml:space="preserve">
    <value>坐位</value>
  </data>
  <data name="txtStand" xml:space="preserve">
    <value>企位</value>
  </data>
  <data name="typeLOOKUPDTL_CORPORATE_Core" xml:space="preserve">
    <value>廳團設定</value>
  </data>
  <data name="typeLOOKUPLST_CORPORATE_Core" xml:space="preserve">
    <value>廳團管理</value>
  </data>
  <data name="msgOverCredit" xml:space="preserve">
    <value>所借金額已超出限額</value>
  </data>
  <data name="typeTICKETLST_Core" xml:space="preserve">
    <value>船票紀錄</value>
  </data>
  <data name="typeTICKETDTL_Core" xml:space="preserve">
    <value>船票紀錄</value>
  </data>
  <data name="wIssueLocationName" xml:space="preserve">
    <value>船票發放地點</value>
  </data>
  <data name="wTicketNo" xml:space="preserve">
    <value>票編號</value>
  </data>
  <data name="wExchangeName" xml:space="preserve">
    <value>兌換名稱</value>
  </data>
  <data name="typeLOOKUPDTL_HELIBOOKINGLOC_Core" xml:space="preserve">
    <value>直升機票訂票地點設定</value>
  </data>
  <data name="typeLOOKUPLST_HELIBOOKINGLOC_Core" xml:space="preserve">
    <value>直升機票訂票地點管理</value>
  </data>
  <data name="txtTicketNoPrefix" xml:space="preserve">
    <value>票號首字</value>
  </data>
  <data name="txtStartTicketNo" xml:space="preserve">
    <value>票號開始編號</value>
  </data>
  <data name="txtEndTicketNo" xml:space="preserve">
    <value>票號最後編號</value>
  </data>
  <data name="txtShowNotUsed" xml:space="preserve">
    <value>未使用</value>
  </data>
  <data name="msgDeptNoRequired" xml:space="preserve">
    <value>必需輸入部門</value>
  </data>
  <data name="msgDuplicate_IOUSource" xml:space="preserve">
    <value>借貸來源重覆</value>
  </data>
  <data name="txtCasinoWinLossAmt" xml:space="preserve">
    <value>公務數</value>
  </data>
  <data name="txtBuyChipAmt" xml:space="preserve">
    <value>買碼數</value>
  </data>
  <data name="global_msgErrMinLargerThanMax" xml:space="preserve">
    <value>{0}必須大於{1}</value>
  </data>
  <data name="global_msgErrRepeated" xml:space="preserve">
    <value>{0}已存在</value>
  </data>
  <data name="typeVOUCHERDTL_Core" xml:space="preserve">
    <value>消費券記錄設定</value>
  </data>
  <data name="typeVOUCHERLST_Core" xml:space="preserve">
    <value>消費券記錄管理</value>
  </data>
  <data name="wCorporate" xml:space="preserve">
    <value>廳團</value>
  </data>
  <data name="wFirstVoucherNumber" xml:space="preserve">
    <value>首張消費券號</value>
  </data>
  <data name="wLastVoucherNumber" xml:space="preserve">
    <value>最後一張消費券號</value>
  </data>
  <data name="wSellingCounter" xml:space="preserve">
    <value>出票場館</value>
  </data>
  <data name="wVoucher" xml:space="preserve">
    <value>消費券</value>
  </data>
  <data name="action_GROUP_type" xml:space="preserve">
    <value>群組</value>
  </data>
  <data name="typeTRAVELAGENCYDTL_Core" xml:space="preserve">
    <value>旅行社管理</value>
  </data>
  <data name="typeTRAVELAGENCYLST_Core" xml:space="preserve">
    <value>旅行社管理</value>
  </data>
  <data name="wIsGroup" xml:space="preserve">
    <value>群組</value>
  </data>
  <data name="wIsHotel" xml:space="preserve">
    <value>酒店</value>
  </data>
  <data name="typePLACENOTIFYRPT_ReportGrp" xml:space="preserve">
    <value>現金確認資料報表</value>
  </data>
  <data name="typeRPLACENOTIFYRPT_Report" xml:space="preserve">
    <value>現金確認資料報表</value>
  </data>
  <data name="txtShowConfirmed" xml:space="preserve">
    <value>已確認</value>
  </data>
  <data name="txtRollingOwn" xml:space="preserve">
    <value>本戶轉碼</value>
  </data>
  <data name="txtRollingOwnWithDownLine" xml:space="preserve">
    <value>本戶連下線轉碼</value>
  </data>
  <data name="txtRollingAPlay" xml:space="preserve">
    <value>A數轉碼</value>
  </data>
  <data name="txtRollingBPlay" xml:space="preserve">
    <value>B數轉碼</value>
  </data>
  <data name="txtRollingOperate" xml:space="preserve">
    <value>營運轉碼</value>
  </data>
  <data name="txtRollingForeign" xml:space="preserve">
    <value>海外點轉碼</value>
  </data>
  <data name="txtPeriodRange" xml:space="preserve">
    <value>週期段</value>
  </data>
  <data name="typeRBUSINESSRPT_Report" xml:space="preserve">
    <value>業績報表</value>
  </data>
  <data name="wTTLMaxIOUHoldAmt" xml:space="preserve">
    <value>總凍結柴金額</value>
  </data>
  <data name="wTTLPendingAmount" xml:space="preserve">
    <value>總倘欠(萬)</value>
  </data>
  <data name="msgBPlayNotenoughStore" xml:space="preserve">
    <value>該場館存卡不足以凍結</value>
  </data>
  <data name="txtOptExpenseDeduct" xml:space="preserve">
    <value>扣減消費(共用/不共用)</value>
  </data>
  <data name="txtShareExpOnly" xml:space="preserve">
    <value>共用</value>
  </data>
  <data name="txtNonShareExpOnly" xml:space="preserve">
    <value>不共用</value>
  </data>
  <data name="txtInvalidFxRate" xml:space="preserve">
    <value>匯率數字(乘/除)</value>
  </data>
  <data name="txtSeatType" xml:space="preserve">
    <value>位置類型</value>
  </data>
  <data name="txtSeat" xml:space="preserve">
    <value>位置</value>
  </data>
  <data name="msgSelectSeatError" xml:space="preserve">
    <value>這位置已有客人, 請重新選擇</value>
  </data>
  <data name="txtShareLine" xml:space="preserve">
    <value>股東線</value>
  </data>
  <data name="wIsInternalUse" xml:space="preserve">
    <value>內部使用</value>
  </data>
  <data name="txtBPlayIsByPassMthComm" xml:space="preserve">
    <value>跳過月結佣金</value>
  </data>
  <data name="typeOPTRANLOGENQUIRY_Core" xml:space="preserve">
    <value>資料日誌查詢(營運)</value>
  </data>
  <data name="txt100NoReturn" xml:space="preserve">
    <value>欠M100天或以上</value>
  </data>
  <data name="txt30NoReturnNoRolling" xml:space="preserve">
    <value>欠M+無轉碼且30天無回數</value>
  </data>
  <data name="txt30NoReturnRolling" xml:space="preserve">
    <value>欠M+有轉碼且30天無回數</value>
  </data>
  <data name="txt30ReturnNoRolling" xml:space="preserve">
    <value>欠M+無轉碼且30天有回數</value>
  </data>
  <data name="txt30ReturnRolling" xml:space="preserve">
    <value>欠M+有轉碼且30天有回數</value>
  </data>
  <data name="txt60NoReturn" xml:space="preserve">
    <value>欠M60天無回數</value>
  </data>
  <data name="txtCashVsCredit" xml:space="preserve">
    <value>現金%/批額%</value>
  </data>
  <data name="txtFreezeAmt" xml:space="preserve">
    <value>凍結數</value>
  </data>
  <data name="txtNetAmtNotFreeze" xml:space="preserve">
    <value>總欠(扣除凍結數)</value>
  </data>
  <data name="txtNewCredit" xml:space="preserve">
    <value>現額度</value>
  </data>
  <data name="txtNewCreditExpired" xml:space="preserve">
    <value>新批額過期</value>
  </data>
  <data name="txtOldCredit" xml:space="preserve">
    <value>原額度</value>
  </data>
  <data name="txtReduceM" xml:space="preserve">
    <value>減M</value>
  </data>
  <data name="typeRCREDITCONTROLLABELRPT_Report" xml:space="preserve">
    <value>信貸監控標籤報表</value>
  </data>
  <data name="wExpiredForeign" xml:space="preserve">
    <value>過海</value>
  </data>
  <data name="wExpiredIOU" xml:space="preserve">
    <value>過面</value>
  </data>
  <data name="wExpiredOperate" xml:space="preserve">
    <value>過營</value>
  </data>
  <data name="wRollingLast3Mths" xml:space="preserve">
    <value>3個月內Rolling(月份-R)</value>
  </data>
  <data name="wStopMRecover" xml:space="preserve">
    <value>復M</value>
  </data>
  <data name="wStopMRecoverCount" xml:space="preserve">
    <value>復M次數</value>
  </data>
  <data name="wSysRemark" xml:space="preserve">
    <value>內部備註</value>
  </data>
  <data name="txtForeignCashIn" xml:space="preserve">
    <value>現金存入</value>
  </data>
  <data name="txtForeignRedEnvelopes" xml:space="preserve">
    <value>紅包</value>
  </data>
  <data name="txtForeignPettyCash" xml:space="preserve">
    <value>零用現金</value>
  </data>
  <data name="txtForeignExpRebate" xml:space="preserve">
    <value>消費回贈</value>
  </data>
  <data name="txtQuickReturnDay" xml:space="preserve">
    <value>快速還款天期</value>
  </data>
  <data name="txtQuickReturnCommRebateRate" xml:space="preserve">
    <value>快速還款佣金回贈率</value>
  </data>
  <data name="txtCashQuickReturnCommRebateRate" xml:space="preserve">
    <value>海外本地現金轉碼快速還款回贈率</value>
  </data>
  <data name="txtReturnDueDate" xml:space="preserve">
    <value>還款到期日</value>
  </data>
  <data name="txtQuickReturnDueDate" xml:space="preserve">
    <value>快速還款到期日</value>
  </data>
  <data name="txtForeignLocalCapitalRolling_10K" xml:space="preserve">
    <value>海外本地現金轉碼數(萬)</value>
  </data>
  <data name="txtForeignLocalCapitalCommRate" xml:space="preserve">
    <value>海外本地現金佣金率</value>
  </data>
  <data name="txtCapital_MRolling_10K" xml:space="preserve">
    <value>M現金轉碼數(萬)</value>
  </data>
  <data name="txtCapital_MCommRate" xml:space="preserve">
    <value>M現金佣金率</value>
  </data>
  <data name="txtIOURolling_10K" xml:space="preserve">
    <value>IOU轉碼數(萬)</value>
  </data>
  <data name="txtIOUCommRate" xml:space="preserve">
    <value>IOU佣金率</value>
  </data>
  <data name="typeAGENTCATEGORYLST_Core" xml:space="preserve">
    <value>代理類別管理</value>
  </data>
  <data name="typeAGENTCATEGORYDTL_Core" xml:space="preserve">
    <value>代理類別記錄</value>
  </data>
  <data name="txtAgentCagegoryTypeCompAcc" xml:space="preserve">
    <value>公司戶口</value>
  </data>
  <data name="txtAgentCagegoryTypeReservedAcc" xml:space="preserve">
    <value>新開戶保留的戶口</value>
  </data>
  <data name="typeRAGENCARDCREDITAMTRPT_Report" xml:space="preserve">
    <value>消費信用額報表</value>
  </data>
  <data name="global_msgLockAgentCountDown" xml:space="preserve">
    <value>已對戶口進行鎖定,請在限時內完成操作</value>
  </data>
  <data name="global_msgAgentLocked" xml:space="preserve">
    <value>因其他用戶對該代理進行操作中,請之後再做嘗試!!</value>
  </data>
  <data name="txtLastNoticeDate" xml:space="preserve">
    <value>最後通報日</value>
  </data>
  <data name="txtRolling_C_10K" xml:space="preserve">
    <value>現金轉碼(萬)</value>
  </data>
  <data name="txtRolling_MI_10K" xml:space="preserve">
    <value>月息轉碼(萬)</value>
  </data>
  <data name="txtOccupiedTable" xml:space="preserve">
    <value>包枱</value>
  </data>
  <data name="txtAgentRemark" xml:space="preserve">
    <value>戶口備註</value>
  </data>
  <data name="wStore" xml:space="preserve">
    <value>內部卡</value>
  </data>
  <data name="wCommRate_C" xml:space="preserve">
    <value>佣金率(現金)</value>
  </data>
  <data name="txtDayPassed" xml:space="preserve">
    <value>最長天期</value>
  </data>
  <data name="typeCRM_BOOKING_Core" xml:space="preserve">
    <value>預訂</value>
  </data>
  <data name="typeCRM_COMPANY_Core" xml:space="preserve">
    <value>公司</value>
  </data>
  <data name="typeCRM_Core" xml:space="preserve">
    <value>CRM</value>
  </data>
  <data name="typeCRM_CS_Core" xml:space="preserve">
    <value>客服</value>
  </data>
  <data name="typeSERVICECOUNTERLST_Core" xml:space="preserve">
    <value>服務計數器列表</value>
  </data>
  <data name="wDefaultHotelCode" xml:space="preserve">
    <value>wDefaultHotelCode</value>
  </data>
  <data name="wRegion" xml:space="preserve">
    <value>wRegion </value>
  </data>
  <data name="String3" xml:space="preserve">
    <value />
  </data>
  <data name="wCode" xml:space="preserve">
    <value>wCode</value>
  </data>
  <data name="wSeqNo" xml:space="preserve">
    <value>wSeqNo</value>
  </data>
  <data name="wSmsRoomID" xml:space="preserve">
    <value>wSmsRoomID</value>
  </data>
  <data name="typeSERVICECOUNTERDTDTL_Core" xml:space="preserve">
    <value>服務計數器詳細</value>
  </data>
  <data name="wServiceCounter" xml:space="preserve">
    <value>wServiceCounter</value>
  </data>
  <data name="typeSERVICECOUNTERDTL_Core" xml:space="preserve">
    <value>typeSERVICECOUNTERDTL_Core</value>
  </data>
  <data name="wRollexCompNo" xml:space="preserve">
    <value>wRollexCompNo</value>
  </data>
  <data name="typeCRMFERRY_Core" xml:space="preserve">
    <value>typeCRMFERRY_Core</value>
  </data>
  <data name="typeCRM_ALLBOOKING_Core" xml:space="preserve">
    <value>typeCRM_ALLBOOKING_Core</value>
  </data>
  <data name="typeALLOTMENT_Core" xml:space="preserve">
    <value>typeALLOTMENT_Core</value>
  </data>
  <data name="typeFERRYTICKETPRICE_Core" xml:space="preserve">
    <value>typeFERRYTICKETPRICE_Core</value>
  </data>
  <data name="typeTICKETBOOKING_Core" xml:space="preserve">
    <value>typeTICKETBOOKING_Core</value>
  </data>
  <data name="typeUPDATETICKETCOSTS_Core" xml:space="preserve">
    <value>typeUPDATETICKETCOSTS_Core</value>
  </data>
  <data name="typeCRMLOOKUPLST_Core" xml:space="preserve">
    <value>typeCRMLOOKUPLST_Core</value>
  </data>
  <data name="typeEXPENSETYPELST_Core" xml:space="preserve">
    <value>typeEXPENSETYPELST_Core</value>
  </data>
  <data name="wCanEdit" xml:space="preserve">
    <value>wCanEdit</value>
  </data>
  <data name="wCanSelect" xml:space="preserve">
    <value>wCanSelect</value>
  </data>
  <data name="wExpenseCategory" xml:space="preserve">
    <value>wExpenseCategory</value>
  </data>
  <data name="wLangCd" xml:space="preserve">
    <value>wLangCd</value>
  </data>
  <data name="wParentCode" xml:space="preserve">
    <value>wParentCode</value>
  </data>
  <data name="wDepartmentCode" xml:space="preserve">
    <value>wDepartmentCode</value>
  </data>
  <data name="wServiceCounterContact" xml:space="preserve">
    <value>Service Counter Contact</value>
  </data>
  <data name="typeCRMLOOKUPDTL_Core" xml:space="preserve">
    <value>typeCRMLOOKUPDTL_Core</value>
  </data>
  <data name="typeEXPENSETYPEDTL_Core" xml:space="preserve">
    <value>typeEXPENSETYPEDTL_Core</value>
  </data>
  <data name="wCRMLookUp" xml:space="preserve">
    <value>wCRMLookUp</value>
  </data>
  <data name="wDescr" xml:space="preserve">
    <value>wDescr</value>
  </data>
  <data name="wExpenseType" xml:space="preserve">
    <value>wExpenseType</value>
  </data>
  <data name="wGiftSubtype" xml:space="preserve">
    <value>wGiftSubtype</value>
  </data>
  <data name="wGiftType" xml:space="preserve">
    <value>wGiftType</value>
  </data>
  <data name="typeSERVICECOUNTERCONTACTDTL_Core" xml:space="preserve">
    <value>typeSERVICECOUNTERCONTACTDTL_Core</value>
  </data>
  <data name="typeALLOTMENTOFFERRYRECORDLST_Core" xml:space="preserve">
    <value>typeALLOTMENTOFFERRYRECORDLST_Core</value>
  </data>
  <data name="wFerryClass" xml:space="preserve">
    <value>wFerryClass</value>
  </data>
  <data name="wIssueLocation" xml:space="preserve">
    <value>wIssueLocation</value>
  </data>
  <data name="typeROUTELST_Core" xml:space="preserve">
    <value>Route List</value>
  </data>
  <data name="wRoute" xml:space="preserve">
    <value>wRoute</value>
  </data>
  <data name="wRouteFrom" xml:space="preserve">
    <value>Route From</value>
  </data>
  <data name="wSvCtrCode" xml:space="preserve">
    <value>wSvCtrCode</value>
  </data>
  <data name="wTicketType" xml:space="preserve">
    <value>wTicketType</value>
  </data>
  <data name="wValidDate" xml:space="preserve">
    <value>wValidDate</value>
  </data>
  <data name="wRouteTo" xml:space="preserve">
    <value>Route To</value>
  </data>
  <data name="typeROUTEDTL_Core" xml:space="preserve">
    <value>Route Details</value>
  </data>
  <data name="txtAvailable" xml:space="preserve">
    <value>txtAvailable</value>
  </data>
  <data name="txtCancelled" xml:space="preserve">
    <value>txtCancelled</value>
  </data>
  <data name="txtDisabled" xml:space="preserve">
    <value>txtDisabled</value>
  </data>
  <data name="txtEconomy" xml:space="preserve">
    <value>txtEconomy</value>
  </data>
  <data name="txtHongKongServiceDpt" xml:space="preserve">
    <value>Hong Kong Service Department</value>
  </data>
  <data name="txtLisboba" xml:space="preserve">
    <value>txtLisboba</value>
  </data>
  <data name="txtPremierGrandClass" xml:space="preserve">
    <value>txtPremierGrandClass</value>
  </data>
  <data name="txtPremierVIPCabin4Seats" xml:space="preserve">
    <value>txtPremierVIPCabin4Seats</value>
  </data>
  <data name="txtSuncityCoupons" xml:space="preserve">
    <value>txtSuncityCoupons</value>
  </data>
  <data name="txtSuper" xml:space="preserve">
    <value>txtSuper</value>
  </data>
  <data name="txtTicketFromSuncity" xml:space="preserve">
    <value>txtTicketFromSuncity</value>
  </data>
  <data name="txtTicketsWithMarked" xml:space="preserve">
    <value>txtTicketsWithMarked</value>
  </data>
  <data name="txtVIPCabin16Seats" xml:space="preserve">
    <value>txtVIPCabin16Seats</value>
  </data>
  <data name="txtVIPCabin4Seats" xml:space="preserve">
    <value>txtVIPCabin4Seats</value>
  </data>
  <data name="txtVIPCabin6Seats" xml:space="preserve">
    <value>txtVIPCabin6Seats</value>
  </data>
  <data name="txtVIPCabin8Or10Seats" xml:space="preserve">
    <value>txtVIPCabin8Or10Seats</value>
  </data>
  <data name="typeALLOTMENTOFFERRYRECORDDTL_Core" xml:space="preserve">
    <value>typeALLOTMENTOFFERRYRECORDDTL_Core</value>
  </data>
  <data name="wCurrency" xml:space="preserve">
    <value>wCurrency</value>
  </data>
  <data name="wFirstAlphabetoftheTktAllotment" xml:space="preserve">
    <value>wFirstAlphabetoftheTktAllotment</value>
  </data>
  <data name="wFirstTicketNo" xml:space="preserve">
    <value>wFirstTicketNo</value>
  </data>
  <data name="wIssueAt" xml:space="preserve">
    <value>wIssueAt</value>
  </data>
  <data name="wLastTicketNo" xml:space="preserve">
    <value>wLastTicketNo</value>
  </data>
  <data name="wValidTill" xml:space="preserve">
    <value>wValidTill</value>
  </data>
  <data name="typeDEPARTMENTTEAMLST_Core" xml:space="preserve">
    <value>typeDEPARTMENTTEAMLST_Core</value>
  </data>
  <data name="wDepartment" xml:space="preserve">
    <value>wDepartment</value>
  </data>
  <data name="typeCRMTRAVELAGENCYDTL_Core" xml:space="preserve">
    <value>typeCRMTRAVELAGENCYDTL_Core</value>
  </data>
  <data name="typeCRMTRAVELAGENCYLST_Core" xml:space="preserve">
    <value>typeCRMTRAVELAGENCYLST_Core</value>
  </data>
  <data name="wIsAirTic" xml:space="preserve">
    <value>wIsAirTic</value>
  </data>
  <data name="wIsShowTic" xml:space="preserve">
    <value>wIsShowTic</value>
  </data>
  <data name="wTravelAgency" xml:space="preserve">
    <value>wTravelAgency</value>
  </data>
  <data name="typeCRMTICKETCOLLECTIONPOINTDTL_Core" xml:space="preserve">
    <value>typeCRMTICKETCOLLECTIONPOINTDTL_Core</value>
  </data>
  <data name="typeCRMTICKETCOLLECTIONPOINTLST_Core" xml:space="preserve">
    <value>typeCRMTICKETCOLLECTIONPOINTLST_Core</value>
  </data>
  <data name="wTicketCollectionPoint" xml:space="preserve">
    <value>wTicketCollectionPoint</value>
  </data>
  <data name="wHasAirTic" xml:space="preserve">
    <value>wHasAirTic</value>
  </data>
  <data name="wHasCheckInService" xml:space="preserve">
    <value>wHasCheckInService</value>
  </data>
  <data name="wHasFerryTic" xml:space="preserve">
    <value>wHasFerryTic</value>
  </data>
  <data name="wHasShowTic" xml:space="preserve">
    <value>wHasShowTic</value>
  </data>
  <data name="String4" xml:space="preserve">
    <value />
  </data>
  <data name="typeDEPARTMENTTEAM_Core" xml:space="preserve">
    <value>typeDEPARTMENTTEAM_Core</value>
  </data>
  <data name="typeDEPARTMENTTEAMDTL_Core" xml:space="preserve">
    <value>typeDEPARTMENTTEAMDTL_Core</value>
  </data>
  <data name="wDeptmentTeam" xml:space="preserve">
    <value>wDeptmentTeam</value>
  </data>
  <data name="wAgentCodeIn" xml:space="preserve">
    <value>Agent Code In</value>
  </data>
  <data name="wRole" xml:space="preserve">
    <value>Role</value>
  </data>
  <data name="wPerson" xml:space="preserve">
    <value>Person</value>
  </data>
  <data name="typePERSONLST_Core" xml:space="preserve">
    <value>Person List</value>
  </data>
  <data name="typePERSONDTL_Core" xml:space="preserve">
    <value>Person Details</value>
  </data>
  <data name="typePERSONTRAVELDOCLST_Core" xml:space="preserve">
    <value>Person Travel List Doc</value>
  </data>
  <data name="wPersonRID" xml:space="preserve">
    <value>wPersonRID</value>
  </data>
  <data name="wExpiryDate" xml:space="preserve">
    <value>Expiry Date</value>
  </data>
  <data name="wPersonTravelDoc" xml:space="preserve">
    <value>Person Travel Doc</value>
  </data>
  <data name="wGender" xml:space="preserve">
    <value>Gender</value>
  </data>
  <data name="wSpeakLangCd" xml:space="preserve">
    <value>Speak Lang</value>
  </data>
  <data name="wTelBusiness" xml:space="preserve">
    <value>TelBusiness</value>
  </data>
  <data name="wTelHome" xml:space="preserve">
    <value>TelHome</value>
  </data>
  <data name="wWritenLangCd" xml:space="preserve">
    <value>Writen Lang</value>
  </data>
  <data name="typePERSONTRAVELDOCDTL_Core" xml:space="preserve">
    <value>Person Travel Doc Details</value>
  </data>
  <data name="wPersonIdType" xml:space="preserve">
    <value>wPersonIdType</value>
  </data>
  <data name="typeROUTETICKETLST_Core" xml:space="preserve">
    <value>Route Ticket List</value>
  </data>
  <data name="wRouteTicket" xml:space="preserve">
    <value>RouteTicket</value>
  </data>
  <data name="wRowID" xml:space="preserve">
    <value> Row Id</value>
  </data>
  <data name="typeROUTETICKETDTL_Core" xml:space="preserve">
    <value>typeROUTETICKETDTL_Core</value>
  </data>
  <data name="typeEXPENSESUBTYPEDTL_Core" xml:space="preserve">
    <value>Expense Subtype Details</value>
  </data>
  <data name="wExpenseSubtype" xml:space="preserve">
    <value>ExpenseSubtype</value>
  </data>
  <data name="wExpCat" xml:space="preserve">
    <value>ExpCat</value>
  </data>
  <data name="typeBOOKINGFERRYLST_Core" xml:space="preserve">
    <value> Booking Ferry lst</value>
  </data>
  <data name="txtFerryBooking" xml:space="preserve">
    <value>txtFerryBooking</value>
  </data>
  <data name="txtPaymentMethod" xml:space="preserve">
    <value>Payment Method</value>
  </data>
  <data name="txtTotalAmt" xml:space="preserve">
    <value>Total amaount</value>
  </data>
  <data name="txtCRMCost" xml:space="preserve">
    <value>Cost</value>
  </data>
  <data name="txtCRMDepartDt" xml:space="preserve">
    <value>Department Detail</value>
  </data>
  <data name="txtCRMQuantity" xml:space="preserve">
    <value>Quantity</value>
  </data>
  <data name="txtCRMRemark" xml:space="preserve">
    <value>Remark</value>
  </data>
  <data name="txtCRMRouteFrom" xml:space="preserve">
    <value>Route Form</value>
  </data>
  <data name="txtDebitDt" xml:space="preserve">
    <value>txtDebitDt</value>
  </data>
  <data name="wOrderNumber" xml:space="preserve">
    <value>wOrderNumber</value>
  </data>
  <data name="wCost" xml:space="preserve">
    <value>Cost</value>
  </data>
  <data name="wEndDate" xml:space="preserve">
    <value>EndDate</value>
  </data>
  <data name="wHandlingFee" xml:space="preserve">
    <value>HandlingFee</value>
  </data>
  <data name="wStartDate" xml:space="preserve">
    <value>StartDate</value>
  </data>
  <data name="typeTICKETPRICINGLST_Core" xml:space="preserve">
    <value>Ferry Ticket Pricing List</value>
  </data>
  <data name="typeTICKETPRICINGDTL_Core" xml:space="preserve">
    <value>TICKETPRICINGDTL Core</value>
  </data>
  <data name="wTicketPricing" xml:space="preserve">
    <value>wTicketPricing</value>
  </data>
  <data name="wCreatedBy" xml:space="preserve">
    <value>wCreatedBy</value>
  </data>
  <data name="wTicketClass" xml:space="preserve">
    <value>wTicketClass</value>
  </data>
  <data name="txtSpecialPeriod" xml:space="preserve">
    <value>Special Period</value>
  </data>
  <data name="typeUPDATEFERRYHELICOPTERTICKETSCOSTLST_CotypeUPDATEFERRYHELICOPTERTICKETSCOSTLST_Co" xml:space="preserve">
    <value>update ferry Helicopter Tickets cost</value>
  </data>
  <data name="txtFerryClass" xml:space="preserve">
    <value>ferry Clas</value>
  </data>
  <data name="txtTicType" xml:space="preserve">
    <value>ticket type</value>
  </data>
  <data name="txtVehicleType" xml:space="preserve">
    <value>vehicale Type</value>
  </data>
  <data name="typeUPDATEFERRYHELICOPTERTICKETSCOSTLST_Core" xml:space="preserve">
    <value>Update  Ferry Helicopter Tickets cost</value>
  </data>
  <data name="txtEnddate" xml:space="preserve">
    <value>end Date</value>
  </data>
  <data name="txtStartdate" xml:space="preserve">
    <value>Start date</value>
  </data>
  <data name="txtTickettype" xml:space="preserve">
    <value>ticket type</value>
  </data>
  <data name="txtUpdateFerryHelicopterTicketsCost" xml:space="preserve">
    <value>Update Ferry Helicopoter Ticket cost</value>
  </data>
  <data name="txtTravelClass" xml:space="preserve">
    <value>ferry Class</value>
  </data>
  <data name="pwTicType" xml:space="preserve">
    <value>Ticket Type</value>
  </data>
  <data name="wVehicleType" xml:space="preserve">
    <value>vehicle Type</value>
  </data>
  <data name="typeUPDATEFERRYHELICOPTERTICKETSCOSTDTL_Core" xml:space="preserve">
    <value>typeUPDATEFERRYHELICOPTERTICKETSCOSTDTL_Core</value>
  </data>
  <data name="wUpdateFerryHelicopterTicketsCost" xml:space="preserve">
    <value>wUpdateFerryHelicopterTicketsCost</value>
  </data>
  <data name="wCurrentDate" xml:space="preserve">
    <value>Current date</value>
  </data>
  <data name="wSpecialPeriod" xml:space="preserve">
    <value>Special Period </value>
  </data>
  <data name="wTax" xml:space="preserve">
    <value>tax</value>
  </data>
  <data name="typeBOOKINGFERRYDTL_Core" xml:space="preserve">
    <value>typeBOOKINGFERRYDTL_Core</value>
  </data>
  <data name="wAllotmentsofFerryRecord" xml:space="preserve">
    <value>AllotmentsofFerryRecord</value>
  </data>
  <data name="wBookingDetail" xml:space="preserve">
    <value>wBookingDetail</value>
  </data>
  <data name="wExpenseAmount" xml:space="preserve">
    <value>wExpenseAmount</value>
  </data>
  <data name="wFerryDateAndFerryTime" xml:space="preserve">
    <value>wFerryDateAndFerryTime</value>
  </data>
  <data name="wOrderNoOrConfirmationNo" xml:space="preserve">
    <value>wOrderNoOrConfirmationNo</value>
  </data>
  <data name="wPaymentMethod" xml:space="preserve">
    <value>wPaymentMethod</value>
  </data>
  <data name="wQuantity" xml:space="preserve">
    <value>wQuantity</value>
  </data>
  <data name="wTotalAmount" xml:space="preserve">
    <value>wTotalAmount</value>
  </data>
  <data name="wTravalClass" xml:space="preserve">
    <value>wTravalClass</value>
  </data>
  <data name="wUnitPrice" xml:space="preserve">
    <value>wUnitPrice</value>
  </data>
  <data name="wTicketAllotments" xml:space="preserve">
    <value>wTicketAllotments</value>
  </data>
  <data name="wHandleBy" xml:space="preserve">
    <value>wHandleBy</value>
  </data>
  <data name="wIsTicketCollected" xml:space="preserve">
    <value>wTicketCollected_?</value>
  </data>
  <data name="wTicketCollection" xml:space="preserve">
    <value>wTicketCollection</value>
  </data>
  <data name="wTicketCollectionDateTime" xml:space="preserve">
    <value>wTicketCollectionDateTime</value>
  </data>
  <data name="wVIPClub" xml:space="preserve">
    <value>wVIPClub</value>
  </data>
  <data name="wBookingFerry" xml:space="preserve">
    <value>wBookingFerry</value>
  </data>
  <data name="txtDebitDate" xml:space="preserve">
    <value>DebitDate</value>
  </data>
  <data name="txtExpenseDateTime" xml:space="preserve">
    <value>Expense DateTime</value>
  </data>
  <data name="txtServiceCounterAndAccount" xml:space="preserve">
    <value>txtServiceCounterAndAccount</value>
  </data>
  <data name="wActReqForBooking" xml:space="preserve">
    <value>wActReqForBooking</value>
  </data>
  <data name="wAssistantBooker" xml:space="preserve">
    <value>wAssistantBooker</value>
  </data>
  <data name="wAssistantBookerPhn" xml:space="preserve">
    <value>wAssistantBookerPhn</value>
  </data>
  <data name="wClientReqForBooking" xml:space="preserve">
    <value>wClientReqForBooking</value>
  </data>
  <data name="wDebitAccount" xml:space="preserve">
    <value>wDebitAccount</value>
  </data>
  <data name="wDebitClientReqForBooking" xml:space="preserve">
    <value>wDebitClientReqForBooking</value>
  </data>
  <data name="wDebitServiceCounter" xml:space="preserve">
    <value>wDebitServiceCounter</value>
  </data>
  <data name="wDepReqForBooking" xml:space="preserve">
    <value>Department Requested For Booking</value>
  </data>
  <data name="wStaffReqForBooking" xml:space="preserve">
    <value>wStaffReqForBooking</value>
  </data>
  <data name="wStrCntRequestedForBooking" xml:space="preserve">
    <value>wStrCntRequestedForBooking</value>
  </data>
  <data name="txtBookingHeli" xml:space="preserve">
    <value>Booking Helicopeter list</value>
  </data>
  <data name="typeBOOKINGHELIPASSENGERINFOLST_Core" xml:space="preserve">
    <value>Heli Passenger Info List</value>
  </data>
  <data name="wAccount" xml:space="preserve">
    <value>Account</value>
  </data>
  <data name="wBookingRid" xml:space="preserve">
    <value>Booking Rid</value>
  </data>
  <data name="wClient" xml:space="preserve">
    <value>Client</value>
  </data>
  <data name="wClientId" xml:space="preserve">
    <value>Client ID</value>
  </data>
  <data name="wTravelDocNo" xml:space="preserve">
    <value>TravelDocNo</value>
  </data>
  <data name="wTravelDocType" xml:space="preserve">
    <value>TravelDocType</value>
  </data>
  <data name="typeBOOKINGHELI_Core" xml:space="preserve">
    <value>Passenger Info</value>
  </data>
  <data name="typeCRMHELICOPTER_Core" xml:space="preserve">
    <value>typeCRMHELICOPTER_Core</value>
  </data>
  <data name="typeHELICOPTERTICKETPRICE_Core" xml:space="preserve">
    <value>Ticket Price</value>
  </data>
  <data name="typeHELICOPTERTICKETPRICELST_Core" xml:space="preserve">
    <value>Helicopter Ticket Price List</value>
  </data>
  <data name="typeHELICOPTERTICKETPRICEDTL_Core" xml:space="preserve">
    <value>Helicopter Ticket Price Details</value>
  </data>
  <data name="typeUPDATEHELITICKETCOSTS_Core" xml:space="preserve">
    <value>Update Ticket Costs</value>
  </data>
  <data name="typeAIRPORTLST_Core" xml:space="preserve">
    <value>Airport List</value>
  </data>
  <data name="typeAIRPORTDTL_Core" xml:space="preserve">
    <value>Airport Details</value>
  </data>
  <data name="wAirport" xml:space="preserve">
    <value>Airport</value>
  </data>
  <data name="typeHELICOPTERBOOKING_Core" xml:space="preserve">
    <value>Booking</value>
  </data>
  <data name="typeHELICOPTERTICKETBOOKINGLST_Core" xml:space="preserve">
    <value>Helicopter Ticket Booking List</value>
  </data>
  <data name="wBookingLocation" xml:space="preserve">
    <value>Booking Venu</value>
  </data>
  <data name="wDebitClient" xml:space="preserve">
    <value>Debit Client</value>
  </data>
  <data name="wReason" xml:space="preserve">
    <value>wReason</value>
  </data>
  <data name="typeBOOKINGAIRTICKETLST_Core" xml:space="preserve">
    <value>Booking AirTicket List</value>
  </data>
  <data name="typeCRMAIRTICKET_Core" xml:space="preserve">
    <value>Air Ticket</value>
  </data>
  <data name="wArrivalTerminal" xml:space="preserve">
    <value>ArrivalTerminal</value>
  </data>
  <data name="wDepartureTerminal" xml:space="preserve">
    <value>DepartureTerminal</value>
  </data>
  <data name="typeBOOKINGHELIDTL_Core" xml:space="preserve">
    <value>Helicopter Ticket Booking Details</value>
  </data>
  <data name="HELICOPTERTICKETBOOKINGDTL" xml:space="preserve">
    <value>Helicopter Ticket Booking Details</value>
  </data>
  <data name="typeAIRTICKETPASSENGERINFOLST_Core" xml:space="preserve">
    <value>Air Ticket Passenger Info List</value>
  </data>
  <data name="typeAIRTICKETPASSENGERINFO_Core" xml:space="preserve">
    <value>Passenger Info</value>
  </data>
  <data name="wArrivalDatetime" xml:space="preserve">
    <value>Time of Return</value>
  </data>
  <data name="wBookingClass" xml:space="preserve">
    <value>Booking Class</value>
  </data>
  <data name="wChangeOrderStatus" xml:space="preserve">
    <value>Change Order Status</value>
  </data>
  <data name="wIsWaiting" xml:space="preserve">
    <value>IsWaiting</value>
  </data>
  <data name="wDepartureDateTime" xml:space="preserve">
    <value>Departure Date/Time</value>
  </data>
  <data name="wBookingHelicopter" xml:space="preserve">
    <value>wBookingHelicopter</value>
  </data>
  <data name="wDepartDt" xml:space="preserve">
    <value>wDepartDt</value>
  </data>
  <data name="wExpAmt" xml:space="preserve">
    <value>wExpAmt</value>
  </data>
  <data name="wTotalAmt" xml:space="preserve">
    <value>wTotalAmt</value>
  </data>
  <data name="wUnitAmt" xml:space="preserve">
    <value>wUnitAmt</value>
  </data>
  <data name="wUseBlackCardFlag" xml:space="preserve">
    <value>wUseBlackCardFlag</value>
  </data>
  <data name="wAdditionalExp" xml:space="preserve">
    <value>wAdditionalExp</value>
  </data>
  <data name="typeCRMHOTEL_Core" xml:space="preserve">
    <value>Hotel</value>
  </data>
  <data name="typeHOTELSETTINGS_Core" xml:space="preserve">
    <value>Hotel Settings</value>
  </data>
  <data name="wHasAllotment" xml:space="preserve">
    <value>Has Allotment</value>
  </data>
  <data name="wReceiptNo" xml:space="preserve">
    <value>wReceiptNo</value>
  </data>
  <data name="wStaffWhoRequestTheOrder" xml:space="preserve">
    <value>wStaffWhoRequestTheOrder</value>
  </data>
  <data name="wActivity" xml:space="preserve">
    <value>wActivity</value>
  </data>
  <data name="AirTic" xml:space="preserve">
    <value>Air Ticket</value>
  </data>
  <data name="Hotel" xml:space="preserve">
    <value>Hotel</value>
  </data>
  <data name="ShowTic" xml:space="preserve">
    <value>Show Ticket</value>
  </data>
  <data name="wRouteInvalid" xml:space="preserve">
    <value>wRouteInvalid</value>
  </data>
  <data name="wHotelCode" xml:space="preserve">
    <value>Hotel Code</value>
  </data>
  <data name="HELICOPTERPASSENGERINFODTL" xml:space="preserve">
    <value>HELICOPTERPASSENGERINFODTL</value>
  </data>
  <data name="typeHELICOPTERPASSENGERINFODTL_Core" xml:space="preserve">
    <value>Helicopter Passenger Info</value>
  </data>
  <data name="wShowTicket" xml:space="preserve">
    <value>Show Ticket</value>
  </data>
  <data name="typeBOOKINGAIRTICKETDTL_Core" xml:space="preserve">
    <value>typeBOOKINGAIRTICKETDTL_Core</value>
  </data>
  <data name="txtRoomNameCode" xml:space="preserve">
    <value>txtRoomNameCode</value>
  </data>
  <data name="wHotelRoom" xml:space="preserve">
    <value>HotelRoom</value>
  </data>
  <data name="typeHOTELROOMDTL_Core" xml:space="preserve">
    <value>typeHOTELROOMDTL_Core</value>
  </data>
  <data name="typeHOTELROOMLST_Core" xml:space="preserve">
    <value>typeHOTELROOMLST_Core</value>
  </data>
  <data name="typeROOMALLOTMENTQUANTITYLST_Core" xml:space="preserve">
    <value>typeROOMALLOTMENTQUANTITYLST_Core</value>
  </data>
  <data name="typeROOMALLOTMENTDTL_Core" xml:space="preserve">
    <value>Room Allotment Details</value>
  </data>
  <data name="typeROOMALLOTMENTQUANTITYDTL_Core" xml:space="preserve">
    <value>Room Allotment Quantity Details</value>
  </data>
  <data name="wRoomAllotmentQuantity" xml:space="preserve">
    <value>RoomAllotmentQuantity</value>
  </data>
  <data name="wRoomAllotment" xml:space="preserve">
    <value>RoomAllotment</value>
  </data>
  <data name="wClientInfo" xml:space="preserve">
    <value>wClientInfo</value>
  </data>
  <data name="wTicketDetails" xml:space="preserve">
    <value>wTicketDetails</value>
  </data>
  <data name="wClientEngName" xml:space="preserve">
    <value>wClientEngName</value>
  </data>
  <data name="wClientName" xml:space="preserve">
    <value>wClientName</value>
  </data>
  <data name="wPlaceOfIssue" xml:space="preserve">
    <value>wPlaceOfIssue</value>
  </data>
  <data name="txtRoomAllotmentName" xml:space="preserve">
    <value>txtRoomAllotmentName</value>
  </data>
  <data name="wRoomAllotmentQuantityDtl" xml:space="preserve">
    <value>RoomAllotmentQuantityDtl</value>
  </data>
  <data name="typeROOMALLOTMENTQTYWITHDTLMAPPING_Core" xml:space="preserve">
    <value>RoomAllotment Quantity With Details Mapping</value>
  </data>
  <data name="wApplyDateTime" xml:space="preserve">
    <value>wApplyDateTime</value>
  </data>
  <data name="wMsgNoCal" xml:space="preserve">
    <value>wMsgNoCal</value>
  </data>
  <data name="global_txtServiceCounter" xml:space="preserve">
    <value>服務櫃臺</value>
  </data>
  <data name="typeUPDATETICKETSCOSTDTL_Core" xml:space="preserve">
    <value>typeUPDATETICKETSCOSTDTL_Core </value>
  </data>
  <data name="wSellingPrice" xml:space="preserve">
    <value>wSellingPrice</value>
  </data>
</root>
'
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
SET @xmlRollsmary = N'<root>
  <data name="global_msgInformationHeader" xml:space="preserve">
    <value>[系統訊息]-資訊</value>
  </data>
  <data name="global_msgCautionHeader" xml:space="preserve">
    <value>[系統訊息]-注意</value>
  </data>
  <data name="global_msgErrorHeader" xml:space="preserve">
    <value>[系統訊息]-提示</value>
  </data>
  <data name="global_msgError" xml:space="preserve">
    <value>很抱歉，系統出現問題。</value>
  </data>
  <data name="global_msgNoRecord" xml:space="preserve">
    <value>沒有資料</value>
  </data>
  <data name="global_msgNoReservationRecord" xml:space="preserve">
    <value>沒有預約資料</value>
  </data>
  <data name="global_msgMissActionCode" xml:space="preserve">
    <value>請輸入經手人</value>
  </data>
  <data name="global_msgMissActionCodePW" xml:space="preserve">
    <value>請輸入經手人密碼</value>
  </data>
  <data name="global_msgEmptyUsr" xml:space="preserve">
    <value>經手人不存在。</value>
  </data>
  <data name="global_msgUNAUTHORIZED" xml:space="preserve">
    <value>沒有權限。</value>
  </data>
  <data name="global_msgExpired" xml:space="preserve">
    <value>經手人已失效。</value>
  </data>
  <data name="global_msgExpiredActionCode" xml:space="preserve">
    <value>權限已失效。</value>
  </data>
  <data name="global_msgRelogin" xml:space="preserve">
    <value>請重新登入。</value>
  </data>
  <data name="global_msgWrongPassword" xml:space="preserve">
    <value>密碼錯誤。</value>
  </data>
  <data name="global_msgMissAuthActionCode" xml:space="preserve">
    <value>請輸入授權人</value>
  </data>
  <data name="global_msgMissAuthActionCodePW" xml:space="preserve">
    <value>請輸入授權人密碼</value>
  </data>
  <data name="global_msgEmptyAuth" xml:space="preserve">
    <value>授權人不存在。</value>
  </data>
  <data name="global_msgExpiredAuth" xml:space="preserve">
    <value>授權人已失效。</value>
  </data>
  <data name="global_txtActionCode" xml:space="preserve">
    <value>經手人</value>
  </data>
  <data name="global_txtActionCodePw" xml:space="preserve">
    <value>經手人密碼</value>
  </data>
  <data name="global_txtAuthActionCode" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="global_txtAuthActionCodePw" xml:space="preserve">
    <value>授權人密碼</value>
  </data>
  <data name="global_btnEnter" xml:space="preserve">
    <value>確認</value>
  </data>
  <data name="global_btnCancel" xml:space="preserve">
    <value>取消</value>
  </data>
  <data name="global_btnReset" xml:space="preserve">
    <value>重置</value>
  </data>
  <data name="global_btnSearch" xml:space="preserve">
    <value>搜尋</value>
  </data>
  <data name="global_btnAdd" xml:space="preserve">
    <value>新增</value>
  </data>
  <data name="global_btnSave" xml:space="preserve">
    <value>保存</value>
  </data>
  <data name="global_btnSavePrint" xml:space="preserve">
    <value>保存及列印</value>
  </data>
  <data name="global_btnDel" xml:space="preserve">
    <value>刪除</value>
  </data>
  <data name="global_btnPrint" xml:space="preserve">
    <value>列印</value>
  </data>
  <data name="global_btnPreview" xml:space="preserve">
    <value>預覽</value>
  </data>
  <data name="global_btnPreviewNewStatement" xml:space="preserve">
    <value>預覽新糧單</value>
  </data>
  <data name="global_btnExport" xml:space="preserve">
    <value>匯出</value>
  </data>
  <data name="global_btnApprove" xml:space="preserve">
    <value>批核</value>
  </data>
  <data name="global_btnSMS" xml:space="preserve">
    <value>SMS</value>
  </data>
  <data name="global_btnClose" xml:space="preserve">
    <value>退出</value>
  </data>
  <data name="typeAGENT_Core" xml:space="preserve">
    <value>戶口</value>
  </data>
  <data name="typeEXPENSE_Core" xml:space="preserve">
    <value>消費</value>
  </data>
  <data name="typeMARKER_Core" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="typeMARKER_LST_Core" xml:space="preserve">
    <value>貸款管理</value>
  </data>
  <data name="typeOPERATE_Core" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="typeREPORT_Core" xml:space="preserve">
    <value>報表</value>
  </data>
  <data name="typeROLLING_Core" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="typeSETTLEMENT_Core" xml:space="preserve">
    <value>月結</value>
  </data>
  <data name="typeSYSTEM_Core" xml:space="preserve">
    <value>系統</value>
  </data>
  <data name="wAgent" xml:space="preserve">
    <value>代理</value>
  </data>
  <data name="wCompNo" xml:space="preserve">
    <value>公司編號</value>
  </data>
  <data name="wCName" xml:space="preserve">
    <value>中文名字</value>
  </data>
  <data name="wEName" xml:space="preserve">
    <value>英文名字</value>
  </data>
  <data name="wShortName" xml:space="preserve">
    <value>簡稱</value>
  </data>
  <data name="wCurrCode" xml:space="preserve">
    <value>貨幣</value>
  </data>
  <data name="wRoomId" xml:space="preserve">
    <value>訊息公司編號</value>
  </data>
  <data name="wTel" xml:space="preserve">
    <value>電話</value>
  </data>
  <data name="wSmsStaff" xml:space="preserve">
    <value>場面公電</value>
  </data>
  <data name="wEmail" xml:space="preserve">
    <value>電郵</value>
  </data>
  <data name="wSmsStaffCage" xml:space="preserve">
    <value>帳房公電</value>
  </data>
  <data name="wLocation" xml:space="preserve">
    <value>地點</value>
  </data>
  <data name="wStatus" xml:space="preserve">
    <value>狀態</value>
  </data>
  <data name="wTeminateDate" xml:space="preserve">
    <value>終止日期</value>
  </data>
  <data name="wUpdByCName" xml:space="preserve">
    <value>經手人</value>
  </data>
  <data name="txtCompanyLst" xml:space="preserve">
    <value>公司管理</value>
  </data>
  <data name="global_txtAgentSummary" xml:space="preserve">
    <value>查數易</value>
  </data>
  <data name="typeAGENT_SUMMARY_Core" xml:space="preserve">
    <value>查數易</value>
  </data>
  <data name="global_txtActionHistory" xml:space="preserve">
    <value>執行記錄</value>
  </data>
  <data name="global_txtAgentNavigateHistory" xml:space="preserve">
    <value>戶口瀏覽記錄</value>
  </data>
  <data name="global_txtNavigateHistory" xml:space="preserve">
    <value>資料瀏覽記錄</value>
  </data>
  <data name="typeCOMPANYLST_Core" xml:space="preserve">
    <value>公司管理</value>
  </data>
  <data name="global_txtAccountLevel" xml:space="preserve">
    <value>級別</value>
  </data>
  <data name="global_txtAccountTypeUpDnReq" xml:space="preserve">
    <value>級別所需轉碼:
太陽客戶: 無需求
金太陽: 連續 3 個月有轉碼
卓越: 累計轉碼數達1億
非凡: 累計轉碼數達5億
奇蹟: 累計轉碼數達10億
傳奇: 累計轉碼數達15億
至尊: 累計轉碼數達20億
</value>
  </data>
  <data name="global_txtAddress" xml:space="preserve">
    <value>聯絡地址</value>
  </data>
  <data name="global_txtAgent" xml:space="preserve">
    <value>戶口</value>
  </data>
  <data name="global_txtAgentIdentity" xml:space="preserve">
    <value>身份</value>
  </data>
  <data name="global_txtAgentTypeHighDeposit" xml:space="preserve">
    <value>大額</value>
  </data>
  <data name="global_txtAgentTypeNew" xml:space="preserve">
    <value>新開戶</value>
  </data>
  <data name="global_txtAgentTypeShare" xml:space="preserve">
    <value>股東</value>
  </data>
  <data name="global_txtAgentTypeOtherClient" xml:space="preserve">
    <value>其他人數</value>
  </data>
  <data name="global_txtAgentTypeShareInt" xml:space="preserve">
    <value>股息</value>
  </data>
  <data name="global_txtAuthorize" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="global_txtBirthDay" xml:space="preserve">
    <value>出生日期</value>
  </data>
  <data name="global_txtCompNo" xml:space="preserve">
    <value>公司編號</value>
  </data>
  <data name="global_txtFollowGroup" xml:space="preserve">
    <value>跟進組別</value>
  </data>
  <data name="global_txtIDExpireDate" xml:space="preserve">
    <value>證件到期日</value>
  </data>
  <data name="global_txtIDNo" xml:space="preserve">
    <value>證件號碼</value>
  </data>
  <data name="global_txtName" xml:space="preserve">
    <value>姓名</value>
  </data>
  <data name="global_txtPreferLang" xml:space="preserve">
    <value>語言</value>
  </data>
  <data name="global_txtSex" xml:space="preserve">
    <value>性別</value>
  </data>
  <data name="global_txtShowIntroducer" xml:space="preserve">
    <value>介紹人</value>
  </data>
  <data name="global_txtStateCountry" xml:space="preserve">
    <value>國籍 (省/縣)</value>
  </data>
  <data name="global_txtTelNo" xml:space="preserve">
    <value>電話號碼</value>
  </data>
  <data name="global_txtType" xml:space="preserve">
    <value>類別</value>
  </data>
  <data name="global_txtUpperAgent" xml:space="preserve">
    <value>上線</value>
  </data>
  <data name="global_txtAgentEntryStatus" xml:space="preserve">
    <value>入場狀態</value>
  </data>
  <data name="global_txtAgentInfo" xml:space="preserve">
    <value>戶口資料</value>
  </data>
  <data name="global_txtAll" xml:space="preserve">
    <value>所有</value>
  </data>
  <data name="global_txtAmount10k" xml:space="preserve">
    <value>金額(萬)</value>
  </data>
  <data name="global_txtBettingMethod" xml:space="preserve">
    <value>投注方法</value>
  </data>
  <data name="global_txtBorrower" xml:space="preserve">
    <value>借款人</value>
  </data>
  <data name="global_txtCage" xml:space="preserve">
    <value>廳</value>
  </data>
  <data name="global_txtCapitalRemark" xml:space="preserve">
    <value>本金備註</value>
  </data>
  <data name="global_txtCardExp_Ext" xml:space="preserve">
    <value>卡消費(外)</value>
  </data>
  <data name="global_txtCardExp_Int" xml:space="preserve">
    <value>卡消費(內)</value>
  </data>
  <data name="global_txtCardType" xml:space="preserve">
    <value>卡類別</value>
  </data>
  <data name="global_txtChipTranGlobalTotalAmount" xml:space="preserve">
    <value>全球結存</value>
  </data>
  <data name="global_txtCName" xml:space="preserve">
    <value>中文姓名</value>
  </data>
  <data name="global_txtComp" xml:space="preserve">
    <value>公司</value>
  </data>
  <data name="global_txtCreditAmt" xml:space="preserve">
    <value>信貸額(萬)</value>
  </data>
  <data name="global_txtCurDateTime" xml:space="preserve">
    <value>記錄時間</value>
  </data>
  <data name="global_txtCurrency" xml:space="preserve">
    <value>貨幣</value>
  </data>
  <data name="global_txtCustName" xml:space="preserve">
    <value>客人名稱</value>
  </data>
  <data name="global_txtCustWinLoss" xml:space="preserve">
    <value>輸贏數(萬)</value>
  </data>
  <data name="global_txtDirectLoan" xml:space="preserve">
    <value>直接信貸</value>
  </data>
  <data name="global_txtEndTime" xml:space="preserve">
    <value>結束時間</value>
  </data>
  <data name="global_txtExpAutoTransfer" xml:space="preserve">
    <value>消費自動轉帳</value>
  </data>
  <data name="global_txtExpenseTerminated" xml:space="preserve">
    <value>停止消費</value>
  </data>
  <data name="global_txtGroupRemark" xml:space="preserve">
    <value>集團備註</value>
  </data>
  <data name="global_txtHKAmount10k" xml:space="preserve">
    <value>HKD金額(萬)</value>
  </data>
  <data name="global_txtHoldChipAmt" xml:space="preserve">
    <value>凍結存款</value>
  </data>
  <data name="global_txtIOUAmount_10K" xml:space="preserve">
    <value>折萛為港幣已簽貸款(萬)</value>
  </data>
  <data name="global_txtIOUTrace" xml:space="preserve">
    <value>信貸監控</value>
  </data>
  <data name="global_txtIOUTraceIncl_CashIOU" xml:space="preserve">
    <value>個人借貸數</value>
  </data>
  <data name="global_txtIOUTraceIncl_Foreign" xml:space="preserve">
    <value>海外數</value>
  </data>
  <data name="global_txtIOUTraceIncl_IOU" xml:space="preserve">
    <value>M數</value>
  </data>
  <data name="global_txtIOUTraceIncl_Operate" xml:space="preserve">
    <value>營運數</value>
  </data>
  <data name="global_txtIsDirectCreditAcc" xml:space="preserve">
    <value>公司授信戶口</value>
  </data>
  <data name="global_txtLastestWinLoss" xml:space="preserve">
    <value>最近輸贏數</value>
  </data>
  <data name="global_txtLeaveRemark" xml:space="preserve">
    <value>離枱備註</value>
  </data>
  <data name="global_txtMemberCardNo" xml:space="preserve">
    <value>會員卡號碼</value>
  </data>
  <data name="global_txtMonth" xml:space="preserve">
    <value>月</value>
  </data>
  <data name="global_txtNo" xml:space="preserve">
    <value>否</value>
  </data>
  <data name="global_txtNumberOfRecord" xml:space="preserve">
    <value>記錄總數</value>
  </data>
  <data name="global_txtPaymentMethod" xml:space="preserve">
    <value>還款方案</value>
  </data>
  <data name="global_txtPenaltyAmt" xml:space="preserve">
    <value>罰息金額</value>
  </data>
  <data name="global_txtRefNo" xml:space="preserve">
    <value>單號碼</value>
  </data>
  <data name="global_txtRemark" xml:space="preserve">
    <value>備註</value>
  </data>
  <data name="global_txtSearchAgent" xml:space="preserve">
    <value>搜尋戶口</value>
  </data>
  <data name="global_txtSelectAll" xml:space="preserve">
    <value>全選</value>
  </data>
  <data name="global_txtShortenForeign" xml:space="preserve">
    <value>海</value>
  </data>
  <data name="global_txtShortenMarker" xml:space="preserve">
    <value>M</value>
  </data>
  <data name="global_txtShortenOperation" xml:space="preserve">
    <value>營</value>
  </data>
  <data name="global_txtShow2ndShareHolderIOU" xml:space="preserve">
    <value>顯示2線股東(股本)M數</value>
  </data>
  <data name="global_txtShowAgentSummaryAgentIOUStatus" xml:space="preserve">
    <value>結存,凍結,罰息</value>
  </data>
  <data name="global_txtShowAgentSummaryCommPay" xml:space="preserve">
    <value>出佣</value>
  </data>
  <data name="global_txtShowAgentSummaryCompCommDrink" xml:space="preserve">
    <value>佣金,積分</value>
  </data>
  <data name="global_txtShowAgentSummaryCompExp" xml:space="preserve">
    <value>消費,前積分</value>
  </data>
  <data name="global_txtShowAgentSummaryCompRoll" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="global_txtShowAgentSummaryCompStore" xml:space="preserve">
    <value>存單,存卡</value>
  </data>
  <data name="global_txtShowAgentSummaryCreditControl" xml:space="preserve">
    <value>還款方案</value>
  </data>
  <data name="global_txtShowAgentSummaryCreditInfo" xml:space="preserve">
    <value>信貸額資料</value>
  </data>
  <data name="global_txtShowAgentSummaryIOUTrace" xml:space="preserve">
    <value>借貸追蹤</value>
  </data>
  <data name="global_txtShowAgentSummaryMarker" xml:space="preserve">
    <value>出M</value>
  </data>
  <data name="global_txtShowAgentSummaryMemberCard" xml:space="preserve">
    <value>會員卡號</value>
  </data>
  <data name="global_txtShowAgentSummaryOrderService" xml:space="preserve">
    <value>訂務</value>
  </data>
  <data name="global_txtShowAgentSummarySelection" xml:space="preserve">
    <value>查詢明細</value>
  </data>
  <data name="global_txtShowAgentSummaryTransaction" xml:space="preserve">
    <value>存/取/轉帳</value>
  </data>
  <data name="global_txtShowAgentSummaryWinLoss" xml:space="preserve">
    <value>輸贏數</value>
  </data>
  <data name="global_txtShowRefresh" xml:space="preserve">
    <value>顯示/更新</value>
  </data>
  <data name="global_txtStartTime" xml:space="preserve">
    <value>開始時間</value>
  </data>
  <data name="global_txtTel" xml:space="preserve">
    <value>電話</value>
  </data>
  <data name="global_txtTempCreditAmt" xml:space="preserve">
    <value>臨時信用額</value>
  </data>
  <data name="global_txtTenk" xml:space="preserve">
    <value>萬</value>
  </data>
  <data name="global_txtTypeCode" xml:space="preserve">
    <value>類型</value>
  </data>
  <data name="global_txtUpdBy" xml:space="preserve">
    <value>經手人</value>
  </data>
  <data name="global_txtWeek" xml:space="preserve">
    <value>週</value>
  </data>
  <data name="global_txtYear" xml:space="preserve">
    <value>年</value>
  </data>
  <data name="global_txtYes" xml:space="preserve">
    <value>是</value>
  </data>
  <data name="txtShowAgentSummaryCompMarker" xml:space="preserve">
    <value>已簽貸款</value>
  </data>
  <data name="txtCompanyDtl" xml:space="preserve">
    <value>公司記錄</value>
  </data>
  <data name="global_msgMissData" xml:space="preserve">
    <value>請輸入所有資料</value>
  </data>
  <data name="global_msgSuccess" xml:space="preserve">
    <value>保存成功</value>
  </data>
  <data name="global_msgFail" xml:space="preserve">
    <value>保存失敗</value>
  </data>
  <data name="global_fnAuthentication" xml:space="preserve">
    <value>認証</value>
  </data>
  <data name="global_fnEditAgent" xml:space="preserve">
    <value>編輯戶口</value>
  </data>
  <data name="global_fnEditCredit" xml:space="preserve">
    <value>編輯信貸額</value>
  </data>
  <data name="global_fnLatestSalary" xml:space="preserve">
    <value>最近糧單</value>
  </data>
  <data name="global_fnNew2ndShareHolderGroup" xml:space="preserve">
    <value>新增二線股東組</value>
  </data>
  <data name="global_fnNewAuthorize" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="global_fnNewChipTranBook" xml:space="preserve">
    <value>新增存卡</value>
  </data>
  <data name="global_fnNewChipTranCash" xml:space="preserve">
    <value>新增存單</value>
  </data>
  <data name="global_fnNewCustWinLossTran" xml:space="preserve">
    <value>新增上下數</value>
  </data>
  <data name="global_fnNewExp" xml:space="preserve">
    <value>新增消費</value>
  </data>
  <data name="global_fnNewMarker" xml:space="preserve">
    <value>新增貸款</value>
  </data>
  <data name="global_fnNewUnderAgent" xml:space="preserve">
    <value>新增下線</value>
  </data>
  <data name="global_fnNewWinLossTran" xml:space="preserve">
    <value>新增客人</value>
  </data>
  <data name="global_fnSettleTranInstant" xml:space="preserve">
    <value>即出佣金</value>
  </data>
  <data name="global_fnStoreCTransferTo" xml:space="preserve">
    <value>內部轉帳</value>
  </data>
  <data name="global_fnWithdrawChipBook" xml:space="preserve">
    <value>綜合理財</value>
  </data>
  <data name="typeStatus_A" xml:space="preserve">
    <value>有效</value>
  </data>
  <data name="typeStatus_T" xml:space="preserve">
    <value>中止</value>
  </data>
  <data name="global_btnEdit" xml:space="preserve">
    <value>修改</value>
  </data>
  <data name="wDate" xml:space="preserve">
    <value>日期</value>
  </data>
  <data name="global_txtDatePeriod" xml:space="preserve">
    <value>時間段</value>
  </data>
  <data name="global_txtTo" xml:space="preserve">
    <value>至</value>
  </data>
  <data name="global_msgCheckFmDate" xml:space="preserve">
    <value>日期需少於 {0}</value>
  </data>
  <data name="global_msgCheckToDate" xml:space="preserve">
    <value>日期需大於 {0}</value>
  </data>
  <data name="global_txtAuComm" xml:space="preserve">
    <value>取佣</value>
  </data>
  <data name="global_txtAuExp" xml:space="preserve">
    <value>簽單</value>
  </data>
  <data name="global_txtAuIOU" xml:space="preserve">
    <value>簽貸款</value>
  </data>
  <data name="global_txtAuOther" xml:space="preserve">
    <value>其他</value>
  </data>
  <data name="global_txtAuRoom" xml:space="preserve">
    <value>取房</value>
  </data>
  <data name="global_txtAuShopping" xml:space="preserve">
    <value>購物</value>
  </data>
  <data name="global_txtAuStore" xml:space="preserve">
    <value>取存碼</value>
  </data>
  <data name="global_txtAuthIdentity" xml:space="preserve">
    <value>授權人身份</value>
  </data>
  <data name="global_txtAuTicket" xml:space="preserve">
    <value>取飛</value>
  </data>
  <data name="global_txtDateOfBirth" xml:space="preserve">
    <value>出生日期</value>
  </data>
  <data name="global_txtEffectYearMth" xml:space="preserve">
    <value>生效日期</value>
  </data>
  <data name="global_txtGunterPassword" xml:space="preserve">
    <value>密碼</value>
  </data>
  <data name="global_btnDisplayDrinkBalSummary" xml:space="preserve">
    <value>顯示食津餘數</value>
  </data>
  <data name="global_btnShownRead" xml:space="preserve">
    <value>顯示/更新</value>
  </data>
  <data name="global_txtAmountByCage" xml:space="preserve">
    <value>用戶各廳概況</value>
  </data>
  <data name="global_txtBFDrinkAmt" xml:space="preserve">
    <value>食津累數</value>
  </data>
  <data name="global_txtBFExpAmt" xml:space="preserve">
    <value>欠前消費</value>
  </data>
  <data name="global_txtBonusPoint" xml:space="preserve">
    <value>贈送積分</value>
  </data>
  <data name="global_txtCageCName" xml:space="preserve">
    <value>廳名</value>
  </data>
  <data name="global_txtChipTranTypeB" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="global_txtChipTranTypeI" xml:space="preserve">
    <value>存單</value>
  </data>
  <data name="global_txtCommission" xml:space="preserve">
    <value>佣金</value>
  </data>
  <data name="global_txtCountryStatus" xml:space="preserve">
    <value>環球概況</value>
  </data>
  <data name="global_txtDrinkNonShare" xml:space="preserve">
    <value>津貼(不共用)</value>
  </data>
  <data name="global_txtDrinkShare" xml:space="preserve">
    <value>津貼(共用)</value>
  </data>
  <data name="global_txtExpenseAmt" xml:space="preserve">
    <value>消費數</value>
  </data>
  <data name="global_txtIOUAmount" xml:space="preserve">
    <value>已簽貸款</value>
  </data>
  <data name="global_txtRollingAmt" xml:space="preserve">
    <value>轉碼數</value>
  </data>
  <data name="global_txtShowCommDrink" xml:space="preserve">
    <value>顯示佣金與津貼</value>
  </data>
  <data name="typeCompAll" xml:space="preserve">
    <value>集團</value>
  </data>
  <data name="global_btnAdv" xml:space="preserve">
    <value>進階</value>
  </data>
  <data name="global_btnCalRealTime" xml:space="preserve">
    <value>即時運算</value>
  </data>
  <data name="global_msgInfoCreditTotalBal" xml:space="preserve">
    <value>一般借貸結餘 = 信貸額結餘 + Ｕ可簽額結餘 + 個人借貸結餘 + 凍結額
*當海外或營運沒有信貸額，其已簽額亦會於一般借貸結餘扣除。</value>
  </data>
  <data name="global_txtAmount" xml:space="preserve">
    <value>金額</value>
  </data>
  <data name="global_txtBalance" xml:space="preserve">
    <value>結餘</value>
  </data>
  <data name="global_txtCapitalTranM" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="global_txtCash_CH" xml:space="preserve">
    <value>個人借貸</value>
  </data>
  <data name="global_txtCasinoCreditAmt" xml:space="preserve">
    <value>娛樂場額</value>
  </data>
  <data name="global_txtCreditAmtU" xml:space="preserve">
    <value>U可簽額</value>
  </data>
  <data name="global_txtCredited" xml:space="preserve">
    <value>已簽額</value>
  </data>
  <data name="global_txtCreditInfo" xml:space="preserve">
    <value>信貸額資料</value>
  </data>
  <data name="global_txtExpired" xml:space="preserve">
    <value>已過期</value>
  </data>
  <data name="global_txtForeign" xml:space="preserve">
    <value>海外</value>
  </data>
  <data name="global_txtIOUFreeze" xml:space="preserve">
    <value>凍結</value>
  </data>
  <data name="global_txtIOUStore" xml:space="preserve">
    <value>暫存/未取</value>
  </data>
  <data name="global_txtIOUTran_SO" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="global_txtNotExpired" xml:space="preserve">
    <value>未過期</value>
  </data>
  <data name="global_txtOperate" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="global_txtOutstandingGroup" xml:space="preserve">
    <value>已簽額</value>
  </data>
  <data name="global_txtSettleStatusOutstanding" xml:space="preserve">
    <value>未結算</value>
  </data>
  <data name="global_txtShowCreditWholeLineGrp" xml:space="preserve">
    <value>顯示全線借貸狀況</value>
  </data>
  <data name="global_txtSpecialIOULoan" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="global_txtSpecialIOUStore" xml:space="preserve">
    <value>存/未取</value>
  </data>
  <data name="global_txtTotalCredit" xml:space="preserve">
    <value>總信貸額</value>
  </data>
  <data name="global_txtTtlExpireOutstanding" xml:space="preserve">
    <value>過期</value>
  </data>
  <data name="global_txtTtlOverOutstanding" xml:space="preserve">
    <value>已超額</value>
  </data>
  <data name="global_txtAgentCard_Elite" xml:space="preserve">
    <value>尊華會卡</value>
  </data>
  <data name="global_txtAgentCard_EliteEmployee" xml:space="preserve">
    <value>尊華員工卡</value>
  </data>
  <data name="global_txtAgentCard_ElitePotential" xml:space="preserve">
    <value>尊華潛質卡</value>
  </data>
  <data name="global_txtAgentCard_Prepaid" xml:space="preserve">
    <value>預付卡</value>
  </data>
  <data name="global_txtAgentCard_SC" xml:space="preserve">
    <value>太陽城卡</value>
  </data>
  <data name="global_txtAgentCard_SCAdditonal" xml:space="preserve">
    <value>太陽城附屬卡</value>
  </data>
  <data name="global_txtEmptyString" xml:space="preserve">
    <value>(空白)</value>
  </data>
  <data name="global_txtGunnerMachine" xml:space="preserve">
    <value>路址機</value>
  </data>
  <data name="global_txtLive" xml:space="preserve">
    <value>現場</value>
  </data>
  <data name="txtCreditControlLst" xml:space="preserve">
    <value>信貸監控</value>
  </data>
  <data name="txtCreditControlContact" xml:space="preserve">
    <value>信貸監控-聯絡資料</value>
  </data>
  <data name="typeRMARKERLSTRPT_Report" xml:space="preserve">
    <value>借貸現況列表</value>
  </data>
  <data name="typeRMARKERRPT_Report" xml:space="preserve">
    <value>借貸現況表</value>
  </data>
  <data name="typeMARKERRPT_ReportGrp" xml:space="preserve">
    <value>借貸現況表</value>
  </data>
  <data name="typeCREDITCONTROLLST_Core" xml:space="preserve">
    <value>信貸監控</value>
  </data>
  <data name="txtAll" xml:space="preserve">
    <value>全部</value>
  </data>
  <data name="txtNewCase" xml:space="preserve">
    <value>新個案</value>
  </data>
  <data name="txtFollowCase" xml:space="preserve">
    <value>待跟進</value>
  </data>
  <data name="txtBookMarkCase" xml:space="preserve">
    <value>關注戶口</value>
  </data>
  <data name="txtBlackListCase" xml:space="preserve">
    <value>黑名單</value>
  </data>
  <data name="wTotalCreditDebit" xml:space="preserve">
    <value>總借貸</value>
  </data>
  <data name="wAlmostDue" xml:space="preserve">
    <value>到期數</value>
  </data>
  <data name="wTotalCredit" xml:space="preserve">
    <value>總信貸額</value>
  </data>
  <data name="wOverdue" xml:space="preserve">
    <value>已過期</value>
  </data>
  <data name="wPenalty" xml:space="preserve">
    <value>罰息</value>
  </data>
  <data name="txtContactPerson" xml:space="preserve">
    <value>聯絡人</value>
  </data>
  <data name="txtCreditRecord" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="txtAssetsRecord" xml:space="preserve">
    <value>資產</value>
  </data>
  <data name="txtContactRecord" xml:space="preserve">
    <value>聯絡記錄</value>
  </data>
  <data name="txtIntroducer" xml:space="preserve">
    <value>推薦人</value>
  </data>
  <data name="txtCredit" xml:space="preserve">
    <value>信貸額</value>
  </data>
  <data name="txtHistory" xml:space="preserve">
    <value>歷史</value>
  </data>
  <data name="txtOtherCageAppCredit" xml:space="preserve">
    <value>其他賭廳信貸額</value>
  </data>
  <data name="txtSO" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="wMthInterest" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="wHold" xml:space="preserve">
    <value>凍結借貸存款</value>
  </data>
  <data name="wIdentity" xml:space="preserve">
    <value>身份</value>
  </data>
  <data name="wPhoto" xml:space="preserve">
    <value>照片</value>
  </data>
  <data name="wRefNo" xml:space="preserve">
    <value>單號</value>
  </data>
  <data name="wBorrower" xml:space="preserve">
    <value>借款人</value>
  </data>
  <data name="wAmount" xml:space="preserve">
    <value>金額</value>
  </data>
  <data name="wOutStanding" xml:space="preserve">
    <value>倘欠</value>
  </data>
  <data name="wDaysPassed" xml:space="preserve">
    <value>已簽天數</value>
  </data>
  <data name="wLastSettleDate" xml:space="preserve">
    <value>最後還款日期</value>
  </data>
  <data name="wType" xml:space="preserve">
    <value>種類</value>
  </data>
  <data name="wValue" xml:space="preserve">
    <value>價值</value>
  </data>
  <data name="wRemark" xml:space="preserve">
    <value>備註</value>
  </data>
  <data name="wAttachFile" xml:space="preserve">
    <value>附件</value>
  </data>
  <data name="wContactDate" xml:space="preserve">
    <value>聯絡日期</value>
  </data>
  <data name="wContactPerson" xml:space="preserve">
    <value>接洽</value>
  </data>
  <data name="wContactMethod" xml:space="preserve">
    <value>聯絡方式</value>
  </data>
  <data name="wResponse" xml:space="preserve">
    <value>回應</value>
  </data>
  <data name="wSolution" xml:space="preserve">
    <value>方案</value>
  </data>
  <data name="wFollowDateTime" xml:space="preserve">
    <value>跟進日期</value>
  </data>
  <data name="wTotaldue" xml:space="preserve">
    <value>總欠款</value>
  </data>
  <data name="wTotalOverdue" xml:space="preserve">
    <value>總過期欠款</value>
  </data>
  <data name="wTotalPenalty" xml:space="preserve">
    <value>總罰息</value>
  </data>
  <data name="global_txtComplete" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="global_txtCutDateTime" xml:space="preserve">
    <value>截更時間</value>
  </data>
  <data name="global_txtInputDate" xml:space="preserve">
    <value>入數日期</value>
  </data>
  <data name="global_txtShiftNo" xml:space="preserve">
    <value>更期</value>
  </data>
  <data name="global_txtShiftCut" xml:space="preserve">
    <value>截更</value>
  </data>
  <data name="txtUsrLst" xml:space="preserve">
    <value>用戶管理</value>
  </data>
  <data name="typeUSRLST_Core" xml:space="preserve">
    <value>用戶管理</value>
  </data>
  <data name="wRoleCd" xml:space="preserve">
    <value>權限</value>
  </data>
  <data name="txtDept" xml:space="preserve">
    <value>部門</value>
  </data>
  <data name="wDtLastLogin" xml:space="preserve">
    <value>最後登入時間</value>
  </data>
  <data name="wName" xml:space="preserve">
    <value>名稱</value>
  </data>
  <data name="wUpdBy" xml:space="preserve">
    <value>經手人</value>
  </data>
  <data name="wUsrId" xml:space="preserve">
    <value>登入名稱</value>
  </data>
  <data name="txtInterestRateLst" xml:space="preserve">
    <value>存款利息管理</value>
  </data>
  <data name="typeINTERESTRATELST_Core" xml:space="preserve">
    <value>存款利息管理</value>
  </data>
  <data name="wYear" xml:space="preserve">
    <value>年</value>
  </data>
  <data name="txtYear" xml:space="preserve">
    <value>年份</value>
  </data>
  <data name="wCurrCodeName" xml:space="preserve">
    <value>貨幣</value>
  </data>
  <data name="wInterestRate" xml:space="preserve">
    <value>利率</value>
  </data>
  <data name="wMonth" xml:space="preserve">
    <value>月</value>
  </data>
  <data name="wUpdDt" xml:space="preserve">
    <value>經手日期</value>
  </data>
  <data name="txtAgentLst" xml:space="preserve">
    <value>戶口列表</value>
  </data>
  <data name="txtConfirmReservationRec" xml:space="preserve">
    <value>確認預約資料</value>
  </data>
  <data name="txtAgentRemarkHisLst" xml:space="preserve">
    <value>戶口備註管理</value>
  </data>
  <data name="txtCustomerLst" xml:space="preserve">
    <value>客人管理</value>
  </data>
  <data name="txtExpTranCardLst" xml:space="preserve">
    <value>卡消費管理</value>
  </data>
  <data name="txtExpTranLst" xml:space="preserve">
    <value>消費管理</value>
  </data>
  <data name="txtExpTranOtherLst" xml:space="preserve">
    <value>欠前消費管理</value>
  </data>
  <data name="txtNewAgentCodeLst" xml:space="preserve">
    <value>開戶格仔表</value>
  </data>
  <data name="txtRoleLst" xml:space="preserve">
    <value>權限管理</value>
  </data>
  <data name="typeAGENTLST_Core" xml:space="preserve">
    <value>戶口列表</value>
  </data>
  <data name="typeAGENTREMARKHISLST_Core" xml:space="preserve">
    <value>戶口備註管理</value>
  </data>
  <data name="typeCUSTOMERLST_Core" xml:space="preserve">
    <value>客人管理</value>
  </data>
  <data name="typeEXPTRANCARDLST_Core" xml:space="preserve">
    <value>卡消費管理</value>
  </data>
  <data name="typeEXPTRANLST_Core" xml:space="preserve">
    <value>消費管理</value>
  </data>
  <data name="typeEXPTRANOTHERLST_Core" xml:space="preserve">
    <value>欠前消費管理</value>
  </data>
  <data name="typeNEWAGENTCODELST_Core" xml:space="preserve">
    <value>開戶格仔表</value>
  </data>
  <data name="typeROLELST_Core" xml:space="preserve">
    <value>權限管理</value>
  </data>
  <data name="txtInterestRateDtl" xml:space="preserve">
    <value>存款利息</value>
  </data>
  <data name="mAgentCode" xml:space="preserve">
    <value>戶口號碼</value>
  </data>
  <data name="wComp" xml:space="preserve">
    <value>公司</value>
  </data>
  <data name="wExpType" xml:space="preserve">
    <value>消費類型</value>
  </data>
  <data name="wMemberCardNo" xml:space="preserve">
    <value>會員卡號碼</value>
  </data>
  <data name="wShopName" xml:space="preserve">
    <value>商戶名稱</value>
  </data>
  <data name="wSumAmount" xml:space="preserve">
    <value>總額</value>
  </data>
  <data name="wTranNo" xml:space="preserve">
    <value>交易編號</value>
  </data>
  <data name="global_txtNumber" xml:space="preserve">
    <value>第</value>
  </data>
  <data name="global_txtShift" xml:space="preserve">
    <value>更</value>
  </data>
  <data name="global_msgErrCannotBeNegativeOrZero" xml:space="preserve">
    <value>數值不可以是負數或為零</value>
  </data>
  <data name="global_msgErrDuplicateRecordInterestRate" xml:space="preserve">
    <value>不可以新增數據與現有地區,月份及年份相同.</value>
  </data>
  <data name="wYearMth" xml:space="preserve">
    <value>週期</value>
  </data>
  <data name="txtAgentDtl" xml:space="preserve">
    <value>戶口記錄</value>
  </data>
  <data name="txtAgentRemarkHisDtl" xml:space="preserve">
    <value>戶口備註記錄</value>
  </data>
  <data name="txtCustomerDtl" xml:space="preserve">
    <value>客人記錄</value>
  </data>
  <data name="txtExpTranCardDtl" xml:space="preserve">
    <value>卡消費記錄</value>
  </data>
  <data name="txtRoleDtl" xml:space="preserve">
    <value>權限管理</value>
  </data>
  <data name="txtUsrDtl" xml:space="preserve">
    <value>用戶管理</value>
  </data>
  <data name="wAgentCode" xml:space="preserve">
    <value>戶口號碼</value>
  </data>
  <data name="wInExp" xml:space="preserve">
    <value>内消费</value>
  </data>
  <data name="wOutExp" xml:space="preserve">
    <value>外消费</value>
  </data>
  <data name="global_txtLogin" xml:space="preserve">
    <value>用戶登入</value>
  </data>
  <data name="global_txtLoginID" xml:space="preserve">
    <value>名稱</value>
  </data>
  <data name="global_txtLoginPassword" xml:space="preserve">
    <value>密碼</value>
  </data>
  <data name="global_txtFixCurrCode" xml:space="preserve">
    <value>固定貨幣</value>
  </data>
  <data name="global_txtThisIsCounter" xml:space="preserve">
    <value>這是帳房柜面電腦</value>
  </data>
  <data name="global_txtCounter" xml:space="preserve">
    <value>櫃</value>
  </data>
  <data name="global_txtCurrCode" xml:space="preserve">
    <value>貨幣</value>
  </data>
  <data name="global_txtCurrRateDivide" xml:space="preserve">
    <value>兌換率(除)</value>
  </data>
  <data name="global_txtCurrRateProduct" xml:space="preserve">
    <value>兌換率(乘)</value>
  </data>
  <data name="global_txtExchangeCurrCode" xml:space="preserve">
    <value>兌換貨幣</value>
  </data>
  <data name="global_txtYearMth" xml:space="preserve">
    <value>週期</value>
  </data>
  <data name="typeCURRENCY_RATE_LST_Core" xml:space="preserve">
    <value>貨幣匯率管理</value>
  </data>
  <data name="wConfPwd" xml:space="preserve">
    <value>確認新密碼</value>
  </data>
  <data name="wNewPwd" xml:space="preserve">
    <value>新密碼</value>
  </data>
  <data name="wStaffSMS" xml:space="preserve">
    <value>SMS號碼</value>
  </data>
  <data name="wTerminationDate" xml:space="preserve">
    <value>終止日期</value>
  </data>
  <data name="txtInputPeriod" xml:space="preserve">
    <value>輸入期</value>
  </data>
  <data name="txtProcessPeriod" xml:space="preserve">
    <value>執行期</value>
  </data>
  <data name="txtReturnAmount" xml:space="preserve">
    <value>歸還額</value>
  </data>
  <data name="txtBFAmt" xml:space="preserve">
    <value>前欠費</value>
  </data>
  <data name="txtOutstandAmt" xml:space="preserve">
    <value>餘額</value>
  </data>
  <data name="txtAgentCode" xml:space="preserve">
    <value>戶口</value>
  </data>
  <data name="txtBFAmtHKD" xml:space="preserve">
    <value>HKD前欠費</value>
  </data>
  <data name="wCurrRate" xml:space="preserve">
    <value>兌換率</value>
  </data>
  <data name="txtCurrRateDesc" xml:space="preserve">
    <value>換率為匯至港幣換率</value>
  </data>
  <data name="wNickName" xml:space="preserve">
    <value>別名</value>
  </data>
  <data name="wIDNo" xml:space="preserve">
    <value>證件號碼</value>
  </data>
  <data name="wFeatureRemark" xml:space="preserve">
    <value>客人特徵</value>
  </data>
  <data name="wCurDateTime" xml:space="preserve">
    <value>時間</value>
  </data>
  <data name="wHavePic" xml:space="preserve">
    <value>有照片</value>
  </data>
  <data name="wLikeRemark" xml:space="preserve">
    <value>客人喜好</value>
  </data>
  <data name="wCustName" xml:space="preserve">
    <value>客人名稱</value>
  </data>
  <data name="wExpDesc" xml:space="preserve">
    <value>消費</value>
  </data>
  <data name="wExpTypeCode" xml:space="preserve">
    <value>消費項目</value>
  </data>
  <data name="wPrice" xml:space="preserve">
    <value>單價</value>
  </data>
  <data name="wRoomBookDt" xml:space="preserve">
    <value>訂房時間</value>
  </data>
  <data name="wRoomCfmCode" xml:space="preserve">
    <value>確認號碼</value>
  </data>
  <data name="wRoomCheckInDt" xml:space="preserve">
    <value>入住日期</value>
  </data>
  <data name="wRoomDeptDt" xml:space="preserve">
    <value>退房日期</value>
  </data>
  <data name="wRoomExpAmt" xml:space="preserve">
    <value>房消費</value>
  </data>
  <data name="wRoomNo" xml:space="preserve">
    <value>房號</value>
  </data>
  <data name="wUnit" xml:space="preserve">
    <value>數量</value>
  </data>
  <data name="wVoucherDt" xml:space="preserve">
    <value>單日期</value>
  </data>
  <data name="wVoucherNo" xml:space="preserve">
    <value>單編號</value>
  </data>
  <data name="txtLineGrp" xml:space="preserve">
    <value>線組</value>
  </data>
  <data name="txtReadDept" xml:space="preserve">
    <value>顯示部門</value>
  </data>
  <data name="wCrtBy" xml:space="preserve">
    <value>建立者</value>
  </data>
  <data name="wCrtDt" xml:space="preserve">
    <value>建立日期</value>
  </data>
  <data name="wForCompNo" xml:space="preserve">
    <value>顯示公司</value>
  </data>
  <data name="wImportance" xml:space="preserve">
    <value>重要性</value>
  </data>
  <data name="wUpdByLastCName" xml:space="preserve">
    <value>最後經手人</value>
  </data>
  <data name="wEffectYearMth" xml:space="preserve">
    <value>有效日期</value>
  </data>
  <data name="wSex" xml:space="preserve">
    <value>性別</value>
  </data>
  <data name="txtAgentType" xml:space="preserve">
    <value>戶口類型</value>
  </data>
  <data name="txtUnderAgent" xml:space="preserve">
    <value>下線</value>
  </data>
  <data name="txtUpperAgent" xml:space="preserve">
    <value>上線</value>
  </data>
  <data name="wAccountType" xml:space="preserve">
    <value>會員級別</value>
  </data>
  <data name="wAgentLevel" xml:space="preserve">
    <value>層數</value>
  </data>
  <data name="txtExpSite" xml:space="preserve">
    <value>消費場地</value>
  </data>
  <data name="wInputDate" xml:space="preserve">
    <value>入數日期</value>
  </data>
  <data name="wShift" xml:space="preserve">
    <value>更期</value>
  </data>
  <data name="wHotelType" xml:space="preserve">
    <value>酒店類型</value>
  </data>
  <data name="wRoomType" xml:space="preserve">
    <value>房間類型</value>
  </data>
  <data name="wDept" xml:space="preserve">
    <value>部門</value>
  </data>
  <data name="txtRefresh" xml:space="preserve">
    <value>刷新</value>
  </data>
  <data name="txtHKDFxRate" xml:space="preserve">
    <value>港幣兌換率</value>
  </data>
  <data name="txtRMBFxRate" xml:space="preserve">
    <value>人民幣兌換率</value>
  </data>
  <data name="wBirthDate" xml:space="preserve">
    <value>出生日期</value>
  </data>
  <data name="wBirthNationality" xml:space="preserve">
    <value>出生地點</value>
  </data>
  <data name="wNationality" xml:space="preserve">
    <value>國籍</value>
  </data>
  <data name="global_btnClear" xml:space="preserve">
    <value>清除</value>
  </data>
  <data name="global_btnUpload" xml:space="preserve">
    <value>上傳</value>
  </data>
  <data name="txtUploadAppForm" xml:space="preserve">
    <value>申請表</value>
  </data>
  <data name="txtUploadID" xml:space="preserve">
    <value>身份證明文件</value>
  </data>
  <data name="txtUploadPassport" xml:space="preserve">
    <value>護照</value>
  </data>
  <data name="txtUploadPhoto" xml:space="preserve">
    <value>照片</value>
  </data>
  <data name="wAddress" xml:space="preserve">
    <value>聯絡地址</value>
  </data>
  <data name="wIDType" xml:space="preserve">
    <value>證件類型</value>
  </data>
  <data name="wOccupation" xml:space="preserve">
    <value>職業</value>
  </data>
  <data name="wPost" xml:space="preserve">
    <value>職位</value>
  </data>
  <data name="global_msgImportance" xml:space="preserve">
    <value>5為最重要,將會在所有輸入版面顯示</value>
  </data>
  <data name="global_txtDept" xml:space="preserve">
    <value>部門</value>
  </data>
  <data name="global_btnAddOneDay" xml:space="preserve">
    <value>+1 日</value>
  </data>
  <data name="global_btnAddOneMonth" xml:space="preserve">
    <value>+1 月</value>
  </data>
  <data name="global_btnAddOneWeek" xml:space="preserve">
    <value>+1 週</value>
  </data>
  <data name="global_btnNever" xml:space="preserve">
    <value>永不</value>
  </data>
  <data name="global_btnStop" xml:space="preserve">
    <value>停用</value>
  </data>
  <data name="global_txtFilter" xml:space="preserve">
    <value>過濾器</value>
  </data>
  <data name="global_txtLevel" xml:space="preserve">
    <value>層</value>
  </data>
  <data name="global_txtNameHidden" xml:space="preserve">
    <value>包括下線(不顯示下線名)</value>
  </data>
  <data name="global_txtNameShow" xml:space="preserve">
    <value>包括下線(顯示下線名)</value>
  </data>
  <data name="global_txtStanda" xml:space="preserve">
    <value>單一</value>
  </data>
  <data name="global_txtUnSelectAll" xml:space="preserve">
    <value>不選</value>
  </data>
  <data name="typeCreditControl_A" xml:space="preserve">
    <value>待跟進</value>
  </data>
  <data name="typeCreditControl_T" xml:space="preserve">
    <value>已跟進</value>
  </data>
  <data name="txtCutOffDate" xml:space="preserve">
    <value>截數日期</value>
  </data>
  <data name="wIOUType" xml:space="preserve">
    <value>借貸類</value>
  </data>
  <data name="wOverdueDay" xml:space="preserve">
    <value>過期日數</value>
  </data>
  <data name="global_optCashType_CH" xml:space="preserve">
    <value>個人借貸</value>
  </data>
  <data name="global_optCashType_IOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="global_optMarker_C" xml:space="preserve">
    <value>已歸還</value>
  </data>
  <data name="global_optMarker_O" xml:space="preserve">
    <value>未歸還</value>
  </data>
  <data name="txtSearchType" xml:space="preserve">
    <value>搜尋類型</value>
  </data>
  <data name="global_optMarker_M" xml:space="preserve">
    <value>過期M</value>
  </data>
  <data name="txtIncludePartner" xml:space="preserve">
    <value>包括外柜數</value>
  </data>
  <data name="wOtherSocialMedia" xml:space="preserve">
    <value>其它電子聯絡方式</value>
  </data>
  <data name="wPinyin" xml:space="preserve">
    <value>拼音</value>
  </data>
  <data name="wProvince" xml:space="preserve">
    <value>省份</value>
  </data>
  <data name="wQQ" xml:space="preserve">
    <value>QQ</value>
  </data>
  <data name="wShareJoinDate" xml:space="preserve">
    <value>入股日期</value>
  </data>
  <data name="wSMS_Remark" xml:space="preserve">
    <value>短訊</value>
  </data>
  <data name="wStoreLock" xml:space="preserve">
    <value>鎖卡</value>
  </data>
  <data name="wStoreNegative" xml:space="preserve">
    <value>可負數卡</value>
  </data>
  <data name="wStoreNoInt" xml:space="preserve">
    <value>停息</value>
  </data>
  <data name="wTelOther" xml:space="preserve">
    <value>其他電話</value>
  </data>
  <data name="wTelSMS" xml:space="preserve">
    <value>存款號碼</value>
  </data>
  <data name="wTelSMS_Exp" xml:space="preserve">
    <value>消費號碼</value>
  </data>
  <data name="wTelSMS_Foreign" xml:space="preserve">
    <value>海外圍號碼</value>
  </data>
  <data name="wTelSMS_IOU" xml:space="preserve">
    <value>貸款號碼</value>
  </data>
  <data name="wTelSMS_OpIntroducer" xml:space="preserve">
    <value>營運來貨號碼</value>
  </data>
  <data name="wTelSMS_Roll" xml:space="preserve">
    <value>轉碼號碼</value>
  </data>
  <data name="wUpLvlAgent" xml:space="preserve">
    <value>上層代理</value>
  </data>
  <data name="wWeChat" xml:space="preserve">
    <value>微信</value>
  </data>
  <data name="wWhatsapp" xml:space="preserve">
    <value>What''s app</value>
  </data>
  <data name="txtArea" xml:space="preserve">
    <value>地區</value>
  </data>
  <data name="txtExpAutoTransfer" xml:space="preserve">
    <value>消費自動轉賬</value>
  </data>
  <data name="txtExpenseTerminated" xml:space="preserve">
    <value>停止消費</value>
  </data>
  <data name="txtFrequency" xml:space="preserve">
    <value>頻率</value>
  </data>
  <data name="txtIsBindingMobileSunApps" xml:space="preserve">
    <value>綁定太陽城手機應用程式</value>
  </data>
  <data name="txtIsNameCardProvided" xml:space="preserve">
    <value>提供卡片</value>
  </data>
  <data name="txtNumberOfTimes" xml:space="preserve">
    <value>次數</value>
  </data>
  <data name="txtOther" xml:space="preserve">
    <value>其他</value>
  </data>
  <data name="txtOtherCage" xml:space="preserve">
    <value>其他所屬貴賓廳</value>
  </data>
  <data name="txtOtherCageCredit" xml:space="preserve">
    <value>其他貴賓信用額</value>
  </data>
  <data name="txtOtherCageType" xml:space="preserve">
    <value>該貴賓廳之身份</value>
  </data>
  <data name="txtOverseasVIPExp" xml:space="preserve">
    <value>曾經到海外出圍的經驗</value>
  </data>
  <data name="txtRelativesEmployedBySuncityGroup" xml:space="preserve">
    <value>於集團是否有親屬</value>
  </data>
  <data name="txtStatusNo" xml:space="preserve">
    <value>否</value>
  </data>
  <data name="txtStatusYes" xml:space="preserve">
    <value>是</value>
  </data>
  <data name="wAgentCreateAmt" xml:space="preserve">
    <value>開戶金額</value>
  </data>
  <data name="wAssetsReport" xml:space="preserve">
    <value>資產總值(港幣)</value>
  </data>
  <data name="wIntroducerCodeIn1" xml:space="preserve">
    <value>介紹人1</value>
  </data>
  <data name="wIntroducerCodeIn2" xml:space="preserve">
    <value>介紹人2</value>
  </data>
  <data name="wIsDirectCreditAcc" xml:space="preserve">
    <value>公司授信戶口</value>
  </data>
  <data name="txtIsDirectCreditAcc" xml:space="preserve">
    <value>直接授信</value>
  </data>
  <data name="wLang1" xml:space="preserve">
    <value>主語言</value>
  </data>
  <data name="wTelSMS_CHN" xml:space="preserve">
    <value>中國(+86)</value>
  </data>
  <data name="wTelSMS_HK" xml:space="preserve">
    <value>香港(+852)</value>
  </data>
  <data name="wTelSMS_MAC" xml:space="preserve">
    <value>澳門(+853)</value>
  </data>
  <data name="wTerminateDate" xml:space="preserve">
    <value>終止日期</value>
  </data>
  <data name="wWrittenLang" xml:space="preserve">
    <value>文字訊息</value>
  </data>
  <data name="global_txtAddNewCurr" xml:space="preserve">
    <value>新增貨幣</value>
  </data>
  <data name="global_txtCurrCName" xml:space="preserve">
    <value>貨幣中文名</value>
  </data>
  <data name="global_txtCurrEName" xml:space="preserve">
    <value>貨幣英文名</value>
  </data>
  <data name="global_txtCurrencyCode" xml:space="preserve">
    <value>貨幣碼</value>
  </data>
  <data name="global_txtToCurrCode" xml:space="preserve">
    <value>兌換貨幣</value>
  </data>
  <data name="txtChipTranB" xml:space="preserve">
    <value>存卡管理</value>
  </data>
  <data name="typeSTORE_Core" xml:space="preserve">
    <value>存取</value>
  </data>
  <data name="typeCHIPTRAN_B_LST_Core" xml:space="preserve">
    <value>存卡管理</value>
  </data>
  <data name="global_msgInvalidInputData" xml:space="preserve">
    <value>輸入資料不正確</value>
  </data>
  <data name="wDepositor" xml:space="preserve">
    <value>存款人</value>
  </data>
  <data name="wCashChip_Tenk" xml:space="preserve">
    <value>現碼(萬)</value>
  </data>
  <data name="wCashChip_ToNew_Tenk" xml:space="preserve">
    <value>結存(萬)</value>
  </data>
  <data name="wTranType" xml:space="preserve">
    <value>類型</value>
  </data>
  <data name="typeChipTran_CR" xml:space="preserve">
    <value>提取</value>
  </data>
  <data name="typeChipTran_CS" xml:space="preserve">
    <value>存入</value>
  </data>
  <data name="global_txtMissingIVRPwd" xml:space="preserve">
    <value>未設密碼</value>
  </data>
  <data name="global_wStoreLock" xml:space="preserve">
    <value>鎖卡</value>
  </data>
  <data name="typeAGENTFIRSTCHECKINRPT_ReportGrp" xml:space="preserve">
    <value>戶口開場查詢資料列表</value>
  </data>
  <data name="typeAGENTINFORPT_ReportGrp" xml:space="preserve">
    <value>戶口資料表</value>
  </data>
  <data name="typeAGENTLEVELLSTRPT_ReportGrp" xml:space="preserve">
    <value>戶口層級樹列表</value>
  </data>
  <data name="typeAGEXWITHOUTROLSTRPT_ReportGrp" xml:space="preserve">
    <value>消費(無轉碼)報表</value>
  </data>
  <data name="typeAGWLYEARMTHRPT_ReportGrp" xml:space="preserve">
    <value>上下數月結總表</value>
  </data>
  <data name="typeCHIPSTORE1RPT_Report" xml:space="preserve">
    <value>存碼細數表</value>
  </data>
  <data name="typeRCHIPTRANRPT_Report" xml:space="preserve">
    <value>存碼出入數表</value>
  </data>
  <data name="typeCOUNTERBALAUDITRPT_ReportGrp" xml:space="preserve">
    <value>賬房銀頭報表</value>
  </data>
  <data name="typeCREDITCONTROLRPT_ReportGrp" xml:space="preserve">
    <value>信用監控列表</value>
  </data>
  <data name="typeCREDITTRANRPT_ReportGrp" xml:space="preserve">
    <value>借貸批額</value>
  </data>
  <data name="typeCRMAGENTRPT_ReportGrp" xml:space="preserve">
    <value>市場部報表</value>
  </data>
  <data name="typeCUSTSTAYINFORPT_ReportGrp" xml:space="preserve">
    <value>戶口留擡時間報表</value>
  </data>
  <data name="typeCUSTWINLOSSRPT_ReportGrp" xml:space="preserve">
    <value>上下數報表</value>
  </data>
  <data name="typeDEPOSITCONDRPT_ReportGrp" xml:space="preserve">
    <value>存碼報表</value>
  </data>
  <data name="typeEXPENSEBFRPT_ReportGrp" xml:space="preserve">
    <value>欠前消費報表</value>
  </data>
  <data name="typeFOODDRINKBFRPT_ReportGrp" xml:space="preserve">
    <value>食津累數報表</value>
  </data>
  <data name="typeFORSPECMARKRPT_ReportGrp" xml:space="preserve">
    <value>海外借貸報表</value>
  </data>
  <data name="typeGAMINGCOMMISSIONRPT_ReportGrp" xml:space="preserve">
    <value>J11及J12博彩佣金報表</value>
  </data>
  <data name="typeINTERESTRATELSTRPT_ReportGrp" xml:space="preserve">
    <value>月結派息總報表</value>
  </data>
  <data name="typeIOUPENALTYSTARPT_ReportGrp" xml:space="preserve">
    <value>罰息現況報表</value>
  </data>
  <data name="typeIOUPENASETTLERPT_ReportGrp" xml:space="preserve">
    <value>罰息歸還報表</value>
  </data>
  <data name="typeMTEADJREPFORACRPT_ReportGrp" xml:space="preserve">
    <value>月結前調整報表</value>
  </data>
  <data name="typeOPERATEEXTERNALRPT_ReportGrp" xml:space="preserve">
    <value>私營報表</value>
  </data>
  <data name="typeRAGENTINFORPT_Report" xml:space="preserve">
    <value>戶口資料表</value>
  </data>
  <data name="typeRAGENTLEVELLSTRPT_Report" xml:space="preserve">
    <value>戶口層級樹列表</value>
  </data>
  <data name="typeRAGEXWITHOUTROLLSTRPT_Report" xml:space="preserve">
    <value>消費(無轉碼)報表</value>
  </data>
  <data name="typeRAGFIRCHECKININRPT_Report" xml:space="preserve">
    <value>戶口開場查詢資料列表</value>
  </data>
  <data name="typeRAGWLYEARMTHRPT_Report" xml:space="preserve">
    <value>上下數月結總表</value>
  </data>
  <data name="typeRCOUNTERBALAUDITRPT_Report" xml:space="preserve">
    <value>賬房銀頭報表</value>
  </data>
  <data name="typeRCREDITCONTROLRPT_Report" xml:space="preserve">
    <value>信用監控列表</value>
  </data>
  <data name="typeRCRMAGENTRPT_Report" xml:space="preserve">
    <value>過濾器</value>
  </data>
  <data name="typeRCUSTSTAYINFORPT_Report" xml:space="preserve">
    <value>戶口留擡時間報表</value>
  </data>
  <data name="typeRCUSTWINLOSSRPT_Report" xml:space="preserve">
    <value>上下數報表</value>
  </data>
  <data name="typeREMITTANCERPT_ReportGrp" xml:space="preserve">
    <value>匯款報表</value>
  </data>
  <data name="typeREMOTEOPERATIONRPT_ReportGrp" xml:space="preserve">
    <value>遙距指令報表</value>
  </data>
  <data name="typeREXPENSEBFRPT_Report" xml:space="preserve">
    <value>欠前消費報表</value>
  </data>
  <data name="typeREXPENSEBFSUMRPT_Report" xml:space="preserve">
    <value>下線欠前消費報表</value>
  </data>
  <data name="typeRFOODDRINKBFRPT_Report" xml:space="preserve">
    <value>食津累數報表</value>
  </data>
  <data name="typeRFORSPECIALMARKERRPT_Report" xml:space="preserve">
    <value>借貸現況表</value>
  </data>
  <data name="typeRFORSPECMARKLSTRPT_Report" xml:space="preserve">
    <value>借貸現況列表</value>
  </data>
  <data name="typeRFORSPECMARKTRANRPT_Report" xml:space="preserve">
    <value>借貸提存表</value>
  </data>
  <data name="typeRGAMINGCOMMISRPT_Report" xml:space="preserve">
    <value>J11及J12博彩佣金報表</value>
  </data>
  <data name="typeRINTERESTRATERPT_Report" xml:space="preserve">
    <value>月結派息總報表</value>
  </data>
  <data name="typeRIOUPENALTYSTARPT_Report" xml:space="preserve">
    <value>罰息現況報表</value>
  </data>
  <data name="typeRIOUPENASETTLERPT_Report" xml:space="preserve">
    <value>罰息歸還報表</value>
  </data>
  <data name="typeRMTEADJREPFORACRPT_Report" xml:space="preserve">
    <value>會計部用</value>
  </data>
  <data name="typeROLLING1RPT_Report" xml:space="preserve">
    <value>轉碼總數表</value>
  </data>
  <data name="typeROLLING2RPT_Report" xml:space="preserve">
    <value>轉碼細數表</value>
  </data>
  <data name="typeROLLINGRPT_ReportGrp" xml:space="preserve">
    <value>轉碼報表</value>
  </data>
  <data name="typeROPERATEEXTERNALRPT_Report" xml:space="preserve">
    <value>私營報表</value>
  </data>
  <data name="typeROVERPT_ReportGrp" xml:space="preserve">
    <value>巨額報表</value>
  </data>
  <data name="typeRPTCREDITTRANRPT_Report" xml:space="preserve">
    <value>借貸批額報表</value>
  </data>
  <data name="typeRREMITTANCERPT_Report" xml:space="preserve">
    <value>匯款報表</value>
  </data>
  <data name="typeRREMOTEOPERATIONRPT_Report" xml:space="preserve">
    <value>遙距指令報表</value>
  </data>
  <data name="typeRROLLINGDAILYRPT_Report" xml:space="preserve">
    <value>轉碼日報表</value>
  </data>
  <data name="typeRROLLINGLISTDTLRPT_Report" xml:space="preserve">
    <value>轉碼細數列表</value>
  </data>
  <data name="typeRROVETRANRPT_Report" xml:space="preserve">
    <value>巨額報表</value>
  </data>
  <data name="typeCHIPSTORE2RPT_Report" xml:space="preserve">
    <value>存碼現況總數表</value>
  </data>
  <data name="typeRRPTMTHINTERESTRPT_Report" xml:space="preserve">
    <value>已派月息報表</value>
  </data>
  <data name="typeRSALARYSETTLELSTRPT_Report" xml:space="preserve">
    <value>月結出量總表</value>
  </data>
  <data name="typeRSETTTRANINSLSTRPT_Report" xml:space="preserve">
    <value>即出報表</value>
  </data>
  <data name="typeRSMSTYPERPT_Report" xml:space="preserve">
    <value>戶口SMS類型表</value>
  </data>
  <data name="typeRSPECIALMARKERRPT_Report" xml:space="preserve">
    <value>借貸現況表</value>
  </data>
  <data name="typeRSPECMARKLSTRPT_Report" xml:space="preserve">
    <value>借貸現況列表</value>
  </data>
  <data name="typeRSPECMARKTRANRPT_Report" xml:space="preserve">
    <value>借貸提存表</value>
  </data>
  <data name="typeRSUGTRANSTATRPT_Report" xml:space="preserve">
    <value>客人特徵及部門備註統計表</value>
  </data>
  <data name="typeRTOPVIPROLLTREERPT_Report" xml:space="preserve">
    <value>VIP轉碼報表</value>
  </data>
  <data name="typeRUSERENQUIRYLOGRPT_Report" xml:space="preserve">
    <value>用戶監察表</value>
  </data>
  <data name="typeRVIPINOUTTIMERPT_Report" xml:space="preserve">
    <value>VIP進出時間報表</value>
  </data>
  <data name="typeRVIPUSAGERPT_Report" xml:space="preserve">
    <value>貴賓房使用率報表</value>
  </data>
  <data name="typeSALARYSETTLELSTRPT_ReportGrp" xml:space="preserve">
    <value>月結出量總表</value>
  </data>
  <data name="typeSETTLEINSTANTLSTRPT_ReportGrp" xml:space="preserve">
    <value>即出報表</value>
  </data>
  <data name="typeSMSTYPERPT_ReportGrp" xml:space="preserve">
    <value>戶口SMS類型資料表</value>
  </data>
  <data name="typeSPECIALMARKERRPT_ReportGrp" xml:space="preserve">
    <value>營運借貸報表</value>
  </data>
  <data name="typeSUGTRANSTATRPT_ReportGrp" xml:space="preserve">
    <value>客人特徵及部門備註統計表</value>
  </data>
  <data name="typeTOPVIPROLLTREERPT_ReportGrp" xml:space="preserve">
    <value>VIP轉碼報表</value>
  </data>
  <data name="typeUSERENQUIRYLOGLSTRPT_ReportGrp" xml:space="preserve">
    <value>用戶監察表</value>
  </data>
  <data name="typeVIPINOUTTIMERPT_ReportGrp" xml:space="preserve">
    <value>VIP進出時間報表</value>
  </data>
  <data name="typeVIPUSAGERPT_ReportGrp" xml:space="preserve">
    <value>貴賓房使用率報表</value>
  </data>
  <data name="typeRMARKERLSTTRANRPT_Report" xml:space="preserve">
    <value>借貸還款列表</value>
  </data>
  <data name="typeRMARKERTRANRPT_Report" xml:space="preserve">
    <value>借貸提存表</value>
  </data>
  <data name="typeRMARKRETTYLSTRPT_Report" xml:space="preserve">
    <value>借貸歸還類別報表</value>
  </data>
  <data name="global_txtAgentAccountType1" xml:space="preserve">
    <value>太陽客戶</value>
  </data>
  <data name="global_txtAgentAccountType2" xml:space="preserve">
    <value>金太陽</value>
  </data>
  <data name="global_txtAgentAccountType3" xml:space="preserve">
    <value>卓越</value>
  </data>
  <data name="global_txtAgentAccountType4" xml:space="preserve">
    <value>非凡</value>
  </data>
  <data name="global_txtAgentAccountType5" xml:space="preserve">
    <value>奇蹟</value>
  </data>
  <data name="global_txtAgentAccountType6" xml:space="preserve">
    <value>傳奇</value>
  </data>
  <data name="global_txtAgentAccountType7" xml:space="preserve">
    <value>至尊</value>
  </data>
  <data name="wHoldCommission" xml:space="preserve">
    <value>凍結出佣</value>
  </data>
  <data name="wIsDelay" xml:space="preserve">
    <value>延期歸還</value>
  </data>
  <data name="wReqNotification" xml:space="preserve">
    <value>訊息提醒</value>
  </data>
  <data name="global_btnSameAbove" xml:space="preserve">
    <value>同上</value>
  </data>
  <data name="global_msgInfoTelFormat" xml:space="preserve">
    <value>格式: +(國家號碼)(電話號碼), 例子: +85223456789</value>
  </data>
  <data name="txtAcctFormNumber" xml:space="preserve">
    <value>開戶編號</value>
  </data>
  <data name="txtAgentCodeOld" xml:space="preserve">
    <value>原戶口號碼</value>
  </data>
  <data name="txtCashIOUContractNo" xml:space="preserve">
    <value>個人借貸合同號</value>
  </data>
  <data name="txtIDExpireDate" xml:space="preserve">
    <value>證件到期日</value>
  </data>
  <data name="txtIOUContractNo" xml:space="preserve">
    <value>借貸合同號</value>
  </data>
  <data name="txtSmsTelSingleRoom" xml:space="preserve">
    <value>短訊使用單一號碼</value>
  </data>
  <data name="wAgentCreateDate" xml:space="preserve">
    <value>開戶日期</value>
  </data>
  <data name="wAgentType" xml:space="preserve">
    <value>戶口類型</value>
  </data>
  <data name="wCity" xml:space="preserve">
    <value>城市</value>
  </data>
  <data name="wCounty" xml:space="preserve">
    <value>縣</value>
  </data>
  <data name="wIntroducerStaff" xml:space="preserve">
    <value>員工介紹人</value>
  </data>
  <data name="wIsShareGrp" xml:space="preserve">
    <value>股東組</value>
  </data>
  <data name="wLevelType" xml:space="preserve">
    <value>級別</value>
  </data>
  <data name="wLine" xml:space="preserve">
    <value>Line</value>
  </data>
  <data name="txtDateRange" xml:space="preserve">
    <value>日期範圍</value>
  </data>
  <data name="txtMeeting" xml:space="preserve">
    <value>會面</value>
  </data>
  <data name="txtInstantCommCard" xml:space="preserve">
    <value>即出咭戶口</value>
  </data>
  <data name="txtMinCheckInCapital" xml:space="preserve">
    <value>開場最低金額(萬)</value>
  </data>
  <data name="txtReport" xml:space="preserve">
    <value>報表</value>
  </data>
  <data name="wLineGrp" xml:space="preserve">
    <value>外圍代號</value>
  </data>
  <data name="wUsrName" xml:space="preserve">
    <value>用戶名稱</value>
  </data>
  <data name="txtCreditControlShowAll" xml:space="preserve">
    <value>顯示所有(包括壞賬及凍結)</value>
  </data>
  <data name="txtDateTo" xml:space="preserve">
    <value>至</value>
  </data>
  <data name="txtDirectCreditAcc" xml:space="preserve">
    <value>只顯示公司授信戶口</value>
  </data>
  <data name="txtFunction" xml:space="preserve">
    <value>功能</value>
  </data>
  <data name="txtGift" xml:space="preserve">
    <value>禮品</value>
  </data>
  <data name="txtIncludeTerminalAgent" xml:space="preserve">
    <value>包括已終止戶口</value>
  </data>
  <data name="txtIncludeTerminalHistory" xml:space="preserve">
    <value>包括己終止歷史記錄</value>
  </data>
  <data name="txtOnlyBadDebt" xml:space="preserve">
    <value>只顯示壞賬</value>
  </data>
  <data name="txtOnlyFreeze" xml:space="preserve">
    <value>只顯示凍結</value>
  </data>
  <data name="txtShowCashLoanInt" xml:space="preserve">
    <value>個人借貸(萬)</value>
  </data>
  <data name="txtShowForeignCredit" xml:space="preserve">
    <value>海外借貸(萬)</value>
  </data>
  <data name="txtShowMthInt" xml:space="preserve">
    <value>月息(萬)</value>
  </data>
  <data name="txtShowShareCredit" xml:space="preserve">
    <value>股本(萬)</value>
  </data>
  <data name="txtShowUCredit" xml:space="preserve">
    <value>可簽額(萬)</value>
  </data>
  <data name="txtShowUCredit_Share" xml:space="preserve">
    <value>U可簽額(萬)</value>
  </data>
  <data name="txtShowYellowCredit" xml:space="preserve">
    <value>營運借貸(萬)</value>
  </data>
  <data name="wReturnDayRemind" xml:space="preserve">
    <value>還款日提醒</value>
  </data>
  <data name="txtPhone" xml:space="preserve">
    <value>電話</value>
  </data>
  <data name="global_txtGenerateData" xml:space="preserve">
    <value>生成數據(預視用)</value>
  </data>
  <data name="global_txtInterRate" xml:space="preserve">
    <value>確認此月份派息</value>
  </data>
  <data name="global_txtPreInfo" xml:space="preserve">
    <value>顯示預示材料</value>
  </data>
  <data name="action_EDIT_type" xml:space="preserve">
    <value>修改</value>
  </data>
  <data name="action_EXPORT_type" xml:space="preserve">
    <value>匯出</value>
  </data>
  <data name="action_INSERT_type" xml:space="preserve">
    <value>新增</value>
  </data>
  <data name="action_LOADDATA_type" xml:space="preserve">
    <value>LOADDATA</value>
  </data>
  <data name="action_MENU_type" xml:space="preserve">
    <value>菜單</value>
  </data>
  <data name="action_PRINT_type" xml:space="preserve">
    <value>列印</value>
  </data>
  <data name="action_REFRESH_type" xml:space="preserve">
    <value>重新搜尋</value>
  </data>
  <data name="action_REPORTGRP_type" xml:space="preserve">
    <value>報表GRP</value>
  </data>
  <data name="action_REPORT_type" xml:space="preserve">
    <value>報表</value>
  </data>
  <data name="action_RESET_type" xml:space="preserve">
    <value>重置</value>
  </data>
  <data name="action_SEARCH_type" xml:space="preserve">
    <value>搜尋</value>
  </data>
  <data name="action_UPDATE_type" xml:space="preserve">
    <value>更新</value>
  </data>
  <data name="global_btnAddNewBFExp" xml:space="preserve">
    <value>新增欠費</value>
  </data>
  <data name="global_btnAddNewBFExpRtn" xml:space="preserve">
    <value>新增欠費歸還</value>
  </data>
  <data name="txtAddCapital" xml:space="preserve">
    <value>加彩</value>
  </data>
  <data name="txtChipTranTypeB" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="txtRoll" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="txtRptByDay" xml:space="preserve">
    <value>日表</value>
  </data>
  <data name="txtRptByMonth" xml:space="preserve">
    <value>月表</value>
  </data>
  <data name="txtRptByWeek" xml:space="preserve">
    <value>週表</value>
  </data>
  <data name="txtStore_Marker" xml:space="preserve">
    <value>存M</value>
  </data>
  <data name="wRemittanceDeposit" xml:space="preserve">
    <value>入數</value>
  </data>
  <data name="wRemittanceWithdraw" xml:space="preserve">
    <value>出數</value>
  </data>
  <data name="txtAddAmt" xml:space="preserve">
    <value>加額</value>
  </data>
  <data name="txtCancelCreditTypeStopM" xml:space="preserve">
    <value>解除停M</value>
  </data>
  <data name="txtCreditTypeStopM" xml:space="preserve">
    <value>停M</value>
  </data>
  <data name="txtDecreaseAmt" xml:space="preserve">
    <value>減額</value>
  </data>
  <data name="txtStaff" xml:space="preserve">
    <value>員工</value>
  </data>
  <data name="txtStoreNegative" xml:space="preserve">
    <value>負數卡</value>
  </data>
  <data name="txtStoreNonNegative" xml:space="preserve">
    <value>非負數卡</value>
  </data>
  <data name="wTranName" xml:space="preserve">
    <value>交易項目</value>
  </data>
  <data name="wIsInternalTran" xml:space="preserve">
    <value>內部交易</value>
  </data>
  <data name="txtShowInternalTran" xml:space="preserve">
    <value>顯示內部交易</value>
  </data>
  <data name="type_CR" xml:space="preserve">
    <value>提卡</value>
  </data>
  <data name="type_CS" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="wInternalRemark" xml:space="preserve">
    <value>內部備註</value>
  </data>
  <data name="txtTransferCentre" xml:space="preserve">
    <value>綜合理財</value>
  </data>
  <data name="txtChipTranI" xml:space="preserve">
    <value>存單管理</value>
  </data>
  <data name="global_txtAllCustomer" xml:space="preserve">
    <value>全部客人</value>
  </data>
  <data name="global_txtSearchType" xml:space="preserve">
    <value>搜尋類型</value>
  </data>
  <data name="txtCustCName" xml:space="preserve">
    <value>存/提款人</value>
  </data>
  <data name="txtDisplay" xml:space="preserve">
    <value>顯示</value>
  </data>
  <data name="txtExpireDate" xml:space="preserve">
    <value>到期日</value>
  </data>
  <data name="txtFromDate" xml:space="preserve">
    <value>結算日期</value>
  </data>
  <data name="txtGroupByCardCode" xml:space="preserve">
    <value>以卡號分類</value>
  </data>
  <data name="txtHaveInterestAcctOnly" xml:space="preserve">
    <value>只顯示收息戶口</value>
  </data>
  <data name="txtIsInternal" xml:space="preserve">
    <value>只顯示內部飛數</value>
  </data>
  <data name="txtOperateRefNo" xml:space="preserve">
    <value>營運編號</value>
  </data>
  <data name="txtRollingMoney" xml:space="preserve">
    <value>轉碼超過(萬)</value>
  </data>
  <data name="txtUseCurDateTimeFilter" xml:space="preserve">
    <value>用於輸入借貸日期作篩選</value>
  </data>
  <data name="txtUserType" xml:space="preserve">
    <value>用戶類型</value>
  </data>
  <data name="txtAbroad" xml:space="preserve">
    <value>海外團</value>
  </data>
  <data name="txtArrRemainRecord" xml:space="preserve">
    <value>欠費餘數記錄</value>
  </data>
  <data name="txtComIOU" xml:space="preserve">
    <value>公司IOU</value>
  </data>
  <data name="txtCRM" xml:space="preserve">
    <value>現碼還M</value>
  </data>
  <data name="txtFDeSlip" xml:space="preserve">
    <value>凍結存款單</value>
  </data>
  <data name="txtFMSCard" xml:space="preserve">
    <value>凍M存卡</value>
  </data>
  <data name="txtGRM" xml:space="preserve">
    <value>贏錢回舊M</value>
  </data>
  <data name="txtHSCard" xml:space="preserve">
    <value>股本存卡</value>
  </data>
  <data name="txtInsSave" xml:space="preserve">
    <value>暫存</value>
  </data>
  <data name="txtMRemainderRecord" xml:space="preserve">
    <value>罰息餘數記錄</value>
  </data>
  <data name="txtMReturnRecord" xml:space="preserve">
    <value>罰息歸還記錄</value>
  </data>
  <data name="txtMRM" xml:space="preserve">
    <value>M還M</value>
  </data>
  <data name="txtMSOrder" xml:space="preserve">
    <value>月息存單</value>
  </data>
  <data name="txtNotAbroad" xml:space="preserve">
    <value>非海外團</value>
  </data>
  <data name="txtOpCard" xml:space="preserve">
    <value>運營卡</value>
  </data>
  <data name="txtPreMOfTM" xml:space="preserve">
    <value>預視此月份罰息</value>
  </data>
  <data name="txtReRecord" xml:space="preserve">
    <value>歸還記錄</value>
  </data>
  <data name="txtShowPenaltyIOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="txtSMRM" xml:space="preserve">
    <value>存M還M</value>
  </data>
  <data name="txtTMthRecord" xml:space="preserve">
    <value>此月份記錄</value>
  </data>
  <data name="txtExpOutstanding" xml:space="preserve">
    <value>尚欠費用</value>
  </data>
  <data name="txtAccURecord" xml:space="preserve">
    <value>累數使用記錄</value>
  </data>
  <data name="txtFReRecord" xml:space="preserve">
    <value>食津餘數記錄</value>
  </data>
  <data name="txtAbgCode" xml:space="preserve">
    <value>海外團號碼</value>
  </data>
  <data name="txtDisplayUnSettle" xml:space="preserve">
    <value>顯示未結算</value>
  </data>
  <data name="txtANumber" xml:space="preserve">
    <value>A數</value>
  </data>
  <data name="txtBNumber" xml:space="preserve">
    <value>B數</value>
  </data>
  <data name="txtChipType" xml:space="preserve">
    <value>數類</value>
  </data>
  <data name="txtGoldenAcc" xml:space="preserve">
    <value>金咭戶</value>
  </data>
  <data name="txtHMemberCard" xml:space="preserve">
    <value>尊貴卡</value>
  </data>
  <data name="txtMemberCard" xml:space="preserve">
    <value>會員卡</value>
  </data>
  <data name="txtMonSettle" xml:space="preserve">
    <value>月結即出</value>
  </data>
  <data name="txtNormalAcc" xml:space="preserve">
    <value>基本戶</value>
  </data>
  <data name="txtNotHoldCommission" xml:space="preserve">
    <value>不顯示HOLD佣</value>
  </data>
  <data name="txtNotVIP" xml:space="preserve">
    <value>非會員</value>
  </data>
  <data name="txtpRtnCur" xml:space="preserve">
    <value>以港幣結算</value>
  </data>
  <data name="txtQuickSettle" xml:space="preserve">
    <value>即出</value>
  </data>
  <data name="typeRAGBOOKINGPRORPT_Report" xml:space="preserve">
    <value>業務進步約見名單</value>
  </data>
  <data name="typeRAGCREOV1KROLUNRPT_Report" xml:space="preserve">
    <value>信貸額1千不達標</value>
  </data>
  <data name="typeRAGECHIBOMTHMARRPT_Report" xml:space="preserve">
    <value>每月存款大於過期Marker</value>
  </data>
  <data name="typeRAGECREDAMOURPT_Report" xml:space="preserve">
    <value>批碼金額及戶口</value>
  </data>
  <data name="typeRCREDANDROLLSTRPT_Report" xml:space="preserve">
    <value>已信貸額玩家戶口及轉碼</value>
  </data>
  <data name="typeRDISPLAYOV1MRPT_Report" xml:space="preserve">
    <value>有額超過1個月無用名單</value>
  </data>
  <data name="typeRFOLZZSACCRPT_Report" xml:space="preserve">
    <value>ZZS/OT/OF/OK分析</value>
  </data>
  <data name="typeRLA30DFIRMARKRACCRPT_Report" xml:space="preserve">
    <value>批M首月轉碼</value>
  </data>
  <data name="typeRNEWAGECREDROLRPT_Report" xml:space="preserve">
    <value>新批玩家戶口及轉碼</value>
  </data>
  <data name="typeRNOMARKERLSTRPT_Report" xml:space="preserve">
    <value>停M名單</value>
  </data>
  <data name="typeRRANKTWINLOSSRPT_Report" xml:space="preserve">
    <value>輸贏排名</value>
  </data>
  <data name="txtInterDate" xml:space="preserve">
    <value>應派息日期</value>
  </data>
  <data name="txtMemberAll" xml:space="preserve">
    <value>VVIP及VIP</value>
  </data>
  <data name="txtOperateDate" xml:space="preserve">
    <value>操作日期</value>
  </data>
  <data name="typeAGENTLOCKRPT_ReportGrp" xml:space="preserve">
    <value>二次授權報表</value>
  </data>
  <data name="typeBONUSGIFTRPT_ReportGrp" xml:space="preserve">
    <value>送禮報表</value>
  </data>
  <data name="typeRAGENTLOCKRPT_Report" xml:space="preserve">
    <value>二次授權報表</value>
  </data>
  <data name="typeRBONUSGIFTRPT_Report" xml:space="preserve">
    <value>送禮報表</value>
  </data>
  <data name="global_txtDest" xml:space="preserve">
    <value>目的地</value>
  </data>
  <data name="global_txtExpParentCode" xml:space="preserve">
    <value>消費類型</value>
  </data>
  <data name="global_txtExpSubCode" xml:space="preserve">
    <value>消費分類</value>
  </data>
  <data name="global_txtExpType" xml:space="preserve">
    <value>消費類型</value>
  </data>
  <data name="global_txtMiscSubType" xml:space="preserve">
    <value>雜項分類</value>
  </data>
  <data name="global_txtMiscType" xml:space="preserve">
    <value>雜項類型</value>
  </data>
  <data name="global_txtResturant" xml:space="preserve">
    <value>餐廳</value>
  </data>
  <data name="global_txtRoomType" xml:space="preserve">
    <value>房間類型</value>
  </data>
  <data name="global_txtSitType" xml:space="preserve">
    <value>座位類型</value>
  </data>
  <data name="global_txtVehicleType" xml:space="preserve">
    <value>工具類型</value>
  </data>
  <data name="wIDType_ID" xml:space="preserve">
    <value>身份證</value>
  </data>
  <data name="wIDType_Passport" xml:space="preserve">
    <value>護照</value>
  </data>
  <data name="wIDType_VISA" xml:space="preserve">
    <value>通行證</value>
  </data>
  <data name="action_UPLOAD_type" xml:space="preserve">
    <value>上傳</value>
  </data>
  <data name="txtToHKD" xml:space="preserve">
    <value>折算港幣</value>
  </data>
  <data name="txtRelateIOU" xml:space="preserve">
    <value>相關借貸</value>
  </data>
  <data name="txtCreditHistory" xml:space="preserve">
    <value>信貸額記錄</value>
  </data>
  <data name="txtUCredit" xml:space="preserve">
    <value>U信貸額</value>
  </data>
  <data name="txtCashLoan" xml:space="preserve">
    <value>個人</value>
  </data>
  <data name="type_LongTerm" xml:space="preserve">
    <value>長期</value>
  </data>
  <data name="type_TEMP" xml:space="preserve">
    <value>臨時</value>
  </data>
  <data name="txtFirstPage" xml:space="preserve">
    <value>首頁</value>
  </data>
  <data name="txtPrevPage" xml:space="preserve">
    <value>上頁</value>
  </data>
  <data name="txtNextPage" xml:space="preserve">
    <value>下頁</value>
  </data>
  <data name="txtLastPage" xml:space="preserve">
    <value>末頁</value>
  </data>
  <data name="txtPageSize" xml:space="preserve">
    <value>顯示記錄數</value>
  </data>
  <data name="txtRecordCount" xml:space="preserve">
    <value>記錄數</value>
  </data>
  <data name="global_txtTransferCard" xml:space="preserve">
    <value>過數卡</value>
  </data>
  <data name="global_btnNewAuthorize" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="global_btnNewUnderAgent" xml:space="preserve">
    <value>新增下線</value>
  </data>
  <data name="global_btnNew" xml:space="preserve">
    <value>新增</value>
  </data>
  <data name="txtAgentBasicDetail" xml:space="preserve">
    <value>戶口記錄</value>
  </data>
  <data name="txtAgentContactDetail" xml:space="preserve">
    <value>聯絡資料</value>
  </data>
  <data name="txtAgentOtherDetail" xml:space="preserve">
    <value>其它資料</value>
  </data>
  <data name="type_Shift1" xml:space="preserve">
    <value>早更</value>
  </data>
  <data name="type_Shift2" xml:space="preserve">
    <value>中更</value>
  </data>
  <data name="type_Shift3" xml:space="preserve">
    <value>夜更</value>
  </data>
  <data name="global_txtFilePath" xml:space="preserve">
    <value>文件位置</value>
  </data>
  <data name="global_btnRoomExt" xml:space="preserve">
    <value>續房</value>
  </data>
  <data name="global_btnPrintAllRoom" xml:space="preserve">
    <value>列印全部房間</value>
  </data>
  <data name="txtAlready" xml:space="preserve">
    <value>已</value>
  </data>
  <data name="txtAuthIndentityAgent" xml:space="preserve">
    <value>戶主</value>
  </data>
  <data name="txtHidden" xml:space="preserve">
    <value>不顯示</value>
  </data>
  <data name="txtIOUTranTypeLst" xml:space="preserve">
    <value>客人未取</value>
  </data>
  <data name="txtOperating" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="txtOperation" xml:space="preserve">
    <value>執行</value>
  </data>
  <data name="txtTranGroupI" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="wAgentCodeInRoll" xml:space="preserve">
    <value>轉碼戶口</value>
  </data>
  <data name="wCashBal" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="txtCommRetM" xml:space="preserve">
    <value>佣金回M</value>
  </data>
  <data name="txtGroupByComM" xml:space="preserve">
    <value>以M現金，海外本地現金出碼及數類 分類</value>
  </data>
  <data name="txtRange" xml:space="preserve">
    <value>範圍</value>
  </data>
  <data name="global_btnDownload" xml:space="preserve">
    <value>下載</value>
  </data>
  <data name="global_btnBrowse" xml:space="preserve">
    <value>瀏覽</value>
  </data>
  <data name="txtUploadFile" xml:space="preserve">
    <value>上傳文件</value>
  </data>
  <data name="wExpirePeriod" xml:space="preserve">
    <value>限期</value>
  </data>
  <data name="global_txtAmountHKD" xml:space="preserve">
    <value>港幣金額</value>
  </data>
  <data name="txtVIP" xml:space="preserve">
    <value>VIP</value>
  </data>
  <data name="txtVVIP" xml:space="preserve">
    <value>VVIP</value>
  </data>
  <data name="txtSearchComboEmpty" xml:space="preserve">
    <value>(全部)</value>
  </data>
  <data name="wCName_Last" xml:space="preserve">
    <value>中文姓氏</value>
  </data>
  <data name="wEName_Last" xml:space="preserve">
    <value>英文姓氏</value>
  </data>
  <data name="txtAgentRoveDtl" xml:space="preserve">
    <value>巨額用戶紀錄</value>
  </data>
  <data name="txtIDIssuedCountry" xml:space="preserve">
    <value>證件簽發地點</value>
  </data>
  <data name="txtOtherInflowDesc" xml:space="preserve">
    <value>請註明 :</value>
  </data>
  <data name="txtTransactionCode" xml:space="preserve">
    <value>交易組別</value>
  </data>
  <data name="txtAgentRoveTranLst" xml:space="preserve">
    <value>巨額報表交易記錄</value>
  </data>
  <data name="txtCustomer" xml:space="preserve">
    <value>客人</value>
  </data>
  <data name="txtGuareantor" xml:space="preserve">
    <value>擔保人</value>
  </data>
  <data name="txtStaffNo" xml:space="preserve">
    <value>員工號碼</value>
  </data>
  <data name="txtVIPNumber" xml:space="preserve">
    <value>貴賓卡號</value>
  </data>
  <data name="wIntroducerCodeIn" xml:space="preserve">
    <value>介紹人</value>
  </data>
  <data name="btnReadCard" xml:space="preserve">
    <value>讀卡</value>
  </data>
  <data name="btnRemarkCount" xml:space="preserve">
    <value>戶口重要備註</value>
  </data>
  <data name="btnRemoteMachineInput" xml:space="preserve">
    <value>遙距輸入</value>
  </data>
  <data name="typeStatus_I" xml:space="preserve">
    <value>不活躍</value>
  </data>
  <data name="txtShareJoinDate" xml:space="preserve">
    <value>入股日期</value>
  </data>
  <data name="txtInfoTelFormat" xml:space="preserve">
    <value>格式: +(國家號碼)(電話號碼), 例子: +85223456789</value>
  </data>
  <data name="wTelSMSOpIntroducer" xml:space="preserve">
    <value>營運來貨號碼</value>
  </data>
  <data name="wTelSMSForeign" xml:space="preserve">
    <value>海外團號碼</value>
  </data>
  <data name="txtAgentPercentage" xml:space="preserve">
    <value>%代理</value>
  </data>
  <data name="txtPleaseClarifyPercertage" xml:space="preserve">
    <value>請註明比例</value>
  </data>
  <data name="txtPlayerPercentage" xml:space="preserve">
    <value>%玩家</value>
  </data>
  <data name="txtHoldStoreCashChip" xml:space="preserve">
    <value>Hold存卡數</value>
  </data>
  <data name="txtSpokenLang" xml:space="preserve">
    <value>對話語言</value>
  </data>
  <data name="txtSeason" xml:space="preserve">
    <value>季度</value>
  </data>
  <data name="txtSeason1" xml:space="preserve">
    <value>1-3</value>
  </data>
  <data name="txtSeason2" xml:space="preserve">
    <value>4-6</value>
  </data>
  <data name="txtSeason3" xml:space="preserve">
    <value>7-9</value>
  </data>
  <data name="txtSeason4" xml:space="preserve">
    <value>10-12</value>
  </data>
  <data name="txtIdentify" xml:space="preserve">
    <value>如"有"，請註明</value>
  </data>
  <data name="txtRelation" xml:space="preserve">
    <value>關係</value>
  </data>
  <data name="txtAuthorize" xml:space="preserve">
    <value>授權</value>
  </data>
  <data name="wAuComm" xml:space="preserve">
    <value>取佣</value>
  </data>
  <data name="wAuExp" xml:space="preserve">
    <value>簽單</value>
  </data>
  <data name="wAuIOU" xml:space="preserve">
    <value>簽貸款</value>
  </data>
  <data name="wAuOther" xml:space="preserve">
    <value>其他</value>
  </data>
  <data name="wAuOtherRemark" xml:space="preserve">
    <value>備註</value>
  </data>
  <data name="wAuRoom" xml:space="preserve">
    <value>取房</value>
  </data>
  <data name="wAuShopping" xml:space="preserve">
    <value>購物</value>
  </data>
  <data name="wAuShoppingHint" xml:space="preserve">
    <value>註: 當選取”購物”代表授權人購物HKD 5,000 內不用通知戶主</value>
  </data>
  <data name="wAuStore" xml:space="preserve">
    <value>取存碼</value>
  </data>
  <data name="wAuStoreBook" xml:space="preserve">
    <value>大簿</value>
  </data>
  <data name="wAuthCName" xml:space="preserve">
    <value>授權主管</value>
  </data>
  <data name="wAuthIdentity" xml:space="preserve">
    <value>授權人身份</value>
  </data>
  <data name="wAuthoize" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="wAuthPerson" xml:space="preserve">
    <value>認證戶口</value>
  </data>
  <data name="wAuthUsrId" xml:space="preserve">
    <value>授權主管編號</value>
  </data>
  <data name="wAuTicket" xml:space="preserve">
    <value>取飛</value>
  </data>
  <data name="global_txtCachOut" xml:space="preserve">
    <value>取走現金</value>
  </data>
  <data name="global_txtCashChipOut" xml:space="preserve">
    <value>袋走現金碼</value>
  </data>
  <data name="global_txtReturnIOU" xml:space="preserve">
    <value>贖回借貸</value>
  </data>
  <data name="global_txtTran" xml:space="preserve">
    <value>存款</value>
  </data>
  <data name="typeChip_StoreC" xml:space="preserve">
    <value>存C</value>
  </data>
  <data name="typeChip_Win" xml:space="preserve">
    <value>贏錢</value>
  </data>
  <data name="typeChip_NNChip" xml:space="preserve">
    <value>泥碼</value>
  </data>
  <data name="typeChipService_WITHDRAWAL" xml:space="preserve">
    <value>提款</value>
  </data>
  <data name="typeChipService_DEPOSIT" xml:space="preserve">
    <value>存款</value>
  </data>
  <data name="typeChipService_TRANSFER" xml:space="preserve">
    <value>轉帳</value>
  </data>
  <data name="typeChipTran_CHIPB" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="typeChipTran_CHIPI" xml:space="preserve">
    <value>存單</value>
  </data>
  <data name="typeChipTran_MTHINTEREST" xml:space="preserve">
    <value>月息單</value>
  </data>
  <data name="typeChipTran_CAPITAL" xml:space="preserve">
    <value>股本卡</value>
  </data>
  <data name="typeChipTran_FREEZE" xml:space="preserve">
    <value>凍M卡</value>
  </data>
  <data name="typeChipTran_HOLD" xml:space="preserve">
    <value>凍結存款單</value>
  </data>
  <data name="typeChipAction_CASH" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="typeChipAction_NNCHIP" xml:space="preserve">
    <value>籌碼</value>
  </data>
  <data name="typeChipAction_REPAYMENT" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="typeChipAction_CHIPB" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="typeChipAction_MTHINTEREST" xml:space="preserve">
    <value>存月息</value>
  </data>
  <data name="typeChipAction_CAPITAL" xml:space="preserve">
    <value>存股本</value>
  </data>
  <data name="typeChipAction_FREEZE" xml:space="preserve">
    <value>凍M</value>
  </data>
  <data name="typeAGENTROVELST_Core" xml:space="preserve">
    <value>巨額用戶管理</value>
  </data>
  <data name="typeAGENTROVETRANLST_Core" xml:space="preserve">
    <value>巨額報表交易記錄</value>
  </data>
  <data name="typeROVECUSTOMERLST_Core" xml:space="preserve">
    <value>客人管理(巨額)</value>
  </data>
  <data name="txtBChipStoreType" xml:space="preserve">
    <value>存款類型</value>
  </data>
  <data name="txtInfoSimilarAgentExists" xml:space="preserve">
    <value>相似戶口</value>
  </data>
  <data name="global_btnImport" xml:space="preserve">
    <value>匯入</value>
  </data>
  <data name="txtErrImportData" xml:space="preserve">
    <value>匯入資料錯誤:{0}</value>
  </data>
  <data name="txtSelect" xml:space="preserve">
    <value>選取</value>
  </data>
  <data name="wStaffNo" xml:space="preserve">
    <value>相關員工編號</value>
  </data>
  <data name="wTradeChip" xml:space="preserve">
    <value>交易金額(萬)</value>
  </data>
  <data name="wTradeType" xml:space="preserve">
    <value>交易類別</value>
  </data>
  <data name="global_btnChangeIVRPwd" xml:space="preserve">
    <value>修改戶口認証密碼</value>
  </data>
  <data name="global_btnResetIVRPwd" xml:space="preserve">
    <value>重設戶口認証密碼</value>
  </data>
  <data name="txtAgentRoveLst" xml:space="preserve">
    <value>巨額用戶列表</value>
  </data>
  <data name="global_txtAskConfirm" xml:space="preserve">
    <value>確定</value>
  </data>
  <data name="global_txtAskConfirmCancelIOUContractNo" xml:space="preserve">
    <value>確定取消借貸合同編號?</value>
  </data>
  <data name="global_txtAskConfirmNewIOUContractNo" xml:space="preserve">
    <value>確定新增借貸合同編號?</value>
  </data>
  <data name="global_txtCustomerGroup_Normal" xml:space="preserve">
    <value>一般</value>
  </data>
  <data name="global_txtCustomerGroup_OP" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="global_txtCustomerGroup_ROVE" xml:space="preserve">
    <value>巨額</value>
  </data>
  <data name="global_txtCustomerGroup_ST" xml:space="preserve">
    <value>出佣人</value>
  </data>
  <data name="txtServiceType" xml:space="preserve">
    <value>服務類型</value>
  </data>
  <data name="txtDeviceDtl" xml:space="preserve">
    <value>裝置記錄</value>
  </data>
  <data name="txtDeviceLst" xml:space="preserve">
    <value>裝置管理</value>
  </data>
  <data name="typeDEVICELST_Core" xml:space="preserve">
    <value>裝置管理</value>
  </data>
  <data name="global_msgErrRecordNotFound" xml:space="preserve">
    <value>找不到相關記錄</value>
  </data>
  <data name="global_btnLogin" xml:space="preserve">
    <value>登入</value>
  </data>
  <data name="global_msgPlaceCardForCardReader" xml:space="preserve">
    <value>請將卡放於讀卡器上</value>
  </data>
  <data name="txtBalanceSheet" xml:space="preserve">
    <value>資產負債表</value>
  </data>
  <data name="global_btnReturn" xml:space="preserve">
    <value>歸還</value>
  </data>
  <data name="eCounterBal" xml:space="preserve">
    <value>櫃數表</value>
  </data>
  <data name="txtStoreNegativeAmt" xml:space="preserve">
    <value>可負數卡,限額(只可輸入負數)</value>
  </data>
  <data name="wNoIVR" xml:space="preserve">
    <value>不需要電話認証</value>
  </data>
  <data name="UsageType_RemoteRolling" xml:space="preserve">
    <value>遙距轉碼</value>
  </data>
  <data name="UsageType_TranApps" xml:space="preserve">
    <value>營運Apps</value>
  </data>
  <data name="wDeviceID" xml:space="preserve">
    <value>裝置編號</value>
  </data>
  <data name="wDeviceType" xml:space="preserve">
    <value>裝置型號</value>
  </data>
  <data name="wUsageType" xml:space="preserve">
    <value>種類</value>
  </data>
  <data name="txtAgentManager" xml:space="preserve">
    <value>戶口經理版</value>
  </data>
  <data name="txtInfoIVRAuthSuccess" xml:space="preserve">
    <value>戶口密碼証證成功</value>
  </data>
  <data name="wGunterPassword" xml:space="preserve">
    <value>密碼</value>
  </data>
  <data name="btnTempByPassAgentAuth" xml:space="preserve">
    <value>跳過戶口認証檢查</value>
  </data>
  <data name="txtLivePasswordInput" xml:space="preserve">
    <value>現場輸入戶口認証</value>
  </data>
  <data name="wIVRPwd" xml:space="preserve">
    <value>戶口密碼</value>
  </data>
  <data name="btnCancelLivePassword" xml:space="preserve">
    <value>轉用電話系統認証</value>
  </data>
  <data name="btnCheckIVRAuth" xml:space="preserve">
    <value>檢查戶主密碼</value>
  </data>
  <data name="txtAuthBy" xml:space="preserve">
    <value>認証</value>
  </data>
  <data name="txtCheckIVRAuth" xml:space="preserve">
    <value>檢查戶口</value>
  </data>
  <data name="txtInfoWaitingIVRAuth" xml:space="preserve">
    <value>等候戶主電話認証中 ....</value>
  </data>
  <data name="txtPreferLang" xml:space="preserve">
    <value>語言</value>
  </data>
  <data name="wExt" xml:space="preserve">
    <value>電話線號</value>
  </data>
  <data name="global_AuthIdentityASSISTANT" xml:space="preserve">
    <value>業務發展部助理</value>
  </data>
  <data name="global_AuthIdentityBOSS" xml:space="preserve">
    <value>幕後老闆</value>
  </data>
  <data name="global_AuthIdentityDIRECTOR" xml:space="preserve">
    <value>總監</value>
  </data>
  <data name="global_AuthIdentityFAMILY" xml:space="preserve">
    <value>家人</value>
  </data>
  <data name="global_AuthIdentityMARKET" xml:space="preserve">
    <value>巿場部</value>
  </data>
  <data name="global_AuthIdentityOWNER" xml:space="preserve">
    <value>戶主</value>
  </data>
  <data name="global_AuthIdentityPARTNER" xml:space="preserve">
    <value>拍檔</value>
  </data>
  <data name="global_AuthIdentitySTAFF" xml:space="preserve">
    <value>伙記</value>
  </data>
  <data name="global_AuthIdentityWARRANTOR" xml:space="preserve">
    <value>借貸担保人</value>
  </data>
  <data name="txtBefore" xml:space="preserve">
    <value>之前</value>
  </data>
  <data name="txtCapitalTranTypeH" xml:space="preserve">
    <value>凍結存款單報表</value>
  </data>
  <data name="txtCapitalTranTypeO" xml:space="preserve">
    <value>營運卡報表</value>
  </data>
  <data name="txtCapitalTranTypeY" xml:space="preserve">
    <value>食貨存卡</value>
  </data>
  <data name="txtChipTotal" xml:space="preserve">
    <value>存碼總和</value>
  </data>
  <data name="txtCreditTranStatusC" xml:space="preserve">
    <value>無效</value>
  </data>
  <data name="txtEliteNOBILITY" xml:space="preserve">
    <value>貴族</value>
  </data>
  <data name="txtEliteROYALTY" xml:space="preserve">
    <value>皇族</value>
  </data>
  <data name="txtLatest" xml:space="preserve">
    <value>最新</value>
  </data>
  <data name="txtMonthFilterOptLstPre" xml:space="preserve">
    <value>上月</value>
  </data>
  <data name="txtMonthFilterOptLstThis" xml:space="preserve">
    <value>本月</value>
  </data>
  <data name="txtMsgNoRecord" xml:space="preserve">
    <value>沒有記錄</value>
  </data>
  <data name="txtReturnType_TS" xml:space="preserve">
    <value>取暫存</value>
  </data>
  <data name="txtSexOptF" xml:space="preserve">
    <value>女</value>
  </data>
  <data name="txtSexOptM" xml:space="preserve">
    <value>男</value>
  </data>
  <data name="txtStatusPlsSelect" xml:space="preserve">
    <value>請選擇</value>
  </data>
  <data name="txtTranGroupCWG" xml:space="preserve">
    <value>客人已取</value>
  </data>
  <data name="txtTranGroupReCI" xml:space="preserve">
    <value>歸還公司IOU</value>
  </data>
  <data name="txtTranGroupReI" xml:space="preserve">
    <value>歸還IOU</value>
  </data>
  <data name="txtTranGroupReS" xml:space="preserve">
    <value>歸還股本</value>
  </data>
  <data name="txtWMRM" xml:space="preserve">
    <value>嬴錢回舊M</value>
  </data>
  <data name="txLineTtlMarker" xml:space="preserve">
    <value>全線總簽賬</value>
  </data>
  <data name="txtAProfitAndLossStandard" xml:space="preserve">
    <value>損益表</value>
  </data>
  <data name="txtBFAmount" xml:space="preserve">
    <value>前額</value>
  </data>
  <data name="txtBonusPointStatusA" xml:space="preserve">
    <value>已批</value>
  </data>
  <data name="txtBonusPointStatusN" xml:space="preserve">
    <value>待批</value>
  </data>
  <data name="txtBonusPointStatusR" xml:space="preserve">
    <value>駁回</value>
  </data>
  <data name="txtBPlayCustomer" xml:space="preserve">
    <value>客戶</value>
  </data>
  <data name="txtCapital" xml:space="preserve">
    <value>本金</value>
  </data>
  <data name="txtCapitalTranF" xml:space="preserve">
    <value>凍M</value>
  </data>
  <data name="txtCapLimitN" xml:space="preserve">
    <value>不接受超額</value>
  </data>
  <data name="txtCapLimitY" xml:space="preserve">
    <value>可接受超額</value>
  </data>
  <data name="txtCashToDrinkRate" xml:space="preserve">
    <value>{0}折</value>
  </data>
  <data name="txtConfirmSheet" xml:space="preserve">
    <value>確認表</value>
  </data>
  <data name="txtCurrentAssets" xml:space="preserve">
    <value>流動資產</value>
  </data>
  <data name="txtCurrentLib" xml:space="preserve">
    <value>流動負債</value>
  </data>
  <data name="txtExchangeSimple" xml:space="preserve">
    <value>兌</value>
  </data>
  <data name="txtExpense" xml:space="preserve">
    <value>支出</value>
  </data>
  <data name="txtExpenseFxRate" xml:space="preserve">
    <value>消費匯率</value>
  </data>
  <data name="txtExpenseIs" xml:space="preserve">
    <value>實收消費為</value>
  </data>
  <data name="txtExpStatement" xml:space="preserve">
    <value>**通用積分有效期為兩個月, 餘下積分可作現金回收; 不通用積分可無限期累積, 直至永利酒店另行通知, 當中所涉及的損失, 本公司一概不作承擔**</value>
  </data>
  <data name="txtFixedAssets" xml:space="preserve">
    <value>固定資產</value>
  </data>
  <data name="txtFollowRemark" xml:space="preserve">
    <value>跟進及備註</value>
  </data>
  <data name="txtForeignDetail" xml:space="preserve">
    <value>海外數明細</value>
  </data>
  <data name="txtFr" xml:space="preserve">
    <value>由</value>
  </data>
  <data name="txtGrpExpCommitment" xml:space="preserve">
    <value>承擔集團之費用</value>
  </data>
  <data name="txtInCome" xml:space="preserve">
    <value>收入</value>
  </data>
  <data name="txtInterest" xml:space="preserve">
    <value>利息</value>
  </data>
  <data name="txtIOUTotalAmt" xml:space="preserve">
    <value>借貸總額</value>
  </data>
  <data name="txtMsgCompShareDebt" xml:space="preserve">
    <value>集團旗下各館共同分擔什此數</value>
  </data>
  <data name="txtNetAsset" xml:space="preserve">
    <value>資產淨值</value>
  </data>
  <data name="txtNetProfit" xml:space="preserve">
    <value>純利</value>
  </data>
  <data name="txtOnSite" xml:space="preserve">
    <value>在場</value>
  </data>
  <data name="txtOrgExpenseIs" xml:space="preserve">
    <value>原消費為</value>
  </data>
  <data name="txtOutSite" xml:space="preserve">
    <value>離場</value>
  </data>
  <data name="txtOutstandingTotalAmt" xml:space="preserve">
    <value>未歸還總額</value>
  </data>
  <data name="txtOwn" xml:space="preserve">
    <value>本人</value>
  </data>
  <data name="txtPointUse_InHKD_Real" xml:space="preserve">
    <value>澳門積分使用</value>
  </data>
  <data name="txtPreliminary" xml:space="preserve">
    <value>最初</value>
  </data>
  <data name="txtPrintDate" xml:space="preserve">
    <value>列印日期</value>
  </data>
  <data name="txtPrintLocation" xml:space="preserve">
    <value>列印場所</value>
  </data>
  <data name="txtProfit" xml:space="preserve">
    <value>毛利</value>
  </data>
  <data name="txtProfitAndLossSheet" xml:space="preserve">
    <value>什支表</value>
  </data>
  <data name="txtRBPlayCompWLReport" xml:space="preserve">
    <value>B數公司上/下數報表.</value>
  </data>
  <data name="txtRBPlayCustWLReport" xml:space="preserve">
    <value>B數客人上/下數報表.</value>
  </data>
  <data name="txtRForeignCompWLReport" xml:space="preserve">
    <value>海外公司上/下數報表</value>
  </data>
  <data name="txtRForeignCustWLReport" xml:space="preserve">
    <value>海外客人上/下數報表</value>
  </data>
  <data name="txtRSpecialMarkerRpt_C" xml:space="preserve">
    <value>個人借貸報表</value>
  </data>
  <data name="txtRSpecialMarkerTran_C" xml:space="preserve">
    <value>個人借貸提存表</value>
  </data>
  <data name="txtRSpecialMarkerTran_F" xml:space="preserve">
    <value>海外借貸提存表</value>
  </data>
  <data name="txtRSpecialMarkerTran_Y" xml:space="preserve">
    <value>營運借貸提存表</value>
  </data>
  <data name="txtSetting" xml:space="preserve">
    <value>設定中</value>
  </data>
  <data name="txtSettleStatusSettled" xml:space="preserve">
    <value>已結算</value>
  </data>
  <data name="txtShareCapital" xml:space="preserve">
    <value>股東資金</value>
  </data>
  <data name="txtSite" xml:space="preserve">
    <value>場地</value>
  </data>
  <data name="txtSubLevelBal" xml:space="preserve">
    <value>下線累計數</value>
  </data>
  <data name="txtSum" xml:space="preserve">
    <value>總和</value>
  </data>
  <data name="txtTotal" xml:space="preserve">
    <value>總計</value>
  </data>
  <data name="txtTotalExpense" xml:space="preserve">
    <value>總支出</value>
  </data>
  <data name="txtAccName" xml:space="preserve">
    <value>戶名</value>
  </data>
  <data name="txtAccTypeDn" xml:space="preserve">
    <value>會員降級</value>
  </data>
  <data name="txtAccTypeUp" xml:space="preserve">
    <value>會員升級</value>
  </data>
  <data name="txtAccTypeUpDn_D" xml:space="preserve">
    <value>降</value>
  </data>
  <data name="txtAccTypeUpDn_U" xml:space="preserve">
    <value>升</value>
  </data>
  <data name="txtAgentGetReg" xml:space="preserve">
    <value>每日戶口取房登記表</value>
  </data>
  <data name="txtAgentName" xml:space="preserve">
    <value>代理名稱</value>
  </data>
  <data name="txtAgentNotFound" xml:space="preserve">
    <value>沒有戶口</value>
  </data>
  <data name="txtAgentTotal" xml:space="preserve">
    <value>代理總計</value>
  </data>
  <data name="txtAltogether" xml:space="preserve">
    <value>共</value>
  </data>
  <data name="txtBalAmount" xml:space="preserve">
    <value>結存金額</value>
  </data>
  <data name="txtBFControl_CannotContact" xml:space="preserve">
    <value>未能聯絡</value>
  </data>
  <data name="txtBFControl_ContactAgain" xml:space="preserve">
    <value>要求再次聯絡</value>
  </data>
  <data name="txtBFControl_NoMoreContact" xml:space="preserve">
    <value>不用再通知</value>
  </data>
  <data name="txtBFControl_Purchased" xml:space="preserve">
    <value>已選購貨品</value>
  </data>
  <data name="txtBFNotPaid" xml:space="preserve">
    <value>前欠未收費用</value>
  </data>
  <data name="txtBFPenalty" xml:space="preserve">
    <value>前欠罰息</value>
  </data>
  <data name="txtBookAndGetTime" xml:space="preserve">
    <value>定時間/取時間</value>
  </data>
  <data name="txtBorrower" xml:space="preserve">
    <value>借貸人</value>
  </data>
  <data name="txtCardExp" xml:space="preserve">
    <value>卡消費</value>
  </data>
  <data name="txtCommDiff" xml:space="preserve">
    <value>佣金差額問題</value>
  </data>
  <data name="txtCompanySum" xml:space="preserve">
    <value>公司總和</value>
  </data>
  <data name="txtCompName" xml:space="preserve">
    <value>公司名稱</value>
  </data>
  <data name="txtCompTotalAmt" xml:space="preserve">
    <value>公司總額</value>
  </data>
  <data name="txtCompUnderAgentProfit" xml:space="preserve">
    <value>集團下線收益</value>
  </data>
  <data name="txtCustomerSign" xml:space="preserve">
    <value>客戶簽收</value>
  </data>
  <data name="txtCutoffTotal" xml:space="preserve">
    <value>合計實出</value>
  </data>
  <data name="txtDateTimePeriodOption" xml:space="preserve">
    <value>日期範圍及時間</value>
  </data>
  <data name="txtDeductPenaltyThisMth" xml:space="preserve">
    <value>現本月已扣罰息</value>
  </data>
  <data name="txtDiffRateComm" xml:space="preserve">
    <value>與預設不同差額問題</value>
  </data>
  <data name="txtDisplayTryRun" xml:space="preserve">
    <value>顯示預視資料</value>
  </data>
  <data name="txtDown" xml:space="preserve">
    <value>下</value>
  </data>
  <data name="txtDrink" xml:space="preserve">
    <value>津貼</value>
  </data>
  <data name="txtDrinkBal" xml:space="preserve">
    <value>津貼餘額</value>
  </data>
  <data name="txtDrinkTotal" xml:space="preserve">
    <value>總津貼</value>
  </data>
  <data name="txtEDrinkBFControlLst" xml:space="preserve">
    <value>食津累數跟進</value>
  </data>
  <data name="txtExceedExp" xml:space="preserve">
    <value>超額消費</value>
  </data>
  <data name="txtFDNonShare" xml:space="preserve">
    <value>食津餘額(不共用)</value>
  </data>
  <data name="txtFDNonShareThisMonth" xml:space="preserve">
    <value>當月津貼餘額(不共用)</value>
  </data>
  <data name="txtFDShare" xml:space="preserve">
    <value>食津餘額(共用)</value>
  </data>
  <data name="txtFDShareThisMonth" xml:space="preserve">
    <value>當月津貼餘額(共用)</value>
  </data>
  <data name="txtForPreview" xml:space="preserve">
    <value>預視用</value>
  </data>
  <data name="txtHundredm" xml:space="preserve">
    <value>億</value>
  </data>
  <data name="txtIOUDate2" xml:space="preserve">
    <value>簽帳日期</value>
  </data>
  <data name="txtKnownNotPaidThisMth" xml:space="preserve">
    <value>現本月已知未收費用</value>
  </data>
  <data name="txtLastRollingTime" xml:space="preserve">
    <value>最後轉碼時間</value>
  </data>
  <data name="txtLeftAmount" xml:space="preserve">
    <value>剩餘金額</value>
  </data>
  <data name="txtMainCard" xml:space="preserve">
    <value>主卡</value>
  </data>
  <data name="txtMarkerAmount" xml:space="preserve">
    <value>借貸額</value>
  </data>
  <data name="txtMsgNeedPreviewSMSMessage" xml:space="preserve">
    <value>需要預覽短訊內容嗎？選擇”No”會立即發送！</value>
  </data>
  <data name="txtMsgCannotFindDebitCard" xml:space="preserve">
    <value>找不到存卡</value>
  </data>
  <data name="txtMsgErrFailedLoadingData" xml:space="preserve">
    <value>未能載入資料</value>
  </data>
  <data name="txtMsgInfoPlsInput" xml:space="preserve">
    <value>請輸入</value>
  </data>
  <data name="txtMthRollingBal" xml:space="preserve">
    <value>轉碼月結</value>
  </data>
  <data name="txtOneDayTotal" xml:space="preserve">
    <value>當日總計</value>
  </data>
  <data name="txtRmNoAndRefNo" xml:space="preserve">
    <value>房號及單號</value>
  </data>
  <data name="txtRollingCIOU" xml:space="preserve">
    <value>公司U轉碼</value>
  </data>
  <data name="txtRollingDaily" xml:space="preserve">
    <value>本日轉碼數</value>
  </data>
  <data name="txtRollingIOU" xml:space="preserve">
    <value>IOU轉碼</value>
  </data>
  <data name="txtRollingSO" xml:space="preserve">
    <value>股本轉碼</value>
  </data>
  <data name="txtRollingTotal" xml:space="preserve">
    <value>轉碼總額</value>
  </data>
  <data name="txtRollingWithCash" xml:space="preserve">
    <value>現金轉碼</value>
  </data>
  <data name="txtRollTypeCodeCIOU" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="txtRptAccTypeLst" xml:space="preserve">
    <value>會員每月升跌表</value>
  </data>
  <data name="txtRptAgeExpWithoutRoLst" xml:space="preserve">
    <value>消費(無轉碼)報表</value>
  </data>
  <data name="typeCAPITALTRANTMP_Report" xml:space="preserve">
    <value>月息單報表</value>
  </data>
  <data name="typeCAPITALTRANH_Report" xml:space="preserve">
    <value>凍結存款單報表</value>
  </data>
  <data name="txtRptCardExpenseTran" xml:space="preserve">
    <value>卡消費記錄報表</value>
  </data>
  <data name="typeCHIPTRANTMP_Report" xml:space="preserve">
    <value>存單報表</value>
  </data>
  <data name="typeCOUNTERSETTLE_Report" xml:space="preserve">
    <value>三更結算表</value>
  </data>
  <data name="txtRptDailyAgentWinLoss" xml:space="preserve">
    <value>每日場面報表</value>
  </data>
  <data name="txtRptDepositCondTemp" xml:space="preserve">
    <value>存碼狀態查詢</value>
  </data>
  <data name="txtRptExpenseTran" xml:space="preserve">
    <value>消費記錄報表</value>
  </data>
  <data name="txtRptIOU1Temp" xml:space="preserve">
    <value>借貸細數表</value>
  </data>
  <data name="txtRptIOU2Temp" xml:space="preserve">
    <value>借貸總數表</value>
  </data>
  <data name="txtRptIOUPenaltyPreview" xml:space="preserve">
    <value>罰息現況報表(本月預視)</value>
  </data>
  <data name="txtRptIOUWarningList" xml:space="preserve">
    <value>借貸提示表</value>
  </data>
  <data name="txtRptOperateExternalReportWeek" xml:space="preserve">
    <value>每週私營報表</value>
  </data>
  <data name="txtRptRollChkSum" xml:space="preserve">
    <value>轉碼數總計報表</value>
  </data>
  <data name="txtRptRollingPenaltyDayLst" xml:space="preserve">
    <value>轉碼日數表</value>
  </data>
  <data name="txtRptRollingPenaltyMthLst" xml:space="preserve">
    <value>轉碼月數表</value>
  </data>
  <data name="txtRptRollingPenaltyYrLst" xml:space="preserve">
    <value>轉碼年數表</value>
  </data>
  <data name="txtRptSettleItemSet" xml:space="preserve">
    <value>佣金設定表</value>
  </data>
  <data name="txtExpCreditLst" xml:space="preserve">
    <value>消費批額管理</value>
  </data>
  <data name="txtUpLvlExpCreditAmt" xml:space="preserve">
    <value>上線消費批額</value>
  </data>
  <data name="txtRptSpecialMarkerLst_C" xml:space="preserve">
    <value>個人借貸現況列表</value>
  </data>
  <data name="txtRptSpecialMarkerLst_F" xml:space="preserve">
    <value>海外借貸現況列表</value>
  </data>
  <data name="txtRptSpecialMarkerLst_Y" xml:space="preserve">
    <value>營運借貸現況列表</value>
  </data>
  <data name="txtRptVouDtlLst" xml:space="preserve">
    <value>票單查詢報表</value>
  </data>
  <data name="txtRSuggestTranStatistic" xml:space="preserve">
    <value>客人特徵及部門備註統計報表</value>
  </data>
  <data name="txtSalaryTitleEnd" xml:space="preserve">
    <value>月份碼佣</value>
  </data>
  <data name="txtSPIOURefNo" xml:space="preserve">
    <value>營運單號</value>
  </data>
  <data name="txtStaffName" xml:space="preserve">
    <value>員工名稱</value>
  </data>
  <data name="txtStoreAmt" xml:space="preserve">
    <value>存碼額</value>
  </data>
  <data name="txtSubTotal" xml:space="preserve">
    <value>小計</value>
  </data>
  <data name="txtSuggestedReward" xml:space="preserve">
    <value>可送</value>
  </data>
  <data name="txtTotalNum" xml:space="preserve">
    <value>總數</value>
  </data>
  <data name="txtTotalNumHKD" xml:space="preserve">
    <value>總數折萛為港幣</value>
  </data>
  <data name="txtTotalRolling" xml:space="preserve">
    <value>總轉碼</value>
  </data>
  <data name="txtTotalRollingLoss" xml:space="preserve">
    <value>總下</value>
  </data>
  <data name="txtTotalRollingWin" xml:space="preserve">
    <value>總上</value>
  </data>
  <data name="txtUp" xml:space="preserve">
    <value>上</value>
  </data>
  <data name="txtWinLossReward_AirTicket" xml:space="preserve">
    <value>來回機票 {0} 張</value>
  </data>
  <data name="txtWinLossReward_Coupon" xml:space="preserve">
    <value>食飛 ${0}</value>
  </data>
  <data name="txtWinLossReward_RoomReservation" xml:space="preserve">
    <value>酒店房間 {0} 晚</value>
  </data>
  <data name="txtWinLossTable" xml:space="preserve">
    <value>輸嬴數表</value>
  </data>
  <data name="wDay" xml:space="preserve">
    <value>日</value>
  </data>
  <data name="btnNewThisRollTran" xml:space="preserve">
    <value>新增此場</value>
  </data>
  <data name="global_txtRollTypeCodeCaptital" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="global_txtRollTypeCodeCash" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="global_txtRollTypeCodeCashChip" xml:space="preserve">
    <value>M現金</value>
  </data>
  <data name="global_txtRollTypeCodeCIOU" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="global_txtRollTypeCodeIOU" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="global_txtRollTypeCodeMIO" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="txtInfoRollTranHasAdjust" xml:space="preserve">
    <value>本轉碼已完成月調整，故不能作任何轉碼管理操作。如要繼續，請先前往「轉碼月轉換」還原此轉碼之月調整。</value>
  </data>
  <data name="txtRollTranMgmLst" xml:space="preserve">
    <value>轉碼管理</value>
  </data>
  <data name="wCageDailyBal" xml:space="preserve">
    <value>本廳日轉碼</value>
  </data>
  <data name="wCageMthBal" xml:space="preserve">
    <value>本廳月轉碼</value>
  </data>
  <data name="wCapitalAmt" xml:space="preserve">
    <value>股本(萬)</value>
  </data>
  <data name="wCashAmt" xml:space="preserve">
    <value>現金(萬)</value>
  </data>
  <data name="wChipCode" xml:space="preserve">
    <value>籌碼代號</value>
  </data>
  <data name="wCIOUAmt" xml:space="preserve">
    <value>公司U(萬)</value>
  </data>
  <data name="wCustWinLoss" xml:space="preserve">
    <value>輸贏數(萬)</value>
  </data>
  <data name="wInDateTime" xml:space="preserve">
    <value>入場時間</value>
  </data>
  <data name="wIOUAmt" xml:space="preserve">
    <value>IOU(萬)</value>
  </data>
  <data name="wRatio" xml:space="preserve">
    <value>比例(%)</value>
  </data>
  <data name="wRollDateTime" xml:space="preserve">
    <value>轉碼時間</value>
  </data>
  <data name="wRolling_10K" xml:space="preserve">
    <value>轉碼數(萬)</value>
  </data>
  <data name="wRollInput" xml:space="preserve">
    <value>輸入數(萬)</value>
  </data>
  <data name="wRollRatio" xml:space="preserve">
    <value>按比例數(萬)</value>
  </data>
  <data name="wRollShowType" xml:space="preserve">
    <value>數類</value>
  </data>
  <data name="txtTransferCard" xml:space="preserve">
    <value>過數卡</value>
  </data>
  <data name="txtCounterBal" xml:space="preserve">
    <value>櫃數表</value>
  </data>
  <data name="global_btnAddNew" xml:space="preserve">
    <value>新增</value>
  </data>
  <data name="global_btnPrintCounterAllSettle" xml:space="preserve">
    <value>列印三更結算表</value>
  </data>
  <data name="global_btnPrintRollDtl" xml:space="preserve">
    <value>列印轉碼細數表</value>
  </data>
  <data name="wCounterBalAudit" xml:space="preserve">
    <value>帳房日結表</value>
  </data>
  <data name="wNNChipForeignAmt" xml:space="preserve">
    <value>外館碼(萬)</value>
  </data>
  <data name="wPromissoryNoteAmt" xml:space="preserve">
    <value>本票(萬)</value>
  </data>
  <data name="wTotalCardDeposite" xml:space="preserve">
    <value>總大簿</value>
  </data>
  <data name="wtotalCashDeposite" xml:space="preserve">
    <value>總存款</value>
  </data>
  <data name="wTotalIOU" xml:space="preserve">
    <value>總貸款</value>
  </data>
  <data name="txtCounterBalBPlayRemark1" xml:space="preserve">
    <value>轉碼比對= (上更餘數 + 本更買泥碼 - 本更轉碼) - (本更餘泥碼)</value>
  </data>
  <data name="txtCounterBalBPlayRemark1a" xml:space="preserve">
    <value>本月轉碼比對=(上月餘泥碼 + 本月買泥碼 - 本月轉碼數) - (本更餘泥碼)</value>
  </data>
  <data name="txtCounterBalBPlayRemark2" xml:space="preserve">
    <value>銀頭比對= (本更餘泥碼 + 現金籌碼 + 現金) - (櫃面銀頭)</value>
  </data>
  <data name="txtCounterBalBPlayRemark3" xml:space="preserve">
    <value>銀頭結算= (櫃面銀頭)</value>
  </data>
  <data name="txtCounterBalBPlayRemark4" xml:space="preserve">
    <value>可動用銀頭= (櫃面銀頭)</value>
  </data>
  <data name="txtBuyChipCurrMthRpt" xml:space="preserve">
    <value>本月買碼表</value>
  </data>
  <data name="txtCounterBalRemark1" xml:space="preserve">
    <value>轉碼比對= (上更餘數 + 本更買泥碼 - 本更轉碼) - (本更餘泥碼)</value>
  </data>
  <data name="txtCounterBalRemark1a" xml:space="preserve">
    <value>本月轉碼比對=(上月餘泥碼 + 本月買泥碼 - 本月轉碼數) - (本更餘泥碼)</value>
  </data>
  <data name="txtCounterBalRemark2" xml:space="preserve">
    <value>銀頭比對= (本更餘泥碼 + 現金籌碼 + iou借貨 + 個人借貸 + 現金) - (櫃面銀頭 + 對外借用銀頭 + 借入客人存碼)</value>
  </data>
  <data name="txtCounterBalRemark3" xml:space="preserve">
    <value>銀頭結算= (櫃面銀頭 - 對外借入銀頭 - 借入客人存碼)</value>
  </data>
  <data name="txtCounterBalRemark4" xml:space="preserve">
    <value>可動用銀頭(包括借入)= (櫃面銀頭 + 對外借入銀頭 + 借入客人存碼)</value>
  </data>
  <data name="txtSignature" xml:space="preserve">
    <value>簽名</value>
  </data>
  <data name="wBalToBeSettledAmt" xml:space="preserve">
    <value>掛數總數(萬)</value>
  </data>
  <data name="wCashChipAmt" xml:space="preserve">
    <value>現金碼(萬)</value>
  </data>
  <data name="wCountCompCapitalAmt" xml:space="preserve">
    <value>實際銀頭(萬)</value>
  </data>
  <data name="wNNChipAmt" xml:space="preserve">
    <value>泥碼(萬)</value>
  </data>
  <data name="wShiftCapitalInAmt" xml:space="preserve">
    <value>股本存卡總數(萬)</value>
  </data>
  <data name="wShiftCapitalMInAmt" xml:space="preserve">
    <value>月息存單總數(萬)</value>
  </data>
  <data name="wShiftCapitalMOutAmt" xml:space="preserve">
    <value>月息取單總數(萬)</value>
  </data>
  <data name="wShiftCapitalOutAmt" xml:space="preserve">
    <value>股本取卡總數(萬)</value>
  </data>
  <data name="wShiftChipBInAmt" xml:space="preserve">
    <value>存卡總數(萬)</value>
  </data>
  <data name="wShiftChipBOutAmt" xml:space="preserve">
    <value>取卡總數(萬)</value>
  </data>
  <data name="wShiftChipIInAmt" xml:space="preserve">
    <value>存單總數(萬)</value>
  </data>
  <data name="wShiftChipIOutAmt" xml:space="preserve">
    <value>取單總數(萬)</value>
  </data>
  <data name="wShiftFreezeInAmt" xml:space="preserve">
    <value>凍M存卡總數(萬)</value>
  </data>
  <data name="wShiftFreezeOutAmt" xml:space="preserve">
    <value>凍M取卡總數(萬)</value>
  </data>
  <data name="wShiftIOUInAmt" xml:space="preserve">
    <value>出M總數(萬)</value>
  </data>
  <data name="wShiftIOUOutAmt" xml:space="preserve">
    <value>回M總數(萬)</value>
  </data>
  <data name="wShiftRollingAmt" xml:space="preserve">
    <value>轉碼總數(萬)</value>
  </data>
  <data name="wShiftYellowInAmt" xml:space="preserve">
    <value>食貨存卡總數(萬)</value>
  </data>
  <data name="wShiftYellowOutAmt" xml:space="preserve">
    <value>食貨取卡總數(萬)</value>
  </data>
  <data name="wTotalAmount10k" xml:space="preserve">
    <value>總金額(萬)</value>
  </data>
  <data name="wTranCompCapitalAmt" xml:space="preserve">
    <value>應有銀頭(萬)</value>
  </data>
  <data name="txtCanUsedCompCapital" xml:space="preserve">
    <value>可動用銀頭</value>
  </data>
  <data name="txtCash" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="txtCChip_Cur" xml:space="preserve">
    <value>本更餘現金碼</value>
  </data>
  <data name="txtCheque" xml:space="preserve">
    <value>支票/本票</value>
  </data>
  <data name="txtChipTranBShift" xml:space="preserve">
    <value>本更存卡數</value>
  </data>
  <data name="txtCompCapital" xml:space="preserve">
    <value>櫃面銀頭</value>
  </data>
  <data name="txtCompCapital_Lend" xml:space="preserve">
    <value>對外借入銀頭</value>
  </data>
  <data name="txtCounterBalAmt" xml:space="preserve">
    <value>銀頭對比</value>
  </data>
  <data name="txtCounterBalNoIOU" xml:space="preserve">
    <value>銀頭結算</value>
  </data>
  <data name="txtIOU" xml:space="preserve">
    <value>本廳MARKER</value>
  </data>
  <data name="txtMthBuyChipTot" xml:space="preserve">
    <value>本月買碼數</value>
  </data>
  <data name="txtMthRollingTot" xml:space="preserve">
    <value>本月轉碼數</value>
  </data>
  <data name="txtNNChipMth_BF" xml:space="preserve">
    <value>上月餘泥碼</value>
  </data>
  <data name="txtNNChip_BF" xml:space="preserve">
    <value>上更餘泥碼</value>
  </data>
  <data name="txtNNChip_Buy" xml:space="preserve">
    <value>本更買泥碼</value>
  </data>
  <data name="txtNNChip_Cur" xml:space="preserve">
    <value>本更餘泥碼</value>
  </data>
  <data name="txtRollingBalAmt" xml:space="preserve">
    <value>轉碼對比</value>
  </data>
  <data name="txtRollingShift" xml:space="preserve">
    <value>本更轉碼數</value>
  </data>
  <data name="txtSTORECHIP_LEND" xml:space="preserve">
    <value>借入客人存碼</value>
  </data>
  <data name="typeROLLTRANMGMLST_Core" xml:space="preserve">
    <value>轉碼管理</value>
  </data>
  <data name="txtBuyChip" xml:space="preserve">
    <value>買碼</value>
  </data>
  <data name="wCardCode" xml:space="preserve">
    <value>卡號</value>
  </data>
  <data name="wDiffAmt10k" xml:space="preserve">
    <value>差額(萬)</value>
  </data>
  <data name="GroupByCardCode" xml:space="preserve">
    <value>以卡號分類</value>
  </data>
  <data name="txtAction" xml:space="preserve">
    <value>功能鍵</value>
  </data>
  <data name="txtLastRolling" xml:space="preserve">
    <value>最後轉碼</value>
  </data>
  <data name="txtLoadShift" xml:space="preserve">
    <value>開啟更數資料</value>
  </data>
  <data name="txtRptDtl" xml:space="preserve">
    <value>細數表</value>
  </data>
  <data name="txtOperationCounterBal" xml:space="preserve">
    <value>營運櫃數表</value>
  </data>
  <data name="txtDepositTime" xml:space="preserve">
    <value>存取時間</value>
  </data>
  <data name="txtGameSeq" xml:space="preserve">
    <value>局號</value>
  </data>
  <data name="txtGrpPlace_10k" xml:space="preserve">
    <value>上下數(萬)</value>
  </data>
  <data name="txtIOU10k" xml:space="preserve">
    <value>借款(萬)</value>
  </data>
  <data name="txtIOUTime" xml:space="preserve">
    <value>借貸時間</value>
  </data>
  <data name="txtNumOfDay" xml:space="preserve">
    <value>天數</value>
  </data>
  <data name="txtStart" xml:space="preserve">
    <value>開始</value>
  </data>
  <data name="txtStop" xml:space="preserve">
    <value>停止</value>
  </data>
  <data name="txtTotalAmount10k" xml:space="preserve">
    <value>總額(萬)</value>
  </data>
  <data name="txtUpdt" xml:space="preserve">
    <value>更新日期</value>
  </data>
  <data name="wCapital" xml:space="preserve">
    <value>本金(萬)</value>
  </data>
  <data name="wDailyBal" xml:space="preserve">
    <value>本日累計(萬)</value>
  </data>
  <data name="wGameStatus" xml:space="preserve">
    <value>本單狀態</value>
  </data>
  <data name="wIntroducer" xml:space="preserve">
    <value>來貨人</value>
  </data>
  <data name="wMthBal" xml:space="preserve">
    <value>本月累計(萬)</value>
  </data>
  <data name="wMutiplyPercentage" xml:space="preserve">
    <value>拖數(%)</value>
  </data>
  <data name="wNNChip10k" xml:space="preserve">
    <value>特碼(萬)</value>
  </data>
  <data name="wPendingAmount" xml:space="preserve">
    <value>倘欠(萬)</value>
  </data>
  <data name="wRollingAmt" xml:space="preserve">
    <value>轉碼(萬)</value>
  </data>
  <data name="wStatusOperate" xml:space="preserve">
    <value>營運狀態</value>
  </data>
  <data name="wStatusPlace" xml:space="preserve">
    <value>場面狀態</value>
  </data>
  <data name="wTotalPendingAmount" xml:space="preserve">
    <value>未提取餘額(萬)</value>
  </data>
  <data name="global_btnExportAll" xml:space="preserve">
    <value>匯出全部</value>
  </data>
  <data name="msgRptNeedAgentCd" xml:space="preserve">
    <value>戶口必須填寫</value>
  </data>
  <data name="txtAgentRoveTranDtl" xml:space="preserve">
    <value>巨額資料</value>
  </data>
  <data name="txtImportRove" xml:space="preserve">
    <value>匯入巨額資料</value>
  </data>
  <data name="btnSetType" xml:space="preserve">
    <value>加彩</value>
  </data>
  <data name="txtBPlayRefNo2" xml:space="preserve">
    <value>B數編號</value>
  </data>
  <data name="txtBPlayRefNoSample" xml:space="preserve">
    <value>例如: BTA00019, BTA000031</value>
  </data>
  <data name="txtchkIsCash" xml:space="preserve">
    <value>客人提供現金作轉碼？</value>
  </data>
  <data name="txtForeignRefNo2" xml:space="preserve">
    <value>海外編號</value>
  </data>
  <data name="txtForeignRefNoSample" xml:space="preserve">
    <value>例如: FTA00018, FTA000030</value>
  </data>
  <data name="txtIOURecord" xml:space="preserve">
    <value>借貸單</value>
  </data>
  <data name="txtOperateRefNoSample" xml:space="preserve">
    <value>例如: YTA00017, YTA000029</value>
  </data>
  <data name="wAgentStaffName" xml:space="preserve">
    <value>交易人名稱</value>
  </data>
  <data name="wIOUOutstanding" xml:space="preserve">
    <value>倘欠貸款(萬)</value>
  </data>
  <data name="wIOUOutstandingF" xml:space="preserve">
    <value>海外倘欠貸款(萬)</value>
  </data>
  <data name="wIOUOutstandingY" xml:space="preserve">
    <value>營運倘欠貸款(萬)</value>
  </data>
  <data name="wTotMarkerOutstandingAmt" xml:space="preserve">
    <value>總倘欠貸款(萬)</value>
  </data>
  <data name="wIsLocalCapital" xml:space="preserve">
    <value>本地現金</value>
  </data>
  <data name="wIsMthInterestRoll" xml:space="preserve">
    <value>M現金</value>
  </data>
  <data name="wRollCageAmt" xml:space="preserve">
    <value>本廳本日(萬)</value>
  </data>
  <data name="wRollCageMonthlyAmt" xml:space="preserve">
    <value>本廳本月(萬)</value>
  </data>
  <data name="wRollDailyAmt" xml:space="preserve">
    <value>集團本日(萬)</value>
  </data>
  <data name="wRollMothlyAmt" xml:space="preserve">
    <value>集團本月(萬)</value>
  </data>
  <data name="txtDetailInfo" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="msgRegNotMath" xml:space="preserve">
    <value>不符合所屬輸入規則，請把鼠標移到字樣處查看規則</value>
  </data>
  <data name="txtIOURefNo" xml:space="preserve">
    <value>借貸編號</value>
  </data>
  <data name="txtSystem" xml:space="preserve">
    <value>系統</value>
  </data>
  <data name="txtPrevious" xml:space="preserve">
    <value>承前</value>
  </data>
  <data name="typeCAPITALTRANO_Report" xml:space="preserve">
    <value>營運卡報表</value>
  </data>
  <data name="typeCHIPTRANB_Report" xml:space="preserve">
    <value>存卡報表</value>
  </data>
  <data name="txtInfoOnlyAgent" xml:space="preserve">
    <value>只能選擇代理戶口</value>
  </data>
  <data name="global_btnSelect" xml:space="preserve">
    <value>選取</value>
  </data>
  <data name="txtDetail" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="txtForeignTourNo" xml:space="preserve">
    <value>海外團號碼</value>
  </data>
  <data name="txtChipB10k" xml:space="preserve">
    <value>存卡(萬)</value>
  </data>
  <data name="global_txtCreditTranStatusC" xml:space="preserve">
    <value>無效</value>
  </data>
  <data name="global_txtCreditTranStatusO" xml:space="preserve">
    <value>有效</value>
  </data>
  <data name="txtCreditTranDtl" xml:space="preserve">
    <value>代理信貸額記錄</value>
  </data>
  <data name="txtCreditTranLst" xml:space="preserve">
    <value>信貸額管理</value>
  </data>
  <data name="wCashLoanAmt" xml:space="preserve">
    <value>個人信貸額(萬)</value>
  </data>
  <data name="wCreditAmt" xml:space="preserve">
    <value>信貸額(萬)</value>
  </data>
  <data name="wCreditCapitalAmt" xml:space="preserve">
    <value>U可簽額(萬)</value>
  </data>
  <data name="wForeignCapitalAmt" xml:space="preserve">
    <value>海外股本(萬)</value>
  </data>
  <data name="wMasterCasinoCreditAmt" xml:space="preserve">
    <value>娛樂場額(萬)</value>
  </data>
  <data name="wMthInterestAmt" xml:space="preserve">
    <value>月息(萬)</value>
  </data>
  <data name="wURemarkOptCIOU" xml:space="preserve">
    <value>公Ｕ</value>
  </data>
  <data name="wURemarkOptPause" xml:space="preserve">
    <value>停Ｍ</value>
  </data>
  <data name="global_msgDuplicateAgent" xml:space="preserve">
    <value>已有相同戶口</value>
  </data>
  <data name="txtBChipWithDrawalType" xml:space="preserve">
    <value>提款類型</value>
  </data>
  <data name="global_txtChipTranTypeB_10K" xml:space="preserve">
    <value>存卡(萬)</value>
  </data>
  <data name="txtShowAllRecord" xml:space="preserve">
    <value>顯示全部</value>
  </data>
  <data name="global_msgInputAmountError" xml:space="preserve">
    <value>輸入金額不正確</value>
  </data>
  <data name="typeChipRtnType_IOU" xml:space="preserve">
    <value>借貸單</value>
  </data>
  <data name="typeChipRtnType_CH" xml:space="preserve">
    <value>個人借貸單</value>
  </data>
  <data name="typeChipRtnType_Y" xml:space="preserve">
    <value>營運借貸單</value>
  </data>
  <data name="typeChipRtnType_F" xml:space="preserve">
    <value>海外借貸單</value>
  </data>
  <data name="wStatus_S_InterestDist" xml:space="preserve">
    <value>已派息</value>
  </data>
  <data name="wStatus_T_InterestCancel" xml:space="preserve">
    <value>取消派息</value>
  </data>
  <data name="txtCHSCard" xml:space="preserve">
    <value>海外股本存卡</value>
  </data>
  <data name="typeCAPITALTRANC_Report" xml:space="preserve">
    <value>海外股本報表</value>
  </data>
  <data name="typeCAPITALTRANF_Report" xml:space="preserve">
    <value>凍M報表</value>
  </data>
  <data name="typeCAPITALTRANS_Report" xml:space="preserve">
    <value>股本報表</value>
  </data>
  <data name="wLstOverDueDay" xml:space="preserve">
    <value>最長天期</value>
  </data>
  <data name="wPaymentRemark" xml:space="preserve">
    <value>還款備註</value>
  </data>
  <data name="wRemind" xml:space="preserve">
    <value>注意事項</value>
  </data>
  <data name="txtIOUReturn_10K" xml:space="preserve">
    <value>還款(萬)</value>
  </data>
  <data name="txtPenaltyRtnAmount10k" xml:space="preserve">
    <value>歸還罰息(萬)</value>
  </data>
  <data name="global_txtPenaltyAmt10K" xml:space="preserve">
    <value>罰息金額(萬)</value>
  </data>
  <data name="global_txtAgentStaffName" xml:space="preserve">
    <value>交易人名稱</value>
  </data>
  <data name="global_txtBPlayRefNo2" xml:space="preserve">
    <value>B數編號</value>
  </data>
  <data name="global_txtCustRemark" xml:space="preserve">
    <value>客人特徵</value>
  </data>
  <data name="global_txtRolling" xml:space="preserve">
    <value>轉碼數</value>
  </data>
  <data name="global_txtRollingCapital" xml:space="preserve">
    <value>轉碼本金</value>
  </data>
  <data name="global_txtStatus" xml:space="preserve">
    <value>狀態</value>
  </data>
  <data name="typePLACE_Core" xml:space="preserve">
    <value>場面管理</value>
  </data>
  <data name="wWinLossCapital" xml:space="preserve">
    <value>入枱本金(萬)</value>
  </data>
  <data name="global_btnNewWinLossTran" xml:space="preserve">
    <value>新增客人</value>
  </data>
  <data name="global_btnRefresh" xml:space="preserve">
    <value>更新</value>
  </data>
  <data name="global_btnReward" xml:space="preserve">
    <value>獎勵名單</value>
  </data>
  <data name="global_btnStatusAOnly" xml:space="preserve">
    <value>在場</value>
  </data>
  <data name="global_btnToday" xml:space="preserve">
    <value>今日</value>
  </data>
  <data name="global_txtCompanyGroup" xml:space="preserve">
    <value>集團</value>
  </data>
  <data name="global_txtNumberOfCustomer" xml:space="preserve">
    <value>全日人客數</value>
  </data>
  <data name="global_txtPotential" xml:space="preserve">
    <value>潛質</value>
  </data>
  <data name="global_txtRollTranDtlKEY" xml:space="preserve">
    <value>加彩明細</value>
  </data>
  <data name="global_txtThisCage" xml:space="preserve">
    <value>本廳</value>
  </data>
  <data name="global_txtTotalAmount" xml:space="preserve">
    <value>總額</value>
  </data>
  <data name="global_txtUpdated" xml:space="preserve">
    <value>有新的資料, 請更新!</value>
  </data>
  <data name="global_txtWinLoss_10K" xml:space="preserve">
    <value>輸贏數(萬)</value>
  </data>
  <data name="global_txtAgentCardCodeDisplay" xml:space="preserve">
    <value>轉碼卡</value>
  </data>
  <data name="typeCOUNTERROLLING_Core" xml:space="preserve">
    <value>帳房轉碼</value>
  </data>
  <data name="btnWriteTempCard" xml:space="preserve">
    <value>寫入臨時卡</value>
  </data>
  <data name="txtRollTranTenk" xml:space="preserve">
    <value>加彩(萬)</value>
  </data>
  <data name="txtLaonTenk" xml:space="preserve">
    <value>借貸(萬)</value>
  </data>
  <data name="txtRtnAmt10K" xml:space="preserve">
    <value>歸還(萬)</value>
  </data>
  <data name="txtRollTranTime" xml:space="preserve">
    <value>加彩時間</value>
  </data>
  <data name="txtCompGroupRollDailyAmt" xml:space="preserve">
    <value>集團本日(萬)</value>
  </data>
  <data name="txtCompGroupRollMothlyAmt" xml:space="preserve">
    <value>集團本月(萬)</value>
  </data>
  <data name="txtRollCageAmt" xml:space="preserve">
    <value>本廳本日(萬)</value>
  </data>
  <data name="txtRollCageMonthlyAmt" xml:space="preserve">
    <value>本廳本月(萬)</value>
  </data>
  <data name="txtValidRecordOnly" xml:space="preserve">
    <value>只有有效記錄</value>
  </data>
  <data name="global_txtAgentLevelAndType" xml:space="preserve">
    <value>身份與級別</value>
  </data>
  <data name="typeCREDITLST_Core" xml:space="preserve">
    <value>代理信貸額管理</value>
  </data>
  <data name="typeCREDITDTL_Core" xml:space="preserve">
    <value>代理信貸額記錄</value>
  </data>
  <data name="txtCommon" xml:space="preserve">
    <value>通用</value>
  </data>
  <data name="txtSettleAlone" xml:space="preserve">
    <value>獨立結算</value>
  </data>
  <data name="global_btnWithdraw" xml:space="preserve">
    <value>提取</value>
  </data>
  <data name="wCreditDay" xml:space="preserve">
    <value>寬限天數</value>
  </data>
  <data name="wPercent" xml:space="preserve">
    <value>息率(分)</value>
  </data>
  <data name="txtCurrAmt" xml:space="preserve">
    <value>現有</value>
  </data>
  <data name="txtIsAllLine" xml:space="preserve">
    <value>是否查詢所有線</value>
  </data>
  <data name="txtIsViewAll" xml:space="preserve">
    <value>是否查詢所有場資料</value>
  </data>
  <data name="global_btnExit" xml:space="preserve">
    <value>離開</value>
  </data>
  <data name="global_txtTelbDetail" xml:space="preserve">
    <value>電投</value>
  </data>
  <data name="txtRollStatusOptC" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="txtRollStatusOptO" xml:space="preserve">
    <value>在場</value>
  </data>
  <data name="msgRptNeedAgentCd_I" xml:space="preserve">
    <value>即出咭戶口必須填寫</value>
  </data>
  <data name="txtGambling" xml:space="preserve">
    <value>博彩</value>
  </data>
  <data name="typeCAPITALDTL_Core" xml:space="preserve">
    <value>月息存單</value>
  </data>
  <data name="global_btnDelete" xml:space="preserve">
    <value>刪除</value>
  </data>
  <data name="global_txtChip" xml:space="preserve">
    <value>籌碼</value>
  </data>
  <data name="txtAllDepositor" xml:space="preserve">
    <value>全部存款人</value>
  </data>
  <data name="txtFBPlayRefNo" xml:space="preserve">
    <value>海外佔成編號</value>
  </data>
  <data name="txtIsIncludeCredit" xml:space="preserve">
    <value>計入戶口信貸額</value>
  </data>
  <data name="txtIssueInterestDate" xml:space="preserve">
    <value>月息日</value>
  </data>
  <data name="txtMonthRate" xml:space="preserve">
    <value>月息率(%)</value>
  </data>
  <data name="txtWithdrawRecords" xml:space="preserve">
    <value>取碼記錄</value>
  </data>
  <data name="wCapitalMOrgDate" xml:space="preserve">
    <value>存入日期</value>
  </data>
  <data name="global_msgInfoCounterBalAuditHasVarient" xml:space="preserve">
    <value>帳房日結有差額，請確認繼續儲存。</value>
  </data>
  <data name="txtCounterBalAmount" xml:space="preserve">
    <value>買碼數(萬)</value>
  </data>
  <data name="txtCounterBalTime" xml:space="preserve">
    <value>買碼時間</value>
  </data>
  <data name="wCashChip" xml:space="preserve">
    <value>現碼</value>
  </data>
  <data name="txtMsgInfoSameRefNo" xml:space="preserve">
    <value>單號碼已使用，請使用新號碼。</value>
  </data>
  <data name="txtOperateNoAlreadyBind" xml:space="preserve">
    <value>綁單已存在</value>
  </data>
  <data name="txtMsgCannotFind" xml:space="preserve">
    <value>找不到</value>
  </data>
  <data name="txtWithdrawer" xml:space="preserve">
    <value>提款人</value>
  </data>
  <data name="wNewRefNo" xml:space="preserve">
    <value>新存單編號</value>
  </data>
  <data name="wNNChip" xml:space="preserve">
    <value>特碼</value>
  </data>
  <data name="txtCapitalM" xml:space="preserve">
    <value>月息單</value>
  </data>
  <data name="txtMsgInfoCannotEditOtherCompanyData" xml:space="preserve">
    <value>不能修改其他場的數據資料，如有需要，請按右下角經授權的場作出修改。</value>
  </data>
  <data name="global_btnCheckOut" xml:space="preserve">
    <value>離場</value>
  </data>
  <data name="global_btnCustomer" xml:space="preserve">
    <value>選取人客</value>
  </data>
  <data name="global_btnNow" xml:space="preserve">
    <value>現在</value>
  </data>
  <data name="global_btnRouteUsrID" xml:space="preserve">
    <value>連接路址機</value>
  </data>
  <data name="global_btnRouteWinLoss" xml:space="preserve">
    <value>獲取路址機輸贏數</value>
  </data>
  <data name="global_btnUpdate" xml:space="preserve">
    <value>更改</value>
  </data>
  <data name="global_txtCapital10k" xml:space="preserve">
    <value>本金(萬)</value>
  </data>
  <data name="global_txtCapLimitAmt" xml:space="preserve">
    <value>封頂數</value>
  </data>
  <data name="global_txtDetails" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="global_txtElite" xml:space="preserve">
    <value>尊華會</value>
  </data>
  <data name="global_txtLikeRemark" xml:space="preserve">
    <value>客人喜好</value>
  </data>
  <data name="global_txtNotObtained" xml:space="preserve">
    <value>未獲取</value>
  </data>
  <data name="global_txtObtained" xml:space="preserve">
    <value>已獲取</value>
  </data>
  <data name="global_txtOperateExternal" xml:space="preserve">
    <value>私營</value>
  </data>
  <data name="global_txtOperateType" xml:space="preserve">
    <value>營運種類</value>
  </data>
  <data name="global_txtWinLoss10k" xml:space="preserve">
    <value>輸贏數(萬)</value>
  </data>
  <data name="txtConnectedRoute" xml:space="preserve">
    <value>已連接路址機</value>
  </data>
  <data name="txtNotConnectedRoute" xml:space="preserve">
    <value>未連接路址機</value>
  </data>
  <data name="typePLACE_CUST_Core" xml:space="preserve">
    <value>客人</value>
  </data>
  <data name="txtMsgInfoAgentRequired" xml:space="preserve">
    <value>必需選取戶口</value>
  </data>
  <data name="txtMsgInfoBPlayRefNoRequired" xml:space="preserve">
    <value>必需要有B數單</value>
  </data>
  <data name="txtTableBookingStatus_Booked" xml:space="preserve">
    <value>已預訂</value>
  </data>
  <data name="txtTableBookingStatus_Empty" xml:space="preserve">
    <value>閒置</value>
  </data>
  <data name="txtTableBookingStatus_Occupied" xml:space="preserve">
    <value>使用中</value>
  </data>
  <data name="txtVIPRoom" xml:space="preserve">
    <value>貴賓廳</value>
  </data>
  <data name="typeTABLETRANLST_Core" xml:space="preserve">
    <value>貴賓廳賭枱管理</value>
  </data>
  <data name="wBookDateTime" xml:space="preserve">
    <value>預訂時間</value>
  </data>
  <data name="wRoomCName" xml:space="preserve">
    <value>房號</value>
  </data>
  <data name="wTableCName" xml:space="preserve">
    <value>枱號</value>
  </data>
  <data name="wAgentCName" xml:space="preserve">
    <value>戶主</value>
  </data>
  <data name="wPrtPage" xml:space="preserve">
    <value>頁數</value>
  </data>
  <data name="wPrtRow" xml:space="preserve">
    <value>行數</value>
  </data>
  <data name="txtPrintSet" xml:space="preserve">
    <value>列印設定</value>
  </data>
  <data name="txtConfirmOutSide" xml:space="preserve">
    <value>請確認離場</value>
  </data>
  <data name="global_txtAgentType" xml:space="preserve">
    <value>戶口類型</value>
  </data>
  <data name="global_txtPercentageSign" xml:space="preserve">
    <value>佔成(%)</value>
  </data>
  <data name="global_txtRouteUsrID" xml:space="preserve">
    <value>路址用戶ID</value>
  </data>
  <data name="global_txtVIPRoom" xml:space="preserve">
    <value>貴賓廳</value>
  </data>
  <data name="global_btnBook" xml:space="preserve">
    <value>預訂</value>
  </data>
  <data name="typeTABLETRANDTL_Core" xml:space="preserve">
    <value>貴賓房配置記錄</value>
  </data>
  <data name="typeWINLOSE_Core" xml:space="preserve">
    <value>上下數</value>
  </data>
  <data name="txtBalanceToBe" xml:space="preserve">
    <value>掛數</value>
  </data>
  <data name="txtRoom" xml:space="preserve">
    <value>房</value>
  </data>
  <data name="txtTableTranStatusOptC" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="txtTableTranStatusOptO" xml:space="preserve">
    <value>有效</value>
  </data>
  <data name="txtMarkerReturnTypeC" xml:space="preserve">
    <value>現碼還M</value>
  </data>
  <data name="txtMarkerReturnTypeM" xml:space="preserve">
    <value>M還M</value>
  </data>
  <data name="txtMarkerReturnTypeR" xml:space="preserve">
    <value>存M還M</value>
  </data>
  <data name="txtMarkerReturnTypeW" xml:space="preserve">
    <value>嬴錢回舊M</value>
  </data>
  <data name="txtMarkerReturnTypeS" xml:space="preserve">
    <value>佣金回M</value>
  </data>
  <data name="typeChip_StoreM" xml:space="preserve">
    <value>存M</value>
  </data>
  <data name="global_txtHoldChipAmt10K" xml:space="preserve">
    <value>凍結存款(萬)</value>
  </data>
  <data name="wStoreNegativeAmt10K" xml:space="preserve">
    <value>可負數額(萬)</value>
  </data>
  <data name="wAvailableAmt10K" xml:space="preserve">
    <value>可動用結存(萬)</value>
  </data>
  <data name="type_IO" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="type_IR" xml:space="preserve">
    <value>歸還IOU</value>
  </data>
  <data name="type_SO" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="type_SR" xml:space="preserve">
    <value>歸還股本</value>
  </data>
  <data name="type_CIO" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="type_CIR" xml:space="preserve">
    <value>歸還公司U</value>
  </data>
  <data name="type_TSO" xml:space="preserve">
    <value>暫存</value>
  </data>
  <data name="type_TSR" xml:space="preserve">
    <value>取暫存</value>
  </data>
  <data name="type_CWO" xml:space="preserve">
    <value>客人未取</value>
  </data>
  <data name="type_CWR" xml:space="preserve">
    <value>客人已取</value>
  </data>
  <data name="txtTllRtnAmt10K" xml:space="preserve">
    <value>總還款額(萬)</value>
  </data>
  <data name="txtTllRtnPenalty10K" xml:space="preserve">
    <value>總還息額(萬)</value>
  </data>
  <data name="global_txtChipTranTypeI_10K" xml:space="preserve">
    <value>存單金額(萬)</value>
  </data>
  <data name="type_ICR" xml:space="preserve">
    <value>提單</value>
  </data>
  <data name="type_ICS" xml:space="preserve">
    <value>存單</value>
  </data>
  <data name="type_CASHR" xml:space="preserve">
    <value>提款</value>
  </data>
  <data name="type_CASHS" xml:space="preserve">
    <value>存款</value>
  </data>
  <data name="global_msgIOUAmountNoMatch" xml:space="preserve">
    <value>借貸單還款金額不符</value>
  </data>
  <data name="global_msgNoIOURecord" xml:space="preserve">
    <value>沒有對應借貸單</value>
  </data>
  <data name="global_txtLobby" xml:space="preserve">
    <value>大堂</value>
  </data>
  <data name="wGame10K" xml:space="preserve">
    <value>本場累計(萬)</value>
  </data>
  <data name="txtPrintTime" xml:space="preserve">
    <value>列印時間</value>
  </data>
  <data name="txtRollingSummaryPrintTableHeader" xml:space="preserve">
    <value>次序   時間　　轉碼　　本場　　本日</value>
  </data>
  <data name="txtGrpChip" xml:space="preserve">
    <value>存單</value>
  </data>
  <data name="txtGrpMarker" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="txtGrpWinLoss" xml:space="preserve">
    <value>枱面</value>
  </data>
  <data name="wCustCName" xml:space="preserve">
    <value>存款人</value>
  </data>
  <data name="wCustEName" xml:space="preserve">
    <value>客人英文名稱</value>
  </data>
  <data name="wCustRemark" xml:space="preserve">
    <value>客人特徵</value>
  </data>
  <data name="typeLOOKUPCUSTOMER_Core" xml:space="preserve">
    <value>選取客人</value>
  </data>
  <data name="txtChipTypeA" xml:space="preserve">
    <value>A數</value>
  </data>
  <data name="txtChipTypeB" xml:space="preserve">
    <value>B數</value>
  </data>
  <data name="global_txtTransactionValue" xml:space="preserve">
    <value>交易金額</value>
  </data>
  <data name="wCrtCompNo" xml:space="preserve">
    <value>創建公司</value>
  </data>
  <data name="wCrtDept" xml:space="preserve">
    <value>創建部門</value>
  </data>
  <data name="typeCOUNTERBAL_Core" xml:space="preserve">
    <value>櫃數表</value>
  </data>
  <data name="typeOPERATIONCOUNTERBAL_Core" xml:space="preserve">
    <value>營運櫃數表</value>
  </data>
  <data name="txtNumber" xml:space="preserve">
    <value>編號</value>
  </data>
  <data name="global_txtAmountHKD10K" xml:space="preserve">
    <value>港幣金額(萬)</value>
  </data>
  <data name="txtRollingView" xml:space="preserve">
    <value>轉碼記錄</value>
  </data>
  <data name="global_msgUserPasswordRule" xml:space="preserve">
    <value>密碼必需6-10位 (包括最少一個數字, 一個大楷, 一個細楷)</value>
  </data>
  <data name="global_txtEName" xml:space="preserve">
    <value>英文姓名</value>
  </data>
  <data name="btnGenActCode" xml:space="preserve">
    <value>重設行動碼</value>
  </data>
  <data name="txtEliteRoyaltyCard" xml:space="preserve">
    <value>尊貴卡</value>
  </data>
  <data name="txtUploadSignature" xml:space="preserve">
    <value>簽名</value>
  </data>
  <data name="wRelatedAgentCodeIn" xml:space="preserve">
    <value>相關代理</value>
  </data>
  <data name="global_MsgXlsxError" xml:space="preserve">
    <value>導入的文件格式不對，請參照相應的導入模板</value>
  </data>
  <data name="txtGamblingEndTime" xml:space="preserve">
    <value>博彩完成時間</value>
  </data>
  <data name="txtGamblingStartTime" xml:space="preserve">
    <value>博彩開始時間</value>
  </data>
  <data name="txtHotelType" xml:space="preserve">
    <value>酒店類型</value>
  </data>
  <data name="wExpParentCode" xml:space="preserve">
    <value>消費類型</value>
  </data>
  <data name="wExpSubCode" xml:space="preserve">
    <value>消費分類</value>
  </data>
  <data name="txtShowCurrentMth" xml:space="preserve">
    <value>只顯示本月</value>
  </data>
  <data name="txtShowSettle" xml:space="preserve">
    <value>已歸還</value>
  </data>
  <data name="wExpOutstanding" xml:space="preserve">
    <value>尚欠費用</value>
  </data>
  <data name="global_msgPwdNotMatch" xml:space="preserve">
    <value>密碼與確認密碼不一致</value>
  </data>
  <data name="wActionCode" xml:space="preserve">
    <value>行動碼</value>
  </data>
  <data name="typeAGENTDTL_Core" xml:space="preserve">
    <value>戶口記錄</value>
  </data>
  <data name="typeAGENTMANAGER_Core" xml:space="preserve">
    <value>戶口經理版</value>
  </data>
  <data name="typeAGENTREMARKHISDTL_Core" xml:space="preserve">
    <value>戶口備註記錄</value>
  </data>
  <data name="typeAGENTROVEDTL_Core" xml:space="preserve">
    <value>戶口經理版</value>
  </data>
  <data name="typeAGENTROVETRANDTL_Core" xml:space="preserve">
    <value>巨額資料</value>
  </data>
  <data name="typeBUYCHIPCURRMTH_Core" xml:space="preserve">
    <value>本月買碼表</value>
  </data>
  <data name="typeBUYCHIPDTL_Core" xml:space="preserve">
    <value>櫃數表</value>
  </data>
  <data name="typeCOMPANYDTL_Core" xml:space="preserve">
    <value>公司記錄</value>
  </data>
  <data name="typeCREDITCONTROL_CONTACT_Core" xml:space="preserve">
    <value>信貸監控-聯絡資料</value>
  </data>
  <data name="typeCURRENCY_RATE_DTL_Core" xml:space="preserve">
    <value>貨幣匯率管理</value>
  </data>
  <data name="typeCUSTOMERDTL_Core" xml:space="preserve">
    <value>客人記錄</value>
  </data>
  <data name="typeDEVICEDTL_Core" xml:space="preserve">
    <value>裝置記錄</value>
  </data>
  <data name="typeEXPTRANCARDDTL_Core" xml:space="preserve">
    <value>卡消費記錄</value>
  </data>
  <data name="typeFOREIGNITEM_Core" xml:space="preserve">
    <value>海外團詳情</value>
  </data>
  <data name="typeIMPORTROVE_Core" xml:space="preserve">
    <value>匯入巨額資料</value>
  </data>
  <data name="typeAGENTEXT_Core" xml:space="preserve">
    <value>客人其他資訊</value>
  </data>
  <data name="typeINTERESTRATEDTL_Core" xml:space="preserve">
    <value>存款利息</value>
  </data>
  <data name="typeMARKERRPT_Core" xml:space="preserve">
    <value>借貸现况表</value>
  </data>
  <data name="typeROLEDTL_Core" xml:space="preserve">
    <value>權限管理</value>
  </data>
  <data name="typeROLLINGDTL_Core" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="typeROLLING_LST_Core" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="typeROVECUSTOMERDTL_Core" xml:space="preserve">
    <value>客人管理</value>
  </data>
  <data name="typeUSRDTL_Core" xml:space="preserve">
    <value>用戶管理</value>
  </data>
  <data name="typeCOUNTERBALSETTLE_Core" xml:space="preserve">
    <value>三更結算表</value>
  </data>
  <data name="action_DELETE_type" xml:space="preserve">
    <value>刪除</value>
  </data>
  <data name="action_IMPORT_type" xml:space="preserve">
    <value>匯入</value>
  </data>
  <data name="action_NEW_type" xml:space="preserve">
    <value>新增New</value>
  </data>
  <data name="txtAlreadySend" xml:space="preserve">
    <value>已發送</value>
  </data>
  <data name="txtBtnGenIOUWarnSMS" xml:space="preserve">
    <value>生成提示短訊</value>
  </data>
  <data name="txtBtnSendSms" xml:space="preserve">
    <value>發送短訊</value>
  </data>
  <data name="txtNeedNotSend" xml:space="preserve">
    <value>不發送</value>
  </data>
  <data name="txtNonExpiredMarker" xml:space="preserve">
    <value>未過期M</value>
  </data>
  <data name="txtShareGrp" xml:space="preserve">
    <value>戶口組</value>
  </data>
  <data name="txtShareWithDownLine" xml:space="preserve">
    <value>股東(包括下線)</value>
  </data>
  <data name="txtShowSubLevel" xml:space="preserve">
    <value>包下線</value>
  </data>
  <data name="txtSMSContent" xml:space="preserve">
    <value>短訊內容</value>
  </data>
  <data name="txtTestNumber" xml:space="preserve">
    <value>測試號碼</value>
  </data>
  <data name="wSMSDateTime" xml:space="preserve">
    <value>SMS發送時間</value>
  </data>
  <data name="txtRemittanceTranLst" xml:space="preserve">
    <value>匯款管理</value>
  </data>
  <data name="txtTransferredAmt10k" xml:space="preserve">
    <value>兌換金額(萬)</value>
  </data>
  <data name="typeREMITTANCETRANDTL_Core" xml:space="preserve">
    <value>匯款記錄</value>
  </data>
  <data name="typeREMITTANCETRANLST_Core" xml:space="preserve">
    <value>匯款管理</value>
  </data>
  <data name="wDeductedTransferredAmt" xml:space="preserve">
    <value>兌換金額(扣除手續費)</value>
  </data>
  <data name="wExchangeTo" xml:space="preserve">
    <value>兌換成</value>
  </data>
  <data name="wFromCurrCode" xml:space="preserve">
    <value>由貨幣</value>
  </data>
  <data name="wFromFxRate" xml:space="preserve">
    <value>匯率(乘)</value>
  </data>
  <data name="wFromFxRateDiv" xml:space="preserve">
    <value>匯率(除)</value>
  </data>
  <data name="wHandlingAmt" xml:space="preserve">
    <value>手續費</value>
  </data>
  <data name="wHandlingAmt10K" xml:space="preserve">
    <value>手續費(萬)</value>
  </data>
  <data name="wHandlingRate" xml:space="preserve">
    <value>手續費(率)</value>
  </data>
  <data name="wToCurrCode" xml:space="preserve">
    <value>至貨幣</value>
  </data>
  <data name="txtWithDownLv" xml:space="preserve">
    <value>連下線</value>
  </data>
  <data name="global_MsgInfoOverwriteOldRec" xml:space="preserve">
    <value>將覆蓋舊有記錄</value>
  </data>
  <data name="txtIOUWarnLst" xml:space="preserve">
    <value>借貸提示</value>
  </data>
  <data name="wForeignCapitalAmt1" xml:space="preserve">
    <value>海外股本(萬)</value>
  </data>
  <data name="wForeignCapitalAmt_CNY" xml:space="preserve">
    <value>海外股本CNY(萬)</value>
  </data>
  <data name="typeOTHERS_Core" xml:space="preserve">
    <value>其他</value>
  </data>
  <data name="typeIOUWARNLST_Core" xml:space="preserve">
    <value>借貸提示</value>
  </data>
  <data name="typeIOUWARNLST_F_Core" xml:space="preserve">
    <value>借貸提示(海外)</value>
  </data>
  <data name="typeIOUWARNLST_Y_Core" xml:space="preserve">
    <value>借貸提示(營運)</value>
  </data>
  <data name="txtRtnInfo" xml:space="preserve">
    <value>歸還資料</value>
  </data>
  <data name="wBFExpAmount" xml:space="preserve">
    <value>欠前消費</value>
  </data>
  <data name="wBFExpRtnAmount" xml:space="preserve">
    <value>欠費歸還</value>
  </data>
  <data name="txtCommission" xml:space="preserve">
    <value>佣金</value>
  </data>
  <data name="wDtLastFailed" xml:space="preserve">
    <value>最後登入錯誤時間</value>
  </data>
  <data name="msgNeedValue" xml:space="preserve">
    <value>必須填寫</value>
  </data>
  <data name="global_msgInfoAgentRequired" xml:space="preserve">
    <value>必需選取戶口</value>
  </data>
  <data name="global_msgInfoInputMissing" xml:space="preserve">
    <value>仍未輸入所有資料</value>
  </data>
  <data name="global_txtWinLoss" xml:space="preserve">
    <value>輸贏</value>
  </data>
  <data name="txtPenaltyRtnAmountHKD10k" xml:space="preserve">
    <value>港幣歸還罰息(萬)</value>
  </data>
  <data name="global_GroupBy" xml:space="preserve">
    <value>分類</value>
  </data>
  <data name="txtURollingDaily" xml:space="preserve">
    <value>轉碼按場日結</value>
  </data>
  <data name="wDailyBalHKD" xml:space="preserve">
    <value>本日折港幣總累計(萬)</value>
  </data>
  <data name="wMthBalHKD" xml:space="preserve">
    <value>本月折港幣總累計(萬)</value>
  </data>
  <data name="typePLACE_CHECKOUT_Core" xml:space="preserve">
    <value>離場及輸贏</value>
  </data>
  <data name="global_msgErrCannotBeZero" xml:space="preserve">
    <value>數值不能為零</value>
  </data>
  <data name="global_msgErrRtnGreaterOutstanding" xml:space="preserve">
    <value>扣減多於餘額</value>
  </data>
  <data name="global_msgInfoNotCurrCode" xml:space="preserve">
    <value>沒有此貨幣</value>
  </data>
  <data name="msgRptNeedDate" xml:space="preserve">
    <value>請選擇日期範圍</value>
  </data>
  <data name="txtCapitalTranM" xml:space="preserve">
    <value>月息單管理</value>
  </data>
  <data name="txtCapitalTranH" xml:space="preserve">
    <value>凍結存款單管理</value>
  </data>
  <data name="typeCAPITALTRAN_M_LST_Core" xml:space="preserve">
    <value>月息單管理</value>
  </data>
  <data name="typeCAPITALTRAN_H_LST_Core" xml:space="preserve">
    <value>凍結存款單管理</value>
  </data>
  <data name="txtShowStoreOutstanding" xml:space="preserve">
    <value>只顯示未取</value>
  </data>
  <data name="global_txtLanguage" xml:space="preserve">
    <value>語言</value>
  </data>
  <data name="global_txtRecipient" xml:space="preserve">
    <value>收件人</value>
  </data>
  <data name="txtExternalExp" xml:space="preserve">
    <value>外消費</value>
  </data>
  <data name="txtInternalExp" xml:space="preserve">
    <value>內消費</value>
  </data>
  <data name="txtCustChipTranBShift" xml:space="preserve">
    <value>本更電投存卡數</value>
  </data>
  <data name="wShiftCustChipBInAmt" xml:space="preserve">
    <value>電投客人存卡總數(萬)</value>
  </data>
  <data name="wShiftCustChipBOutAmt" xml:space="preserve">
    <value>電投客人取卡總數(萬)</value>
  </data>
  <data name="txtMsgCurrencyExchangeFormula" xml:space="preserve">
    <value>若匯率(乘) 及 (除) 均有數值, 會以匯率(乘) 為準計算
  兌換公式
    使用匯率(乘): 金額 * 匯率(乘) - 手續費
    使用匯率(除): 金額 / 匯率(除) - 手續費
  若手續費欄位為0時, 輸入手續費(率) 會自動計算手續費。</value>
  </data>
  <data name="txtMonthlyInterestWorkList" xml:space="preserve">
    <value>月息派發管理</value>
  </data>
  <data name="txtCompanyReal" xml:space="preserve">
    <value>公司實數</value>
  </data>
  <data name="txtInterestYearMth" xml:space="preserve">
    <value>派息月份</value>
  </data>
  <data name="txtPoint" xml:space="preserve">
    <value>積分</value>
  </data>
  <data name="txtPointHKD" xml:space="preserve">
    <value>積分HKD</value>
  </data>
  <data name="txtTtlCaplitalAmt" xml:space="preserve">
    <value>總月息HKD(萬)</value>
  </data>
  <data name="wBPenaltyInterest" xml:space="preserve">
    <value>尚餘罰息HKD(萬)</value>
  </data>
  <data name="wConfirmInterestAmt" xml:space="preserve">
    <value>確認派息(萬)</value>
  </data>
  <data name="wConfirmPenalty" xml:space="preserve">
    <value>確認罰息(萬)</value>
  </data>
  <data name="wConfirmPoint" xml:space="preserve">
    <value>確認積分HKD</value>
  </data>
  <data name="wDPenaltyInterest" xml:space="preserve">
    <value>扣減罰息HKD</value>
  </data>
  <data name="wDPenaltyInterestOrg" xml:space="preserve">
    <value>扣減罰息</value>
  </data>
  <data name="wInterestAmt" xml:space="preserve">
    <value>利息(萬)</value>
  </data>
  <data name="wInterestDateTime" xml:space="preserve">
    <value>派息日期</value>
  </data>
  <data name="wModifiedDate" xml:space="preserve">
    <value>更新時間</value>
  </data>
  <data name="wMonthlyRefNo" xml:space="preserve">
    <value>月息單號碼</value>
  </data>
  <data name="wMTotalChargeInterest" xml:space="preserve">
    <value>總扣減罰息(港幣)(萬)</value>
  </data>
  <data name="wMTotalChargePenalty" xml:space="preserve">
    <value>總尚餘罰息(港幣)(萬)</value>
  </data>
  <data name="wMTotalInterestCNY" xml:space="preserve">
    <value>總利息(人民幣)(萬)</value>
  </data>
  <data name="wMTotalInterest" xml:space="preserve">
    <value>總利息(港幣)(萬)</value>
  </data>
  <data name="wMTotalMonthPenalty" xml:space="preserve">
    <value>總罰息(港幣)(萬)</value>
  </data>
  <data name="wMTotalRealInterestCNY" xml:space="preserve">
    <value>總實出派息(人民幣)(萬)</value>
  </data>
  <data name="wMTotalRealInterest" xml:space="preserve">
    <value>總實出派息(港幣)(萬)</value>
  </data>
  <data name="wMTotalRealPoint" xml:space="preserve">
    <value>總派息積分(港幣)(萬)</value>
  </data>
  <data name="wOrgDate" xml:space="preserve">
    <value>原單日期</value>
  </data>
  <data name="wPenaltyInterest" xml:space="preserve">
    <value>罰息HKD(萬)</value>
  </data>
  <data name="wRealInterestAmt" xml:space="preserve">
    <value>實出利息(萬)</value>
  </data>
  <data name="typeBCounterBal_Core" xml:space="preserve">
    <value>B數櫃數表</value>
  </data>
  <data name="txtBFShiftCounterBal" xml:space="preserve">
    <value>請檢查上更資料是否已結算.</value>
  </data>
  <data name="txtAgentMonthly" xml:space="preserve">
    <value>客人月息</value>
  </data>
  <data name="txtEmployeeMonthly" xml:space="preserve">
    <value>員工月息</value>
  </data>
  <data name="txtMonthlyType" xml:space="preserve">
    <value>月息類型</value>
  </data>
  <data name="wMOnlyShowTStatus" xml:space="preserve">
    <value>只顯示取消派息</value>
  </data>
  <data name="wRegenMonthlyInterest" xml:space="preserve">
    <value>重新生成月息(只限未派月息)</value>
  </data>
  <data name="wStatusA_NoInterest" xml:space="preserve">
    <value>尚未派息</value>
  </data>
  <data name="wStatusI_MonthlyInterest" xml:space="preserve">
    <value>尚未派息及已派息</value>
  </data>
  <data name="typeMTHINTERWORKLST_Core" xml:space="preserve">
    <value>月息派發管理</value>
  </data>
  <data name="typeROLLINGDAILY_Core" xml:space="preserve">
    <value>轉碼按場日結</value>
  </data>
  <data name="typeCHIPTRAN_I_LST_Core" xml:space="preserve">
    <value>存單管理</value>
  </data>
  <data name="msgErrLoginFailed" xml:space="preserve">
    <value>登入錯誤</value>
  </data>
  <data name="wDomain" xml:space="preserve">
    <value>網域名稱</value>
  </data>
  <data name="wTelbCustomerID" xml:space="preserve">
    <value>電投戶口</value>
  </data>
  <data name="btnPrintRollDtl" xml:space="preserve">
    <value>列印轉碼細數表</value>
  </data>
  <data name="txtCustChipTranTBShift" xml:space="preserve">
    <value>本更電投存卡數</value>
  </data>
  <data name="txtBettingMethod" xml:space="preserve">
    <value>投注方法</value>
  </data>
  <data name="txtNonDoubleIdentity" xml:space="preserve">
    <value>雙重身份</value>
  </data>
  <data name="txtRollChipOpt" xml:space="preserve">
    <value>出碼類</value>
  </data>
  <data name="global_msgConflictAuth" xml:space="preserve">
    <value>授權人與經手人相同。</value>
  </data>
  <data name="btnCancelTelPassword" xml:space="preserve">
    <value>轉用現場認証</value>
  </data>
  <data name="txtInfoIVRAuthByPass" xml:space="preserve">
    <value>已跳過戶口密碼証證</value>
  </data>
  <data name="txtAdjust" xml:space="preserve">
    <value>調整</value>
  </data>
  <data name="global_msgErrBackDayRollingShouldNotBeToday" xml:space="preserve">
    <value>此功能所選之日期，不能大於今天的會計日期</value>
  </data>
  <data name="global_msgInfoAgentNotFound" xml:space="preserve">
    <value>戶口不存在</value>
  </data>
  <data name="global_msgMissingIOURefNo" xml:space="preserve">
    <value>還未選擇借貸單, 繼續嗎 ?</value>
  </data>
  <data name="global_msgTelbPositiveNegativeNotCorrect" xml:space="preserve">
    <value>電投買碼正負值不正確</value>
  </data>
  <data name="txtTelbRecordCannotAddCapital" xml:space="preserve">
    <value>電投紀錄不能加彩</value>
  </data>
  <data name="msgIVRMissingToken" xml:space="preserve">
    <value>內線被佔用,請重新認証</value>
  </data>
  <data name="msgErrIVRAuthFail" xml:space="preserve">
    <value>認証失敗,請重新認証</value>
  </data>
  <data name="msgErrIVRAuthIncorrect" xml:space="preserve">
    <value>未獲得有效認証, 請重新輸入有效的戶口密碼或授權人密碼</value>
  </data>
  <data name="txtIOUDate" xml:space="preserve">
    <value>借貸日期</value>
  </data>
  <data name="txtPenaltyAmtHKD" xml:space="preserve">
    <value>HKD 罰息金額</value>
  </data>
  <data name="txtPenaltyRtnAmount10k_HKD" xml:space="preserve">
    <value>HKD歸還罰息(萬)</value>
  </data>
  <data name="typeSPECIALMARKERLST_F_Core" xml:space="preserve">
    <value>海外貸款管理</value>
  </data>
  <data name="typeSPECIALMARKERLST_Y_Core" xml:space="preserve">
    <value>營運貸款管理</value>
  </data>
  <data name="global_onlyIOUStatusComplete" xml:space="preserve">
    <value>只顯示已清還</value>
  </data>
  <data name="global_onlyIOUStatusOpen" xml:space="preserve">
    <value>只顯示倘有未清還</value>
  </data>
  <data name="txtReturnDateTime" xml:space="preserve">
    <value>還款時間</value>
  </data>
  <data name="txtMarkerAmt" xml:space="preserve">
    <value>貸款額</value>
  </data>
  <data name="txtMarkerRemainAmt" xml:space="preserve">
    <value>貸款餘額</value>
  </data>
  <data name="txtMarkerRtnAmt" xml:space="preserve">
    <value>已還款</value>
  </data>
  <data name="typeMARKERDTL_Core" xml:space="preserve">
    <value>貸款記錄</value>
  </data>
  <data name="typeMARKERLST_Core" xml:space="preserve">
    <value>貸款管理</value>
  </data>
  <data name="global_btnEdt" xml:space="preserve">
    <value>編緝</value>
  </data>
  <data name="txtAllBorrower" xml:space="preserve">
    <value>全部借款人</value>
  </data>
  <data name="txtBadDebt" xml:space="preserve">
    <value>壞賬</value>
  </data>
  <data name="txtContractNo" xml:space="preserve">
    <value>合同編號</value>
  </data>
  <data name="txtIOUMonthlyFreeze" xml:space="preserve">
    <value>月結M凍結</value>
  </data>
  <data name="txtLimit" xml:space="preserve">
    <value>限額</value>
  </data>
  <data name="txtLimitCompany" xml:space="preserve">
    <value>本廳信貸額(萬)</value>
  </data>
  <data name="txtLimitGroup" xml:space="preserve">
    <value>集團信貸額(萬)</value>
  </data>
  <data name="txtLoanCompany" xml:space="preserve">
    <value>本廳已簽額(萬)</value>
  </data>
  <data name="txtLoanGroup" xml:space="preserve">
    <value>集團已簽額(萬)</value>
  </data>
  <data name="txtPhotoExpiry" xml:space="preserve">
    <value>相片已過期</value>
  </data>
  <data name="txtReturnRecords" xml:space="preserve">
    <value>還款記錄</value>
  </data>
  <data name="wAgentStaff" xml:space="preserve">
    <value>伙計</value>
  </data>
  <data name="wConditionType" xml:space="preserve">
    <value>條件類型</value>
  </data>
  <data name="wOutstandingGroup" xml:space="preserve">
    <value>已簽額(萬)</value>
  </data>
  <data name="wPenaltyRate" xml:space="preserve">
    <value>息率(%)</value>
  </data>
  <data name="wReturnType" xml:space="preserve">
    <value>歸還類</value>
  </data>
  <data name="wSettleMan" xml:space="preserve">
    <value>還款人</value>
  </data>
  <data name="wTotalCreditLeftGroup" xml:space="preserve">
    <value>可簽餘額(萬)</value>
  </data>
  <data name="wTotalCredit_10K" xml:space="preserve">
    <value>總信貸額(萬)</value>
  </data>
  <data name="wSalt" xml:space="preserve">
    <value>RollexSamLin</value>
  </data>
  <data name="global_btnSet" xml:space="preserve">
    <value>選擇</value>
  </data>
  <data name="txtChkShowSettled" xml:space="preserve">
    <value>顯示已清還記錄</value>
  </data>
  <data name="txtRelatedIOU" xml:space="preserve">
    <value>相關借貸單</value>
  </data>
  <data name="txtRelatedSIOU" xml:space="preserve">
    <value>相關營運借貸單</value>
  </data>
  <data name="txtCreditTypeMonRate" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="txtPenalty" xml:space="preserve">
    <value>罰息</value>
  </data>
  <data name="wDeduct" xml:space="preserve">
    <value>扣取</value>
  </data>
  <data name="wPayment" xml:space="preserve">
    <value>派發</value>
  </data>
  <data name="wReal" xml:space="preserve">
    <value>實出</value>
  </data>
  <data name="txtIOUHK" xml:space="preserve">
    <value>HKD借款</value>
  </data>
  <data name="txtMarkerCurrency" xml:space="preserve">
    <value>借貸貨幣</value>
  </data>
  <data name="txtMsgInfoMarkerCurrency" xml:space="preserve">
    <value>代理對公司的貨幣</value>
  </data>
  <data name="txtMsgInfoSettleCurrency" xml:space="preserve">
    <value>公司對外地賭場的貨幣</value>
  </data>
  <data name="txtSettleCurrency" xml:space="preserve">
    <value>交易貨幣</value>
  </data>
  <data name="txtShowSettled" xml:space="preserve">
    <value>顯示已清還記錄</value>
  </data>
  <data name="msgErrPWDNotSame" xml:space="preserve">
    <value>確認密碼不相同</value>
  </data>
  <data name="global_txtDataSource" xml:space="preserve">
    <value>數據來源</value>
  </data>
  <data name="global_txtDataSourceName" xml:space="preserve">
    <value>數據名稱</value>
  </data>
  <data name="txtOnlyIOUStatusComplete" xml:space="preserve">
    <value>只顯示已清還</value>
  </data>
  <data name="txtOnlyIOUStatusOpen" xml:space="preserve">
    <value>只顯示倘有未清還</value>
  </data>
  <data name="txtPenaltyRtnAmount_HKD" xml:space="preserve">
    <value>HKD歸還罰息</value>
  </data>
  <data name="txtReturnCurrency" xml:space="preserve">
    <value>還款貨幣</value>
  </data>
  <data name="txtReturnType_CW" xml:space="preserve">
    <value>客人取回</value>
  </data>
  <data name="msgIVRPWDFormat" xml:space="preserve">
    <value>密碼需為全數字及長度為4至6</value>
  </data>
  <data name="global_txt10k" xml:space="preserve">
    <value>萬</value>
  </data>
  <data name="txtCustOnBoard" xml:space="preserve">
    <value>客人正在場面</value>
  </data>
  <data name="txtPenaltyRtnAmount" xml:space="preserve">
    <value>歸還罰息</value>
  </data>
  <data name="txtTotSettleAmount" xml:space="preserve">
    <value>總歸還額</value>
  </data>
  <data name="typeMARKERRETURNDTL_Core" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="wHKAmount" xml:space="preserve">
    <value>HKD總額</value>
  </data>
  <data name="global_msgInfoAgentCreditExists" xml:space="preserve">
    <value>戶口信貸額已存在，請按確定以繼續編輯，按取消重新輸入戶口。</value>
  </data>
  <data name="global_btnSaveAndPrint" xml:space="preserve">
    <value>儲存併列印</value>
  </data>
  <data name="txtIOUReturnHK" xml:space="preserve">
    <value>HKD還款</value>
  </data>
  <data name="txtRelatedMarkerReturn" xml:space="preserve">
    <value>相關還款</value>
  </data>
  <data name="typeMARKERLST_C_Core" xml:space="preserve">
    <value>個人借貸管理</value>
  </data>
  <data name="txtIOUAgent" xml:space="preserve">
    <value>借貸戶口</value>
  </data>
  <data name="typeENQUIRY_Core" xml:space="preserve">
    <value>查詢</value>
  </data>
  <data name="typeTRANLOGENQUIRY_Core" xml:space="preserve">
    <value>資料日誌查詢</value>
  </data>
  <data name="typeMARKERDTL_C_Core" xml:space="preserve">
    <value>個人借貸記錄</value>
  </data>
  <data name="wDataCode" xml:space="preserve">
    <value>檔案類型</value>
  </data>
  <data name="wLogDesc" xml:space="preserve">
    <value>資料</value>
  </data>
  <data name="wOperation" xml:space="preserve">
    <value>行動</value>
  </data>
  <data name="wNewCName" xml:space="preserve">
    <value>新增中文姓名</value>
  </data>
  <data name="wTagetName" xml:space="preserve">
    <value>目標姓名</value>
  </data>
  <data name="global_msgAgentHasTran" xml:space="preserve">
    <value>戶口交易記錄已存在</value>
  </data>
  <data name="global_msgRecordExist" xml:space="preserve">
    <value>記錄已存在</value>
  </data>
  <data name="type_MCR" xml:space="preserve">
    <value>提月息單</value>
  </data>
  <data name="type_MCS" xml:space="preserve">
    <value>存月息單</value>
  </data>
  <data name="type_HCR" xml:space="preserve">
    <value>提凍結單</value>
  </data>
  <data name="type_HCS" xml:space="preserve">
    <value>存凍結單</value>
  </data>
  <data name="global_chkMaster" xml:space="preserve">
    <value>母資料</value>
  </data>
  <data name="global_btnMerger" xml:space="preserve">
    <value>客人合併</value>
  </data>
  <data name="typeCUSTOMERMERGERDTL_Core" xml:space="preserve">
    <value>客人合併</value>
  </data>
  <data name="txtFreezeAmt10K" xml:space="preserve">
    <value>凍結(萬)</value>
  </data>
  <data name="txtMsgInfoRefNoOnlyAlphaNumeric" xml:space="preserve">
    <value>單號只接受英文字母和數目字</value>
  </data>
  <data name="global_msgInfoCannotEditOtherCompanyData" xml:space="preserve">
    <value>不能修改其他場的數據資料，如有需要，請按右下角經授權的場作出修改。</value>
  </data>
  <data name="global_msgDuplicateCustNameC" xml:space="preserve">
    <value>不能輸入重覆中文名</value>
  </data>
  <data name="global_msgDuplicateMaster" xml:space="preserve">
    <value>不能選取多於一個母資料</value>
  </data>
  <data name="global_wMissingTargetName" xml:space="preserve">
    <value>請選擇目標名字</value>
  </data>
  <data name="global_MasterData" xml:space="preserve">
    <value>[母資料]</value>
  </data>
  <data name="global_txtCustomer" xml:space="preserve">
    <value>客人</value>
  </data>
  <data name="global_txtManagement" xml:space="preserve">
    <value>管理層</value>
  </data>
  <data name="global_txtShare" xml:space="preserve">
    <value>股東</value>
  </data>
  <data name="txtIOUReturn" xml:space="preserve">
    <value>贖</value>
  </data>
  <data name="global_msgInfoReturnTypeIsRequired" xml:space="preserve">
    <value>必需選擇歸還類</value>
  </data>
  <data name="typeCashType_CH" xml:space="preserve">
    <value>個人借貸</value>
  </data>
  <data name="typeCashType_IOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="global_MsgAskConfirmDel" xml:space="preserve">
    <value>確定要刪除記錄?</value>
  </data>
  <data name="global_MsgAskConfirmDeleteVoucher" xml:space="preserve">
    <value>確定刪除票據(包括所有明細)？</value>
  </data>
  <data name="global_MsgInfoViodedCannotVoid" xml:space="preserve">
    <value>已刪除的紀錄不能再刪除</value>
  </data>
  <data name="global_msgErrOverSettleAmount" xml:space="preserve">
    <value>還款金額過大</value>
  </data>
  <data name="txtCreditTranURemarkAll" xml:space="preserve">
    <value>停M,公Ｕ</value>
  </data>
  <data name="txtMsgInfoInputMissing" xml:space="preserve">
    <value>仍未輸入所有資料!</value>
  </data>
  <data name="global_msgErrBorrowerRequired" xml:space="preserve">
    <value>必須填上還款人</value>
  </data>
  <data name="txtSettingDesc" xml:space="preserve">
    <value>設定詳述</value>
  </data>
  <data name="txtSettingName" xml:space="preserve">
    <value>設定名稱</value>
  </data>
  <data name="txtSettleItemSetOtherLst" xml:space="preserve">
    <value>月結其他設定記錄</value>
  </data>
  <data name="txtValue" xml:space="preserve">
    <value>數值</value>
  </data>
  <data name="txtDate" xml:space="preserve">
    <value>約見</value>
  </data>
  <data name="txtNoResponse" xml:space="preserve">
    <value>沒有回應</value>
  </data>
  <data name="txtNoSolution" xml:space="preserve">
    <value>沒有方案</value>
  </data>
  <data name="wFailSolution" xml:space="preserve">
    <value>方案不達標</value>
  </data>
  <data name="txtRelateCustomer" xml:space="preserve">
    <value>相關客人</value>
  </data>
  <data name="txtCompAllStatus" xml:space="preserve">
    <value>集團概況</value>
  </data>
  <data name="txtCreditStatus" xml:space="preserve">
    <value>信貸額概況</value>
  </data>
  <data name="txtRemarkContent" xml:space="preserve">
    <value>備注內容</value>
  </data>
  <data name="typeSETTLEITEMLST_Core" xml:space="preserve">
    <value>佣金設定表</value>
  </data>
  <data name="typeSETTLEITEM_Core" xml:space="preserve">
    <value>月結</value>
  </data>
  <data name="txtCommRate" xml:space="preserve">
    <value>佣</value>
  </data>
  <data name="txtDefaulSet" xml:space="preserve">
    <value>預設值</value>
  </data>
  <data name="txtDrinkRate" xml:space="preserve">
    <value>飲</value>
  </data>
  <data name="txtHKD" xml:space="preserve">
    <value>港幣</value>
  </data>
  <data name="txtOtherCodeIn1" xml:space="preserve">
    <value>其他戶口1</value>
  </data>
  <data name="txtSettleCurrCode" xml:space="preserve">
    <value>結算貨幣</value>
  </data>
  <data name="txtSettleRemark" xml:space="preserve">
    <value>佣金備註</value>
  </data>
  <data name="txtUpLvAgent" xml:space="preserve">
    <value>上線代理</value>
  </data>
  <data name="wDrinkToCashRate" xml:space="preserve">
    <value>(股東,代理) 回現金%</value>
  </data>
  <data name="wTopShare" xml:space="preserve">
    <value>大股東</value>
  </data>
  <data name="wTotal" xml:space="preserve">
    <value>合計</value>
  </data>
  <data name="wUpperAgent1" xml:space="preserve">
    <value>上線代理1</value>
  </data>
  <data name="wUpperAgent2" xml:space="preserve">
    <value>上線代理2</value>
  </data>
  <data name="wUpperAgent3" xml:space="preserve">
    <value>上線代理3</value>
  </data>
  <data name="wUpperAgent4" xml:space="preserve">
    <value>上線代理4</value>
  </data>
  <data name="wUpperAgent5" xml:space="preserve">
    <value>上線代理5</value>
  </data>
  <data name="wUpperAgent6" xml:space="preserve">
    <value>上線代理6</value>
  </data>
  <data name="txtHaveRollingOnly" xml:space="preserve">
    <value>本月有轉碼</value>
  </data>
  <data name="txtSettleSetNotConfirm" xml:space="preserve">
    <value>未確認</value>
  </data>
  <data name="wCommRate" xml:space="preserve">
    <value>佣金率</value>
  </data>
  <data name="wComm" xml:space="preserve">
    <value>佣金</value>
  </data>
  <data name="wDrinkRate" xml:space="preserve">
    <value>飲食率</value>
  </data>
  <data name="wDrinkShare" xml:space="preserve">
    <value>共通積分</value>
  </data>
  <data name="wDrinkNonShare" xml:space="preserve">
    <value>永利積分</value>
  </data>
  <data name="wDrinkGrp" xml:space="preserve">
    <value>積分類別</value>
  </data>
  <data name="typeSETTLEITEMSETLST_Core" xml:space="preserve">
    <value>佣金設定表</value>
  </data>
  <data name="global_btnHold" xml:space="preserve">
    <value>待發</value>
  </data>
  <data name="global_btnModify" xml:space="preserve">
    <value>修正</value>
  </data>
  <data name="global_btnResend" xml:space="preserve">
    <value>重發</value>
  </data>
  <data name="global_btnSend" xml:space="preserve">
    <value>發送</value>
  </data>
  <data name="txtExtraNumber" xml:space="preserve">
    <value>短訊號碼</value>
  </data>
  <data name="txtSMSContentUpLv" xml:space="preserve">
    <value>上線內容</value>
  </data>
  <data name="txtSMSRemark" xml:space="preserve">
    <value>訊息備註</value>
  </data>
  <data name="typeSETTLEITEMSETOTHERLST_Core" xml:space="preserve">
    <value>月結其他設定記錄</value>
  </data>
  <data name="txtMsgInfoAgentExisted" xml:space="preserve">
    <value>戶口已存在</value>
  </data>
  <data name="txtMsgInfoCommRateGreatThanDefaultOrNegative" xml:space="preserve">
    <value>''佣金設定'' 大於 ''預設值'' 或 少於零</value>
  </data>
  <data name="txtDisableCurrent" xml:space="preserve">
    <value>本次</value>
  </data>
  <data name="txtDisablePermanent" xml:space="preserve">
    <value>永久</value>
  </data>
  <data name="txtOutstandAmt10K" xml:space="preserve">
    <value>未歸還(萬)</value>
  </data>
  <data name="txtPenaltyAmt" xml:space="preserve">
    <value>罰息金額</value>
  </data>
  <data name="txtPenaltyDate" xml:space="preserve">
    <value>罰息日期</value>
  </data>
  <data name="txtPenaltyInfo" xml:space="preserve">
    <value>罰息資料</value>
  </data>
  <data name="txtPenaltyRtnAmt" xml:space="preserve">
    <value>歸還額</value>
  </data>
  <data name="txtPenaltyRtnInfo" xml:space="preserve">
    <value>罰息歸還</value>
  </data>
  <data name="txtShowRemainPenalty" xml:space="preserve">
    <value>顯示罰息未還</value>
  </data>
  <data name="wDateTime" xml:space="preserve">
    <value>時間</value>
  </data>
  <data name="wPenaltyDay" xml:space="preserve">
    <value>罰息日數</value>
  </data>
  <data name="wRemainPenalty" xml:space="preserve">
    <value>罰息餘額(萬)</value>
  </data>
  <data name="wRtnDate" xml:space="preserve">
    <value>歸還日期</value>
  </data>
  <data name="txtCapitalTranFDtl" xml:space="preserve">
    <value>凍結借貸卡管理</value>
  </data>
  <data name="txtCapitalTranFFDtl" xml:space="preserve">
    <value>凍海外借貸卡管理</value>
  </data>
  <data name="txtCapitalTranFYDtl" xml:space="preserve">
    <value>凍營運借貸卡管理</value>
  </data>
  <data name="txtCapitalTranFLst" xml:space="preserve">
    <value>凍結借貸卡管理</value>
  </data>
  <data name="txtCapitalTranFYLst" xml:space="preserve">
    <value>凍營運借貸卡管理</value>
  </data>
  <data name="txtCapitalTranFFLst" xml:space="preserve">
    <value>凍海外借貸卡管理</value>
  </data>
  <data name="txtCreditTypeStopComm" xml:space="preserve">
    <value>停佣</value>
  </data>
  <data name="txtBookMark" xml:space="preserve">
    <value>關注</value>
  </data>
  <data name="txtLatestFiveRecord" xml:space="preserve">
    <value>Latest 5</value>
  </data>
  <data name="txtReturnIOU" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="txtReturnPenalty" xml:space="preserve">
    <value>還息</value>
  </data>
  <data name="txtPaymentProgress" xml:space="preserve">
    <value>還款進度</value>
  </data>
  <data name="wLabel" xml:space="preserve">
    <value>標籤</value>
  </data>
  <data name="txtFreezeAgent" xml:space="preserve">
    <value>凍M戶口</value>
  </data>
  <data name="typeCAPITALTRAN_F_LST_Core" xml:space="preserve">
    <value>凍結借貸卡管理</value>
  </data>
  <data name="wCIOURolling" xml:space="preserve">
    <value>公司U 配置</value>
  </data>
  <data name="wCompleteMonth" xml:space="preserve">
    <value>完成月份</value>
  </data>
  <data name="wCompleteYear" xml:space="preserve">
    <value>完成年份</value>
  </data>
  <data name="wDiffAmt" xml:space="preserve">
    <value>差額</value>
  </data>
  <data name="wIOURolling" xml:space="preserve">
    <value>IOU配置</value>
  </data>
  <data name="wShareRolling" xml:space="preserve">
    <value>股本配置</value>
  </data>
  <data name="txtDrinkPeriod" xml:space="preserve">
    <value>可累積月</value>
  </data>
  <data name="txtDrinkPeriodDef" xml:space="preserve">
    <value>預設可累積月</value>
  </data>
  <data name="txtIndividualSetting" xml:space="preserve">
    <value>個別設定</value>
  </data>
  <data name="typeSETTLEITEMSETDRINKLST_Core" xml:space="preserve">
    <value>積分期限設定表</value>
  </data>
  <data name="global_btnAddNewPenalty" xml:space="preserve">
    <value>新增罰息</value>
  </data>
  <data name="global_btnAddNewPenaltyRtn" xml:space="preserve">
    <value>新增罰息歸還</value>
  </data>
  <data name="PenaltyTypeF" xml:space="preserve">
    <value>海外</value>
  </data>
  <data name="PenaltyTypeIOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="PenaltyTypeY" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="typeCAPITALTRAN_S_LST_Core" xml:space="preserve">
    <value>股本存款管理</value>
  </data>
  <data name="txtCapitalTranSLst" xml:space="preserve">
    <value>股本存款管理</value>
  </data>
  <data name="txtCapitalTranSDtl" xml:space="preserve">
    <value>股本存款管理</value>
  </data>
  <data name="txtCapitalTranCLst" xml:space="preserve">
    <value>海外股本存款管理</value>
  </data>
  <data name="txtCapitalTranCDtl" xml:space="preserve">
    <value>海外股本存款管理</value>
  </data>
  <data name="txtPenaltyOutstanding" xml:space="preserve">
    <value>尚欠罰息</value>
  </data>
  <data name="typeIOUPENALTYADJLST_F_Core" xml:space="preserve">
    <value>罰息調整管理(海外)</value>
  </data>
  <data name="typeIOUPENALTYADJLST_IOU_Core" xml:space="preserve">
    <value>罰息調整管理</value>
  </data>
  <data name="typeIOUPENALTYADJLST_Y_Core" xml:space="preserve">
    <value>罰息調整管理(營運)</value>
  </data>
  <data name="txtCapitalTranYLst" xml:space="preserve">
    <value>食貨存款管理</value>
  </data>
  <data name="txtCapitalTranYDtl" xml:space="preserve">
    <value>食貨存款管理</value>
  </data>
  <data name="txtCapitalTranOLst" xml:space="preserve">
    <value>營運存款管理</value>
  </data>
  <data name="txtCapitalTranODtl" xml:space="preserve">
    <value>營運存款管理</value>
  </data>
  <data name="typeCAPITALTRAN_C_LST_Core" xml:space="preserve">
    <value>海外股本存款管理</value>
  </data>
  <data name="typeCAPITALTRAN_Y_LST_Core" xml:space="preserve">
    <value>食貨存款管理</value>
  </data>
  <data name="typeCAPITALTRAN_O_LST_Core" xml:space="preserve">
    <value>營運存款管理</value>
  </data>
  <data name="IOUBonusStatusA" xml:space="preserve">
    <value>未處理</value>
  </data>
  <data name="IOUBonusStatusC" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="IOUBonusStatusH" xml:space="preserve">
    <value>待付款</value>
  </data>
  <data name="IOUBonusStatusI" xml:space="preserve">
    <value>完成轉C</value>
  </data>
  <data name="IOUBonusStatusP" xml:space="preserve">
    <value>待處理</value>
  </data>
  <data name="typeIOUBONUSLST_Core" xml:space="preserve">
    <value>月結貸款配置管理</value>
  </data>
  <data name="wChipTranICnt" xml:space="preserve">
    <value>存單數目</value>
  </data>
  <data name="wCompleteDatetime" xml:space="preserve">
    <value>完成日期</value>
  </data>
  <data name="wCompleteYearMth" xml:space="preserve">
    <value>完成週期</value>
  </data>
  <data name="wConditionType30Day" xml:space="preserve">
    <value>30天期</value>
  </data>
  <data name="wConditionTypeNormal" xml:space="preserve">
    <value>普通條件</value>
  </data>
  <data name="wHoldAgentCName" xml:space="preserve">
    <value>承擔人名稱</value>
  </data>
  <data name="wHoldAgentCode" xml:space="preserve">
    <value>承擔戶號</value>
  </data>
  <data name="wIOUBonusAmt" xml:space="preserve">
    <value>奬金(萬)</value>
  </data>
  <data name="wIOUBonusAmtImmediate" xml:space="preserve">
    <value>轉Ｃ奬金(萬)</value>
  </data>
  <data name="wIOURefNos" xml:space="preserve">
    <value>相關貸款號碼</value>
  </data>
  <data name="wOutDateTime" xml:space="preserve">
    <value>離場時間</value>
  </data>
  <data name="wRollingWithoutCash" xml:space="preserve">
    <value>非現金轉碼(萬)</value>
  </data>
  <data name="wCashChipTenk" xml:space="preserve">
    <value>現碼（萬）</value>
  </data>
  <data name="wChipTranDtl" xml:space="preserve">
    <value>存單記錄</value>
  </data>
  <data name="wNumNormalMDay" xml:space="preserve">
    <value>顯示天數</value>
  </data>
  <data name="txtCreateDate" xml:space="preserve">
    <value>開單日期</value>
  </data>
  <data name="txtDisableCurrent_L" xml:space="preserve">
    <value>本次不收</value>
  </data>
  <data name="txtDisablePermanent_L" xml:space="preserve">
    <value>永久不收</value>
  </data>
  <data name="txtIOUInfo" xml:space="preserve">
    <value>IOU資料</value>
  </data>
  <data name="txtIOUPenaltyDailyDtl" xml:space="preserve">
    <value>罰息每日明細</value>
  </data>
  <data name="txtOutAmt" xml:space="preserve">
    <value>借款額</value>
  </data>
  <data name="txtOutstandAmt_S" xml:space="preserve">
    <value>未歸還</value>
  </data>
  <data name="txtRtnAmt_S" xml:space="preserve">
    <value>歸還</value>
  </data>
  <data name="txtSettlementDate" xml:space="preserve">
    <value>結算日期</value>
  </data>
  <data name="wRemainIOU" xml:space="preserve">
    <value>IOU餘額</value>
  </data>
  <data name="txtPenaltyRtnAmtHKD" xml:space="preserve">
    <value>HKD 歸還額</value>
  </data>
  <data name="typeRCREDITCONTROL_STATUS_LIST_RPT_Report" xml:space="preserve">
    <value>授信戶口信貸概況報表</value>
  </data>
  <data name="txtDownLineCreditDay" xml:space="preserve">
    <value>下線天數</value>
  </data>
  <data name="txtDownLinePenaltyRate" xml:space="preserve">
    <value>下線息率(分)</value>
  </data>
  <data name="txtDown_Indv_CreditDay" xml:space="preserve">
    <value>下線/個別天數</value>
  </data>
  <data name="txtDown_Indv_PenaltyRate" xml:space="preserve">
    <value>下線/個別息率(分)</value>
  </data>
  <data name="txtIndividualAgent" xml:space="preserve">
    <value>個別戶口</value>
  </data>
  <data name="txtIndividualAgentSetting" xml:space="preserve">
    <value>個別戶口設定</value>
  </data>
  <data name="txtShareCreditDay" xml:space="preserve">
    <value>股東天數</value>
  </data>
  <data name="txtSharePenaltyRate" xml:space="preserve">
    <value>股東息率(分)</value>
  </data>
  <data name="txtUpdIOU_Day_Rate" xml:space="preserve">
    <value>應用借貸天數及息率</value>
  </data>
  <data name="typeIOUPENALTYSETLST_Core" xml:space="preserve">
    <value>罰息設定管理</value>
  </data>
  <data name="txtIndividualCreditDay" xml:space="preserve">
    <value>個別天數</value>
  </data>
  <data name="txtIndividualPenaltyRate" xml:space="preserve">
    <value>個別息率(分)</value>
  </data>
  <data name="txtUpdateInfo" xml:space="preserve">
    <value>更改資料</value>
  </data>
  <data name="txtUpdateScope" xml:space="preserve">
    <value>更改範圍</value>
  </data>
  <data name="global_msgInfoNotFound" xml:space="preserve">
    <value>不存在</value>
  </data>
  <data name="typeCAPITALTRAN_FF_LST_Core" xml:space="preserve">
    <value>凍海外借貸卡管理</value>
  </data>
  <data name="typeCAPITALTRAN_FY_LST_Core" xml:space="preserve">
    <value>凍營運借貸卡管理</value>
  </data>
  <data name="typeCAPITALTRAN_FF_DTL_Core" xml:space="preserve">
    <value>凍海外借貸卡</value>
  </data>
  <data name="typeCAPITALTRAN_FY_DTL_Core" xml:space="preserve">
    <value>凍營運借貸卡</value>
  </data>
  <data name="typeCAPITALTRANWITHDRAW_Core" xml:space="preserve">
    <value>提款</value>
  </data>
  <data name="txtExpCreditAmt" xml:space="preserve">
    <value>消費信用額</value>
  </data>
  <data name="wOverOutstanding_10K" xml:space="preserve">
    <value>剩餘信貸額(萬)</value>
  </data>
  <data name="wExpireOutstanding_10K" xml:space="preserve">
    <value>過期(萬)</value>
  </data>
  <data name="wSettleStatusOutstanding_10K" xml:space="preserve">
    <value>未結算(萬)</value>
  </data>
  <data name="wIOUStore_10K" xml:space="preserve">
    <value>暫存/未取(萬)</value>
  </data>
  <data name="btnCreditUplvOpen" xml:space="preserve">
    <value>開啓上線</value>
  </data>
  <data name="btnCreditUplvClose" xml:space="preserve">
    <value>關閉上線</value>
  </data>
  <data name="txtCreditSummaryDetail" xml:space="preserve">
    <value>詳細信貸額概況</value>
  </data>
  <data name="global_btnAddNewBFDrink" xml:space="preserve">
    <value>新增積分</value>
  </data>
  <data name="global_btnAddNewBFDrinkRtn" xml:space="preserve">
    <value>新增積分扣減</value>
  </data>
  <data name="txtBFDrinkRtnAmt" xml:space="preserve">
    <value>積分使用</value>
  </data>
  <data name="txtDeductInfo" xml:space="preserve">
    <value>扣減資料</value>
  </data>
  <data name="txtIndivdualSettle" xml:space="preserve">
    <value>個別處理</value>
  </data>
  <data name="typeDRINKBFLST_Core" xml:space="preserve">
    <value>積分累數管理</value>
  </data>
  <data name="typeDRINKBFDTL_Core" xml:space="preserve">
    <value>積分累數記錄</value>
  </data>
  <data name="wBFDrinkAmount" xml:space="preserve">
    <value>積分累數</value>
  </data>
  <data name="wBFDrinkRtnAmount" xml:space="preserve">
    <value>積分累數扣減</value>
  </data>
  <data name="global_txtIOU" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="typeCAPITALTRAN_F_DTL_Core" xml:space="preserve">
    <value>凍結借貸卡</value>
  </data>
  <data name="typeCAPITALTRAN_S_DTL_Core" xml:space="preserve">
    <value>股本存款</value>
  </data>
  <data name="typeCAPITALTRAN_C_DTL_Core" xml:space="preserve">
    <value>海外股本存款</value>
  </data>
  <data name="typeCAPITALTRAN_Y_DTL_Core" xml:space="preserve">
    <value>食貨存款</value>
  </data>
  <data name="typeCAPITALTRAN_O_DTL_Core" xml:space="preserve">
    <value>營運存款</value>
  </data>
  <data name="typeCAPITALTRAN_H_DTL_Core" xml:space="preserve">
    <value>凍結存款單</value>
  </data>
  <data name="typeCAPITALTRAN_M_DTL_Core" xml:space="preserve">
    <value>月息單</value>
  </data>
  <data name="txtShowOutstandAmt" xml:space="preserve">
    <value>未使用</value>
  </data>
  <data name="txtShowUsed" xml:space="preserve">
    <value>已使用</value>
  </data>
  <data name="txtSPECIALMARKERLST_FRecord" xml:space="preserve">
    <value>海外貸款記錄</value>
  </data>
  <data name="txtSPECIALMARKERLST_YRecord" xml:space="preserve">
    <value>營運貸款記錄</value>
  </data>
  <data name="global_msgMAmountNotMatchDetail" xml:space="preserve">
    <value>罰息金額與明細不符</value>
  </data>
  <data name="global_msgDelSuccess" xml:space="preserve">
    <value>刪除成功</value>
  </data>
  <data name="global_msgInfoNotAllowToDel" xml:space="preserve">
    <value>不能刪除記錄</value>
  </data>
  <data name="global_msgInfoSettleExisted" xml:space="preserve">
    <value>扣減記錄存在</value>
  </data>
  <data name="btnSearchSMSSeqNo" xml:space="preserve">
    <value>搜尋惟一碼</value>
  </data>
  <data name="txtAccountType" xml:space="preserve">
    <value>戶口級別升降</value>
  </data>
  <data name="txtAgentUpd" xml:space="preserve">
    <value>戶口修改</value>
  </data>
  <data name="txtBecomeHolderSMS" xml:space="preserve">
    <value>成為股東</value>
  </data>
  <data name="txtBfExpTranExpire" xml:space="preserve">
    <value>欠前消費到期</value>
  </data>
  <data name="txtBonusGiftSMS" xml:space="preserve">
    <value>贈送禮物</value>
  </data>
  <data name="txtCapitalTranC" xml:space="preserve">
    <value>海外股本</value>
  </data>
  <data name="txtCapitalTranO" xml:space="preserve">
    <value>營運卡</value>
  </data>
  <data name="txtExpDailyRpt" xml:space="preserve">
    <value>每日集團消費報表</value>
  </data>
  <data name="txtInstantCancelSMS" xml:space="preserve">
    <value>取消即出訊息</value>
  </data>
  <data name="txtInstantSMS" xml:space="preserve">
    <value>即出訊息</value>
  </data>
  <data name="txtIOURtn" xml:space="preserve">
    <value>貸款歸還</value>
  </data>
  <data name="txtLangBig5" xml:space="preserve">
    <value>繁體中文</value>
  </data>
  <data name="txtLangCHN" xml:space="preserve">
    <value>簡體中文</value>
  </data>
  <data name="txtLangEn" xml:space="preserve">
    <value>英文</value>
  </data>
  <data name="txtLangJPN" xml:space="preserve">
    <value>日文</value>
  </data>
  <data name="txtLangKOR" xml:space="preserve">
    <value>韓文</value>
  </data>
  <data name="txtLangTH" xml:space="preserve">
    <value>泰文</value>
  </data>
  <data name="txtMonthEndSettleCanelSMS" xml:space="preserve">
    <value>取消出佣訊息</value>
  </data>
  <data name="txtMonthEndSettleSMS" xml:space="preserve">
    <value>出佣訊息</value>
  </data>
  <data name="txtMonthlyInt" xml:space="preserve">
    <value>回贈</value>
  </data>
  <data name="txtOpenSMS" xml:space="preserve">
    <value>開場訊息</value>
  </data>
  <data name="txtOutSMS" xml:space="preserve">
    <value>離場訊息</value>
  </data>
  <data name="txtRollingDailyRpt" xml:space="preserve">
    <value>每日集團轉碼報表</value>
  </data>
  <data name="txtRollingDailySettle" xml:space="preserve">
    <value>轉碼日結</value>
  </data>
  <data name="txtRollingDailySettleShare" xml:space="preserve">
    <value>轉碼日結(股東組)</value>
  </data>
  <data name="txtRollWinLoss" xml:space="preserve">
    <value>轉碼及上下數</value>
  </data>
  <data name="txtSendFrom" xml:space="preserve">
    <value>發送自</value>
  </data>
  <data name="txtSMSBounsPointsExpire" xml:space="preserve">
    <value>積分到期通知</value>
  </data>
  <data name="txtSMSLang" xml:space="preserve">
    <value>訊息語言</value>
  </data>
  <data name="txtSMSManual" xml:space="preserve">
    <value>手動SMS</value>
  </data>
  <data name="txtSMSStatus_A1" xml:space="preserve">
    <value>已推送</value>
  </data>
  <data name="txtSMSStatus_C1" xml:space="preserve">
    <value>成功</value>
  </data>
  <data name="txtSMSStatus_F" xml:space="preserve">
    <value>失敗</value>
  </data>
  <data name="txtSMSStatus_O" xml:space="preserve">
    <value>排隊發送</value>
  </data>
  <data name="txtSMSStatus_T" xml:space="preserve">
    <value>發送系統故障</value>
  </data>
  <data name="txtStore" xml:space="preserve">
    <value>內部</value>
  </data>
  <data name="txtSubAgentInfo" xml:space="preserve">
    <value>下線資料</value>
  </data>
  <data name="txtUpdMuli" xml:space="preserve">
    <value>批額修改</value>
  </data>
  <data name="typeSMSENQUIRY_Core" xml:space="preserve">
    <value>SMS查詢</value>
  </data>
  <data name="wSMSSeqNo" xml:space="preserve">
    <value>訊息惟一碼</value>
  </data>
  <data name="txtBFDrinkHKDRtnAmt" xml:space="preserve">
    <value>HKD積分使用</value>
  </data>
  <data name="txtClientUpdated" xml:space="preserve">
    <value>有新的版本, 將會更新!</value>
  </data>
  <data name="typeSHIFTAUTHLST_Core" xml:space="preserve">
    <value>授權人管理</value>
  </data>
  <data name="typeSHIFTAUTHDTL_Core" xml:space="preserve">
    <value>授權人記錄</value>
  </data>
  <data name="wDeduct_10K" xml:space="preserve">
    <value>扣取(萬)</value>
  </data>
  <data name="wRealOutStanding_10K" xml:space="preserve">
    <value>扣後尚欠(萬)</value>
  </data>
  <data name="rIOUTranByCageReport" xml:space="preserve">
    <value>貸款報表</value>
  </data>
  <data name="wCashChipHKD" xml:space="preserve">
    <value>HKD現碼</value>
  </data>
  <data name="typeROLLINGMONTHLYADJUSTLST_Core" xml:space="preserve">
    <value>轉碼月轉換</value>
  </data>
  <data name="global_btnUndo" xml:space="preserve">
    <value>還原</value>
  </data>
  <data name="wZCapitalAmt" xml:space="preserve">
    <value>Z卡股本(萬)</value>
  </data>
  <data name="wZCashAmt" xml:space="preserve">
    <value>Z卡現金(萬)</value>
  </data>
  <data name="wZCIOUAmt" xml:space="preserve">
    <value>Z卡公司U(萬)</value>
  </data>
  <data name="wZIOUAmt" xml:space="preserve">
    <value>Z卡IOU(萬)</value>
  </data>
  <data name="txtOneTimeBuyChip" xml:space="preserve">
    <value>一次性買碼</value>
  </data>
  <data name="txtResetPwd" xml:space="preserve">
    <value>重設密碼</value>
  </data>
  <data name="txtResendPwd" xml:space="preserve">
    <value>重發密碼</value>
  </data>
  <data name="txtSMSBpPlayAddCapital" xml:space="preserve">
    <value>B數加彩</value>
  </data>
  <data name="wCapitalAmtHKD" xml:space="preserve">
    <value>股本總值(萬)(港幣)</value>
  </data>
  <data name="wCreditAmtHKD" xml:space="preserve">
    <value>信貸額總值(萬)(港幣)</value>
  </data>
  <data name="txtiouAgentCode" xml:space="preserve">
    <value>IOU戶口</value>
  </data>
  <data name="txtiouAgentName" xml:space="preserve">
    <value>IOU名稱</value>
  </data>
  <data name="wFreezeAmt" xml:space="preserve">
    <value>凍結(萬)</value>
  </data>
  <data name="txtSMSBpPlayClose" xml:space="preserve">
    <value>B數離場</value>
  </data>
  <data name="txtSMSBpPlayCloseCont" xml:space="preserve">
    <value>B數離場(續場)</value>
  </data>
  <data name="txtSMSBpPlayOpen" xml:space="preserve">
    <value>B數開場</value>
  </data>
  <data name="txtSMSBpPlayOpenCont" xml:space="preserve">
    <value>B數開場(續場)</value>
  </data>
  <data name="txtSMSBpPlaySettleCu" xml:space="preserve">
    <value>客人B數結算</value>
  </data>
  <data name="txtSMSFbPlayAddCapital" xml:space="preserve">
    <value>海外佔成加彩</value>
  </data>
  <data name="txtSMSFbPlayClose" xml:space="preserve">
    <value>海外佔成離場</value>
  </data>
  <data name="txtSMSFbPlayCloseCont" xml:space="preserve">
    <value>海外佔成離場(續場)</value>
  </data>
  <data name="txtSMSFbPlayOpen" xml:space="preserve">
    <value>海外佔成開場</value>
  </data>
  <data name="txtSMSFbPlayOpenCont" xml:space="preserve">
    <value>海外佔成開場(續場)</value>
  </data>
  <data name="txtSMSFbPlaySettleCu" xml:space="preserve">
    <value>客人海外佔成結算</value>
  </data>
  <data name="txtSMSForeignAddCapital" xml:space="preserve">
    <value>海外加彩</value>
  </data>
  <data name="txtSMSForeignClose" xml:space="preserve">
    <value>海外離場</value>
  </data>
  <data name="txtSMSForeignCloseCont" xml:space="preserve">
    <value>海外離場(續場)</value>
  </data>
  <data name="txtSMSForeignOpen" xml:space="preserve">
    <value>海外開場</value>
  </data>
  <data name="txtSMSForeignOpenCont" xml:space="preserve">
    <value>海外開場(續場)</value>
  </data>
  <data name="txtSMSForeignSettleCu" xml:space="preserve">
    <value>客人海外結算</value>
  </data>
  <data name="txtSMSOperateAddCapital" xml:space="preserve">
    <value>營運加彩</value>
  </data>
  <data name="txtSMSOperateClose" xml:space="preserve">
    <value>營運離場</value>
  </data>
  <data name="txtSMSOperateCloseCont" xml:space="preserve">
    <value>營運離場(續場)</value>
  </data>
  <data name="txtSMSOperateOpen" xml:space="preserve">
    <value>營運開場</value>
  </data>
  <data name="txtSMSOperateOpenCont" xml:space="preserve">
    <value>營運開場(續場)</value>
  </data>
  <data name="txtSMSOperateSettleCu" xml:space="preserve">
    <value>客人營運結算</value>
  </data>
  <data name="txtSMSTelBAgentLoginPwd" xml:space="preserve">
    <value>代理登入密碼</value>
  </data>
  <data name="typeBPLAYSMSENQUIRY_Core" xml:space="preserve">
    <value>SMS查詢(B數)</value>
  </data>
  <data name="typeTELEBET_ROOT_Core" xml:space="preserve">
    <value>電投</value>
  </data>
  <data name="typeBPLAY_Core" xml:space="preserve">
    <value>B數</value>
  </data>
  <data name="typeFOREIGNSMSENQUIRY_Core" xml:space="preserve">
    <value>SMS查詢(海外)</value>
  </data>
  <data name="typeFOREIGN_Core" xml:space="preserve">
    <value>海外</value>
  </data>
  <data name="typeOPERATESMSENQUIRY_Core" xml:space="preserve">
    <value>SMS查詢(營運)</value>
  </data>
  <data name="typeTELBSMSENQUIRY_Core" xml:space="preserve">
    <value>SMS查詢(電投)</value>
  </data>
  <data name="wMontly" xml:space="preserve">
    <value>月份</value>
  </data>
  <data name="txtOnlyAllowShowBelowLevel2" xml:space="preserve">
    <value>只能顯示第3層或以下</value>
  </data>
  <data name="global_btnNewMthInterest" xml:space="preserve">
    <value>新增月息</value>
  </data>
  <data name="typePLACE_ROOT_Core" xml:space="preserve">
    <value>場面</value>
  </data>
  <data name="whole" xml:space="preserve">
    <value>整</value>
  </data>
  <data name="txtLatestTwoRecord" xml:space="preserve">
    <value>Latest 2</value>
  </data>
  <data name="txtLatestOneRecord" xml:space="preserve">
    <value>Latest 1</value>
  </data>
  <data name="wCashChip_ToNew" xml:space="preserve">
    <value>結存</value>
  </data>
  <data name="global_txtAlready" xml:space="preserve">
    <value>已</value>
  </data>
  <data name="global_txtInvalid" xml:space="preserve">
    <value>不正確</value>
  </data>
  <data name="global_txtSend" xml:space="preserve">
    <value>發出</value>
  </data>
  <data name="global_txtSMS" xml:space="preserve">
    <value>手機短訊</value>
  </data>
  <data name="global_MsgErrAmountDifferent" xml:space="preserve">
    <value>金額不同</value>
  </data>
  <data name="global_MsgNotAllowToUseThisFunction" xml:space="preserve">
    <value>此場不能用有關功能</value>
  </data>
  <data name="global_msgInfoPlsEdit" xml:space="preserve">
    <value>請先編輯要刪除的項</value>
  </data>
  <data name="global_msgErrAgentCodeExists" xml:space="preserve">
    <value>戶口編號已存在</value>
  </data>
  <data name="txtTotalRolling10K" xml:space="preserve">
    <value>總轉碼(萬)</value>
  </data>
  <data name="typeROLLINGENQUIRY_Core" xml:space="preserve">
    <value>轉碼查詢</value>
  </data>
  <data name="txtAgentLevel" xml:space="preserve">
    <value>等級</value>
  </data>
  <data name="txtCreditAmt" xml:space="preserve">
    <value>信用額</value>
  </data>
  <data name="txtLastMonthRolling" xml:space="preserve">
    <value>上月轉碼(萬)(連下線)</value>
  </data>
  <data name="txtthisMonthRolling" xml:space="preserve">
    <value>本月轉碼(萬)(連下線)</value>
  </data>
  <data name="txtthisMonthTotalRollingAmt" xml:space="preserve">
    <value>當月累計轉碼(萬)(連下線)</value>
  </data>
  <data name="txtWk" xml:space="preserve">
    <value>本週(萬)(連下線)</value>
  </data>
  <data name="txtWk1" xml:space="preserve">
    <value>本週-1(萬)(連下線)</value>
  </data>
  <data name="txtWk2" xml:space="preserve">
    <value>本週-2(萬)(連下線)</value>
  </data>
  <data name="txtWk3" xml:space="preserve">
    <value>本週-3(萬)(連下線)</value>
  </data>
  <data name="typePOTEROLLINGAGENENQUIRY_Core" xml:space="preserve">
    <value>潛質會員查詢</value>
  </data>
  <data name="wAgentName" xml:space="preserve">
    <value>戶口姓名</value>
  </data>
  <data name="txtCreditOver1MRollingUnder10MLst" xml:space="preserve">
    <value>批額超過1千萬轉碼不過億名單</value>
  </data>
  <data name="txtNoCreditThisMonthRollingOver10MLst" xml:space="preserve">
    <value>無批額本月轉碼過億名單</value>
  </data>
  <data name="txtNoCreditThisWeekRollingOver10MLst" xml:space="preserve">
    <value>無批額本週轉碼過億名單</value>
  </data>
  <data name="txtRollingUnder10MLst" xml:space="preserve">
    <value>上月轉碼過億今月不過名單</value>
  </data>
  <data name="global_MsgInfoDateMissing" xml:space="preserve">
    <value>請輸入日期</value>
  </data>
  <data name="txtInvalidYearMth" xml:space="preserve">
    <value>不是有效週期</value>
  </data>
  <data name="global_btnSavePos" xml:space="preserve">
    <value>保存坐標</value>
  </data>
  <data name="glabal_msgInvalidTourNoOrCustomerInfo" xml:space="preserve">
    <value>Invalid Tour No or Customer Info</value>
  </data>
  <data name="txtMaxLevelHit" xml:space="preserve">
    <value>已到最大的層數, 不能新增</value>
  </data>
  <data name="txtMsgInfoNoCombineMessage" xml:space="preserve">
    <value>不能發送，缺少贖回Marker的部份訊息。</value>
  </data>
  <data name="txtSendSMSFail" xml:space="preserve">
    <value>發送失敗</value>
  </data>
  <data name="txtSendSMSSuccess" xml:space="preserve">
    <value>發送成功</value>
  </data>
  <data name="txtSMSPressReply" xml:space="preserve">
    <value>如有任何查詢，請致電聯絡我們。</value>
  </data>
  <data name="txtSMSPressReplyHotline" xml:space="preserve">
    <value>如有任何查詢，請致電&lt;wTel&gt;聯絡我們。</value>
  </data>
  <data name="global_txtCompanySet" xml:space="preserve">
    <value>公司預設</value>
  </data>
  <data name="global_txtIndividualAgentSet" xml:space="preserve">
    <value>個別戶口線設定(月結即出)</value>
  </data>
  <data name="global_txtIndividualCageSet" xml:space="preserve">
    <value>個別廳設定</value>
  </data>
  <data name="typeSETTLEINSTANTSETLST_Core" xml:space="preserve">
    <value>即出佣金設定</value>
  </data>
  <data name="global_btnReprint" xml:space="preserve">
    <value>重印</value>
  </data>
  <data name="global_PopUpSettleLocationPeriod" xml:space="preserve">
    <value>出糧批核週期</value>
  </data>
  <data name="global_txtAllCommission" xml:space="preserve">
    <value>佣金總額(萬)</value>
  </data>
  <data name="global_txtIsIncludeFoodDrinkBF" xml:space="preserve">
    <value>積分表</value>
  </data>
  <data name="global_txtIsIncludeMthEndExpense" xml:space="preserve">
    <value>月結消費單</value>
  </data>
  <data name="global_txtIsIncludeSummaryDownDtl" xml:space="preserve">
    <value>下線佣金收益表</value>
  </data>
  <data name="global_txtMonthEndRptUseOldFormat" xml:space="preserve">
    <value>月結單使用舊格式</value>
  </data>
  <data name="global_txtOutstandingCommission" xml:space="preserve">
    <value>未出佣金(萬)</value>
  </data>
  <data name="global_txtPaidByLocal" xml:space="preserve">
    <value>[本地出]</value>
  </data>
  <data name="global_txtPaidByMacau" xml:space="preserve">
    <value>[澳門出]</value>
  </data>
  <data name="global_txtSalarySummaryInclude" xml:space="preserve">
    <value>糧單包括</value>
  </data>
  <data name="global_txtSettledCommission" xml:space="preserve">
    <value>已出佣金(萬)</value>
  </data>
  <data name="typeSETTLETRANLST_Core" xml:space="preserve">
    <value>出糧管理</value>
  </data>
  <data name="global_btnCentralAuth" xml:space="preserve">
    <value>中央信貸部</value>
  </data>
  <data name="wCommissionCutoff10k" xml:space="preserve">
    <value>實出佣(萬)</value>
  </data>
  <data name="wCommissionCutoffHKD10k" xml:space="preserve">
    <value>實出佣HKD(萬)</value>
  </data>
  <data name="txtShowBFExp" xml:space="preserve">
    <value>欠费</value>
  </data>
  <data name="txtShowHaveComm" xml:space="preserve">
    <value>有佣金</value>
  </data>
  <data name="txtShowZeroComm" xml:space="preserve">
    <value>零佣金</value>
  </data>
  <data name="wCentralUpdByCName" xml:space="preserve">
    <value>中央信貸部經手人</value>
  </data>
  <data name="wExpOutstandingHKD" xml:space="preserve">
    <value>尚欠費用HKD</value>
  </data>
  <data name="wIOUOutstandingHKD" xml:space="preserve">
    <value>倘欠貸款HKD(萬)</value>
  </data>
  <data name="wIVRAuthByCName" xml:space="preserve">
    <value>IVR授權人</value>
  </data>
  <data name="wIVRAuthDt" xml:space="preserve">
    <value>IVR授權時間</value>
  </data>
  <data name="wPaidByCName" xml:space="preserve">
    <value>出糧經手人</value>
  </data>
  <data name="wPaidCompCName" xml:space="preserve">
    <value>出糧地點</value>
  </data>
  <data name="wPaidDt" xml:space="preserve">
    <value>出糧時間</value>
  </data>
  <data name="btnLeaveRemarkDeposit" xml:space="preserve">
    <value>存</value>
  </data>
  <data name="btnLeaveRemarkReturn" xml:space="preserve">
    <value>贖</value>
  </data>
  <data name="btnLeaveRemarkTake" xml:space="preserve">
    <value>袋</value>
  </data>
  <data name="global_txtOrder" xml:space="preserve">
    <value>排序</value>
  </data>
  <data name="txtCapitalRemark" xml:space="preserve">
    <value>本金備註</value>
  </data>
  <data name="txtCapitalRemarkType_Work" xml:space="preserve">
    <value>工作碼</value>
  </data>
  <data name="txtCapitalRemarkType_WorkCash" xml:space="preserve">
    <value>工作碼(卡C)</value>
  </data>
  <data name="txtCapitalRemarkType_WorkM" xml:space="preserve">
    <value>工作碼(M)</value>
  </data>
  <data name="txtCapitalRemark_CardC" xml:space="preserve">
    <value>卡C</value>
  </data>
  <data name="txtCapitalRemark_Cash" xml:space="preserve">
    <value>現</value>
  </data>
  <data name="txtCapitalRemark_Chip" xml:space="preserve">
    <value>泥</value>
  </data>
  <data name="txtCapitalRemark_CMM" xml:space="preserve">
    <value>公司MM</value>
  </data>
  <data name="txtCapitalRemark_CreditCard" xml:space="preserve">
    <value>碌卡</value>
  </data>
  <data name="txtCapitalRemark_StoreM" xml:space="preserve">
    <value>存M</value>
  </data>
  <data name="txtCapitalType" xml:space="preserve">
    <value>本金種類</value>
  </data>
  <data name="txtLeaveAction" xml:space="preserve">
    <value>離場動作</value>
  </data>
  <data name="txtLeaveRemarkAction_K" xml:space="preserve">
    <value>取現</value>
  </data>
  <data name="txtLeaveRemarkType_Tip" xml:space="preserve">
    <value>小費</value>
  </data>
  <data name="txtLeaveRemarkType_W" xml:space="preserve">
    <value>舊M</value>
  </data>
  <data name="txtLeaveType" xml:space="preserve">
    <value>離場類型</value>
  </data>
  <data name="txtPlaceShiftDate" xml:space="preserve">
    <value>截更日期</value>
  </data>
  <data name="txtRollingAmtByAgent" xml:space="preserve">
    <value>轉碼概況</value>
  </data>
  <data name="txtRollingTotalByCurrency" xml:space="preserve">
    <value>轉碼總值(萬)</value>
  </data>
  <data name="txtRollingTotal_HKD" xml:space="preserve">
    <value>轉碼總值(萬)(港幣)</value>
  </data>
  <data name="typeIOU_IOENQUIRY_Core" xml:space="preserve">
    <value>借貸出入數查詢</value>
  </data>
  <data name="txtInAmt" xml:space="preserve">
    <value>還款額</value>
  </data>
  <data name="wRtnRefNo" xml:space="preserve">
    <value>歸還(單號)</value>
  </data>
  <data name="txtPopupSMSPreview" xml:space="preserve">
    <value>發送短訊預覽</value>
  </data>
  <data name="txtIndividualAgentSet" xml:space="preserve">
    <value>個別戶口線設定</value>
  </data>
  <data name="typeMonthEndAdjust_Core" xml:space="preserve">
    <value>月結前調整</value>
  </data>
  <data name="wCommissionDisplayType" xml:space="preserve">
    <value>碼類,貨幣,投注類</value>
  </data>
  <data name="global_msgInfoNoChange" xml:space="preserve">
    <value>資料沒有更改</value>
  </data>
  <data name="global_txtData" xml:space="preserve">
    <value>資料</value>
  </data>
  <data name="global_MsgInfoTelbProcessing" xml:space="preserve">
    <value>準備中</value>
  </data>
  <data name="txtCheckIn" xml:space="preserve">
    <value>入場</value>
  </data>
  <data name="txtCustChipTranTypeTB" xml:space="preserve">
    <value>電投客人存卡</value>
  </data>
  <data name="typeCUSTOMERTELBLST_Core" xml:space="preserve">
    <value>電投客人管理</value>
  </data>
  <data name="wTelbCreditType" xml:space="preserve">
    <value>批額類型</value>
  </data>
  <data name="wTelbLoginID" xml:space="preserve">
    <value>電投登入戶口</value>
  </data>
  <data name="wTelbSMS" xml:space="preserve">
    <value>訊息號碼</value>
  </data>
  <data name="wTelebetPhoneNumber" xml:space="preserve">
    <value>電投號碼</value>
  </data>
  <data name="wTelebetDateTime" xml:space="preserve">
    <value>電投時間</value>
  </data>
  <data name="wTelbCreditAvaliable" xml:space="preserve">
    <value>餘額(萬)</value>
  </data>
  <data name="wTelbExpirDate" xml:space="preserve">
    <value>到期日期</value>
  </data>
  <data name="btnReadCardActCode" xml:space="preserve">
    <value>讀取卡行動碼</value>
  </data>
  <data name="wSaltStaffCard" xml:space="preserve">
    <value>RollexCardCode</value>
  </data>
  <data name="typeBPLAY_ROOT_Core" xml:space="preserve">
    <value>B數</value>
  </data>
  <data name="typeBPLAY_LST_Core" xml:space="preserve">
    <value>B數管理</value>
  </data>
  <data name="global_BPLAY_DTL" xml:space="preserve">
    <value>B數記錄</value>
  </data>
  <data name="global_msgInfoYearMthOrAgentRequired" xml:space="preserve">
    <value>必須填上週期或者用戶其中一欄</value>
  </data>
  <data name="global_msgInfoYearMthWrong" xml:space="preserve">
    <value>月份輸入不正確, 請輸入如: 201301, 201302</value>
  </data>
  <data name="global_msgInfoCommissionCardNotExists" xml:space="preserve">
    <value>本月佣金卡不存在, 如2013年1月份佣金卡號碼該為 "13-01"</value>
  </data>
  <data name="typeBPLAY_SETTING_Core" xml:space="preserve">
    <value>B數佣金設定</value>
  </data>
  <data name="txtBPLAYSET_Remark" xml:space="preserve">
    <value>**佣金率 : 代理最後收取 | 海外佣金率 : 海外廳於佣金率當中所佔部份，結算時用作扣除</value>
  </data>
  <data name="txtPointsRate" xml:space="preserve">
    <value>積分率</value>
  </data>
  <data name="txtForeignCommRate" xml:space="preserve">
    <value>海外佣金率</value>
  </data>
  <data name="msgCardDateInvalid" xml:space="preserve">
    <value>資料不正確</value>
  </data>
  <data name="txtCage" xml:space="preserve">
    <value>貴賓廳</value>
  </data>
  <data name="btnReject" xml:space="preserve">
    <value>不批準</value>
  </data>
  <data name="btnCancelAppointment" xml:space="preserve">
    <value>取消預約</value>
  </data>
  <data name="txtCancel" xml:space="preserve">
    <value>取消</value>
  </data>
  <data name="txtFriday" xml:space="preserve">
    <value>週五</value>
  </data>
  <data name="txtMonday" xml:space="preserve">
    <value>週一</value>
  </data>
  <data name="txtSaturday" xml:space="preserve">
    <value>週六</value>
  </data>
  <data name="txtSunday" xml:space="preserve">
    <value>週日</value>
  </data>
  <data name="txtThursday" xml:space="preserve">
    <value>週四</value>
  </data>
  <data name="txtTuesday" xml:space="preserve">
    <value>週二</value>
  </data>
  <data name="txtWednesday" xml:space="preserve">
    <value>週三</value>
  </data>
  <data name="global_msgCannotSeacrhLastMonthlyInterest" xml:space="preserve">
    <value>只可以選擇 201502 後月份 </value>
  </data>
  <data name="global_msgErrDayIssueAfterMth" xml:space="preserve">
    <value>不可選取大於未過月份</value>
  </data>
  <data name="global_msgErrDayIssueMissing" xml:space="preserve">
    <value>請選擇月息日</value>
  </data>
  <data name="txtStatusOperateOpen" xml:space="preserve">
    <value>已開場</value>
  </data>
  <data name="wStatusOperateCancel" xml:space="preserve">
    <value>已取消</value>
  </data>
  <data name="wStatusOperateExit" xml:space="preserve">
    <value>已離場</value>
  </data>
  <data name="wStatusOperateSettle" xml:space="preserve">
    <value>已結算</value>
  </data>
  <data name="wMSummaryTitle" xml:space="preserve">
    <value>總派息資料</value>
  </data>
  <data name="global_MsgErrForWriteUserEnquiryLog" xml:space="preserve">
    <value>保存用戶查詢日誌失敗</value>
  </data>
  <data name="txtButton" xml:space="preserve">
    <value>按鍵</value>
  </data>
  <data name="txtOption" xml:space="preserve">
    <value>選項</value>
  </data>
  <data name="typeSALARYSETTLEMENTLST_Core" xml:space="preserve">
    <value>月結出糧總表</value>
  </data>
  <data name="txtConfirmSettleTran" xml:space="preserve">
    <value>確認此月份碼糧</value>
  </data>
  <data name="txtConfirmSettleTranTryRun" xml:space="preserve">
    <value>確認此月份的預視碼糧</value>
  </data>
  <data name="txtMthEndProcess" xml:space="preserve">
    <value>執行月結</value>
  </data>
  <data name="txtPrintSalaryDtlSummary" xml:space="preserve">
    <value>列印出糧下線細數表</value>
  </data>
  <data name="txtPrintSalarySummary" xml:space="preserve">
    <value>列印出糧總報表</value>
  </data>
  <data name="txtPrintSalarySummaryDetailTryRun" xml:space="preserve">
    <value>列印預視出糧下線細數表</value>
  </data>
  <data name="txtPrintSalarySummaryTryRun" xml:space="preserve">
    <value>列印預視出糧總報表</value>
  </data>
  <data name="wConfirmMthEndUpdBy" xml:space="preserve">
    <value>確認月結經手人</value>
  </data>
  <data name="wConfirmPreviewUpdBy" xml:space="preserve">
    <value>確認預視經手人</value>
  </data>
  <data name="wEndDateTime" xml:space="preserve">
    <value>完成時間</value>
  </data>
  <data name="global_YearMthLengthOnlySix" xml:space="preserve">
    <value>週期只能為6位數</value>
  </data>
  <data name="txtRemoteRolling" xml:space="preserve">
    <value>遙距轉碼</value>
  </data>
  <data name="typeBPlayMethod_Tel" xml:space="preserve">
    <value>電話</value>
  </data>
  <data name="typeBPlayMethod_Live" xml:space="preserve">
    <value>現場</value>
  </data>
  <data name="typeBPlayCapital_CASH" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="typeBPlayCapital_MCASH" xml:space="preserve">
    <value>M現金</value>
  </data>
  <data name="typeBPlayCapital_IOU" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="txtBComp" xml:space="preserve">
    <value>B數公司</value>
  </data>
  <data name="global_msgNoChange" xml:space="preserve">
    <value>記錄沒有修改</value>
  </data>
  <data name="txtRefreshMthEndStatus" xml:space="preserve">
    <value>更新月結狀態</value>
  </data>
  <data name="wCurrRateDivideDaily" xml:space="preserve">
    <value>當日兌換率(除)</value>
  </data>
  <data name="wCurrRateProductDaily" xml:space="preserve">
    <value>當日兌換率(乘)</value>
  </data>
  <data name="global_msgInfoSettleItemSetFxRate" xml:space="preserve">
    <value>匯率的乘及除只可以一個是1或設定匯率為0</value>
  </data>
  <data name="global_msgInfoSettleItemSetNotFinish" xml:space="preserve">
    <value>佣金設定尚未完成</value>
  </data>
  <data name="txtError" xml:space="preserve">
    <value>錯誤</value>
  </data>
  <data name="txtInProgress" xml:space="preserve">
    <value>進行中...</value>
  </data>
  <data name="global_msgInfoCustomerUsed" xml:space="preserve">
    <value>該客人名稱已使用,不能更改</value>
  </data>
  <data name="global_msgInfoPlsInputCustomerName" xml:space="preserve">
    <value>請輸入客人名稱</value>
  </data>
  <data name="global_msgInfoPlsInputCustomerTel" xml:space="preserve">
    <value>請輸入客人電話</value>
  </data>
  <data name="global_msgInfoTranUsed" xml:space="preserve">
    <value>客人已有相關交易,不能更改或刪除</value>
  </data>
  <data name="global_msgErrTelSMSFormatInvalid" xml:space="preserve">
    <value>短訊號碼格式不正確</value>
  </data>
  <data name="typeSETTLETRANINSTANTLST_Core" xml:space="preserve">
    <value>即出佣金紀錄</value>
  </data>
  <data name="wRecByCName" xml:space="preserve">
    <value>出佣人</value>
  </data>
  <data name="txtBPlayStatus" xml:space="preserve">
    <value>B數狀態</value>
  </data>
  <data name="txtBPlayExchangeStatus" xml:space="preserve">
    <value>交易狀態</value>
  </data>
  <data name="txtSMSStatus" xml:space="preserve">
    <value>短訊狀態</value>
  </data>
  <data name="typeStatusBPlay_Setting" xml:space="preserve">
    <value>設定中</value>
  </data>
  <data name="typeStatusBPlay_RequestOpenGame" xml:space="preserve">
    <value>要求開場</value>
  </data>
  <data name="typeStatusBPlay_ReqEdit" xml:space="preserve">
    <value>要求修改</value>
  </data>
  <data name="typeStatusBPlay_ReqCancel" xml:space="preserve">
    <value>要求取消</value>
  </data>
  <data name="typeStatusBPlay_ReqAddCapital" xml:space="preserve">
    <value>要求加彩</value>
  </data>
  <data name="typeStatusBPlay_RequestExit" xml:space="preserve">
    <value>要求離場</value>
  </data>
  <data name="typeStatusBPlay_Cancel" xml:space="preserve">
    <value>已取消</value>
  </data>
  <data name="typeStatusBPlay_Exit" xml:space="preserve">
    <value>已離場</value>
  </data>
  <data name="typeStatusBPlay_Settle" xml:space="preserve">
    <value>已結算</value>
  </data>
  <data name="txtBPlayExchangeStatusNone" xml:space="preserve">
    <value>未交易</value>
  </data>
  <data name="txtBPlayExchangeStatusSuccess" xml:space="preserve">
    <value>交易成功</value>
  </data>
  <data name="txtStatusSMSOpt0" xml:space="preserve">
    <value>全部未發</value>
  </data>
  <data name="txtStatusSMSOpt1" xml:space="preserve">
    <value>已發開場</value>
  </data>
  <data name="txtStatusSMSOpt2" xml:space="preserve">
    <value>已發離場</value>
  </data>
  <data name="txtStatusSMSOpt3" xml:space="preserve">
    <value>已發結算</value>
  </data>
  <data name="wBPlayRatio" xml:space="preserve">
    <value>佔成(%)</value>
  </data>
  <data name="wBPlayShareRatio" xml:space="preserve">
    <value>免佣佔成(%)</value>
  </data>
  <data name="txtTtlGame" xml:space="preserve">
    <value>本場總局數</value>
  </data>
  <data name="txtTtlCapital" xml:space="preserve">
    <value>本場總本金</value>
  </data>
  <data name="txtAgentCommRate" xml:space="preserve">
    <value>代理佣金率</value>
  </data>
  <data name="txtCustCurrCode" xml:space="preserve">
    <value>客人貨幣</value>
  </data>
  <data name="txtCustFxRate" xml:space="preserve">
    <value>客人匯率</value>
  </data>
  <data name="txtCapitalCurrCode" xml:space="preserve">
    <value>本金貨幣</value>
  </data>
  <data name="txtCapitalFxRate" xml:space="preserve">
    <value>本金匯率</value>
  </data>
  <data name="global_txtCompanySetCar" xml:space="preserve">
    <value>公司預設（會員卡）</value>
  </data>
  <data name="global_txtCompanySetManila" xml:space="preserve">
    <value>公司預設(馬尼拉)</value>
  </data>
  <data name="global_txtCompanySetOut" xml:space="preserve">
    <value>公司預設(月結即出)</value>
  </data>
  <data name="global_txtIndividualAgentSetManila" xml:space="preserve">
    <value>個別戶口線設定(馬尼拉)</value>
  </data>
  <data name="global_txtIndividualCageSetCar" xml:space="preserve">
    <value>個別廳設定(會員卡)</value>
  </data>
  <data name="global_txtIndividualCageSetOut" xml:space="preserve">
    <value>個別廳設定(月結即出)</value>
  </data>
  <data name="global_msgInfoPreviewPeriodOnly" xml:space="preserve">
    <value>預視模式可選擇的週期為{0}或以後</value>
  </data>
  <data name="global_eSettleTranStatusOpt_C" xml:space="preserve">
    <value>已出</value>
  </data>
  <data name="global_eSettleTranStatusOpt_O" xml:space="preserve">
    <value>未出</value>
  </data>
  <data name="global_msgPlsEditInfo" xml:space="preserve">
    <value>請先編輯</value>
  </data>
  <data name="wGunterID" xml:space="preserve">
    <value>槍手編號</value>
  </data>
  <data name="wExternalAgentCodeName" xml:space="preserve">
    <value>外線戶口</value>
  </data>
  <data name="wMaxIOUHoldAmt" xml:space="preserve">
    <value>凍結柴金額</value>
  </data>
  <data name="wCapLimitAmt" xml:space="preserve">
    <value>封頂數</value>
  </data>
  <data name="wIsMaxIOU" xml:space="preserve">
    <value>柴</value>
  </data>
  <data name="txtOnTableCapitalAmt" xml:space="preserve">
    <value>出碼本金(萬)</value>
  </data>
  <data name="txtOpenBalanceRemark" xml:space="preserve">
    <value>開場金額備註</value>
  </data>
  <data name="txtIsForeignComm" xml:space="preserve">
    <value>海外廳佣金</value>
  </data>
  <data name="wIsSecretPlay" xml:space="preserve">
    <value>偷食</value>
  </data>
  <data name="txtTtlRolling" xml:space="preserve">
    <value>本場總轉碼</value>
  </data>
  <data name="txtTtlWinLoss" xml:space="preserve">
    <value>本場總輸贏</value>
  </data>
  <data name="txtMarkerAmount10K" xml:space="preserve">
    <value>借貸額(萬)</value>
  </data>
  <data name="btnShowCapitalFxRate" xml:space="preserve">
    <value>如需要輸入第二種貨幣，請按這裡。</value>
  </data>
  <data name="wLocalFxRate" xml:space="preserve">
    <value>自訂匯率</value>
  </data>
  <data name="wFollowStaff" xml:space="preserve">
    <value>跟單員工</value>
  </data>
  <data name="wStartUsr" xml:space="preserve">
    <value>開場員工</value>
  </data>
  <data name="wEndUsr" xml:space="preserve">
    <value>離場員工</value>
  </data>
  <data name="wTableCheckOutAmt" xml:space="preserve">
    <value>離枱數(萬)</value>
  </data>
  <data name="btnImportRolling" xml:space="preserve">
    <value>匯入轉碼</value>
  </data>
  <data name="wIsStoreLocal" xml:space="preserve">
    <value>存本地</value>
  </data>
  <data name="wStoreLocalAmt10K" xml:space="preserve">
    <value>存回金額(萬)</value>
  </data>
  <data name="txtBPlayRatio" xml:space="preserve">
    <value>佔成</value>
  </data>
  <data name="txtBPlayShareRatio" xml:space="preserve">
    <value>免佣佔成</value>
  </data>
  <data name="txtBPlayCashOutLstTitle" xml:space="preserve">
    <value>B數水錢支出列表</value>
  </data>
  <data name="wCustFxRate" xml:space="preserve">
    <value>公對客Ex(乘)</value>
  </data>
  <data name="wCustFxRateDiv" xml:space="preserve">
    <value>公對客Ex(除)</value>
  </data>
  <data name="wCustToForeignSiteFxRate" xml:space="preserve">
    <value>當日Ex(乘)</value>
  </data>
  <data name="wCustToForeignSiteFxRateDiv" xml:space="preserve">
    <value>當日Ex(除)</value>
  </data>
  <data name="txtTableCheckOut" xml:space="preserve">
    <value>離枱數</value>
  </data>
  <data name="txtCommExpense_10k" xml:space="preserve">
    <value>佣金支出(萬)</value>
  </data>
  <data name="txtCommIncome_10k" xml:space="preserve">
    <value>佣金收入(萬)</value>
  </data>
  <data name="wNetAmt_10K" xml:space="preserve">
    <value>實出金額(萬)</value>
  </data>
  <data name="wPoints_10K" xml:space="preserve">
    <value>積分(萬)</value>
  </data>
  <data name="txtTtlCapital10K" xml:space="preserve">
    <value>本場總本金(萬)</value>
  </data>
  <data name="txtTtlRolling10K" xml:space="preserve">
    <value>本場總轉碼(萬)</value>
  </data>
  <data name="txtTtlWinLoss10K" xml:space="preserve">
    <value>本場總輸贏(萬)</value>
  </data>
  <data name="txtSettle" xml:space="preserve">
    <value>結算</value>
  </data>
  <data name="wAgentComm" xml:space="preserve">
    <value>代理佣金</value>
  </data>
  <data name="wAgentSalary" xml:space="preserve">
    <value>代理實出</value>
  </data>
  <data name="wTIPS" xml:space="preserve">
    <value>水錢</value>
  </data>
  <data name="txtPaidByMacau" xml:space="preserve">
    <value>[澳門出]</value>
  </data>
  <data name="global_msgInfoInvalidPeriod" xml:space="preserve">
    <value>月結不存在</value>
  </data>
  <data name="global_optCashType_F" xml:space="preserve">
    <value>海外借貸</value>
  </data>
  <data name="global_optCashType_O" xml:space="preserve">
    <value>營運借貸</value>
  </data>
  <data name="global_msgDoCentralAuthorizeFirst" xml:space="preserve">
    <value>請先由中央信貸部授權才可進行出糧動作</value>
  </data>
  <data name="global_btnConfirmCancelPayoff" xml:space="preserve">
    <value>取消此次出佣</value>
  </data>
  <data name="global_msgErrorAuthFailed" xml:space="preserve">
    <value>{0}授權失敗</value>
  </data>
  <data name="typeCUSTOMERTELBDTL_Core" xml:space="preserve">
    <value>客人記錄</value>
  </data>
  <data name="global_msgMissingFxRate" xml:space="preserve">
    <value>找不到此貨幣兌換港元的匯率</value>
  </data>
  <data name="global_msgMthEndPrepare" xml:space="preserve">
    <value>月結 仍在準備中</value>
  </data>
  <data name="global_PopUpSettleRemark" xml:space="preserve">
    <value>出糧備註</value>
  </data>
  <data name="global_PopUpSettleTranInstantRemark" xml:space="preserve">
    <value>即出備註</value>
  </data>
  <data name="global_msgIVRAuthSuccess" xml:space="preserve">
    <value>IVR授權成功; 請於30分鐘內出糧</value>
  </data>
  <data name="global_msgErrIVRAuthExpired" xml:space="preserve">
    <value>IVR操作逾時; 請重新授權</value>
  </data>
  <data name="global_msgWarnHasOverdueAmt" xml:space="preserve">
    <value>此戶口過期M {0} 萬</value>
  </data>
  <data name="wSaltAgentWebPassword" xml:space="preserve">
    <value>RollexWebPassword</value>
  </data>
  <data name="global_txtCustomerAcc" xml:space="preserve">
    <value>客人戶口</value>
  </data>
  <data name="btnSettleTranInstant" xml:space="preserve">
    <value>即出佣金</value>
  </data>
  <data name="txtLocalTable" xml:space="preserve">
    <value>本地枱</value>
  </data>
  <data name="msgEliteMemberCalcDrinkRate" xml:space="preserve">
    <value>尊貴卡積分計算方法: 本金 X (佣金率 + 0.1%)</value>
  </data>
  <data name="msgInfoIncludeCashRollngOnly" xml:space="preserve">
    <value>只包括現金/月息轉碼數</value>
  </data>
  <data name="txtRollingAPlay_10K" xml:space="preserve">
    <value>A數轉碼(萬)</value>
  </data>
  <data name="txtRollingBPlay_10K" xml:space="preserve">
    <value>B數轉碼(萬)</value>
  </data>
  <data name="txtTableCurrency" xml:space="preserve">
    <value>賭枱貨幣</value>
  </data>
  <data name="txtBFDrinkAmt" xml:space="preserve">
    <value>食津累數</value>
  </data>
  <data name="txtExpAmount" xml:space="preserve">
    <value>消費數</value>
  </data>
  <data name="global_msgErrHasNoDataToPrint" xml:space="preserve">
    <value>沒有數據可列印</value>
  </data>
  <data name="txtCannotVoid" xml:space="preserve">
    <value>不可取消</value>
  </data>
  <data name="txtSettlementExists" xml:space="preserve">
    <value>月結已存在</value>
  </data>
  <data name="global_btnTransfer" xml:space="preserve">
    <value>轉帳</value>
  </data>
  <data name="txtfrmSettle" xml:space="preserve">
    <value>出</value>
  </data>
  <data name="txtIsSettle" xml:space="preserve">
    <value>的糧</value>
  </data>
  <data name="txtTo" xml:space="preserve">
    <value>至</value>
  </data>
  <data name="wCommissionCutoff" xml:space="preserve">
    <value>實出佣</value>
  </data>
  <data name="global_IOUPenaltyStatus" xml:space="preserve">
    <value>結算罰息</value>
  </data>
  <data name="txtConfirmCurPenalty" xml:space="preserve">
    <value>確認此月份罰息</value>
  </data>
  <data name="txtCustomerCode" xml:space="preserve">
    <value>客人號碼</value>
  </data>
  <data name="txtShowDisable" xml:space="preserve">
    <value>顯示不收</value>
  </data>
  <data name="typeCUSTOMERCHIPTRANBLST_Core" xml:space="preserve">
    <value>電投客人存款及明細</value>
  </data>
  <data name="txtOutstandingCommission" xml:space="preserve">
    <value>未出佣</value>
  </data>
  <data name="txt60DaysWithoutRtn" xml:space="preserve">
    <value>60日或以上沒有還款記錄</value>
  </data>
  <data name="txtOutStandingPenalty" xml:space="preserve">
    <value>倘欠罰息戶口</value>
  </data>
  <data name="txtDaysExp" xml:space="preserve">
    <value>過期天數</value>
  </data>
  <data name="txtTtl" xml:space="preserve">
    <value>總</value>
  </data>
  <data name="wOverdueAmt" xml:space="preserve">
    <value>過期數</value>
  </data>
  <data name="txtInstantCardBPlay" xml:space="preserve">
    <value>B數即出咭戶口</value>
  </data>
  <data name="typeCUSTOMERCHIPTRANBDTL_Core" xml:space="preserve">
    <value>電投存卡紀錄</value>
  </data>
  <data name="txtWin" xml:space="preserve">
    <value>羸錢</value>
  </data>
  <data name="wSettleTypeI" xml:space="preserve">
    <value>即出</value>
  </data>
  <data name="txtday" xml:space="preserve">
    <value>天</value>
  </data>
  <data name="typePLACE_FLOOR_PLAN_Core" xml:space="preserve">
    <value>場面平面圖</value>
  </data>
  <data name="typeCHIPTRANWITHDRAW_Core" xml:space="preserve">
    <value>提取</value>
  </data>
  <data name="txtAlreadyConfirmedInterestRate" xml:space="preserve">
    <value>已確認此月份派息</value>
  </data>
  <data name="txtConfirmInterestRate" xml:space="preserve">
    <value>確認此月份派息</value>
  </data>
  <data name="txtGenerateData" xml:space="preserve">
    <value>生成數據</value>
  </data>
  <data name="wInterested" xml:space="preserve">
    <value>已派回贈</value>
  </data>
  <data name="wBAmount_10k" xml:space="preserve">
    <value>存卡(萬)</value>
  </data>
  <data name="wCurrCName_AgentSummary" xml:space="preserve">
    <value>項目</value>
  </data>
  <data name="wExpAmount_10k" xml:space="preserve">
    <value>本月消費(萬)</value>
  </data>
  <data name="wHoldChipAmt_10k" xml:space="preserve">
    <value>凍結存卡(萬)</value>
  </data>
  <data name="wIAmount_10k" xml:space="preserve">
    <value>存單(萬)</value>
  </data>
  <data name="wIOUAmount_10k" xml:space="preserve">
    <value>借貸(萬)</value>
  </data>
  <data name="wRollingAmount_10k" xml:space="preserve">
    <value>本月轉碼(萬)</value>
  </data>
  <data name="typeSETTLEINTERESTRATELST_Core" xml:space="preserve">
    <value>回贈</value>
  </data>
  <data name="txtFollowing" xml:space="preserve">
    <value>跟進中</value>
  </data>
  <data name="txtRealLocate" xml:space="preserve">
    <value>資產處置中</value>
  </data>
  <data name="txtStopM" xml:space="preserve">
    <value>停止借貸</value>
  </data>
  <data name="txtHoldComm" xml:space="preserve">
    <value>HOLD佣</value>
  </data>
  <data name="txtLostContact" xml:space="preserve">
    <value>失聯</value>
  </data>
  <data name="typeRMARKRETTYOLSTRPT_Report" xml:space="preserve">
    <value>借貸歸還類別報表</value>
  </data>
  <data name="typeRMARKRETTYFLSTRPT_Report" xml:space="preserve">
    <value>借貸歸還類別報表</value>
  </data>
  <data name="global_msgErrAmountSmallerThanZero" xml:space="preserve">
    <value>金額必需大於 0</value>
  </data>
  <data name="global_msgErrHasNoRefNo" xml:space="preserve">
    <value>必需填入單號碼</value>
  </data>
  <data name="global_msgErrNewRefNoRequired" xml:space="preserve">
    <value>部份提單必需要填入新單號碼</value>
  </data>
  <data name="global_msgErrUpdByEqualAuthBy" xml:space="preserve">
    <value>授權人與經手人或跳過戶口認證授權人與經手人不能相同</value>
  </data>
  <data name="global_msgErrWrongAuthBy" xml:space="preserve">
    <value>授權人錯誤</value>
  </data>
  <data name="global_msgInfoPlsWaitForChecking" xml:space="preserve">
    <value>請稍候... ...系統正在覆核資料 ...</value>
  </data>
  <data name="txtMsgInvalidData" xml:space="preserve">
    <value>資料未能符合要求</value>
  </data>
  <data name="typeIOUPENALTYSTATUS_Core" xml:space="preserve">
    <value>結算罰息</value>
  </data>
  <data name="wPrice_10k" xml:space="preserve">
    <value>單價(萬)</value>
  </data>
  <data name="wRoomExpAmt_10k" xml:space="preserve">
    <value>房消費(萬)</value>
  </data>
  <data name="wCashRollC_10k" xml:space="preserve">
    <value>現金(萬)</value>
  </data>
  <data name="wCashRollS_10k" xml:space="preserve">
    <value>股本(萬)</value>
  </data>
  <data name="wCIOURoll_10k" xml:space="preserve">
    <value>公司U(萬)</value>
  </data>
  <data name="wIOURoll_10k" xml:space="preserve">
    <value>IOU(萬)</value>
  </data>
  <data name="wTotRollAmt_10k" xml:space="preserve">
    <value>總轉碼(萬)</value>
  </data>
  <data name="global_InterestRateInProgress" xml:space="preserve">
    <value>存款月利息計算中, 請於5至10分鐘後回來檢察狀態</value>
  </data>
  <data name="global_msgErrInterestMonthNotCompleted" xml:space="preserve">
    <value>回贈月份不能為未結束之月份</value>
  </data>
  <data name="global_msgInterestIsDividend" xml:space="preserve">
    <value>這個月份利息已計數</value>
  </data>
  <data name="ROLL" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="ROLL_C" xml:space="preserve">
    <value>加彩</value>
  </data>
  <data name="wRemarkColon" xml:space="preserve">
    <value>備註:</value>
  </data>
  <data name="txtSearchPanelFilter" xml:space="preserve">
    <value>過濾器設定</value>
  </data>
  <data name="wAppointmentDate" xml:space="preserve">
    <value>約見日期</value>
  </data>
  <data name="txtHasAppointment" xml:space="preserve">
    <value>有約見日期</value>
  </data>
  <data name="txtONLYOVERDUE" xml:space="preserve">
    <value>已過期單</value>
  </data>
  <data name="txtCreditExpDay" xml:space="preserve">
    <value>批額過期日數</value>
  </data>
  <data name="txtNoReturnDay" xml:space="preserve">
    <value>無還款天數</value>
  </data>
  <data name="txtAppointmentCount" xml:space="preserve">
    <value>約見次數</value>
  </data>
  <data name="txtDisConnectCount" xml:space="preserve">
    <value>失聯次數</value>
  </data>
  <data name="txtFailSolutionCount" xml:space="preserve">
    <value>約見方案不達標次數</value>
  </data>
  <data name="txtOverdueOrderpercent" xml:space="preserve">
    <value>過期單比例</value>
  </data>
  <data name="txtOverdueAmtpercent" xml:space="preserve">
    <value>過期數比例</value>
  </data>
  <data name="typeCOUNTERBAL_B_Core" xml:space="preserve">
    <value>B數櫃數表</value>
  </data>
  <data name="wDrinkOutstanding" xml:space="preserve">
    <value>尚餘積分</value>
  </data>
  <data name="wBFExpOutstanding" xml:space="preserve">
    <value>尚餘欠費</value>
  </data>
  <data name="wBFDrinkAmountHKD" xml:space="preserve">
    <value>HKD積分累數</value>
  </data>
  <data name="typeCREDITCONTROL_ROOT_Core" xml:space="preserve">
    <value>信貸</value>
  </data>
  <data name="wSolutionExpDate" xml:space="preserve">
    <value>方案到期日</value>
  </data>
  <data name="txtComingExpire" xml:space="preserve">
    <value>即將到期</value>
  </data>
  <data name="txtExpire" xml:space="preserve">
    <value>已到期</value>
  </data>
  <data name="txtFollowDate" xml:space="preserve">
    <value>跟進日期</value>
  </data>
  <data name="txtSolutionExpire" xml:space="preserve">
    <value>方案到期</value>
  </data>
  <data name="txtNotShowHoldComm" xml:space="preserve">
    <value>不顯示HOLD佣</value>
  </data>
  <data name="global_msgExpireYearMthNoLargerPeriodCodeIn_Process" xml:space="preserve">
    <value>限期不能小于執行期</value>
  </data>
  <data name="global_msgYearMthNoLargerPeriodCodeIn_Process" xml:space="preserve">
    <value>輸入期不能小于執行期</value>
  </data>
  <data name="global_msgSelectedMaster" xml:space="preserve">
    <value>選取或母資料並未選取</value>
  </data>
  <data name="global_txtNumberOfRoom" xml:space="preserve">
    <value>房數</value>
  </data>
  <data name="global_txtNumberOfTable" xml:space="preserve">
    <value>枱數</value>
  </data>
  <data name="global_txtRouteMachine" xml:space="preserve">
    <value>路紙機</value>
  </data>
  <data name="global_msgSystemDataCannotAmend" xml:space="preserve">
    <value>不能修改系統資料</value>
  </data>
  <data name="global_txtAmt" xml:space="preserve">
    <value>額</value>
  </data>
  <data name="global_txtCapital" xml:space="preserve">
    <value>本金</value>
  </data>
  <data name="global_txtLarge" xml:space="preserve">
    <value>大</value>
  </data>
  <data name="global_txtNormal" xml:space="preserve">
    <value>普通</value>
  </data>
  <data name="global_txtSmall" xml:space="preserve">
    <value>小</value>
  </data>
  <data name="global_txtBNumber_X" xml:space="preserve">
    <value>偷食</value>
  </data>
  <data name="global_txtBooked" xml:space="preserve">
    <value>已預留</value>
  </data>
  <data name="global_txtNotSpecified" xml:space="preserve">
    <value>未定義</value>
  </data>
  <data name="btnConfirm" xml:space="preserve">
    <value>確定</value>
  </data>
  <data name="cbConfirmSettleTran" xml:space="preserve">
    <value>確認此月份碼糧</value>
  </data>
  <data name="CompanyGroup" xml:space="preserve">
    <value>集團</value>
  </data>
  <data name="GrpOperate" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="IOU10k" xml:space="preserve">
    <value>借款(萬)</value>
  </data>
  <data name="mAgent" xml:space="preserve">
    <value>戶口</value>
  </data>
  <data name="month" xml:space="preserve">
    <value>月</value>
  </data>
  <data name="msgErrAmountSmallerThanZero" xml:space="preserve">
    <value>金額必需大於 0</value>
  </data>
  <data name="msgErrFail" xml:space="preserve">
    <value>失敗</value>
  </data>
  <data name="msgErrNotSufficient" xml:space="preserve">
    <value>不足夠</value>
  </data>
  <data name="msgInfoSettleItemSetFxRate" xml:space="preserve">
    <value>匯率的乘及除只可以一個是1或設定匯率為0</value>
  </data>
  <data name="RollStatusOptC" xml:space="preserve">
    <value>離場</value>
  </data>
  <data name="statusPlsSelect" xml:space="preserve">
    <value>請選擇</value>
  </data>
  <data name="txtCurrencyCode" xml:space="preserve">
    <value>貨幣碼</value>
  </data>
  <data name="txtCustomerCurrency" xml:space="preserve">
    <value>客人兌換貨幣</value>
  </data>
  <data name="txtCustomInstantCard" xml:space="preserve">
    <value>自訂即出咭戶口</value>
  </data>
  <data name="txtEarlyInstant" xml:space="preserve">
    <value>提前即出佣金</value>
  </data>
  <data name="txtExchangeCurrCode" xml:space="preserve">
    <value>兌換貨幣</value>
  </data>
  <data name="txtForeign" xml:space="preserve">
    <value>海外</value>
  </data>
  <data name="txtForeignInstantPaidAtMacau" xml:space="preserve">
    <value>在澳門支付佣金</value>
  </data>
  <data name="txtGlobalPointFxRate" xml:space="preserve">
    <value>澳門積分兌換率</value>
  </data>
  <data name="txtInstantBFExpCard" xml:space="preserve">
    <value>即出欠前消費咭戶口</value>
  </data>
  <data name="txtInstantExpCard2" xml:space="preserve">
    <value>即出會員消費咭戶口</value>
  </data>
  <data name="txtIou_ForeignInstantPaid" xml:space="preserve">
    <value>本次借貸(萬)</value>
  </data>
  <data name="txtNoSettingWithCurrency" xml:space="preserve">
    <value>未設有關貨幣表</value>
  </data>
  <data name="txtSalaryPaidByHKD" xml:space="preserve">
    <value>以港幣支付佣金</value>
  </data>
  <data name="year" xml:space="preserve">
    <value>年</value>
  </data>
  <data name="AccTypeDn" xml:space="preserve">
    <value>會員降級</value>
  </data>
  <data name="AccTypeExtend" xml:space="preserve">
    <value>延期</value>
  </data>
  <data name="AccTypeUp" xml:space="preserve">
    <value>會員升級</value>
  </data>
  <data name="All" xml:space="preserve">
    <value>所有</value>
  </data>
  <data name="Amount" xml:space="preserve">
    <value>金額</value>
  </data>
  <data name="AuthIdentityASSISTANT" xml:space="preserve">
    <value>業務發展部助理</value>
  </data>
  <data name="AuthIdentityAUTH" xml:space="preserve">
    <value>授權人</value>
  </data>
  <data name="AuthIdentityBOSS" xml:space="preserve">
    <value>幕後老闆</value>
  </data>
  <data name="AuthIdentityCLIENT" xml:space="preserve">
    <value>客人</value>
  </data>
  <data name="AuthIdentityDIRECTOR" xml:space="preserve">
    <value>總監</value>
  </data>
  <data name="AuthIdentityFAMILY" xml:space="preserve">
    <value>家人</value>
  </data>
  <data name="AuthIdentityMARKETING" xml:space="preserve">
    <value>市場部</value>
  </data>
  <data name="AuthIdentityOWNER" xml:space="preserve">
    <value>戶主</value>
  </data>
  <data name="AuthIdentityPARTNER" xml:space="preserve">
    <value>拍檔</value>
  </data>
  <data name="AuthIdentitySTAFF" xml:space="preserve">
    <value>伙記</value>
  </data>
  <data name="AuthIdentityWARRANTOR" xml:space="preserve">
    <value>借貸担保人</value>
  </data>
  <data name="btnDontSend" xml:space="preserve">
    <value>不發送</value>
  </data>
  <data name="btnSelAll" xml:space="preserve">
    <value>全選</value>
  </data>
  <data name="btnShowAll" xml:space="preserve">
    <value>顯示所有</value>
  </data>
  <data name="CancelCreditTypeStopM" xml:space="preserve">
    <value>解除停M</value>
  </data>
  <data name="Capital" xml:space="preserve">
    <value>本金</value>
  </data>
  <data name="CashTypeCH" xml:space="preserve">
    <value>個人借貸</value>
  </data>
  <data name="CashTypeIOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="cbShowBalance" xml:space="preserve">
    <value>顯示結存</value>
  </data>
  <data name="cent" xml:space="preserve">
    <value>分</value>
  </data>
  <data name="ChipTranTranTypeCR" xml:space="preserve">
    <value>提取</value>
  </data>
  <data name="ChipTranTranTypeCS" xml:space="preserve">
    <value>存入</value>
  </data>
  <data name="ChipTranTypeB" xml:space="preserve">
    <value>存卡</value>
  </data>
  <data name="CreditTypeLongTerm" xml:space="preserve">
    <value>長期</value>
  </data>
  <data name="CreditTypeMonRate" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="CreditTypeOnce" xml:space="preserve">
    <value>一次</value>
  </data>
  <data name="CreditTypeStopM" xml:space="preserve">
    <value>停M</value>
  </data>
  <data name="CurrentAssets" xml:space="preserve">
    <value>流動資產</value>
  </data>
  <data name="CurrentLib" xml:space="preserve">
    <value>流動負債</value>
  </data>
  <data name="dollar" xml:space="preserve">
    <value>圓</value>
  </data>
  <data name="dollarWhole" xml:space="preserve">
    <value>圓整</value>
  </data>
  <data name="eight" xml:space="preserve">
    <value>捌</value>
  </data>
  <data name="emptyString" xml:space="preserve">
    <value>(空白)</value>
  </data>
  <data name="eSettleTranStatusOpt_C" xml:space="preserve">
    <value>已出</value>
  </data>
  <data name="eSettleTranStatusOpt_O" xml:space="preserve">
    <value>未出</value>
  </data>
  <data name="ExpenseCateF" xml:space="preserve">
    <value>食單</value>
  </data>
  <data name="ExpenseCateH" xml:space="preserve">
    <value>酒店</value>
  </data>
  <data name="ExpenseCateO" xml:space="preserve">
    <value>其它</value>
  </data>
  <data name="ExpenseCateS" xml:space="preserve">
    <value>船票</value>
  </data>
  <data name="ExpenseCateTC" xml:space="preserve">
    <value>直升機/車</value>
  </data>
  <data name="five" xml:space="preserve">
    <value>伍</value>
  </data>
  <data name="FixedAssets" xml:space="preserve">
    <value>固定資產</value>
  </data>
  <data name="four" xml:space="preserve">
    <value>肆</value>
  </data>
  <data name="GeneralExpense" xml:space="preserve">
    <value>通常開支</value>
  </data>
  <data name="GrpMarker" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="GrpWinLoss" xml:space="preserve">
    <value>枱面</value>
  </data>
  <data name="hidden" xml:space="preserve">
    <value>不顯示</value>
  </data>
  <data name="hundred" xml:space="preserve">
    <value>佰</value>
  </data>
  <data name="hundredm" xml:space="preserve">
    <value>億</value>
  </data>
  <data name="lblMainIntroduce" xml:space="preserve">
    <value>主要來貨</value>
  </data>
  <data name="lblOthersIntroduce" xml:space="preserve">
    <value>其他來貨</value>
  </data>
  <data name="ManufacturingAcc" xml:space="preserve">
    <value>工業賬目</value>
  </data>
  <data name="MarkerReportSearchType_Completed" xml:space="preserve">
    <value>已歸還</value>
  </data>
  <data name="MarkerReportSearchType_Outstanding" xml:space="preserve">
    <value>未歸還</value>
  </data>
  <data name="mExpense" xml:space="preserve">
    <value>消費</value>
  </data>
  <data name="msgAskConfirm" xml:space="preserve">
    <value>請確認</value>
  </data>
  <data name="msgAskConfirmChipTranB" xml:space="preserve">
    <value>確認完成此項存卡？</value>
  </data>
  <data name="msgAskConfirmPerformRollingAction" xml:space="preserve">
    <value>確認並執行此項轉碼？</value>
  </data>
  <data name="msgAskConfirmRollCompleted" xml:space="preserve">
    <value>確認完成此項轉碼？</value>
  </data>
  <data name="msgAskConfirmStoreMarker" xml:space="preserve">
    <value>確認完成此項存M？</value>
  </data>
  <data name="msgAskRejectRoll" xml:space="preserve">
    <value>確認不允許此項轉碼？</value>
  </data>
  <data name="msgInfoPlsInput" xml:space="preserve">
    <value>請輸入</value>
  </data>
  <data name="msgInvalidData" xml:space="preserve">
    <value>資料未能符合要求</value>
  </data>
  <data name="msgNeedAddCapitalBeforeRolling" xml:space="preserve">
    <value>轉碼執行前必須加彩</value>
  </data>
  <data name="msgNotPositiveNumber" xml:space="preserve">
    <value>輸入的不是正數字！</value>
  </data>
  <data name="msgNumTooLarge" xml:space="preserve">
    <value>數字太大，無法換算，請輸入一萬億元以下的金額</value>
  </data>
  <data name="msgPlsWaitUntilPerviousActionEnded" xml:space="preserve">
    <value>請等待完成上一項動作</value>
  </data>
  <data name="Negative" xml:space="preserve">
    <value>負</value>
  </data>
  <data name="nine" xml:space="preserve">
    <value>玖</value>
  </data>
  <data name="one" xml:space="preserve">
    <value>壹</value>
  </data>
  <data name="PrintPreview" xml:space="preserve">
    <value>預覽列印</value>
  </data>
  <data name="ProvisionForTaxation" xml:space="preserve">
    <value>預繳稅金</value>
  </data>
  <data name="rAgentBookingProgressive" xml:space="preserve">
    <value>業務進步約見名單</value>
  </data>
  <data name="rAgentChipBookMoreThanMarker" xml:space="preserve">
    <value>每月存款大於過期Marker</value>
  </data>
  <data name="rAgentCreditAmount" xml:space="preserve">
    <value>批碼金額及戶口</value>
  </data>
  <data name="rAgentCreditOver100KRollUnder1M" xml:space="preserve">
    <value>批額1千不達標</value>
  </data>
  <data name="rAgentWinLossTop20" xml:space="preserve">
    <value>輸贏排名</value>
  </data>
  <data name="rCreditAndRollingList" xml:space="preserve">
    <value>已批額玩家戶口及轉碼</value>
  </data>
  <data name="RemoteOperation" xml:space="preserve">
    <value>遙距指令</value>
  </data>
  <data name="ReturnType_C" xml:space="preserve">
    <value>現碼還M</value>
  </data>
  <data name="ReturnType_M" xml:space="preserve">
    <value>M還M</value>
  </data>
  <data name="ReturnType_R" xml:space="preserve">
    <value>存M還M</value>
  </data>
  <data name="ReturnType_W" xml:space="preserve">
    <value>贏M回舊M</value>
  </data>
  <data name="rFollowZZSAccount" xml:space="preserve">
    <value>ZZS/OT/OF/OK分析</value>
  </data>
  <data name="rLatest30DaysFirstMarkerAccount" xml:space="preserve">
    <value>批M首月轉碼</value>
  </data>
  <data name="rNewAgentCreditRolling" xml:space="preserve">
    <value>新批玩家戶口及轉碼</value>
  </data>
  <data name="rNoMarkerList" xml:space="preserve">
    <value>停M名單</value>
  </data>
  <data name="RollStatusOptO" xml:space="preserve">
    <value>在場</value>
  </data>
  <data name="txtRollTypeCode" xml:space="preserve">
    <value>轉碼類型</value>
  </data>
  <data name="RollTypeCodeCaptital" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="RollTypeCodeCash" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="RollTypeCodeCIOU" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="RollTypeCodeIOU" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="rSubstandardAgentCreditOver1M" xml:space="preserve">
    <value>有額超過1個月無用名單</value>
  </data>
  <data name="SettleSetConfirm" xml:space="preserve">
    <value>確認</value>
  </data>
  <data name="SettleSetNotConfirm" xml:space="preserve">
    <value>未確認</value>
  </data>
  <data name="seven" xml:space="preserve">
    <value>柒</value>
  </data>
  <data name="Shift1" xml:space="preserve">
    <value>早更</value>
  </data>
  <data name="Shift2" xml:space="preserve">
    <value>中更</value>
  </data>
  <data name="Shift3" xml:space="preserve">
    <value>夜更</value>
  </data>
  <data name="six" xml:space="preserve">
    <value>陸</value>
  </data>
  <data name="SMSStatus_A1" xml:space="preserve">
    <value>已推送</value>
  </data>
  <data name="SMSStatus_C1" xml:space="preserve">
    <value>成功</value>
  </data>
  <data name="SMSStatus_F" xml:space="preserve">
    <value>失敗</value>
  </data>
  <data name="SMSStatus_O" xml:space="preserve">
    <value>排隊發送</value>
  </data>
  <data name="SMSStatus_T" xml:space="preserve">
    <value>發送系統故障</value>
  </data>
  <data name="SMS_ACCOUNTTYPE" xml:space="preserve">
    <value>戶口級別升降</value>
  </data>
  <data name="SMS_AGENTUPD" xml:space="preserve">
    <value>戶口修改</value>
  </data>
  <data name="SMS_CREDIT" xml:space="preserve">
    <value>批額修改</value>
  </data>
  <data name="SMS_DAIROLLRPT" xml:space="preserve">
    <value>每日集團轉碼報表</value>
  </data>
  <data name="SMS_EXPDAILY" xml:space="preserve">
    <value>每日集團消費報表</value>
  </data>
  <data name="SMS_FOREIGN_ADDCAPITAL" xml:space="preserve">
    <value>海外加彩</value>
  </data>
  <data name="SMS_FOREIGN_CLOSE" xml:space="preserve">
    <value>海外離場</value>
  </data>
  <data name="SMS_FOREIGN_CLOSECONT" xml:space="preserve">
    <value>海外離場(續場)</value>
  </data>
  <data name="SMS_FOREIGN_OPEN" xml:space="preserve">
    <value>海外開場</value>
  </data>
  <data name="SMS_FOREIGN_OPENCONT" xml:space="preserve">
    <value>海外開場(續場)</value>
  </data>
  <data name="SMS_FOREIGN_SETTLE_CU" xml:space="preserve">
    <value>客人海外結算</value>
  </data>
  <data name="SMS_OPERATE_ADDCAPITAL" xml:space="preserve">
    <value>營運加彩</value>
  </data>
  <data name="SMS_OPERATE_CLOSE" xml:space="preserve">
    <value>營運離場</value>
  </data>
  <data name="SMS_OPERATE_CLOSECONT" xml:space="preserve">
    <value>營運離場(續場)</value>
  </data>
  <data name="SMS_OPERATE_OPEN" xml:space="preserve">
    <value>營運開場</value>
  </data>
  <data name="SMS_OPERATE_OPENCONT" xml:space="preserve">
    <value>營運開場(續場)</value>
  </data>
  <data name="SMS_OPERATE_SETTLE_CU" xml:space="preserve">
    <value>客人營運結算</value>
  </data>
  <data name="SMS_ROLLDAILY" xml:space="preserve">
    <value>轉碼日結</value>
  </data>
  <data name="SMS_ROLLDAILYSHARE" xml:space="preserve">
    <value>轉碼日結(股東組)</value>
  </data>
  <data name="SMS_SUBAGENT_INFO" xml:space="preserve">
    <value>下線資料</value>
  </data>
  <data name="TableBookingStatus_Booked" xml:space="preserve">
    <value>已預訂</value>
  </data>
  <data name="TableBookingStatus_Empty" xml:space="preserve">
    <value>閒置</value>
  </data>
  <data name="TableBookingStatus_Occupied" xml:space="preserve">
    <value>使用中</value>
  </data>
  <data name="TableTranStatusOptC" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="TableTranStatusOptO" xml:space="preserve">
    <value>有效</value>
  </data>
  <data name="tAssetsProcess" xml:space="preserve">
    <value>資產處理中</value>
  </data>
  <data name="tBlackList" xml:space="preserve">
    <value>黑名單</value>
  </data>
  <data name="tCannotConnect" xml:space="preserve">
    <value>無法接通</value>
  </data>
  <data name="tDelayPaid" xml:space="preserve">
    <value>延期還款</value>
  </data>
  <data name="tEmptyNo" xml:space="preserve">
    <value>空號</value>
  </data>
  <data name="ten" xml:space="preserve">
    <value>拾</value>
  </data>
  <data name="tenCent" xml:space="preserve">
    <value>角</value>
  </data>
  <data name="tenk" xml:space="preserve">
    <value>萬</value>
  </data>
  <data name="tenZero" xml:space="preserve">
    <value>拾零</value>
  </data>
  <data name="tExpectPaid" xml:space="preserve">
    <value>預期還款</value>
  </data>
  <data name="thousand" xml:space="preserve">
    <value>仟</value>
  </data>
  <data name="three" xml:space="preserve">
    <value>叁</value>
  </data>
  <data name="tInstallments" xml:space="preserve">
    <value>分期還款</value>
  </data>
  <data name="tNoReceiveCall" xml:space="preserve">
    <value>無人接聽</value>
  </data>
  <data name="tNotConfrimPaidDate" xml:space="preserve">
    <value>沒法落實時間</value>
  </data>
  <data name="tOtherPplReceiveCall" xml:space="preserve">
    <value>其它人接聽</value>
  </data>
  <data name="tProcessing" xml:space="preserve">
    <value>跟進中</value>
  </data>
  <data name="TradingAccount" xml:space="preserve">
    <value>貿易賬目</value>
  </data>
  <data name="tReceiveCall" xml:space="preserve">
    <value>本人接聽</value>
  </data>
  <data name="tReceiveNotStable" xml:space="preserve">
    <value>接聽次數不穩定</value>
  </data>
  <data name="tRepeatedlyDelay" xml:space="preserve">
    <value>多次延期</value>
  </data>
  <data name="tSeekInterest" xml:space="preserve">
    <value>追收利息</value>
  </data>
  <data name="tShutDown" xml:space="preserve">
    <value>關機</value>
  </data>
  <data name="two" xml:space="preserve">
    <value>貳</value>
  </data>
  <data name="txtAgentAccountType1" xml:space="preserve">
    <value>太陽客戶</value>
  </data>
  <data name="txtAgentAccountType2" xml:space="preserve">
    <value>金太陽</value>
  </data>
  <data name="txtAgentAccountType3" xml:space="preserve">
    <value>卓越</value>
  </data>
  <data name="txtAgentAccountType4" xml:space="preserve">
    <value>非凡</value>
  </data>
  <data name="txtAgentAccountType5" xml:space="preserve">
    <value>奇蹟</value>
  </data>
  <data name="txtAgentAccountType6" xml:space="preserve">
    <value>傳奇</value>
  </data>
  <data name="txtAgentAccountType7" xml:space="preserve">
    <value>至尊</value>
  </data>
  <data name="txtAgentTypeGolden" xml:space="preserve">
    <value>金咭戶</value>
  </data>
  <data name="txtAgentTypeNew" xml:space="preserve">
    <value>新開戶</value>
  </data>
  <data name="txtAgentTypeNormal" xml:space="preserve">
    <value>基本戶</value>
  </data>
  <data name="txtAgentTypeVIP" xml:space="preserve">
    <value>VIP</value>
  </data>
  <data name="txtAgentTypeVVIP" xml:space="preserve">
    <value>VVIP</value>
  </data>
  <data name="txtCapitalTranS" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="txtCapitalTranY" xml:space="preserve">
    <value>食貨</value>
  </data>
  <data name="txtCashIOU" xml:space="preserve">
    <value>現金借貸單</value>
  </data>
  <data name="txtCasinoCreditAmt" xml:space="preserve">
    <value>娛樂場額</value>
  </data>
  <data name="txtChipTranCompanyTotalAmount" xml:space="preserve">
    <value>集團結存</value>
  </data>
  <data name="txtCreditAmtU" xml:space="preserve">
    <value>U可簽額</value>
  </data>
  <data name="txtDateOption" xml:space="preserve">
    <value>日期</value>
  </data>
  <data name="txtDatePeriodOption" xml:space="preserve">
    <value>日期範圍</value>
  </data>
  <data name="txtDept_Cage" xml:space="preserve">
    <value>賬房</value>
  </data>
  <data name="txtDept_CustRelate" xml:space="preserve">
    <value>業務發展部</value>
  </data>
  <data name="txtDept_Develop" xml:space="preserve">
    <value>市場拓展部</value>
  </data>
  <data name="txtDept_Front" xml:space="preserve">
    <value>市場及貴賓部</value>
  </data>
  <data name="txtDept_Member" xml:space="preserve">
    <value>會籍部</value>
  </data>
  <data name="txtDept_Room" xml:space="preserve">
    <value>客戶服務部</value>
  </data>
  <data name="txtDept_Vehicle" xml:space="preserve">
    <value>車務部</value>
  </data>
  <data name="txtFalse" xml:space="preserve">
    <value>否</value>
  </data>
  <data name="txtForeignCapitalCheckInType" xml:space="preserve">
    <value>出碼數計算佣金</value>
  </data>
  <data name="txtForeignCapitalCheckIn_WLType" xml:space="preserve">
    <value>出碼及下數計算佣金</value>
  </data>
  <data name="txtForeignCapitalRollingType" xml:space="preserve">
    <value>轉碼數倍數佣金</value>
  </data>
  <data name="txtForeignCashOut" xml:space="preserve">
    <value>現金支出</value>
  </data>
  <data name="txtForeignExpense" xml:space="preserve">
    <value>支出</value>
  </data>
  <data name="txtForeignIOU" xml:space="preserve">
    <value>海外借貸單</value>
  </data>
  <data name="txtForeignTour" xml:space="preserve">
    <value>外來團</value>
  </data>
  <data name="txtInterestDateOpt" xml:space="preserve">
    <value>應派息日期</value>
  </data>
  <data name="txtIOUFreeze" xml:space="preserve">
    <value>凍結</value>
  </data>
  <data name="txtLocalTour" xml:space="preserve">
    <value>本地團</value>
  </data>
  <data name="txtNNChip" xml:space="preserve">
    <value>泥碼</value>
  </data>
  <data name="txtOneMonth" xml:space="preserve">
    <value>一月</value>
  </data>
  <data name="txtOneWeek" xml:space="preserve">
    <value>一週</value>
  </data>
  <data name="txtOneYear" xml:space="preserve">
    <value>一年</value>
  </data>
  <data name="txtOperateExternal" xml:space="preserve">
    <value>私營</value>
  </data>
  <data name="txtOperateIOU" xml:space="preserve">
    <value>營運借貸單</value>
  </data>
  <data name="txtOutStanding" xml:space="preserve">
    <value>欠款</value>
  </data>
  <data name="txtOutStandingPartPrint" xml:space="preserve">
    <value>是次部分</value>
  </data>
  <data name="txtOutStandingPrint" xml:space="preserve">
    <value>尚欠</value>
  </data>
  <data name="txtPay" xml:space="preserve">
    <value>出糧</value>
  </data>
  <data name="txtPersonal" xml:space="preserve">
    <value>個人</value>
  </data>
  <data name="txtRollingPeriod_DAY" xml:space="preserve">
    <value>日數</value>
  </data>
  <data name="txtRollingPeriod_MTH" xml:space="preserve">
    <value>月數</value>
  </data>
  <data name="txtRollingPeriod_YER" xml:space="preserve">
    <value>年數</value>
  </data>
  <data name="txtSettleStatusOutstanding" xml:space="preserve">
    <value>未結算</value>
  </data>
  <data name="txtSMS_EXIT" xml:space="preserve">
    <value>離場訊息</value>
  </data>
  <data name="txtSMS_MONTH_END_SETTLE" xml:space="preserve">
    <value>出佣訊息</value>
  </data>
  <data name="txtSMS_OPEN" xml:space="preserve">
    <value>開場訊息</value>
  </data>
  <data name="txtStore_Cash" xml:space="preserve">
    <value>存C</value>
  </data>
  <data name="txtTrue" xml:space="preserve">
    <value>是</value>
  </data>
  <data name="txtUpdtOpt" xml:space="preserve">
    <value>操作日期</value>
  </data>
  <data name="txtYearMonthOption" xml:space="preserve">
    <value>年月份</value>
  </data>
  <data name="txtYearOption" xml:space="preserve">
    <value>年份</value>
  </data>
  <data name="uIOUWarnLst" xml:space="preserve">
    <value>貸款提示</value>
  </data>
  <data name="visible" xml:space="preserve">
    <value>顯示</value>
  </data>
  <data name="zero" xml:space="preserve">
    <value>零</value>
  </data>
  <data name="zeroCent" xml:space="preserve">
    <value>零分</value>
  </data>
  <data name="zeroHundred" xml:space="preserve">
    <value>零佰</value>
  </data>
  <data name="zeroHundredm" xml:space="preserve">
    <value>零億</value>
  </data>
  <data name="zeroTen" xml:space="preserve">
    <value>零拾</value>
  </data>
  <data name="zeroTenCent" xml:space="preserve">
    <value>零角</value>
  </data>
  <data name="zeroTenk" xml:space="preserve">
    <value>零萬</value>
  </data>
  <data name="zeroThousand" xml:space="preserve">
    <value>零仟</value>
  </data>
  <data name="zeroZero" xml:space="preserve">
    <value>零零</value>
  </data>
  <data name="msgInfoCardReaderReadFailed" xml:space="preserve">
    <value>讀卡錯誤</value>
  </data>
  <data name="msgInfoCardReaderWriteFailed" xml:space="preserve">
    <value>寫卡錯誤</value>
  </data>
  <data name="msgInfoNoSmartCardDetected" xml:space="preserve">
    <value>請放上智能卡</value>
  </data>
  <data name="msgInfoSuccess" xml:space="preserve">
    <value>成功</value>
  </data>
  <data name="txtElite" xml:space="preserve">
    <value>尊華會</value>
  </data>
  <data name="txtYearMth" xml:space="preserve">
    <value>週期</value>
  </data>
  <data name="txtTranAmt10k" xml:space="preserve">
    <value>交易金額(萬)</value>
  </data>
  <data name="typeOPERATECOMPLST_Core" xml:space="preserve">
    <value>營運公司管理</value>
  </data>
  <data name="txtManagement" xml:space="preserve">
    <value>管理層</value>
  </data>
  <data name="txtOperateCompCredit" xml:space="preserve">
    <value>保證金</value>
  </data>
  <data name="txtOperateCompCreditBal" xml:space="preserve">
    <value>保證金存額</value>
  </data>
  <data name="txtOperateCompTitle" xml:space="preserve">
    <value>公司列表</value>
  </data>
  <data name="txtShare" xml:space="preserve">
    <value>股份</value>
  </data>
  <data name="txtShareListTitle" xml:space="preserve">
    <value>股東列表</value>
  </data>
  <data name="txtSMS" xml:space="preserve">
    <value>短訊</value>
  </data>
  <data name="statusActive" xml:space="preserve">
    <value>有效</value>
  </data>
  <data name="statusSuspend" xml:space="preserve">
    <value>停用</value>
  </data>
  <data name="txtTransactionValue10K" xml:space="preserve">
    <value>交易金額(萬)</value>
  </data>
  <data name="eOperateCompLst" xml:space="preserve">
    <value>營運公司管理</value>
  </data>
  <data name="txtRelateAgent" xml:space="preserve">
    <value>相關戶口</value>
  </data>
  <data name="ePopupOperateCompDtl" xml:space="preserve">
    <value>營運公司記錄</value>
  </data>
  <data name="txtStatus" xml:space="preserve">
    <value>狀態</value>
  </data>
  <data name="txtStatusTerminateDate" xml:space="preserve">
    <value>中止日期</value>
  </data>
  <data name="wAppBidTakeRest" xml:space="preserve">
    <value>以手機應用程式食貨如超額認購，自動認購系統當時的餘額佔成</value>
  </data>
  <data name="wCreditHoldMultiple" xml:space="preserve">
    <value>凍結倍數</value>
  </data>
  <data name="wIsCheckCredit" xml:space="preserve">
    <value>佔成時檢查保証金</value>
  </data>
  <data name="wIsCheckCreditAddCapital" xml:space="preserve">
    <value>加彩時檢查保証金</value>
  </data>
  <data name="wIsMainComp" xml:space="preserve">
    <value>主公司</value>
  </data>
  <data name="ePopupOperateCompShareDtl" xml:space="preserve">
    <value>營運公司股東記錄</value>
  </data>
  <data name="lblAppsNewBidPassword" xml:space="preserve">
    <value>手機程式食貨密碼</value>
  </data>
  <data name="lblAppsNewPassword" xml:space="preserve">
    <value>新手機程式密碼</value>
  </data>
  <data name="txtCustName" xml:space="preserve">
    <value>名稱</value>
  </data>
  <data name="txtSharePercent" xml:space="preserve">
    <value>股份數量</value>
  </data>
  <data name="txtTelSMS" xml:space="preserve">
    <value>短訊號碼</value>
  </data>
  <data name="txtShiftRolling" xml:space="preserve">
    <value>本更轉碼</value>
  </data>
  <data name="txtLineGrp_Ext" xml:space="preserve">
    <value>(A-Z)</value>
  </data>
  <data name="msgInfoOperateCompAgentAdded" xml:space="preserve">
    <value>股東已加入</value>
  </data>
  <data name="txtNoData" xml:space="preserve">
    <value>沒有數據</value>
  </data>
  <data name="global_btnGenCardActCode" xml:space="preserve">
    <value>設置卡行動碼</value>
  </data>
  <data name="global_msgErrStaffCardActionCodeEmpty" xml:space="preserve">
    <value>必須設置卡行動碼</value>
  </data>
  <data name="global_RegenCardActCode" xml:space="preserve">
    <value>重設卡行動碼</value>
  </data>
  <data name="msgErrPwdNotMatch" xml:space="preserve">
    <value>新密碼及確認密碼必須相同</value>
  </data>
  <data name="eOperateCompCreditDtl" xml:space="preserve">
    <value>營運公司保證金記錄</value>
  </data>
  <data name="txtOperateCompany" xml:space="preserve">
    <value>營運公司</value>
  </data>
  <data name="typeOPERATECOMPCREDIT_Core" xml:space="preserve">
    <value>營運公司保證金管理</value>
  </data>
  <data name="action_BOOKMARK_type" xml:space="preserve">
    <value>關注</value>
  </data>
  <data name="action_BYPASS_type" xml:space="preserve">
    <value>By Pass</value>
  </data>
  <data name="action_COMPALLSTATUS_type" xml:space="preserve">
    <value>集團概況</value>
  </data>
  <data name="action_CREDITCONTROL_type" xml:space="preserve">
    <value>信貸監控</value>
  </data>
  <data name="action_CREDITSTATUS_type" xml:space="preserve">
    <value>信貸額概況</value>
  </data>
  <data name="action_CUSTOMER_type" xml:space="preserve">
    <value>相關客人</value>
  </data>
  <data name="action_FIRST_SET_PWD_type" xml:space="preserve">
    <value>FirstSetPwd</value>
  </data>
  <data name="action_LASTESTWINLOSS_type" xml:space="preserve">
    <value>最近輸贏數</value>
  </data>
  <data name="action_MEMBERCARD_type" xml:space="preserve">
    <value>會員卡</value>
  </data>
  <data name="action_PREVIEW_type" xml:space="preserve">
    <value>列印預覽</value>
  </data>
  <data name="action_RESET_PWD_type" xml:space="preserve">
    <value>重置密碼</value>
  </data>
  <data name="action_ROLLINGAMT_type" xml:space="preserve">
    <value>轉碼概況</value>
  </data>
  <data name="action_SAVE_type" xml:space="preserve">
    <value>儲存Save</value>
  </data>
  <data name="action_SMS_type" xml:space="preserve">
    <value>SMS</value>
  </data>
  <data name="action_UPDATEPRINT_type" xml:space="preserve">
    <value>儲存並列印</value>
  </data>
  <data name="typeCOMP_SHIFTCUT_Core" xml:space="preserve">
    <value>換更</value>
  </data>
  <data name="typeSEARCHPANELCONFIG_Core" xml:space="preserve">
    <value>過濾器設定</value>
  </data>
  <data name="typeRCREDITCONTROL_AGENT_TRACE_RPT_Report" xml:space="preserve">
    <value>信貸監控個人報表</value>
  </data>
  <data name="txtSettleByCode" xml:space="preserve">
    <value>港幣結算</value>
  </data>
  <data name="txtSettleByRMB" xml:space="preserve">
    <value>人民幣結算</value>
  </data>
  <data name="typeBPLAY_DTL_Core" xml:space="preserve">
    <value>B數記錄</value>
  </data>
  <data name="typeFINANCIAL_CENTRE_Core" xml:space="preserve">
    <value>綜合理財</value>
  </data>
  <data name="typeIOUPENALTYADJDTL_F_Core" xml:space="preserve">
    <value>罰息調整記錄海外)</value>
  </data>
  <data name="typeIOUPENALTYADJDTL_IOU_Core" xml:space="preserve">
    <value>罰息調整記錄</value>
  </data>
  <data name="typeIOUPENALTYADJDTL_Y_Core" xml:space="preserve">
    <value>罰息調整記錄(營運)</value>
  </data>
  <data name="typeIOUPENALTYSETDTL_Core" xml:space="preserve">
    <value>罰息設定記錄</value>
  </data>
  <data name="typeIOUPENALTYSETUPD_Core" xml:space="preserve">
    <value>更改借貸天數及息率</value>
  </data>
  <data name="typeOPERATECOMPCREDITDTL_Core" xml:space="preserve">
    <value>營運公司保證金記錄</value>
  </data>
  <data name="typePOPUPUPLOADFILE_Core" xml:space="preserve">
    <value>上傳文件</value>
  </data>
  <data name="typeREMOTEOPERATIONLST_Core" xml:space="preserve">
    <value>遙距指令</value>
  </data>
  <data name="typeREPORTSUMMARY_Core" xml:space="preserve">
    <value>報表</value>
  </data>
  <data name="typeSETTLEINSTANT_Core" xml:space="preserve">
    <value>即出佣金</value>
  </data>
  <data name="typeSETTLELOCATIONPERIODDTL_Core" xml:space="preserve">
    <value>出糧批核週期</value>
  </data>
  <data name="typeSETTLEREMARKDTL_Core" xml:space="preserve">
    <value>出糧備註</value>
  </data>
  <data name="typeSPECIALMARKERDTL_F_Core" xml:space="preserve">
    <value>海外貸款記錄</value>
  </data>
  <data name="typeSPECIALMARKERDTL_Y_Core" xml:space="preserve">
    <value>營運貸款記錄</value>
  </data>
  <data name="typeSPECIALMARKERRETURN_F_Core" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="typeCOUNTERROLLOUTSIDE_Core" xml:space="preserve">
    <value>離場</value>
  </data>
  <data name="typeMARKERRETURNDTL_C_Core" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="typePLACE_IOU_Core" xml:space="preserve">
    <value>貸款</value>
  </data>
  <data name="typeROLLINGEDITREFNO_Core" xml:space="preserve">
    <value>聯絡記錄</value>
  </data>
  <data name="typeSETTLEITEMSETOTHERDTL_Core" xml:space="preserve">
    <value>月結其他設定記錄</value>
  </data>
  <data name="typeSPECIALMARKERRETURN_Y_Core" xml:space="preserve">
    <value>還款</value>
  </data>
  <data name="typeOPERATECOMPDTL_Core" xml:space="preserve">
    <value>營運公司記錄</value>
  </data>
  <data name="typeOPERATECOMPSHAREDTL_Core" xml:space="preserve">
    <value>營運公司股東記錄</value>
  </data>
  <data name="txtCheckUserActionMode" xml:space="preserve">
    <value>認證方法</value>
  </data>
  <data name="typeBOUNDSGIFTRPT_ReportGrp" xml:space="preserve">
    <value>送禮報表</value>
  </data>
  <data name="txtOperateCompWLReport" xml:space="preserve">
    <value>營運公司上/下數報表</value>
  </data>
  <data name="txtPlsInputRoleCode" xml:space="preserve">
    <value>請輸入權限編碼</value>
  </data>
  <data name="txtPlsInputRoleName" xml:space="preserve">
    <value>請輸入權限名稱</value>
  </data>
  <data name="txtRoleCode" xml:space="preserve">
    <value>權限編號</value>
  </data>
  <data name="txtRoleName" xml:space="preserve">
    <value>權限名稱</value>
  </data>
  <data name="typeBOUNDSGIFTRPT_Core" xml:space="preserve">
    <value>送禮報表</value>
  </data>
  <data name="typeIVR_Core" xml:space="preserve">
    <value>IVR</value>
  </data>
  <data name="typePLACE_REMARK_Core" xml:space="preserve">
    <value>場面備註</value>
  </data>
  <data name="typePLACE_SHIFTCUT_Core" xml:space="preserve">
    <value>場面截更</value>
  </data>
  <data name="typeROLEPROGCLONE_Core" xml:space="preserve">
    <value>權限複製</value>
  </data>
  <data name="txtOperateCustWLReport" xml:space="preserve">
    <value>營運客人上/下數報表</value>
  </data>
  <data name="btnChgComp" xml:space="preserve">
    <value>轉場</value>
  </data>
  <data name="txtCompany" xml:space="preserve">
    <value>公司</value>
  </data>
  <data name="txtMsgCannotSave" xml:space="preserve">
    <value>不能保存</value>
  </data>
  <data name="txtTelbDetail" xml:space="preserve">
    <value>電投</value>
  </data>
  <data name="btnRegister" xml:space="preserve">
    <value>系統登錄</value>
  </data>
  <data name="wRSDate" xml:space="preserve">
    <value>入數日期</value>
  </data>
  <data name="typeOPERATETRANSMSLST_Core" xml:space="preserve">
    <value>營運每日訊息表</value>
  </data>
  <data name="txtIncludeCompany" xml:space="preserve">
    <value>資料包括</value>
  </data>
  <data name="txtShowCompWinLoss" xml:space="preserve">
    <value>顯示公司上/下數</value>
  </data>
  <data name="typeOPERATERPT_ReportGrp" xml:space="preserve">
    <value>營運報表</value>
  </data>
  <data name="typeROPERATECOMPWLRPT_Report" xml:space="preserve">
    <value>營運公司上/下數報表</value>
  </data>
  <data name="typeROPERATECUSTWLRPT_Report" xml:space="preserve">
    <value>營運客人上/下數報表</value>
  </data>
  <data name="typeTELBONETIME_Core" xml:space="preserve">
    <value>一次性買碼確定</value>
  </data>
  <data name="txtBuyChip10k" xml:space="preserve">
    <value>買碼(萬)</value>
  </data>
  <data name="global_txtSeat" xml:space="preserve">
    <value>座位</value>
  </data>
  <data name="txtLate" xml:space="preserve">
    <value>逾期還款</value>
  </data>
  <data name="txtChangeSolution" xml:space="preserve">
    <value>方案不相符</value>
  </data>
  <data name="txtFailMeeting" xml:space="preserve">
    <value>約見不成功</value>
  </data>
  <data name="txtCommRtn" xml:space="preserve">
    <value>佣金回數</value>
  </data>
  <data name="txtCurrRateRemark" xml:space="preserve">
    <value>換率為匯至港幣換率</value>
  </data>
  <data name="txtDebuctMthInt" xml:space="preserve">
    <value>扣減月息</value>
  </data>
  <data name="txtDebuctDLCapital" xml:space="preserve">
    <value>扣減下線股本</value>
  </data>
  <data name="typeFOREIGNTOURLST_Core" xml:space="preserve">
    <value>海外團管理</value>
  </data>
  <data name="txtForeignCustExtID" xml:space="preserve">
    <value>客人帳號</value>
  </data>
  <data name="txtForeignStartDate" xml:space="preserve">
    <value>起程日期</value>
  </data>
  <data name="txtForeignTourDtl" xml:space="preserve">
    <value>海外團名單記錄</value>
  </data>
  <data name="txtForeignTourLst" xml:space="preserve">
    <value>海外團列表</value>
  </data>
  <data name="txtForeignTourNameLstTitle" xml:space="preserve">
    <value>海外團名單列表</value>
  </data>
  <data name="txtForeignTourRecord" xml:space="preserve">
    <value>海外團記錄</value>
  </data>
  <data name="txtGameSiteName" xml:space="preserve">
    <value>賭場名稱</value>
  </data>
  <data name="txtTourType" xml:space="preserve">
    <value>團種類</value>
  </data>
  <data name="typeFOREIGNRPT_ReportGrp" xml:space="preserve">
    <value>海外報表</value>
  </data>
  <data name="typeRFOREIGNCOMPWLRPT_REPORT" xml:space="preserve">
    <value>海外公司上/下數報表</value>
  </data>
  <data name="typeRFOREIGNCUSTWLRPT_REPORT" xml:space="preserve">
    <value>海外客人上/下數報表</value>
  </data>
  <data name="txtBonusPoints" xml:space="preserve">
    <value>贈送積分(萬)</value>
  </data>
  <data name="wRolling_100M" xml:space="preserve">
    <value>全線轉碼數(億)</value>
  </data>
  <data name="typeBONUSPOINTSLST_Core" xml:space="preserve">
    <value>贈送積分管理</value>
  </data>
  <data name="wExpireMth" xml:space="preserve">
    <value>過期月數</value>
  </data>
  <data name="typeFOREIGNGAMESITELST_Core" xml:space="preserve">
    <value>海外賭場管理</value>
  </data>
  <data name="txtForeignGameSiteTitle" xml:space="preserve">
    <value>海外賭場列表</value>
  </data>
  <data name="txtForeignGameSiteName" xml:space="preserve">
    <value>海外賭場</value>
  </data>
  <data name="wCreateDate" xml:space="preserve">
    <value>建立日期</value>
  </data>
  <data name="global_msgDelFail" xml:space="preserve">
    <value>刪除失敗</value>
  </data>
  <data name="txtMsgInfoRecExisted" xml:space="preserve">
    <value>檔案已存在</value>
  </data>
  <data name="txtForeignCommRateCash_S" xml:space="preserve">
    <value>現/股佣金(%)</value>
  </data>
  <data name="txtForeignCommRateIOU_S" xml:space="preserve">
    <value>M佣金(%)</value>
  </data>
  <data name="txtForeignDiscountRebateRate" xml:space="preserve">
    <value>折扣回贈(%)</value>
  </data>
  <data name="txtForeignDrinkRateCash_S" xml:space="preserve">
    <value>現/股積分(%)</value>
  </data>
  <data name="txtForeignDrinkRateIOU_S" xml:space="preserve">
    <value>M積分(%)</value>
  </data>
  <data name="txtForeignExtraCommRate" xml:space="preserve">
    <value>額外佣金(%)</value>
  </data>
  <data name="txtForeignExtraCondCreditDay" xml:space="preserve">
    <value>還款天數</value>
  </data>
  <data name="txtForeignExtraDiscountRebateRate" xml:space="preserve">
    <value>還款回贈(%)</value>
  </data>
  <data name="txtForeignExtraRollTime" xml:space="preserve">
    <value>轉碼倍數</value>
  </data>
  <data name="txtGameSiteCommissionTitle" xml:space="preserve">
    <value>海外佣金設定列表</value>
  </data>
  <data name="txtGameType" xml:space="preserve">
    <value>玩法種類</value>
  </data>
  <data name="wCurrRateProduct" xml:space="preserve">
    <value>兌換率(乘)</value>
  </data>
  <data name="txtForeignExtraCondLoss_tenk" xml:space="preserve">
    <value>實際下數(回贈) (萬)</value>
  </data>
  <data name="txtForeignTotalLoss_tenk" xml:space="preserve">
    <value>實際下數 (萬)</value>
  </data>
  <data name="wCurrRateDivide" xml:space="preserve">
    <value>兌換率(除)</value>
  </data>
  <data name="typeFOREIGNGAMESITE_Core" xml:space="preserve">
    <value>海外賭場記錄</value>
  </data>
  <data name="typeFOREIGNGAMESITEDTL_Core" xml:space="preserve">
    <value>海外佣金設定記錄</value>
  </data>
  <data name="action_VIEW_type" xml:space="preserve">
    <value>檢視</value>
  </data>
  <data name="global_txtCopy" xml:space="preserve">
    <value>複製</value>
  </data>
  <data name="txtForeignCommRateCash" xml:space="preserve">
    <value>現/股佣金(%)</value>
  </data>
  <data name="txtForeignCommRateIOU" xml:space="preserve">
    <value>M佣金(%)</value>
  </data>
  <data name="txtForeignDrinkRateCash" xml:space="preserve">
    <value>現/股積分(%)</value>
  </data>
  <data name="txtForeignDrinkRateIOU" xml:space="preserve">
    <value>M積分(%)</value>
  </data>
  <data name="txtForeignExtraCondLoss" xml:space="preserve">
    <value>實際下數(回贈)</value>
  </data>
  <data name="txtForeignExtraTitle" xml:space="preserve">
    <value>額外條件</value>
  </data>
  <data name="txtForeignGameValue" xml:space="preserve">
    <value>出碼/轉碼</value>
  </data>
  <data name="txtForeignTotalLoss" xml:space="preserve">
    <value>實際下數</value>
  </data>
  <data name="txtForeignGameValue_tenk" xml:space="preserve">
    <value>出碼/轉碼 (萬)</value>
  </data>
  <data name="typeBONUSPOINTSWORKLST_Core" xml:space="preserve">
    <value>贈送積分批核</value>
  </data>
  <data name="BonusPointStatusA" xml:space="preserve">
    <value>已批</value>
  </data>
  <data name="BonusPointStatusN" xml:space="preserve">
    <value>待批</value>
  </data>
  <data name="btnExport" xml:space="preserve">
    <value>匯出</value>
  </data>
  <data name="btnGenBonusPoints" xml:space="preserve">
    <value>生成贈送積分</value>
  </data>
  <data name="txtApprove" xml:space="preserve">
    <value>批核</value>
  </data>
  <data name="txtApprovePerson" xml:space="preserve">
    <value>批核人</value>
  </data>
  <data name="txtBonusPointsRealReceive" xml:space="preserve">
    <value>實取積分(萬)</value>
  </data>
  <data name="txtBonusPointsReceive" xml:space="preserve">
    <value>獲取積分(萬)</value>
  </data>
  <data name="txtBonusPointsSubReceive" xml:space="preserve">
    <value>下線獲取積分(萬)</value>
  </data>
  <data name="txtUpdateStatus" xml:space="preserve">
    <value>更改狀態</value>
  </data>
  <data name="wSelfRolling_100M" xml:space="preserve">
    <value>個人轉碼數(億)</value>
  </data>
  <data name="BonusPointStatusR" xml:space="preserve">
    <value>駁回</value>
  </data>
  <data name="btnApprove" xml:space="preserve">
    <value>確認</value>
  </data>
  <data name="typeTELBAPPROVALDTL_Core" xml:space="preserve">
    <value>電投確定</value>
  </data>
  <data name="global_btnReject" xml:space="preserve">
    <value>不批準</value>
  </data>
  <data name="txtTelbReservationData" xml:space="preserve">
    <value>預約資料</value>
  </data>
  <data name="txtTelbReservationDateTime" xml:space="preserve">
    <value>預約時間</value>
  </data>
  <data name="txtApproveData" xml:space="preserve">
    <value>批准資料</value>
  </data>
  <data name="txtCheckInData" xml:space="preserve">
    <value>在場資料</value>
  </data>
  <data name="txtTelbCName" xml:space="preserve">
    <value>客人姓名</value>
  </data>
  <data name="wExtNo" xml:space="preserve">
    <value>內線號碼</value>
  </data>
  <data name="wFunctionCd" xml:space="preserve">
    <value>權限號碼</value>
  </data>
  <data name="txtLoginExit" xml:space="preserve">
    <value>登出</value>
  </data>
  <data name="txtProfile" xml:space="preserve">
    <value>我的賬戶</value>
  </data>
  <data name="wOldPwd" xml:space="preserve">
    <value>舊密碼</value>
  </data>
  <data name="global_msgErrCustAlreadyExit" xml:space="preserve">
    <value>客人已離場，不能買碼</value>
  </data>
  <data name="global_msgAskSelectRolling" xml:space="preserve">
    <value>是否選取B數管理</value>
  </data>
  <data name="global_msgInfoManualTelbFix" xml:space="preserve">
    <value>是否已自行解凍結存款單,還借貸單及B數單</value>
  </data>
  <data name="global_msgInfoPrinterSettingNotFound" xml:space="preserve">
    <value>找不到相關的打印機設定</value>
  </data>
  <data name="msgInfoRecUpdated" xml:space="preserve">
    <value>記錄已更改</value>
  </data>
  <data name="typeBONUSPOINTSLOGDTL_Core" xml:space="preserve">
    <value>贈送積分管理</value>
  </data>
  <data name="typeROLEFUNCTIONITEM_Core" xml:space="preserve">
    <value>權限記錄</value>
  </data>
  <data name="txtAddRoleName" xml:space="preserve">
    <value>增加角色名稱</value>
  </data>
  <data name="txtSelectedRoleName" xml:space="preserve">
    <value>已選角色列表</value>
  </data>
  <data name="txtPwdMatchError" xml:space="preserve">
    <value>舊密碼不對</value>
  </data>
  <data name="global_msgInfoNorecord" xml:space="preserve">
    <value>沒有符合的資料</value>
  </data>
  <data name="global_txtTable" xml:space="preserve">
    <value>枱</value>
  </data>
  <data name="txtCopyRoleFunction" xml:space="preserve">
    <value>複製權限</value>
  </data>
  <data name="global_txtAskConfirmCloneRole" xml:space="preserve">
    <value>注意，此複製將會從角色{0}複製所有權限到角色{1}</value>
  </data>
  <data name="typeBONUSPOINTSAPPROVE_Core" xml:space="preserve">
    <value>贈送積分批核</value>
  </data>
  <data name="txtApproveStatus" xml:space="preserve">
    <value>批核狀態</value>
  </data>
  <data name="txtNotYetSend" xml:space="preserve">
    <value>未發送</value>
  </data>
  <data name="txtNumberOfRecord" xml:space="preserve">
    <value>記錄總數：</value>
  </data>
  <data name="typeROLEACTIONITEM_Core" xml:space="preserve">
    <value>權限動作記錄</value>
  </data>
  <data name="wActionType" xml:space="preserve">
    <value>動作號碼</value>
  </data>
  <data name="wActionTypeTitle" xml:space="preserve">
    <value>動作</value>
  </data>
  <data name="global_msgErrMissingOverdueDay" xml:space="preserve">
    <value>必須填上過期日數</value>
  </data>
  <data name="global_txtStartDate" xml:space="preserve">
    <value>開始日期</value>
  </data>
  <data name="txtOnlyShowSelected" xml:space="preserve">
    <value>僅顯示已選</value>
  </data>
  <data name="txtOtherCodeIn" xml:space="preserve">
    <value>其他戶口</value>
  </data>
  <data name="wChkAuthStaffCard" xml:space="preserve">
    <value>檢視授權人</value>
  </data>
  <data name="wChkIVR" xml:space="preserve">
    <value>檢視IVR</value>
  </data>
  <data name="wChkStaffCard" xml:space="preserve">
    <value>檢視經手人</value>
  </data>
  <data name="txtDocument" xml:space="preserve">
    <value>文件</value>
  </data>
  <data name="txtIncludeActionType" xml:space="preserve">
    <value>行動包含</value>
  </data>
  <data name="txtRoleRoot" xml:space="preserve">
    <value>權限目錄</value>
  </data>
  <data name="txtTotalWinLoss" xml:space="preserve">
    <value>總輸贏</value>
  </data>
  <data name="txtCreditControlAssess" xml:space="preserve">
    <value>信貸監控-評估及意見</value>
  </data>
  <data name="txtAgentAssess" xml:space="preserve">
    <value>評估及意見</value>
  </data>
  <data name="txtAgentFormat" xml:space="preserve">
    <value>{0}戶口號為：{1}</value>
  </data>
  <data name="type_ccAppStatus_NONE" xml:space="preserve">
    <value>未安排</value>
  </data>
  <data name="type_ccAppStatus_SUGGEST" xml:space="preserve">
    <value>建議</value>
  </data>
  <data name="type_ccAppStatus_INPROGRESS" xml:space="preserve">
    <value>安排中</value>
  </data>
  <data name="type_ccAppStatus_FAIL" xml:space="preserve">
    <value>不成功</value>
  </data>
  <data name="type_ccAppStatus_SUCCESS" xml:space="preserve">
    <value>已安排</value>
  </data>
  <data name="wAppointmentStatus" xml:space="preserve">
    <value>約見狀態</value>
  </data>
  <data name="wDelayDays" xml:space="preserve">
    <value>延期天數</value>
  </data>
  <data name="global_txtMTypeIOU" xml:space="preserve">
    <value>一般</value>
  </data>
  <data name="txtCapitalMType" xml:space="preserve">
    <value>借貸類型</value>
  </data>
  <data name="txtSuggestStopM" xml:space="preserve">
    <value>建議停M</value>
  </data>
  <data name="txtInterestProblem" xml:space="preserve">
    <value>利息問題</value>
  </data>
  <data name="txtMthIntreLate" xml:space="preserve">
    <value>月息綑綁</value>
  </data>
  <data name="action_UPDATEPOINT_type" xml:space="preserve">
    <value>保存坐標</value>
  </data>
  <data name="typeAGENTRELATION_Core" xml:space="preserve">
    <value>相關戶口</value>
  </data>
  <data name="typeAGENTREMARK_Core" xml:space="preserve">
    <value>戶口備註記錄</value>
  </data>
  <data name="typeCREDITCONTROL_Core" xml:space="preserve">
    <value>借貸追蹤</value>
  </data>
  <data name="typeLASTESTWINLOSS_Core" xml:space="preserve">
    <value>最近輸贏數</value>
  </data>
  <data name="typePRINTOUTBASE_Core" xml:space="preserve">
    <value>存卡/借貸單 列印座標設定</value>
  </data>
  <data name="typeROLLINGAMT_Core" xml:space="preserve">
    <value>轉碼概況</value>
  </data>
  <data name="txtAgentSpecialLabel" xml:space="preserve">
    <value>特別設定</value>
  </data>
  <data name="typeBPLAY_SETTLE_Core" xml:space="preserve">
    <value>B數結算</value>
  </data>
  <data name="action_SHIFTCUT_type" xml:space="preserve">
    <value>截更</value>
  </data>
  <data name="global_txtTelB" xml:space="preserve">
    <value>電投</value>
  </data>
  <data name="global_txtContinue" xml:space="preserve">
    <value>續場</value>
  </data>
  <data name="txtBasicInfo" xml:space="preserve">
    <value>基本資料</value>
  </data>
  <data name="msgNotAllowToSelectBoth" xml:space="preserve">
    <value>不能同時選取</value>
  </data>
  <data name="global_msgInfoExportColumnsZero" xml:space="preserve">
    <value>匯出的列數量為0或用了Template取不到列的值.</value>
  </data>
  <data name="typeBPlay_Exchange_Core" xml:space="preserve">
    <value>B數交易</value>
  </data>
  <data name="typeEXPTRANOTHERDTL_Core" xml:space="preserve">
    <value>欠前消費記錄</value>
  </data>
  <data name="txtRelatedRefNo" xml:space="preserve">
    <value>相關單號</value>
  </data>
  <data name="txtMthEndExpense" xml:space="preserve">
    <value>應付金額: </value>
  </data>
  <data name="txtMthEndForeignShare" xml:space="preserve">
    <value>積分結餘: </value>
  </data>
  <data name="txtMthEndInstantDtl" xml:space="preserve">
    <value>即出/月結明細</value>
  </data>
  <data name="txtMthEndNonShare" xml:space="preserve">
    <value>永利積分結餘: </value>
  </data>
  <data name="txtSharePoint" xml:space="preserve">
    <value>積分</value>
  </data>
  <data name="txtNonSharePoint" xml:space="preserve">
    <value>永利積分</value>
  </data>
  <data name="txtMthEndRptDetail" xml:space="preserve">
    <value>列印出糧下線細數表</value>
  </data>
  <data name="txtMthEndRptDetail_TryRun" xml:space="preserve">
    <value>列印預視出糧下線細數表</value>
  </data>
  <data name="txtMthEndShare" xml:space="preserve">
    <value>共通積分結餘: </value>
  </data>
  <data name="msgNotAllowToUseThisFunction" xml:space="preserve">
    <value>此場不能用有關能力</value>
  </data>
  <data name="msgInfoInputMissing" xml:space="preserve">
    <value>仍未輸入所有資料!</value>
  </data>
  <data name="global_txtCard" xml:space="preserve">
    <value>卡</value>
  </data>
  <data name="typeCREDITCONTROLLST_CONTACT_Core" xml:space="preserve">
    <value>新增聯絡</value>
  </data>
  <data name="typeCREDITCONTROLLST_ASSESS_Core" xml:space="preserve">
    <value>新增評估及意見</value>
  </data>
  <data name="typeCREDITCONTROL_ASSESS_Core" xml:space="preserve">
    <value>信貸監控-評估及意見</value>
  </data>
  <data name="global_txtRemarkForFunc" xml:space="preserve">
    <value>相關操作</value>
  </data>
  <data name="txtIdentityAndLevel" xml:space="preserve">
    <value>身份 / 級別</value>
  </data>
  <data name="txtShortFormAgent" xml:space="preserve">
    <value>代</value>
  </data>
  <data name="txtShortFormPlayer" xml:space="preserve">
    <value>玩</value>
  </data>
  <data name="txtMsgInvalidLangInput" xml:space="preserve">
    <value>不能為中文</value>
  </data>
  <data name="global_txtCannotAchieve" xml:space="preserve">
    <value>不到</value>
  </data>
  <data name="global_txtDetect" xml:space="preserve">
    <value>偵測</value>
  </data>
  <data name="typeAUTHORSOURCE_Core" xml:space="preserve">
    <value>歸屬地管理</value>
  </data>
  <data name="txtMenuList" xml:space="preserve">
    <value>二級菜單</value>
  </data>
  <data name="txtRootList" xml:space="preserve">
    <value>一級菜單</value>
  </data>
  <data name="txtSelectedMenu" xml:space="preserve">
    <value>選中菜單</value>
  </data>
  <data name="wRollTranStatus" xml:space="preserve">
    <value>帳房狀況</value>
  </data>
  <data name="txtSettleAtMacau" xml:space="preserve">
    <value>澳門結算</value>
  </data>
  <data name="global_txtLineGrp" xml:space="preserve">
    <value>組別</value>
  </data>
  <data name="global_txtOutstanding" xml:space="preserve">
    <value>未歸還額</value>
  </data>
  <data name="txtAccAmount10K" xml:space="preserve">
    <value>累計數(萬)</value>
  </data>
  <data name="txtAgent" xml:space="preserve">
    <value>會員賬號</value>
  </data>
  <data name="txtAgentCName" xml:space="preserve">
    <value>戶口名稱</value>
  </data>
  <data name="txtDueDate" xml:space="preserve">
    <value>到期日</value>
  </data>
  <data name="txtMarkTime" xml:space="preserve">
    <value>貸款時間</value>
  </data>
  <data name="txtOutstandingAmt" xml:space="preserve">
    <value>尚欠金額</value>
  </data>
  <data name="txtRptPrintLocation" xml:space="preserve">
    <value>列印地點</value>
  </data>
  <data name="txtTotSetAmt10K" xml:space="preserve">
    <value>歸還額(萬)</value>
  </data>
  <data name="txtUse10KBased" xml:space="preserve">
    <value>銀碼以(萬)為單位</value>
  </data>
  <data name="txtAddTime" xml:space="preserve">
    <value>新增時間</value>
  </data>
  <data name="txtBorrowerAmt" xml:space="preserve">
    <value>貸款金額</value>
  </data>
  <data name="txtBorrowerDate" xml:space="preserve">
    <value>貸款日期</value>
  </data>
  <data name="txtReturnDate" xml:space="preserve">
    <value>還款日期</value>
  </data>
  <data name="txtTotSetAmt" xml:space="preserve">
    <value>還款金額</value>
  </data>
  <data name="txtTypeGrp" xml:space="preserve">
    <value>類別(團)</value>
  </data>
  <data name="txtUplvlAgent" xml:space="preserve">
    <value>擔保戶口</value>
  </data>
  <data name="wRptBorrower" xml:space="preserve">
    <value>貸款人</value>
  </data>
  <data name="txtSubTotal_Agent" xml:space="preserve">
    <value>代理總計</value>
  </data>
  <data name="txtSubTotal_Card" xml:space="preserve">
    <value>卡類總計</value>
  </data>
  <data name="txtSubTotal_Day" xml:space="preserve">
    <value>日總計</value>
  </data>
  <data name="wCardType" xml:space="preserve">
    <value>卡類</value>
  </data>
  <data name="wTotalAmt10k" xml:space="preserve">
    <value>總計(萬)</value>
  </data>
  <data name="global_txtAgentCode" xml:space="preserve">
    <value>代理號碼</value>
  </data>
  <data name="txtChinsesName" xml:space="preserve">
    <value>中文名稱</value>
  </data>
  <data name="txtDailyRolling_10k" xml:space="preserve">
    <value>日轉碼(萬)</value>
  </data>
  <data name="txtDepositeDate" xml:space="preserve">
    <value>存款日期</value>
  </data>
  <data name="txtIOUNo" xml:space="preserve">
    <value>借貸單No</value>
  </data>
  <data name="txtMember" xml:space="preserve">
    <value>會員</value>
  </data>
  <data name="txtMonthlyRolling_10k" xml:space="preserve">
    <value>月轉碼(萬)</value>
  </data>
  <data name="txtMonthlyTranDate" xml:space="preserve">
    <value>每月過數日期</value>
  </data>
  <data name="txtRefNo" xml:space="preserve">
    <value>存單編號</value>
  </data>
  <data name="txtRptIOUAgentCode" xml:space="preserve">
    <value>借貸單代理號碼</value>
  </data>
  <data name="txtRptIOUAgentName" xml:space="preserve">
    <value>借貸單代理名稱</value>
  </data>
  <data name="txtTotalDeposite10k" xml:space="preserve">
    <value>總存碼(萬)</value>
  </data>
  <data name="wCIOURoll" xml:space="preserve">
    <value>公司IOU(萬)</value>
  </data>
  <data name="btnWriteUserID" xml:space="preserve">
    <value>寫入員工號碼</value>
  </data>
  <data name="txtHasPeriodUpdate" xml:space="preserve">
    <value>未更新週期</value>
  </data>
  <data name="txtNoRolling" xml:space="preserve">
    <value>沒有轉碼數</value>
  </data>
  <data name="txtProcessFailed" xml:space="preserve">
    <value>執行失敗</value>
  </data>
  <data name="txtFinished" xml:space="preserve">
    <value>完成</value>
  </data>
  <data name="txtMonetaryUnit" xml:space="preserve">
    <value>金額單位</value>
  </data>
  <data name="txtMsgOverSpentExpRem" xml:space="preserve">
    <value>*超額消費會在月息扣除</value>
  </data>
  <data name="typerMthEndExpenseTran_Core" xml:space="preserve">
    <value>戶口消費總結</value>
  </data>
  <data name="wCageBalance" xml:space="preserve">
    <value>廳結存</value>
  </data>
  <data name="global_txtUpdateRollsClient" xml:space="preserve">
    <value>系統更新</value>
  </data>
  <data name="global_txtAllowInputActionCode" xml:space="preserve">
    <value>允許輸入經手人</value>
  </data>
  <data name="txtRptMultiLang" xml:space="preserve">
    <value>報表語言</value>
  </data>
  <data name="global_msgStaffCardCheckSuccess" xml:space="preserve">
    <value>成功認證</value>
  </data>
  <data name="global_txtSuccess" xml:space="preserve">
    <value>成功</value>
  </data>
  <data name="typeCHANGECOMP_Core" xml:space="preserve">
    <value>轉場</value>
  </data>
  <data name="txtActionCodeChecking_Card" xml:space="preserve">
    <value>員工卡</value>
  </data>
  <data name="txtActionCodeChecking_Input" xml:space="preserve">
    <value>輸入經手人</value>
  </data>
  <data name="txtActionCodeChecking_RoleSettings" xml:space="preserve">
    <value>跟隨權限組別設定</value>
  </data>
  <data name="txtPersonalActionCodeSettings" xml:space="preserve">
    <value>經手人設定</value>
  </data>
  <data name="txtAgentCardLst" xml:space="preserve">
    <value>會員卡管理</value>
  </data>
  <data name="txtHolderCName" xml:space="preserve">
    <value>持卡人姓名</value>
  </data>
  <data name="txtCountryCode" xml:space="preserve">
    <value>國家碼</value>
  </data>
  <data name="txtCreditType" xml:space="preserve">
    <value>信用額方式</value>
  </data>
  <data name="typeAGENTCARDLST_Core" xml:space="preserve">
    <value>會員卡管理</value>
  </data>
  <data name="txtBdgroupStaff" xml:space="preserve">
    <value>業務發展部跟進同事</value>
  </data>
  <data name="txtMainStaff" xml:space="preserve">
    <value>主要跟進同事</value>
  </data>
  <data name="txtMarketStaff" xml:space="preserve">
    <value>市場部跟進同事</value>
  </data>
  <data name="txtOverseaStaff" xml:space="preserve">
    <value>海外部跟進同事</value>
  </data>
  <data name="txtRptDeposit" xml:space="preserve">
    <value>存(萬)</value>
  </data>
  <data name="txtRptWithdraw" xml:space="preserve">
    <value>提(萬)</value>
  </data>
  <data name="global_msgUpdateCountMessage" xml:space="preserve">
    <value>資訊更新</value>
  </data>
  <data name="global_txtAgentRollTran" xml:space="preserve">
    <value>潛質</value>
  </data>
  <data name="global_txtCounterRolling" xml:space="preserve">
    <value>櫃枱轉碼</value>
  </data>
  <data name="global_txtCustInOut" xml:space="preserve">
    <value>客人進/出場</value>
  </data>
  <data name="global_txtCustInOutDtl" xml:space="preserve">
    <value>客人進/出場</value>
  </data>
  <data name="global_txtCustTelB" xml:space="preserve">
    <value>電投</value>
  </data>
  <data name="global_txtFloorPlan" xml:space="preserve">
    <value>場面平面圖</value>
  </data>
  <data name="global_txtOperateTran" xml:space="preserve">
    <value>營運</value>
  </data>
  <data name="global_txtRollTran" xml:space="preserve">
    <value>轉碼</value>
  </data>
  <data name="global_txtTableTran" xml:space="preserve">
    <value>預約枱</value>
  </data>
  <data name="gobal_txtRemoteOperation" xml:space="preserve">
    <value>遙距指令</value>
  </data>
  <data name="txtRolltranDtl" xml:space="preserve">
    <value>轉碼明細</value>
  </data>
  <data name="global_txtPlace" xml:space="preserve">
    <value>場面</value>
  </data>
  <data name="txtAgentCardDtl" xml:space="preserve">
    <value>會員卡記錄</value>
  </data>
  <data name="wCardNo" xml:space="preserve">
    <value>卡號</value>
  </data>
  <data name="wAgentCardType" xml:space="preserve">
    <value>分類</value>
  </data>
  <data name="wAgentCardCreditTypeNone" xml:space="preserve">
    <value>沒有</value>
  </data>
  <data name="wAgentCardCreditTypeShare" xml:space="preserve">
    <value>共用</value>
  </data>
  <data name="wAgentCardCreditTypeSole" xml:space="preserve">
    <value>獨立</value>
  </data>
  <data name="wRecMembCard" xml:space="preserve">
    <value>已領取此咭</value>
  </data>
  <data name="wShowIOU_DnLv" xml:space="preserve">
    <value>IOU(下線)</value>
  </data>
  <data name="wShowRoll_DnLv" xml:space="preserve">
    <value>轉碼(下線)</value>
  </data>
  <data name="wShowDrink" xml:space="preserve">
    <value>食額</value>
  </data>
  <data name="global_msgPlaceShiftCutMessage" xml:space="preserve">
    <value>場面截更更新</value>
  </data>
  <data name="global_msgShiftCutMessage" xml:space="preserve">
    <value>截更更新</value>
  </data>
  <data name="txtDesc" xml:space="preserve">
    <value>描述</value>
  </data>
  <data name="txtExtName" xml:space="preserve">
    <value>格式</value>
  </data>
  <data name="txtOptionComp" xml:space="preserve">
    <value>可選公司</value>
  </data>
  <data name="txtPhotoName" xml:space="preserve">
    <value>圖片名</value>
  </data>
  <data name="typeMonitorPhotoLst_Core" xml:space="preserve">
    <value>帳房櫃檯廣告圖片管理</value>
  </data>
  <data name="txtMonitorPhoto" xml:space="preserve">
    <value>帳房櫃檯廣告圖片</value>
  </data>
  <data name="txtSMSTypeSet" xml:space="preserve">
    <value>訊息設定</value>
  </data>
  <data name="txtApp" xml:space="preserve">
    <value>App</value>
  </data>
  <data name="type_SMS_GRP_ACCOUNT" xml:space="preserve">
    <value>戶口訊息</value>
  </data>
  <data name="type_SMS_GRP_COMMISSION" xml:space="preserve">
    <value>佣金與即出</value>
  </data>
  <data name="type_SMS_GRP_EXPENSE" xml:space="preserve">
    <value>消費與積分</value>
  </data>
  <data name="type_SMS_GRP_IOU" xml:space="preserve">
    <value>信貸訊息</value>
  </data>
  <data name="type_SMS_GRP_OTHER" xml:space="preserve">
    <value>其他</value>
  </data>
  <data name="type_SMS_GRP_ROLLING" xml:space="preserve">
    <value>轉碼及上下數</value>
  </data>
  <data name="type_SMS_GRP_STORE" xml:space="preserve">
    <value>存取與利息</value>
  </data>
  <data name="type_SMS_GRP_TELEBET" xml:space="preserve">
    <value>電投訊息</value>
  </data>
  <data name="type_SMS_GRP_PROMO" xml:space="preserve">
    <value>推廣訊息</value>
  </data>
  <data name="txtSetCredit" xml:space="preserve">
    <value>設定信用額</value>
  </data>
  <data name="typeAGENTCARDCASHTRAN_Core" xml:space="preserve">
    <value>現金充值</value>
  </data>
  <data name="typeAGENTCARDCREDITTRAN_Core" xml:space="preserve">
    <value>會員卡臨時信用額</value>
  </data>
  <data name="global_txtCurrNumberOfCustomer" xml:space="preserve">
    <value>在場人客數</value>
  </data>
  <data name="txtMsgPhotoError" xml:space="preserve">
    <value>圖片還沒有上傳</value>
  </data>
  <data name="txtMsgIncorrectRollCombo" xml:space="preserve">
    <value>轉碼組合不存在</value>
  </data>
  <data name="global_txtPlaceAgent" xml:space="preserve">
    <value>在場代理</value>
  </data>
  <data name="txtStatusForeign" xml:space="preserve">
    <value>海外狀態</value>
  </data>
  <data name="txtStatusSMS" xml:space="preserve">
    <value>短訊狀態</value>
  </data>
  <data name="typeFOREIGNTRANLST_Core" xml:space="preserve">
    <value>海外管理</value>
  </data>
  <data name="txtTotalGameRolling" xml:space="preserve">
    <value>本場總轉碼</value>
  </data>
  <data name="txtTotalForeignGameWinLose" xml:space="preserve">
    <value>本場總上下</value>
  </data>
  <data name="action_SEARCH_ALL_type" xml:space="preserve">
    <value>搜尋所有</value>
  </data>
  <data name="wBindingType" xml:space="preserve">
    <value>綁定類型</value>
  </data>
  <data name="btnNewAssess" xml:space="preserve">
    <value>新增評估</value>
  </data>
  <data name="btnNewContacts" xml:space="preserve">
    <value>新增聯絡</value>
  </data>
  <data name="btnCheckUserID" xml:space="preserve">
    <value>檢查卡員工編號</value>
  </data>
  <data name="global_txtUserID" xml:space="preserve">
    <value>員工編號</value>
  </data>
  <data name="rOutstandingCommission" xml:space="preserve">
    <value>未出糧報表</value>
  </data>
  <data name="typeSETTLEMENTRPT_ReportGrp" xml:space="preserve">
    <value>月結報表</value>
  </data>
  <data name="typeROUTSTANDINGCOMMISSIONRPT_Report" xml:space="preserve">
    <value>未出糧報表</value>
  </data>
  <data name="txtNon_Assess" xml:space="preserve">
    <value>未評估戶口</value>
  </data>
  <data name="txtSummary" xml:space="preserve">
    <value>總結</value>
  </data>
  <data name="txtSearchDeposit" xml:space="preserve">
    <value>搜尋存單</value>
  </data>
  <data name="txtSearchMarker" xml:space="preserve">
    <value>搜尋借貸</value>
  </data>
  <data name="txtErrSearchChipI" xml:space="preserve">
    <value>沒找到存單</value>
  </data>
  <data name="txtErrSearchMarker" xml:space="preserve">
    <value>沒有找到借貸</value>
  </data>
  <data name="txtPenaltyM" xml:space="preserve">
    <value>罰息</value>
  </data>
  <data name="txtBeforeSettleLevelText" xml:space="preserve">
    <value>戶主是其</value>
  </data>
  <data name="txtSettleLevel98Text" xml:space="preserve">
    <value>獎金</value>
  </data>
  <data name="msgRptNeedCustomerName" xml:space="preserve">
    <value>客人必須填寫</value>
  </data>
  <data name="typeTABLETRAN_Core" xml:space="preserve">
    <value>貴賓廳管理</value>
  </data>
  <data name="wTableStatus" xml:space="preserve">
    <value>枱狀態</value>
  </data>
  <data name="wUsagedStatus" xml:space="preserve">
    <value>使用狀態</value>
  </data>
  <data name="txtShowBalance" xml:space="preserve">
    <value>顯示結存</value>
  </data>
  <data name="txtErrorRoomCName" xml:space="preserve">
    <value>房號不能為空！</value>
  </data>
  <data name="txtErrorTableCName" xml:space="preserve">
    <value>枱號不能為空！</value>
  </data>
  <data name="global_txtCapitalTranH" xml:space="preserve">
    <value>凍結存款單</value>
  </data>
  <data name="wOutstandAmountHKD" xml:space="preserve">
    <value>倘欠HKD(萬)</value>
  </data>
  <data name="typeFOREIGNTRANDTL_Core" xml:space="preserve">
    <value>海外記錄</value>
  </data>
  <data name="txtForeignWLDiscountRebateRate" xml:space="preserve">
    <value>下數回贈率</value>
  </data>
  <data name="txtForeignAirTicketRebate" xml:space="preserve">
    <value>機票回贈額</value>
  </data>
  <data name="txtReturnDay" xml:space="preserve">
    <value>還款天期</value>
  </data>
  <data name="txtGetRollingAndWinLoss" xml:space="preserve">
    <value>匯入轉碼及上下數</value>
  </data>
  <data name="txtTotalPoint" xml:space="preserve">
    <value>累積當地積分</value>
  </data>
  <data name="txtForeignTranDtlAllTourNoInfo" xml:space="preserve">
    <value>本團客人狀況</value>
  </data>
  <data name="txtForeignTranDtlCashOutLstTitle" xml:space="preserve">
    <value>海外現金支出列表</value>
  </data>
  <data name="txtForeignTranDtlExpOutLstTitle" xml:space="preserve">
    <value>海外消費列表</value>
  </data>
  <data name="txtForeignPerson" xml:space="preserve">
    <value>個別客戶開單</value>
  </data>
  <data name="txtForeignWholeTour" xml:space="preserve">
    <value>全團客戶開單</value>
  </data>
  <data name="txtForeignSettle" xml:space="preserve">
    <value>海外結算</value>
  </data>
  <data name="msgAskConfirmAddWholeTourOpening" xml:space="preserve">
    <value>此團第一次開場, 是否自動新增 ''全團開場'' 記錄?</value>
  </data>
  <data name="msgInfoMissingSite" xml:space="preserve">
    <value>需要揀選場地</value>
  </data>
  <data name="txtForeignGame" xml:space="preserve">
    <value>本單狀況</value>
  </data>
  <data name="global_ConfirmedInterestRateInProgress" xml:space="preserve">
    <value>存款月利息正在確認中, 並且發送訊息, 請於5至10分鐘後回來檢察狀態</value>
  </data>
  <data name="wOverdueExcludeFrozenAmtHKD" xml:space="preserve">
    <value>實際過期數</value>
  </data>
  <data name="global_txtCash_short" xml:space="preserve">
    <value>現</value>
  </data>
  <data name="txt_DAY" xml:space="preserve">
    <value>日數</value>
  </data>
  <data name="txtCutOffDate_Preview" xml:space="preserve">
    <value>截數日期(預視功能)</value>
  </data>
  <data name="txtShowDisable_Preview" xml:space="preserve">
    <value>顯示不收(預視功能)</value>
  </data>
  <data name="txtShowRemainPenalty_Preview" xml:space="preserve">
    <value>顯示罰息未還(預視功能)</value>
  </data>
  <data name="txtNonBPlayGameSite" xml:space="preserve">
    <value>此場地不能新增B數單</value>
  </data>
  <data name="global_txtSecondAuth" xml:space="preserve">
    <value>二次授權</value>
  </data>
  <data name="global_msgConnectTimeOut" xml:space="preserve">
    <value>[連接失敗]-未能成功連接系統</value>
  </data>
  <data name="global_txtInProgress" xml:space="preserve">
    <value>處理中</value>
  </data>
  <data name="global_txtProgressFinished" xml:space="preserve">
    <value>處理完成</value>
  </data>
  <data name="global_msgReconnect" xml:space="preserve">
    <value>重新連線</value>
  </data>
  <data name="txtUploadDate" xml:space="preserve">
    <value>上載日期</value>
  </data>
  <data name="txtUploadID2" xml:space="preserve">
    <value>證件</value>
  </data>
  <data name="txtAgentDoc" xml:space="preserve">
    <value>戶口文件</value>
  </data>
  <data name="typeAGENTDOC_Core" xml:space="preserve">
    <value>戶口文件</value>
  </data>
  <data name="global_txtReOption" xml:space="preserve">
    <value>重新選項</value>
  </data>
  <data name="rRollingDesc" xml:space="preserve">
    <value>各股東線轉碼數</value>
  </data>
  <data name="wCageDailyBal_10k" xml:space="preserve">
    <value>本場日轉碼(萬)</value>
  </data>
  <data name="txtOtherLineGrp" xml:space="preserve">
    <value>外線</value>
  </data>
  <data name="txtOtherMixLineGrp" xml:space="preserve">
    <value>雜線</value>
  </data>
  <data name="txtManila" xml:space="preserve">
    <value>馬尼拉</value>
  </data>
  <data name="txtRollingDate" xml:space="preserve">
    <value>轉碼日期</value>
  </data>
  <data name="typeRROLLINGSHARERPT_Report" xml:space="preserve">
    <value>股東轉碼報表</value>
  </data>
  <data name="txtPrevPhoto" xml:space="preserve">
    <value>上一張</value>
  </data>
  <data name="txtNextPhoto" xml:space="preserve">
    <value>下一張</value>
  </data>
  <data name="msgMissingIOURefNo" xml:space="preserve">
    <value>還未選擇借貸單, 繼續嗎 ?</value>
  </data>
  <data name="global_txtAlreadySent" xml:space="preserve">
    <value>已發出</value>
  </data>
  <data name="global_txtCanPreview" xml:space="preserve">
    <value>可預視</value>
  </data>
  <data name="global_txtPreparing" xml:space="preserve">
    <value>預備中</value>
  </data>
  <data name="global_msgDepositorChanged" xml:space="preserve">
    <value>存款人已更改</value>
  </data>
  <data name="txtCashFlow" xml:space="preserve">
    <value>資金流</value>
  </data>
  <data name="txtLocal" xml:space="preserve">
    <value>本地</value>
  </data>
  <data name="txtOverSea" xml:space="preserve">
    <value>跨區</value>
  </data>
  <data name="txtCurrCodeExchangeRemark" xml:space="preserve">
    <value>貨幣兌換</value>
  </data>
  <data name="txtTransferRemark" xml:space="preserve">
    <value>跨貨幣轉帳</value>
  </data>
  <data name="global_msgInfoRefNoOnlyAlphaNumeric" xml:space="preserve">
    <value>單號只接受英文字母和數目字</value>
  </data>
  <data name="global_msgCompanyNotMatch" xml:space="preserve">
    <value>不能修改其他公司</value>
  </data>
  <data name="wStoreType" xml:space="preserve">
    <value>存款類型</value>
  </data>
  <data name="global_txtAmountInvalid" xml:space="preserve">
    <value>數值不正確</value>
  </data>
  <data name="wTotalWithDraw_ChipB" xml:space="preserve">
    <value>存卡提款額</value>
  </data>
  <data name="wTotalWithDraw_ChipI" xml:space="preserve">
    <value>存單提款額</value>
  </data>
  <data name="global_msgErrFieldCannotBeZero" xml:space="preserve">
    <value>{0}不能爲零</value>
  </data>
  <data name="global_msgInfoFieldInputMissing" xml:space="preserve">
    <value>必需填入{0}</value>
  </data>
  <data name="global_msgInfoFieldSelectMissing" xml:space="preserve">
    <value>必需選取{0}</value>
  </data>
  <data name="msgInfoPlsWaitForChecking" xml:space="preserve">
    <value>請稍候... ...系統正在覆核資料 ...</value>
  </data>
  <data name="txtCashLoanAmt" xml:space="preserve">
    <value>個人借貸額(萬)</value>
  </data>
  <data name="txtMasterCasinoCreditAmt" xml:space="preserve">
    <value>Credit額(萬)</value>
  </data>
  <data name="wCreditAmt_10k" xml:space="preserve">
    <value>批額(萬)</value>
  </data>
  <data name="global_msgMissingFxRate_All" xml:space="preserve">
    <value>找不到此貨幣兌換匯率</value>
  </data>
  <data name="txt_ChipIData" xml:space="preserve">
    <value>存單資料</value>
  </data>
  <data name="txt_ChipBCageBalance" xml:space="preserve">
    <value>存卡各廳結存</value>
  </data>
  <data name="txt_IOUData" xml:space="preserve">
    <value>借貸單資料</value>
  </data>
  <data name="txt_MthInterestData" xml:space="preserve">
    <value>月息單資料</value>
  </data>
  <data name="txt_CapitalData" xml:space="preserve">
    <value>股本資料</value>
  </data>
  <data name="txt_FreezeData" xml:space="preserve">
    <value>凍M資料</value>
  </data>
  <data name="txt_HoldData" xml:space="preserve">
    <value>凍結存款資料</value>
  </data>
  <data name="txtWithDrawAmt_10K" xml:space="preserve">
    <value>提款額(萬)</value>
  </data>
  <data name="txtAllowFreeze" xml:space="preserve">
    <value>下線可凍借貸</value>
  </data>
  <data name="txtTotalFreezeAmt10K" xml:space="preserve">
    <value>凍結總額(萬)</value>
  </data>
  <data name="txtRepaymentType" xml:space="preserve">
    <value>還款類型</value>
  </data>
  <data name="txtStore_Cash10K" xml:space="preserve">
    <value>存C(萬)</value>
  </data>
  <data name="txtStore_Win10K" xml:space="preserve">
    <value>羸錢(萬)</value>
  </data>
  <data name="txtCheckingUpdate" xml:space="preserve">
    <value>檢查更新...</value>
  </data>
  <data name="txtProcessUpdate" xml:space="preserve">
    <value>正在更新...</value>
  </data>
  <data name="txtUpdated" xml:space="preserve">
    <value>已更新</value>
  </data>
  <data name="txtShowAllComm" xml:space="preserve">
    <value>所有正負佣金</value>
  </data>
  <data name="txtShowPositiveComm" xml:space="preserve">
    <value>只包括正佣金</value>
  </data>
  <data name="txtShowNegativeComm" xml:space="preserve">
    <value>只包括負佣金</value>
  </data>
  <data name="typeSETTLETRANCOMPLEXLST_Core" xml:space="preserve">
    <value>綜合出糧管理</value>
  </data>
  <data name="global_txtInput" xml:space="preserve">
    <value>輸入</value>
  </data>
  <data name="global_txtRemoteMachineInput" xml:space="preserve">
    <value>遙距輸入</value>
  </data>
  <data name="global_txtRemoteMachineInputPassword" xml:space="preserve">
    <value>遙距輸入</value>
  </data>
  <data name="txtPlease" xml:space="preserve">
    <value>請</value>
  </data>
  <data name="txtRetry" xml:space="preserve">
    <value>重新嘗試</value>
  </data>
  <data name="txtTimeExceedWaitPeriod" xml:space="preserve">
    <value>超過等候時間</value>
  </data>
  <data name="txtCashType" xml:space="preserve">
    <value>電投出碼類型</value>
  </data>
  <data name="txtTelNotify" xml:space="preserve">
    <value>電話通知</value>
  </data>
  <data name="wTelbBPlayRatio" xml:space="preserve">
    <value>代理B數佔成(%)</value>
  </data>
  <data name="global_msgNoPreview" xml:space="preserve">
    <value>文案沒有預覽功能</value>
  </data>
  <data name="global_PopUpSettleComplexRemark" xml:space="preserve">
    <value>綜合出糧備註</value>
  </data>
  <data name="global_txtNotFound" xml:space="preserve">
    <value>找不到</value>
  </data>
  <data name="global_txtPage" xml:space="preserve">
    <value>頁面</value>
  </data>
  <data name="typeTRANSFERCENTRE_Core" xml:space="preserve">
    <value>綜合理財確認</value>
  </data>
  <data name="wJoinDate" xml:space="preserve">
    <value>加入時間</value>
  </data>
  <data name="global_txtAgentJunket" xml:space="preserve">
    <value>加入記錄</value>
  </data>
  <data name="global_txtAgentJunketSales" xml:space="preserve">
    <value>每月轉碼</value>
  </data>
  <data name="wJunketCName" xml:space="preserve">
    <value>貴賓廳中文名</value>
  </data>
  <data name="wWinLossAmt" xml:space="preserve">
    <value>上下數(萬)</value>
  </data>
  <data name="txtStoreSettle" xml:space="preserve">
    <value>月結存回</value>
  </data>
  <data name="typeOTHERJUNKETLST_Core" xml:space="preserve">
    <value>其他貴賓廳管理</value>
  </data>
  <data name="wJunketCode" xml:space="preserve">
    <value>代號</value>
  </data>
  <data name="wJunket" xml:space="preserve">
    <value>貴賓廳</value>
  </data>
  <data name="typeOTHERJUNKETDTL_Core" xml:space="preserve">
    <value>其他貴賓廳管理</value>
  </data>
  <data name="txtAgentSummaryDetail" xml:space="preserve">
    <value>明細</value>
  </data>
  <data name="wAmountPoint" xml:space="preserve">
    <value>點數(萬)</value>
  </data>
  <data name="btnBPlayApprove" xml:space="preserve">
    <value>B數確認</value>
  </data>
  <data name="txtStoreMethod" xml:space="preserve">
    <value>存回方法</value>
  </data>
  <data name="txtIsStoreOther" xml:space="preserve">
    <value>存指定</value>
  </data>
  <data name="txtStoreLocal" xml:space="preserve">
    <value>存回當地</value>
  </data>
  <data name="txtStoreSettleCard" xml:space="preserve">
    <value>存回即出卡</value>
  </data>
  <data name="txtSettleCurExp" xml:space="preserve">
    <value>找本月消費</value>
  </data>
  <data name="typeSettleRemarkComplexDtl_Core" xml:space="preserve">
    <value>綜合出糧備註</value>
  </data>
  <data name="txtAmountCanFreeze" xml:space="preserve">
    <value>可凍結金額(萬)</value>
  </data>
  <data name="txtCashType_Credit" xml:space="preserve">
    <value>批額</value>
  </data>
  <data name="eChipTranBDtl" xml:space="preserve">
    <value>存卡記錄</value>
  </data>
  <data name="typeCHIPTRAN_B_DTL_Core" xml:space="preserve">
    <value>存卡記錄</value>
  </data>
  <data name="typeCHIPTRAN_I_DTL_Core" xml:space="preserve">
    <value>存單記錄</value>
  </data>
  <data name="global_txtChipWin" xml:space="preserve">
    <value>贏錢</value>
  </data>
  <data name="txtPlayer" xml:space="preserve">
    <value>玩家</value>
  </data>
  <data name="typeSettleTranComplexPreview_Core" xml:space="preserve">
    <value>出糧預覽</value>
  </data>
  <data name="wIOUNonOutstandingExpire" xml:space="preserve">
    <value>未過(M)</value>
  </data>
  <data name="wIOUOutstandingExpire" xml:space="preserve">
    <value>已過(M)</value>
  </data>
  <data name="wOperationNonOutstandingExpire" xml:space="preserve">
    <value>未過(營)</value>
  </data>
  <data name="wOperationOutstandingExpire" xml:space="preserve">
    <value>已過(營)</value>
  </data>
  <data name="wForeignNonOutstandingExpire" xml:space="preserve">
    <value>未過(海)</value>
  </data>
  <data name="wForeignOutstandingExpire" xml:space="preserve">
    <value>已過(海)</value>
  </data>
  <data name="wRollSource" xml:space="preserve">
    <value>借貸來源</value>
  </data>
  <data name="global_txtCustomer_SHORT" xml:space="preserve">
    <value>客</value>
  </data>
  <data name="txtAssCurMonCommission" xml:space="preserve">
    <value>調配當月佣金</value>
  </data>
  <data name="txtAssCurMonPoint" xml:space="preserve">
    <value>調配當月積分</value>
  </data>
  <data name="txtAustralia" xml:space="preserve">
    <value>澳洲</value>
  </data>
  <data name="txtAutoAdjust" xml:space="preserve">
    <value>自動判斷</value>
  </data>
  <data name="txtBFExpense" xml:space="preserve">
    <value>前累欠費</value>
  </data>
  <data name="txtBF_Card_Expense" xml:space="preserve">
    <value>前累卡欠費</value>
  </data>
  <data name="txtBFPoint" xml:space="preserve">
    <value>前累積分</value>
  </data>
  <data name="txtMthIntDrink" xml:space="preserve">
    <value>月息積分</value>
  </data>
  <data name="txtBFTelbDrink" xml:space="preserve">
    <value>前累電投積分</value>
  </data>
  <data name="txtCurTelbDrink" xml:space="preserve">
    <value>本月電投積分</value>
  </data>
  <data name="txtCardExpenseInCurMon" xml:space="preserve">
    <value>當月卡消費(內)</value>
  </data>
  <data name="txtCardExpenseOutCurMon" xml:space="preserve">
    <value>當月卡消費(外)</value>
  </data>
  <data name="txtDiffBetCommPoint" xml:space="preserve">
    <value>佣金減去積分結餘</value>
  </data>
  <data name="txtExpenseCurMon" xml:space="preserve">
    <value>當月消費</value>
  </data>
  <data name="txtFreezeRefNo" xml:space="preserve">
    <value>凍結借貸單號</value>
  </data>
  <data name="txtFrom" xml:space="preserve">
    <value>從</value>
  </data>
  <data name="txtKorea" xml:space="preserve">
    <value>韓國</value>
  </data>
  <data name="txtMacau" xml:space="preserve">
    <value>澳門</value>
  </data>
  <data name="txtPhilippines" xml:space="preserve">
    <value>菲律賓</value>
  </data>
  <data name="txtPointCurMon" xml:space="preserve">
    <value>本月積分</value>
  </data>
  <data name="txtPointsStatus" xml:space="preserve">
    <value>積分概況</value>
  </data>
  <data name="txtRelease" xml:space="preserve">
    <value>解除</value>
  </data>
  <data name="txtTotalPointSettle" xml:space="preserve">
    <value>合計現有積分結餘</value>
  </data>
  <data name="txtTransferIn" xml:space="preserve">
    <value>轉入</value>
  </data>
  <data name="txtUnCommon" xml:space="preserve">
    <value>不通用</value>
  </data>
  <data name="txtWithDrawAmt_10K_Store" xml:space="preserve">
    <value>存C提款額(萬)</value>
  </data>
  <data name="txtWithDrawAmt_10K_Win" xml:space="preserve">
    <value>贏錢提款額(萬)</value>
  </data>
  <data name="typeAGENTJUNKETDTL_Core" xml:space="preserve">
    <value>加入記錄管理</value>
  </data>
  <data name="typeAGENTJUNKETLST_Core" xml:space="preserve">
    <value>加入記錄</value>
  </data>
  <data name="typeAGENTJUNKETSALESDTL_Core" xml:space="preserve">
    <value>每月轉碼管理</value>
  </data>
  <data name="typeAGENTJUNKETSALESLST_Core" xml:space="preserve">
    <value>每月轉碼</value>
  </data>
  <data name="txtResetTelbCust_PWD" xml:space="preserve">
    <value>重設客人戶口密碼</value>
  </data>
  <data name="txtResetTelbShadow_PWD" xml:space="preserve">
    <value>重設關注戶口密碼</value>
  </data>
  <data name="btnClose" xml:space="preserve">
    <value>關閉</value>
  </data>
  <data name="msgActCodeChangeRequired" xml:space="preserve">
    <value>你的行動碼已經過期，必須先重設行動碼才能繼續使用。</value>
  </data>
  <data name="txtSettleDelete" xml:space="preserve">
    <value>刪除此結算</value>
  </data>
  <data name="typeAGENTSPECIAL_Core" xml:space="preserve">
    <value>特別設定</value>
  </data>
  <data name="typeBONUSPOINTSDTL_Core" xml:space="preserve">
    <value>贈送積分管理</value>
  </data>
  <data name="typeMONITORPHOTODTL_Core" xml:space="preserve">
    <value>帳房櫃檯廣告圖片管理</value>
  </data>
  <data name="typePROFILE_Core" xml:space="preserve">
    <value>我的賬戶</value>
  </data>
  <data name="txtProcess" xml:space="preserve">
    <value>進行</value>
  </data>
  <data name="txtUpdate" xml:space="preserve">
    <value>更新</value>
  </data>
  <data name="txtWill" xml:space="preserve">
    <value>將</value>
  </data>
  <data name="global_btnApply" xml:space="preserve">
    <value>應用</value>
  </data>
  <data name="txtPenaltyInterest" xml:space="preserve">
    <value>罰息(萬)</value>
  </data>
  <data name="btnImport" xml:space="preserve">
    <value>匯入</value>
  </data>
  <data name="txtCurrency" xml:space="preserve">
    <value>貨幣</value>
  </data>
  <data name="txtSameAgentTransfer" xml:space="preserve">
    <value>同館同戶口不能轉帳</value>
  </data>
  <data name="txtSameCurrCodeTransfer" xml:space="preserve">
    <value>相同貨幣不能轉帳</value>
  </data>
  <data name="global_txtRead" xml:space="preserve">
    <value>讀取</value>
  </data>
  <data name="txtShowInternal" xml:space="preserve">
    <value>顯示內部飛數</value>
  </data>
  <data name="txtCurrentSettleAmt_MthEnd_Inst" xml:space="preserve">
    <value>本月月結/即出扣除</value>
  </data>
  <data name="global_msgInfoSameAgent" xml:space="preserve">
    <value>戶口相同</value>
  </data>
  <data name="typePOPUPSTORECTRANSFERTO_Core" xml:space="preserve">
    <value>內部轉帳</value>
  </data>
  <data name="msgSystemBusy" xml:space="preserve">
    <value>系統繁忙中，請稍後再嘗試。</value>
  </data>
  <data name="msgRequestInProgress" xml:space="preserve">
    <value>該出碼要求已經正在進行中...</value>
  </data>
  <data name="msgDifferentUpdBy" xml:space="preserve">
    <value>經手人已不同，需要原本進行確認的經手人才可繼續。</value>
  </data>
  <data name="txtBFExpenseWithDnAgent" xml:space="preserve">
    <value>欠前消費(包下線)</value>
  </data>
  <data name="wCurExpRemain" xml:space="preserve">
    <value>當月新增欠費</value>
  </data>
  <data name="wTotExpRemain" xml:space="preserve">
    <value>欠費總數</value>
  </data>
  <data name="wBFExpByMth" xml:space="preserve">
    <value>欠費月份</value>
  </data>
  <data name="txtWarningExpense" xml:space="preserve">
    <value>**下線消費欠款必需由上線承擔</value>
  </data>
  <data name="msgInfoAgentHasNoIVRPwd" xml:space="preserve">
    <value>戶口未設定驗証密碼</value>
  </data>
  <data name="typeEXPENDCARDINOROUTSIDE_Core" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="wExpenseDate" xml:space="preserve">
    <value>消費日期</value>
  </data>
  <data name="wAmountActual_CRM" xml:space="preserve">
    <value>總值</value>
  </data>
  <data name="wExpAmount" xml:space="preserve">
    <value>消費額</value>
  </data>
  <data name="txtNotifyAgent_EveryTime" xml:space="preserve">
    <value>每次通知</value>
  </data>
  <data name="txtNotifyAgent_NoNeed" xml:space="preserve">
    <value>不用通知</value>
  </data>
  <data name="txtTelbBPlayRatio_0" xml:space="preserve">
    <value>零佔</value>
  </data>
  <data name="txtTelbBPlayRatio_50" xml:space="preserve">
    <value>半佔</value>
  </data>
  <data name="txtTelbBPlayRatio_100" xml:space="preserve">
    <value>全佔</value>
  </data>
  <data name="msgSCMCustExitYet" xml:space="preserve">
    <value>SCM 客人還未完成離場</value>
  </data>
  <data name="action_VOID_INTEREST_type" xml:space="preserve">
    <value>取消月息</value>
  </data>
  <data name="txtOwner" xml:space="preserve">
    <value>負責人</value>
  </data>
  <data name="txtTelbStartBet" xml:space="preserve">
    <value>第一口電投訊息</value>
  </data>
  <data name="txtTelbAgentDailySum" xml:space="preserve">
    <value>每日電投總結</value>
  </data>
  <data name="txtCashShort" xml:space="preserve">
    <value>現</value>
  </data>
  <data name="txtCiouShort" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="txtTelbWebPassword" xml:space="preserve">
    <value>電投管理網密碼</value>
  </data>
  <data name="btnSetPassword" xml:space="preserve">
    <value>設置密碼</value>
  </data>
  <data name="txtAgentTelbCurrency" xml:space="preserve">
    <value>代理電投貨幣</value>
  </data>
  <data name="glabal_msgSecurityCardRead" xml:space="preserve">
    <value>為保安理由, 請把員工卡放在卡機上進行確認</value>
  </data>
  <data name="glabal_msgMultipleCardReaderDetected_FAIL" xml:space="preserve">
    <value>員工卡設定未能成功，請檢查設定並按(Ctrl + R)重新進行</value>
  </data>
  <data name="typeRBPLAYCUSTWLRPT_Report" xml:space="preserve">
    <value>B數上下數報表</value>
  </data>
  <data name="txtBPlayCompSummary" xml:space="preserve">
    <value>來貨人總表</value>
  </data>
  <data name="txtCustChipTranB" xml:space="preserve">
    <value>電投存卡</value>
  </data>
  <data name="action_SMS_MANUAL_type" xml:space="preserve">
    <value>手動SMS</value>
  </data>
  <data name="glabal_msgOneCardReaderDetected" xml:space="preserve">
    <value>偵測到一部讀卡器，將此讀卡器定義為員工讀卡器？(若選否，將會定義為戶口讀卡器)</value>
  </data>
  <data name="msgDiffCustCurrCode" xml:space="preserve">
    <value>貨幣與客人貨幣不同</value>
  </data>
  <data name="global_txtCardReader" xml:space="preserve">
    <value>讀卡器</value>
  </data>
  <data name="global_CurrentIVR" xml:space="preserve">
    <value>當前IVR戶口</value>
  </data>
  <data name="txtSMSSendType" xml:space="preserve">
    <value>發送組別</value>
  </data>
  <data name="typeRAGENTSUMMARYCREDITINFORPT_Core" xml:space="preserve">
    <value>信貸額況列表</value>
  </data>
  <data name="typeRAGENTSUMMARYCREDITINFORPT_Report" xml:space="preserve">
    <value>信貸額況列表</value>
  </data>
  <data name="global_txtGambleTable" xml:space="preserve">
    <value>賭枱</value>
  </data>
  <data name="glabal_msgMultipleCardReaderDetected" xml:space="preserve">
    <value>偵測到多於一部讀卡器，現將進行員工讀卡器設定(一次性)，請將員工卡放到員工讀卡器上。確定進行？.</value>
  </data>
  <data name="global_txtCorrect" xml:space="preserve">
    <value>正確</value>
  </data>
  <data name="global_txtIsBusy" xml:space="preserve">
    <value>繁忙中</value>
  </data>
  <data name="global_txtNotSupport" xml:space="preserve">
    <value>數據不支持</value>
  </data>
  <data name="txtPlaceDate" xml:space="preserve">
    <value>場面日期</value>
  </data>
  <data name="msgErrIVRAgentNotFound" xml:space="preserve">
    <value>未設定認証戶口，請聯系資訊科技部解決。</value>
  </data>
  <data name="global_txtDepositor" xml:space="preserve">
    <value>存/取款人</value>
  </data>
  <data name="global_Salary" xml:space="preserve">
    <value>糧單</value>
  </data>
  <data name="wIDType_HKID" xml:space="preserve">
    <value>香港居民身份証</value>
  </data>
  <data name="wIDType_CNID" xml:space="preserve">
    <value>中國居民身份証</value>
  </data>
  <data name="wIDType_MOID" xml:space="preserve">
    <value>澳門居民身份証</value>
  </data>
  <data name="global_msgInfoIsNotAgentRove" xml:space="preserve">
    <value>該戶口不是巨額用戶,不能添加巨額客人</value>
  </data>
  <data name="txtSignalRConnected" xml:space="preserve">
    <value>推播資訊已連接</value>
  </data>
  <data name="txtSignalRDisconnected" xml:space="preserve">
    <value>連接不到推播資訊</value>
  </data>
  <data name="global_txtSystemRemark" xml:space="preserve">
    <value>系統備註</value>
  </data>
  <data name="txtMonthEndSettleComplexSMS" xml:space="preserve">
    <value>綜合出佣訊息</value>
  </data>
  <data name="txtMonthEndSettleCancelComplexSMS" xml:space="preserve">
    <value>取消綜合出佣訊息</value>
  </data>
  <data name="typeAGENTEXPCREDIT_LST_Core" xml:space="preserve">
    <value>消費批額管理</value>
  </data>
  <data name="txtAgentExpCredit" xml:space="preserve">
    <value>消費批額</value>
  </data>
  <data name="typePOPUPSMSPREVIEW_Core" xml:space="preserve">
    <value>發送短訊預覽</value>
  </data>
  <data name="txtShowRemark" xml:space="preserve">
    <value>顯示備註</value>
  </data>
  <data name="txtAllHoldChipAmt10K" xml:space="preserve">
    <value>全球凍結存款(萬)</value>
  </data>
  <data name="txtConfirmNotDeductExpense" xml:space="preserve">
    <value>確認不扣除消費嗎</value>
  </data>
  <data name="global_btnRegister" xml:space="preserve">
    <value>注冊</value>
  </data>
  <data name="global_btnResetRegister" xml:space="preserve">
    <value>重置注冊</value>
  </data>
  <data name="msgInfoIVRMissingTelExt" xml:space="preserve">
    <value>請設定有效的電話短號</value>
  </data>
  <data name="global_txtValue" xml:space="preserve">
    <value>設定</value>
  </data>
  <data name="typeSYSTABLELST_Core" xml:space="preserve">
    <value>系統管理</value>
  </data>
  <data name="wDesc" xml:space="preserve">
    <value>詳述</value>
  </data>
  <data name="global_txtSave" xml:space="preserve">
    <value>儲存</value>
  </data>
  <data name="txtNotInclude" xml:space="preserve">
    <value>不包括</value>
  </data>
  <data name="txtCancelExchange" xml:space="preserve">
    <value>取消交易</value>
  </data>
  <data name="typeTRANSFERALLTRAN_Core" xml:space="preserve">
    <value>綜合詳情</value>
  </data>
  <data name="txtCanEditByUser" xml:space="preserve">
    <value>可修改</value>
  </data>
  <data name="txtCannotEditByUser" xml:space="preserve">
    <value>不可修改</value>
  </data>
  <data name="txtIsEditByUser" xml:space="preserve">
    <value>是否可修改</value>
  </data>
  <data name="txtDelRemark" xml:space="preserve">
    <value>刪除備註</value>
  </data>
  <data name="global_msgWinLossInputAmountError" xml:space="preserve">
    <value>輸入輸贏數金額不正確</value>
  </data>
  <data name="global_msgInfoHasIOUBonusI" xml:space="preserve">
    <value>不能修改，本轉轉碼設有即贖獎金，請聯繫相關會計同事作出修改。</value>
  </data>
  <data name="global_msgInfoHasSettleInstant" xml:space="preserve">
    <value>此轉碼已即出，不能修改。</value>
  </data>
  <data name="type_CounterChipCode_AUD" xml:space="preserve">
    <value>澳幣</value>
  </data>
  <data name="type_CounterChipCode_AUDB" xml:space="preserve">
    <value>澳幣B</value>
  </data>
  <data name="type_CounterChipCode_HKD" xml:space="preserve">
    <value>港幣</value>
  </data>
  <data name="type_CounterChipCode_KRW" xml:space="preserve">
    <value>韓幣</value>
  </data>
  <data name="type_CounterChipCode_HKDA" xml:space="preserve">
    <value>港幣A</value>
  </data>
  <data name="type_CounterChipCode_HKDB" xml:space="preserve">
    <value>港幣B</value>
  </data>
  <data name="type_CounterChipCode_CNYA" xml:space="preserve">
    <value>人民幣A</value>
  </data>
  <data name="type_CounterChipCode_CNYB" xml:space="preserve">
    <value>人民幣B</value>
  </data>
  <data name="type_CounterChipCode_HKDCNYA" xml:space="preserve">
    <value>港/人A</value>
  </data>
  <data name="type_CounterChipCode_HKDCNYB" xml:space="preserve">
    <value>港/人B</value>
  </data>
  <data name="type_CounterChipCode_PHPA" xml:space="preserve">
    <value>披索A</value>
  </data>
  <data name="type_CounterChipCode_PHPB" xml:space="preserve">
    <value>披索B</value>
  </data>
  <data name="wCompanyRemark" xml:space="preserve">
    <value>本廳備註</value>
  </data>
  <data name="wDayIssueInterest" xml:space="preserve">
    <value>月息日</value>
  </data>
  <data name="wExpireDatetime" xml:space="preserve">
    <value>有效日期</value>
  </data>
  <data name="wGroupRemark" xml:space="preserve">
    <value>集團備註</value>
  </data>
  <data name="wIsIncludeCredit" xml:space="preserve">
    <value>計入戶口批額</value>
  </data>
  <data name="wNight" xml:space="preserve">
    <value>晚</value>
  </data>
  <data name="wRate" xml:space="preserve">
    <value>月息率(%)</value>
  </data>
  <data name="wRolling" xml:space="preserve">
    <value>轉碼數</value>
  </data>
  <data name="wStatusSMS" xml:space="preserve">
    <value>短訊狀態</value>
  </data>
  <data name="wWinLoss" xml:space="preserve">
    <value>輸贏數(萬)</value>
  </data>
  <data name="global_msgPlaceShiftTwentyHourOnce" xml:space="preserve">
    <value>場面截更20小時內只能截一次</value>
  </data>
  <data name="txtLessThanProcessPeriod" xml:space="preserve">
    <value>執行期小於等於</value>
  </data>
  <data name="txtChipSum" xml:space="preserve">
    <value>存碼總和</value>
  </data>
  <data name="msgInfoCapitalThisGame" xml:space="preserve">
    <value>本場本金用於讀場訊息</value>
  </data>
  <data name="msgInfoFollowStaffTelExmaple" xml:space="preserve">
    <value>需輸入區號, 格式為 +85395124578 </value>
  </data>
  <data name="wCapitalThisGame" xml:space="preserve">
    <value>本場本金(萬)</value>
  </data>
  <data name="wFollowStaffTel" xml:space="preserve">
    <value>查詢電話</value>
  </data>
  <data name="txtCommReturnIOU" xml:space="preserve">
    <value>出佣回M</value>
  </data>
  <data name="txtSendUpLevel" xml:space="preserve">
    <value>訊息同時發給上線</value>
  </data>
  <data name="txtRequestNotSend" xml:space="preserve">
    <value>特別不發送</value>
  </data>
  <data name="String1" xml:space="preserve">
    <value />
  </data>
  <data name="txtCapitalTranMBal" xml:space="preserve">
    <value>月息結餘</value>
  </data>
  <data name="txtCustCurrency" xml:space="preserve">
    <value>客人貨幣</value>
  </data>
  <data name="txtForeign_CompCommRate" xml:space="preserve">
    <value>海外佣金率</value>
  </data>
  <data name="txtOperate_CompCommRate" xml:space="preserve">
    <value>營運佣金率</value>
  </data>
  <data name="txtSyndicationBal" xml:space="preserve">
    <value>集團結餘</value>
  </data>
  <data name="wBorrowDateTime" xml:space="preserve">
    <value>借款時間</value>
  </data>
  <data name="wCapitalTempRemark" xml:space="preserve">
    <value>臺面數備註</value>
  </data>
  <data name="wGameSite" xml:space="preserve">
    <value>場地</value>
  </data>
  <data name="wTableName" xml:space="preserve">
    <value>枱名</value>
  </data>
  <data name="wWithdrawDate" xml:space="preserve">
    <value>提數日期</value>
  </data>
  <data name="txtCommNotEnoughPaidExpense" xml:space="preserve">
    <value>佣金不足以支付消費</value>
  </data>
  <data name="txtPayWay" xml:space="preserve">
    <value>付款方式</value>
  </data>
  <data name="wCashIOUContractNo" xml:space="preserve">
    <value>個人借貸合同號</value>
  </data>
  <data name="wIOUContractNo" xml:space="preserve">
    <value>借貸合同號</value>
  </data>
  <data name="typeOPERATINGAPPROVAL_Core" xml:space="preserve">
    <value>營運確認</value>
  </data>
  <data name="typeACCOUNTRPT_ReportGrp" xml:space="preserve">
    <value>會員報表</value>
  </data>
  <data name="typeRACCTYPEUPDNRPT_Report" xml:space="preserve">
    <value>會員每月升跌表</value>
  </data>
  <data name="wAssessors" xml:space="preserve">
    <value>評估人</value>
  </data>
  <data name="txtMemberCardLst" xml:space="preserve">
    <value>會員白卡列表</value>
  </data>
  <data name="wIsConfirmSelect" xml:space="preserve">
    <value>確認選擇</value>
  </data>
  <data name="global_SMSInProgress" xml:space="preserve">
    <value>發送訊息, 請於5至10分鐘後回來檢察狀態</value>
  </data>
  <data name="txtBTMCreateCardSuccess" xml:space="preserve">
    <value>BTM開卡成功</value>
  </data>
  <data name="txtSummaryLst" xml:space="preserve">
    <value>總表</value>
  </data>
  <data name="typeSETCREDIT_Core" xml:space="preserve">
    <value>設定信用額</value>
  </data>
  <data name="txtCreditControlLstV2" xml:space="preserve">
    <value>信貸監控V2</value>
  </data>
  <data name="txtPersonalData" xml:space="preserve">
    <value>個人資料</value>
  </data>
  <data name="typeCREDITCONTROLLSTV2_Core" xml:space="preserve">
    <value>信貸監控V2</value>
  </data>
  <data name="typeCREDITCONTROLLSTV3_Core" xml:space="preserve">
    <value>集團信貸</value>
  </data>
  <data name="btnShowIVRResult" xml:space="preserve">
    <value>顯示結果</value>
  </data>
  <data name="txtMsgCustStatusTerminated" xml:space="preserve">
    <value>客人狀態已終止</value>
  </data>
  <data name="global_txtPokerKingCard" xml:space="preserve">
    <value>Poker King卡</value>
  </data>
  <data name="wEmptyMemberCardNo" xml:space="preserve">
    <value>會員卡號碼(空白)</value>
  </data>
  <data name="txtBTM_CardType" xml:space="preserve">
    <value>卡類型</value>
  </data>
  <data name="txtBTM_MainCard" xml:space="preserve">
    <value>主卡</value>
  </data>
  <data name="txtBTM_SubCard" xml:space="preserve">
    <value>附屬卡</value>
  </data>
  <data name="txtBTM_ConsumptionMethod" xml:space="preserve">
    <value>消費方式</value>
  </data>
  <data name="txtBTM_NotAllowExpense" xml:space="preserve">
    <value>不能消費</value>
  </data>
  <data name="txtBTM_ShareCredit" xml:space="preserve">
    <value>共用信用額</value>
  </data>
  <data name="txtBTM_NonShareCredit" xml:space="preserve">
    <value>獨立信用額</value>
  </data>
  <data name="txtBTM_TelCountryCode" xml:space="preserve">
    <value>電話區號</value>
  </data>
  <data name="txtBTM_IsSMSSend" xml:space="preserve">
    <value>主卡是否接收附屬卡消費訊息</value>
  </data>
  <data name="txtBTM_IsActive" xml:space="preserve">
    <value>是否立即取卡</value>
  </data>
  <data name="txtBTM_TakeCardLater" xml:space="preserve">
    <value>稍後取卡</value>
  </data>
  <data name="txtBTM_TakeCardNow" xml:space="preserve">
    <value>立即取卡</value>
  </data>
  <data name="txtBTM_SelectedCardNo" xml:space="preserve">
    <value>已選會員卡編號</value>
  </data>
  <data name="txtSending" xml:space="preserve">
    <value>發送中</value>
  </data>
  <data name="txtSendSMSToQueProcs" xml:space="preserve">
    <value>正在發送短信，請半個小時後再查看</value>
  </data>
  <data name="txtCreditInfo" xml:space="preserve">
    <value>批額資料</value>
  </data>
  <data name="txtBackgroundDataAndContract" xml:space="preserve">
    <value>背景資料及合同</value>
  </data>
  <data name="global_txtShowRollingWholeLineGrp" xml:space="preserve">
    <value>顯示全線轉碼狀況</value>
  </data>
  <data name="typeNEWMEMBERCARDLST_Core" xml:space="preserve">
    <value>會員開卡</value>
  </data>
  <data name="global_fnEditAgentExt" xml:space="preserve">
    <value>編輯資訊</value>
  </data>
  <data name="txtMarketLevel" xml:space="preserve">
    <value>市場星級</value>
  </data>
  <data name="txtRollTranYearMth" xml:space="preserve">
    <value>月結結算週期</value>
  </data>
  <data name="txtExpUnlimitedCredit" xml:space="preserve">
    <value>消費無限額</value>
  </data>
  <data name="global_txtIsForeignGrp" xml:space="preserve">
    <value>是否外團數</value>
  </data>
  <data name="global_txtIsInternal" xml:space="preserve">
    <value>是否內部飛數</value>
  </data>
  <data name="txtIsForeignGrp" xml:space="preserve">
    <value>顯示外團數</value>
  </data>
  <data name="typeRAGENTLEVELINFORPT_Report" xml:space="preserve">
    <value>戶口身份級別報表</value>
  </data>
  <data name="wReturMarker" xml:space="preserve">
    <value>還本</value>
  </data>
  <data name="wPaidAmt" xml:space="preserve">
    <value>還款總數</value>
  </data>
  <data name="txtCutoff" xml:space="preserve">
    <value>截至</value>
  </data>
  <data name="txtTtlCount" xml:space="preserve">
    <value>紀錄總數</value>
  </data>
  <data name="txtBTMCreateCard" xml:space="preserve">
    <value>開BTM卡</value>
  </data>
  <data name="global_msgDuplicateCustomer" xml:space="preserve">
    <value>已有相同客人</value>
  </data>
  <data name="global_txtLastWinLoss" xml:space="preserve">
    <value>前更輸贏</value>
  </data>
  <data name="global_txtThisWinLoss" xml:space="preserve">
    <value>本更輸贏</value>
  </data>
  <data name="typeSYSSMSLST_Core" xml:space="preserve">
    <value>系統SMS管理</value>
  </data>
  <data name="typeSYSSMSEDIT_Core" xml:space="preserve">
    <value>系統SMS修改</value>
  </data>
  <data name="global_txtDayRate" xml:space="preserve">
    <value>即日匯率</value>
  </data>
  <data name="global_txtMonthRate" xml:space="preserve">
    <value>公司匯率</value>
  </data>
  <data name="txtRate" xml:space="preserve">
    <value>匯率</value>
  </data>
  <data name="txtSendEmaiFail" xml:space="preserve">
    <value>Email發送失敗</value>
  </data>
  <data name="typeRAGENTNAGSTORERPT_Report" xml:space="preserve">
    <value>可負數戶口報表</value>
  </data>
  <data name="txtNotSend" xml:space="preserve">
    <value>不發送</value>
  </data>
  <data name="txtDataAnalysis" xml:space="preserve">
    <value>數據分析</value>
  </data>
  <data name="txtReturnMarkerAnalysis" xml:space="preserve">
    <value>還款分析</value>
  </data>
  <data name="wCreditBlackList" xml:space="preserve">
    <value>信貸黑名單</value>
  </data>
  <data name="wExpAutoPay" xml:space="preserve">
    <value>消費自動付款</value>
  </data>
  <data name="wIntroducerCredit" xml:space="preserve">
    <value>介紹信貸</value>
  </data>
  <data name="wMarketLevelType" xml:space="preserve">
    <value>星級</value>
  </data>
  <data name="wShopSettleTran" xml:space="preserve">
    <value>停佣</value>
  </data>
  <data name="wStopExt" xml:space="preserve">
    <value>停止消費</value>
  </data>
  <data name="wStopM" xml:space="preserve">
    <value>停止借貸</value>
  </data>
  <data name="txtAccountTotal" xml:space="preserve">
    <value>戶口總額</value>
  </data>
  <data name="txtExpenseTotal" xml:space="preserve">
    <value>消費總額</value>
  </data>
  <data name="wOneToThirty" xml:space="preserve">
    <value>1-30天 </value>
  </data>
  <data name="wThirtyoneToSixty" xml:space="preserve">
    <value>31-60天 </value>
  </data>
  <data name="wSixtyoneToNinety" xml:space="preserve">
    <value>61-90天 </value>
  </data>
  <data name="wNinety" xml:space="preserve">
    <value>90天以上 </value>
  </data>
  <data name="txtReturnProportionDtlChart" xml:space="preserve">
    <value>回款過期比例圖</value>
  </data>
  <data name="txtReturnProportionChart" xml:space="preserve">
    <value>回款比例圖</value>
  </data>
  <data name="txtNameNotAllowNumericOnly" xml:space="preserve">
    <value>中英文(姓氏/名字), 不含有數字組合</value>
  </data>
  <data name="txtDepartmentLst" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="wDeptCode" xml:space="preserve">
    <value>部門編號</value>
  </data>
  <data name="wDeptName" xml:space="preserve">
    <value>部門名稱</value>
  </data>
  <data name="wRateType" xml:space="preserve">
    <value>匯率類型</value>
  </data>
  <data name="txtDisplayExpired" xml:space="preserve">
    <value>顯示已過期</value>
  </data>
  <data name="typeCHARTOFACC_Core" xml:space="preserve">
    <value>帳項資料圖</value>
  </data>
  <data name="global_txtBalanceSheet" xml:space="preserve">
    <value>資產負責表</value>
  </data>
  <data name="txtAccountGroup" xml:space="preserve">
    <value>帳項組</value>
  </data>
  <data name="txtAccountingCredit" xml:space="preserve">
    <value>貸項</value>
  </data>
  <data name="txtAccountingDebit" xml:space="preserve">
    <value>借項</value>
  </data>
  <data name="txtAccountName" xml:space="preserve">
    <value>帳項名稱</value>
  </data>
  <data name="txtAccountSeq" xml:space="preserve">
    <value>帳項排序</value>
  </data>
  <data name="txtDebitCredit" xml:space="preserve">
    <value>借/貸</value>
  </data>
  <data name="txtManufacturingAcc" xml:space="preserve">
    <value>工業帳目</value>
  </data>
  <data name="txtTradingAccount" xml:space="preserve">
    <value>貿易帳目</value>
  </data>
  <data name="txtUpperAccountCode" xml:space="preserve">
    <value>上線帳項碼</value>
  </data>
  <data name="typeACCOUNTING_Core" xml:space="preserve">
    <value>會計</value>
  </data>
  <data name="global_msgAccountingCodeInvalid" xml:space="preserve">
    <value>帳項碼及上線帳項碼必須正確</value>
  </data>
  <data name="txtEventCode" xml:space="preserve">
    <value>事項碼</value>
  </data>
  <data name="txtVouCreditAmt" xml:space="preserve">
    <value>貸項額</value>
  </data>
  <data name="txtVouDebitAmt" xml:space="preserve">
    <value>借項額</value>
  </data>
  <data name="typeVOUDTLLSTENQUIRY_Core" xml:space="preserve">
    <value>票單查詢</value>
  </data>
  <data name="wVouId" xml:space="preserve">
    <value>票單編號</value>
  </data>
  <data name="txtWithOutAccountingRole" xml:space="preserve">
    <value>沒有會計權限</value>
  </data>
  <data name="txtImageManage" xml:space="preserve">
    <value>圖像管理</value>
  </data>
  <data name="txtImportRollexSummaryValues" xml:space="preserve">
    <value>匯入RollsMary系統數</value>
  </data>
  <data name="txtReview" xml:space="preserve">
    <value>覆核</value>
  </data>
  <data name="wVouPrefix" xml:space="preserve">
    <value>字首</value>
  </data>
  <data name="wVouYearMth" xml:space="preserve">
    <value>年月</value>
  </data>
  <data name="txtAccountCode" xml:space="preserve">
    <value>帳項碼</value>
  </data>
  <data name="typeFXRATELST_Core" xml:space="preserve">
    <value>匯率管理</value>
  </data>
  <data name="typeVOULST_Core" xml:space="preserve">
    <value>票單管理</value>
  </data>
  <data name="typeCOMPEXPSHARELST_Core" xml:space="preserve">
    <value>公司比例設定</value>
  </data>
  <data name="wCompGrp" xml:space="preserve">
    <value>公司組</value>
  </data>
  <data name="wShareRate" xml:space="preserve">
    <value>比例</value>
  </data>
  <data name="txtDepartmentDtl" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="typeDEPARTMENTDTL_Core" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="typeDEPARTMENTLST_Core" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="String2" xml:space="preserve">
    <value />
  </data>
  <data name="wExpireYearMth" xml:space="preserve">
    <value>到期時間</value>
  </data>
  <data name="wYearMthEffective" xml:space="preserve">
    <value>生效月份</value>
  </data>
  <data name="wYearMthExpire" xml:space="preserve">
    <value>到期月份</value>
  </data>
  <data name="txtAlreadyReviewed" xml:space="preserve">
    <value>已覆核</value>
  </data>
  <data name="txtAutoGenVoucher" xml:space="preserve">
    <value>自動票單</value>
  </data>
  <data name="txtInputVoucherCOA" xml:space="preserve">
    <value>輸入票單所屬帳項碼</value>
  </data>
  <data name="txtInputVoucherComp" xml:space="preserve">
    <value>輸入票單所屬公司</value>
  </data>
  <data name="txtNumOfRecords" xml:space="preserve">
    <value>筆記錄</value>
  </data>
  <data name="txtVoucherNo" xml:space="preserve">
    <value>票據編號</value>
  </data>
  <data name="txtVoucherSumEach" xml:space="preserve">
    <value>各項總數</value>
  </data>
  <data name="typeVOUDTL_Core" xml:space="preserve">
    <value>票單記錄</value>
  </data>
  <data name="txtAccountingYear" xml:space="preserve">
    <value>會計年度</value>
  </data>
  <data name="txtAccountingYearMth" xml:space="preserve">
    <value>會計週期</value>
  </data>
  <data name="typePROFITANDLOSS_Core" xml:space="preserve">
    <value>什支表</value>
  </data>
  <data name="txtCHIPTRAN_CONVERT" xml:space="preserve">
    <value>存卡類轉互</value>
  </data>
  <data name="type_C_TO_W" xml:space="preserve">
    <value>存C 轉換成 羸錢</value>
  </data>
  <data name="type_W_TO_C" xml:space="preserve">
    <value>羸錢 轉換成 存C</value>
  </data>
  <data name="wResponseStatus" xml:space="preserve">
    <value>接聽狀態</value>
  </data>
  <data name="txtCEO" xml:space="preserve">
    <value>總裁</value>
  </data>
  <data name="txtCEO_CENTRAL" xml:space="preserve">
    <value>總裁+信貸</value>
  </data>
  <data name="txtTEXTREPLAY" xml:space="preserve">
    <value>訊息回覆</value>
  </data>
  <data name="txtVoiceMessage" xml:space="preserve">
    <value>留言信箱</value>
  </data>
  <data name="txtStartCannotContact" xml:space="preserve">
    <value>開始聯絡不上</value>
  </data>
  <data name="txtStartAppointment" xml:space="preserve">
    <value>開始通知約見</value>
  </data>
  <data name="txtReject" xml:space="preserve">
    <value>拒絕</value>
  </data>
  <data name="txtNotice" xml:space="preserve">
    <value>提示</value>
  </data>
  <data name="txtInputTotal" xml:space="preserve">
    <value>所輸入總數</value>
  </data>
  <data name="global_msgBothCreditDebitZeroh" xml:space="preserve">
    <value>借項額和貸項額同時為零</value>
  </data>
  <data name="global_msgDebitCreditMistmatch" xml:space="preserve">
    <value>借項額需與貸項額相同 (如全部票單都是借項或貸項的其中一種，系統會自動計算所需差額票單)</value>
  </data>
  <data name="global_msgDebitCreditMistmatchRollexImport" xml:space="preserve">
    <value>借項額需與貸項額相同</value>
  </data>
  <data name="global_msgMoreThanOneCurrency" xml:space="preserve">
    <value>不能輸入多於一個貨幣</value>
  </data>
  <data name="txtAuStoreBookCustomer" xml:space="preserve">
    <value>大薄(客戶)</value>
  </data>
  <data name="txtAuStoreBookStore" xml:space="preserve">
    <value>大薄(內部)</value>
  </data>
  <data name="txtCashTypeCC" xml:space="preserve">
    <value>現金碼</value>
  </data>
  <data name="txtCasinoCredit" xml:space="preserve">
    <value>賭場CREDIT</value>
  </data>
  <data name="txtNNChipForeign" xml:space="preserve">
    <value>外館碼</value>
  </data>
  <data name="typeBALANCESHEET_Core" xml:space="preserve">
    <value>資產負債表</value>
  </data>
  <data name="wPromissoryNote" xml:space="preserve">
    <value>本票</value>
  </data>
  <data name="global_btnDeleteVoucher" xml:space="preserve">
    <value>刪除票據(包括所有明細)</value>
  </data>
  <data name="typePROFITANDLOSSSTANDARD_Core" xml:space="preserve">
    <value>損益表</value>
  </data>
  <data name="txtSolutionCount" xml:space="preserve">
    <value>約見方案達標次數</value>
  </data>
  <data name="txtFailSolution" xml:space="preserve">
    <value>不達標</value>
  </data>
  <data name="txtCreditControlPenaltyProblem" xml:space="preserve">
    <value>信貸監控-利息問題</value>
  </data>
  <data name="txtPenaltyProblem" xml:space="preserve">
    <value>利息問題</value>
  </data>
  <data name="typeCREDITCONTROLLSTV2_PENALTYPROBLEM_Core" xml:space="preserve">
    <value>新增利息問題</value>
  </data>
  <data name="typeCREDITCONTROLLSTV2_NOTICE_Core" xml:space="preserve">
    <value>新增通報機制</value>
  </data>
  <data name="typeCREDITCONTROLLSTV2_TMPCREDIT_Core" xml:space="preserve">
    <value>新增臨時額</value>
  </data>
  <data name="typeCREDITCONTROL_TMPCREDIT_Core" xml:space="preserve">
    <value>信貸監控-臨時額</value>
  </data>
  <data name="typeCREDITCONTROL_PENALTYPROBLEM_Core" xml:space="preserve">
    <value>信貸監控-利息問題</value>
  </data>
  <data name="typeCREDITCONTROL_NOTICE_Core" xml:space="preserve">
    <value>信貸監控-通報機制</value>
  </data>
  <data name="txtCreditControlNotice" xml:space="preserve">
    <value>通報機制</value>
  </data>
  <data name="txtNoticeList" xml:space="preserve">
    <value>通報紀錄</value>
  </data>
  <data name="txtWavePenalty" xml:space="preserve">
    <value>免息金額</value>
  </data>
  <data name="wTmpCreditAmt" xml:space="preserve">
    <value>額度</value>
  </data>
  <data name="wCreditDate" xml:space="preserve">
    <value>批額日期</value>
  </data>
  <data name="wLastReturn" xml:space="preserve">
    <value>最近回數(萬)</value>
  </data>
  <data name="wLastReturnAmt" xml:space="preserve">
    <value>最近回數</value>
  </data>
  <data name="wCenterRemark" xml:space="preserve">
    <value>信貸部建議</value>
  </data>
  <data name="wCEORemark" xml:space="preserve">
    <value>總裁致電後回覆</value>
  </data>
  <data name="wNoticeDate" xml:space="preserve">
    <value>通知日期</value>
  </data>
  <data name="wCreditTmpAmt" xml:space="preserve">
    <value>現時臨時額(萬)</value>
  </data>
  <data name="wCreditLimitDate" xml:space="preserve">
    <value>期限</value>
  </data>
  <data name="wCreditMarker" xml:space="preserve">
    <value>可簽大數(萬)</value>
  </data>
  <data name="txtMethordAndMeeting" xml:space="preserve">
    <value>方案及約見紀錄</value>
  </data>
  <data name="txtHKDToCNY" xml:space="preserve">
    <value>港幣兌人民幣</value>
  </data>
  <data name="txtCNYToHKD" xml:space="preserve">
    <value>人民幣兌港幣</value>
  </data>
  <data name="txt60Return" xml:space="preserve">
    <value>60天無回款</value>
  </data>
  <data name="wCreditOver" xml:space="preserve">
    <value>額度屆滿</value>
  </data>
  <data name="wCreditLimt" xml:space="preserve">
    <value>額度</value>
  </data>
  <data name="txtNewResponseOnResponse" xml:space="preserve">
    <value>最新情況/不達標原因</value>
  </data>
  <data name="txtRollingAnalysis" xml:space="preserve">
    <value>轉碼分析</value>
  </data>
  <data name="txtContactAnalysis" xml:space="preserve">
    <value>聯絡分析</value>
  </data>
  <data name="txtAppointmentAnalysis" xml:space="preserve">
    <value>約見分析</value>
  </data>
  <data name="txtContactChart" xml:space="preserve">
    <value>接聽狀態比例圖</value>
  </data>
  <data name="txtNoContantAnalysis" xml:space="preserve">
    <value>聯絡不上紀錄</value>
  </data>
  <data name="wAppointmentCount" xml:space="preserve">
    <value>約見次數</value>
  </data>
  <data name="txtLastAppointmentDate" xml:space="preserve">
    <value>距離上次約見時間</value>
  </data>
  <data name="txtCanContact" xml:space="preserve">
    <value>聯絡上</value>
  </data>
  <data name="txtCannotContact" xml:space="preserve">
    <value>聯絡不上</value>
  </data>
  <data name="global_msgInputAccCode" xml:space="preserve">
    <value>必須輸入帳項碼</value>
  </data>
  <data name="global_msgInputComp" xml:space="preserve">
    <value>必須輸入公司</value>
  </data>
  <data name="global_msgInputCurrCode" xml:space="preserve">
    <value>必須輸入貨幣</value>
  </data>
  <data name="global_msgReviewDifUpdby" xml:space="preserve">
    <value>覆核經手人需要與經手人不同</value>
  </data>
  <data name="txtAutoGeneratedVoucher" xml:space="preserve">
    <value>**此單是因為借貸項不相等而自動產生的票單</value>
  </data>
  <data name="typeACTIONVOUDTL_Core" xml:space="preserve">
    <value>票單管理</value>
  </data>
  <data name="typePOPUPLIST_Core" xml:space="preserve">
    <value>详情</value>
  </data>
  <data name="global_msgBlock_CWO_TSO" xml:space="preserve">
    <value>暫存/未取 請使用綜合理財</value>
  </data>
  <data name="txtContactProportion" xml:space="preserve">
    <value>已接聽比例</value>
  </data>
  <data name="txtNonContactProportion" xml:space="preserve">
    <value>未接聽比例</value>
  </data>
  <data name="txtRateDtl" xml:space="preserve">
    <value>匯率詳情</value>
  </data>
  <data name="global_msgPhotoUploaded" xml:space="preserve">
    <value>圖片已上載</value>
  </data>
  <data name="typeCRM_Core" xml:space="preserve">
    <value>CRM</value>
  </data>
  <data name="typeTEAMMEMBERLST_Core" xml:space="preserve">
    <value>部門組別管理</value>
  </data>
  <data name="txtTeamMemberLst" xml:space="preserve">
    <value>部門組別管理</value>
  </data>
  <data name="txtCRMDept" xml:space="preserve">
    <value>部門</value>
  </data>
  <data name="txtCRMDeptCode" xml:space="preserve">
    <value>部門編碼</value>
  </data>
  <data name="txtCRMPlace" xml:space="preserve">
    <value>場館</value>
  </data>
  <data name="txtCRMSMSOption" xml:space="preserve">
    <value>SMS選項</value>
  </data>
  <data name="txtCRMStaffCode" xml:space="preserve">
    <value>員工號碼</value>
  </data>
  <data name="txtCRMTeam" xml:space="preserve">
    <value>組別名稱</value>
  </data>
  <data name="txtCRMTeamCrtDate" xml:space="preserve">
    <value>建立時間</value>
  </data>
  <data name="txtCRMTeamStatus" xml:space="preserve">
    <value>狀態原因</value>
  </data>
  <data name="txtCRMUsrDisplayName" xml:space="preserve">
    <value>顯示名稱</value>
  </data>
  <data name="txtCRMUsrFullName" xml:space="preserve">
    <value>全名</value>
  </data>
  <data name="txtCRMPrivateTel" xml:space="preserve">
    <value>個人電話</value>
  </data>
  <data name="txtCRMSMSTel" xml:space="preserve">
    <value>SMS電話</value>
  </data>
  <data name="typeTEAMMEMBERDTL_Core" xml:space="preserve">
    <value>部門組別管理</value>
  </data>
  <data name="txtCRMCountry" xml:space="preserve">
    <value>地區</value>
  </data>
  <data name="txtCRMNormal" xml:space="preserve">
    <value>一般</value>
  </data>
  <data name="txtCRMOtherMembers" xml:space="preserve">
    <value>其他人員</value>
  </data>
  <data name="txtCRMTeamMembers" xml:space="preserve">
    <value>組別人員</value>
  </data>
  <data name="txtPointType" xml:space="preserve">
    <value>積分類</value>
  </data>
  <data name="txtCRMActivate" xml:space="preserve">
    <value>使用中</value>
  </data>
  <data name="txtCRMSuspend" xml:space="preserve">
    <value>暫停使用</value>
  </data>
  <data name="wGame" xml:space="preserve">
    <value>遊戲</value>
  </data>
  <data name="txtMarkerAndCreditAnalysis" xml:space="preserve">
    <value>簽碼及批額分析</value>
  </data>
  <data name="txtMarkerDayAndProportion" xml:space="preserve">
    <value>過期次數及比例%</value>
  </data>
  <data name="txtAvgExpireDay" xml:space="preserve">
    <value>平均過期天數</value>
  </data>
  <data name="txtAvgExpireAmtProportion" xml:space="preserve">
    <value>過期金額比例%</value>
  </data>
  <data name="txtAvgExpireMaxMumberDay" xml:space="preserve">
    <value>過期最長天數</value>
  </data>
  <data name="txtLstMarkerDayAndAmt" xml:space="preserve">
    <value>最後開工時間及金額</value>
  </data>
  <data name="txtHaveCreditNoUseDay" xml:space="preserve">
    <value>有額度而無用的天數</value>
  </data>
  <data name="txtOneMth" xml:space="preserve">
    <value>一個月</value>
  </data>
  <data name="txtThreeMth" xml:space="preserve">
    <value>三個月</value>
  </data>
  <data name="txtSixMth" xml:space="preserve">
    <value>六個月</value>
  </data>
  <data name="txtTotalMarkerAmt" xml:space="preserve">
    <value>累計簽碼金額</value>
  </data>
  <data name="txtGameType1" xml:space="preserve">
    <value>百家樂</value>
  </data>
  <data name="RollSourceType_CAPITAL" xml:space="preserve">
    <value>股本</value>
  </data>
  <data name="RollSourceType_CAPITAL_M" xml:space="preserve">
    <value>股本M</value>
  </data>
  <data name="RollSourceType_CREDIT" xml:space="preserve">
    <value>批額</value>
  </data>
  <data name="RollSourceType_HOLD_COMM" xml:space="preserve">
    <value>HOLD佣出M</value>
  </data>
  <data name="RollSourceType_CIO" xml:space="preserve">
    <value>公司U</value>
  </data>
  <data name="RollSourceType_IOU" xml:space="preserve">
    <value>IOU</value>
  </data>
  <data name="RollSourceType_HOLD_STORE" xml:space="preserve">
    <value>凍咭</value>
  </data>
  <data name="RollSourceType_MTHINT" xml:space="preserve">
    <value>月息</value>
  </data>
  <data name="RollSourceType_MTHINT_M" xml:space="preserve">
    <value>月息M</value>
  </data>
  <data name="RollSourceType_MASTER" xml:space="preserve">
    <value>娛樂場額</value>
  </data>
  <data name="global_msgFieldACannotMatchFieldB" xml:space="preserve">
    <value>{0}不能與{1}相同</value>
  </data>
  <data name="txtPrintAppForm" xml:space="preserve">
    <value>開戶申請表</value>
  </data>
  <data name="wIsAttention" xml:space="preserve">
    <value>專案</value>
  </data>
  <data name="action_ATTENTION_type" xml:space="preserve">
    <value>專案</value>
  </data>
  <data name="typeCOMPCREDITDASHBOARD_Core" xml:space="preserve">
    <value>集團信貸Dashboard</value>
  </data>
  <data name="Place_txtBirthday" xml:space="preserve">
    <value>生日</value>
  </data>
  <data name="txtCashNotify" xml:space="preserve">
    <value>現金</value>
  </data>
  <data name="typePLACE_NOTIFYAPPROVAL_Core" xml:space="preserve">
    <value>現金確認</value>
  </data>
  <data name="action_APPROVEDATA_type" xml:space="preserve">
    <value>確認</value>
  </data>
  <data name="typeCOMPEXPSHAREDTL_Core" xml:space="preserve">
    <value>公司比例記錄</value>
  </data>
  <data name="typeFXRATEDTL_Core" xml:space="preserve">
    <value>匯率記錄</value>
  </data>
  <data name="typeBALANCESHEET_Report" xml:space="preserve">
    <value>資產負債表</value>
  </data>
  <data name="typeCHARTOFACCDTL_Core" xml:space="preserve">
    <value>帳項資料圖</value>
  </data>
  <data name="typePROFITANDLOSSSTANDARD_Report" xml:space="preserve">
    <value>損益表</value>
  </data>
  <data name="typePROFITANDLOSS_Report" xml:space="preserve">
    <value>什支表</value>
  </data>
  <data name="typerVouDtlLst_Report" xml:space="preserve">
    <value>票單查詢報表</value>
  </data>
  <data name="msgCustCurrCodeMismatch" xml:space="preserve">
    <value>客人貨幣與出碼貨幣不相符。</value>
  </data>
  <data name="typeSHIFTUSERLST_Core" xml:space="preserve">
    <value>當值員工管理</value>
  </data>
  <data name="typeSHIFTUSERDTL_Core" xml:space="preserve">
    <value>當值員工記錄</value>
  </data>
  <data name="typeACCOUNTING_DEPARTMENTDTL_Core" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="typeACCOUNTING_DEPARTMENTLST_Core" xml:space="preserve">
    <value>部門設定</value>
  </data>
  <data name="txtOverCreditMarker" xml:space="preserve">
    <value>半年內每月最高峰總簽大數</value>
  </data>
  <data name="txtMaxCreditMarker" xml:space="preserve">
    <value>半年內簽過額</value>
  </data>
  <data name="txtC_TO_W" xml:space="preserve">
    <value>存C轉WINC</value>
  </data>
  <data name="txtW_TO_C" xml:space="preserve">
    <value>WINC轉存C</value>
  </data>
  <data name="typeSTORETYPETRANLSTRPT_Report" xml:space="preserve">
    <value>存卡類轉換報表</value>
  </data>
  <data name="wTime" xml:space="preserve">
    <value>時間</value>
  </data>
  <data name="txtRefreshMthEndFxRate" xml:space="preserve">
    <value>更新兌換率</value>
  </data>
  <data name="txtPopBFDrinkTitle" xml:space="preserve">
    <value>積分概況詳情 - 未做月結前</value>
  </data>
  <data name="txtSignatureSample" xml:space="preserve">
    <value>簽署式樣 Signature Sample</value>
  </data>
  <data name="txtBossStr" xml:space="preserve">
    <value>帳戶利益最終歸屬者</value>
  </data>
  <data name="txtAuthActionCodeEName" xml:space="preserve">
    <value>Authorized Representative</value>
  </data>
  <data name="txtBossEName" xml:space="preserve">
    <value>Ultimate Account Owner</value>
  </data>
  <data name="txtAcctType" xml:space="preserve">
    <value>申請類型</value>
  </data>
  <data name="txtAppliedBy" xml:space="preserve">
    <value>申請人身份</value>
  </data>
  <data name="msgRepaymentMorethan15" xml:space="preserve">
    <value>單次還款單數不能多於15單。</value>
  </data>
  <data name="typePLACE_FOLLOWSTAFF_Core" xml:space="preserve">
    <value>跟單員工</value>
  </data>
  <data name="action_REJECT_type" xml:space="preserve">
    <value>不批準</value>
  </data>
  <data name="global_txtShiftCutAlready" xml:space="preserve">
    <value>已截更</value>
  </data>
  <data name="global_txtHasPeddingFollowStaff" xml:space="preserve">
    <value>已有未確認的跟單員工</value>
  </data>
  <data name="global_txtNoFollowStaff" xml:space="preserve">
    <value>未有跟單員工</value>
  </data>
  <data name="global_txtNoFollowStaff_SwitchShift" xml:space="preserve">
    <value>請設定截更之跟單員工</value>
  </data>
  <data name="txtCreditStatus_V2" xml:space="preserve">
    <value>信貸額概況V2</value>
  </data>
  <data name="action_CREDITSTATUS_V2_type" xml:space="preserve">
    <value>信貸額概況V2</value>
  </data>
  <data name="txtOutstanding_CAP" xml:space="preserve">
    <value>股本已簽額(萬)</value>
  </data>
  <data name="txtOutstanding_IO" xml:space="preserve">
    <value>U已簽額(萬)</value>
  </data>
  <data name="txtOutstanding_Y" xml:space="preserve">
    <value>營運已簽額(萬)</value>
  </data>
  <data name="txtOutstanding_F" xml:space="preserve">
    <value>海外已簽額(萬)</value>
  </data>
  <data name="txtOutstanding_CH" xml:space="preserve">
    <value>個人已簽額(萬)</value>
  </data>
  <data name="wMIOURolling" xml:space="preserve">
    <value>月息配置</value>
  </data>
  <data name="wZMIOUAmt" xml:space="preserve">
    <value>Z卡月息(萬)</value>
  </data>
  <data name="txtIsCreditContract" xml:space="preserve">
    <value>信貸合同</value>
  </data>
  <data name="txtIsCashCheckNotice" xml:space="preserve">
    <value>本票責任聲明書</value>
  </data>
  <data name="txtIsCheckNotice" xml:space="preserve">
    <value>支票責任聲明書</value>
  </data>
  <data name="txtIsPromissoryNote" xml:space="preserve">
    <value>Promissory Note</value>
  </data>
  <data name="txtIsCheck" xml:space="preserve">
    <value>支票</value>
  </data>
  <data name="wSmallAmount" xml:space="preserve">
    <value>小額</value>
  </data>
  <data name="txtNonNotice" xml:space="preserve">
    <value>未通報戶口</value>
  </data>
  <data name="txtCreditFull" xml:space="preserve">
    <value>額度屆滿</value>
  </data>
  <data name="txtFirstCreditMarkerExpire" xml:space="preserve">
    <value>首次批額簽碼過期</value>
  </data>
  <data name="txtDisConnectDay" xml:space="preserve">
    <value>失聯天數</value>
  </data>
  <data name="txtMeetingSuccessCount" xml:space="preserve">
    <value>約見逹標次數</value>
  </data>
  <data name="msgWarnCreditControl" xml:space="preserve">
    <value>如戶主出現於各館,或白咭存取等任何動作,請立即聯絡中央信貸部同事跟進,謝謝</value>
  </data>
  <data name="txtRollingAPlay_MI_10K" xml:space="preserve">
    <value>A數[月息]轉碼(萬)</value>
  </data>
  <data name="txtRollingBPlay_MI_10K" xml:space="preserve">
    <value>B數[月息]轉碼(萬)</value>
  </data>
  <data name="txtRollingMIOU" xml:space="preserve">
    <value>月息轉碼</value>
  </data>
  <data name="wCommRate_MI" xml:space="preserve">
    <value>佣金率(月息)</value>
  </data>
  <data name="wExchangeCurrCode" xml:space="preserve">
    <value>存澳門貨幣</value>
  </data>
  <data name="txtCNY" xml:space="preserve">
    <value>人民幣</value>
  </data>
  <data name="txtAccountEName" xml:space="preserve">
    <value>帳項英文名稱</value>
  </data>
  <data name="wDeptEName" xml:space="preserve">
    <value>部門英文名稱</value>
  </data>
  <data name="txtCRMPickUpPlaceSetting" xml:space="preserve">
    <value>取票地點管理</value>
  </data>
  <data name="txtCRMPickUpPlace" xml:space="preserve">
    <value>取票地點</value>
  </data>
  <data name="typePICKUPPLACELST_Core" xml:space="preserve">
    <value>取票地點管理</value>
  </data>
  <data name="txtSearchKey" xml:space="preserve">
    <value>尋找字眼</value>
  </data>
  <data name="txtSortSeqNo" xml:space="preserve">
    <value>排序號</value>
  </data>
  <data name="wShipTicket" xml:space="preserve">
    <value>船票</value>
  </data>
  <data name="wAirTicket" xml:space="preserve">
    <value>飛機票</value>
  </data>
  <data name="wFlightBoarding" xml:space="preserve">
    <value>登機服務</value>
  </data>
  <data name="wEntranceTicket" xml:space="preserve">
    <value>門票</value>
  </data>
  <data name="typePICKUPPLACEDTL_Core" xml:space="preserve">
    <value>取票地點管理</value>
  </data>
  <data name="txtAccecptNumericOnly" xml:space="preserve">
    <value>只接受為數字</value>
  </data>
  <data name="wCreditExpiryDate" xml:space="preserve">
    <value>批額到期日</value>
  </data>
  <data name="wCreditExpire" xml:space="preserve">
    <value>批額到期</value>
  </data>
  <data name="global_btnManage" xml:space="preserve">
    <value>管理</value>
  </data>
  <data name="typeSETTLETRANADMINMODE_Core" xml:space="preserve">
    <value>手動出糧</value>
  </data>
  <data name="txtCRMHotelSetting" xml:space="preserve">
    <value>酒店管理</value>
  </data>
  <data name="typeHOTELLST_Core" xml:space="preserve">
    <value>酒店管理</value>
  </data>
  <data name="txtHotelName" xml:space="preserve">
    <value>酒店名稱</value>
  </data>
  <data name="txtCRMHotelCName" xml:space="preserve">
    <value>酒店名稱(中)</value>
  </data>
  <data name="txtCRMHotelEName" xml:space="preserve">
    <value>酒店名稱(英)</value>
  </data>
  <data name="txtCRMHotelJapanName" xml:space="preserve">
    <value>酒店名稱(日)</value>
  </data>
  <data name="txtCRMHotelKoreaName" xml:space="preserve">
    <value>酒店名稱(韓)</value>
  </data>
  <data name="txtCRMHotelThaiName" xml:space="preserve">
    <value>酒店名稱(泰)</value>
  </data>
  <data name="txtLocation" xml:space="preserve">
    <value>地區</value>
  </data>
  <data name="txtExternalHotel" xml:space="preserve">
    <value>外館酒店</value>
  </data>
  <data name="typeHOTELDTL_Core" xml:space="preserve">
    <value>酒店設定</value>
  </data>
  <data name="txtParentHotelName" xml:space="preserve">
    <value>母系酒店</value>
  </data>
  <data name="txtInvalidParentHotelRID" xml:space="preserve">
    <value>母系酒店不可與酒店相同</value>
  </data>
  <data name="txtAllFiles" xml:space="preserve">
    <value>全部文件</value>
  </data>
  <data name="typeACCOUNTING_SYSRPT_Core" xml:space="preserve">
    <value>會計系統</value>
  </data>
  <data name="typeOPERATE_SYSRPT_Core" xml:space="preserve">
    <value>營運系統</value>
  </data>
  <data name="typeROLLING_SYSRPT_Core" xml:space="preserve">
    <value>轉碼系統</value>
  </data>
  <data name="typeROPERATECAPITALTRANMRPT_Report" xml:space="preserve">
    <value>股東個人交貨月報表</value>
  </data>
  <data name="typeRFREEZESTATUSRPT_Report" xml:space="preserve">
    <value>凍M拆息現況報表</value>
  </data>
  <data name="typeRFREEZESETTLERPT_Report" xml:space="preserve">
    <value>凍M拆息歸還報表</value>
  </data>
  <data name="typeFREEZEPENALTYRPT_ReportGrp" xml:space="preserve">
    <value>凍M拆息報表</value>
  </data>
  <data name="wPendFollowStaff" xml:space="preserve">
    <value>待跟單員工</value>
  </data>
  <data name="txtFollowEnd" xml:space="preserve">
    <value>結束</value>
  </data>
  <data name="global_msgNoAvaibleFollower" xml:space="preserve">
    <value>沒有可用跟單員工</value>
  </data>
  <data name="typeDigit10K" xml:space="preserve">
    <value>萬位</value>
  </data>
  <data name="typeDigitK" xml:space="preserve">
    <value>千位</value>
  </data>
  <data name="typeDigitH" xml:space="preserve">
    <value>百位</value>
  </data>
  <data name="wIOURtnDigit" xml:space="preserve">
    <value>Marker回至</value>
  </data>
  <data name="typeOPERATETRANLST_Core" xml:space="preserve">
    <value>營運管理</value>
  </data>
  <data name="txtOutsideOperate" xml:space="preserve">
    <value>外來</value>
  </data>
  <data name="txtOutsideRefNo" xml:space="preserve">
    <value>派貨單號碼</value>
  </data>
  <data name="wOccupiedPercentage" xml:space="preserve">
    <value>已食貨(%)</value>
  </data>
  <data name="txtAddCapitalSMS" xml:space="preserve">
    <value>加彩訊息</value>
  </data>
  <data name="txtStartSMS" xml:space="preserve">
    <value>開局訊息</value>
  </data>
  <data name="typeACCOUNTINGRPT_ReportGrp" xml:space="preserve">
    <value>會計報表</value>
  </data>
  <data name="typeRBALANCESHEETSTANDARDREPORT_Report" xml:space="preserve">
    <value>資產負債表</value>
  </data>
  <data name="typeRPROFITANDLOSSREPORTSTANDARDREPORT_Report" xml:space="preserve">
    <value>損益表</value>
  </data>
  <data name="typeRPROFITANDLOSSREPORT_Report" xml:space="preserve">
    <value>什支表</value>
  </data>
  <data name="txtIsSummary" xml:space="preserve">
    <value>只顯示統計</value>
  </data>
  <data name="msgReadCardAgentChange" xml:space="preserve">
    <value>拍卡轉戶口</value>
  </data>
  <data name="txtRollingSMSUnderAgent" xml:space="preserve">
    <value>收下線訊息(轉碼及上下數)</value>
  </data>
  <data name="msgCreditExpire" xml:space="preserve">
    <value>信貸批額已到期</value>
  </data>
  <data name="typeAGENTCREDITEXPIRE_Core" xml:space="preserve">
    <value>信貸批額到期</value>
  </data>
  <data name="typeCREDITISDIRECTACCEXPIRERPT_Report" xml:space="preserve">
    <value>直接授信批額過期</value>
  </data>
  <data name="txtCRMGiftSetting" xml:space="preserve">
    <value>送禮/特批管理</value>
  </data>
  <data name="typeCRM_GIFTLST_Core" xml:space="preserve">
    <value>送禮/特批管理</value>
  </data>
  <data name="txtCRMGiftName" xml:space="preserve">
    <value>送禮/特批名稱</value>
  </data>
  <data name="typeGIFTDTL_Core" xml:space="preserve">
    <value>送禮/特批管理</value>
  </data>
  <data name="global_btnGameResult" xml:space="preserve">
    <value>結果訊息</value>
  </data>
  <data name="global_btnSearchAndAdd" xml:space="preserve">
    <value>搜尋及新增</value>
  </data>
  <data name="txtAdminMode" xml:space="preserve">
    <value>管理員模式</value>
  </data>
  <data name="txtBettingDate" xml:space="preserve">
    <value>投注日期</value>
  </data>
  <data name="txtCustRecentGameRefNo" xml:space="preserve">
    <value>客人最近5場記錄</value>
  </data>
  <data name="txtDrag" xml:space="preserve">
    <value>拖數</value>
  </data>
  <data name="txtGame" xml:space="preserve">
    <value>場次</value>
  </data>
  <data name="txtIsBPlayCutOff" xml:space="preserve">
    <value>B仔數(計到十位)</value>
  </data>
  <data name="txtNo" xml:space="preserve">
    <value>没有</value>
  </data>
  <data name="txtOperateSettleInfo_HKD" xml:space="preserve">
    <value>結算資料 (HKD)</value>
  </data>
  <data name="txtRouteList" xml:space="preserve">
    <value>路址</value>
  </data>
  <data name="txtSettleAmount" xml:space="preserve">
    <value>結算金額</value>
  </data>
  <data name="txtTax" xml:space="preserve">
    <value>稅</value>
  </data>
  <data name="txtYes" xml:space="preserve">
    <value>有</value>
  </data>
  <data name="typeOPERATETRANDTL_Core" xml:space="preserve">
    <value>營運記錄</value>
  </data>
  <data name="wCustBetRemark" xml:space="preserve">
    <value>投注特徵</value>
  </data>
  <data name="wGameSet" xml:space="preserve">
    <value>靴</value>
  </data>
  <data name="wIsAllowSubmitRatio" xml:space="preserve">
    <value>放置於手機應用程式派貨</value>
  </data>
  <data name="wIsMainIntroduce" xml:space="preserve">
    <value>計入公司來貨</value>
  </data>
  <data name="global_msgEmptyGameSetOrTableName" xml:space="preserve">
    <value>路址圖必須填上檯號及靴數</value>
  </data>
  <data name="global_msgErrOccupiedRatioLargerThanMultiply" xml:space="preserve">
    <value>佔成數不能大於拖數</value>
  </data>
  <data name="global_msgInfoHistoryRecoedIsFive" xml:space="preserve">
    <value>最多只可輸入5條記錄</value>
  </data>
  <data name="global_msgInfoMissingGunter" xml:space="preserve">
    <value>沒有輸入槍手資料</value>
  </data>
  <data name="global_msgInfoOperateMissingSite" xml:space="preserve">
    <value>需要揀選場地或輸入新場地名稱</value>
  </data>
  <data name="txtAddNewSite" xml:space="preserve">
    <value>新增場地</value>
  </data>
  <data name="wCreditBalance" xml:space="preserve">
    <value>額度結餘</value>
  </data>
  <data name="wIsOutside" xml:space="preserve">
    <value>派貨公司</value>
  </data>
  <data name="global_msgHelpIsAllowSubmitRatio" xml:space="preserve">
    <value>一經放於應用程式掛貨, 本地將不容許作出佔成修改。
如果應用程式未能處理所有貨量, 需要包底開場, 
請修改營運狀態為開場, 配置剩餘貨量予包底公司。</value>
  </data>
  <data name="txtOperateDelete" xml:space="preserve">
    <value>刪除營運結算</value>
  </data>
  <data name="txtOperateReSettle" xml:space="preserve">
    <value>營運重新結算</value>
  </data>
  <data name="txtOperateSettle" xml:space="preserve">
    <value>營運結算</value>
  </data>
  <data name="global_msgErrOperateSettleDateMustBeInput" xml:space="preserve">
    <value>結算日期必須輸入</value>
  </data>
  <data name="global_msgErrOperateStatusMustBeLeave" xml:space="preserve">
    <value>請確認有關場次已離場 或 已取消(未開場之場次必需取消)</value>
  </data>
  <data name="txtCRMGiftDtlSetting" xml:space="preserve">
    <value>送禮/特批副類型管理</value>
  </data>
  <data name="typeGIFTSUBLST_Core" xml:space="preserve">
    <value>送禮/特批副類型管理</value>
  </data>
  <data name="txtCRMGiftDtlName" xml:space="preserve">
    <value>送禮/特批副類型名稱</value>
  </data>
  <data name="typeGIFTSUBDTL_Core" xml:space="preserve">
    <value>送禮/特批副類型管理</value>
  </data>
  <data name="global_msgHasTranNotAllowToDel" xml:space="preserve">
    <value>因已被相關交易使用, 不可刪除</value>
  </data>
  <data name="txtCRMExpenseSetting" xml:space="preserve">
    <value>消費類型管理</value>
  </data>
  <data name="txtCRMExpenseDtlSetting" xml:space="preserve">
    <value>消費副類型管理</value>
  </data>
  <data name="txtCRMExpenseName" xml:space="preserve">
    <value>消費類型名稱</value>
  </data>
  <data name="txtCRMExpenseDtlName" xml:space="preserve">
    <value>消費副類型名稱</value>
  </data>
  <data name="typeEXPENSELST_Core" xml:space="preserve">
    <value>消費類型管理</value>
  </data>
  <data name="typeEXPENSEDTL_Core" xml:space="preserve">
    <value>消費類型管理</value>
  </data>
  <data name="typeCOUNTERDTL_Core" xml:space="preserve">
    <value>場館部門聯絡資料管理</value>
  </data>
  <data name="typeCOUNTERMAIN_Core" xml:space="preserve">
    <value>工作場所管理</value>
  </data>
  <data name="typeCOUNTER_Core" xml:space="preserve">
    <value>場館資料管理</value>
  </data>
  <data name="wChineseName" xml:space="preserve">
    <value>名稱(中)</value>
  </data>
  <data name="wContactType" xml:space="preserve">
    <value>聯絡類型</value>
  </data>
  <data name="wCounterCode" xml:space="preserve">
    <value>場館編號</value>
  </data>
  <data name="wDefaultHotel" xml:space="preserve">
    <value>預設酒店</value>
  </data>
  <data name="wEnglishName" xml:space="preserve">
    <value>名稱(英)</value>
  </data>
  <data name="wJapaneseName" xml:space="preserve">
    <value>名稱(日)</value>
  </data>
  <data name="wThaiName" xml:space="preserve">
    <value>名稱(泰)</value>
  </data>
  <data name="wKoreanName" xml:space="preserve">
    <value>名稱(韓)</value>
  </data>
  <data name="wTelOrEmail" xml:space="preserve">
    <value>電話號碼/電郵</value>
  </data>
  <data name="typeEXPENSESUBLST_Core" xml:space="preserve">
    <value>消費副類型管理</value>
  </data>
  <data name="typeEXPENSESUBDTL_Core" xml:space="preserve">
    <value>消費副類型管理</value>
  </data>
  <data name="global_msgRollTranRIDUsed" xml:space="preserve">
    <value>轉碼卡已經被使用了，使用者是</value>
  </data>
  <data name="txtRptComplex" xml:space="preserve">
    <value>綜合</value>
  </data>
  <data name="typeRFOLLOWERRPT_Report" xml:space="preserve">
    <value>跟單人報表</value>
  </data>
  <data name="typeFOLLOWERRPT_ReportGrp" xml:space="preserve">
    <value>跟單人報表</value>
  </data>
  <data name="txtSMSRoomID" xml:space="preserve">
    <value>短訊使用編號</value>
  </data>
  <data name="txtUnitedStates" xml:space="preserve">
    <value>美國</value>
  </data>
  <data name="txtItaly" xml:space="preserve">
    <value>意大利</value>
  </data>
  <data name="txtCambodia" xml:space="preserve">
    <value>柬埔寨</value>
  </data>
  <data name="txtMalaysia" xml:space="preserve">
    <value>馬來西亞</value>
  </data>
  <data name="txtVietnam" xml:space="preserve">
    <value>越南</value>
  </data>
  <data name="txtSingapore" xml:space="preserve">
    <value>新加坡</value>
  </data>
  <data name="txtCzechRepublic" xml:space="preserve">
    <value>捷克</value>
  </data>
  <data name="typePASSPORTISSUEDCOUNTRYDTL_Core" xml:space="preserve">
    <value>證件簽發地設定</value>
  </data>
  <data name="typePASSPORTISSUEDCOUNTRYLST_Core" xml:space="preserve">
    <value>證件簽發地管理</value>
  </data>
  <data name="typeCRMDASHBOARD_Core" xml:space="preserve">
    <value>CRM Dashboard</value>
  </data>
  <data name="txtToolTip_TotalCredit" xml:space="preserve">
    <value>總信貸額:
股本 + 月息 + 娛樂場額 + 信貨額 + U可簽額</value>
  </data>
  <data name="txtToolTip_TotalRealOutstanding" xml:space="preserve">
    <value>已簽額:
下線 扣後尚欠(對減 股本,月息,凍M) 累加至上線 
  
股本已簽額 + U已簽額 + 個人借貸 + 營運已簽額 + 海外已簽額

(*不包括* 海外 - 暫存/未取)
(*不包括* 營運 - 未結算,暫存/未取)
  </value>
  </data>
  <data name="txtToolTip_TotalRealOutstanding_SO" xml:space="preserve">
    <value>股本已簽額:
  股本 + 股本M + 批額 +  凍結柴出M + 月息 + 月息M
  </value>
  </data>
  <data name="txtToolTip_TotalRealOutstanding_IO" xml:space="preserve">
    <value>U已簽額:
公司U + IOU
  </value>
  </data>
  <data name="txtToolTip_TotalRealOutstanding_Y" xml:space="preserve">
    <value>營運已簽額:
*不包括* 未結算,暫存/未取
  </value>
  </data>
  <data name="txtToolTip_TotalRealOutstanding_F" xml:space="preserve">
    <value>海外已簽額:
*不包括* 未結算,暫存/未取
  </value>
  </data>
  <data name="txtToolTip_EXPCREDITAMT" xml:space="preserve">
    <value>消費信用額:
1. 當沒有Marker的時候：股本ｘ５％ ＋ 當月未提取月息利息ｘ１００％ + 批額ｘ２％
2. 當有Marker [已用月息轉碼]但沒有過期M的時候：股本ｘ５％＋批額ｘ２％+當月未提取月息利息ｘ１００％
3. 當有過期M的時候: (批額＋股本＋月息存款－過期M-U可簽M)ｘ２％
註明：批額包括Ｕ額＋營運額
  </value>
  </data>
  <data name="global_msgOperateSettleDeleted" xml:space="preserve">
    <value>營運結算已刪除</value>
  </data>
  <data name="global_msgOperateSettleSuccess" xml:space="preserve">
    <value>營運結算完成</value>
  </data>
  <data name="global_msgCantUseAdminModeWhenUseApps" xml:space="preserve">
    <value>不能修改已經手機掛貨的單。</value>
  </data>
  <data name="global_msgErrRollAmtCantLessThanlossAmt" xml:space="preserve">
    <value>客下，轉碼數不能少於客下數</value>
  </data>
  <data name="wFirstGameTranDate" xml:space="preserve">
    <value>首場時間</value>
  </data>
  <data name="wLastGameTranDate" xml:space="preserve">
    <value>尾場時間</value>
  </data>
  <data name="typeLOOKUPLST_RELATE_Core" xml:space="preserve">
    <value>關係類別管理</value>
  </data>
  <data name="typeLOOKUPDTL_RELATE_Core" xml:space="preserve">
    <value>關係類別管理</value>
  </data>
  <data name="typeDEPTSHIFTLST_Core" xml:space="preserve">
    <value>部門更期管理</value>
  </data>
  <data name="typeDEPTSHIFTDTL_Core" xml:space="preserve">
    <value>部門更期管理</value>
  </data>
  <data name="txtDeptShift" xml:space="preserve">
    <value>部門更期管理</value>
  </data>
  <data name="txtWarnMsgInstantBPlay" xml:space="preserve">
    <value>B數碼存在, 是否使用預設 - 即出咭</value>
  </data>
  <data name="typeMarkerDtlV2_Core" xml:space="preserve">
    <value>綜合借貸</value>
  </data>
  <data name="typeMarkerDtlV2_CH_Core" xml:space="preserve">
    <value>綜合借貸-個人</value>
  </data>
  <data name="typeMarkerDtlV2_Y_Core" xml:space="preserve">
    <value>綜合借貸-營運</value>
  </data>
  <data name="typeMarkerDtlV2_F_Core" xml:space="preserve">
    <value>綜合借貸-海外</value>
  </data>
  <data name="typeMarkerActionType_IOU" xml:space="preserve">
    <value>借貸</value>
  </data>
  <data name="typeMarkerActionType_HOLDSTORE" xml:space="preserve">
    <value>凍結卡錢</value>
  </data>
  <data name="typeMarkerActionType_HOLDCOMM" xml:space="preserve">
    <value>凍結佣金</value>
  </data>
  <data name="typeMarkerActionType_HOLDMAXIOU" xml:space="preserve">
    <value>凍M出M</value>
  </data>
  <data name="txtHoldAmount" xml:space="preserve">
    <value>凍結金額</value>
  </data>
  <data name="wHoldStoreRate" xml:space="preserve">
    <value>凍卡出M 匯率</value>
  </data>
  <data name="wAvailableAmt" xml:space="preserve">
    <value>可動用結存</value>
  </data>
  <data name="txtBookAndSMS" xml:space="preserve">
    <value>訂務及訊息</value>
  </data>
  <data name="txtBookingSMS" xml:space="preserve">
    <value>訂務訊息</value>
  </data>
  <data name="txtStopAllBookingSMS" xml:space="preserve">
    <value>所有訂務停發</value>
  </data>
  <data name="typeAGENTSMSDTL_Core" xml:space="preserve">
    <value>訊息及訂務設定</value>
  </data>
  <data name="typeAGENTSMSLST_Core" xml:space="preserve">
    <value>訊息及訂務管理</value>
  </data>
  <data name="wCheckIn" xml:space="preserve">
    <value>登機服務</value>
  </data>
  <data name="wHelicopter" xml:space="preserve">
    <value>直升機</value>
  </data>
  <data name="wHotel" xml:space="preserve">
    <value>酒店/房間</value>
  </data>
  <data name="wOtherExp" xml:space="preserve">
    <value>其他消費</value>
  </data>
  <data name="wPlane" xml:space="preserve">
    <value>飛機票</value>
  </data>
  <data name="wRestaurant" xml:space="preserve">
    <value>餐廳</value>
  </data>
  <data name="wRoomExp" xml:space="preserve">
    <value>房間消費</value>
  </data>
  <data name="wRoomKey" xml:space="preserve">
    <value>房間取匙</value>
  </data>
  <data name="wShip" xml:space="preserve">
    <value>船票</value>
  </data>
  <data name="wTicket" xml:space="preserve">
    <value>門票</value>
  </data>
  <data name="wVehicle" xml:space="preserve">
    <value>車務</value>
  </data>
  <data name="wWarmRemind" xml:space="preserve">
    <value>温馨提示</value>
  </data>
  <data name="txtAchievements" xml:space="preserve">
    <value>業績</value>
  </data>
  <data name="txtRollCountRank" xml:space="preserve">
    <value>入場次數排名</value>
  </data>
  <data name="txtCustCountRank" xml:space="preserve">
    <value>入場客量排名</value>
  </data>
  <data name="txtTopPlaceCapitalHKD" xml:space="preserve">
    <value>最高入場金額HKD</value>
  </data>
  <data name="txtAverageCapitalHKD" xml:space="preserve">
    <value>平均入場金額HKD</value>
  </data>
  <data name="txtAveragePlaceStayTime" xml:space="preserve">
    <value>平均留枱時間</value>
  </data>
  <data name="typeLOOKUPDTL_PASSPORTTYPE_Core" xml:space="preserve">
    <value>證件類別設定</value>
  </data>
  <data name="typeLOOKUPDTL_SUPPLIER_Core" xml:space="preserve">
    <value>供應商設定</value>
  </data>
  <data name="typeLOOKUPLST_PASSPORTTYPE_Core" xml:space="preserve">
    <value>證件類別管理</value>
  </data>
  <data name="typeLOOKUPLST_SUPPLIER_Core" xml:space="preserve">
    <value>供應商管理</value>
  </data>
  <data name="global_msgErrOperateQuitBeforeStart" xml:space="preserve">
    <value>營運單未發開場訊息, 不能離場, 請聯絡營運同事</value>
  </data>
  <data name="typeAGENTFOLLOWUPLST_Core" xml:space="preserve">
    <value>戶口跟進組別管理</value>
  </data>
  <data name="typeAGENTFOLLOWUPDTL_Core" xml:space="preserve">
    <value>戶口跟進組別管理</value>
  </data>
  <data name="txtAgentFollowUp" xml:space="preserve">
    <value>戶口跟進組別管理</value>
  </data>
  <data name="wIsDenyContact" xml:space="preserve">
    <value>拒絕聯絡</value>
  </data>
  <data name="typePARENTCHILDDTL_HABIT_Core" xml:space="preserve">
    <value>喜好類別設定</value>
  </data>
  <data name="typePARENTCHILDLST_HABIT_Core" xml:space="preserve">
    <value>喜好類別管理</value>
  </data>
  <data name="wChildType" xml:space="preserve">
    <value>副類型</value>
  </data>
  <data name="wHabit" xml:space="preserve">
    <value>喜好</value>
  </data>
  <data name="typeLOOKUPDTL_CUISINE_Core" xml:space="preserve">
    <value>菜式類型設定</value>
  </data>
  <data name="typeLOOKUPLST_CUISINE_Core" xml:space="preserve">
    <value>菜式類型管理</value>
  </data>
  <data name="typeLOOKUPDTL_COUNTERDAILY_Core" xml:space="preserve">
    <value>場館日誌類別設定</value>
  </data>
  <data name="typeLOOKUPLST_COUNTERDAILY_Core" xml:space="preserve">
    <value>場館日誌類別管理</value>
  </data>
  <data name="typeLOOKUPDTL_MESSAGEMETHOD_Core" xml:space="preserve">
    <value>接收訊息方式設定</value>
  </data>
  <data name="typeLOOKUPLST_MESSAGEMETHOD_Core" xml:space="preserve">
    <value>接收訊息方式管理</value>
  </data>
  <data name="txtNumberOfTimesShort" xml:space="preserve">
    <value>次</value>
  </data>
  <data name="typeSHOPLST_RESTAURANT_Core" xml:space="preserve">
    <value>餐廳資料管理</value>
  </data>
  <data name="typeSHOPDTL_RESTAURANT_Core" xml:space="preserve">
    <value>餐廳資料管理</value>
  </data>
  <data name="typeSHOPLST_SPA_Core" xml:space="preserve">
    <value>SPA資料管理</value>
  </data>
  <data name="typeSHOPDTL_SPA_Core" xml:space="preserve">
    <value>SPA資料管理</value>
  </data>
  <data name="wOpenHour" xml:space="preserve">
    <value>營業時間</value>
  </data>
  <data name="wClass" xml:space="preserve">
    <value>級別</value>
  </data>
  <data name="wMenu" xml:space="preserve">
    <value>菜單</value>
  </data>
  <data name="wIsBTM" xml:space="preserve">
    <value>BTM</value>
  </data>
  <data name="wIsCreditPay" xml:space="preserve">
    <value>簽單</value>
  </data>
  <data name="wSeat" xml:space="preserve">
    <value>坐位數</value>
  </data>
  <data name="wMinCharge" xml:space="preserve">
    <value>最低消費</value>
  </data>
  <data name="txtMealStyle" xml:space="preserve">
    <value>菜式</value>
  </data>
  <data name="global_txtAmount100000k" xml:space="preserve">
    <value>金額(億)</value>
  </data>
  <data name="typeLOOKUPLST_CASINOCARD_Core" xml:space="preserve">
    <value>賭場卡類別管理</value>
  </data>
  <data name="typeLOOKUPDTL_CASINOCARD_Core" xml:space="preserve">
    <value>賭場卡類別管理</value>
  </data>
  <data name="txtPhoneResposeDate" xml:space="preserve">
    <value>回電日期</value>
  </data>
  <data name="txtAppointmentDate" xml:space="preserve">
    <value>約見日期</value>
  </data>
  <data name="txtSolutionExpDate" xml:space="preserve">
    <value>方案到期日</value>
  </data>
  <data name="wMaxIOULoanDay" xml:space="preserve">
    <value>天期</value>
  </data>
  <data name="wTotIOULoanAmount" xml:space="preserve">
    <value>金額</value>
  </data>
  <data name="typePARENTCHILDDTL_DAILYTASK_Core" xml:space="preserve">
    <value>工作日誌類型設定</value>
  </data>
  <data name="typePARENTCHILDDTL_INCOMPLIANCEREASON_Core" xml:space="preserve">
    <value>不達標原因設定</value>
  </data>
  <data name="typePARENTCHILDLST_DAILYTASK_Core" xml:space="preserve">
    <value>工作日誌類型管理</value>
  </data>
  <data name="typePARENTCHILDLST_INCOMPLIANCEREASON_Core" xml:space="preserve">
    <value>不達標原因管理</value>
  </data>
  <data name="wDailyTask" xml:space="preserve">
    <value>工作日誌</value>
  </data>
  <data name="wIncomplianceReason" xml:space="preserve">
    <value>不達標原因</value>
  </data>
  <data name="wParentType" xml:space="preserve">
    <value>類型</value>
  </data>
  <data name="typeCASINOCARDLST_Core" xml:space="preserve">
    <value>賭場卡管理</value>
  </data>
  <data name="typeCASINOCARDDTL_Core" xml:space="preserve">
    <value>賭場卡管理</value>
  </data>
  <data name="txtCasinoCardName" xml:space="preserve">
    <value>賭場卡類別</value>
  </data>
  <data name="txtCustAuthName" xml:space="preserve">
    <value>客人/受權人名稱</value>
  </data>
  <data name="txtProcesSuccess" xml:space="preserve">
    <value>處理成功</value>
  </data>
  <data name="txtFailPlan" xml:space="preserve">
    <value>方案失敗</value>
  </data>
  <data name="txtOnlyInterest" xml:space="preserve">
    <value>只有利息戶口顯示</value>
  </data>
  <data name="txtSpending" xml:space="preserve">
    <value>簽賬</value>
  </data>
  <data name="txtSpendingC" xml:space="preserve">
    <value>簽賬(公U)</value>
  </data>
  <data name="txtShortFormCapital" xml:space="preserve">
    <value>股</value>
  </data>
  <data name="txtShortFormMthInt" xml:space="preserve">
    <value>月</value>
  </data>
  <data name="txtShortFormCash" xml:space="preserve">
    <value>現</value>
  </data>
  <data name="txtShortFormCredit" xml:space="preserve">
    <value>批</value>
  </data>
  <data name="txtUsed" xml:space="preserve">
    <value>已用</value>
  </data>
  <data name="txtRemain" xml:space="preserve">
    <value>未用</value>
  </data>
  <data name="txtSettleTranInstant" xml:space="preserve">
    <value>即出數</value>
  </data>
  <data name="txtRollCapitalRank" xml:space="preserve">
    <value>轉碼排名</value>
  </data>
  <data name="txtRollCapitalFlow" xml:space="preserve">
    <value>轉碼走勢</value>
  </data>
  <data name="txtRollingProportion" xml:space="preserve">
    <value>類型分佈</value>
  </data>
  <data name="txtCRMFollowList" xml:space="preserve">
    <value>跟進事項</value>
  </data>
  <data name="txtCRMAgentActivity" xml:space="preserve">
    <value>互動紀錄</value>
  </data>
  <data name="txtCRMAgentAnalyze" xml:space="preserve">
    <value>戶口分析</value>
  </data>
  <data name="txtCRMTotalCredit" xml:space="preserve">
    <value>總批額</value>
  </data>
  <data name="txtCRMAvaibleCredit" xml:space="preserve">
    <value>可用批額</value>
  </data>
  <data name="txtCRMOutstandingAmt" xml:space="preserve">
    <value>已借之金額</value>
  </data>
  <data name="txtCRMOverdueOutstandingAmt" xml:space="preserve">
    <value>已過期之金額</value>
  </data>
  <data name="txtCRMFreezeAmt" xml:space="preserve">
    <value>已凍結之金額</value>
  </data>
  <data name="txtCRMLastIOUDate" xml:space="preserve">
    <value>最近借貸日期</value>
  </data>
  <data name="txtCRMLastOverdueDate" xml:space="preserve">
    <value>最近過期日期</value>
  </data>
  <data name="txtCRMFreezeDay" xml:space="preserve">
    <value>已凍結天數</value>
  </data>
  <data name="txtCRMOverduePercentage" xml:space="preserve">
    <value>過期次數比例</value>
  </data>
  <data name="txtCRMAvgOverdueDay" xml:space="preserve">
    <value>平均過期天數</value>
  </data>
  <data name="txtCRMMaxOverdueDay" xml:space="preserve">
    <value>最長過期天數</value>
  </data>
  <data name="txtCRMCreditInfo" xml:space="preserve">
    <value>信貸</value>
  </data>
  <data name="txtCRMRollingA" xml:space="preserve">
    <value>A</value>
  </data>
  <data name="txtCRMRollingB" xml:space="preserve">
    <value>B</value>
  </data>
  <data name="txtCRMRollingTelB" xml:space="preserve">
    <value>電</value>
  </data>
  <data name="txtCRMOperate" xml:space="preserve">
    <value>營</value>
  </data>
  <data name="txtCRMForeign" xml:space="preserve">
    <value>海</value>
  </data>
  <data name="txtCRMAgentAndSubLine" xml:space="preserve">
    <value>戶口 + 下線</value>
  </data>
  <data name="txtCRMAgentRollingFlow" xml:space="preserve">
    <value>6個月轉碼走勢</value>
  </data>
  <data name="txt_msgSelectError" xml:space="preserve">
    <value>方案達標與不達標, 不能同時選擇</value>
  </data>
  <data name="txtCompliance" xml:space="preserve">
    <value>達標</value>
  </data>
  <data name="typeCOUNTERSHIFTDTL_Core" xml:space="preserve">
    <value>交更記錄</value>
  </data>
  <data name="typeCOUNTERSHIFTLST_Core" xml:space="preserve">
    <value>交更記錄</value>
  </data>
  <data name="txtCRMCounterName" xml:space="preserve">
    <value>場館名稱</value>
  </data>
  <data name="global_msgNotAcceptMessage" xml:space="preserve">
    <value>不可接受</value>
  </data>
  <data name="global_msgErrOperateSettleFail" xml:space="preserve">
    <value>營運結算失敗</value>
  </data>
  <data name="global_msgErrOperateWrongRatio" xml:space="preserve">
    <value>拖數與佔成數不符</value>
  </data>
  <data name="global_msgPlsInputSettleRollingAndWinLossAmt" xml:space="preserve">
    <value>請輸入計算轉碼及輸贏數</value>
  </data>
  <data name="typePOPUPOPERATECOMPSHARELST_Core" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="typePOPUPROUTELST_Core" xml:space="preserve">
    <value>路址</value>
  </data>
  <data name="typeAUTHCUSTHABITDTL_Core" xml:space="preserve">
    <value>客人/授權人喜好表記錄設定</value>
  </data>
  <data name="typeAUTHCUSTHABITLST_Core" xml:space="preserve">
    <value>客人/授權人喜好表記錄管理</value>
  </data>
  <data name="wCounterDiaryType" xml:space="preserve">
    <value>場館日誌類別管理</value>
  </data>
  <data name="Place_txtShareGame" xml:space="preserve">
    <value>股東自賭</value>
  </data>
  <data name="Place_txtGambleTableUp" xml:space="preserve">
    <value>賭枱升紅</value>
  </data>
  <data name="global_txtCentroidPersonCheck" xml:space="preserve">
    <value>博彩信貸資料庫資料</value>
  </data>
  <data name="typeDIARYLST_COUNTER_Core" xml:space="preserve">
    <value>場館日誌管理</value>
  </data>
  <data name="typeDIARYDTL_COUNTER_Core" xml:space="preserve">
    <value>場館日誌設定</value>
  </data>
  <data name="wCounterDiary" xml:space="preserve">
    <value>場館日誌</value>
  </data>
  <data name="wCreateCName" xml:space="preserve">
    <value>建立人</value>
  </data>
  <data name="txtContent" xml:space="preserve">
    <value>內容</value>
  </data>
  <data name="txtUnHandle" xml:space="preserve">
    <value>未處理</value>
  </data>
  <data name="txtHandled" xml:space="preserve">
    <value>已處理</value>
  </data>
  <data name="wCaseDate" xml:space="preserve">
    <value>發案時間</value>
  </data>
  <data name="wIsHighPriority" xml:space="preserve">
    <value>高度重視事件</value>
  </data>
  <data name="txtCRMClosed" xml:space="preserve">
    <value>已關閉</value>
  </data>
  <data name="global_msgInfoNotAllow" xml:space="preserve">
    <value>禁止 {0}</value>
  </data>
  <data name="typeCRMMASTER_Core" xml:space="preserve">
    <value>基本管理</value>
  </data>
  <data name="typeCRMBOOKING_Core" xml:space="preserve">
    <value>票務管理</value>
  </data>
  <data name="typeCRMREPORT_Core" xml:space="preserve">
    <value>報表</value>
  </data>
  <data name="typeCRMMARKETING_Core" xml:space="preserve">
    <value>市場及推廣管理</value>
  </data>
  <data name="typeCRMOTHER_Core" xml:space="preserve">
    <value>其他管理</value>
  </data>
  <data name="txtNoPlan" xml:space="preserve">
    <value>沒有方案</value>
  </data>
  <data name="txtHasPlan" xml:space="preserve">
    <value>有方案</value>
  </data>
  <data name="typeLOOKUPLST_POINTTYPE_Core" xml:space="preserve">
    <value>積分類型管理</value>
  </data>
  <data name="typeLOOKUPDTL_POINTTYPE_Core" xml:space="preserve">
    <value>積分類型管理</value>
  </data>
  <data name="typeLOOKUPLST_APPOINTTYPE_Core" xml:space="preserve">
    <value>約會類別管理</value>
  </data>
  <data name="typeLOOKUPDTL_APPOINTTYPE_Core" xml:space="preserve">
    <value>約會類別管理</value>
  </data>
  <data name="typeLOOKUPLST_APPOINTISSUE_Core" xml:space="preserve">
    <value>約會議題類型管理</value>
  </data>
  <data name="typeLOOKUPDTL_APPOINTISSUE_Core" xml:space="preserve">
    <value>約會議題類型管理</value>
  </data>
  <data name="wTitle" xml:space="preserve">
    <value>標題</value>
  </data>
  <data name="wRelateToName" xml:space="preserve">
    <value>涉及人物</value>
  </data>
  <data name="Agent_txtCapitalType" xml:space="preserve">
    <value>本</value>
  </data>
  <data name="Agent_txtGameType" xml:space="preserve">
    <value>場</value>
  </data>
  <data name="Agent_txtCapitalPlayer" xml:space="preserve">
    <value>玩家本金</value>
  </data>
  <data name="Agent_txtCapitalAgent" xml:space="preserve">
    <value>代理本金</value>
  </data>
  <data name="Agent_txtGamePlayer" xml:space="preserve">
    <value>玩家場次</value>
  </data>
  <data name="Agent_txtGameAgent" xml:space="preserve">
    <value>代理場次</value>
  </data>
  <data name="typeOPERATESETTLE_Core" xml:space="preserve">
    <value>營運結算</value>
  </data>
  <data name="typePOPUPBYOPERATEITEM_Core" xml:space="preserve">
    <value>詳情</value>
  </data>
  <data name="Agent_txtCreditRollRatio" xml:space="preserve">
    <value>轉碼/批額比率</value>
  </data>
  <data name="typeAGENTREQUESTSETLST_Core" xml:space="preserve">
    <value>股東上/下線服務管理</value>
  </data>
  <data name="typeAGENTREQUESTSETDTL_Core" xml:space="preserve">
    <value>股東上/下線服務管理</value>
  </data>
  <data name="txtCRM_ServiceNeeded" xml:space="preserve">
    <value>選擇提供之服務</value>
  </data>
  <data name="txtCRM_ServiceProvidedByBusiness" xml:space="preserve">
    <value>選擇提供予下線之服務</value>
  </data>
  <data name="txtCRM_ServiceProvidedByDesignatedAccount" xml:space="preserve">
    <value>選擇提供予特別戶口之服務</value>
  </data>
  <data name="txtCRM_NoticeMethod" xml:space="preserve">
    <value>選擇通知之方式</value>
  </data>
  <data name="wIsAppointmentAlert" xml:space="preserve">
    <value>提示下線之要求約見老闆</value>
  </data>
  <data name="wIsDOBAlert" xml:space="preserve">
    <value>提示下線生日</value>
  </data>
  <data name="wIsJoinEventAlert" xml:space="preserve">
    <value>提示下線所參加之活動</value>
  </data>
  <data name="wIsEntertainmentAlert" xml:space="preserve">
    <value>提示下線將獲邀之應酬</value>
  </data>
  <data name="wIsBenefitAlert" xml:space="preserve">
    <value>提示下線所獲得之禮遇 </value>
  </data>
  <data name="wIsPerformanceRpt" xml:space="preserve">
    <value>提供下線之業績報表</value>
  </data>
  <data name="wIsConsumptionRpt" xml:space="preserve">
    <value>提供下線之消費報表</value>
  </data>
  <data name="wIsRepaymentStatus" xml:space="preserve">
    <value>提供下線之還款狀況</value>
  </data>
  <data name="wIsDinnerParty" xml:space="preserve">
    <value>安排生日飯局及生日禮物 </value>
  </data>
  <data name="wIsGift" xml:space="preserve">
    <value>業績達標送禮（包括積分/長房/禮品等）</value>
  </data>
  <data name="CRM_ByAgent" xml:space="preserve">
    <value>您的名義</value>
  </data>
  <data name="CRM_ByComp" xml:space="preserve">
    <value>公司名義</value>
  </data>
  <data name="wIsEventInvitation" xml:space="preserve">
    <value>活動邀請</value>
  </data>
  <data name="wIs24HrsAssistant" xml:space="preserve">
    <value>24 小時助理團隊（卓越以上客戶）</value>
  </data>
  <data name="wIsLimoService" xml:space="preserve">
    <value>勞斯萊斯接送服務</value>
  </data>
  <data name="txtSpecAgent" xml:space="preserve">
    <value>特別戶口</value>
  </data>
  <data name="typeAGENTMEMBERSHIPINFODTL_Core" xml:space="preserve">
    <value>戶口會藉部相關資料設定</value>
  </data>
  <data name="typeAGENTMEMBERSHIPINFOLST_Core" xml:space="preserve">
    <value>戶口會藉部相關資料管理</value>
  </data>
  <data name="wAutoPayAuthLetter" xml:space="preserve">
    <value>自動轉帳授權書</value>
  </data>
  <data name="wCardValidFrom" xml:space="preserve">
    <value>換卡日期</value>
  </data>
  <data name="wDoNotDistrubList" xml:space="preserve">
    <value>不打擾名單</value>
  </data>
  <data name="wDownloadSunCityApp" xml:space="preserve">
    <value>下載太陽城APP</value>
  </data>
  <data name="wFirstChoiceMessage" xml:space="preserve">
    <value>首選收訊息方式</value>
  </data>
  <data name="wIntroSunChat" xml:space="preserve">
    <value>介紹SUN CHAT</value>
  </data>
  <data name="wMembershipClubRemark" xml:space="preserve">
    <value>會藉部備註</value>
  </data>
  <data name="wSubscribeSunCity" xml:space="preserve">
    <value>關注太陽城訂閱號</value>
  </data>
  <data name="typePARENTCHILDLST_PROGRAMMETYPE_Core" xml:space="preserve">
    <value>節目類型管理</value>
  </data>
  <data name="wProgramme" xml:space="preserve">
    <value>節目</value>
  </data>
  <data name="typePARENTCHILDDTL_PROGRAMMETYPE_Core" xml:space="preserve">
    <value>節目類型設定</value>
  </data>
  <data name="typePARENTCHILDDTL_GROUPOPINIONTYPE_Core" xml:space="preserve">
    <value>集團意見類型設定</value>
  </data>
  <data name="typePARENTCHILDLST_GROUPOPINIONTYPE_Core" xml:space="preserve">
    <value>集團意見類型管理</value>
  </data>
  <data name="wGroupOpinion" xml:space="preserve">
    <value>集團意見</value>
  </data>
  <data name="msgMustMatchUpLevelGroupNo" xml:space="preserve">
    <value>戶口組號(開始格式), 必須與上線相同{0}</value>
  </data>
  <data name="msgMustAlpha_AfterUpLevelGroupNo" xml:space="preserve">
    <value>戶口組號(開始格式)尾後一個位, 必須是英文字</value>
  </data>
  <data name="wCasinoWinLossAmt" xml:space="preserve">
    <value>公務數(萬)</value>
  </data>
  <data name="wTelBRollingAmt" xml:space="preserve">
    <value>電投轉碼數(萬)</value>
  </data>
  <data name="typeCOMPWINLOSSTRANLST_Core" xml:space="preserve">
    <value>賭場上下數管理</value>
  </data>
  <data name="typeCOMPWINLOSSTRANDTL_Core" xml:space="preserve">
    <value>賭場上下數詳細</value>
  </data>
  <data name="SMS_EXPDAILY_COMPLEX" xml:space="preserve">
    <value>(新)每日集團消費報表</value>
  </data>
  <data name="msgBeginAgentNoMustBeAlpha" xml:space="preserve">
    <value>[下線編號]開始必須是英文字</value>
  </data>
  <data name="global_msgErrOverSettlePenaltyAmount" xml:space="preserve">
    <value>還息金額過大</value>
  </data>
  <data name="typeWORKDIARYDTL_Core" xml:space="preserve">
    <value>工作日誌設定</value>
  </data>
  <data name="typeWORKDIARYLST_Core" xml:space="preserve">
    <value>工作日誌管理</value>
  </data>
  <data name="wWorkDiary" xml:space="preserve">
    <value>工作日誌</value>
  </data>
  <data name="wBusinessContent" xml:space="preserve">
    <value>業務內容</value>
  </data>
  <data name="wBusinessContentDetail" xml:space="preserve">
    <value>業務內容詳細資料</value>
  </data>
  <data name="wCounterAgent" xml:space="preserve">
    <value>場館及戶口</value>
  </data>
  <data name="wJobDescription" xml:space="preserve">
    <value>工作描述</value>
  </data>
  <data name="wResident" xml:space="preserve">
    <value>駐場</value>
  </data>
  <data name="typeAUTHCUSTRELATIONSHIPDTL_Core" xml:space="preserve">
    <value>客人/授權人之間的關係記錄設定</value>
  </data>
  <data name="typeAUTHCUSTRELATIONSHIPLST_Core" xml:space="preserve">
    <value>客人/授權人之間的關係記錄管理</value>
  </data>
  <data name="wAgentOrCust1" xml:space="preserve">
    <value>客人/授權人1</value>
  </data>
  <data name="wAgentOrCust2" xml:space="preserve">
    <value>客人/授權人2</value>
  </data>
  <data name="wHoldIOUAmount_10K" xml:space="preserve">
    <value>凍柴(萬)</value>
  </data>
  <data name="wHoldIOUOutstanding_10K" xml:space="preserve">
    <value>凍柴倘欠(萬)</value>
  </data>
  <data name="typeCOMPWINLOSSRPT_ReportGrp" xml:space="preserve">
    <value>賭場上下數報表</value>
  </data>
  <data name="txt_DailyCompWinLossReport" xml:space="preserve">
    <value>貴賓會每天上下水數表</value>
  </data>
  <data name="typeRCOMPWINLOSSRPT_Report" xml:space="preserve">
    <value>賭場上下數報表</value>
  </data>
  <data name="txtCRMPier" xml:space="preserve">
    <value>船票航線地點管理</value>
  </data>
  <data name="typePIERLST_Core" xml:space="preserve">
    <value>船票航線地點管理</value>
  </data>
  <data name="typePIERDTL_Core" xml:space="preserve">
    <value>船票航線地點管理</value>
  </data>
  <data name="txtCRMChiName" xml:space="preserve">
    <value>名稱(中)</value>
  </data>
  <data name="txtCRMEngName" xml:space="preserve">
    <value>名稱(英)</value>
  </data>
  <data name="txtCRMJpnName" xml:space="preserve">
    <value>名稱(日)</value>
  </data>
  <data name="txtCRMKorName" xml:space="preserve">
    <value>名稱(韓)</value>
  </data>
  <data name="txtCRMThaName" xml:space="preserve">
    <value>名稱(泰)</value>
  </data>
  <data name="global_msgErrOpCompCreditSmallerThanZero" xml:space="preserve">
    <value>保證金額必須大於零</value>
  </data>
  <data name="typeOPERATINGPLACEAPPROVAL_Core" xml:space="preserve">
    <value>營運確認(New Db Flow)</value>
  </data>
  <data name="typeLOOKUPLST_SHIP_TICKETTYPE_Core" xml:space="preserve">
    <value>船票票類管理</value>
  </data>
  <data name="typeLOOKUPDTL_SHIP_TICKETTYPE_Core" xml:space="preserve">
    <value>船票票類管理</value>
  </data>
  <data name="wCountry" xml:space="preserve">
    <value>國家</value>
  </data>
  <data name="typeAUTHCUSTPASSPORTDTL_Core" xml:space="preserve">
    <value>客人/授權人等旅遊證件記錄設定</value>
  </data>
  <data name="typeAUTHCUSTPASSPORTLST_Core" xml:space="preserve">
    <value>客人/授權人等旅遊證件記錄管理</value>
  </data>
  <data name="wPassportType" xml:space="preserve">
    <value>證件類別</value>
  </data>
  <data name="wENamePinYin" xml:space="preserve">
    <value>英文名字拼音</value>
  </data>
  <data name="wIssuedLocation" xml:space="preserve">
    <value>簽發地</value>
  </data>
  <data name="wValidUntil" xml:space="preserve">
    <value>有效期至</value>
  </data>
  <data name="typeUCPHOTOENLARGE_Core" xml:space="preserve">
    <value>圖片管理</value>
  </data>
  <data name="txtCRMShipRoute" xml:space="preserve">
    <value>船票航線管理</value>
  </data>
  <data name="typeSHIPROUTELST_Core" xml:space="preserve">
    <value>船票航線管理</value>
  </data>
  <data name="typeSHIPROUTEDTL_Core" xml:space="preserve">
    <value>船票航線管理</value>
  </data>
  <data name="txtSingleWay" xml:space="preserve">
    <value>單程</value>
  </data>
  <data name="txtRoundTrip" xml:space="preserve">
    <value>來回</value>
  </data>
  <data name="txtCRMRouteName" xml:space="preserve">
    <value>航線</value>
  </data>
  <data name="txtCRMDepartName" xml:space="preserve">
    <value>出發地</value>
  </data>
  <data name="txtCRMArriveName" xml:space="preserve">
    <value>目的地</value>
  </data>
  <data name="msgNotAllowInSame" xml:space="preserve">
    <value>不可相同</value>
  </data>
  <data name="msgDuplicatedRec" xml:space="preserve">
    <value>已有相同紀錄</value>
  </data>
  <data name="txtTickTypeName" xml:space="preserve">
    <value>價目類</value>
  </data>
  <data name="txtTickPrice" xml:space="preserve">
    <value>票價</value>
  </data>
  <data name="typeSHIPTICKPRICELST_Core" xml:space="preserve">
    <value>船票航線票價管理</value>
  </data>
  <data name="typeSHIPTICKPRICEDTL_Core" xml:space="preserve">
    <value>船票航線票價管理</value>
  </data>
  <data name="msgNotAllowLessThanZero" xml:space="preserve">
    <value>不可少於零</value>
  </data>
  <data name="txtSit" xml:space="preserve">
    <value>坐位</value>
  </data>
  <data name="txtStand" xml:space="preserve">
    <value>企位</value>
  </data>
  <data name="typeLOOKUPDTL_CORPORATE_Core" xml:space="preserve">
    <value>廳團設定</value>
  </data>
  <data name="typeLOOKUPLST_CORPORATE_Core" xml:space="preserve">
    <value>廳團管理</value>
  </data>
  <data name="msgOverCredit" xml:space="preserve">
    <value>所借金額已超出限額</value>
  </data>
  <data name="typeTICKETLST_Core" xml:space="preserve">
    <value>船票紀錄</value>
  </data>
  <data name="typeTICKETDTL_Core" xml:space="preserve">
    <value>船票紀錄</value>
  </data>
  <data name="wIssueLocationName" xml:space="preserve">
    <value>船票發放地點</value>
  </data>
  <data name="wTicketNo" xml:space="preserve">
    <value>票編號</value>
  </data>
  <data name="wExchangeName" xml:space="preserve">
    <value>兌換名稱</value>
  </data>
  <data name="typeLOOKUPDTL_HELIBOOKINGLOC_Core" xml:space="preserve">
    <value>直升機票訂票地點設定</value>
  </data>
  <data name="typeLOOKUPLST_HELIBOOKINGLOC_Core" xml:space="preserve">
    <value>直升機票訂票地點管理</value>
  </data>
  <data name="txtTicketNoPrefix" xml:space="preserve">
    <value>票號首字</value>
  </data>
  <data name="txtStartTicketNo" xml:space="preserve">
    <value>票號開始編號</value>
  </data>
  <data name="txtEndTicketNo" xml:space="preserve">
    <value>票號最後編號</value>
  </data>
  <data name="txtShowNotUsed" xml:space="preserve">
    <value>未使用</value>
  </data>
  <data name="msgDeptNoRequired" xml:space="preserve">
    <value>必需輸入部門</value>
  </data>
  <data name="msgDuplicate_IOUSource" xml:space="preserve">
    <value>借貸來源重覆</value>
  </data>
  <data name="txtCasinoWinLossAmt" xml:space="preserve">
    <value>公務數</value>
  </data>
  <data name="txtBuyChipAmt" xml:space="preserve">
    <value>買碼數</value>
  </data>
  <data name="global_msgErrMinLargerThanMax" xml:space="preserve">
    <value>{0}必須大於{1}</value>
  </data>
  <data name="global_msgErrRepeated" xml:space="preserve">
    <value>{0}已存在</value>
  </data>
  <data name="typeVOUCHERDTL_Core" xml:space="preserve">
    <value>消費券記錄設定</value>
  </data>
  <data name="typeVOUCHERLST_Core" xml:space="preserve">
    <value>消費券記錄管理</value>
  </data>
  <data name="wCorporate" xml:space="preserve">
    <value>廳團</value>
  </data>
  <data name="wFirstVoucherNumber" xml:space="preserve">
    <value>首張消費券號</value>
  </data>
  <data name="wLastVoucherNumber" xml:space="preserve">
    <value>最後一張消費券號</value>
  </data>
  <data name="wSellingCounter" xml:space="preserve">
    <value>出票場館</value>
  </data>
  <data name="wVoucher" xml:space="preserve">
    <value>消費券</value>
  </data>
  <data name="action_GROUP_type" xml:space="preserve">
    <value>群組</value>
  </data>
  <data name="typeTRAVELAGENCYDTL_Core" xml:space="preserve">
    <value>旅行社管理</value>
  </data>
  <data name="typeTRAVELAGENCYLST_Core" xml:space="preserve">
    <value>旅行社管理</value>
  </data>
  <data name="wIsGroup" xml:space="preserve">
    <value>群組</value>
  </data>
  <data name="wIsHotel" xml:space="preserve">
    <value>酒店</value>
  </data>
  <data name="typePLACENOTIFYRPT_ReportGrp" xml:space="preserve">
    <value>現金確認資料報表</value>
  </data>
  <data name="typeRPLACENOTIFYRPT_Report" xml:space="preserve">
    <value>現金確認資料報表</value>
  </data>
  <data name="txtShowConfirmed" xml:space="preserve">
    <value>已確認</value>
  </data>
  <data name="txtRollingOwn" xml:space="preserve">
    <value>本戶轉碼</value>
  </data>
  <data name="txtRollingOwnWithDownLine" xml:space="preserve">
    <value>本戶連下線轉碼</value>
  </data>
  <data name="txtRollingAPlay" xml:space="preserve">
    <value>A數轉碼</value>
  </data>
  <data name="txtRollingBPlay" xml:space="preserve">
    <value>B數轉碼</value>
  </data>
  <data name="txtRollingOperate" xml:space="preserve">
    <value>營運轉碼</value>
  </data>
  <data name="txtRollingForeign" xml:space="preserve">
    <value>海外點轉碼</value>
  </data>
  <data name="txtPeriodRange" xml:space="preserve">
    <value>週期段</value>
  </data>
  <data name="typeRBUSINESSRPT_Report" xml:space="preserve">
    <value>業績報表</value>
  </data>
  <data name="wTTLMaxIOUHoldAmt" xml:space="preserve">
    <value>總凍結柴金額</value>
  </data>
  <data name="wTTLPendingAmount" xml:space="preserve">
    <value>總倘欠(萬)</value>
  </data>
  <data name="msgBPlayNotenoughStore" xml:space="preserve">
    <value>該場館存卡不足以凍結</value>
  </data>
  <data name="txtOptExpenseDeduct" xml:space="preserve">
    <value>扣減消費(共用/不共用)</value>
  </data>
  <data name="txtShareExpOnly" xml:space="preserve">
    <value>共用</value>
  </data>
  <data name="txtNonShareExpOnly" xml:space="preserve">
    <value>不共用</value>
  </data>
  <data name="txtInvalidFxRate" xml:space="preserve">
    <value>匯率數字(乘/除)</value>
  </data>
  <data name="txtSeatType" xml:space="preserve">
    <value>位置類型</value>
  </data>
  <data name="txtSeat" xml:space="preserve">
    <value>位置</value>
  </data>
  <data name="msgSelectSeatError" xml:space="preserve">
    <value>這位置已有客人, 請重新選擇</value>
  </data>
  <data name="txtShareLine" xml:space="preserve">
    <value>股東線</value>
  </data>
  <data name="wIsInternalUse" xml:space="preserve">
    <value>內部使用</value>
  </data>
  <data name="txtBPlayIsByPassMthComm" xml:space="preserve">
    <value>跳過月結佣金</value>
  </data>
  <data name="typeOPTRANLOGENQUIRY_Core" xml:space="preserve">
    <value>資料日誌查詢(營運)</value>
  </data>
  <data name="txt100NoReturn" xml:space="preserve">
    <value>欠M100天或以上</value>
  </data>
  <data name="txt30NoReturnNoRolling" xml:space="preserve">
    <value>欠M+無轉碼且30天無回數</value>
  </data>
  <data name="txt30NoReturnRolling" xml:space="preserve">
    <value>欠M+有轉碼且30天無回數</value>
  </data>
  <data name="txt30ReturnNoRolling" xml:space="preserve">
    <value>欠M+無轉碼且30天有回數</value>
  </data>
  <data name="txt30ReturnRolling" xml:space="preserve">
    <value>欠M+有轉碼且30天有回數</value>
  </data>
  <data name="txt60NoReturn" xml:space="preserve">
    <value>欠M60天無回數</value>
  </data>
  <data name="txtCashVsCredit" xml:space="preserve">
    <value>現金%/批額%</value>
  </data>
  <data name="txtFreezeAmt" xml:space="preserve">
    <value>凍結數</value>
  </data>
  <data name="txtNetAmtNotFreeze" xml:space="preserve">
    <value>總欠(扣除凍結數)</value>
  </data>
  <data name="txtNewCredit" xml:space="preserve">
    <value>現額度</value>
  </data>
  <data name="txtNewCreditExpired" xml:space="preserve">
    <value>新批額過期</value>
  </data>
  <data name="txtOldCredit" xml:space="preserve">
    <value>原額度</value>
  </data>
  <data name="txtReduceM" xml:space="preserve">
    <value>減M</value>
  </data>
  <data name="typeRCREDITCONTROLLABELRPT_Report" xml:space="preserve">
    <value>審視額度標籤報表</value>
  </data>
  <data name="wExpiredForeign" xml:space="preserve">
    <value>過海</value>
  </data>
  <data name="wExpiredIOU" xml:space="preserve">
    <value>過面</value>
  </data>
  <data name="wExpiredOperate" xml:space="preserve">
    <value>過營</value>
  </data>
  <data name="wRollingLast3Mths" xml:space="preserve">
    <value>3個月內Rolling(月份- {0})</value>
  </data>
  <data name="wStopMRecover" xml:space="preserve">
    <value>復M</value>
  </data>
  <data name="wStopMRecoverCount" xml:space="preserve">
    <value>復M次數</value>
  </data>
  <data name="wSysRemark" xml:space="preserve">
    <value>內部備註</value>
  </data>
  <data name="txtForeignCashIn" xml:space="preserve">
    <value>現金存入</value>
  </data>
  <data name="txtForeignRedEnvelopes" xml:space="preserve">
    <value>紅包</value>
  </data>
  <data name="txtForeignPettyCash" xml:space="preserve">
    <value>零用現金</value>
  </data>
  <data name="txtForeignExpRebate" xml:space="preserve">
    <value>消費回贈</value>
  </data>
  <data name="txtQuickReturnDay" xml:space="preserve">
    <value>快速還款天期</value>
  </data>
  <data name="txtQuickReturnCommRebateRate" xml:space="preserve">
    <value>快速還款佣金回贈率</value>
  </data>
  <data name="txtCashQuickReturnCommRebateRate" xml:space="preserve">
    <value>海外本地現金轉碼快速還款回贈率</value>
  </data>
  <data name="txtReturnDueDate" xml:space="preserve">
    <value>還款到期日</value>
  </data>
  <data name="txtQuickReturnDueDate" xml:space="preserve">
    <value>快速還款到期日</value>
  </data>
  <data name="txtForeignLocalCapitalRolling_10K" xml:space="preserve">
    <value>海外本地現金轉碼數(萬)</value>
  </data>
  <data name="txtForeignLocalCapitalCommRate" xml:space="preserve">
    <value>海外本地現金佣金率</value>
  </data>
  <data name="txtCapital_MRolling_10K" xml:space="preserve">
    <value>M現金轉碼數(萬)</value>
  </data>
  <data name="txtCapital_MCommRate" xml:space="preserve">
    <value>M現金佣金率</value>
  </data>
  <data name="txtIOURolling_10K" xml:space="preserve">
    <value>IOU轉碼數(萬)</value>
  </data>
  <data name="txtIOUCommRate" xml:space="preserve">
    <value>IOU佣金率</value>
  </data>
  <data name="typeAGENTCATEGORYLST_Core" xml:space="preserve">
    <value>代理類別管理</value>
  </data>
  <data name="typeAGENTCATEGORYDTL_Core" xml:space="preserve">
    <value>代理類別記錄</value>
  </data>
  <data name="txtAgentCagegoryTypeCompAcc" xml:space="preserve">
    <value>公司戶口</value>
  </data>
  <data name="txtAgentCagegoryTypeReservedAcc" xml:space="preserve">
    <value>開戶保留戶口</value>
  </data>
  <data name="txtAgentCagegoryTypeOtherLineGrpAcc" xml:space="preserve">
    <value>外團客人戶口</value>
  </data>
  <data name="typeRAGENCARDCREDITAMTRPT_Report" xml:space="preserve">
    <value>消費信用額報表</value>
  </data>
  <data name="global_msgLockAgentCountDown" xml:space="preserve">
    <value>已對戶口進行鎖定,請在限時內完成操作</value>
  </data>
  <data name="global_msgAgentLocked" xml:space="preserve">
    <value>因其他用戶對該代理進行操作中,請之後再做嘗試!!</value>
  </data>
  <data name="txtLastNoticeDate" xml:space="preserve">
    <value>最後通報日</value>
  </data>
  <data name="txtRolling_C_10K" xml:space="preserve">
    <value>現金轉碼(萬)</value>
  </data>
  <data name="txtRolling_MI_10K" xml:space="preserve">
    <value>月息轉碼(萬)</value>
  </data>
  <data name="txtOccupiedTable" xml:space="preserve">
    <value>包枱</value>
  </data>
  <data name="txtAgentRemark" xml:space="preserve">
    <value>戶口備註</value>
  </data>
  <data name="wStore" xml:space="preserve">
    <value>內部卡</value>
  </data>
  <data name="wCommRate_C" xml:space="preserve">
    <value>佣金率(現金)</value>
  </data>
  <data name="txtDayPassed" xml:space="preserve">
    <value>最長天期</value>
  </data>
  <data name="txtPlaceOfIssue" xml:space="preserve">
    <value>簽發地點</value>
  </data>
  <data name="txtDisablePenalty" xml:space="preserve">
    <value>免息</value>
  </data>
  <data name="txtIOUPenaltyDailyNeedReduce" xml:space="preserve">
    <value>明細需減額</value>
  </data>
  <data name="txtIOUPenaltyTotalDtl" xml:space="preserve">
    <value>罰息明細總額</value>
  </data>
  <data name="txtIOUPenaltyDailyNeedAdd" xml:space="preserve">
    <value>明細需加額</value>
  </data>
  <data name="global_msgInfoIsTransferRecord" xml:space="preserve">
    <value>積分調整記錄</value>
  </data>
  <data name="txtWithStore" xml:space="preserve">
    <value>連本金</value>
  </data>
  <data name="action_RPT_CHECK_AGENT_type" xml:space="preserve">
    <value>無戶口限制</value>
  </data>
  <data name="action_RPT_SHARE_LEVEL_type" xml:space="preserve">
    <value>可查閱股東層</value>
  </data>
  <data name="typeRPTCREDITTRANRPT_Core" xml:space="preserve">
    <value>借貸批額報表</value>
  </data>
  <data name="typeRAGENTINFORPT_Core" xml:space="preserve">
    <value>戶口資料表</value>
  </data>
  <data name="typeRAGENTLEVELINFORPT_Core" xml:space="preserve">
    <value>戶口身份級別報表</value>
  </data>
  <data name="typeRBUSINESSRPT_Core" xml:space="preserve">
    <value>業績報表</value>
  </data>
  <data name="typeRTOPVIPROLLTREERPT_Core" xml:space="preserve">
    <value>VIP轉碼報表</value>
  </data>
  <data name="typeCREDITISDIRECTACCEXPIRERPT_Core" xml:space="preserve">
    <value>直接授信批額過期</value>
  </data>
  <data name="txtBindingMobileSunAppsPhoneNum" xml:space="preserve">
    <value>綁定太陽城APPS號碼</value>
  </data>
  <data name="typeBFTRANTRANSFERDTL_Core" xml:space="preserve">
    <value>新增積分調整</value>
  </data>
  <data name="typeBFTRANTRANSFERLST_Core" xml:space="preserve">
    <value>積分調整管理</value>
  </data>
  <data name="txtAgentCodeFrom" xml:space="preserve">
    <value>由戶口</value>
  </data>
  <data name="txtAgentCodeTo" xml:space="preserve">
    <value>至戶口</value>
  </data>
  <data name="txtPointMove" xml:space="preserve">
    <value>搬積分數</value>
  </data>
  <data name="txtWhetherShareExpOnly" xml:space="preserve">
    <value>是否共用</value>
  </data>
  <data name="global_msgErrRtnTotalAmt" xml:space="preserve">
    <value>搬積分多於總餘數</value>
  </data>
  <data name="typeSETTLECOMMISIONENQUIRY_Core" xml:space="preserve">
    <value>月結佣金設定查詢</value>
  </data>
  <data name="txtPHP" xml:space="preserve">
    <value>披索</value>
  </data>
  <data name="typeREXPTRANDTLRPT_Report" xml:space="preserve">
    <value>消費明細報表</value>
  </data>
  <data name="global_txtBNumberLimit" xml:space="preserve">
    <value>B數有上限(封頂)</value>
  </data>
  <data name="global_txtBookTable" xml:space="preserve">
    <value>包枱</value>
  </data>
  <data name="global_txtClosing" xml:space="preserve">
    <value>關閉中</value>
  </data>
  <data name="global_txtAllDay" xml:space="preserve">
    <value>全日</value>
  </data>
  <data name="txtBorrowerAmt10K" xml:space="preserve">
    <value>貸款金額(萬)</value>
  </data>
  <data name="txtTotSetAmtHKD10K" xml:space="preserve">
    <value>歸還額(萬)(港幣結算)</value>
  </data>
  <data name="txtMRM10K" xml:space="preserve">
    <value>M還M(萬)</value>
  </data>
  <data name="txtMarkerReturnTypeR10K" xml:space="preserve">
    <value>存M還M(萬)</value>
  </data>
  <data name="txtMarkerReturnTypeC10K" xml:space="preserve">
    <value>現碼還M(萬)</value>
  </data>
  <data name="txtGRM10K" xml:space="preserve">
    <value>贏錢回舊M(萬)</value>
  </data>
  <data name="txtCommRetM10K" xml:space="preserve">
    <value>佣金回M(萬)</value>
  </data>
  <data name="txtIOURtnDays" xml:space="preserve">
    <value>借貸單還款日數</value>
  </data>
  <data name="txtIOUNoOfOverDue" xml:space="preserve">
    <value>借貸單過期次數</value>
  </data>
  <data name="wIsSupremacy" xml:space="preserve">
    <value>至尊</value>
  </data>
  <data name="typeAGENTSPECIALACCTYPE_Core" xml:space="preserve">
    <value>特別會員類型設定</value>
  </data>
  <data name="txtAgentSpecialAccountTypeLabel" xml:space="preserve">
    <value>特別會員類型設定</value>
  </data>
  <data name="txtGroup" xml:space="preserve">
    <value>組</value>
  </data>
  <data name="typeSETTLEITEMDRINKSETLST_Core" xml:space="preserve">
    <value>股東組食津設定表</value>
  </data>
  <data name="typeSETTLEITEMDRINKSETDTL_Core" xml:space="preserve">
    <value>股東組食津設定記錄</value>
  </data>
  <data name="global_msgBuyChipRequestNotReady" xml:space="preserve">
    <value>電投短號配對中，請稍後再列印。</value>
  </data>
  <data name="txtUsePeriod" xml:space="preserve">
    <value>使用週期</value>
  </data>
  <data name="txtQuestionnaireForm" xml:space="preserve">
    <value>問卷調查表</value>
  </data>
  <data name="txtCompWinLossCompLst" xml:space="preserve">
    <value>場館設定</value>
  </data>
  <data name="txtCOMPWINLOSSCOMPDTL" xml:space="preserve">
    <value>場館設定</value>
  </data>
  <data name="typeCOMPWINLOSSCOMPDTL_Core" xml:space="preserve">
    <value>場館設定</value>
  </data>
  <data name="typeCOMPWINLOSSCOMPLST_Core" xml:space="preserve">
    <value>場館設定</value>
  </data>
  <data name="txtCompWinLossCompCode" xml:space="preserve">
    <value>場館編號</value>
  </data>
  <data name="global_txtCompWinLossComp" xml:space="preserve">
    <value>會名</value>
  </data>
  <data name="global_msgCannotInputDuplicate" xml:space="preserve">
    <value>不能重複輸入</value>
  </data>
  <data name="typeCOMPWINLOSSTRANDTLSPL_Core" xml:space="preserve">
    <value>賭場上下數詳細(特別權限)</value>
  </data>
  <data name="txtCustBlackListLst" xml:space="preserve">
    <value>客人黑名單</value>
  </data>
  <data name="typeCUSTBLACKLISTLST_Core" xml:space="preserve">
    <value>客人黑名單</value>
  </data>
  <data name="typeCUSTBLACKLISTDTL_Core" xml:space="preserve">
    <value>客人黑名單</value>
  </data>
  <data name="txtCustBlackListDtl" xml:space="preserve">
    <value>客人黑名單</value>
  </data>
  <data name="txtAgentRollingMonth" xml:space="preserve">
    <value>戶口有轉碼月份</value>
  </data>
  <data name="txtIOUOfOverDue" xml:space="preserve">
    <value>借貸過期次數</value>
  </data>
  <data name="txtOverDue" xml:space="preserve">
    <value>過期次數</value>
  </data>
  <data name="txtRollingMonth" xml:space="preserve">
    <value>累計轉碼月份</value>
  </data>
  <data name="txtTotalMonth" xml:space="preserve">
    <value>累計月份</value>
  </data>
  <data name="txtTotalOverDue" xml:space="preserve">
    <value>總過期</value>
  </data>
  <data name="txtAnnual" xml:space="preserve">
    <value>年度</value>
  </data>
  <data name="txtMonth1" xml:space="preserve">
    <value>1月</value>
  </data>
  <data name="txtMonth10" xml:space="preserve">
    <value>10月</value>
  </data>
  <data name="txtMonth11" xml:space="preserve">
    <value>11月</value>
  </data>
  <data name="txtMonth12" xml:space="preserve">
    <value>12月</value>
  </data>
  <data name="txtMonth2" xml:space="preserve">
    <value>2月</value>
  </data>
  <data name="txtMonth3" xml:space="preserve">
    <value>3月</value>
  </data>
  <data name="txtMonth4" xml:space="preserve">
    <value>4月</value>
  </data>
  <data name="txtMonth5" xml:space="preserve">
    <value>5月</value>
  </data>
  <data name="txtMonth6" xml:space="preserve">
    <value>6月</value>
  </data>
  <data name="txtMonth7" xml:space="preserve">
    <value>7月</value>
  </data>
  <data name="txtMonth8" xml:space="preserve">
    <value>8月</value>
  </data>
  <data name="txtMonth9" xml:space="preserve">
    <value>9月</value>
  </data>
  <data name="msgMarkerMorethenAvaChip" xml:space="preserve">
    <value>借貸金額大於可動用結存</value>
  </data>
  <data name="global_txtUserCName" xml:space="preserve">
    <value>員工姓名</value>
  </data>
  <data name="global_txtSCMTelB" xml:space="preserve">
    <value>SCM電投</value>
  </data>
  <data name="typeRemittanceTran_EXLst_Core" xml:space="preserve">
    <value>匯款交易</value>
  </data>
  <data name="typeRemittanceTran_EXCHANGE_Core" xml:space="preserve">
    <value>交易</value>
  </data>
  <data name="txtDirectCreditAccWithDownLine" xml:space="preserve">
    <value>直接授信(包括下線)</value>
  </data>
  <data name="typeCREDITDTLPRESET_Core" xml:space="preserve">
    <value>臨時批額記錄</value>
  </data>
  <data name="txtStatusPending" xml:space="preserve">
    <value>設定中</value>
  </data>
  <data name="txtStatusActive" xml:space="preserve">
    <value>執行中</value>
  </data>
  <data name="txtStatusCancel" xml:space="preserve">
    <value>已取消</value>
  </data>
  <data name="txtStatusDone" xml:space="preserve">
    <value>已完結</value>
  </data>
  <data name="global_txtEndDate" xml:space="preserve">
    <value>結束日期</value>
  </data>
  <data name="msgStartDateLargerThenToday" xml:space="preserve">
    <value>開始日期必須大於{0}</value>
  </data>
  <data name="msgEndDateLargerThenToday" xml:space="preserve">
    <value>結束日期必須大於{0}</value>
  </data>
  <data name="msgEndDateLargerThenStartday" xml:space="preserve">
    <value>結束日期必須大於開始日期</value>
  </data>
  <data name="btnAddTmpCredit" xml:space="preserve">
    <value>新增臨時批額</value>
  </data>
  <data name="txtAccAmount" xml:space="preserve">
    <value>累計數</value>
  </data>
  <data name="txtExpireAmt" xml:space="preserve">
    <value>過期金額</value>
  </data>
  <data name="txtLastResponse" xml:space="preserve">
    <value>最新回應</value>
  </data>
  <data name="txtSCMGunner" xml:space="preserve">
    <value>SCM電投員</value>
  </data>
  <data name="typeCUSTEXTERNALROLLAPPROVAL_Core" xml:space="preserve">
    <value>客人買碼確認</value>
  </data>
  <data name="txtCustExternalRoll" xml:space="preserve">
    <value>客人買碼</value>
  </data>
  <data name="CreditControlNoticeCreditAmtValFormat" xml:space="preserve">
    <value>{5}{0}{1} 和 {2}{1}{3} ({4})</value>
  </data>
  <data name="txtOnlyInterest_Opt" xml:space="preserve">
    <value>只有利息</value>
  </data>
  <data name="global_txtAskConfirmCiscoAgent" xml:space="preserve">
    <value>收到來電戶口，確定顯示？</value>
  </data>
  <data name="global_txtTelExt" xml:space="preserve">
    <value>內線編號</value>
  </data>
  <data name="global_msgCiscoAgent" xml:space="preserve">
    <value>收到來電戶口</value>
  </data>
  <data name="txtTelExtAgent" xml:space="preserve">
    <value>來電戶口</value>
  </data>
  <data name="txtPending" xml:space="preserve">
    <value>待定</value>
  </data>
  <data name="typeAGENTCREDITPRESET_Report" xml:space="preserve">
    <value>代理臨時批額報表</value>
  </data>
  <data name="wRollingAmount_Instant_10k" xml:space="preserve">
    <value>本月已即出轉碼(萬)</value>
  </data>
  <data name="wCashRollMI_10k" xml:space="preserve">
    <value>月息轉碼(萬)</value>
  </data>
  <data name="typeGIFTLST_Core" xml:space="preserve">
    <value>禮品管理</value>
  </data>
  <data name="txtGiftType" xml:space="preserve">
    <value>禮品種類</value>
  </data>
  <data name="txtRedemptionPoints" xml:space="preserve">
    <value>換領分數</value>
  </data>
  <data name="msgInfoRecUpdated_ConfirmSearch" xml:space="preserve">
    <value>記錄有改動,是否繼續搜尋?</value>
  </data>
  <data name="ROVE_TRAN_TYPE_A" xml:space="preserve">
    <value>鎖售現金碼或代用碼</value>
  </data>
  <data name="ROVE_TRAN_TYPE_B" xml:space="preserve">
    <value>鎖售泥碼</value>
  </data>
  <data name="ROVE_TRAN_TYPE_C" xml:space="preserve">
    <value>鎖售買碼券和其他代用券</value>
  </data>
  <data name="ROVE_TRAN_TYPE_D" xml:space="preserve">
    <value>存入定金</value>
  </data>
  <data name="ROVE_TRAN_TYPE_E" xml:space="preserve">
    <value>贖回借據/償還賒帳</value>
  </data>
  <data name="ROVE_TRAN_TYPE_F" xml:space="preserve">
    <value>錦標賽/競賽入場費</value>
  </data>
  <data name="ROVE_TRAN_TYPE_G" xml:space="preserve">
    <value>博彩結帳收入</value>
  </data>
  <data name="ROVE_TRAN_TYPE_H" xml:space="preserve">
    <value>其他存入(請註明)</value>
  </data>
  <data name="ROVE_TRAN_TYPE_K" xml:space="preserve">
    <value>兌換金碼(本金)或代幣</value>
  </data>
  <data name="ROVE_TRAN_TYPE_L" xml:space="preserve">
    <value>兌現呢碼</value>
  </data>
  <data name="ROVE_TRAN_TYPE_M" xml:space="preserve">
    <value>兌現買碼券和其他代用券</value>
  </data>
  <data name="ROVE_TRAN_TYPE_N" xml:space="preserve">
    <value>提取定金</value>
  </data>
  <data name="ROVE_TRAN_TYPE_O" xml:space="preserve">
    <value>中介人與娛樂場結帳</value>
  </data>
  <data name="ROVE_TRAN_TYPE_P" xml:space="preserve">
    <value>中介人貸款予客人</value>
  </data>
  <data name="ROVE_TRAN_TYPE_Q" xml:space="preserve">
    <value>娛樂桌淨贏支付</value>
  </data>
  <data name="ROVE_TRAN_TYPE_R" xml:space="preserve">
    <value>角子機累積大奬支付</value>
  </data>
  <data name="ROVE_TRAN_TYPE_S" xml:space="preserve">
    <value>角子機帳面餘額支付/取消</value>
  </data>
  <data name="ROVE_TRAN_TYPE_T" xml:space="preserve">
    <value>錦標賽/競賽支出</value>
  </data>
  <data name="ROVE_TRAN_TYPE_U" xml:space="preserve">
    <value>其他支付/競賽支出</value>
  </data>
  <data name="typeROVEDTL_Core" xml:space="preserve">
    <value>巨額報表</value>
  </data>
  <data name="typeROVELST_Core" xml:space="preserve">
    <value>巨額報表管理</value>
  </data>
  <data name="wAgentLicenseNo" xml:space="preserve">
    <value>戶口許可證號</value>
  </data>
  <data name="wBank" xml:space="preserve">
    <value>銀行名稱</value>
  </data>
  <data name="wFundTransfer" xml:space="preserve">
    <value>飛碼</value>
  </data>
  <data name="wReportNo" xml:space="preserve">
    <value>報表編號</value>
  </data>
  <data name="wReviewedBy" xml:space="preserve">
    <value>覆核者</value>
  </data>
  <data name="wSourceOfFund" xml:space="preserve">
    <value>資金來源</value>
  </data>
  <data name="wTenderType" xml:space="preserve">
    <value>資金種類</value>
  </data>
  <data name="wTransactionDate" xml:space="preserve">
    <value>交易日期</value>
  </data>
  <data name="wRelName" xml:space="preserve">
    <value>付款人/收款人/匯款人姓名</value>
  </data>
  <data name="typeEVENTLST_Core" xml:space="preserve">
    <value>活動管理</value>
  </data>
  <data name="typeEVENTDTL_Core" xml:space="preserve">
    <value>活動詳情</value>
  </data>
  <data name="wGiftExpireDt" xml:space="preserve">
    <value>換領日期</value>
  </data>
  <data name="txtEventDate" xml:space="preserve">
    <value>活動日期</value>
  </data>
  <data name="typeAGENTFOLLOW_Core" xml:space="preserve">
    <value>代理跟進管理</value>
  </data>
  <data name="txtAgentFollowGrp" xml:space="preserve">
    <value>代理跟進組別</value>
  </data>
  <data name="txtAgentFollowDtl" xml:space="preserve">
    <value>代理跟進組別人</value>
  </data>
  <data name="txtTeamMembers" xml:space="preserve">
    <value>組別人員</value>
  </data>
  <data name="txtTeamName" xml:space="preserve">
    <value>組別名稱</value>
  </data>
  <data name="txtRoveTranMerger" xml:space="preserve">
    <value>巨額報表合併</value>
  </data>
  <data name="txtSaving" xml:space="preserve">
    <value>儲蓄</value>
  </data>
  <data name="wIDType_OtherID" xml:space="preserve">
    <value>其他國家身份證</value>
  </data>
  <data name="global_txtCompanySetVietnam" xml:space="preserve">
    <value>公司預設(越南)</value>
  </data>
  <data name="global_txtIndividualAgentSetVietnam" xml:space="preserve">
    <value>個別戶口線設定(越南)</value>
  </data>
  <data name="typeBTMVISACARDLST_Core" xml:space="preserve">
    <value>BTM Visa卡管理</value>
  </data>
  <data name="txtBTMVisaCardDtl" xml:space="preserve">
    <value>BTM Visa卡記錄</value>
  </data>
  <data name="txtCardCollection1" xml:space="preserve">
    <value>濠庭都會BNU分行 (氹仔)</value>
  </data>
  <data name="txtCardCollection2" xml:space="preserve">
    <value>光輝苑BNU分行 (澳門)</value>
  </data>
  <data name="txtCardCollection" xml:space="preserve">
    <value>取卡地點</value>
  </data>
  <data name="typeBTMVISACARDAPPLYLST_Core" xml:space="preserve">
    <value>BTM Visa申請記錄</value>
  </data>
  <data name="Expense_txtNewApply" xml:space="preserve">
    <value>新申請</value>
  </data>
  <data name="Expense_txtCreditChange" xml:space="preserve">
    <value>信用額更新</value>
  </data>
  <data name="Expense_txtBTMVisaCardStatus_I" xml:space="preserve">
    <value>申請中</value>
  </data>
  <data name="Expense_txtBTMVisaCardStatus_R" xml:space="preserve">
    <value>被拒絕</value>
  </data>
  <data name="Expense_txtBTMVisaCardStatus_A" xml:space="preserve">
    <value>可使用</value>
  </data>
  <data name="Expense_txtBTMVisaCardStatus_S" xml:space="preserve">
    <value>被冷結</value>
  </data>
  <data name="Expense_txtBTMVisaCardStatus_C" xml:space="preserve">
    <value>被取消</value>
  </data>
  <data name="typeROVETRANMERGER_Core" xml:space="preserve">
    <value>巨額報表合併</value>
  </data>
  <data name="global_msgTransactionDateErr" xml:space="preserve">
    <value>所有報表必須在同一交易日期</value>
  </data>
  <data name="txtDial" xml:space="preserve">
    <value>撥號</value>
  </data>
  <data name="txtOperateSettleInfo" xml:space="preserve">
    <value>結算資料</value>
  </data>
  <data name="txtAge" xml:space="preserve">
    <value>年齡</value>
  </data>
  <data name="txtYearsOld" xml:space="preserve">
    <value>歲</value>
  </data>
  <data name="txtEventRule" xml:space="preserve">
    <value>活動規則</value>
  </data>
  <data name="txtEventRuleDesc" xml:space="preserve">
    <value>活動規則-細節</value>
  </data>
  <data name="txtEventName" xml:space="preserve">
    <value>活動名稱</value>
  </data>
  <data name="global_txtBadDebt" xml:space="preserve">
    <value>壞帳</value>
  </data>
  <data name="txtAmount10k" xml:space="preserve">
    <value>全額(萬)</value>
  </data>
  <data name="txtAmountAlmostOverdue10k" xml:space="preserve">
    <value>到期數(萬)</value>
  </data>
  <data name="txtAmountOverdue10k" xml:space="preserve">
    <value>過期數(萬)</value>
  </data>
  <data name="txtDailyPenaltyAdd10k" xml:space="preserve">
    <value>每日增加罰息(萬)</value>
  </data>
  <data name="txtDownLineAlmostOverDue10k" xml:space="preserve">
    <value>下線到期數(萬)</value>
  </data>
  <data name="txtDownLineAmount10k" xml:space="preserve">
    <value>下線借貸額(萬)</value>
  </data>
  <data name="txtDownlineDailyPenaltyAdd10k" xml:space="preserve">
    <value>下線每日增加罰息(萬)</value>
  </data>
  <data name="txtDownLineOverDue10k" xml:space="preserve">
    <value>下線過期數(萬)</value>
  </data>
  <data name="txtDownlinePenaltyInterest10k" xml:space="preserve">
    <value>下線罰息(萬)</value>
  </data>
  <data name="txtFreezeAmount10k" xml:space="preserve">
    <value>凍結金額(萬)</value>
  </data>
  <data name="txtLongestOverdueDays" xml:space="preserve">
    <value>最大過期天數</value>
  </data>
  <data name="txtMthInterestBill10k" xml:space="preserve">
    <value>月息單(萬)</value>
  </data>
  <data name="txtNumOfMarker" xml:space="preserve">
    <value>借貸單數</value>
  </data>
  <data name="txtNumOfOverdue" xml:space="preserve">
    <value>過期單數</value>
  </data>
  <data name="txtRemainCreditDay" xml:space="preserve">
    <value>剩餘寬限天數</value>
  </data>
  <data name="txtReturnInterest10k" xml:space="preserve">
    <value>還息(萬)</value>
  </data>
  <data name="txtUMarkerAmount10K" xml:space="preserve">
    <value>U信貸額(萬)</value>
  </data>
  <data name="txtGetWinLoss" xml:space="preserve">
    <value>匯入上下數</value>
  </data>
  <data name="txtTemp" xml:space="preserve">
    <value>臨時</value>
  </data>
  <data name="action_CONTRACTNO_type" xml:space="preserve">
    <value>合同編號</value>
  </data>
  <data name="txtAddCapitalRemark" xml:space="preserve">
    <value>加彩備註</value>
  </data>
  <data name="txtAddCapitalType" xml:space="preserve">
    <value>加彩本金種類</value>
  </data>
  <data name="msgAddCapitalTypeError" xml:space="preserve">
    <value>加彩找不到相關本金種類</value>
  </data>
  <data name="global_txtTelExtIn" xml:space="preserve">
    <value>來電內線</value>
  </data>
  <data name="global_txtTelExtOut" xml:space="preserve">
    <value>撥號內線</value>
  </data>
  <data name="txtLvl2CrContractNo" xml:space="preserve">
    <value>二級授信編號</value>
  </data>
  <data name="global_txtAskConfirmNewCrContractNo" xml:space="preserve">
    <value>確定新增二級授信編號?</value>
  </data>
  <data name="msgCannotExistSameTime_IOUAndCreditContractNo" xml:space="preserve">
    <value>二級授信合同號與借貸合同號不能共存</value>
  </data>
  <data name="txtContract" xml:space="preserve">
    <value>合同</value>
  </data>
  <data name="txtMarkDone" xml:space="preserve">
    <value>標記完成</value>
  </data>
  <data name="typeDEPTNOTIFICATIONLST_Core" xml:space="preserve">
    <value>部門通知清單</value>
  </data>
  <data name="txtFmDept" xml:space="preserve">
    <value>發送部門</value>
  </data>
  <data name="txtToDept" xml:space="preserve">
    <value>收訊部門</value>
  </data>
  <data name="typeAGENTFOLLOWDTL_Core" xml:space="preserve">
    <value>代理跟進記錄</value>
  </data>
  <data name="txtWait" xml:space="preserve">
    <value>稍候</value>
  </data>
  <data name="global_msgNegativeAmtAfterRolling" xml:space="preserve">
    <value>退碼後戶口轉碼為負數</value>
  </data>
  <data name="typeLIMOBOOKING_Core" xml:space="preserve">
    <value>LIMO 預約</value>
  </data>
  <data name="wRoute" xml:space="preserve">
    <value>規定路線</value>
  </data>
  <data name="btn_RollingDtl" xml:space="preserve">
    <value>轉碼細數</value>
  </data>
  <data name="wPhoneDist" xml:space="preserve">
    <value>電話地區編號</value>
  </data>
  <data name="wStaffPhoneDist" xml:space="preserve">
    <value>員工電話地區編號</value>
  </data>
  <data name="wCustomerRemark" xml:space="preserve">
    <value>客人備註</value>
  </data>
  <data name="wAgentAndCustSamePerson" xml:space="preserve">
    <value>與客人為同一個人</value>
  </data>
  <data name="txtInbox" xml:space="preserve">
    <value>收件箱</value>
  </data>
  <data name="txtSent" xml:space="preserve">
    <value>發送框（未讀）</value>
  </data>
  <data name="global_msgCompNoErr" xml:space="preserve">
    <value>所有報表必須在同一公司</value>
  </data>
  <data name="wAssessRemark" xml:space="preserve">
    <value>評估記錄</value>
  </data>
  <data name="wPenaltyProblemRemark" xml:space="preserve">
    <value>利息問題</value>
  </data>
  <data name="wTmpCreditRemark" xml:space="preserve">
    <value>臨時額記錄</value>
  </data>
  <data name="typeAGENTMEMBERCARDOTHER_Core" xml:space="preserve">
    <value>會員卡及其他編輯</value>
  </data>
  <data name="typeAPPLICATIONFORM_CORE" xml:space="preserve">
    <value>開戶申請表</value>
  </data>
  <data name="wDLAgentExpCredit" xml:space="preserve">
    <value>消費擔保</value>
  </data>
  <data name="txtSetLIMOSuccess" xml:space="preserve">
    <value>LIMO預約成功，請耐心等候來電確認。</value>
  </data>
  <data name="txtSetLIMOFail" xml:space="preserve">
    <value>LIMO預約失敗，請再嘗試。

詳情 :{0}
    </value>
  </data>
  <data name="typeRACCQUEFORMBYDATE_Report" xml:space="preserve">
    <value>滿意度及問卷調查表</value>
  </data>
  <data name="txtBPlayRollSourceType" xml:space="preserve">
    <value>凍柴類型</value>
  </data>
  <data name="typeBTMVISACARDCREDIT_Core" xml:space="preserve">
    <value>BTM Visa設定信用額</value>
  </data>
  <data name="Expense_txtFormNo" xml:space="preserve">
    <value>申請編號</value>
  </data>
  <data name="typeRACCOUNTRATEDIFFREPORT_Report" xml:space="preserve">
    <value>理應匯差表</value>
  </data>
  <data name="typeAGENTCONTACTLST_CORE" xml:space="preserve">
    <value>代理聯絡管理</value>
  </data>
  <data name="typeAGENTCONTACTDTL_CORE" xml:space="preserve">
    <value>代理聯絡記錄</value>
  </data>
  <data name="typeRIOUPENALTYSET_Report" xml:space="preserve">
    <value>罰息設定報表</value>
  </data>
  <data name="TxtTempSettleWithBracket" xml:space="preserve">
    <value>(臨時結算)</value>
  </data>
  <data name="txtPlaceFloorLineColor" xml:space="preserve">
    <value>平面圖線顏色</value>
  </data>
  <data name="txtPlaceFloorLineThickness" xml:space="preserve">
    <value>平面圖線大小</value>
  </data>
  <data name="msgRptBusinessRollingInputWarning" xml:space="preserve">
    <value>必需輸入戶口或勾選戶口類型</value>
  </data>
  <data name="wAgentRatio" xml:space="preserve">
    <value>代</value>
  </data>
  <data name="wCapitalRatio" xml:space="preserve">
    <value>本金比例</value>
  </data>
  <data name="wCountRatio" xml:space="preserve">
    <value>場次比例</value>
  </data>
  <data name="wGamblersRatio" xml:space="preserve">
    <value>玩</value>
  </data>
  <data name="typeEMI_Core" xml:space="preserve">
    <value>EMI</value>
  </data>
  <data name="txtUsrCapitalTran" xml:space="preserve">
    <value>員工月息單管理</value>
  </data>
  <data name="txtHours" xml:space="preserve">
    <value>小時</value>
  </data>
  <data name="txtWithin" xml:space="preserve">
    <value>內</value>
  </data>
  <data name="type48hrsExpNoRolling_Report" xml:space="preserve">
    <value>48小時內有消費沒轉碼報表</value>
  </data>
  <data name="wDepartment" xml:space="preserve">
    <value>部門</value>
  </data>
  <data name="global_txtTeam" xml:space="preserve">
    <value>小組</value>
  </data>
  <data name="global_txtTeamMember" xml:space="preserve">
    <value>員工</value>
  </data>
  <data name="wContactLocation" xml:space="preserve">
    <value>約見地點</value>
  </data>
  <data name="wContactPersonCName" xml:space="preserve">
    <value>跟進人名稱</value>
  </data>
  <data name="statusInactive" xml:space="preserve">
    <value>無效</value>
  </data>
  <data name="typeAGENTRECENTREMARKHIS_Core" xml:space="preserve">
    <value>戶口備註</value>
  </data>
  <data name="txtCurExpAmount" xml:space="preserve">
    <value>本月消費</value>
  </data>
  <data name="txtLvl2Credit" xml:space="preserve">
    <value>二級授信</value>
  </data>
  <data name="typeTEAMTARGET_SETTING_Core" xml:space="preserve">
    <value>組別目標設定</value>
  </data>
  <data name="txtDepartment" xml:space="preserve">
    <value>部門</value>
  </data>
  <data name="txtTeam" xml:space="preserve">
    <value>組別</value>
  </data>
  <data name="txtTargetType" xml:space="preserve">
    <value>目標類型</value>
  </data>
  <data name="txtTarget" xml:space="preserve">
    <value>目標</value>
  </data>
  <data name="typeUSRCAPITALTRANLST_Core" xml:space="preserve">
    <value>員工月息單管理</value>
  </data>
  <data name="txtUsrChipTran" xml:space="preserve">
    <value>員工存卡管理</value>
  </data>
  <data name="typeUSRCHIPTRANLST_Core" xml:space="preserve">
    <value>員工存卡管理</value>
  </data>
  <data name="txtIOUPenaltyAmt10K" xml:space="preserve">
    <value>罰息扣結算金額（萬）</value>
  </data>
  <data name="txtDialing" xml:space="preserve">
    <value>正在撥號中</value>
  </data>
  <data name="txtSMSOperateUpRatio" xml:space="preserve">
    <value>營運更正佔成</value>
  </data>
  <data name="txtRank" xml:space="preserve">
    <value>排名</value>
  </data>
  <data name="typeRACCOUNTINGSUMMARYRPT_Report" xml:space="preserve">
    <value>會計總表</value>
  </data>
  <data name="wForeignJunket" xml:space="preserve">
    <value>海外貴賓廳</value>
  </data>
  <data name="wMacauJunket" xml:space="preserve">
    <value>澳門貴賓廳</value>
  </data>
  <data name="txtWinLoss" xml:space="preserve">
    <value>上下數</value>
  </data>
  <data name="txtPlace" xml:space="preserve">
    <value>場館</value>
  </data>
  <data name="txtSelectedDate" xml:space="preserve">
    <value>當日</value>
  </data>
  <data name="txtAccumulate" xml:space="preserve">
    <value>累計</value>
  </data>
  <data name="txtCurrentMonth" xml:space="preserve">
    <value>本月</value>
  </data>
  <data name="txtWinLossAmt" xml:space="preserve">
    <value>殺數</value>
  </data>
  <data name="typeGIFTTRANLST_Core" xml:space="preserve">
    <value>禮品換領管理</value>
  </data>
  <data name="wGiftGotValue" xml:space="preserve">
    <value>所得積分</value>
  </data>
  <data name="wGiftUsedValue" xml:space="preserve">
    <value>已用積分</value>
  </data>
  <data name="wGiftBalValue" xml:space="preserve">
    <value>尚餘積分</value>
  </data>
  <data name="typeGIFTTRANREDEM_Core" xml:space="preserve">
    <value>禮品換領</value>
  </data>
  <data name="txtTeamTargetType_CashRolling" xml:space="preserve">
    <value>現金轉碼</value>
  </data>
  <data name="txtTeamTargetType_IOURolling" xml:space="preserve">
    <value>M轉碼</value>
  </data>
  <data name="txtTeamTargetType_CNYRolling" xml:space="preserve">
    <value>CNY轉碼</value>
  </data>
  <data name="txtTeamTargetType_OperateRolling" xml:space="preserve">
    <value>營運轉碼</value>
  </data>
  <data name="typeEMIRPT_ReportGrp" xml:space="preserve">
    <value>EMI報表</value>
  </data>
  <data name="typeEMIDEPOSITWITHDRAWRPT_Report" xml:space="preserve">
    <value>員工存取報表</value>
  </data>
  <data name="wStoreOutOneTimeLimit" xml:space="preserve">
    <value>單次可動用金額</value>
  </data>
  <data name="wStoreOutPeriodLimit" xml:space="preserve">
    <value>期限可動用金額</value>
  </data>
  <data name="txtStoreOutCheck" xml:space="preserve">
    <value>可動用金額-授權人</value>
  </data>
  <data name="txtStoreOutCheckPw" xml:space="preserve">
    <value>可動用金額-授權人密碼</value>
  </data>
  <data name="SMS_OUTSTORE_LIMIT" xml:space="preserve">
    <value>可動用金額</value>
  </data>
  <data name="txtNotContactAgentCount" xml:space="preserve">
    <value>未連絡戶口數</value>
  </data>
  <data name="txtResponseAgentCount" xml:space="preserve">
    <value>負責戶口數</value>
  </data>
  <data name="txtCompletionRatio" xml:space="preserve">
    <value>完成度</value>
  </data>
  <data name="txtCurYear" xml:space="preserve">
    <value>本年</value>
  </data>
  <data name="txtPrevYear" xml:space="preserve">
    <value>上年</value>
  </data>
  <data name="txtBeforeLastYear" xml:space="preserve">
    <value>前年</value>
  </data>
  <data name="txtLastInDate" xml:space="preserve">
    <value>最後進場</value>
  </data>
  <data name="txtLastContactDate" xml:space="preserve">
    <value>上次聯絡</value>
  </data>
  <data name="txtCurMthRollingMultiple" xml:space="preserve">
    <value>本月轉碼倍數</value>
  </data>
  <data name="txtPrevMthRollingMultiple" xml:space="preserve">
    <value>上月轉碼倍數</value>
  </data>
  <data name="txtCurMthCredited" xml:space="preserve">
    <value>本月已簽</value>
  </data>
  <data name="txtCurMthCredit" xml:space="preserve">
    <value>本月批額</value>
  </data>
  <data name="txtCurMthOverDue" xml:space="preserve">
    <value>本月已過期</value>
  </data>
  <data name="txtCurMthCashRolling" xml:space="preserve">
    <value>本月現金轉碼</value>
  </data>
  <data name="txtCurMthMartkerRolling" xml:space="preserve">
    <value>本月M轉碼</value>
  </data>
  <data name="txtCurMthCNYRolling" xml:space="preserve">
    <value>本月CNY轉碼</value>
  </data>
  <data name="txtCurMthOperateRolling" xml:space="preserve">
    <value>本月營運轉碼</value>
  </data>
  <data name="txtPrevMthCashRolling" xml:space="preserve">
    <value>上月現金轉碼</value>
  </data>
  <data name="txtCurMthTotalRolling" xml:space="preserve">
    <value>本月總轉碼</value>
  </data>
  <data name="txtPrevMthTotalRolling" xml:space="preserve">
    <value>上月總轉碼</value>
  </data>
  <data name="txtCurMthAvgInRollingAmt" xml:space="preserve">
    <value>本月平均進場</value>
  </data>
  <data name="txtPrevMthAvgInRollingAmt" xml:space="preserve">
    <value>上月平均進場</value>
  </data>
  <data name="txtCurMthRollingKeyAmt" xml:space="preserve">
    <value>本月本金</value>
  </data>
  <data name="txtPrevMthRollingKeyAmt" xml:space="preserve">
    <value>上月本金</value>
  </data>
  <data name="txtCurMthCustWinLossAmt" xml:space="preserve">
    <value>本月上下數</value>
  </data>
  <data name="txtPrevMthCustWinLossAmt" xml:space="preserve">
    <value>上月上下數</value>
  </data>
  <data name="txtCurYearCustWinLossAmt" xml:space="preserve">
    <value>本年上下數</value>
  </data>
  <data name="txtPrevYearCustWinLossAmt" xml:space="preserve">
    <value>上年上下數</value>
  </data>
  <data name="txtBeforeLastYearCustWinLossAmt" xml:space="preserve">
    <value>前年上下數</value>
  </data>
  <data name="txtCurYearTotalRolling" xml:space="preserve">
    <value>本年總轉碼</value>
  </data>
  <data name="txtPrevYearTotalRolling" xml:space="preserve">
    <value>上年總轉碼</value>
  </data>
  <data name="txtBeforeLastYearTotalRolling" xml:space="preserve">
    <value>前年總轉碼</value>
  </data>
  <data name="typeMDDASHBOARD_Core" xml:space="preserve">
    <value>市場部代理管理</value>
  </data>
  <data name="txtCreditAccount" xml:space="preserve">
    <value>批額戶口</value>
  </data>
  <data name="txtCashAccount" xml:space="preserve">
    <value>現金戶口</value>
  </data>
  <data name="typeSTOREOUTLIMIT_Core" xml:space="preserve">
    <value>可動用金額特批</value>
  </data>
  <data name="typeTARGETROLLINGDTL_Core" xml:space="preserve">
    <value>目標轉碼數</value>
  </data>
  <data name="typeTARGETROLLINGLST_Core" xml:space="preserve">
    <value>目標轉碼數</value>
  </data>
  <data name="wTargetAmt" xml:space="preserve">
    <value>目標數</value>
  </data>
  <data name="typeFOREIGNTRANDTLV2_Core" xml:space="preserve">
    <value>海外記錄V2</value>
  </data>
  <data name="txtForeignSettleV2" xml:space="preserve">
    <value>海外結算V2</value>
  </data>
  <data name="global_txtServiceCounter" xml:space="preserve">
    <value>服務櫃臺</value>
  </data>
  <data name="txtCannot" xml:space="preserve">
    <value>不能</value>
  </data>
  <data name="typeSTAFFFOLLOWLST_Core" xml:space="preserve">
    <value>員工跟進代理管理</value>
  </data>
  <data name="txtStaffFollowDtl" xml:space="preserve">
    <value>代理跟進組別人</value>
  </data>
  <data name="typeSTAFFFOLLOWDTL_Core" xml:space="preserve">
    <value>員工跟進代理記錄</value>
  </data>
  <data name="wIsManualAgentType" xml:space="preserve">
    <value>手動</value>
  </data>
</root>'


EXEC sp_xml_preparedocument @hDocRollsmary OUTPUT, @xmlRollsmary
EXEC sp_xml_preparedocument @hDocCRM OUTPUT, @xmlCRM
SELECT 
	crm.*
FROM 
	OPENXML(@hDocCRM, 'root/data') WITH 
	(
		name [nvarchar](500) '@name',
		value [nvarchar](MAX) 'value'
	) as crm
LEFT JOIN
	OPENXML(@hDocRollsmary, 'root/data') WITH 
	(
		name [nvarchar](500) '@name',
		value [nvarchar](MAX) 'value'
	) as rollsmary ON crm.name = rollsmary.name
WHERE
	rollsmary.name is null


END