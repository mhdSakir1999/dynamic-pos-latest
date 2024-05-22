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

	SELECT @refundTotal=SUM(ISNULL(INVDET_UNITQTY,0)* ISNULL(INVDET_SELLING,0)) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND
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


-------------------------------------------------------------------

ALTER PROCEDURE [dbo].[myPOS_DP_GET_HOLD_INV_DETAILS]
    @invoiceNo varchar(max)
AS
BEGIN

            SELECT DISTINCT
            i.INVDET_INVNO INVOICE_NO
            ,CONVERT(varchar,i.INVDET_DATETIME,126) AS DATE_TIME
            ,'' TEMP_KEY
            ,i.INVDET_SETUPLOC SETUP_LOCATION
            ,i.INVDET_LINENO LINE_NO
            ,i.INVDET_SALESMAN SALEMAN
            ,i.INVDET_VOID ITEM_VOID
            ,i.INVDET_PROCODE PRO_CODE
            ,i.INVDET_STOCKCODE STOCK_CODE
            ,i.INVDET_PRODESC POS_DESC
            ,u.UM_CODE PRO_UNIT
            ,i.INVDET_PROCASESIZE PRO_CASE_SIZE
            ,i.INVDET_PROCOST PRO_COST
            ,i.INVDET_PROSELLING PRO_SELLING
            ,i.INVDET_PROAVGCOST PRO_AVG_COST
            ,i.INVDET_SELLING SELLING
            ,i.INVDET_DISCPER DISC_PRE
            ,i.INVDET_DISCAMT DISC_AMT
            ,i.INVDET_BILLDISCPER BILL_DISC_PRE
            ,i.INVDET_BILLDISCAMT BILL_DISC_AMT
            ,i.INVDET_CASEQTY CASE_QTY
            ,i.INVDET_UNITQTY UNIT_QTY
            ,i.INVDET_CASERETQTY CASE_FREE_QTY
            ,i.INVDET_UNITRETQTY UNIT_FREE_QTY
            ,i.INVDET_AMOUNT AMOUNT
            ,i.INVDET_FREEQTY FREE_QTY
            ,i.INVDET_NODISC NO_DISC
            ,i.INVDET_SCANBARCODE SCAN_BARCODE
            ,i.INVDET_DISTYPE INVDET_DISTYPE
            ,i.INVDET_ISVOUCHER IS_VOUCHER
            ,p.PLU_MAXDISCPER MAXDISC_PER
            ,p.PLU_MAXDISCAMT MAXDISC_AMT
            ,'' LINE_REMARK
            ,I.INVDET_PRICEMODE PRICE_MODE
            ,i.INVDET_PROMODISCPER PROMO_DISCPER
            ,i.INVDET_PROMODISCAMT PROMO_DISCAMT
            ,i.INVDET_PROMOBILLDISCPER PROMO_BILLDISCPER
            ,i.INVDET_PROMOCODE PROMO_CODE
            FROM T_TBLINVDETAILS_HOLD i
            INNER JOIN T_TBLINVHEADER_HOLD h
            ON INVDET_LOCCODE=INVHED_LOCCODE AND INVDET_INVNO=INVHED_INVNO AND INVDET_MODE=INVHED_MODE
            LEFT JOIN M_TBLPROMASTER p
            ON i.INVDET_PROCODE= p.PLU_CODE
            LEFT JOIN M_TBLUNITS u
            ON u.UM_DESC=i.INVDET_PROUNIT
            where i.INVDET_INVNO=@invoiceNo AND h.INVHED_MODE='INV' AND h.INVHED_CANCELED=0 ORDER BY i.INVDET_LINENO
END
GO

----------------------------------------------------------
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
	UPDATE U_TBLUSERHEAD SET UH_SHIFTNO=0 where UH_SIGNLOC=@setupLoc; 
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


-------------------------------------------------------------------------

create PROCEDURE [dbo].[myPOS_DP_REPRINT_MNGSIGNOFF]
	@cashier varchar(50),
	@shiftNo varchar(4),
	@signOndate varchar(50),
	@terminalId varchar(50),
	@setUpLocation varchar(50)
