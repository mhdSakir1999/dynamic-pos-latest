




ALTER PROCEDURE [dbo].[myPOS_DP_GET_PROMOTIONS]
	@loc varchar(5)
	,@comCode varchar(5)
AS
BEGIN
	set datefirst 1;
	
	DECLARE @day int

	SET @day = DATEPART(WEEKDAY, GETDATE())
	SELECT 
	   PRO_CODE
      ,PRO_DESC
      ,PRO_NARRATION
      ,PRO_PRINT
      ,PRO_GROUP
      ,PRO_STATUS
      ,PRO_STDATE
      ,PRO_ENDATE
      ,PRO_STTIME
      ,PRO_ENTIME
      ,PRO_DAYS
      ,PRO_ST_BILLNET
      ,PRO_EN_BILLNET
      ,PRO_COMPANYS
      ,PRO_BDAY
      ,PRO_BDFROM
      ,PRO_BDTO
      ,PRO_ANNIVERSARY
      ,PRO_MINPOINTBAL
      ,PRO_CUSLIMIT
      ,PRO_INCLUSIVEITEMS
      ,PRO_PRIORITY
      ,PRO_LOYALCUSTOMERS
	  ,PROL_LOCCODE,
	  PG_CODE
      ,PG_DESC
      ,PG_STATUS
      ,PG_OUTLET
      ,PG_EXCL_ACT
      ,PG_INCL_ACT
      ,PG_PSKUBID_ACT
      ,PG_GRPBID_ACT
      ,PG_DISCPER_ACT
      ,PG_DISCAMT_ACT
      ,PG_FSKUBID_ACT
      ,PG_TICKET_ACT
      ,PG_VOU_ACT
      ,PG_POINT_ACT
      ,PG_CUS_SPECIFIC
	  ,PG_INCL_ACT_QTY 
	  ,PG_INCL_ACT_VALUE 
	  ,PG_INCL_ACT_ITEM 
	  ,PG_INCL_ACT_COMBINATION
	  ,PG_EXCL_ACT_QTY
	  ,PG_EXCL_ACT_VALUE
	  ,PG_EXCL_ACT_ITEM
	  ,PG_EXCL_ACT_COMBINATION
	  ,inc.PROE_CUSGROUPS PROI_CUSGROUPS
      ,inc.PROE_SUPGROUPS PROI_SUPGROUPS
      ,'' PROI_ITEMBUNDLEGROUPS
      ,'' PROI_GROUPBUNDLEGROUPS
	  ,'' PROE_CUSGROUPS
      ,'' PROE_SUPGROUPS
      ,'' PROE_ITEMBUNDLEGROUPS
      ,'' PROE_GROUPBUNDLEGROUPS	  
	  --,inc.PROE_CUSGROUPS PROI_CUSGROUPS
   --   ,inc.PROE_SUPGROUPS PROI_SUPGROUPS
   --   ,inc.PROE_ITEMBUNDLEGROUPS PROI_ITEMBUNDLEGROUPS
   --   ,inc.PROE_GROUPBUNDLEGROUPS PROI_GROUPBUNDLEGROUPS
	  --,exc.PROE_CUSGROUPS PROE_CUSGROUPS
   --   ,exc.PROE_SUPGROUPS PROE_SUPGROUPS
   --   ,exc.PROE_ITEMBUNDLEGROUPS PROE_ITEMBUNDLEGROUPS
   --   ,exc.PROE_GROUPBUNDLEGROUPS PROE_GROUPBUNDLEGROUPS
	,ISNULL( gp.PG_CARD,0) PG_CARD
	 ,ISNULL( gp.PG_PAY_ACT,0) PG_PAY_ACT,
	 isnull(promo.PRO_SELECTABLE,0) as PRO_SELECTABLE
	 ,PG_EXCLUDE_INCLUSIVE
	 ,PG_VALIDQTY_CHECK_SKU
	 ,PG_DISCAMT_APPLY_TO_BILL
	 ,PG_TICKET_VALUE
	 ,PG_COUPON_REDEMPTION
	 ,PRO_COUPON_TYPE
	 ,PG_PRICE_MODE
	 ,PRO_PRICEMODE
	  FROM M_TBLPROMOTION promo
	  INNER JOIN M_TBLPROMOTION_LOC loc
	  ON promo.PRO_CODE = loc.PROL_CODE
	  INNER JOIN M_TBLPROMOTION_GROUPS gp
	  ON gp.PG_CODE = promo.PRO_GROUP
	  LEFT JOIN (SELECT DISTINCT PROE_CODE,PROE_CUSGROUPS,PROE_SUPGROUPS FROM M_TBLPROMOTION_INCLUDES ) inc
	  ON promo.PRO_CODE = inc.PROE_CODE
	  LEFT JOIN M_TBLPROMOTION_EXCLUSIONS exc
	  ON promo.PRO_CODE = exc.PROE_CODE
	  WHERE promo.PRO_STATUS=1 AND
	  convert(datetime, PRO_STDATE, 120) <= convert(datetime, cast(getdate() as date), 120) AND
   	  convert(datetime, PRO_ENDATE, 120) >= convert(datetime, cast(getdate() as date), 120) AND
	  promo.PRO_DAYS like '%'+ CONVERT(varchar,@day) +'%' AND 
	  loc.PROL_LOCCODE = @loc
	  AND PRO_COMPANYS IN (@comCode)
	  AND PG_STATUS=1
	  ORDER BY promo.PRO_PRIORITY,promo.PRO_LOYALCUSTOMERS desc

end
GO



--------------------------------------



ALTER TABLE dbo.T_TBLINVFREEISSUES ADD
	INVPROMO_DESC varchar(500) NULL
GO

---------------------------------------





ALTER PROCEDURE [dbo].[myPOS_DP_SAVE_INVOICE]
@INVOICE_NO  varchar(max),
	@SETUP_LOCATION varchar(10),
	@LOC_CODE varchar(10),
	@comCode varchar(10),
	@date datetime,
	@time datetime,
	@invMode varchar(3),
	@cashier varchar(50),
	@tempCashier varchar(50),
	@startTime datetime,
	@startDate datetime,
	@startDateTime datetime,
	@datetime datetime,
	@memberCode varchar(50),
	@signOnDate datetime,
	@terminalId varchar(10),
	@shiftNo int,
	@priceMode varchar(5),
	@grossAmt numeric(18,2),
	@discPer  numeric(18,2),
	@promoDiscPer  numeric(18,2)=0,
	@discAmt  numeric(18,2),
	@earnedPoints numeric(18,2)=0,
	@burnedPoints numeric(18,2)=0,
	@lineDiscPerTot  numeric(18,2),
	@lineDiscAmtTot numeric(18,2),
	@netAmount numeric(18,2),
	@payAmount numeric(18,2),
	@dueAmount numeric(18,2),
	@changeAmount numeric(18,2),
	@invoiced tinyint = 1,
	@details varchar(max),
	@payments varchar(max),
	@refMode varchar(50) = '',
	@promoCode varchar(50) = '',
	@refNo varchar(50) = '',
	@taxInc numeric(18,2) = 0,
	@taxExc numeric(18,2) = 0,
	@paymentRefs varchar(max),
	@proTax varchar(max),
	@lineRemarks varchar(max),
	@promoFreeIssues varchar(max),
	@promoTickets varchar(max),
	@error nvarchar(max) output
