

create proc [dbo].[myPOS_DP_GET_INVOICE_DET_PRINT]
@invno varchar(25),
@loc varchar(10),
@invmode varchar(5)

as
begin
    select * from T_TBLINVHEADER where invhed_invno=@invno and invhed_loccode=@loc and invhed_mode=@invmode
    select * from T_TBLINVDETAILS where invdet_invno=@invno and invdet_loccode=@loc and invdet_mode=@invmode
    select * from T_TBLINVPAYMENTS where invpay_invno=@invno and invpay_loccode=@loc and invpay_mode=@invmode
    select * from T_TBLINVFREEISSUES where INVPROMO_INVNO=@invno and INVPROMO_LOCCODE=@loc
    select * from T_TBLINVLINEREMARKS where INVREM_INVNO=@invno and INVREM_LOCCODE=@loc
    select * from M_TBLCUSTOMER where cm_code=(select INVHED_MEMBER from T_TBLINVHEADER where invhed_invno=@invno and invhed_loccode=@loc and invhed_mode=@invmode)
    select * from U_TBLPRINTMSG
    SELECT * FROM M_TBLPAYMODEHEAD
    SELECT * FROM M_TBLPAYMODEDET
    SELECT * FROM M_TBLLOCATIONS where LOC_CODE=@loc
    select * from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@loc AND PROMO_INVNO=@invno
    select H.PTICK_CODE AS TICKET_CODE,H.PTICK_DESC AS TICKET_NAME,D.PTICK_LINENO AS LINE_NO,D.PTICK_DESC AS LINE_CONTENT,D.PTICK_BOLD AS IS_BOLD,
    D.PTICK_UNDLINE AS IS_UNDERLINE from M_TBLPROMOTION_TICKETS_HED H,M_TBLPROMOTION_TICKETS_DET D
    WHERE H.PTICK_CODE=D.PTICK_CODE AND H.PTICK_CODE IN (select PROMO_TICKETID from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@loc AND PROMO_INVNO=@invno) ORDER BY H.PTICK_CODE, D.PTICK_LINENO
end    
GO

------------------------------------------------------------------
ALTER proc [dbo].[myPOS_DP_GET_INVOICE_DET_PRINT]
@invno varchar(25),
@loc varchar(10),
@invmode varchar(5)

as
begin
    select * from T_TBLINVHEADER where invhed_invno=@invno and invhed_loccode=@loc and invhed_mode=@invmode
    select * from T_TBLINVDETAILS where invdet_invno=@invno and invdet_loccode=@loc and invdet_mode=@invmode
    select * from T_TBLINVPAYMENTS where invpay_invno=@invno and invpay_loccode=@loc and invpay_mode=@invmode
    select * from T_TBLINVFREEISSUES where INVPROMO_INVNO=@invno and INVPROMO_LOCCODE=@loc
    select * from T_TBLINVLINEREMARKS where INVREM_INVNO=@invno and INVREM_LOCCODE=@loc
    select * from M_TBLCUSTOMER where cm_code=(select INVHED_MEMBER from T_TBLINVHEADER where invhed_invno=@invno and invhed_loccode=@loc and invhed_mode=@invmode)
    select * from U_TBLPRINTMSG
    SELECT * FROM M_TBLPAYMODEHEAD
    SELECT * FROM M_TBLPAYMODEDET
    SELECT * FROM M_TBLLOCATIONS where LOC_CODE=@loc
    select * from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@loc AND PROMO_INVNO=@invno
    select H.PTICK_CODE AS TICKET_CODE,H.PTICK_DESC AS TICKET_NAME,D.PTICK_LINENO AS LINE_NO,D.PTICK_DESC AS LINE_CONTENT,D.PTICK_BOLD AS IS_BOLD,
    D.PTICK_UNDLINE AS IS_UNDERLINE from M_TBLPROMOTION_TICKETS_HED H,M_TBLPROMOTION_TICKETS_DET D
    WHERE H.PTICK_CODE=D.PTICK_CODE AND H.PTICK_CODE IN (select PROMO_TICKETID from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@loc AND PROMO_INVNO=@invno) ORDER BY H.PTICK_CODE, D.PTICK_LINENO