AS
BEGIN
	DECLARE @error varchar(max)

	BEGIN TRY
	BEGIN TRAN






	
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

	SELECT @refundTotal=SUM(ISNULL(INVDET_UNITQTY,0)* ISNULL(INVDET_SELLING,0)) FROM T_TBLINVDETAILS,T_TBLINVHEADER WHERE INVHED_INVNO=INVDET_INVNO AND
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

	
	--calculated cash
	DECLARE @cashCalculated numeric(18,2)

	SELECT @cashSales=ISNULL(SUM(INVPAY_PAIDAMOUNT),0) FROM T_TBLINVPAYMENTS,T_TBLINVHEADER WHERE INVHED_INVNO=INVPAY_INVNO AND CONVERT(DATE,INVHED_SIGNONDATE) = CONVERT(DATE,@signOndate) AND 
	INVHED_CASHIER = @cashier AND INVHED_INVOICED=1 AND INVHED_CANCELED=0 AND INVPAY_PHCODE='CSH' AND INVHED_MODE = 'INV'  AND INVHED_SHITNO=@shiftNo AND INVHED_STATION=@terminalId
	SET @cashCalculated =  + @cashSales + @cashIn - @cashOut

	
	
	
	SELECT * FROM U_TBLSIGNOFFHEADER where SOH_LOCATION=@setUpLocation and SOH_DATE=@signOndate and SOH_USER=@cashier and SOH_STATION=@terminalId and SOH_SHIFT=@shiftNo
	SELECT U_TBLSIGNOFFDETAIL.*,PH_DESC FROM U_TBLSIGNOFFDETAIL, M_TBLPAYMODEHEAD where SOD_PAYCODE=PH_CODE and SOD_LOCATION=@setUpLocation and SOD_DATE=@signOndate and SOD_USER=@cashier and SOD_STATION=@terminalId and SOD_SHIFT=@shiftNo
	--select * from U_TBLSIGNOFFDENOMINATIONDET where DE_LOCATION=@setUpLocation and DE_DATE=@signOndate and DE_USER=@cashier and DE_STATION=@terminalId and DE_SHIFT=@shiftNo
	select h.*, d.DEN_DENVALUE from  (select * from U_TBLSIGNOFFDENOMINATIONDET where DE_LOCATION='00009' and DE_DATE='19/May/2024' and DE_USER='4697' and DE_STATION='003' and DE_SHIFT='2') h 
	inner join M_TBLPAYDENOMINATIONS d on h.de_dencode = d. den_code

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
-------------------------------------------

CREATE PROCEDURE [dbo].[myPOS_DP_GET_RETURN_BOTTLE_PRODUCTS] 
	@loc varchar(40)
as 
BEGIN 
DECLARE @pluCode varchar(max);
	DECLARE @posDesc varchar(max);
	DECLARE @stockCode varchar(max);
	DECLARE @noDisc bit;
	DECLARE @active bit;
	DECLARE @minus bit;
	DECLARE @pluOpen bit=0;
	DECLARE @pluDecimal bit=0;
	DECLARE @sih numeric;
	DECLARE @selling numeric(18,2);
	DECLARE @temp int;
	DECLARE @caseSize numeric;
	DECLARE @maxDisc numeric;
	DECLARE @maxDiscAmt numeric;
	DECLARE @cost numeric;
	DECLARE @avgCost numeric;
	DECLARE @pluUnit varchar(50);
	DECLARE @department varchar(50);
	DECLARE @subDepartment varchar(50);
	DECLARE @pluLen int;
	DECLARE @typeLen int; -- typed pro code length
	DECLARE @picture varchar(max);
	DECLARE @imageHash varchar(max);
	DECLARE @pluPrefix varchar(max);
	DECLARE @pluCharLen int;
	DECLARE @createdPluCode varchar(max);
	DECLARE @maxQty numeric(18,2)
	DECLARE @maxQtyGrp varchar(50);
	DECLARE @maxQtyGrpLvl varchar(50);
	DECLARE @volume numeric(18,2);
	DECLARE @status varchar(15) = NULL;
	DECLARE @inventorySearched bit=0;
	DECLARE @proMasterSearched bit=1;
	DECLARE @searchCode varchar(max);
	DECLARE @hasSpecialPrice bit = 0;
	DECLARE @specialPrice numeric(18,2)= 0;
	DECLARE @exchangable bit = 1;
	DECLARE @vendorPlu varchar(15);
	DECLARE @posactive bit =0;
	declare @emptyBtCode varchar(20);
	declare @variantEnable bit=0;
	DECLARE @motherCode varchar(max);
	declare @batchEnable bit=0;
	declare @CompanyVariantEnable bit=0;
	declare @ActMotherCode varchar(max);
	declare @isEmptyCode int;

 SELECT @pluCode=PLU_CODE,@posDesc = PLU_POSDESC,@active= PLU_ACTIVE,@noDisc=PLU_NODISC,@caseSize=PLU_CS,@pluUnit=PLU_UNIT,@pluOpen = PLU_OPEN,@picture=PLU_PICTURE ,
 @imageHash=PLU_PICTURE_HASH,@maxDisc=PLU_MAXDISCPER,@maxDiscAmt=PLU_MAXDISCAMT,@pluDecimal = PLU_DECIMAL,@minus=PLU_MINUSALLOW,@maxQty = PLU_ALLOWQTY,@exchangable=PLU_EXCHANGABLE,
 @vendorPlu=PLU_VENDORPLU,@posactive =PLU_POSACTIVE, @emptyBtCode=PLU_RETURN,@variantEnable=PLU_VARIANTANABLE,@motherCode=PLU_STOCKCODE,@batchEnable=PLU_BATCHENABLE, 
 @isEmptyCode=PLU_EMPTY
    FROM M_TBLPROMASTER p 
    WHERE (plu_empty = 1  AND PLU_RAWITEM=0 AND PLU_ACTIVE=1)


