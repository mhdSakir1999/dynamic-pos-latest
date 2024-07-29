ALTER proc [dbo].[myPOS_DP_CASHOUT_ALERT]
	@location varchar(10),
	@cashier varchar(10),
	@station varchar(10),
	@shift int
AS
BEGIN
	DECLARE @Sales numeric(18,2)
	DECLARE @CashIn numeric(18,2)
	DECLARE @CashOut numeric(18,2)
	declare @CurrentSale numeric(18,2)
	declare @OpCash numeric(18,2)

	select @OpCash = isnull(UH_FLOAT,0)
	from U_TBLUSERHEAD
	where UH_ID=@cashier and UH_SHIFTNO=@shift and UH_STATION=@station and UH_SIGNLOC=@location

	select @Sales=SUM(INVPAY_PAIDAMOUNT)
	from T_TBLINVHEADER inner join T_TBLINVPAYMENTS on INVHED_LOCCODE=INVPAY_LOCCODE and INVHED_INVNO=INVPAY_INVNO and INVHED_MODE=INVPAY_MODE
	where INVHED_LOCCODE=@location and INVHED_INVOICED=1 and INVHED_CANCELED=0 and INVHED_MODE<>'REC' AND INVHED_MODE<>'WIT' AND INVHED_STATION=@station AND INVHED_CASHIER=@cashier AND
		INVHED_SHITNO= @shift AND INVPAY_PHCODE='CSH' and INVHED_SIGNONDATE=(select UH_SIGNONDATE
		from U_TBLUSERHEAD
		where UH_ID=@cashier)

	select @CashIn=SUM(INVPAY_PAIDAMOUNT)
	from T_TBLINVHEADER inner join T_TBLINVPAYMENTS on INVHED_LOCCODE=INVPAY_LOCCODE and INVHED_INVNO=INVPAY_INVNO and INVHED_MODE=INVPAY_MODE
	where INVHED_LOCCODE=@location and INVHED_INVOICED=1 and INVHED_CANCELED=0 and INVHED_MODE = 'REC' AND INVHED_STATION=@station AND INVHED_CASHIER=@cashier AND
		INVHED_SHITNO= @shift AND INVPAY_PHCODE='CSH' and INVHED_SIGNONDATE=(select UH_SIGNONDATE
		from U_TBLUSERHEAD
		where UH_ID=@cashier)

	select @CashOut=SUM(INVPAY_PAIDAMOUNT)
	from T_TBLINVHEADER inner join T_TBLINVPAYMENTS on INVHED_LOCCODE=INVPAY_LOCCODE and INVHED_INVNO=INVPAY_INVNO and INVHED_MODE=INVPAY_MODE
	where INVHED_LOCCODE=@location and INVHED_INVOICED=1 and INVHED_CANCELED=0 AND INVHED_MODE='WIT' AND INVHED_STATION=@station AND INVHED_CASHIER=@cashier AND
		INVHED_SHITNO= @shift AND INVPAY_PHCODE='CSH' and INVHED_SIGNONDATE=(select UH_SIGNONDATE
		from U_TBLUSERHEAD
		where UH_ID=@cashier)

	set @CurrentSale = isnull(@Sales,0) + isnull(@OpCash,0) + isNull(@CashIn,0)

	select isnull(@CurrentSale,0) as Sales, isnull(@CashOut,0) as CashOuts

END
GO

---------------------------------------------

ALTER PROCEDURE [dbo].[myPOS_DP_SAVE_SpotDenominations]
	@cashier varchar(50),
	@spotCheckUser varchar(50),
	@shiftNo varchar(4),
	@signOndate varchar(50),
	@signOnTime varchar(50),
	@terminalId varchar(50),
	@setUpLocation varchar(50),
	@details dbo.DenominatonDet READONLY,
	@list dbo.Denominaton READONLY