AS

DECLARE @CreditAmount numeric(18,2)

BEGIN
	BEGIN TRY
	BEGIN TRAN

	SET NOCOUNT ON;

	--Preparing INV DETAIL dataset
	SELECT [SETUP_LOCATION] ,[LOC_CODE] ,[COM_CODE] ,[LINE_NO] ,[SALEMAN] ,[ITEM_VOID] ,[PRO_CODE] ,[STOCK_CODE] ,[POS_DESC] ,[PRO_UNIT] ,[PRO_CASE_SIZE] ,[PRO_COST] ,[PRO_SELLING] ,[PRO_AVG_COST] ,[SELLING] ,
	[DISC_PRE] ,[DISC_AMT] ,[BILL_DISC_PRE] ,[BILL_DISC_AMT] ,[CASE_QTY] ,[UNIT_QTY] ,[CASE_FREE_QTY] ,[AMOUNT] ,[FREE_QTY] ,[NO_DISC] ,[SCAN_BARCODE] ,[INVDET_DISTYPE] ,[IS_VOUCHER] ,[LINE_REMARK] ,
	[PROMO_DISC_PRE] ,[PROMO_DISC_AMT] ,[PROMO_BILL_DISC_PRE] ,[PROMO_CODE] ,[TEMP_KEY] ,[PROMO_ORIGINAL_ITEM] ,[INVDET_PRICEMODE] 
	INTO #details FROM OPENJSON(@details)
			WITH (  [SETUP_LOCATION] [varchar](10) ,[LOC_CODE] [varchar](10) ,[COM_CODE] [varchar](10) ,[LINE_NO] [numeric](18,0) ,[SALEMAN] [varchar](max) ,[ITEM_VOID] [bit] ,[PRO_CODE] [varchar](50) ,[STOCK_CODE] [varchar](50) ,
			[POS_DESC] [varchar](max) ,[PRO_UNIT] [varchar](5) ,[PRO_CASE_SIZE] [numeric](18, 0) ,[PRO_COST] [numeric](18, 2) ,[PRO_SELLING] [numeric](18, 2) ,[PRO_AVG_COST] [numeric](18, 2) ,[SELLING] [numeric](18, 2) ,
			[DISC_PRE] [numeric](18, 2) ,[DISC_AMT] [numeric](18, 2) ,[BILL_DISC_PRE] [numeric](18, 2) ,[BILL_DISC_AMT] [numeric](18, 2) ,[CASE_QTY] [numeric](18, 3) ,[UNIT_QTY] [numeric](18, 3) ,[CASE_FREE_QTY] [numeric](18, 3) ,
			[AMOUNT] [numeric](18, 2) ,[FREE_QTY] [numeric](18, 3) ,[NO_DISC] [bit] ,[SCAN_BARCODE] [varchar](max) ,[INVDET_DISTYPE] [varchar](max) ,[IS_VOUCHER] [bit] ,[LINE_REMARK] [varchar](150) ,
			[PROMO_DISC_PRE] [numeric](18, 2) ,[PROMO_DISC_AMT] [numeric](18, 2) ,[PROMO_BILL_DISC_PRE] [numeric](18, 2) ,[PROMO_CODE] [varchar](150) ,[TEMP_KEY] [varchar](150) ,[PROMO_ORIGINAL_ITEM] [varchar](150) ,[INVDET_PRICEMODE] [varchar](15) 
			) 
	
	--Preparing INV PAYMENTS dataset
	SELECT	[paid_amount] ,[date_time] ,[amount] ,	[canceled] ,[pd_code] ,[ph_code] , [ref_no] ,[date] ,[rate] 
	INTO #payments FROM OPENJSON(@payments)
	WITH ([paid_amount] [numeric](18, 2) ,[date_time] [varchar](max) ,[amount] [numeric](18, 2) ,	[canceled] [bit] ,[pd_code] [varchar](8) ,[ph_code] [varchar](8), [ref_no] [varchar](max) ,
	[date] [varchar](55) ,[rate] [numeric](18, 3) 
	)

	--Preparing CARD DETAILS dataset
	SELECT [strTxnInvoiceNum] ,[strTxnReference] ,[strTxnCardtype] ,[strTxnCardBin] ,[strTxnCardLastDigits] ,[strTxnCardHolderName] ,[strTxnTerminal] ,[strTxnMerchent] ,[strIssuedBank] ,
	[strAcknowledgement] ,	[success] 
	INTO #paymentRefs FROM OPENJSON(@paymentRefs)
	WITH ([strTxnInvoiceNum] [varchar](150) ,[strTxnReference] [varchar](150) ,[strTxnCardtype] [varchar](25) ,[strTxnCardBin] [varchar](20) ,[strTxnCardLastDigits] [varchar](6) ,
	[strTxnCardHolderName] [varchar](50) ,[strTxnTerminal] [varchar](50) ,[strTxnMerchent] [varchar](50) ,[strIssuedBank] [varchar](50) ,[strAcknowledgement] [varchar](50) ,
	[success] [bit] 
	)

	--Preparing INV PRO TAX dataset
	SELECT [taxCode] ,[productCode] ,[grossAmount] ,[taxAmount] ,[taxPercentage] ,[afterTax] ,
	[taxInc] ,[plineNo] ,[taxSeq] 
	INTO #proTax FROM OPENJSON(@proTax)
	WITH ([taxCode] [varchar](10) ,[productCode] [varchar](30) ,[grossAmount] [numeric](18, 2) ,[taxAmount] [numeric](18, 2) ,[taxPercentage] [numeric](18, 2) ,[afterTax] [numeric](18, 2) ,
	[taxInc] [bit] ,[plineNo] [int] ,[taxSeq] [int] 
	)

	--Preparing INV LINE REMARKS dataset
	SELECT [LINE_NO],[LINE_REMARK]
	INTO #lineRemarks FROM OPENJSON(@lineRemarks) WITH ([LINE_NO] [numeric](18,0) ,	[LINE_REMARK] [varchar](250))

	--Preparing INV FREE ISSUE (PROMOTIONS) dataset
	SELECT [Location_code] ,[Promotion_code] ,[product_code] ,[cancelled] ,[discount_per] ,[discount_amt] ,
	[line_no] ,[barcode] ,[free_qty] ,[selling_price] ,[invoice_qty] ,[invoice_mode] ,
	[invoice_date] ,[coupon_code] ,[promo_product] ,[beneficial_value] ,[promotion_name]
	INTO #promoFreeIssues FROM OPENJSON(@promoFreeIssues)
	WITH ([Location_code] [varchar](10) ,[Promotion_code] [varchar](10) ,[product_code] [varchar](30) ,[cancelled] [bit] ,[discount_per] [numeric](18, 2) ,[discount_amt] [numeric](18, 2) ,
	[line_no] [numeric](18, 2) ,[barcode] [varchar](30) ,[free_qty] [numeric](18, 2) ,[selling_price] [numeric](18, 2) ,[invoice_qty] [numeric](18, 2) ,[invoice_mode] [varchar](10) ,
	[invoice_date] [varchar](40) ,[coupon_code] [varchar](30) ,[promo_product] [varchar](30) ,[beneficial_value] [numeric](18, 2) , [promotion_name] varchar(500)
	)

	--Preparing INV PROMO TICKETS (PROMOTIONS) dataset
	SELECT [ticketId] ,[ticketQty] ,[promotionCode] ,[promotionDesc] ,[ticketValue], [ticketRedeemFromDate], [ticketRedeemToDate], 
		[ticketRedeemFromVal], [ticketRedeemToVal], [ticketSerial], [company]
		INTO #promoTickets FROM OPENJSON(@promoTickets) 
		WITH ([ticketId] [varchar](10) ,[ticketQty] [numeric](18, 2) ,[promotionCode] [varchar](30) ,[promotionDesc] [varchar](200) ,
		[ticketValue] [numeric](18, 2), [ticketRedeemFromDate] [varchar](100), [ticketRedeemToDate] [varchar](100), 
		[ticketRedeemFromVal] [numeric](18, 2), [ticketRedeemToVal] [numeric](18, 2), [ticketSerial] [varchar](100), [company] [varchar](10))

	SELECT @CreditAmount = SUM(ISNULL(paid_amount,0)) FROM #payments WHERE ph_code = 'CRE'

