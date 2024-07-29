ALTER TABLE dbo.M_TBLPAYMODEHEAD ADD
	PH_QRPAY int NULL
GO


-----------------------------------


ALTER PROCEDURE [dbo].[myPOS_DP_GET_PAYMODE_HEADERS] @signOffOnly bit =0
   
AS
BEGIN
   IF @signOffOnly=0 
	BEGIN
	   SELECT PH_CODE,PH_DESC,dbo.parseBool(PH_DETAILS) PH_DETAIL,dbo.parseBool(PH_OVERPAY) PH_OVERPAY,dbo.parseBool(PH_LINKCREDIT) PH_LINKCREDIT,dbo.parseBool(PH_LINKLOYALTY) PH_LINKLOYALTY,dbo.parseBool(PH_LINKGV) PH_LINKGV,PH_APISP,dbo.parseBool(PH_SW_SIGNOFF) PH_SW_SIGNOFF, dbo.parseBool(PH_LINKCUSTOMERCOUPON) PH_LINKCUSTOMERCOUPON, CONVERT(numeric(18,2),PH_POINTSPER) PH_POINTSPER,dbo.parseBool(PH_LINKPROMO) PH_LINKPROMO,dbo.parseBool(PH_DEFAULT) PH_DEFAULT,PH_REFERENCE, dbo.parseBool(PH_LOCALMODE) PH_LOCALMODE,dbo.parseBool(isnull(PH_LINKADVANCE,0)) PH_LINKADVANCE
	   ,dbo.parseBool(isnull(PH_QRPAY,0)) PH_QRPAY
	   FROM M_TBLPAYMODEHEAD 
	   ORDER BY PH_ORDER 
	END
   ELSE
	BEGIN
	   SELECT PH_CODE,PH_DESC,dbo.parseBool(PH_DETAILS) PH_DETAIL,dbo.parseBool(PH_OVERPAY) PH_OVERPAY,dbo.parseBool(PH_LINKCREDIT) PH_LINKCREDIT,dbo.parseBool(PH_LINKLOYALTY) PH_LINKLOYALTY,dbo.parseBool(PH_LINKGV) PH_LINKGV,PH_APISP,dbo.parseBool(PH_SW_SIGNOFF) PH_SW_SIGNOFF, dbo.parseBool(PH_LINKCUSTOMERCOUPON) PH_LINKCUSTOMERCOUPON, CONVERT(numeric(18,2),PH_POINTSPER) PH_POINTSPER,dbo.parseBool(PH_LINKPROMO) PH_LINKPROMO,dbo.parseBool(PH_DEFAULT) PH_DEFAULT,PH_REFERENCE, dbo.parseBool(PH_LOCALMODE) PH_LOCALMODE,dbo.parseBool(isnull(PH_LINKADVANCE,0)) PH_LINKADVANCE
	   ,dbo.parseBool(isnull(PH_QRPAY,0)) PH_QRPAY
	   FROM M_TBLPAYMODEHEAD 
	   WHERE PH_SW_SIGNOFF=1
	   ORDER BY PH_ORDER 
	END
END
GO