-- pay det table results
AS
BEGIN

	DECLARE @error varchar(max)

	BEGIN TRY
	BEGIN TRAN

	-- sign off user header


	
	DECLARE @invoiceCount int;
	DECLARE @cancelInvoiceCount int;
	DECLARE @reprintCount int;
	DECLARE @firstInvoice varchar(50);
	DECLARE @lastInvoice varchar(50);
	DECLARE @netTotal numeric(18,2);
	DECLARE @discountTotal numeric(18,2);
	DECLARE @discPerTotal numeric(18,2);
	DECLARE @discAmtTotal numeric(18,2);
	DECLARE @billDiscTotal numeric(18,2);

	DECLARE @holdBillTotal numeric(18,2);
	DECLARE @refundTotal numeric(18,2);
	DECLARE @cashIn numeric(18,2);
	DECLARE @cashOut numeric(18,2);
	DECLARE @cashSales numeric(18,2);
	DECLARE @physicalCashAmount numeric(18,2);
	DECLARE @openBalance numeric(18,2);
	DECLARE @id varchar(50);

	SET @id = @setUpLocation + @terminalId + @cashier + @spotCheckUser + FORMAT(SYSDATETIME(), 'yyyyMMddHHmmssffffff')
	--select @id

	-- get invoice count,cancel invoice count reprint count
	SELECT @invoiceCount=COUNT(INVHED_INVNO)
	FROM T_TBLINVHEADER
	WHERE  CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' --AND INVHED_SPOTCHECK=0
	SELECT @cancelInvoiceCount=COUNT(INVHED_INVNO)
	FROM T_TBLINVHEADER
	WHERE  CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_CANCELED=1 AND INVHED_MODE='INV' --AND INVHED_SPOTCHECK=0
	SELECT @reprintCount=SUM(INVHED_PRINTNO)
	FROM T_TBLINVHEADER
	WHERE  CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' --AND INVHED_SPOTCHECK=0
	
	--get first and last invoice no
	SELECT TOP 1
		@firstInvoice=INVHED_INVNO
	FROM T_TBLINVHEADER
	WHERE  CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV'
	ORDER BY INVHED_TIME  --AND INVHED_SPOTCHECK=0
	SELECT TOP 1
		@lastInvoice=INVHED_INVNO
	FROM T_TBLINVHEADER
	WHERE  CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV'
	ORDER BY INVHED_TIME DESC --AND INVHED_SPOTCHECK=0

	-- get net total
	SELECT @netTotal=ISNULL(SUM(INVHED_NETAMT),0)
	FROM T_TBLINVHEADER
	WHERE  CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED= 0 AND INVHED_MODE='INV' --AND INVHED_SPOTCHECK=0

	--get hold bill total
	SELECT @holdBillTotal=ISNULL(SUM(INVHED_NETAMT) ,0)
	FROM T_TBLINVHEADER
	WHERE  CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=0 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' --AND INVHED_SPOTCHECK=0

	-- refund total
	--SELECT @refundTotal=SUM(ISNULL(INVDET_UNITQTY,0)* ISNULL(INVDET_SELLING,0)) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND
	--CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND 
	--INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVDET_UNITQTY<0 AND INVHED_MODE='INV' AND INVHED_SPOTCHECK=0
	SELECT @refundTotal=SUM(ISNULL(INVDET_UNITQTY,0)* ISNULL(INVDET_SELLING,0))
	FROM T_TBLINVDETAILS, T_TBLINVHEADER
	WHERE INVHED_INVNO=INVDET_INVNO AND invdet_void = 0 and
		CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND
		INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVDET_UNITQTY<0 AND INVHED_MODE='INV' AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId

	-- discount calculation
	SELECT @discAmtTotal=SUM(INVDET_DISCAMT)
	FROM T_TBLINVDETAILS, T_TBLINVHEADER
	WHERE INVHED_INVNO=INVDET_INVNO AND
		CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND
		INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' AND INVHED_SPOTCHECK=0

	SELECT @discPerTotal=SUM(INVDET_DISCPER * INVDET_UNITQTY * INVDET_SELLING / 100)
	FROM T_TBLINVDETAILS, T_TBLINVHEADER
	WHERE INVHED_INVNO=INVDET_INVNO AND
		CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND
		INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' AND INVHED_SPOTCHECK=0

	SELECT @billDiscTotal=SUM(INVDET_BILLDISCPER * INVDET_UNITQTY * INVDET_SELLING / 100)
	FROM T_TBLINVDETAILS, T_TBLINVHEADER
	WHERE INVHED_INVNO=INVDET_INVNO AND
		CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND
		INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVDET_NODISC=0 AND INVHED_MODE='INV' AND INVHED_SPOTCHECK=0

	SET @discountTotal = ISNULL(@billDiscTotal,0)+ISNULL(@discPerTotal,0)+ISNULL(@discAmtTotal,0)

	-- get cash in 
	SELECT @cashIn=ISNULL(SUM(INVHED_NETAMT) ,0)
	FROM T_TBLINVHEADER
	WHERE  CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='REC' AND INVHED_SPOTCHECK=0
	
	-- get cash out
	SELECT @cashOut=ISNULL(SUM(INVHED_NETAMT) ,0)
	FROM T_TBLINVHEADER
	WHERE  CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='WIT' AND INVHED_SPOTCHECK=0


	-- get openning balance
	SELECT @openBalance=ISNULL(UH_FLOAT,0)
	FROM U_TBLUSERHEAD
	WHERE UH_ID = @cashier

	--get it physical cash amount from denominations
	DECLARE @temp1 numeric(18,2)
	DECLARE @temp2 numeric(18,2)
	SELECT @temp1=SUM(d_value*d_count)
	FROM @details
	WHERE main_code = 'CSH'
	SELECT @temp2=SUM(total_value)
	FROM @list
	WHERE detail_code = 'CSH'
	SET @physicalCashAmount = ISNULL(@temp1,0)+ISNULL(@temp2,0);
	--calculated cash
	DECLARE @cashCalculated numeric(18,2)

	--SELECT @cashSales=ISNULL(SUM(INVPAY_PAIDAMOUNT),0) FROM T_TBLINVPAYMENTS,T_TBLINVHEADER WHERE INVHED_INVNO=INVPAY_INVNO AND CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	--INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVPAY_PHCODE='CSH' AND INVHED_SPOTCHECK=0 
	SELECT @cashSales=ISNULL(SUM(INVPAY_PAIDAMOUNT),0)
	FROM T_TBLINVPAYMENTS, T_TBLINVHEADER
	WHERE INVHED_INVNO=INVPAY_INVNO AND CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND
		INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVPAY_PHCODE='CSH' AND INVHED_MODE = 'INV' and INVPAY_MODE = 'INV'
		AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId

	SET @cashCalculated =  + @cashSales + @cashIn - @cashOut

	-- insert into sign off header
	INSERT INTO [dbo].[U_TBLSPTCHKHEADER]
		([SOH_DATE]
		,[SOH_TIME]
		,[SOH_LOCATION]
		,[SOH_USER]
		,[SOH_STATION]
		,[SOH_SHIFT]
		,[SOH_SIGNONDATE]
		,[SOH_SIGNONTIME]
		,[SOH_INVCOUNT]
		,[SOH_CANINVCOUNT]
		,[SOH_STARTINVNO]
		,[SOH_ENDINVNO]
		,[SOH_BILLNETTOTAL]
		,[SOH_REFUNDTOTAL]
		,[SOH_DISCTOTAL]
		,[SOH_TOTHOLDBILLS]
		,[SOH_OPBALANCE]
		,[SOH_DTTRANSFER]
		,[DTRANS]
		,[DTPROCESS]
		,[DTSPROCESS]
		,[SOH_REPRINTCOUNT]
		,[SOH_RECEIPTS]
		,[SOH_WITHDRAWALS]
		,[SOH_ACTUALREFUNDS]
		,[SOH_BKOFFDATE]
		,[SOH_CASHSALE]
		,[SOH_CASHCALCULATED]
		,[SOH_CASHPHYSICAL]
		,[SOH_RECEIPTS_OTHER],SOH_ID)
	VALUES
		(
			@signOndate,--<SOH_DATE, datetime,>
			@signOnTime,--<SOH_TIME, datetime,>
			@setUpLocation,--<SOH_LOCATION, varchar(5),>
			@cashier,--<SOH_USER, varchar(10),>
			@terminalId,--<SOH_STATION, varchar(3),>
			@shiftNo,--<SOH_SHIFT, decimal(18,0),>
			@signOndate,--<SOH_SIGNONDATE, datetime,>
			@signOnTime,--<SOH_SIGNONTIME, datetime,>
			@invoiceCount,--<SOH_INVCOUNT, decimal(18,0),>
			@cancelInvoiceCount,--<SOH_CANINVCOUNT, decimal(18,0),>
			@firstInvoice,--<SOH_STARTINVNO, varchar(11),>
			@lastInvoice,--<SOH_ENDINVNO, varchar(11),>
			@netTotal,--<SOH_BILLNETTOTAL, decimal(18,4),>
			@refundTotal,--<SOH_REFUNDTOTAL, decimal(18,4),>
			@discountTotal,--<SOH_DISCTOTAL, decimal(18,4),>
			@holdBillTotal,--<SOH_TOTHOLDBILLS, decimal(18,0),>
			@openBalance,--<SOH_OPBALANCE, decimal(18,4),>
			0,--<SOH_DTTRANSFER, bit,>
			0,--<DTRANS, bit,>
			0,--<DTPROCESS, bit,>
			0,--<DTSPROCESS, bit,>
			@reprintCount,--<SOH_REPRINTCOUNT, decimal(18,0),>
			@cashIn,--<SOH_RECEIPTS, numeric(18,2),>
			@cashOut,--<SOH_WITHDRAWALS, numeric(18,2),>
			@refundTotal,--<SOH_ACTUALREFUNDS, numeric(18,2),>
			GETDATE(),--<SOH_BKOFFDATE, datetime,>
			@cashSales,--<SOH_CASHSALE, numeric(18,2),>
			@cashCalculated,--<SOH_CASHCALCULATED, numeric(18,2),>
			@physicalCashAmount,--<SOH_CASHPHYSICAL, numeric(18,2),>
			0,--<SOH_RECEIPTS_OTHER, numeric(18,2),>
			@id
		   );

	-- insert into sign off details

	INSERT INTO [dbo].[U_TBLSPTCHKDETAIL]
		([SOD_DATE]
		,[SOD_TIME]
		,[SOD_LOCATION]
		,[SOD_USER]
		,[SOD_STATION]
		,[SOD_SHIFT]
		,[SOD_PAYCODE]
		,[SOD_PAYDETCODE]
		,[SOD_SYSAMT]
		,[SOD_PHYAMT]
		,[SOD_VARAMT]
		,[DTRANS]
		,[DTPROCESS]
		,[DTSPROCESS]
		, SOD_ID
		)
	SELECT
		@signOndate,--<SOD_DATE, datetime,>
		@signOnTime,--<SOD_TIME, datetime,>
		@setUpLocation,--<SOD_LOCATION, varchar(5),>
		@cashier,--<SOD_USER, varchar(10),>
		@terminalId,--<SOD_STATION, varchar(3),>
		@shiftNo,--<SOD_SHIFT, decimal(18,0),>
		INVPAY_PHCODE,--<SOD_PAYCODE, varchar(5),>
		INVPAY_PDCODE,--<SOD_PAYDETCODE, varchar(50),>
		SUM(isnull(INVPAY_PAIDAMOUNT,0)),--<SOD_SYSAMT, decimal(18,4),>
		ISNull(total_value,0),--<SOD_PHYAMT, decimal(18,4),>
		ISNULL(total_value,0)-ISNULL(SUM(INVPAY_PAIDAMOUNT),0),--<SOD_VARAMT, decimal(18,4),>
		0,--<DTRANS, bit,>
		0,--<DTPROCESS, bit,>
		0,--<DTSPROCESS, bit,>
		@id
	--FROM T_TBLINVPAYMENTS
	--INNER JOIN T_TBLINVHEADER
	--ON INVHED_INVNO=INVPAY_INVNO
	--LEFT JOIN @list
	--ON INVPAY_PDCODE=detail_code
	--WHERE CONVERT(DATE,INVHED_DATETIME) = CONVERT(DATE,@signOndate) AND INVPAY_PDCODE !='CSH' AND
	--INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0
	--GROUP BY INVPAY_PDCODE,INVPAY_PHCODE,total_value
	from
		(select INVPAY_PHCODE, INVPAY_PDCODE, INVPAY_PAIDAMOUNT
		FROM T_TBLINVPAYMENTS
			INNER JOIN T_TBLINVHEADER
			ON INVHED_INVNO=INVPAY_INVNO
		WHERE CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVPAY_PDCODE !='CSH' AND
			INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId AND INVHED_MODE = 'INV' ) P
		full outer join
		@list ON P.INVPAY_PDCODE=detail_code
	GROUP BY INVPAY_PDCODE,detail_code,INVPAY_PHCODE,code,total_value

	-- insert cash record
		INSERT INTO [dbo].[U_TBLSPTCHKDETAIL]
		([SOD_DATE]
		,[SOD_TIME]
		,[SOD_LOCATION]
		,[SOD_USER]
		,[SOD_STATION]
		,[SOD_SHIFT]
		,[SOD_PAYCODE]
		,[SOD_PAYDETCODE]
		,[SOD_SYSAMT]
		,[SOD_PHYAMT]
		,[SOD_VARAMT]
		,[DTRANS]
		,[DTPROCESS]
		,[DTSPROCESS],SOD_ID)
	VALUES(
			@signOndate,--<SOD_DATE, datetime,>
			@signOnTime,--<SOD_TIME, datetime,>
			@setUpLocation,--<SOD_LOCATION, varchar(5),>
			@cashier,--<SOD_USER, varchar(10),>
			@terminalId,--<SOD_STATION, varchar(3),>
			@shiftNo,--<SOD_SHIFT, decimal(18,0),>
			'CSH',--<SOD_PAYCODE, varchar(5),>
			'CSH',--<SOD_PAYDETCODE, varchar(50),>
			@cashSales,--<SOD_SYSAMT, decimal(18,4),>
			@physicalCashAmount,--<SOD_PHYAMT, decimal(18,4),>
			ISNULL(@physicalCashAmount,0)-ISNULL(@cashSales,0),--<SOD_VARAMT, decimal(18,4),>
			0,--<DTRANS, bit,>
			0,--<DTPROCESS, bit,>
			0,--<DTSPROCESS, bit,
			@id
		   )
	-- update the spot check flag
	UPDATE T_TBLINVHEADER SET INVHED_SPOTCHECK=1
	WHERE CONVERT(DATE,INVHED_DATETIME) >= CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_SPOTCHECK=0

	SELECT *
	FROM U_TBLSPTCHKHEADER
	where SOH_LOCATION=@setUpLocation and SOH_DATE=@signOndate and SOH_USER=@cashier and SOH_STATION=@terminalId and SOH_SHIFT=@shiftNo and SOH_ID = @id

	SELECT U_TBLSPTCHKDETAIL.*, PH_DESC
	FROM U_TBLSPTCHKDETAIL, M_TBLPAYMODEHEAD
	where SOD_PAYCODE=PH_CODE and SOD_LOCATION=@setUpLocation and SOD_DATE=@signOndate
		and SOD_USER=@cashier and SOD_STATION=@terminalId and SOD_SHIFT=@shiftNo and SOD_ID = @id

	select @signOndate as DE_DATE, @signOnTime as DE_TIME, @setUpLocation as DE_LOCATION, @cashier as DE_USER, @terminalId as DE_STATION, @shiftNo as DE_SHIFT,
		denomination_code as DE_DENCODE, ISNull(SUM(d_value * d_count),0) as DE_DENPHYAMT, 0 AS DTRANS, 0 AS DTPROCESS, 0 AS DTSPROCESS
	from @details
	group by denomination_code


	COMMIT TRAN
	END TRY
    
	BEGIN CATCH
	ROLLBACK TRAN
		SET @error = ERROR_MESSAGE();
		return @error
	END CATCH


	SELECT @error as error;