IF @status IS NULL
    BEGIN
        IF @proMasterSearched = 0
        BEGIN
            SELECT @pluCode=PLU_CODE,@active= PLU_ACTIVE,@noDisc=PLU_NODISC,@caseSize=PLU_CS,@pluUnit=PLU_UNIT,@pluOpen = PLU_OPEN,@picture=PLU_PICTURE ,@imageHash=PLU_PICTURE_HASH,@maxDisc=PLU_MAXDISCPER,@maxDiscAmt=PLU_MAXDISCAMT,@pluDecimal = PLU_DECIMAL,@minus=PLU_MINUSALLOW,@maxQty = PLU_ALLOWQTY,@exchangable=PLU_EXCHANGABLE,@vendorPlu=PLU_VENDORPLU,@posactive =PLU_POSACTIVE , @emptyBtCode=PLU_RETURN,@motherCode=PLU_STOCKCODE,@batchEnable=PLU_BATCHENABLE,@variantEnable=PLU_VARIANTANABLE, @isEmptyCode=PLU_EMPTY
            FROM M_TBLPROMASTER p 
            WHERE PLU_CODE = @pluCode
        END

		if @CompanyVariantEnable=1
		begin
			set @ActMotherCode = @motherCode+'0000'
		end
		else
		begin
			set @ActMotherCode = @motherCode
		end

        -- SELECT PRODUCT VOLUME AND GROUP
		SELECT @volume=UM_VOLUME FROM M_TBLUNITS u WHERE u.UM_CODE = @pluUnit
		SELECT @maxQty=a.VL_TOTALCAPACITY,@maxQtyGrp=a.VL_GROUPCODE,@maxQtyGrpLvl=a.VL_GROUPLEVEL FROM U_TBLMAXALLOWED a WHERE a.VL_GROUPCODE = (select GPLU_GROUPCODE3 from M_TBLPROGROUPS where GPLU_CODE=@pluCode) --and a.VL_UOM= @pluUnit

		-- fetech inventory details
        IF @inventorySearched = 0 
        BEGIN
            SELECT  @selling=IPLU_SELL,@sih = IPLU_SIH,@plucode = IPLU_CODE,@avgCost = IPLU_AVGCOST,
            @stockCode=IPLU_PRODUCTCODE,
			@cost=IPLU_COST,@posDesc = IPLU_DESC,@specialPrice = IPLU_SPECIALPRICE, @posactive=CAST(IPLU_ACTIVE AS BIT)
            FROM M_TBLPROINVENTORY WHERE IPLU_CODE=@pluCode
            AND IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1 

			IF @hasSpecialPrice = 1 
			BEGIN
				SET @selling = @specialPrice
			END

			SELECT @stockCode SCAN_CODE,@pluCode as PLU_CODE,@posDesc  as  PLU_POSDESC,case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE,@active as  PLU_ACTIVE,@noDisc as PLU_NODISC,@selling as SELLING_PRICE, @sih as SIH,
			@caseSize as CASE_SIZE,@cost as PLU_COST, @avgCost as PLU_AVGCOST,@pluUnit as PLU_UNIT,@department PLU_DEPARTMENT,@subDepartment PLU_SUB_DEPARTMENT,@picture IMAGE_PATH,@pluDecimal as PLU_DECIMAL,@status as status,@pluOpen as PLU_OPEN,@imageHash PLU_PICTURE_HASH,@maxDisc PLU_MAXDISCPER,@maxDiscAmt PLU_MAXDISCAMT,@minus PLU_MINUSALLOW,@maxQty PLU_MAXVOLUME,@maxQtyGrp PLU_MAXVOLUME_GRP,@maxQtyGrpLvl PLU_MAXVOLUME_GRPLV,@volume PLU_VOLUME,@exchangable PLU_EXCHANGABLE,@vendorPlu PLU_VENDORPLU,@posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN,@variantEnable PLU_VARIANTANABLE,@batchEnable PLU_BATCHENABLE, isnull(@isEmptyCode,0) PLU_EMPTY
        END

		IF @inventorySearched = 1
		BEGIN
			IF @hasSpecialPrice = 1 
			BEGIN
				SET @selling = @specialPrice
			END

			SELECT @stockCode SCAN_CODE,@pluCode as PLU_CODE,@posDesc  as  PLU_POSDESC,case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE,@active as  PLU_ACTIVE,@noDisc as PLU_NODISC,@selling as SELLING_PRICE, @sih as SIH,
			@caseSize as CASE_SIZE,@cost as PLU_COST, @avgCost as PLU_AVGCOST,@pluUnit as PLU_UNIT,@department PLU_DEPARTMENT,@subDepartment PLU_SUB_DEPARTMENT,@picture IMAGE_PATH,@pluDecimal as PLU_DECIMAL,@status as status,@pluOpen as PLU_OPEN,@imageHash PLU_PICTURE_HASH,@maxDisc PLU_MAXDISCPER,@maxDiscAmt PLU_MAXDISCAMT,@minus PLU_MINUSALLOW,@maxQty PLU_MAXVOLUME,@maxQtyGrp PLU_MAXVOLUME_GRP,@maxQtyGrpLvl PLU_MAXVOLUME_GRPLV,@volume PLU_VOLUME,@exchangable PLU_EXCHANGABLE,@vendorPlu PLU_VENDORPLU,@posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN,@variantEnable PLU_VARIANTANABLE,@batchEnable PLU_BATCHENABLE , isnull(@isEmptyCode,0) PLU_EMPTY
		END
		ELSE 
		BEGIN
			/*
			SELECT @stockCode SCAN_CODE,@pluCode as PLU_CODE,IPLU_DESC  as  PLU_POSDESC,IPLU_PRODUCTCODE as PLU_STOCKCODE,@active as  PLU_ACTIVE,@noDisc as PLU_NODISC, 
			CASE WHEN @hasSpecialPrice = 1 THEN @specialPrice ELSE IPLU_SELL END SELLING_PRICE,IPLU_SIH AS SIH,@caseSize as CASE_SIZE,IPLU_COST AS PLU_COST,IPLU_AVGCOST AS PLU_AVGCOST,@pluUnit as PLU_UNIT,
            @department PLU_DEPARTMENT,@subDepartment PLU_SUB_DEPARTMENT,@picture IMAGE_PATH,@pluDecimal as PLU_DECIMAL,@status as status,@pluOpen as PLU_OPEN,@imageHash PLU_PICTURE_HASH,
			@maxDisc PLU_MAXDISCPER,@maxDiscAmt PLU_MAXDISCAMT,@minus PLU_MINUSALLOW,@maxQty PLU_MAXVOLUME,@maxQtyGrp PLU_MAXVOLUME_GRP,@maxQtyGrpLvl PLU_MAXVOLUME_GRPLV,@volume PLU_VOLUME,
			@exchangable PLU_EXCHANGABLE,@vendorPlu PLU_VENDORPLU,@posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN
            FROM M_TBLPROINVENTORY WHERE IPLU_CODE=@pluCode
            AND IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1 
			*/
			SELECT  @selling=IPLU_SELL,@sih = IPLU_SIH,@plucode = IPLU_CODE,@avgCost = IPLU_AVGCOST,
            @stockCode=IPLU_PRODUCTCODE,
			@cost=IPLU_COST,@posDesc = IPLU_DESC,@specialPrice = IPLU_SPECIALPRICE, @posactive=CAST(IPLU_ACTIVE AS BIT)
            FROM M_TBLPROINVENTORY WHERE IPLU_CODE=@pluCode
            AND IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1 
			
			print('inventory')
		END

    END

	ELSE
	BEGIN
		if @CompanyVariantEnable=1
		begin
			set @ActMotherCode = @motherCode+'0000'
		end
		else
		begin
			set @ActMotherCode = @motherCode
		end

		IF @hasSpecialPrice = 1 
		BEGIN
			SET @selling = @specialPrice
		END
		SELECT @stockCode SCAN_CODE,@pluCode as PLU_CODE,@posDesc  as  PLU_POSDESC,case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE,@active as  PLU_ACTIVE,@noDisc as PLU_NODISC,@selling as SELLING_PRICE, @sih as SIH,@caseSize as CASE_SIZE,@cost as PLU_COST, @avgCost as PLU_AVGCOST,@pluUnit as PLU_UNIT,@department PLU_DEPARTMENT,@subDepartment PLU_SUB_DEPARTMENT,@picture IMAGE_PATH,@pluDecimal as PLU_DECIMAL,@status as status,@pluOpen as PLU_OPEN,@imageHash PLU_PICTURE_HASH,@maxDisc PLU_MAXDISCPER,@maxDiscAmt PLU_MAXDISCAMT,@minus PLU_MINUSALLOW,@maxQty PLU_MAXVOLUME,@maxQtyGrp PLU_MAXVOLUME_GRP,@maxQtyGrpLvl PLU_MAXVOLUME_GRPLV,@volume PLU_VOLUME,@exchangable PLU_EXCHANGABLE,@vendorPlu PLU_VENDORPLU,@posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN,@variantEnable PLU_VARIANTANABLE,@batchEnable PLU_BATCHENABLE, isnull(@isEmptyCode,0) PLU_EMPTY
	END

 --SELECT @stockCode SCAN_CODE,@pluCode as PLU_CODE,@posDesc  as  PLU_POSDESC,case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE,
 --@active as  PLU_ACTIVE,@noDisc as PLU_NODISC,@selling as SELLING_PRICE, @sih as SIH,@caseSize as CASE_SIZE,@cost as PLU_COST, @avgCost as PLU_AVGCOST,@pluUnit as PLU_UNIT,
 --@department PLU_DEPARTMENT,@subDepartment PLU_SUB_DEPARTMENT,@picture IMAGE_PATH,@pluDecimal as PLU_DECIMAL,@status as status,@pluOpen as PLU_OPEN,@imageHash PLU_PICTURE_HASH,
 --@maxDisc PLU_MAXDISCPER,@maxDiscAmt PLU_MAXDISCAMT,@minus PLU_MINUSALLOW,@maxQty PLU_MAXVOLUME,@maxQtyGrp PLU_MAXVOLUME_GRP,@maxQtyGrpLvl PLU_MAXVOLUME_GRPLV,@volume PLU_VOLUME,
 --@exchangable PLU_EXCHANGABLE,@vendorPlu PLU_VENDORPLU,@posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN,@variantEnable PLU_VARIANTANABLE,@batchEnable PLU_BATCHENABLE, 
 --isnull(@isEmptyCode,0) PLU_EMPTY
