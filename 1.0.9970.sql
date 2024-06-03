

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

	select  @date=INVHED_DATETIME,@memberCode=INVHED_MEMBER,@signOnDate=INVHED_SIGNONDATE,@terminalId=INVHED_STATION,@cashier=INVHED_CASHIER,@shiftNo=INVHED_SHITNO,@tempCashier=INVHED_TEMCASHIER,@netAmount=INVHED_NETAMT  from T_TBLINVHEADER where INVHED_LOCCODE=@LOC_CODE and INVHED_INVNO=@INVOICE_NO and INVHED_MODE=@invMode

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


CREATE TABLE [dbo].[T_TBLINVREMARKS](
	[INVREM_LOCCODE] [varchar](10) NOT NULL,
	[INVREM_INVNO] [varchar](30) NOT NULL,
	[INVREM_REMARKS1] [varchar](100) NULL,
	[INVREM_REMARKS2] [varchar](100) NULL,
	[INVREM_REMARKS3] [varchar](100) NULL,
	[INVREM_REMARKS4] [varchar](100) NULL,
	[INVREM_REMARKS5] [varchar](100) NULL,
	[DTRANS] [bit] NULL,
	[DTPROCESS] [bit] NULL,
	[DTSPROCESS] [bit] NULL
) ON [PRIMARY]
GO


------------------------------------------------------


CREATE TABLE [dbo].[T_TBLINVREMARKS_HOLD](
	[INVREM_LOCCODE] [varchar](10) NOT NULL,
	[INVREM_INVNO] [varchar](30) NOT NULL,
	[INVREM_REMARKS1] [varchar](100) NULL,
	[INVREM_REMARKS2] [varchar](100) NULL,
	[INVREM_REMARKS3] [varchar](100) NULL,
	[INVREM_REMARKS4] [varchar](100) NULL,
	[INVREM_REMARKS5] [varchar](100) NULL,
	[DTRANS] [bit] NULL,
	[DTPROCESS] [bit] NULL,
	[DTSPROCESS] [bit] NULL
) ON [PRIMARY]
GO


---------------------------------------------------------



CREATE PROCEDURE [dbo].[myPOS_DP_GET_HEDREMARK]
	@invoiceNo varchar(30)
AS
BEGIN

            SELECT 
				[INVREM_REMARKS1],
				[INVREM_REMARKS2],
				[INVREM_REMARKS3],
				[INVREM_REMARKS4],
				[INVREM_REMARKS5] 
			FROM T_TBLINVREMARKS 
			where INVREM_INVNO=@invoiceNo
END
GO


-----------------------------------------------


CREATE PROCEDURE [dbo].[myPOS_DP_GET_HOLD_HEDREMARK]
	@invoiceNo varchar(30)
AS
BEGIN
 SELECT 
				[INVREM_REMARKS1],
				[INVREM_REMARKS2],
				[INVREM_REMARKS3],
				[INVREM_REMARKS4],
				[INVREM_REMARKS5] 
			FROM T_TBLINVREMARKS_HOLD 
			where INVREM_INVNO=@invoiceNo
END
GO


------------------------------------

ALTER PROCEDURE [dbo].[myPOS_DP_HOLD_INVOICE]
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
	@hedRemarks varchar(max),
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
	/*
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
	*/

	/*
	--Preparing INV PRO TAX dataset
	SELECT [taxCode] ,[productCode] ,[grossAmount] ,[taxAmount] ,[taxPercentage] ,[afterTax] ,
	[taxInc] ,[plineNo] ,[taxSeq] 
	INTO #proTax FROM OPENJSON(@proTax)
	WITH ([taxCode] [varchar](10) ,[productCode] [varchar](30) ,[grossAmount] [numeric](18, 2) ,[taxAmount] [numeric](18, 2) ,[taxPercentage] [numeric](18, 2) ,[afterTax] [numeric](18, 2) ,
	[taxInc] [bit] ,[plineNo] [int] ,[taxSeq] [int] 
	)
	*/

	--Preparing INV LINE REMARKS dataset
	SELECT [LINE_NO],[LINE_REMARK]
	INTO #lineRemarks FROM OPENJSON(@lineRemarks) WITH ([LINE_NO] [numeric](18,0) ,	[LINE_REMARK] [varchar](250))

	--Preparing INV HEADER REMARKS dataset
	SELECT [INVREM_REMARKS1],[INVREM_REMARKS2],[INVREM_REMARKS3],[INVREM_REMARKS4],[INVREM_REMARKS5]
	INTO #hedRemarks FROM OPENJSON(@hedRemarks) WITH ([INVREM_REMARKS1] [varchar](100),[INVREM_REMARKS2] [varchar](100),[INVREM_REMARKS3] [varchar](100),[INVREM_REMARKS4] [varchar](100),[INVREM_REMARKS5] [varchar](100))

	/*
	--Preparing INV LINE FREE ISSUE (PROMOTIONS) dataset
	SELECT [Location_code] ,[Promotion_code] ,[product_code] ,[cancelled] ,[discount_per] ,[discount_amt] ,
	[line_no] ,[barcode] ,[free_qty] ,[selling_price] ,[invoice_qty] ,[invoice_mode] ,
	[invoice_date] ,[coupon_code] ,[promo_product] ,[beneficial_value] 
	INTO #promoFreeIssues FROM OPENJSON(@promoFreeIssues)
	WITH ([Location_code] [varchar](10) ,[Promotion_code] [varchar](10) ,[product_code] [varchar](30) ,[cancelled] [bit] ,[discount_per] [numeric](18, 2) ,[discount_amt] [numeric](18, 2) ,
	[line_no] [numeric](18, 2) ,[barcode] [varchar](30) ,[free_qty] [numeric](18, 2) ,[selling_price] [numeric](18, 2) ,[invoice_qty] [numeric](18, 2) ,[invoice_mode] [varchar](10) ,
	[invoice_date] [varchar](40) ,[coupon_code] [varchar](30) ,[promo_product] [varchar](30) ,[beneficial_value] [numeric](18, 2) 
	)

	
	--Preparing INV PROMO TICKETS (PROMOTIONS) dataset
	SELECT [ticketId] ,[ticketQty] ,[promotionCode] ,[promotionDesc] ,[ticketValue], [ticketRedeemFromDate], [ticketRedeemToDate], 
		[ticketRedeemFromVal], [ticketRedeemToVal], [ticketSerial], [company]
		INTO #promoTickets FROM OPENJSON(@promoTickets) 
		WITH ([ticketId] [varchar](10) ,[ticketQty] [numeric](18, 2) ,[promotionCode] [varchar](30) ,[promotionDesc] [varchar](200) ,
		[ticketValue] [numeric](18, 2), [ticketRedeemFromDate] [varchar](100), [ticketRedeemToDate] [varchar](100), 
		[ticketRedeemFromVal] [numeric](18, 2), [ticketRedeemToVal] [numeric](18, 2), [ticketSerial] [varchar](100), [company] [varchar](10))
		*/
	--SELECT @CreditAmount = SUM(ISNULL(paid_amount,0)) FROM #payments WHERE ph_code = 'CRE'