-- save inv header
	INSERT INTO [dbo].[T_TBLINVHEADER]
           ([INVHED_SETUPLOC]
           ,[INVHED_LOCCODE]
           ,[INVHED_INVNO]
           ,[INVHED_MODE]
           ,[INVHED_TXNDATE]
           ,[INVHED_TIME]
		   ,[INVHED_STARTTIME]
           ,[INVHED_ENDDATE]
           ,[INVHED_ENDTIME]
           ,[INVHED_SIGNONDATE]
           ,[INVHED_STATION]
           ,[INVHED_CASHIER]
           ,[INVHED_SHITNO]
           ,[INVHED_TEMCASHIER]
           ,[INVHED_MEMBER]
           ,[INVHED_PRICEMODE]
           ,[INVHED_REFMODE]
           ,[INVHED_REFNO]
           ,[INVHED_GROAMT]
           ,[INVHED_DISPER]
           ,[INVHED_DISAMT]
           ,[INVHED_LINEDISCPERTOT]
           ,[INVHED_LINEDISAMTTOT]
           ,[INVHED_ADDAMT]
           ,[INVHED_NETAMT]
           ,[INVHED_PAYAMT]
           ,[INVHED_DUEAMT]
           ,[INVHED_CHANGE]
           ,[INVHED_POINTADDED]
           ,[INVHED_POINTDEDUCT]
           ,[INVHED_PRINTNO]
           ,[INVHED_CANCELED]
           ,[INVHED_CANUSER]
           ,[INVHED_CANDATE]
           ,[INVHED_CANTIME]
           ,[CR_DATE]
           ,[CR_BY]
           ,[MD_DATE]
           ,[MD_BY]
           ,[DTS_DATE]
           ,[INVHED_INVOICED]
           ,[INVHED_ORDNUMBER]
           ,[INVHED_ORDDATE]
           ,[INVHED_ORDTIME]
           ,[INVHED_ORDENDDATE]
           ,[INVHED_ORDENDTIME]
           ,[INVHED_ORDSTATION]
           ,[INVHED_ORDCASHIER]
           ,[DTRANS]
           ,[DTPROCESS]
           ,[DTSPROCESS]
           ,[INVHED_CREAMT]
           ,[INVHED_TAXPER]
           ,[INVHED_INCTAXAMT]
           ,[INVHED_SERAMT]
           ,[GLBATCHNO]
           ,[GLBATCHNO2]
           ,[INVHED_PRINT]
           ,[INVHED_DATETIME]
           ,[INVHED_COMCODE]
           ,[INVHED_SLR_CONVERT]
           ,[INVHED_TAXBILLNO]
           ,[INVHED_SIGNOFF]
           ,[INVHED_SESSION]
           ,[INVHED_SALEMODE]
           ,[INVHED_TABLE]
           ,[INVHED_VAT]
           ,[INVHED_NBT]
           ,[INVHED_TRANSFER])
     VALUES
           (@SETUP_LOCATION
           ,@LOC_CODE
           ,@INVOICE_NO
           ,@invMode
           ,@date
           ,@time--<INVHED_TIME, datetime,>
		   ,@startTime
           ,@date--<INVHED_ENDDATE, datetime,>
           ,@time--<INVHED_ENDTIME, datetime,>
           ,@signOnDate--<INVHED_SIGNONDATE, datetime,>
           ,@terminalId--<INVHED_STATION, varchar(3),>
           ,@cashier--<INVHED_CASHIER, varchar(10),>
           ,@shiftNo--<INVHED_SHITNO, decimal(18,0),>
           ,@tempCashier--<INVHED_TEMCASHIER, varchar(10),>
           ,@memberCode--<INVHED_MEMBER, varchar(20),>
           ,@priceMode--<INVHED_PRICEMODE, varchar(5),>
           ,@refMode--<INVHED_REFMODE, varchar(3),>
           ,@refNo--<INVHED_REFNO, varchar(10),>
           ,@grossAmt--<INVHED_GROAMT, decimal(18,2),>
           ,@discPer--<INVHED_DISPER, decimal(18,2),>
           ,@discAmt--<INVHED_DISAMT, decimal(18,2),>
           ,@lineDiscPerTot--<INVHED_LINEDISCPERTOT, decimal(18,2),>
           ,@lineDiscAmtTot--<INVHED_LINEDISAMTTOT, decimal(18,2),>
           ,0--<INVHED_ADDAMT, decimal(18,2),>
           ,@netAmount--<INVHED_NETAMT, decimal(18,2),>
           ,@payAmount--<INVHED_PAYAMT, decimal(18,2),>
           ,@dueAmount--<INVHED_DUEAMT, decimal(18,2),>
           ,@changeAmount--<INVHED_CHANGE, decimal(18,2),>
           ,@earnedPoints --<INVHED_POINTADDED, decimal(18,2),>
           ,@burnedPoints--<INVHED_POINTDEDUCT, decimal(18,2),>
           ,0--<INVHED_PRINTNO, decimal(18,0),>
           ,0--<INVHED_CANCELED, bit,>
           ,''--<INVHED_CANUSER, varchar(10),>
           ,@date--<INVHED_CANDATE, datetime,>
           ,@time--<INVHED_CANTIME, datetime,>
           ,@date--<CR_DATE, datetime,>
           ,@cashier--<CR_BY, varchar(10),>
           ,Null--<MD_DATE, datetime,>
           ,null--<MD_BY, varchar(10),>
           ,@date--<DTS_DATE, datetime,>
           ,@invoiced--<INVHED_INVOICED, bit,>
           ,@refNo--<INVHED_ORDNUMBER, varchar(10),>
           ,null--<INVHED_ORDDATE, datetime,>
           ,null--<INVHED_ORDTIME, datetime,>
           ,null--<INVHED_ORDENDDATE, datetime,>
           ,null--<INVHED_ORDENDTIME, datetime,>
           ,null--<INVHED_ORDSTATION, varchar(3),>
           ,null--<INVHED_ORDCASHIER, varchar(10),>
           ,0--<DTRANS, bit,>
           ,0--<DTPROCESS, bit,>
           ,0--<DTSPROCESS, bit,>
           ,@CreditAmount--<INVHED_CREAMT, decimal(18,2),>
           ,0--<INVHED_TAXPER, decimal(18,2),>
           ,@taxInc--<INVHED_INCTAXAMT, decimal(18,3),>
           ,0--<INVHED_SERAMT, decimal(18,3),>
           ,''--<GLBATCHNO, varchar(10),>
           ,''--<GLBATCHNO2, varchar(10),>
           ,0--<INVHED_PRINT, bit,>
           ,GETDATE()--<INVHED_DATETIME, datetime,>
           ,@comCode--<HED_COMCODE, varchar(3),>
           ,1--<INVHED_SLR_CONVERT, numeric(18,2)(18,5),>
           ,0--<INVHED_TAXBILLNO, numeric(18,2)(18,0),>
           ,0--<INVHED_SIGNOFF, bit,>
           ,0--<INVHED_SESSION, numeric(18,2)(18,0),>
           ,''--<INVHED_SALEMODE, varchar(3),>
           ,''--<INVHED_TABLE, varchar(8),>
           ,0--<INVHED_VAT, numeric(18,2)(18,2),>
           ,0--<INVHED_NBT, numeric(18,2)(18,2),>
           ,0--<INVHED_TRANSFER, int,>
		   )

		   print('header saved');

	-- save details level
	INSERT INTO [dbo].[T_TBLINVDETAILS]
           ([INVDET_SETUPLOC]
           ,[INVDET_LOCCODE]
           ,[INVDET_INVNO]
           ,[INVDET_MODE]
           ,[INVDET_LINENO]
           ,[INVDET_TXNDATE]
           ,[INVDET_TIME]
           ,[INVDET_SALESMAN]
           ,[INVDET_CANCELED]
           ,[INVDET_VOID]
           ,[INVDET_PROCODE]
           ,[INVDET_ISVOUCHER]
           ,[INVDET_OPITEM]
           ,[INVDET_STOCKCODE]
           ,[INVDET_PRODESC]
           ,[INVDET_PROUNIT]
           ,[INVDET_PROCASESIZE]
           ,[INVDET_PROCOST]
           ,[INVDET_PROSELLING]
           ,[INVDET_PROAVGCOST]
           ,[INVDET_SELLING]
           ,[INVDET_DISCPER]
           ,[INVDET_DISCAMT]
           ,[INVDET_BILLDISCPER]
           ,[INVDET_BILLDISCAMT]
           ,[INVDET_CASEQTY]
           ,[INVDET_UNITQTY]
           ,[INVDET_CASERETQTY]
           ,[INVDET_UNITRETQTY]
           ,[INVDET_AMOUNT]
           ,[DTRANS]
           ,[DTPROCESS]
           ,[DTSPROCESS]
           ,[INVDET_MEMBER]
           ,[INVDET_INVOICEDKOT]
           ,[INVDET_FREEQTY]
           ,[INVDET_NODISC]
           ,[INVDET_KOTBOTTYPE]
           ,[INVDET_KOTBOTNO]
           ,[INVDET_PRINT]
           ,[INVDET_SLR_CONVERT]
           ,[DET_SERVICEPER]
           ,[INVDET_SALE1]
           ,[INVDET_SALE1COMM]
           ,[INVDET_SALE2]
           ,[INVDET_SALE2COMM]
           ,[INVDET_SALE3]
           ,[INVDET_SALE3COMM]
           ,[DET_COMCODE]
           ,[INVDET_CALEXP]
           ,[INVDET_SCANBARCODE]
           ,[INVDET_DATETIME]
           --,[INVDET_EXPDATE]
           ,[INV_DISPLAYED]
           ,[INVDET_PLU_PACKPRICE],INVDET_DISTYPE
		   ,INVDET_PROMODISCAMT
		   ,INVDET_PROMODISCPER
		   ,INVDET_PROMOBILLDISCPER
		   ,INVDET_PRICEMODE
		   )
	 SELECT 
			@SETUP_LOCATION
           ,@LOC_CODE
           ,@INVOICE_NO
           ,@invMode
           ,LINE_NO
		   ,@date
           ,@time
           ,SALEMAN
           ,0--canceled
           ,ITEM_VOID --void
           ,PRO_CODE -- pro code
           ,IS_VOUCHER--<INVDET_ISVOUCHER, bit,>
           ,0--<INVDET_OPITEM, bit,>
           ,CASE WHEN STOCK_CODE = '' THEN PRO_CODE ELSE STOCK_CODE END--<INVDET_STOCKCODE, varchar(25),>
           ,POS_DESC--<INVDET_PRODESC, varchar(40),>
           ----,(SELECT UM_DESC FROM M_TBLUNITS WHERE UM_CODE=PRO_UNIT) --<INVDET_PROUNIT, varchar(5),>
		   ,PRO_UNIT
           ,PRO_CASE_SIZE --<INVDET_PROCASESIZE, numeric(18,2)(18,0),>
           ,PRO_COST--<INVDET_PROCOST, numeric(18,2)(18,2),>
           ,PRO_SELLING--<INVDET_PROSELLING, numeric(18,2)(18,2),>
           ,PRO_AVG_COST--<INVDET_PROAVGCOST, numeric(18,2)(18,2),>
           ,SELLING--<INVDET_SELLING, numeric(18,2)(18,2),>
           ,DISC_PRE--<INVDET_DISCPER, numeric(18,2)(18,2),>
           ,DISC_AMT--<INVDET_DISCAMT, numeric(18,2)(18,2),>
           ,BILL_DISC_PRE--<INVDET_BILLDISCPER, numeric(18,2)(18,2),>
           ,BILL_DISC_AMT--<INVDET_BILLDISCAMT, numeric(18,2)(18,2),>
           ,CASE_QTY--<INVDET_CASEQTY, numeric(18,2)(18,3),>
           ,UNIT_QTY--<INVDET_UNITQTY, numeric(18,2)(18,3),>
           ,CASE_FREE_QTY--<INVDET_CASERETQTY, numeric(18,2)(18,3),>
           ,0--<INVDET_UNITRETQTY, numeric(18,2)(18,3),>
           ,AMOUNT--<INVDET_AMOUNT, numeric(18,2)(18,2),>
           ,0--<DTRANS, bit,>
           ,0--<DTPROCESS, bit,>
           ,0--<DTSPROCESS, bit,>
           ,''--<INVDET_MEMBER, varchar(8),>
           ,0--<INVDET_INVOICEDKOT, bit,>
           ,FREE_QTY--<INVDET_FREEQTY, numeric(18,2)(18,3),>
           ,NO_DISC--<INVDET_NODISC, bit,>
           ,''--<INVDET_KOTBOTTYPE, varchar(1),>
           ,''--<INVDET_KOTBOTNO, varchar(20),>
           ,0--<INVDET_PRINT, int,>
           ,1--<INVDET_SLR_CONVERT, numeric(18,2)(18,5),>
           ,0--<DET_SERVICEPER, numeric(18,2)(18,2),>
           ,''--<INVDET_SALE1, varchar(8),>
           ,0--<INVDET_SALE1COMM, numeric(18,2)(18,2),>
           ,''--<INVDET_SALE2, varchar(8),>
           ,0--<INVDET_SALE2COMM, numeric(18,2)(18,2),>
           ,''--<INVDET_SALE3, varchar(8),>
           ,0--<INVDET_SALE3COMM, numeric(18,2)(18,2),>
           ,@comCode--<DET_COMCODE, varchar(3),>
           ,0--<INVDET_CALEXP, int,>
           ,SCAN_BARCODE--<INVDET_SCANBARCODE, varchar(13),>
           ,GETDATE()--<INVDET_DATETIME, datetime,>
           --,--<INVDET_EXPDATE, datetime,>
           ,''--<INV_DISPLAYED, varchar(1),>
           ,0--<INVDET_PLU_PACKPRICE, numeric(18,2)(18,2),>
		   ,INVDET_DISTYPE
		   ,PROMO_DISC_AMT
		   ,PROMO_DISC_PRE
		   ,PROMO_BILL_DISC_PRE
		   ,INVDET_PRICEMODE
		   FROM #details
		   print('details saved');

		   --save tax
	INSERT INTO [dbo].[T_TBLTXNTAX]
           ([TXN_TYPE]
           ,[TXN_RUNNO]
           ,[TXN_PROCODE]
           ,[TXN_TAX]
           ,[TXN_SEQ]
           ,[TAX_GRAMT]
           ,[TXN_RATE]
           ,[TXN_AMOUNT]
           ,[TXN_SETUPLOC]
           ,[TXN_LOCCODE]
           ,[TXN_INVNO]
           ,[TXN_MODE]
           ,[TXN_COMCODE]
           ,[TXN_MULTIPLY]
           ,[TAX_PRICE]
           ,[TXN_LINENO])
     SELECT 
           @invMode--<TXN_TYPE, varchar(3),>
           ,@INVOICE_NO--<TXN_RUNNO, varchar(10),>
           ,productCode--<TXN_PROCODE, varchar(50),>
           ,taxCode--<TXN_TAX, varchar(5),>
           ,taxSeq--<TXN_SEQ, numeric(18,0),>
           ,grossAmount--<TAX_GRAMT, numeric(18,2),>
           ,taxPercentage--<TXN_RATE, numeric(18,2),>
           ,taxAmount--<TXN_AMOUNT, numeric(18,2),>
           ,@SETUP_LOCATION--<TXN_SETUPLOC, varchar(5),>
           ,@LOC_CODE--<TXN_LOCCODE, varchar(5),>
           ,@INVOICE_NO--<TXN_INVNO, varchar(50),>
           ,@invMode--<TXN_MODE, varchar(3),>
           ,@comCode--<TXN_COMCODE, varchar(3),>
           ,1--<TXN_MULTIPLY, int,>
           ,afterTax--<TAX_PRICE, numeric(18,2),>
           ,plineNo--<TXN_LINENO, numeric(18,0),>
	FROM #proTax
	print('tax saved');


	/*
	if @promoCode is not null AND @promoCode <> ''
	BEGIN
		INSERT INTO [dbo].[T_TBLINVFREEISSUES]
			   ([INVPROMO_LOCCODE]
			   ,[INVPROMO_INVNO]
			   ,[INVPROMO_PROCODE]
			   ,[INVPROMO_PLU]
			   ,[INVPROMO_CANCELED]
			   ,[INVPROMO_LOC]
			   ,[DTRANS]
			   ,[DTPROCESS]
			   ,[DTSPROCESS]
			   ,[INVPROMO_DISCPER]
			   ,[INVPROMO_DICAMT]
			   ,[INVPROMO_LINENO]
			   ,[INVPROMO_BARCODE]
			   ,[INVPROMO_FREEQTY]
			   ,[INVPROMO_SPRICE]
			   ,[INVPROMO_INVQTY]
			   ,[INVPROMO_TYPE]
			   ,[INVPROMO_TXNDATE]
			   ,[INVPROMO_COUPON]
			   ,[INVPROMO_PROMOPLUCODE])
		 VALUES
			   (@LOC_CODE--<INVPROMO_LOCCODE, varchar(5),>
			   ,@INVOICE_NO--<INVPROMO_INVNO, varchar(30),>
			   ,@promoCode--<INVPROMO_PROCODE, varchar(30),>
			   ,''--<INVPROMO_PLU, varchar(30),>
			   ,0--<INVPROMO_CANCELED, bit,>
			   ,@LOC_CODE--<INVPROMO_LOC, varchar(5),>
			   ,0--<DTRANS, bit,>
			   ,0--<DTPROCESS, bit,>
			   ,0--<DTSPROCESS, bit,>
			   ,@promoDiscPer--<INVPROMO_DISCPER, numeric(18,2),>
			   ,0--<INVPROMO_DICAMT, numeric(18,2),>
			   ,NULL--<INVPROMO_LINENO, numeric(18,0),>
			   ,''--<INVPROMO_BARCODE, varchar(30),>
			   ,0--<INVPROMO_FREEQTY, numeric(18,0),>
			   ,0--<INVPROMO_SPRICE, numeric(18,2),>
			   ,0--<INVPROMO_INVQTY, numeric(18,3),>
			   ,@invMode--<INVPROMO_TYPE, varchar(3),>
			   ,@date--<INVPROMO_TXNDATE, datetime,>
			   ,''--<INVPROMO_COUPON, varchar(30),>
			   ,''--<INVPROMO_PROMOPLUCODE, varchar(30),>
			)
		END
		if @memberCode!=''
		begin 
			insert into  U_TBLCUSTOMERPROMOTION (PRC_CMCODE, PRC_PROMOCODE, PRC_DATETIME, PRC_INVNO, PRC_LOCCODE, PRC_STATION, PRC_CASHIER) values(@memberCode,@promoCode,@date,@INVOICE_NO,@LOC_CODE,@terminalId,@cashier)
		end
	-- save promotions

	INSERT INTO [dbo].[T_TBLINVFREEISSUES]
           ([INVPROMO_LOCCODE]
           ,[INVPROMO_INVNO]
           ,[INVPROMO_PROCODE]
           ,[INVPROMO_PLU]
           ,[INVPROMO_CANCELED]
           ,[INVPROMO_LOC]
           ,[DTRANS]
           ,[DTPROCESS]
           ,[DTSPROCESS]
           ,[INVPROMO_DISCPER]
           ,[INVPROMO_DICAMT]
           ,[INVPROMO_LINENO]
           ,[INVPROMO_BARCODE]
           ,[INVPROMO_FREEQTY]
           ,[INVPROMO_SPRICE]
           ,[INVPROMO_INVQTY]
           ,[INVPROMO_TYPE]
           ,[INVPROMO_TXNDATE]
           ,[INVPROMO_COUPON]
		   ,INVPROMO_PROMOPLUCODE
		   )
     SELECT
           @LOC_CODE--<INVPROMO_LOCCODE, varchar(3),>
           ,@INVOICE_NO--<INVPROMO_INVNO, varchar(30),>
           ,d.PROMO_CODE--<INVPROMO_PROCODE, varchar(30),>
           ,d.PRO_CODE--<INVPROMO_PLU, varchar(30),>
           ,0--<INVPROMO_CANCELED, bit,>
           ,@LOC_CODE--<INVPROMO_LOC, varchar(5),>
           ,0--<DTRANS, bit,>
           ,0--<DTPROCESS, bit,>
           ,0--<DTSPROCESS, bit,>
           ,d.PROMO_DISC_PRE--<INVPROMO_DISCPER, numeric(18,2),>
           ,d.PROMO_DISC_AMT--<INVPROMO_DICAMT, numeric(18,2),>
           ,d.LINE_NO--<INVPROMO_LINENO, numeric(18,0),>
           ,d.SCAN_BARCODE--<INVPROMO_BARCODE, varchar(30),>
           ,d.FREE_QTY--<INVPROMO_FREEQTY, numeric(18,0),>
           ,d.SELLING--<INVPROMO_SPRICE, numeric(18,2),>
           ,d.UNIT_QTY--<INVPROMO_INVQTY, numeric(18,3),>
           ,'INV'--<INVPROMO_TYPE, varchar(3),>
           ,@datetime--<INVPROMO_TXNDATE, datetime,>
           ,''--<INVPROMO_COUPON, varchar(30),>
		   ,d.PROMO_ORIGINAL_ITEM
		 FROM @details d WHERE d.PROMO_CODE is NOT NULL AND d.PROMO_CODE!='' AND d.ITEM_VOID=0 AND (d.PROMO_ORIGINAL_ITEM!='' OR d.PROMO_BILL_DISC_PRE>0 OR d.PROMO_DISC_AMT>0 OR d.PROMO_DISC_PRE>0)
		 
		if @memberCode!=''
		begin 
			insert into  U_TBLCUSTOMERPROMOTION (PRC_CMCODE, PRC_PROMOCODE, PRC_DATETIME, PRC_INVNO, PRC_LOCCODE, PRC_STATION, PRC_CASHIER) 
			select @memberCode,d.PROMO_CODE,@date,@INVOICE_NO,@LOC_CODE,@terminalId,@cashier from @details d 
			WHERE d.PROMO_CODE is NOT NULL AND d.PROMO_CODE!='' AND d.ITEM_VOID=0 AND (d.PROMO_ORIGINAL_ITEM!='' OR d.PROMO_BILL_DISC_PRE>0 OR d.PROMO_DISC_AMT>0 OR d.PROMO_DISC_PRE>0)
		end

		*/

		INSERT INTO [dbo].[T_TBLINVFREEISSUES]
			   ([INVPROMO_LOCCODE]
			   ,[INVPROMO_INVNO]
			   ,[INVPROMO_PROCODE]
			   ,[INVPROMO_PLU]
			   ,[INVPROMO_CANCELED]
			   ,[INVPROMO_LOC]
			   ,[DTRANS]
			   ,[DTPROCESS]
			   ,[DTSPROCESS]
			   ,[INVPROMO_DISCPER]
			   ,[INVPROMO_DICAMT]
			   ,[INVPROMO_LINENO]
			   ,[INVPROMO_BARCODE]
			   ,[INVPROMO_FREEQTY]
			   ,[INVPROMO_SPRICE]
			   ,[INVPROMO_INVQTY]
			   ,[INVPROMO_TYPE]
			   ,[INVPROMO_TXNDATE]
			   ,[INVPROMO_COUPON]
			   ,[INVPROMO_PROMOPLUCODE],
			   [INVPROMO_BENEFICIALVALUE]
			   ,[INVPROMO_DESC])
		 select Location_code,
				@INVOICE_NO,
				Promotion_code,
				product_code,
				0,
				Location_code,
				0,
				0,
				0,
				discount_per,
				discount_amt,
				line_no,
				barcode,
				free_qty,
				selling_price,
				invoice_qty,
				invoice_mode,
				@datetime,
				coupon_code,
				promo_product,
				beneficial_value,
				promotion_name
		 from #promoFreeIssues
		 
		if @memberCode!=''
		begin 
			insert into  U_TBLCUSTOMERPROMOTION (PRC_CMCODE, PRC_PROMOCODE, PRC_DATETIME, PRC_INVNO, PRC_LOCCODE, PRC_STATION, PRC_CASHIER) 
			select distinct @memberCode,Promotion_code,@date,@INVOICE_NO,@LOC_CODE,@terminalId,@cashier from #promoFreeIssues 
		end

		print('free issue saved');

		--Save promo tickets
		--DECLARE @NumberOfTickets INT;
		--select @NumberOfTickets=isnull(ticketQty,0) from #promoTickets

		IF EXISTS (SELECT 1 FROM #promoTickets)
		begin
			--DECLARE @Counter INT = 1;
			--DECLARE @RandomNumber INT;

			--WHILE @Counter <= @NumberOfTickets
			--begin
			--	SET @RandomNumber = FLOOR(RAND() * 100) + 1;
				
			--	INSERT INTO T_TBLINVPROMOTICKETS (PROMO_LOCCODE,PROMO_INVNO,PROMO_TICKETID,PROMO_SERIAL,PROMO_PROCODE)
			--	SELECT @LOC_CODE,@INVOICE_NO,ticketId,@INVOICE_NO + CAST(@RandomNumber AS VARCHAR(20)),promotionCode FROM #promoTickets
			--	SET @Counter = @Counter + 1;
			--end
			
			INSERT INTO T_TBLINVPROMOTICKETS (
			PROMO_LOCCODE,
			PROMO_INVNO,
			PROMO_TICKETID,
			PROMO_SERIAL,
			PROMO_PROCODE,
			PROMO_TICKETVALUE)
			SELECT 
			@LOC_CODE,
			@INVOICE_NO,
			ticketId,
			ticketSerial,
			promotionCode,
			ticketValue
			FROM #promoTickets
		end


		   --save inv payment ref



			INSERT INTO T_TBLINVPAYMENTREF
					   ([INVREF_INVNO]
					   ,[INVREF_TXNINVNO]
					   ,[INVREF_TXNREFNO]
					   ,[INVREF_CARDTYPE]
					   ,[INVREF_CARDBIN]
					   ,[INVREF_LASTDIGITS]
					   ,[INVREF_HOLDER]
					   ,[INVREF_TERMINAL]
					   ,[INVREF_MERCHANT]
					   ,[INVREF_BANK]
					   ,[INVREF_ACKNOWLEDGEMENT]
					   ,[INVREF_STATUS]
					   ,INVREF_DATETIME
					   )
				 SELECT 
					   @INVOICE_NO--<INVREF_INVNO, varchar(30),>
					   ,strTxnInvoiceNum--<INVREF_TXNINVNO, varchar(150),>
					   ,strTxnReference--<INVREF_TXNREFNO, varchar(150),>
					   ,strTxnCardtype--<INVREF_CARDTYPE, varchar(25),>
					   ,strTxnCardBin--<INVREF_CARDBIN, varchar(6),>
					   ,strTxnCardLastDigits--<INVREF_LASTDIGITS, varchar(6),>
					   ,strTxnCardHolderName--<INVREF_HOLDER, varchar(50),>
					   ,strTxnTerminal--<INVREF_TERMINAL, varchar(50),>
					   ,strTxnMerchent--<INVREF_MERCHANT, varchar(50),>
					   ,strIssuedBank--<INVREF_BANK, varchar(50),>
					   ,strAcknowledgement--<INVREF_ACKNOWLEDGEMENT, varchar(50),>
					   ,success--<INVREF_STATUS, bit,>)
					   ,GETDATE()
					   FROM #paymentRefs
		 print('payment ref saved ');

		   -- save line remarks 

		   INSERT INTO [dbo].[T_TBLINVLINEREMARKS]
           ([INVREM_LOCCODE]
           ,[INVREM_INVNO]
           ,[INVREM_LINENO]
           ,[INVREM_LINEREMARKS]
           ,[DTRANS]
           ,[DTPROCESS]
           ,[DTSPROCESS])
		   SELECT 
		    @LOC_CODE--<INVREM_LOCCODE, varchar(5),>
           ,@INVOICE_NO--<INVREM_INVNO, varchar(15),>
           ,LINE_NO--<INVREM_LINENO, numeric(18,0),>
           ,LINE_REMARK--<INVREM_LINEREMARKS, varchar(60),>
           ,0--<DTRANS, bit,>
           ,0--<DTPROCESS, bit,>
           ,1--<DTSPROCESS, bit,>
		   
		   FROM #lineRemarks

		   print('line remark saved')

	-- save payment
	
	INSERT INTO [dbo].[T_TBLINVPAYMENTS]
           ([INVPAY_SETUPLOC]
           ,[INVPAY_LOCCODE]
           ,[INVPAY_INVNO]
           ,[INVPAY_MODE]
           ,[INVPAY_SIGNONDATE]
           ,[INVPAY_STATION]
           ,[INVPAY_CASHIER]
           ,[INVPAY_SHITNO]
           ,[INVPAY_TEMCASHIER]
           ,[INVPAY_SEQUENCE]
           ,[INVPAY_PHCODE]
           ,[INVPAY_PDCODE]
           ,[INVPAY_REFNO]
           ,[INVPAY_AMOUNT]
           ,[INVPAY_PAIDAMOUNT]
           ,[INVPAY_DETDATE]
           ,[INVPAY_CANCELD]
           ,[DTRANS]
           ,[DTPROCESS]
           ,[DTSPROCESS]
           ,[INVPAY_FRAMOUNT]
           ,[PAY_COMCODE]
           ,[INVPAY_US_VS_FC]
           ,[INVPAY_SL_VS_FC]
           ,[INVPAY_SLR_CONVERT]
           ,[INVPAY_SIGNOFF])
           SELECT @SETUP_LOCATION--<INVPAY_SETUPLOC, varchar(3),>
           ,@LOC_CODE--<INVPAY_LOCCODE, varchar(3),>
           ,@INVOICE_NO--<INVPAY_INVNO, varchar(11),>
           ,@invMode--<INVPAY_MODE, varchar(3),>
           ,@signOnDate--<INVPAY_SIGNONDATE, datetime,>
           ,@terminalId--<INVPAY_STATION, varchar(3),>
           ,@cashier--<INVPAY_CASHIER, varchar(10),>
           ,@shiftNo--<INVPAY_SHITNO, numeric(18,2)(18,0),>
           ,@tempCashier--<INVPAY_TEMCASHIER, varchar(10),>
           ,1--<INVPAY_SEQUENCE, numeric(18,2)(18,0),>
           ,ph_code--<INVPAY_PHCODE, varchar(8),>
           ,pd_code--<INVPAY_PDCODE, varchar(8),>
           ,ref_no--<INVPAY_REFNO, varchar(25),>
           ,@netAmount--<INVPAY_AMOUNT, numeric(18,2)(18,2),>
           ,paid_amount--<INVPAY_PAIDAMOUNT, numeric(18,2)(18,2),>
           ,IIF(date IS NULL OR date ='',  @date,date) --<INVPAY_DETDATE, datetime,>
           ,0--<INVPAY_CANCELD, bit,>
           ,0--<DTRANS, bit,>
           ,0--<DTPROCESS, bit,>
           ,0--<DTSPROCESS, bit,>
           ,amount--<INVPAY_FRAMOUNT, numeric(18,2)(18,2),>
           ,@comCode--<PAY_COMCODE, varchar(3),>
           ,0--<INVPAY_US_VS_FC, numeric(18,2)(18,5),>
           ,rate--<INVPAY_SL_VS_FC, numeric(18,2)(18,5),>
           ,0--<INVPAY_SLR_CONVERT, numeric(18,2)(18,5),>
           ,0--<INVPAY_SIGNOFF, bit,>
		   FROM #payments

	--Update advance payment redeemptions	
	update T_TBLINVHEADER set INVHED_ORDNUMBER=@INVOICE_NO 
	from T_TBLINVHEADER, 
	(select p.ref_no from #payments p inner join M_TBLPAYMODEHEAD h on p.ph_code=h.PH_CODE where h.PH_LINKADVANCE=1) adv
	where INVHED_INVNO=adv.ref_no AND INVHED_MODE='REC'

	---Update Stock In Hand

	SELECT STOCK_CODE, ((SUM(ISNULL(CASE_QTY,0))*MAX(PRO_CASE_SIZE)) + (SUM(ISNULL(CASE_FREE_QTY,0))*MAX(PRO_CASE_SIZE)) + SUM(UNIT_QTY) + SUM(ISNULL(FREE_QTY,0))) AS QTY INTO #Temp 
	FROM #details GROUP BY STOCK_CODE

	UPDATE pn SET pn.IPLU_SIH = pn.IPLU_SIH - dt.QTY
	FROM M_TBLPROINVENTORY pn INNER JOIN #Temp dt ON pn.IPLU_PRODUCTCODE = dt.STOCK_CODE
	WHERE pn.IPLU_LOCCODE = @LOC_CODE

	--UPDATE pn SET pn.IPLU_SIH = pn.IPLU_SIH - ((CASE_QTY*PRO_CASE_SIZE) + (CASE_FREE_QTY*PRO_CASE_SIZE) + UNIT_QTY + FREE_QTY) 
	--FROM M_TBLPROINVENTORY pn INNER JOIN @details dt ON pn.IPLU_PRODUCTCODE = dt.STOCK_CODE
	--WHERE pn.IPLU_LOCCODE = @LOC_CODE
		
	-- UPDATE TRANSACTION TABLE
	IF @refMode <> '' AND @refNo <> ''
	BEGIN
		DECLARE @table varchar(25)
		DECLARE @sql varchar(1000)

		SELECT @table=TX_HEADERTABLE FROM U_TBLTXNSETUP WHERE TX_TYPE=@refMode
		
		SET @sql= 'UPDATE ' + @table + ' SET HED_INVS=1 WHERE HED_RUNNO = ''' + @refNo +'''';
		EXEC (@sql)



	END

	select * from T_TBLINVHEADER where invhed_invno=@INVOICE_NO and invhed_loccode=@LOC_CODE and invhed_mode=@invMode
	select * from T_TBLINVDETAILS where invdet_invno=@INVOICE_NO and invdet_loccode=@LOC_CODE and invdet_mode=@invMode
	select * from T_TBLINVPAYMENTS where invpay_invno=@INVOICE_NO and invpay_loccode=@LOC_CODE and invpay_mode=@invMode
	select * from T_TBLINVFREEISSUES where INVPROMO_INVNO=@INVOICE_NO and INVPROMO_LOCCODE=@LOC_CODE
	select * from T_TBLINVLINEREMARKS where INVREM_INVNO=@INVOICE_NO and INVREM_LOCCODE=@LOC_CODE
	select * from M_TBLCUSTOMER where cm_code=@memberCode
	select * from U_TBLPRINTMSG
	SELECT * FROM M_TBLPAYMODEHEAD
	SELECT * FROM M_TBLPAYMODEDET
	SELECT * FROM M_TBLLOCATIONS
	select * from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@LOC_CODE AND PROMO_INVNO=@INVOICE_NO
	select H.PTICK_CODE AS TICKET_CODE,H.PTICK_DESC AS TICKET_NAME,D.PTICK_LINENO AS LINE_NO,D.PTICK_DESC AS LINE_CONTENT,D.PTICK_BOLD AS IS_BOLD,
	D.PTICK_UNDLINE AS IS_UNDERLINE from M_TBLPROMOTION_TICKETS_HED H,M_TBLPROMOTION_TICKETS_DET D 
	WHERE H.PTICK_CODE=D.PTICK_CODE AND H.PTICK_CODE IN (select PROMO_TICKETID from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@LOC_CODE AND PROMO_INVNO=@INVOICE_NO) ORDER BY H.PTICK_CODE, D.PTICK_LINENO 
	--SELECT * FROM M_TBLTITLES

	/*
	-- going through gv from inv details
	UPDATE M_TBLVOUCHERS
	SET VC_SOLDINVNO=@INVOICE_NO,VC_SOLDPOS=@terminalId,VC_SOLDCASHIER=@cashier,VC_SOLDLOC=@LOC_CODE,VC_SOLDDATE=@date
	FROM M_TBLVOUCHERS
	JOIN @details a ON a.PRO_CODE = VC_NUMBER 
	WHERE a.IS_VOUCHER =1 AND a.ITEM_VOID=0 AND a.UNIT_QTY>0 AND a.PRO_CODE != 'exchange_999999_voucher' AND @invoiced=1


	-- going through return gb from inv details
	UPDATE M_TBLVOUCHERS
	SET VC_RETURNINVNO=@INVOICE_NO,VC_RETURNPOS=@terminalId,VC_RETURNCASHIER=@cashier,VC_RETURNLOC=@LOC_CODE,VC_RETURNDATE=@date
	FROM M_TBLVOUCHERS
	JOIN @details a ON a.PRO_CODE = VC_NUMBER 
	WHERE a.IS_VOUCHER =1 AND a.ITEM_VOID=0 AND a.UNIT_QTY<0 AND a.PRO_CODE != 'exchange_999999_voucher'


	-- going through gv from inv payments
	UPDATE M_TBLVOUCHERS
	SET VC_REDEEMINVNO=@INVOICE_NO,VC_REDEEMPOS=@terminalId,VC_REDEEMCASHIER=@cashier,VC_REDEEMLOC=@LOC_CODE,VC_REDEEMDATE=@date
	FROM M_TBLVOUCHERS
	JOIN @payments a ON a.ref_no = VC_NUMBER
	JOIN M_TBLPAYMODEHEAD h ON a.pd_code = h.PH_CODE OR a.ph_code = h.PH_CODE AND h.PH_LINKCUSTOMERCOUPON=1
	WHERE h.PH_LINKGV=1 OR h.PH_LINKCUSTOMERCOUPON=1
	*/

		  

	
	SET @error = null;

	COMMIT TRAN
	END TRY
    
	BEGIN CATCH
	ROLLBACK TRAN
		SET @error = ERROR_MESSAGE();
		return @error
	END CATCH
  
  

END
GO