--if @@ROWCOUNT = 0
--begin
--SELECT  @selling=IPLU_SELL,@sih = IPLU_SIH,@plucode = IPLU_CODE,@avgCost = IPLU_AVGCOST,
--                @stockCode=IPLU_PRODUCTCODE,@cost=IPLU_COST ,@posDesc = IPLU_DESC,@specialPrice = IPLU_SPECIALPRICE, @posactive=IPLU_ACTIVE
--                FROM M_TBLPROINVENTORY inner join M_TBLPROMASTER on IPLU_CODE = PLU_CODE  WHERE 
--                 IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1 and PLU_EMPTY = 1
--end
END
GO
----------------------------------------------------------

ALTER PROCEDURE [dbo].[myPOS_DP_GET_RETURN_BOTTLE_PRODUCTS] 
	@loc varchar(40)
as 
BEGIN 
DECLARE @pluCode varchar(max);
	DECLARE @posDesc varchar(max);
	DECLARE @stockCode varchar(max);
	DECLARE @noDisc bit;
	DECLARE @active bit;
	DECLARE @minus bit;
	DECLARE @pluOpen bit=0;
	DECLARE @pluDecimal bit=0;
	DECLARE @sih numeric;
	DECLARE @selling numeric(18,2);
	DECLARE @temp int;
	DECLARE @caseSize numeric;
	DECLARE @maxDisc numeric;
	DECLARE @maxDiscAmt numeric;
	DECLARE @cost numeric;
	DECLARE @avgCost numeric;
	DECLARE @pluUnit varchar(50);
	DECLARE @department varchar(50);
	DECLARE @subDepartment varchar(50);
	DECLARE @pluLen int;
	DECLARE @typeLen int; -- typed pro code length
	DECLARE @picture varchar(max);
	DECLARE @imageHash varchar(max);
	DECLARE @pluPrefix varchar(max);
	DECLARE @pluCharLen int;
	DECLARE @createdPluCode varchar(max);
	DECLARE @maxQty numeric(18,2)
	DECLARE @maxQtyGrp varchar(50);
	DECLARE @maxQtyGrpLvl varchar(50);
	DECLARE @volume numeric(18,2);
	DECLARE @status varchar(15) = NULL;
	DECLARE @inventorySearched bit=0;
	DECLARE @proMasterSearched bit=1;
	DECLARE @searchCode varchar(max);
	DECLARE @hasSpecialPrice bit = 0;
	DECLARE @specialPrice numeric(18,2)= 0;
	DECLARE @exchangable bit = 1;
	DECLARE @vendorPlu varchar(15);
	DECLARE @posactive bit =0;
	declare @emptyBtCode varchar(20);
	declare @variantEnable bit=0;
	DECLARE @motherCode varchar(max);
	declare @batchEnable bit=0;
	declare @CompanyVariantEnable bit=0;
	declare @ActMotherCode varchar(max);
	declare @isEmptyCode int;


	--SELECT IPLU_PRODUCTCODE SCAN_CODE,PLU_CODE,IPLU_DESC  as  PLU_POSDESC,IPLU_PRODUCTCODE as PLU_STOCKCODE,IPLU_ACTIVE as  PLU_ACTIVE,PLU_NODISC as PLU_NODISC, 
	--		IPLU_SELL SELLING_PRICE,IPLU_SIH AS SIH,PLU_CS as CASE_SIZE,IPLU_COST AS PLU_COST,IPLU_AVGCOST AS PLU_AVGCOST,PLU_UNIT as PLU_UNIT,
 --           '' PLU_DEPARTMENT,'' PLU_SUB_DEPARTMENT,PLU_PICTURE IMAGE_PATH,PLU_DECIMAL as PLU_DECIMAL,'' as status,PLU_OPEN as PLU_OPEN,PLU_PICTURE_HASH PLU_PICTURE_HASH,
	--		PLU_MAXDISCPER,PLU_MAXDISCAMT,PLU_MINUSALLOW,0 AS PLU_MAXVOLUME,0 AS PLU_MAXVOLUME_GRP,'' AS PLU_MAXVOLUME_GRPLV,0 AS PLU_VOLUME,
	--		PLU_EXCHANGABLE,PLU_VENDORPLU,cast(IPLU_ACTIVE as bit) AS PLU_POSACTIVE, PLU_RETURN,cast(0 as bit) PLU_VARIANTANABLE,cast(0 as bit) PLU_BATCHENABLE,isnull(PLU_EMPTY,0) PLU_EMPTY
 --           FROM M_TBLPROMASTER INNER JOIN M_TBLPROINVENTORY ON PLU_CODE=IPLU_CODE WHERE IPLU_LOCCODE=@loc
 --           AND IPLU_ACTIVE=1 AND PLU_EMPTY=1
	SELECT IPLU_PRODUCTCODE SCAN_CODE,PLU_CODE,IPLU_DESC  as  PLU_POSDESC,IPLU_PRODUCTCODE as PLU_STOCKCODE, cast(IPLU_ACTIVE as bit) as  PLU_ACTIVE,cast(PLU_NODISC as bit) as PLU_NODISC, 
			IPLU_SELL SELLING_PRICE,IPLU_SIH AS SIH,PLU_CS as CASE_SIZE,IPLU_COST AS PLU_COST,IPLU_AVGCOST AS PLU_AVGCOST,PLU_UNIT as PLU_UNIT,
            '' PLU_DEPARTMENT,'' PLU_SUB_DEPARTMENT,PLU_PICTURE IMAGE_PATH,cast(PLU_DECIMAL as bit) as PLU_DECIMAL,'' as status,cast(PLU_OPEN as bit) as PLU_OPEN,PLU_PICTURE_HASH PLU_PICTURE_HASH,
			PLU_MAXDISCPER,PLU_MAXDISCAMT,PLU_MINUSALLOW,cast(0 as numeric) AS PLU_MAXVOLUME,'' AS PLU_MAXVOLUME_GRP,'' AS PLU_MAXVOLUME_GRPLV,cast(0 as numeric) AS PLU_VOLUME,
			PLU_EXCHANGABLE,PLU_VENDORPLU, PLU_POSACTIVE, PLU_RETURN, PLU_VARIANTANABLE, PLU_BATCHENABLE,isnull(PLU_EMPTY,0) PLU_EMPTY
            FROM M_TBLPROMASTER INNER JOIN M_TBLPROINVENTORY ON PLU_CODE=IPLU_CODE WHERE IPLU_LOCCODE=@loc
            AND IPLU_ACTIVE=1 AND PLU_EMPTY=1