end    
GO
--------------------------------------------------------------------

CREATE TABLE [dbo].[U_TBLINVHEADER_RECLASSIFIED_LOG](
	[INVHED_RECLASSIFY_DATE] [datetime] NULL,
	[INVHED_SETUPLOC] [varchar](5) NULL,
	[INVHED_LOCCODE] [varchar](5) NULL,
	[INVHED_INVNO] [nvarchar](30) NULL,
	[INVHED_MODE] [varchar](3) NULL,
	[INVHED_TXNDATE] [datetime] NULL,
	[INVHED_TIME] [datetime] NULL,
	[INVHED_ENDDATE] [datetime] NULL,
	[INVHED_ENDTIME] [datetime] NULL,
	[INVHED_SIGNONDATE] [datetime] NULL,
	[INVHED_STATION] [varchar](3) NULL,
	[INVHED_CASHIER] [varchar](10) NULL,
	[INVHED_SHITNO] [decimal](18, 0) NULL,
	[INVHED_TEMCASHIER] [varchar](10) NULL,
	[INVHED_MEMBER] [varchar](20) NULL,
	[INVHED_PRICEMODE] [varchar](5) NULL,
	[INVHED_REFMODE] [varchar](3) NULL,
	[INVHED_REFNO] [varchar](30) NULL,
	[INVHED_GROAMT] [decimal](18, 2) NULL,
	[INVHED_DISPER] [decimal](18, 2) NULL,
	[INVHED_DISAMT] [decimal](18, 2) NULL,
	[INVHED_LINEDISCPERTOT] [decimal](18, 2) NULL,
	[INVHED_LINEDISAMTTOT] [decimal](18, 2) NULL,
	[INVHED_ADDAMT] [decimal](18, 2) NULL,
	[INVHED_NETAMT] [decimal](18, 2) NULL,
	[INVHED_PAYAMT] [decimal](18, 2) NULL,
	[INVHED_DUEAMT] [decimal](18, 2) NULL,
	[INVHED_CHANGE] [decimal](18, 2) NULL,
	[INVHED_POINTADDED] [decimal](18, 2) NULL,
	[INVHED_POINTDEDUCT] [decimal](18, 2) NULL,
	[INVHED_PRINTNO] [decimal](18, 0) NULL,
	[INVHED_CANCELED] [bit] NULL,
	[INVHED_CANUSER] [varchar](10) NULL,
	[INVHED_CANDATE] [datetime] NULL,
	[INVHED_CANTIME] [datetime] NULL,
	[CR_DATE] [datetime] NULL,
	[CR_BY] [varchar](10) NULL,
	[MD_DATE] [datetime] NULL,
	[MD_BY] [varchar](10) NULL,
	[DTS_DATE] [datetime] NULL,
	[INVHED_INVOICED] [bit] NULL,
	[INVHED_ORDNUMBER] [varchar](30) NULL,
	[INVHED_ORDDATE] [datetime] NULL,
	[INVHED_ORDTIME] [datetime] NULL,
	[INVHED_ORDENDDATE] [datetime] NULL,
	[INVHED_ORDENDTIME] [datetime] NULL,
	[INVHED_ORDSTATION] [varchar](3) NULL,
	[INVHED_ORDCASHIER] [varchar](10) NULL,
	[DTRANS] [bit] NULL,
	[DTPROCESS] [bit] NULL,
	[DTSPROCESS] [bit] NULL,
	[INVHED_CREAMT] [decimal](18, 2) NULL,
	[INVHED_TAXPER] [decimal](18, 2) NULL,
	[INVHED_INCTAXAMT] [decimal](18, 3) NULL,
	[INVHED_SERAMT] [decimal](18, 3) NULL,
	[GLBATCHNO] [nvarchar](30) NULL,
	[GLBATCHNO2] [nvarchar](30) NULL,
	[INVHED_PRINT] [bit] NULL,
	[INVHED_DATETIME] [datetime] NULL,
	[INVHED_SLR_CONVERT] [numeric](18, 5) NULL,
	[INVHED_TAXBILLNO] [numeric](18, 0) NULL,
	[INVHED_SIGNOFF] [bit] NULL,
	[INVHED_SESSION] [numeric](18, 0) NULL,
	[INVHED_SALEMODE] [varchar](3) NULL,
	[INVHED_TABLE] [varchar](8) NULL,
	[INVHED_VAT] [numeric](18, 2) NULL,
	[INVHED_NBT] [numeric](18, 2) NULL,
	[INVHED_TRANSFER] [int] NULL,
	[INVHED_SPOTCHECK] [bit] NULL,
	[INVHED_VOUCHER] [bit] NULL,
	[INVHED_STARTTIME] [datetime] NULL,
	[INVHED_COMCODE] [varchar](5) NULL,
	[HED_GLBATCH] [nvarchar](30) NULL,
	[INVHED_LOGLOCATION] [nvarchar](10) NULL
) ON [PRIMARY]
GO