-- save inv header
	INSERT INTO [dbo].[T_TBLINVHEADER_HOLD]
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
	INSERT INTO [dbo].[T_TBLINVDETAILS_HOLD]
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


		   -- save line remarks 

		   INSERT INTO [dbo].[T_TBLINVLINEREMARKS_HOLD]
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

		   IF EXISTS (SELECT 1 FROM #hedRemarks)
			begin
				INSERT INTO [T_TBLINVREMARKS_HOLD]
				(
				[INVREM_LOCCODE],
				[INVREM_INVNO],
				[INVREM_REMARKS1],
				[INVREM_REMARKS2],
				[INVREM_REMARKS3],
				[INVREM_REMARKS4],
				[INVREM_REMARKS5],
				[DTRANS],
				[DTPROCESS],
				[DTSPROCESS]
				)
				SELECT 
				@LOC_CODE,
				@INVOICE_NO,
				[INVREM_REMARKS1],
				[INVREM_REMARKS2],
				[INVREM_REMARKS3],
				[INVREM_REMARKS4],
				[INVREM_REMARKS5],
				0,
				0,
				0
				FROM #hedRemarks

			end
		print('header remarks saved')


	select * from T_TBLINVHEADER_HOLD where invhed_invno=@INVOICE_NO and invhed_loccode=@LOC_CODE and invhed_mode=@invMode
	select * from T_TBLINVDETAILS_HOLD where invdet_invno=@INVOICE_NO and invdet_loccode=@LOC_CODE and invdet_mode=@invMode
	select * from T_TBLINVPAYMENTS where invpay_invno=@INVOICE_NO and invpay_loccode=@LOC_CODE and invpay_mode=@invMode
	select * from T_TBLINVFREEISSUES where INVPROMO_INVNO=@INVOICE_NO and INVPROMO_LOCCODE=@LOC_CODE
	select * from T_TBLINVLINEREMARKS_HOLD where INVREM_INVNO=@INVOICE_NO and INVREM_LOCCODE=@LOC_CODE
	select * from M_TBLCUSTOMER where cm_code=@memberCode
	select * from U_TBLPRINTMSG
	SELECT * FROM M_TBLPAYMODEHEAD
	SELECT * FROM M_TBLPAYMODEDET
	SELECT * FROM M_TBLLOCATIONS
	select * from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@LOC_CODE AND PROMO_INVNO=@INVOICE_NO
	select H.PTICK_CODE AS TICKET_CODE,H.PTICK_DESC AS TICKET_NAME,D.PTICK_LINENO AS LINE_NO,D.PTICK_DESC AS LINE_CONTENT,D.PTICK_BOLD AS IS_BOLD,
	D.PTICK_UNDLINE AS IS_UNDERLINE from M_TBLPROMOTION_TICKETS_HED H,M_TBLPROMOTION_TICKETS_DET D 
	WHERE H.PTICK_CODE=D.PTICK_CODE AND H.PTICK_CODE IN (select PROMO_TICKETID from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@LOC_CODE AND PROMO_INVNO=@INVOICE_NO) ORDER BY H.PTICK_CODE, D.PTICK_LINENO 
	select * from T_TBLINVREMARKS_HOLD where INVREM_INVNO=@INVOICE_NO and INVREM_LOCCODE=@LOC_CODE

	--SELECT * FROM M_TBLTITLES

	
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


------------------------------------------


ALTER TABLE dbo.U_TBLSETUP ADD
	SETUP_SALES_BOM int NULL
GO
ALTER TABLE dbo.U_TBLSETUP ADD CONSTRAINT
	DF_U_TBLSETUP_SETUP_SALES_BOM DEFAULT 0 FOR SETUP_SALES_BOM
GO
ALTER TABLE dbo.U_TBLSETUP SET (LOCK_ESCALATION = TABLE)
GO

--------------------------------------------






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
	@hedRemarks varchar(max),
	@error nvarchar(max) output
AS

DECLARE @CreditAmount numeric(18,2)

BEGIN
	SET NOCOUNT ON;
	set xact_abort on;
	BEGIN TRY
	BEGIN TRAN t_inv
	print ('transaction begin')


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
	SELECT	[paid_amount] ,[date_time] ,[amount] ,	[canceled] ,[pd_code] ,[ph_code] , [ref_no] ,[date] ,[rate] ,[framount]
	INTO #payments FROM OPENJSON(@payments)
	WITH ([paid_amount] [numeric](18, 2) ,[date_time] [varchar](max) ,[amount] [numeric](18, 2) ,	[canceled] [bit] ,[pd_code] [varchar](8) ,[ph_code] [varchar](8), [ref_no] [varchar](max) ,
	[date] [varchar](MAX) ,[rate] [numeric](18, 3) , [framount] [numeric](18, 3) 
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
	[taxInc] ,[lineNo] ,[taxSeq] 
	INTO #proTax FROM OPENJSON(@proTax)
	WITH ([taxCode] [varchar](10) ,[productCode] [varchar](30) ,[grossAmount] [numeric](18, 2) ,[taxAmount] [numeric](18, 2) ,[taxPercentage] [numeric](18, 2) ,[afterTax] [numeric](18, 2) ,
	[taxInc] [bit] ,[lineNo] [int] ,[taxSeq] [int] 
	)

	--Preparing INV LINE REMARKS dataset
	SELECT [LINE_NO],[LINE_REMARK]
	INTO #lineRemarks FROM OPENJSON(@lineRemarks) WITH ([LINE_NO] [numeric](18,0) ,	[LINE_REMARK] [varchar](250))

	--Preparing INV HEADER REMARKS dataset
	SELECT [INVREM_REMARKS1],[INVREM_REMARKS2],[INVREM_REMARKS3],[INVREM_REMARKS4],[INVREM_REMARKS5]
	INTO #hedRemarks FROM OPENJSON(@hedRemarks) WITH ([INVREM_REMARKS1] [varchar](100),[INVREM_REMARKS2] [varchar](100),[INVREM_REMARKS3] [varchar](100),[INVREM_REMARKS4] [varchar](100),[INVREM_REMARKS5] [varchar](100))

	--Preparing INV FREE ISSUE (PROMOTIONS) dataset
	SELECT [Location_code] ,[Promotion_code] ,[product_code] ,[cancelled] ,[discount_per] ,[discount_amt] ,
	[line_no] ,[barcode] ,[free_qty] ,[selling_price] ,[invoice_qty] ,[invoice_mode] ,
	[invoice_date] ,[coupon_code] ,[promo_product] ,[beneficial_value] ,[promotion_name],[discountValue]
	INTO #promoFreeIssues FROM OPENJSON(@promoFreeIssues)
	WITH ([Location_code] [varchar](10) ,[Promotion_code] [varchar](10) ,[product_code] [varchar](30) ,[cancelled] [bit] ,[discount_per] [numeric](18, 2) ,[discount_amt] [numeric](18, 2) ,
	[line_no] [numeric](18, 2) ,[barcode] [varchar](30) ,[free_qty] [numeric](18, 2) ,[selling_price] [numeric](18, 2) ,[invoice_qty] [numeric](18, 2) ,[invoice_mode] [varchar](10) ,
	[invoice_date] [varchar](40) ,[coupon_code] [varchar](30) ,[promo_product] [varchar](30) ,[beneficial_value] [numeric](18, 2) , [promotion_name] varchar(500), [discountValue] [numeric](18,2)
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
           ,(select top(1) STAT_MACHINEID from u_tblstations where STAT_ID=@terminalId and STAT_LOCCODE=@LOC_CODE)--<INVHED_TABLE, varchar(8),>
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
		   ,INVDET_PROMOCODE
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
		   ,ISNULL(PROMO_DISC_AMT,0) AS PROMO_DISC_AMT
		   ,ISNULL(PROMO_DISC_PRE,0) AS PROMO_DISC_PRE
		   ,ISNULL(PROMO_BILL_DISC_PRE,0) AS PROMO_BILL_DISC_PRE
		   ,INVDET_PRICEMODE
		   ,PROMO_CODE
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
           ,[lineNo]--<TXN_LINENO, numeric(18,0),>
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
			   ,[INVPROMO_COMPANY_CONTRIB]
			   ,[INVPROMO_SUPPLIER_CONTRIB]
			   ,[INVPROMO_DESC]
			   ,[INVPROMO_DISC_VALUE])
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
				PRO_COMPANY_CONTRIBUTION,
				PRO_SUPPLIER_CONTRIBUTION,
				promotion_name,
				discountValue
		 from #promoFreeIssues left outer join M_TBLPROMOTION on Promotion_code= PRO_CODE 
		 print('free issue saved');
		 

		 -----Contribution update from M_TBLPROPRICE table for promo items

		 IF EXISTS (SELECT 1 FROM #promoFreeIssues)
		 begin

		 update T_TBLINVFREEISSUES set INVPROMO_COMPANY_CONTRIB=contrib.PPLU_COMCONTRIBUTE, INVPROMO_SUPPLIER_CONTRIB=contrib.PPLU_SUPCONTRIBUTE
		 from T_TBLINVFREEISSUES F,
		 (select A.product_code,A.Promotion_code,A.Location_code,PPLU_COMCONTRIBUTE,PPLU_SUPCONTRIBUTE 
		 from 
		 (select product_code, Promotion_code,PRO_PRICEMODE,Location_code from #promoFreeIssues inner join M_TBLPROMOTION on Promotion_code=PRO_CODE 
		 where (PRO_PRICEMODE is not null and PRO_PRICEMODE<>'')) A , M_TBLPROPRICE where A.product_code=PPLU_CODE and A.PRO_PRICEMODE=PPLU_PRIMODE and A.Location_code=PPLU_LOCCODE) contrib
		 where F.INVPROMO_PROCODE=contrib.Promotion_code and F.INVPROMO_LOCCODE=contrib.Location_code  and F.INVPROMO_PLU=contrib.product_code and F.INVPROMO_INVNO=@INVOICE_NO and F.INVPROMO_LOCCODE=@LOC_CODE
		 print('free issue price mode contribution saved');
		 end
		 --************************************************************

		if @memberCode!=''
		begin 
			insert into  U_TBLCUSTOMERPROMOTION (PRC_CMCODE, PRC_PROMOCODE, PRC_DATETIME, PRC_INVNO, PRC_LOCCODE, PRC_STATION, PRC_CASHIER) 
			select distinct @memberCode,Promotion_code,@date,@INVOICE_NO,@LOC_CODE,@terminalId,@cashier from #promoFreeIssues 
		end

		print('free issue cus update saved');

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

	IF EXISTS (SELECT 1 FROM #hedRemarks)
	begin
		INSERT INTO [T_TBLINVREMARKS]
		(
		[INVREM_LOCCODE],
		[INVREM_INVNO],
		[INVREM_REMARKS1],
		[INVREM_REMARKS2],
		[INVREM_REMARKS3],
		[INVREM_REMARKS4],
		[INVREM_REMARKS5],
		[DTRANS],
		[DTPROCESS],
		[DTSPROCESS]
		)
		SELECT 
		@LOC_CODE,
		@INVOICE_NO,
		[INVREM_REMARKS1],
		[INVREM_REMARKS2],
		[INVREM_REMARKS3],
		[INVREM_REMARKS4],
		[INVREM_REMARKS5],
		0,
		0,
		0
		FROM #hedRemarks

	end
	print('header remarks saved')
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
           ,framount--<INVPAY_FRAMOUNT, numeric(18,2)(18,2),>
           ,@comCode--<PAY_COMCODE, varchar(3),>
           ,0--<INVPAY_US_VS_FC, numeric(18,2)(18,5),>
           ,rate--<INVPAY_SL_VS_FC, numeric(18,2)(18,5),>
           ,0--<INVPAY_SLR_CONVERT, numeric(18,2)(18,5),>
           ,0--<INVPAY_SIGNOFF, bit,>
		   FROM #payments
	
	print('payment saved')

	--Update advance payment redeemptions	
	update T_TBLINVHEADER set INVHED_ORDNUMBER=@INVOICE_NO 
	from T_TBLINVHEADER, 
	(select p.ref_no from #payments p inner join M_TBLPAYMODEHEAD h on p.ph_code=h.PH_CODE where h.PH_LINKADVANCE=1) adv
	where INVHED_INVNO=adv.ref_no AND INVHED_MODE='REC'

	print('advance payment redemption saved')

	--Sales BOM Update

	if @invMode='INV'
	BEGIN
		DECLARE @IsActiveSalesBOM int
		SELECT @IsActiveSalesBOM = isnull(SETUP_SALES_BOM,0) FROM U_TBLSETUP

		IF @IsActiveSalesBOM=1
		BEGIN
			IF EXISTS(SELECT PLU_CODE FROM #details, M_TBLPROMASTER WHERE [PRO_CODE]=PLU_CODE AND PLU_PRODUCTION_POS=1)
			BEGIN
			INSERT INTO T_TBLSPN_POS_DETAILS(
			DET_LINENO, DET_TYPE, DET_RUNNO, DET_COMCODE, DET_LOCFROM, DET_LOCTO, DET_SACODE, DET_PROCODE, DET_STOCKCODE, DET_PRODESC, DET_UNIT, DET_CS, DET_EXPDATE, DET_EXPBATCH, DET_SYSQTY, 
            DET_CASEQTY, DET_UNITQTY, DET_FCASEQTY, DET_FUNITQTY, DET_BALQTY, DET_FBALQTY, DET_VARQTY, DET_OSPRICE, DET_OCPRICE, DET_OACPRICE, DET_SPRICE, DET_CPRICE, DET_ACOST, DET_APRICE, DET_DISCPER, 
            DET_DISCAMT, DET_AMOUNT, DET_REMCODE, CR_DATE, CR_BY, DTS_DATE, DTRANS, DTPROCESS
			)
			select ROW_NUMBER() OVER (ORDER BY [PRO_CODE]) AS line, *
			from
			(
			SELECT 'SBM' AS TXTYPE,@INVOICE_NO AS RUNNO,@comCode as company,@LOC_CODE as LocFrom,@LOC_CODE as LocTo,'' as SA,[PRO_CODE],[STOCK_CODE],PLU_DESC,PLU_UNIT,PLU_CS,'01/JAN/1900' as EXPIRY,'' AS EXBATCH,0 as SYSQTY, 
			0 AS CQTY,UNIT_QTY,0 AS FQTY,0 AS FUQTY,UNIT_QTY AS BALQTY,0 AS FBAL,0 AS VARQTY,[PRO_SELLING] AS DET_OSPRICE,[PRO_COST] AS DET_OCPRICE,[PRO_AVG_COST] AS DET_OACPRICE,[PRO_SELLING] AS DET_SPRICE,[PRO_COST] AS DET_CPRICE,[PRO_AVG_COST] AS DET_ACOST,[PRO_AVG_COST] AS DET_APRICE,0 as DISCPER,
			0 AS DISAMT,[PRO_COST]*UNIT_QTY AS AMT, '' AS REMCODE,GETDATE() AS CR_DATE,@cashier as CR_USER,GETDATE() AS DTS_DATE,0 AS DTRANS,0 AS DTPROCESS
			FROM #details, M_TBLPROMASTER WHERE [PRO_CODE]=PLU_CODE AND PLU_PRODUCTION_POS=1
			UNION ALL
			SELECT  'SBM' AS TXTYPE,@INVOICE_NO AS RUNNO,@comCode as company,@LOC_CODE as LocFrom,@LOC_CODE as LocTo,'' as SA,DBOM_SPLU,IPLU_PRODUCTCODE,PLU_DESC,PLU_UNIT,PLU_CS,'01/JAN/1900' as EXPIRY,'' AS EXBATCH,0 as SYSQTY, 
			0 AS CQTY,(UNIT_QTY*DBOM_QTY)*-1 AS UNIT_QTY,0 AS FQTY,0 AS FUQTY,UNIT_QTY AS BALQTY,0 AS FBAL,0 AS VARQTY,IPLU_SELL AS DET_OSPRICE,IPLU_COST AS DET_OCPRICE,IPLU_AVGCOST AS DET_OACPRICE,IPLU_SELL AS DET_SPRICE,IPLU_COST AS DET_CPRICE,IPLU_AVGCOST AS DET_ACOST,IPLU_AVGCOST AS DET_APRICE,0 as DISCPER,
			0 AS DISAMT,IPLU_COST*(UNIT_QTY*DBOM_QTY)*-1 AS AMT, '' AS REMCODE,GETDATE() AS CR_DATE,@cashier as CR_USER,GETDATE() AS DTS_DATE,0 AS DTRANS,0 AS DTPROCESS
			FROM M_TBLPROBOMHED, M_TBLPROBOMDET, (SELECT PLU_CODE,[UNIT_QTY] FROM #details, M_TBLPROMASTER WHERE [PRO_CODE]=PLU_CODE AND PLU_PRODUCTION_POS=1) F_ITEM, M_TBLPROMASTER, M_TBLPROINVENTORY 
			WHERE BOM_CODE=DBOM_CODE AND BOM_FINISHPRO= F_ITEM.PLU_CODE AND DBOM_SPLU=M_TBLPROMASTER.PLU_CODE AND DBOM_SPLU=IPLU_CODE AND IPLU_LOCCODE=@LOC_CODE
			) A
			print('BOM details saved')
			DECLARE @TotAmount numeric(18,2)
			SELECT @TotAmount=SUM(DET_AMOUNT) FROM T_TBLSPN_POS_DETAILS WHERE DET_RUNNO=@INVOICE_NO
			INSERT INTO T_TBLSPN_POS_HEADER(
			HED_TYPE, HED_RUNNO, HED_COMCODE, HED_SETUPLOC, HED_TXNDATE, HED_TIME, HED_PROCDATE, HED_CANDATE, HED_LOGLOCATION, HED_LOCFROM, HED_LOCTO, HED_LOCDEL, HED_SUPCODE, 
            HED_CUSCODE, HED_REFTYPE, HED_REFNO, HED_REF1, HED_REF2, HED_PRIECMODE, HED_GROAMT, HED_DISCPER, HED_ITAXAMT, HED_ETAXAMT, HED_ADDAMT, HED_DEDAMT, HED_NETAMT, HED_CANUSER, HED_EXPBATCH, 
            HED_GLBATCH, HED_PRINTCOUNT, HED_RECCOUNT, HED_REFCOUNT, HED_PROCESSED, HED_CANCELLED, HED_FULLYUSED, HED_EXPORT, HED_LOCKED, HED_INVS, HED_REFDOCVAL, HED_EXTREFDOC, HED_PAIDAMT, 
            HED_DUEAMT, HED_BEFOREDATE, HED_AFTERDATE, CR_DATE, CR_BY, MD_DATE, MD_BY, DTS_DATE, DTRANS, DTPROCESS, INTERMEDIARYUPLOADBEGIN, INTERMEDIARYUPLOADEND
			)
			VALUES(
			'SBM',@INVOICE_NO,@comCode,@SETUP_LOCATION,@date,@time-2,GETDATE(),NULL,@LOC_CODE,@LOC_CODE,@LOC_CODE,@LOC_CODE,'',
			'','','','','','',@TotAmount,0,0,0,0,0,@TotAmount,'','',
			'',0,0,0,1,0,1,0,0,0,0,'',0,
			0,@date,@date,GETDATE(),@cashier,GETDATE(),null,getdate(),0,0,0,0
			)
			print('BOM header saved')
			
			UPDATE M_TBLPROINVENTORY SET IPLU_SIH= IPLU_SIH - (STK.QTY*-1) 
			FROM M_TBLPROINVENTORY, (select  DET_STOCKCODE, sum(DET_UNITQTY) AS QTY from T_TBLSPN_POS_DETAILS where DET_RUNNO=@INVOICE_NO group by DET_STOCKCODE) STK
			WHERE IPLU_PRODUCTCODE=STK.DET_STOCKCODE AND IPLU_LOCCODE=@LOC_CODE

			print('BOM stock update saved')
			END
		END

	END
	--end update BOM

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
	SELECT * FROM M_TBLLOCATIONS where LOC_CODE = @LOC_CODE
	select * from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@LOC_CODE AND PROMO_INVNO=@INVOICE_NO
	select H.PTICK_CODE AS TICKET_CODE,H.PTICK_DESC AS TICKET_NAME,D.PTICK_LINENO AS LINE_NO,D.PTICK_DESC AS LINE_CONTENT,D.PTICK_BOLD AS IS_BOLD,
	D.PTICK_UNDLINE AS IS_UNDERLINE from M_TBLPROMOTION_TICKETS_HED H,M_TBLPROMOTION_TICKETS_DET D 
	WHERE H.PTICK_CODE=D.PTICK_CODE AND H.PTICK_CODE IN (select PROMO_TICKETID from T_TBLINVPROMOTICKETS where PROMO_LOCCODE=@LOC_CODE AND PROMO_INVNO=@INVOICE_NO) ORDER BY H.PTICK_CODE, D.PTICK_LINENO 
	select * from T_TBLINVREMARKS where INVREM_INVNO=@INVOICE_NO and INVREM_LOCCODE=@LOC_CODE
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


----------------------------------------

CREATE PROCEDURE [dbo].[myPOS_DP_GET_INVOICE_HED_REMARKS_BY_INVOICE_ID]
	@InvoiceID NVARCHAR(30)
AS
BEGIN
	SELECT * FROM T_TBLINVREMARKS WHERE INVREM_INVNO = @InvoiceID
END
GO


-------------------------------------------



CREATE TYPE [dbo].[SYNC_INV_HED_REMARKS] AS TABLE(
	[INVREM_LOCCODE] [varchar](10) NOT NULL,
	[INVREM_INVNO] [varchar](20) NOT NULL,
	[INVREM_REMARKS1] [varchar](100) NULL,
	[INVREM_REMARKS2] [varchar](100) NULL,
	[INVREM_REMARKS3] [varchar](100) NULL,
	[INVREM_REMARKS4] [varchar](100) NULL,
	[INVREM_REMARKS5] [varchar](100) NULL,
	[DTRANS] [bit] NULL,
	[DTPROCESS] [bit] NULL,
	[DTSPROCESS] [bit] NULL
)
GO


------------------------------------------




ALTER PROCEDURE [dbo].[myPOS_DP_SYNC_INVOICE]
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
	@discAmt  numeric(18,2),
	@lineDiscPerTot  numeric(18,2),
	@lineDiscAmtTot numeric(18,2),
	@netAmount numeric(18,2),
	@payAmount numeric(18,2),
	@dueAmount numeric(18,2),
	@changeAmount numeric(18,2),
	@invoiced tinyint = 1,	
	@refMode varchar(50) = '',
	@refNo varchar(50) = '',
	@taxInc numeric(18,2) = 0,
	@taxExc numeric(18,2) = 0,
	@detailsTable dbo.SYNC_INV_DETAILS READONLY,
	@paymentsTable dbo.SYNC_INV_PAYMENTS READONLY,
	@lineRemarksTable dbo.SYNC_INV_LINE_REMARKS READONLY,
	@freeIssueTable dbo.SYNC_INV_FREE_ISSUES READONLY,
	@proTax dbo.SYNC_INV_PRO_TAX READONLY,
	@hedRemarks dbo.SYNC_INV_HED_REMARKS readonly,
	@error nvarchar(max) output
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN

	SET NOCOUNT ON;

	DECLARE @pointAdded  numeric(18,2)=0;
	DECLARE @pointDeducted  numeric(18,2)=0;
	DECLARE @pointNetAmount  numeric(18,2)=0;

-- save inv header
	INSERT INTO [dbo].[T_TBLINVHEADER]
           ([INVHED_SETUPLOC]
           ,[INVHED_LOCCODE]
           ,[INVHED_INVNO]
           ,[INVHED_MODE]
           ,[INVHED_TXNDATE]
           ,[INVHED_TIME]
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
           ,[INVHED_TRANSFER]
           ,[INVHED_SPOTCHECK]
		   ,[INVHED_STARTTIME]
		   )
     VALUES
           (@SETUP_LOCATION
           ,@LOC_CODE
           ,@INVOICE_NO
           ,@invMode
           ,@date
           ,@startTime--<INVHED_TIME, datetime,>
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
           ,@pointAdded --<INVHED_POINTADDED, decimal(18,2),>
           ,@pointDeducted--<INVHED_POINTDEDUCT, decimal(18,2),>
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
           ,0--<INVHED_CREAMT, decimal(18,2),>
           ,0--<INVHED_TAXPER, decimal(18,2),>
           ,@taxInc--<INVHED_INCTAXAMT, decimal(18,3),>
           ,0--<INVHED_SERAMT, decimal(18,3),>
           ,''--<GLBATCHNO, varchar(10),>
           ,''--<GLBATCHNO2, varchar(10),>
           ,0--<INVHED_PRINT, bit,>
           ,@startDateTime--<INVHED_DATETIME, datetime,>
           ,@comCode--<HED_COMCODE, varchar(3),>
           ,1--<INVHED_SLR_CONVERT, numeric(18,2)(18,5),>
           ,0--<INVHED_TAXBILLNO, numeric(18,2)(18,0),>
           ,0--<INVHED_SIGNOFF, bit,>
           ,0--<INVHED_SESSION, numeric(18,2)(18,0),>
           ,'LM'--<INVHED_SALEMODE, varchar(3),>
           ,(select top(1) STAT_MACHINEID from u_tblstations where STAT_ID=@terminalId and STAT_LOCCODE=@LOC_CODE)--<INVHED_TABLE, varchar(8),>
           ,0--<INVHED_VAT, numeric(18,2)(18,2),>
           ,0--<INVHED_NBT, numeric(18,2)(18,2),>
           ,0--<INVHED_TRANSFER, int,>
		   ,null
		   ,@startTime--<INVHED_STARTTIME datetime> 
		   )


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
           ,[DET_SERVICEPER]
           ,[INVDET_SALE1]
           ,[INVDET_SALE1COMM]
           ,[INVDET_SALE2]
           ,[INVDET_SALE2COMM]
           ,[INVDET_SALE3]
           ,[INVDET_SALE3COMM]
           ,[DET_COMCODE]
           ,[INVDET_SLR_CONVERT]
           ,[INVDET_PRINT]
           ,[INVDET_SCANBARCODE]
           ,[INVDET_EXPDATE]
           ,[INVDET_CALEXP]
           ,[INVDET_DATETIME]
           ,[INV_DISPLAYED]
           ,[INVDET_PLU_PACKPRICE]
           ,[INVDET_DISTYPE]
           ,[INVDET_PROMODISCPER]
           ,[INVDET_PROMODISCAMT]
           ,[INVDET_PROMOBILLDISCPER])
	 SELECT [INVDET_SETUPLOC]
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
			,[DET_SERVICEPER]
			,[INVDET_SALE1]
			,[INVDET_SALE1COMM]
			,[INVDET_SALE2]
			,[INVDET_SALE2COMM]
			,[INVDET_SALE3]
			,[INVDET_SALE3COMM]
			,[DET_COMCODE]
			,[INVDET_SLR_CONVERT]
			,[INVDET_PRINT]
			,[INVDET_SCANBARCODE]
			,[INVDET_EXPDATE]
			,[INVDET_CALEXP]
			,[INVDET_DATETIME]
			,[INV_DISPLAYED]
			,[INVDET_PLU_PACKPRICE]
			,[INVDET_DISTYPE]
			,[INVDET_PROMODISCPER]
			,[INVDET_PROMODISCAMT]
			,[INVDET_PROMOBILLDISCPER]
		FROM @detailsTable

	-- Save payment data
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
	SELECT [INVPAY_SETUPLOC]
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
		  ,[INVPAY_SIGNOFF]
	  FROM @paymentsTable

	-- save data invoice line remarks
	INSERT INTO [dbo].[T_TBLINVLINEREMARKS]
				([INVREM_LOCCODE]
				,[INVREM_INVNO]
				,[INVREM_LINENO]
				,[INVREM_LINEREMARKS]
				,[DTRANS]
				,[DTPROCESS]
				,[DTSPROCESS])
	SELECT [INVREM_LOCCODE]
			,[INVREM_INVNO]
			,[INVREM_LINENO]
			,[INVREM_LINEREMARKS]
			,[DTRANS]
			,[DTPROCESS]
			,[DTSPROCESS]
		FROM @lineRemarksTable

	--save invoice header remarks
	INSERT INTO [dbo].[T_TBLINVREMARKS]
				([INVREM_LOCCODE] ,
				[INVREM_INVNO] ,
				[INVREM_REMARKS1] ,
				[INVREM_REMARKS2] ,
				[INVREM_REMARKS3] ,
				[INVREM_REMARKS4] ,
				[INVREM_REMARKS5] ,
				[DTRANS] ,
				[DTPROCESS] ,
				[DTSPROCESS])
	SELECT [INVREM_LOCCODE] ,
				[INVREM_INVNO] ,
				[INVREM_REMARKS1] ,
				[INVREM_REMARKS2] ,
				[INVREM_REMARKS3] ,
				[INVREM_REMARKS4] ,
				[INVREM_REMARKS5] ,
				[DTRANS] ,
				[DTPROCESS] ,
				[DTSPROCESS]
	FROM @hedRemarks

	-- save free issues data
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
           ,[INVPROMO_COUPON])
	SELECT [INVPROMO_LOCCODE]
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
		FROM @freeIssueTable

	-- save data invoice promotion tax
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
	SELECT [TXN_TYPE]
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
		,[TXN_LINENO]
	FROM @proTax

	update  pn SET pn.IPLU_SIH = pn.IPLU_SIH - dt.QTY
	FROM M_TBLPROINVENTORY pn inner join (select INVDET_STOCKCODE,sum((INVDET_CASEQTY*INVDET_PROCASESIZE) +INVDET_UNITQTY) as QTY from @detailsTable group by INVDET_STOCKCODE) dt
	ON pn.IPLU_PRODUCTCODE = dt.INVDET_STOCKCODE
	where pn.IPLU_LOCCODE= @LOC_CODE
	
	
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


-----------------------------------



ALTER PROCEDURE [dbo].[myPOS_DP_DELETE_SYNCED_INVOICE_FROM_LOCAL]
   -- Add the parameters for the stored procedure here
   @InvoiceID varchar(30),
   @InvMode varchar(5)
AS
BEGIN
   -- SET NOCOUNT ON added to prevent extra result sets from
   -- interfering with SELECT statements.
   SET NOCOUNT ON;

   -- Insert statements for procedure here
   DELETE FROM T_TBLINVHEADER WHERE INVHED_INVNO=@InvoiceID AND INVHED_MODE= @InvMode
   DELETE FROM T_TBLINVDETAILS WHERE INVDET_INVNO=@InvoiceID AND INVDET_MODE= @InvMode
   DELETE FROM T_TBLINVPAYMENTS WHERE INVPAY_INVNO=@InvoiceID AND INVPAY_MODE= @InvMode
   DELETE FROM T_TBLTXNTAX WHERE TXN_INVNO=@InvoiceID AND TXN_MODE= @InvMode
   DELETE FROM T_TBLINVFREEISSUES WHERE INVPROMO_INVNO=@InvoiceID
   DELETE FROM T_TBLINVLINEREMARKS WHERE INVREM_INVNO=@InvoiceID
   DELETE FROM T_TBLINVREMARKS WHERE INVREM_INVNO=@InvoiceID
END
GO


--------------------------------------

ALTER PROCEDURE [dbo].[myPOS_DP_SAVE_Denominations]
	@cashier varchar(50),
	@shiftNo varchar(4),
	@signOndate varchar(50),
	@signOnTime varchar(50),
	@terminalId varchar(50),
	@setUpLocation varchar(50),
	@details dbo.DenominatonDet READONLY,
	@list dbo.Denominaton READONLY -- pay det table results
AS
BEGIN
	DECLARE @error varchar(max)

	BEGIN TRY
	BEGIN TRAN



	-- insert the denominations 

INSERT INTO [dbo].[U_TBLSIGNOFFDENOMINATIONDET]
           ([DE_DATE]
           ,[DE_TIME]
           ,[DE_LOCATION]
           ,[DE_USER]
           ,[DE_STATION]
           ,[DE_SHIFT]
           ,[DE_DENCODE]
           ,[DE_DENPHYAMT]
           ,[DTRANS]
           ,[DTPROCESS]
           ,[DTSPROCESS])
     SELECT 
		    @signOndate--<DE_DATE, datetime,>
           ,@signOnTime,--<DE_TIME, datetime,>
           @setUpLocation,--<DE_LOCATION, varchar(5),>
           @cashier,--<DE_USER, varchar(10),>
           @terminalId,--<DE_STATION, varchar(3),>
           @shiftNo,--<DE_SHIFT, decimal(18,0),>
           denomination_code,--<DE_DENCODE, varchar(5),>
           SUM(d_value * d_count),--<DE_DENPHYAMT, decimal(18,4),>
           0,--<DTRANS, bit,>
           0,--<DTPROCESS, bit,>
           0--<DTSPROCESS, bit,>
	FROM @details
	GROUP BY denomination_code


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


-- get invoice count,cancel invoice count reprint count
	SELECT @invoiceCount=COUNT(INVHED_INVNO) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId
	SELECT @cancelInvoiceCount=COUNT(INVHED_INVNO) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_CANCELED=1 AND INVHED_MODE='INV' AND INVHED_SHITNO=@shiftNo  AND INVHED_STATION=@terminalId
	SELECT @reprintCount=SUM(INVHED_PRINTNO) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV'  AND INVHED_SHITNO=@shiftNo  AND INVHED_STATION=@terminalId
	--get first and last invoice no
	SELECT TOP 1 @firstInvoice=INVHED_INVNO FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' AND INVHED_SHITNO=@shiftNo  AND INVHED_STATION=@terminalId ORDER BY INVHED_TIME 
	SELECT TOP 1 @lastInvoice=INVHED_INVNO FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' AND INVHED_SHITNO=@shiftNo   AND INVHED_STATION=@terminalId ORDER BY INVHED_TIME DESC

	-- get net total
	SELECT @netTotal=ISNULL(SUM(INVHED_NETAMT),0) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED= 0AND INVHED_MODE='INV' AND INVHED_SHITNO=@shiftNo  AND INVHED_STATION=@terminalId

	--get hold bill total
	SELECT @holdBillTotal=ISNULL(SUM(INVHED_NETAMT) ,0) FROM T_TBLINVHEADER_HOLD WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=0 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId

	-- refund total

	SELECT @refundTotal=SUM(ISNULL(INVDET_UNITQTY,0)* ISNULL(INVDET_SELLING,0)) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND invdet_void = 0 and
	CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVDET_UNITQTY<0 AND INVHED_MODE='INV'  AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId

	-- discount calculation
	SELECT @discAmtTotal=SUM(INVDET_DISCAMT) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND
	CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV'  AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId

	SELECT @discPerTotal=SUM(INVDET_DISCPER * INVDET_UNITQTY * INVDET_SELLING / 100) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND
	CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV'  AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId

	SELECT @billDiscTotal=SUM(INVDET_BILLDISCPER * INVDET_UNITQTY * INVDET_SELLING / 100) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND
	CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVDET_NODISC=0 AND INVHED_MODE='INV'  AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId

	SET @discountTotal = ISNULL(@billDiscTotal,0)+ISNULL(@discPerTotal,0)+ISNULL(@discAmtTotal,0)

	-- get cash in 
	SELECT @cashIn=ISNULL(SUM(INVHED_NETAMT) ,0) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='REC'  AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId
	
	-- get cash out
	SELECT @cashOut=ISNULL(SUM(INVHED_NETAMT) ,0) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='WIT'  AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId


	-- get openning balance
	SELECT @openBalance=ISNULL(UH_FLOAT,0) FROM U_TBLUSERHEAD WHERE UH_ID = @cashier

	--get it physical cash amount from denominations
	DECLARE @temp1 numeric(18,2)
	DECLARE @temp2 numeric(18,2)
	SELECT @temp1=SUM(d_value*d_count) FROM @details WHERE main_code = 'CSH'
	SELECT @temp2=SUM(total_value) FROM @list WHERE detail_code = 'CSH'
	SET @physicalCashAmount = ISNULL(@temp1,0)+ISNULL(@temp2,0);
	--calculated cash
	DECLARE @cashCalculated numeric(18,2)

	SELECT @cashSales=ISNULL(SUM(INVPAY_PAIDAMOUNT),0) FROM T_TBLINVPAYMENTS,T_TBLINVHEADER WHERE INVHED_INVNO=INVPAY_INVNO AND CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVPAY_PHCODE='CSH' AND INVHED_MODE = 'INV' and INVPAY_MODE = 'INV'  AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId
	SET @cashCalculated =  + @cashSales + @cashIn - @cashOut

	-- insert into sign off header
	INSERT INTO [dbo].[U_TBLSIGNOFFHEADER]
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
           ,[SOH_RECEIPTS_OTHER])
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
           0--<SOH_RECEIPTS_OTHER, numeric(18,2),>
		   );

	-- insert into sign off details
	INSERT INTO [dbo].[U_TBLSIGNOFFDETAIL]
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
           ,[DTSPROCESS])
     SELECT
		   @signOndate,--<SOD_DATE, datetime,>
           @signOnTime,--<SOD_TIME, datetime,>
           @setUpLocation,--<SOD_LOCATION, varchar(5),>
           @cashier,--<SOD_USER, varchar(10),>
           @terminalId,--<SOD_STATION, varchar(3),>
           @shiftNo,--<SOD_SHIFT, decimal(18,0),>
           isnull(INVPAY_PHCODE,code),--<SOD_PAYCODE, varchar(5),>
           isnull(INVPAY_PDCODE,detail_code),--<SOD_PAYDETCODE, varchar(50),>
           SUM(isnull(INVPAY_PAIDAMOUNT,0)),--<SOD_SYSAMT, decimal(18,4),>
           ISNULL (total_value,0),--<SOD_PHYAMT, decimal(18,4),>
           ISNULL(total_value,0)-ISNULL(SUM(INVPAY_PAIDAMOUNT),0),--<SOD_VARAMT, decimal(18,4),>
           0,--<DTRANS, bit,>
           0,--<DTPROCESS, bit,>
           0--<DTSPROCESS, bit,>
	from
	(select INVPAY_PHCODE,INVPAY_PDCODE,INVPAY_PAIDAMOUNT
	FROM T_TBLINVPAYMENTS
	INNER JOIN T_TBLINVHEADER
	ON INVHED_INVNO=INVPAY_INVNO
	WHERE CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVPAY_PDCODE !='CSH' AND
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0  AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId AND INVHED_MODE = 'INV' ) P
	full outer join
	@list ON P.INVPAY_PDCODE=detail_code
	GROUP BY INVPAY_PDCODE,detail_code,INVPAY_PHCODE,code,total_value

	--commented below by Pubudu Wijetunge to fix the issue when there are no actual payments recorded in invoice tables (29/03/2024) 
	/*
	INSERT INTO [dbo].[U_TBLSIGNOFFDETAIL]
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
           ,[DTSPROCESS])
     SELECT
		   @signOndate,--<SOD_DATE, datetime,>
           @signOnTime,--<SOD_TIME, datetime,>
           @setUpLocation,--<SOD_LOCATION, varchar(5),>
           @cashier,--<SOD_USER, varchar(10),>
           @terminalId,--<SOD_STATION, varchar(3),>
           @shiftNo,--<SOD_SHIFT, decimal(18,0),>
           INVPAY_PHCODE,--<SOD_PAYCODE, varchar(5),>
           INVPAY_PDCODE,--<SOD_PAYDETCODE, varchar(50),>
           SUM(INVPAY_PAIDAMOUNT),--<SOD_SYSAMT, decimal(18,4),>
           ISNULL (total_value,0),--<SOD_PHYAMT, decimal(18,4),>
           ISNULL(total_value,0)-ISNULL(SUM(INVPAY_PAIDAMOUNT),0),--<SOD_VARAMT, decimal(18,4),>
           0,--<DTRANS, bit,>
           0,--<DTPROCESS, bit,>
           0--<DTSPROCESS, bit,>
	FROM T_TBLINVPAYMENTS
	INNER JOIN T_TBLINVHEADER
	ON INVHED_INVNO=INVPAY_INVNO
	LEFT JOIN @list
	ON INVPAY_PDCODE=detail_code
	WHERE CONVERT(DATE,INVHED_DATETIME) = CONVERT(DATE,@signOndate) AND INVPAY_PDCODE !='CSH' AND
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVPAY_SHITNO = @shiftNo AND INVHED_MODE = 'INV'
	GROUP BY INVPAY_PDCODE,INVPAY_PHCODE,total_value
	*/
	-- insert cash record
		INSERT INTO [dbo].[U_TBLSIGNOFFDETAIL]
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
           ,[DTSPROCESS])
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
           ISNULL(@physicalCashAmount,0),--<SOD_PHYAMT, decimal(18,4),>
           ISNULL(@physicalCashAmount,0)-ISNULL(@cashSales,0),--<SOD_VARAMT, decimal(18,4),>
           0,--<DTRANS, bit,>
           0,--<DTPROCESS, bit,>
           0--<DTSPROCESS, bit,>
		   )
	-- update user hed table
	UPDATE U_TBLUSERHEAD SET UH_ISMNGSIGNOFF=1 WHERE UH_ID=@cashier;
	
	UPDATE T_TBLINVHEADER SET INVHED_SIGNOFF=1 WHERE INVHED_CASHIER=@cashier 
	AND INVHED_SHITNO=@shiftNo AND INVHED_SIGNONDATE=@signOndate AND INVHED_STATION=@terminalId AND INVHED_LOCCODE=@setUpLocation
	
	SELECT * FROM U_TBLSIGNOFFHEADER where SOH_LOCATION=@setUpLocation and SOH_DATE=@signOndate and SOH_USER=@cashier and SOH_STATION=@terminalId and SOH_SHIFT=@shiftNo
	SELECT U_TBLSIGNOFFDETAIL.*,PH_DESC FROM U_TBLSIGNOFFDETAIL, M_TBLPAYMODEHEAD where SOD_PAYCODE=PH_CODE and SOD_LOCATION=@setUpLocation and SOD_DATE=@signOndate and SOD_USER=@cashier and SOD_STATION=@terminalId and SOD_SHIFT=@shiftNo
	select * from U_TBLSIGNOFFDENOMINATIONDET where DE_LOCATION=@setUpLocation and DE_DATE=@signOndate and DE_USER=@cashier and DE_STATION=@terminalId and DE_SHIFT=@shiftNo

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