END
GO

-----------------------------------------------------------

ALTER proc [dbo].[myPOS_DP_GET_INVOICE_DET_PRINT]
	@invno varchar(25),
	@loc varchar(10),
	@invmode varchar(5)

as
begin
	select *
	from T_TBLINVHEADER
	where invhed_invno=@invno and invhed_loccode=@loc and invhed_mode=@invmode and invhed_canceled = 0
	select *
	from T_TBLINVDETAILS
	where invdet_invno=@invno and invdet_loccode=@loc and invdet_mode=@invmode
	select *
	from T_TBLINVPAYMENTS, t_tblinvheader
	where invpay_invno=@invno and invpay_invno = invhed_invno and invhed_canceled = 0 and invpay_loccode=@loc and invpay_mode=@invmode
	select *
	from T_TBLINVFREEISSUES
	where INVPROMO_INVNO=@invno and INVPROMO_LOCCODE=@loc
	select *
	from T_TBLINVLINEREMARKS
	where INVREM_INVNO=@invno and INVREM_LOCCODE=@loc
	select *
	from M_TBLCUSTOMER
	where cm_code=(select INVHED_MEMBER
	from T_TBLINVHEADER
	where invhed_invno=@invno and invhed_loccode=@loc and invhed_mode=@invmode)
	select *
	from U_TBLPRINTMSG
	SELECT *
	FROM M_TBLPAYMODEHEAD
	SELECT *
	FROM M_TBLPAYMODEDET
	SELECT *
	FROM M_TBLLOCATIONS
	where LOC_CODE=@loc
	select *
	from T_TBLINVPROMOTICKETS
	where PROMO_LOCCODE=@loc AND PROMO_INVNO=@invno
	select H.PTICK_CODE AS TICKET_CODE, H.PTICK_DESC AS TICKET_NAME, D.PTICK_LINENO AS LINE_NO, D.PTICK_DESC AS LINE_CONTENT, D.PTICK_BOLD AS IS_BOLD,
		D.PTICK_UNDLINE AS IS_UNDERLINE
	from M_TBLPROMOTION_TICKETS_HED H, M_TBLPROMOTION_TICKETS_DET D
	WHERE H.PTICK_CODE=D.PTICK_CODE AND H.PTICK_CODE IN (select PROMO_TICKETID
		from T_TBLINVPROMOTICKETS
		where PROMO_LOCCODE=@loc AND PROMO_INVNO=@invno)
	ORDER BY H.PTICK_CODE, D.PTICK_LINENO
	select *
	from T_TBLINVREMARKS
	where INVREM_INVNO=@invno and INVREM_LOCCODE=@loc