------------------------------------------------------------


CREATE TABLE [dbo].[U_TBLINVPAYMENTS_RECLASSIFIED_LOG](
	[INVPAY_RECLASSIFY_DATE] [datetime] NULL,
	[INVPAY_SETUPLOC] [varchar](5) NULL,
	[INVPAY_LOCCODE] [varchar](5) NULL,
	[INVPAY_INVNO] [nvarchar](30) NULL,
	[INVPAY_MODE] [varchar](3) NULL,
	[INVPAY_SIGNONDATE] [datetime] NULL,
	[INVPAY_STATION] [varchar](3) NULL,
	[INVPAY_CASHIER] [varchar](10) NULL,
	[INVPAY_SHITNO] [numeric](18, 0) NULL,
	[INVPAY_TEMCASHIER] [varchar](10) NULL,
	[INVPAY_SEQUENCE] [numeric](18, 0) NULL,
	[INVPAY_PHCODE] [varchar](8) NULL,
	[INVPAY_PDCODE] [varchar](8) NULL,
	[INVPAY_REFNO] [varchar](25) NULL,
	[INVPAY_AMOUNT] [numeric](18, 2) NULL,
	[INVPAY_PAIDAMOUNT] [numeric](18, 2) NULL,
	[INVPAY_DETDATE] [datetime] NULL,
	[INVPAY_CANCELD] [bit] NULL,
	[DTRANS] [bit] NULL,
	[DTPROCESS] [bit] NULL,
	[DTSPROCESS] [bit] NULL,
	[INVPAY_FRAMOUNT] [numeric](18, 2) NULL,
	[PAY_COMCODE] [varchar](5) NULL,
	[INVPAY_US_VS_FC] [numeric](18, 5) NULL,
	[INVPAY_SL_VS_FC] [numeric](18, 5) NULL,
	[INVPAY_SLR_CONVERT] [numeric](18, 5) NULL,
	[INVPAY_SIGNOFF] [bit] NULL
) ON [PRIMARY]
GO

------------------------------------------




CREATE PROCEDURE [dbo].[myPOS_DP_RECLASSIFY_INVOICE]
	@INVOICE_NO  varchar(max),
	@SETUP_LOCATION varchar(10),
	@LOC_CODE varchar(10),
	@comCode varchar(10),
	@invMode varchar(3),
	@payments varchar(max),
	@error nvarchar(max) output
AS

DECLARE @CreditAmount numeric(18,2)

