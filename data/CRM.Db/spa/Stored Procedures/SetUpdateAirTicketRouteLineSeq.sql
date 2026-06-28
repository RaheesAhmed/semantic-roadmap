CREATE PROCEDURE [spa].[SetUpdateAirTicketRouteLineSeq]
(
    @pXML XML,
    @pActionType CHAR(1), -- I/U/D
    @pMainCompNo INT,
    @pNonceToken VARCHAR(64), 
    @pReturnResultSet CHAR(1) = 'N',
    @pBookingRid BIGINT,
    @pBookingType VARCHAR(30)='',
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT 
) 
AS
BEGIN
	SET NOCOUNT ON;		
	
	DECLARE @sBeginTranCount INT = 0,@sRuningIndex INT = 1,@sRecCount INT = 0,@sRowID BIGINT = 0, @sDocHandle INT;
	DECLARE @sUpdDt DATETIME2(7), @sUpdBy BIGINT

	SET @sBeginTranCount = @@trancount;

	EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;

	SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt desc),*
	INTO #DataSet_SetAirTicketRoutesLastUpdDt
	FROM OPENXML (@sDocHandle, 'DataSet/GetAirTicketRouteLstResult', 1)
	WITH (
			 RowID BIGINT
			,wType VARCHAR(30)
			,wTypeRid BIGINT
			,wPNRNo VARCHAR(50)
			,wLine INT
			,wFlightType VARCHAR(30)
			,wAirline VARCHAR(10)
			,wClassCd VARCHAR(10)
			,wIsReturn CHAR(1)
			,wDepartFlightNo VARCHAR(20)
			,wDepartureAirportRid BIGINT
			,wArrivalAirportRid BIGINT
			,wDepartureTerminal NVARCHAR(50)
			,wArrivalTerminal NVARCHAR(50)
			,wTakeOffDt DATETIME2(7)
			,wArrivalDt DATETIME2(7)
			,wStatus CHAR(1)
			,wCrtDt DATETIME2(7)
			,wCrtBy BIGINT
			,wUpdDt DATETIME2(7)
			,wUpdBy BIGINT)

   BEGIN TRY	

	-- Try to make the transaction scope as small as possible to reduce locking
	IF @sBeginTranCount = 0
	BEGIN
		BEGIN TRAN;
    END;

	IF @pActionType = 'U' or @pActionType ='I'
	BEGIN
		
		select Top 1 
			@sUpdDt=wUpdDt, 
			@sUpdBy=wUpdBy
		from #DataSet_SetAirTicketRoutesLastUpdDt 
		order by wUpdDt desc

		-- Update passenger's Take Off DateTime
		;With cteAirTicket as (
			select rd.RowID, rd.wLine, rd.wTakeOffDt 
			from dbo.eAirTicketRouteDtl rd
			inner join dbo.eBookingAirTicket a on a.RowID = rd.wTypeRid 
			where a.wBookingRid=@pBookingRid and rd.wStatus='A' and rd.wType='AIRTICKET'
		),
		ctePassenger as (
			select rd.RowID, rd.wLine 
			from dbo.eAirTicketRouteDtl rd
			inner join dbo.ePassengerDetails p on p.RowID = rd.wTypeRid 
			where p.wBookingRid=@pBookingRid and rd.wStatus='A' and rd.wType='PASSENGER'

		)update rd set 
				--rd.wTakeOffDt = a.wTakeOffDt,
				rd.wUpdBy = @sUpdBy,
				rd.wUpdDt = @sUpdDt
		 from dbo.eAirTicketRouteDtl rd
		 inner join ctePassenger p on p.RowID = rd.RowID
		 inner join cteAirTicket a on a.wLine = p.wLine
		 where rd.wTakeOffDt <> a.wTakeOffDt
		
        -- 不能重新排wLine順序，因為時差問題，可能會出現后條記錄的航線出發時間小時前一條記錄的時間
		-- update AirTicket's Line 
		--;With cteAirTicket as (
		--	select 
		--		rd.RowID, 
		--		rd.wLine, 
		--		wLine_New = ROW_NUMBER() OVER ( ORDER BY wIsReturn, wTakeOffDt )
		--	from dbo.eAirTicketRouteDtl rd
		--	inner join dbo.eBookingAirTicket a on a.RowID = rd.wTypeRid 
		--	where a.wBookingRid=@pBookingRid and rd.wStatus='A' and rd.wType='AIRTICKET'

		--)
        
        -- update rd set
		--		rd.wLine = a.wLine_New,
		--		rd.wUpdBy = @sUpdBy,
	 --			rd.wUpdDt = @sUpdDt
		-- from dbo.eAirTicketRouteDtl rd
		-- inner join cteAirTicket a on a.RowID = rd.RowID
		-- where rd.wLine <> a.wLine_New
		
		-- update Passenger's Line 
		--;With ctePassenger as (
		--	select 
		--		rd.RowID,
		--		rd.wLine,
		--		wLine_New = ROW_NUMBER() OVER (Partition By rd.wTypeRid ORDER BY rd.wIsReturn, rd.wTakeOffDt )
		--	from dbo.eAirTicketRouteDtl rd
		--	inner join dbo.ePassengerDetails p on p.RowID = rd.wTypeRid 
		--	where p.wBookingRid=@pBookingRid and rd.wStatus='A' and rd.wType='PASSENGER'

		--)
        
        -- update rd set
		--		rd.wLine = p.wLine_New,
		--		rd.wUpdBy = @sUpdBy,
	 --			rd.wUpdDt = @sUpdDt
		-- from dbo.eAirTicketRouteDtl rd
		-- inner join ctePassenger p on p.RowID = rd.RowID
		-- where rd.wLine <> p.wLine

	END

	IF @sBeginTranCount = 0 AND @@trancount > 0
	BEGIN
         COMMIT;
    END; 

	RETURN;
	END TRY
        BEGIN CATCH
            DECLARE @vErrorNum INT ,
                @vCatchErrorMessage NVARCHAR(4000) ,
                @xstate INT ,
                @vProcedureName VARCHAR(100) ,
                @vRtnCodeLog INT ,
                @vErrMessageLog NVARCHAR(4000);
	        
			SET  @vErrorNum = ERROR_NUMBER();
			SET  @vCatchErrorMessage = ERROR_MESSAGE();
			SET  @xstate = XACT_STATE();
			SET  @vProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                BEGIN
                    SET @pErrCode = 999;
                END;
            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @vErrorNum, ') ', @vCatchErrorMessage);
			
			IF @sBeginTranCount = 0 BEGIN
				IF @xstate != 0
					ROLLBACK;
	            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @vProcedureName, @pErrMsg, @vRtnCodeLog OUTPUT, @vErrMessageLog OUTPUT;
			END
			ELSE
				THROW;

        END CATCH;
	
		EXEC sp_xml_removedocument @sDocHandle;
	
		IF OBJECT_ID('tempdb..#DataSet_#DataSet_SetAirTicketRoutesLastUpdDt') IS NOT NULL DROP TABLE #DataSet_SetAirTicketRoutesLastUpdDt;
END