end
GO

-------------------------------------------------------------
ALTER PROCEDURE [dbo].[myPOS_DP_CANCEL_INVOICE]
	@cashier varchar(20),
	@invoiceNo varchar(100),
	@locCode varchar(10),
	@invMode varchar(5)
AS
BEGIN

	BEGIN TRAN t1;
	DECLARE @error varchar(max);
	DECLARE @RowCount1 INTEGER

	UPDATE T_TBLINVHEADER SET 
	INVHED_CANCELED=1,
	INVHED_CANUSER=@cashier,
	INVHED_CANDATE=GETDATE(),
	INVHED_CANTIME=GETDATE(),
	MD_BY=@cashier,
	MD_DATE= GETDATE(),
	DTRANS=0, DTPROCESS=0,DTSPROCESS=0
	WHERE INVHED_CASHIER = @cashier AND INVHED_INVNO = @invoiceNo AND INVHED_MODE = @invMode
	SELECT @RowCount1 = @@ROWCOUNT
	PRINT 'INVHED UPDATE DONE'

	---Update Stock In Hand
	/*
	UPDATE pn SET pn.IPLU_SIH = pn.IPLU_SIH + ((dt.INVDET_CASEQTY*dt.INVDET_PROCASESIZE) + (dt.INVDET_FREEQTY*dt.INVDET_PROCASESIZE) + INVDET_UNITQTY + INVDET_FREEQTY) 
	FROM M_TBLPROINVENTORY pn INNER JOIN T_TBLINVDETAILS dt ON pn.IPLU_CODE = dt.INVDET_PROCODE 
	WHERE dt.INVDET_INVNO=@invoiceNo AND pn.IPLU_LOCCODE = dt.INVDET_LOCCODE
	*/
	UPDATE pn SET pn.IPLU_SIH = pn.IPLU_SIH + dt.QTY
	FROM M_TBLPROINVENTORY pn INNER JOIN
		(select INVDET_INVNO, INVDET_LOCCODE, INVDET_STOCKCODE, sum((INVDET_CASEQTY*INVDET_PROCASESIZE) + INVDET_UNITQTY) AS QTY
		from T_TBLINVDETAILS
		where INVDET_INVNO=@invoiceNo AND INVDET_LOCCODE=@locCode
		group by INVDET_INVNO,INVDET_LOCCODE,INVDET_STOCKCODE) dt
		ON pn.IPLU_PRODUCTCODE = dt.INVDET_STOCKCODE AND pn.IPLU_LOCCODE = dt.INVDET_LOCCODE

	PRINT 'STOCK UPDATE DONE'

	/*
	-- going through sold gvs
	UPDATE M_TBLVOUCHERS
	SET VC_CANCASHIER=@cashier,VC_CANDATE=GETDATE(), VC_CANINVNO=@invoiceNo,VC_CANLOC=INVDET_LOCCODE,VC_CANPOS=INVHED_STATION
	FROM M_TBLVOUCHERS
	JOIN T_TBLINVDETAILS
	ON INVDET_PROCODE = VC_NUMBER
	JOIN T_TBLINVHEADER
	ON INVHED_INVNO = INVDET_INVNO
	WHERE INVHED_INVNO=@invoiceNo AND INVDET_ISVOUCHER=1
	PRINT 'VOUCHER UPDATE DONE'

	--cancle loyalty
	UPDATE U_TBLLOYALTY_POINTS SET POINT_CANCELED=1 WHERE POINT_INVNO = @invoiceNo
	PRINT 'LOYALTY POINT UPDATE DONE'
*/
	select *
	from T_TBLINVHEADER
	where invhed_invno=@invoiceNo and invhed_loccode=@locCode and invhed_mode=@invMode
	select *
	from T_TBLINVDETAILS
	where invdet_invno=@invoiceNo and invdet_loccode=@locCode and invdet_mode=@invMode
	select *
	from T_TBLINVPAYMENTS
	where invpay_invno=@invoiceNo and invpay_loccode=@locCode and invpay_mode=@invMode
	select *
	from T_TBLINVFREEISSUES
	where INVPROMO_INVNO=@invoiceNo and INVPROMO_LOCCODE=@locCode
	select *
	from T_TBLINVLINEREMARKS
	where INVREM_INVNO=@invoiceNo and INVREM_LOCCODE=@locCode
	select *
	from M_TBLCUSTOMER
	where cm_code=(select invhed_member
	from T_TBLINVHEADER
	where invhed_invno=@invoiceNo and invhed_loccode=@locCode and invhed_mode=@invMode)
	select *
	from U_TBLPRINTMSG
	SELECT *
	FROM M_TBLPAYMODEHEAD
	SELECT *
	FROM M_TBLPAYMODEDET
	SELECT *
	FROM M_TBLLOCATIONS
	where loc_code = @locCode

	IF @RowCount1=1
		BEGIN
		SET @error = '';
		COMMIT TRAN t1;
	END
	ELSE
		BEGIN
		SET @error = 'You cannot cancel this invoice';
		ROLLBACK TRAN t1
	END
	SELECT @error as error