BEGIN
	SET NOCOUNT ON;
	set xact_abort on;
	BEGIN TRY
	BEGIN TRAN t_inv
	print ('transaction begin')

	--Preparing INV PAYMENTS dataset
	SELECT	[paid_amount] ,[date_time] ,[amount] ,	[canceled] ,[pd_code] ,[ph_code] , [ref_no] ,[date] ,[rate] ,[framount]
	INTO #payments FROM OPENJSON(@payments)
	WITH ([paid_amount] [numeric](18, 2) ,[date_time] [varchar](max) ,[amount] [numeric](18, 2) ,	[canceled] [bit] ,[pd_code] [varchar](8) ,[ph_code] [varchar](8), [ref_no] [varchar](max) ,
	[date] [varchar](MAX) ,[rate] [numeric](18, 3) , [framount] [numeric](18, 3) 
	)

	SELECT @CreditAmount = SUM(ISNULL(paid_amount,0)) FROM #payments WHERE ph_code = 'CRE'

	INSERT INTO U_TBLINVHEADER_RECLASSIFIED_LOG 
	( INVHED_RECLASSIFY_DATE,INVHED_SETUPLOC, INVHED_LOCCODE, INVHED_INVNO, INVHED_MODE, INVHED_TXNDATE, INVHED_TIME, INVHED_ENDDATE, INVHED_ENDTIME, INVHED_SIGNONDATE, INVHED_STATION, INVHED_CASHIER, 
                         INVHED_SHITNO, INVHED_TEMCASHIER, INVHED_MEMBER, INVHED_PRICEMODE, INVHED_REFMODE, INVHED_REFNO, INVHED_GROAMT, INVHED_DISPER, INVHED_DISAMT, INVHED_LINEDISCPERTOT, 
                         INVHED_LINEDISAMTTOT, INVHED_ADDAMT, INVHED_NETAMT, INVHED_PAYAMT, INVHED_DUEAMT, INVHED_CHANGE, INVHED_POINTADDED, INVHED_POINTDEDUCT, INVHED_PRINTNO, INVHED_CANCELED, 
                         INVHED_CANUSER, INVHED_CANDATE, INVHED_CANTIME, CR_DATE, CR_BY, MD_DATE, MD_BY, DTS_DATE, INVHED_INVOICED, INVHED_ORDNUMBER, INVHED_ORDDATE, INVHED_ORDTIME, INVHED_ORDENDDATE, 
                         INVHED_ORDENDTIME, INVHED_ORDSTATION, INVHED_ORDCASHIER, DTRANS, DTPROCESS, DTSPROCESS, INVHED_CREAMT, INVHED_TAXPER, INVHED_INCTAXAMT, INVHED_SERAMT, GLBATCHNO, GLBATCHNO2, 
                         INVHED_PRINT, INVHED_DATETIME, INVHED_SLR_CONVERT, INVHED_TAXBILLNO, INVHED_SIGNOFF, INVHED_SESSION, INVHED_SALEMODE, INVHED_TABLE, INVHED_VAT, INVHED_NBT, INVHED_TRANSFER, 
                         INVHED_SPOTCHECK, INVHED_VOUCHER, INVHED_STARTTIME, INVHED_COMCODE, HED_GLBATCH, INVHED_LOGLOCATION
	)
	select GETDATE(),
	 INVHED_SETUPLOC, INVHED_LOCCODE, INVHED_INVNO, INVHED_MODE, INVHED_TXNDATE, INVHED_TIME, INVHED_ENDDATE, INVHED_ENDTIME, INVHED_SIGNONDATE, INVHED_STATION, INVHED_CASHIER, 
                         INVHED_SHITNO, INVHED_TEMCASHIER, INVHED_MEMBER, INVHED_PRICEMODE, INVHED_REFMODE, INVHED_REFNO, INVHED_GROAMT, INVHED_DISPER, INVHED_DISAMT, INVHED_LINEDISCPERTOT, 
                         INVHED_LINEDISAMTTOT, INVHED_ADDAMT, INVHED_NETAMT, INVHED_PAYAMT, INVHED_DUEAMT, INVHED_CHANGE, INVHED_POINTADDED, INVHED_POINTDEDUCT, INVHED_PRINTNO, INVHED_CANCELED, 
                         INVHED_CANUSER, INVHED_CANDATE, INVHED_CANTIME, CR_DATE, CR_BY, MD_DATE, MD_BY, DTS_DATE, INVHED_INVOICED, INVHED_ORDNUMBER, INVHED_ORDDATE, INVHED_ORDTIME, INVHED_ORDENDDATE, 
                         INVHED_ORDENDTIME, INVHED_ORDSTATION, INVHED_ORDCASHIER, DTRANS, DTPROCESS, DTSPROCESS, INVHED_CREAMT, INVHED_TAXPER, INVHED_INCTAXAMT, INVHED_SERAMT, GLBATCHNO, GLBATCHNO2, 
                         INVHED_PRINT, INVHED_DATETIME, INVHED_SLR_CONVERT, INVHED_TAXBILLNO, INVHED_SIGNOFF, INVHED_SESSION, INVHED_SALEMODE, INVHED_TABLE, INVHED_VAT, INVHED_NBT, INVHED_TRANSFER, 
                         INVHED_SPOTCHECK, INVHED_VOUCHER, INVHED_STARTTIME, INVHED_COMCODE, HED_GLBATCH, INVHED_LOGLOCATION
	from T_TBLINVHEADER where INVHED_LOCCODE=@LOC_CODE and INVHED_INVNO=@INVOICE_NO and INVHED_MODE=@invMode