-------------------------------------------





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
	SELECT @invoiceCount=COUNT(INVHED_INVNO) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV'
	SELECT @cancelInvoiceCount=COUNT(INVHED_INVNO) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_CANCELED=1 AND INVHED_MODE='INV'
	SELECT @reprintCount=SUM(INVHED_PRINTNO) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV'
	--get first and last invoice no
	SELECT TOP 1 @firstInvoice=INVHED_INVNO FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' ORDER BY INVHED_TIME
	SELECT TOP 1 @lastInvoice=INVHED_INVNO FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV' ORDER BY INVHED_TIME DESC

	-- get net total
	SELECT @netTotal=ISNULL(SUM(INVHED_NETAMT),0) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED= 0AND INVHED_MODE='INV'

	--get hold bill total
	SELECT @holdBillTotal=ISNULL(SUM(INVHED_NETAMT) ,0) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=0 AND INVHED_CANCELED=0 AND INVHED_MODE='INV'

	-- refund total

	SELECT @refundTotal=SUM(ISNULL(INVDET_UNITQTY,0)* ISNULL(INVDET_SELLING,0)) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND
	CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVDET_UNITQTY<0 AND INVHED_MODE='INV'

	-- discount calculation
	SELECT @discAmtTotal=SUM(INVDET_DISCAMT) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND
	CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV'

	SELECT @discPerTotal=SUM(INVDET_DISCPER * INVDET_UNITQTY * INVDET_SELLING / 100) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND
	CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='INV'

	SELECT @billDiscTotal=SUM(INVDET_BILLDISCPER * INVDET_UNITQTY * INVDET_SELLING / 100) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND
	CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVDET_NODISC=0 AND INVHED_MODE='INV'

	SET @discountTotal = ISNULL(@billDiscTotal,0)+ISNULL(@discPerTotal,0)+ISNULL(@discAmtTotal,0)

	-- get cash in 
	SELECT @cashIn=ISNULL(SUM(INVHED_NETAMT) ,0) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='REC'
	
	-- get cash out
	SELECT @cashOut=ISNULL(SUM(INVHED_NETAMT) ,0) FROM T_TBLINVHEADER WHERE  CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVHED_MODE='WIT'


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
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVPAY_PHCODE='CSH' AND INVHED_MODE = 'INV' AND INVPAY_SHITNO = @shiftNo
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
	WHERE CONVERT(DATE,INVHED_DATETIME) = CONVERT(DATE,@signOndate) AND INVPAY_PDCODE !='CSH' AND
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVPAY_SHITNO = @shiftNo AND INVHED_MODE = 'INV' ) P
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



------------------------------------

GO