END
GO

-------------------------------------------------------------------------------

ALTER   PROCEDURE [dbo].[myPOS_DP_EOD_VALIDATION]
	@date datetime = null,
	@location nvarchar(10)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @error varchar(max);
	DECLARE @setupLoc varchar(max);
	DECLARE @signOnCount varchar(max);
	Declare @mngSignOnCount varchar(max);
	IF @date = null
	BEGIN
		SET @date = GETDATE();
	END
	--SELECT @setupLoc=SETUP_LOCATION FROM U_TBLSETUP
	set @setupLoc=@location
	-- validate sign on users 
	SELECT @signOnCount =COUNT(UH_ID)
	FROM U_TBLUSERHEAD
	WHERE UH_ISSIGNEDON = 1 AND UH_SIGNLOC =@setupLoc
	select @mngSignOnCount = COUNT(UH_ID)
	from U_TBLUSERHEAD
	WHERE UH_ISMNGSIGNOFF = 0 AND UH_SIGNLOC =@setupLoc

	IF @signOnCount>0
	BEGIN
		SET @error = 'sign_on'
	END
	else if @mngSignOnCount>0
	BEGIN
		SET @error = 'manager_sign_off'
	END
	ELSE
	BEGIN
		-- validate hold invoices
		DECLARE @invoiceCount varchar(max);
		SELECT @invoiceCount = COUNT(INVHED_INVNO)
		FROM T_TBLINVHEADER
		WHERE INVHED_INVOICED=0 AND INVHED_CANCELED=0 AND CONVERT(DATE,INVHED_DATETIME) = CONVERT(DATE,@date)

		IF @invoiceCount>0
		BEGIN
			SET @error = 'invoice'
		END
		ELSE
		BEGIN
			-- validate date
			DECLARE @endDate datetime;
			--SELECT @endDate = SETUP_ENDDATE FROM U_TBLSETUP
			SELECT @endDate=EOD_DATE
			FROM U_TBLLAST_EOD
			WHERE EOD_LOC=@setupLoc
			IF  CONVERT(DATE,@endDate) < CONVERT(DATE,@date)
			BEGIN
				SET @error = null
			END
			ELSE
			BEGIN
				SET @error = convert(varchar,@endDate)
			END

		END

	END

	SELECT @error as error

END
GO

-------------------------------------------------------------------------