-- save inv header
	UPDATE [dbo].[T_TBLINVHEADER] SET [INVHED_CHANGE]=0,[INVHED_CREAMT]=@CreditAmount
	WHERE [INVHED_SETUPLOC]=@SETUP_LOCATION AND [INVHED_LOCCODE]=@LOC_CODE AND [INVHED_INVNO]=@INVOICE_NO AND [INVHED_MODE]=@invMode
	
	print('header saved');


	declare @signOnDate datetime
	declare @terminalId varchar(5)
	declare @cashier varchar(20)
	declare @shiftNo int
	declare @tempCashier varchar(20)
	declare @netAmount numeric(18,2)
	declare @memberCode varchar(30)
	declare @date datetime

	select  @date=INVHED_DATETIME,@memberCode=INVHED_MEMBER,@signOnDate=INVHED_SIGNONDATE,@terminalId=@terminalId,@cashier=INVHED_CASHIER,@shiftNo=INVHED_SHITNO,@tempCashier=INVHED_TEMCASHIER,@netAmount=INVHED_NETAMT  from T_TBLINVHEADER where INVHED_LOCCODE=@LOC_CODE and INVHED_INVNO=@INVOICE_NO and INVHED_MODE=@invMode

	INSERT into U_TBLINVPAYMENTS_RECLASSIFIED_LOG 
	(INVPAY_RECLASSIFY_DATE,INVPAY_SETUPLOC, INVPAY_LOCCODE, INVPAY_INVNO, INVPAY_MODE, INVPAY_SIGNONDATE, INVPAY_STATION, INVPAY_CASHIER, INVPAY_SHITNO, INVPAY_TEMCASHIER, INVPAY_SEQUENCE, 
                         INVPAY_PHCODE, INVPAY_PDCODE, INVPAY_REFNO, INVPAY_AMOUNT, INVPAY_PAIDAMOUNT, INVPAY_DETDATE, INVPAY_CANCELD, DTRANS, DTPROCESS, DTSPROCESS, INVPAY_FRAMOUNT, PAY_COMCODE, 
                         INVPAY_US_VS_FC, INVPAY_SL_VS_FC, INVPAY_SLR_CONVERT, INVPAY_SIGNOFF
	)
	select GETDATE(),
	INVPAY_SETUPLOC, INVPAY_LOCCODE, INVPAY_INVNO, INVPAY_MODE, INVPAY_SIGNONDATE, INVPAY_STATION, INVPAY_CASHIER, INVPAY_SHITNO, INVPAY_TEMCASHIER, INVPAY_SEQUENCE, 
                         INVPAY_PHCODE, INVPAY_PDCODE, INVPAY_REFNO, INVPAY_AMOUNT, INVPAY_PAIDAMOUNT, INVPAY_DETDATE, INVPAY_CANCELD, DTRANS, DTPROCESS, DTSPROCESS, INVPAY_FRAMOUNT, PAY_COMCODE, 
                         INVPAY_US_VS_FC, INVPAY_SL_VS_FC, INVPAY_SLR_CONVERT, INVPAY_SIGNOFF
	from T_TBLINVPAYMENTS where INVPAY_LOCCODE=@LOC_CODE and INVPAY_INVNO=@INVOICE_NO and INVPAY_MODE=@invMode

	DELETE FROM T_TBLINVPAYMENTS where INVPAY_LOCCODE=@LOC_CODE and INVPAY_INVNO=@INVOICE_NO and INVPAY_MODE=@invMode

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
           ,framount--<INVPAY_FRAMOUNT, numeric(18,2)(18,2),>
           ,@comCode--<PAY_COMCODE, varchar(3),>
           ,0--<INVPAY_US_VS_FC, numeric(18,2)(18,5),>
           ,rate--<INVPAY_SL_VS_FC, numeric(18,2)(18,5),>
           ,0--<INVPAY_SLR_CONVERT, numeric(18,2)(18,5),>
           ,0--<INVPAY_SIGNOFF, bit,>
		   FROM #payments
	
	print('payment saved')


	select * from T_TBLINVHEADER where invhed_invno=@INVOICE_NO and invhed_loccode=@LOC_CODE and invhed_mode=@invMode
	select * from T_TBLINVDETAILS where invdet_invno=@INVOICE_NO and invdet_loccode=@LOC_CODE and invdet_mode=@invMode
	select * from T_TBLINVPAYMENTS where invpay_invno=@INVOICE_NO and invpay_loccode=@LOC_CODE and invpay_mode=@invMode
	select * from T_TBLINVFREEISSUES where INVPROMO_INVNO=@INVOICE_NO and INVPROMO_LOCCODE=@LOC_CODE
	select * from T_TBLINVLINEREMARKS where INVREM_INVNO=@INVOICE_NO and INVREM_LOCCODE=@LOC_CODE
	select * from M_TBLCUSTOMER where cm_code=@memberCode
	select * from U_TBLPRINTMSG
	SELECT * FROM M_TBLPAYMODEHEAD
	SELECT * FROM M_TBLPAYMODEDET
	SELECT * FROM M_TBLLOCATIONS where LOC_CODE = @LOC_CODE
	select * from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@LOC_CODE AND PROMO_INVNO=@INVOICE_NO
	select H.PTICK_CODE AS TICKET_CODE,H.PTICK_DESC AS TICKET_NAME,D.PTICK_LINENO AS LINE_NO,D.PTICK_DESC AS LINE_CONTENT,D.PTICK_BOLD AS IS_BOLD,
	D.PTICK_UNDLINE AS IS_UNDERLINE from M_TBLPROMOTION_TICKETS_HED H,M_TBLPROMOTION_TICKETS_DET D 
	WHERE H.PTICK_CODE=D.PTICK_CODE AND H.PTICK_CODE IN (select PROMO_TICKETID from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@LOC_CODE AND PROMO_INVNO=@INVOICE_NO) ORDER BY H.PTICK_CODE, D.PTICK_LINENO 
	 
	SET @error = null;

	COMMIT TRAN t_inv
	END TRY
    
	BEGIN CATCH
	print 'inside catch'
	ROLLBACK TRAN t_inv
		SET @error = ERROR_MESSAGE();
		return @error
	END CATCH
  
  

END
GO


------------------------------------------------------------