--------------------------------------------------------------------------------

ALTER PROCEDURE [dbo].[myPOS_DP_REPRINT_INVOICE]
@invoiceNo varchar(50),
@locCode varchar(10),
@invMode varchar(5)
AS
BEGIN
	DECLARE @count int
	
	SELECT  @count = INVHED_PRINTNO FROM T_TBLINVHEADER
	WHERE INVHED_INVNO=@invoiceNo

	SET @count= @count+1


	UPDATE T_TBLINVHEADER SET INVHED_PRINTNO=@count WHERE INVHED_INVNO=@invoiceNo
	
	select * from T_TBLINVHEADER where invhed_invno=@invoiceNo and invhed_loccode=@locCode and invhed_mode=@invMode
	select * from T_TBLINVDETAILS where invdet_invno=@invoiceNo and invdet_loccode=@locCode and invdet_mode=@invMode
	select * from T_TBLINVPAYMENTS where invpay_invno=@invoiceNo and invpay_loccode=@locCode and invpay_mode=@invMode
	select * from T_TBLINVFREEISSUES where INVPROMO_INVNO=@invoiceNo and INVPROMO_LOCCODE=@locCode
	select * from T_TBLINVLINEREMARKS where INVREM_INVNO=@invoiceNo and INVREM_LOCCODE=@locCode
	select * from M_TBLCUSTOMER where cm_code=(select invhed_member from T_TBLINVHEADER where invhed_invno=@invoiceNo and invhed_loccode=@locCode and invhed_mode=@invMode)
	select * from U_TBLPRINTMSG
	SELECT * FROM M_TBLPAYMODEHEAD
	SELECT * FROM M_TBLPAYMODEDET
	SELECT * FROM M_TBLLOCATIONS where LOC_CODE = @locCode
	select * from T_TBLINVREMARKS where INVREM_INVNO=@invoiceNo and INVREM_LOCCODE=@locCode

	--SELECT '' as error

END
GO

----------------------------------------------------------------------