/****** Object:  StoredProcedure [dbo].[myPOS_DP_EOD_PROCESS]    Script Date: 4/8/2024 7:12:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[myPOS_DP_EOD_PROCESS]
	@date datetime = null,
	@location nvarchar(10)
AS
BEGIN
    SET NOCOUNT ON;
	
	DECLARE @error varchar(max);
	DECLARE @setupLoc varchar(max);
	DECLARE @lastDateOftheMonth date;

	--SELECT @setupLoc=SETUP_LOCATION FROM U_TBLSETUP
	set @setupLoc=@location
	IF @date = null
	BEGIN
		SET @date = GETDATE();
	END

	--CANCELL PENDING INVOICES
	BEGIN TRAN T1
	UPDATE T_TBLINVHEADER Set INVHED_CANCELED = 1 FROM T_TBLINVHEADER LEFT OUTER JOIN T_TBLINVPAYMENTS ON 
	T_TBLINVHEADER.INVHED_LOCCODE = T_TBLINVPAYMENTS.INVPAY_LOCCODE AND T_TBLINVHEADER.INVHED_INVNO = T_TBLINVPAYMENTS.INVPAY_INVNO And T_TBLINVHEADER.INVHED_MODE = T_TBLINVPAYMENTS.INVPAY_MODE 
	WHERE  INVHED_NETAMT <> 0 AND INVHED_INVOICED =1 AND (NOT EXISTS (SELECT INVPAY_INVNO, INVPAY_LOCCODE, INVPAY_MODE FROM T_TBLINVPAYMENTS AS T_TBLINVPAYMENTS_1 WHERE
	 (T_TBLINVHEADER.INVHED_INVNO = INVPAY_INVNO) AND (T_TBLINVHEADER.INVHED_LOCCODE = INVPAY_LOCCODE) AND  (T_TBLINVHEADER.INVHED_MODE = INVPAY_MODE))) AND CONVERT(DATE,INVHED_DATETIME) = CONVERT(DATE,@date)
	AND INVHED_LOCCODE=@setupLoc

	INSERT INTO T_TBLINVLINEREMARKS (INVREM_LOCCODE, INVREM_INVNO, INVREM_LINENO, INVREM_LINEREMARKS)  SELECT INVHED_LOCCODE, INVHED_INVNO,  0,'** CANCELLED BY EOD **' 
	FROM T_TBLINVHEADER where INVHED_LOCCODE=@setupLoc AND INVHED_CANCELED = 0 AND INVHED_INVOICED = 0 AND INVHED_MODE ='INV' AND CONVERT(DATE,INVHED_DATETIME) = CONVERT(DATE,@date)
	
	UPDATE T_TBLINVHEADER SET INVHED_ORDNUMBER = INVHED_INVNO, INVHED_CANCELED = 1, INVHED_INVOICED = 1, INVHED_CANUSER = 'EOD', 
	INVHED_CANDATE = INVHED_TXNDATE, INVHED_CANTIME = INVHED_TIME,   INVHED_ORDDATE = INVHED_TXNDATE , INVHED_ORDTIME = INVHED_TIME, INVHED_ORDENDDATE = INVHED_TXNDATE,
	INVHED_ORDENDTIME = INVHED_TIME, INVHED_ORDSTATION = INVHED_STATION, INVHED_ORDCASHIER = INVHED_CASHIER, DTPROCESS = 0 , DTSPROCESS = 1 
	where INVHED_LOCCODE=@setupLoc AND INVHED_CANCELED = 0 AND INVHED_INVOICED = 0 AND INVHED_MODE ='INV' AND CONVERT(DATE,INVHED_DATETIME) = CONVERT(DATE,@date)

	-- EOD PROCESS
	UPDATE U_TBLUSERHEAD SET UH_SHIFTNO=0; 
	UPDATE U_TBLSETUP SET SETUP_ENDDATE = @date, SETUP_ENDTIME = @date;
	UPDATE U_TBLLAST_EOD SET EOD_DATE = @date WHERE EOD_LOC=@setupLoc;
	

	--- EOD SIH Update
	---EXEC spReorganizeStock @location, 'EOD'

	INSERT INTO [dbo].[U_TBLEOD_SIH]
           ([DS_EOD]
           ,[DS_PLUCODE]
		   ,[DS_STOCKCODE]
           ,[DS_LOCCODE]
           ,[DS_SIH]
		   ,[DS_COST]
		   ,[DS_SELL]
		   ,[DS_AVGCOST])
    SELECT CAST(GETDATE() AS DATE), IPLU_CODE, IPLU_PRODUCTCODE, @location, ISNULL(SUM(IPLU_SIH),0), IPLU_COST, IPLU_SELL, IPLU_AVGCOST
    FROM M_TBLPROINVENTORY WHERE IPLU_LOCCODE = @location AND IPLU_SIH != 0  
	GROUP BY IPLU_CODE, IPLU_PRODUCTCODE,IPLU_COST, IPLU_SELL, IPLU_AVGCOST

	--- UPDATE  Current Month Out of Stock days (OSD)
	UPDATE bp SET bp.CM_OSD = bp.CM_OSD + 1 FROM U_TBLBRANCH_ITEM_PARA bp INNER JOIN M_TBLPROINVENTORY pr ON bp.PLU_CODE = pr.IPLU_CODE AND bp.LOC_CODE = pr.IPLU_LOCCODE
	WHERE bp.LOC_CODE = @location AND pr.IPLU_SIH <= 0 


	SELECT @lastDateOftheMonth = CAST(DATEADD(MM,DATEDIFF(MM, -1, GETDATE()),-1) AS DATE)

	IF (CAST(GETDATE() AS DATE) = @lastDateOftheMonth) --- When last date of the month (Month end)
	BEGIN
			UPDATE bp SET bp.LM_OSD = bp.CM_OSD FROM U_TBLBRANCH_ITEM_PARA bp INNER JOIN M_TBLPROINVENTORY pr ON bp.PLU_CODE = pr.IPLU_CODE AND bp.LOC_CODE = pr.IPLU_LOCCODE
			WHERE bp.LOC_CODE = @location AND pr.IPLU_SIH <= 0 

			UPDATE U_TBLBRANCH_ITEM_PARA SET CM_OSD = 0
	END

	COMMIT  TRAN T1
	SELECT @error as error

END
GO

--------------------------------------------