/*
 SELECT @pluCode=PLU_CODE,@posDesc = PLU_POSDESC,@active= PLU_ACTIVE,@noDisc=PLU_NODISC,@caseSize=PLU_CS,@pluUnit=PLU_UNIT,@pluOpen = PLU_OPEN,@picture=PLU_PICTURE ,
 @imageHash=PLU_PICTURE_HASH,@maxDisc=PLU_MAXDISCPER,@maxDiscAmt=PLU_MAXDISCAMT,@pluDecimal = PLU_DECIMAL,@minus=PLU_MINUSALLOW,@maxQty = PLU_ALLOWQTY,@exchangable=PLU_EXCHANGABLE,
 @vendorPlu=PLU_VENDORPLU,@posactive =PLU_POSACTIVE, @emptyBtCode=PLU_RETURN,@variantEnable=PLU_VARIANTANABLE,@motherCode=PLU_STOCKCODE,@batchEnable=PLU_BATCHENABLE, 
 @isEmptyCode=PLU_EMPTY
    FROM M_TBLPROMASTER p 
    WHERE (plu_empty = 1  AND PLU_RAWITEM=0 AND PLU_ACTIVE=1)


IF @status IS NULL
    BEGIN
        IF @proMasterSearched = 0
        BEGIN
            SELECT @pluCode=PLU_CODE,@active= PLU_ACTIVE,@noDisc=PLU_NODISC,@caseSize=PLU_CS,@pluUnit=PLU_UNIT,@pluOpen = PLU_OPEN,@picture=PLU_PICTURE ,@imageHash=PLU_PICTURE_HASH,@maxDisc=PLU_MAXDISCPER,@maxDiscAmt=PLU_MAXDISCAMT,@pluDecimal = PLU_DECIMAL,@minus=PLU_MINUSALLOW,@maxQty = PLU_ALLOWQTY,@exchangable=PLU_EXCHANGABLE,@vendorPlu=PLU_VENDORPLU,@posactive =PLU_POSACTIVE , @emptyBtCode=PLU_RETURN,@motherCode=PLU_STOCKCODE,@batchEnable=PLU_BATCHENABLE,@variantEnable=PLU_VARIANTANABLE, @isEmptyCode=PLU_EMPTY
            FROM M_TBLPROMASTER p 
            WHERE PLU_CODE = @pluCode
        END

		if @CompanyVariantEnable=1
		begin
			set @ActMotherCode = @motherCode+'0000'
		end
		else
		begin
			set @ActMotherCode = @motherCode
		end

        -- SELECT PRODUCT VOLUME AND GROUP
		SELECT @volume=UM_VOLUME FROM M_TBLUNITS u WHERE u.UM_CODE = @pluUnit
		SELECT @maxQty=a.VL_TOTALCAPACITY,@maxQtyGrp=a.VL_GROUPCODE,@maxQtyGrpLvl=a.VL_GROUPLEVEL FROM U_TBLMAXALLOWED a WHERE a.VL_GROUPCODE = (select GPLU_GROUPCODE3 from M_TBLPROGROUPS where GPLU_CODE=@pluCode) --and a.VL_UOM= @pluUnit

		-- fetech inventory details
        IF @inventorySearched = 0 
        BEGIN
			print('----------')
            SELECT  @selling=IPLU_SELL,@sih = IPLU_SIH,@plucode = IPLU_CODE,@avgCost = IPLU_AVGCOST,
            @stockCode=IPLU_PRODUCTCODE,
			@cost=IPLU_COST,@posDesc = IPLU_DESC,@specialPrice = IPLU_SPECIALPRICE, @posactive=CAST(IPLU_ACTIVE AS BIT)
            FROM M_TBLPROINVENTORY WHERE IPLU_CODE=@pluCode
            AND IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1 
			print('----------')
			IF @hasSpecialPrice = 1 
			BEGIN
				SET @selling = @specialPrice
			END

			SELECT @stockCode SCAN_CODE,@pluCode as PLU_CODE,@posDesc  as  PLU_POSDESC,case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE,@active as  PLU_ACTIVE,@noDisc as PLU_NODISC,@selling as SELLING_PRICE, @sih as SIH,
			@caseSize as CASE_SIZE,@cost as PLU_COST, @avgCost as PLU_AVGCOST,@pluUnit as PLU_UNIT,@department PLU_DEPARTMENT,@subDepartment PLU_SUB_DEPARTMENT,@picture IMAGE_PATH,@pluDecimal as PLU_DECIMAL,@status as status,@pluOpen as PLU_OPEN,@imageHash PLU_PICTURE_HASH,@maxDisc PLU_MAXDISCPER,@maxDiscAmt PLU_MAXDISCAMT,@minus PLU_MINUSALLOW,@maxQty PLU_MAXVOLUME,@maxQtyGrp PLU_MAXVOLUME_GRP,@maxQtyGrpLvl PLU_MAXVOLUME_GRPLV,@volume PLU_VOLUME,@exchangable PLU_EXCHANGABLE,@vendorPlu PLU_VENDORPLU,@posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN,@variantEnable PLU_VARIANTANABLE,@batchEnable PLU_BATCHENABLE, isnull(@isEmptyCode,0) PLU_EMPTY
        END

		IF @inventorySearched = 1
		BEGIN
			IF @hasSpecialPrice = 1 
			BEGIN
				SET @selling = @specialPrice
			END

			SELECT @stockCode SCAN_CODE,@pluCode as PLU_CODE,@posDesc  as  PLU_POSDESC,case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE,@active as  PLU_ACTIVE,@noDisc as PLU_NODISC,@selling as SELLING_PRICE, @sih as SIH,
			@caseSize as CASE_SIZE,@cost as PLU_COST, @avgCost as PLU_AVGCOST,@pluUnit as PLU_UNIT,@department PLU_DEPARTMENT,@subDepartment PLU_SUB_DEPARTMENT,@picture IMAGE_PATH,@pluDecimal as PLU_DECIMAL,@status as status,@pluOpen as PLU_OPEN,@imageHash PLU_PICTURE_HASH,@maxDisc PLU_MAXDISCPER,@maxDiscAmt PLU_MAXDISCAMT,@minus PLU_MINUSALLOW,@maxQty PLU_MAXVOLUME,@maxQtyGrp PLU_MAXVOLUME_GRP,@maxQtyGrpLvl PLU_MAXVOLUME_GRPLV,@volume PLU_VOLUME,@exchangable PLU_EXCHANGABLE,@vendorPlu PLU_VENDORPLU,@posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN,@variantEnable PLU_VARIANTANABLE,@batchEnable PLU_BATCHENABLE , isnull(@isEmptyCode,0) PLU_EMPTY
		END
		ELSE 
		BEGIN
			/*
			SELECT @stockCode SCAN_CODE,@pluCode as PLU_CODE,IPLU_DESC  as  PLU_POSDESC,IPLU_PRODUCTCODE as PLU_STOCKCODE,@active as  PLU_ACTIVE,@noDisc as PLU_NODISC, 
			CASE WHEN @hasSpecialPrice = 1 THEN @specialPrice ELSE IPLU_SELL END SELLING_PRICE,IPLU_SIH AS SIH,@caseSize as CASE_SIZE,IPLU_COST AS PLU_COST,IPLU_AVGCOST AS PLU_AVGCOST,@pluUnit as PLU_UNIT,
            @department PLU_DEPARTMENT,@subDepartment PLU_SUB_DEPARTMENT,@picture IMAGE_PATH,@pluDecimal as PLU_DECIMAL,@status as status,@pluOpen as PLU_OPEN,@imageHash PLU_PICTURE_HASH,
			@maxDisc PLU_MAXDISCPER,@maxDiscAmt PLU_MAXDISCAMT,@minus PLU_MINUSALLOW,@maxQty PLU_MAXVOLUME,@maxQtyGrp PLU_MAXVOLUME_GRP,@maxQtyGrpLvl PLU_MAXVOLUME_GRPLV,@volume PLU_VOLUME,
			@exchangable PLU_EXCHANGABLE,@vendorPlu PLU_VENDORPLU,@posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN
            FROM M_TBLPROINVENTORY WHERE IPLU_CODE=@pluCode
            AND IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1 
			*/
			SELECT  @selling=IPLU_SELL,@sih = IPLU_SIH,@plucode = IPLU_CODE,@avgCost = IPLU_AVGCOST,
            @stockCode=IPLU_PRODUCTCODE,
			@cost=IPLU_COST,@posDesc = IPLU_DESC,@specialPrice = IPLU_SPECIALPRICE, @posactive=CAST(IPLU_ACTIVE AS BIT)
            FROM M_TBLPROINVENTORY WHERE IPLU_CODE=@pluCode
            AND IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1 
			
			print('inventory')
		END

    END

	ELSE
	BEGIN
		if @CompanyVariantEnable=1
		begin
			set @ActMotherCode = @motherCode+'0000'
		end
		else
		begin
			set @ActMotherCode = @motherCode
		end

		IF @hasSpecialPrice = 1 
		BEGIN
			SET @selling = @specialPrice
		END
		SELECT @stockCode SCAN_CODE,@pluCode as PLU_CODE,@posDesc  as  PLU_POSDESC,case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE,@active as  PLU_ACTIVE,@noDisc as PLU_NODISC,@selling as SELLING_PRICE, @sih as SIH,@caseSize as CASE_SIZE,@cost as PLU_COST, @avgCost as PLU_AVGCOST,@pluUnit as PLU_UNIT,@department PLU_DEPARTMENT,@subDepartment PLU_SUB_DEPARTMENT,@picture IMAGE_PATH,@pluDecimal as PLU_DECIMAL,@status as status,@pluOpen as PLU_OPEN,@imageHash PLU_PICTURE_HASH,@maxDisc PLU_MAXDISCPER,@maxDiscAmt PLU_MAXDISCAMT,@minus PLU_MINUSALLOW,@maxQty PLU_MAXVOLUME,@maxQtyGrp PLU_MAXVOLUME_GRP,@maxQtyGrpLvl PLU_MAXVOLUME_GRPLV,@volume PLU_VOLUME,@exchangable PLU_EXCHANGABLE,@vendorPlu PLU_VENDORPLU,@posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN,@variantEnable PLU_VARIANTANABLE,@batchEnable PLU_BATCHENABLE, isnull(@isEmptyCode,0) PLU_EMPTY
	END

 --SELECT @stockCode SCAN_CODE,@pluCode as PLU_CODE,@posDesc  as  PLU_POSDESC,case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE,
 --@active as  PLU_ACTIVE,@noDisc as PLU_NODISC,@selling as SELLING_PRICE, @sih as SIH,@caseSize as CASE_SIZE,@cost as PLU_COST, @avgCost as PLU_AVGCOST,@pluUnit as PLU_UNIT,
 --@department PLU_DEPARTMENT,@subDepartment PLU_SUB_DEPARTMENT,@picture IMAGE_PATH,@pluDecimal as PLU_DECIMAL,@status as status,@pluOpen as PLU_OPEN,@imageHash PLU_PICTURE_HASH,
 --@maxDisc PLU_MAXDISCPER,@maxDiscAmt PLU_MAXDISCAMT,@minus PLU_MINUSALLOW,@maxQty PLU_MAXVOLUME,@maxQtyGrp PLU_MAXVOLUME_GRP,@maxQtyGrpLvl PLU_MAXVOLUME_GRPLV,@volume PLU_VOLUME,
 --@exchangable PLU_EXCHANGABLE,@vendorPlu PLU_VENDORPLU,@posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN,@variantEnable PLU_VARIANTANABLE,@batchEnable PLU_BATCHENABLE, 
 --isnull(@isEmptyCode,0) PLU_EMPTY
--if @@ROWCOUNT = 0
--begin
--SELECT  @selling=IPLU_SELL,@sih = IPLU_SIH,@plucode = IPLU_CODE,@avgCost = IPLU_AVGCOST,
--                @stockCode=IPLU_PRODUCTCODE,@cost=IPLU_COST ,@posDesc = IPLU_DESC,@specialPrice = IPLU_SPECIALPRICE, @posactive=IPLU_ACTIVE
--                FROM M_TBLPROINVENTORY inner join M_TBLPROMASTER on IPLU_CODE = PLU_CODE  WHERE 
--                 IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1 and PLU_EMPTY = 1
--end

*/
END
GO


-------------------------------------------------------------