/****** Author: TM.Sakir ******/
/****** Objective: Getting COD payment based invoices ******/

CREATE PROCEDURE [dbo].[myPOS_DP_GET_COD_INVOICES]
    @cashier varchar(max)
AS
BEGIN

    select d.*, isNull(r.invrem_remarks1 , '') REM1, isNull(r.invrem_remarks2 , '') REM2, isNull(r.invrem_remarks3 , '') REM3, isNull(r.invrem_remarks4 , '') REM4, isNull(r.invrem_remarks5 , '') REM5
    from
        (select INVHED_INVNO, convert(date, INVHED_TXNDATE) as INVHED_TXNDATE , INVPAY_PDCODE, INVPAY_PAIDAMOUNT, INVHED_CASHIER
        from t_tblinvheader, t_tblinvpayments
        where invhed_invno = invpay_invno and invpay_pdcode = 'cod' and INVHED_INVOICED = 1 and INVHED_CANCELED = 0 and INVHED_CASHIER = @cashier) d
        left outer join T_TBLINVREMARKS r on d.invhed_invno = r.invrem_invno

END
GO

-------------------------------------------------------------
ALTER PROCEDURE [dbo].[myPOS_DP_GET_COD_INVOICES]
    @cashier varchar(max)
AS
BEGIN

    select d.*, isNull(r.invrem_remarks1 , '') REM1, isNull(r.invrem_remarks2 , '') REM2, isNull(r.invrem_remarks3 , '') REM3, isNull(r.invrem_remarks4 , '') REM4, isNull(r.invrem_remarks5 , '') REM5
    from
        (select INVHED_INVNO, INVHED_TXNDATE , INVPAY_PDCODE, INVPAY_PAIDAMOUNT, INVHED_CASHIER
        from t_tblinvheader, t_tblinvpayments
        where invhed_invno = invpay_invno and invpay_pdcode = 'cod' and INVHED_INVOICED = 1 and INVHED_CANCELED = 0 and INVHED_CASHIER = @cashier and INVHED_MODE = 'INV') d
        left outer join T_TBLINVREMARKS r on d.invhed_invno = r.invrem_invno

END
GO

-------------------------------------------------------------
ALTER         PROCEDURE [dbo].[myPOS_DP_GET_TODAY_INVOICES]
    @cashier varchar(max)
AS
BEGIN


    --SELECT  top (5000) 
    --INVHED_INVNO,INVHED_CASHIER,INVHED_TIME,INVHED_MODE,INVHED_NETAMT,INVHED_DISPER,INVHED_GROAMT,
    --INVHED_INVOICED,INVHED_MEMBER,INVHED_PRICEMODE FROM T_TBLINVHEADER
    --WHERE  INVHED_CASHIER = @cashier AND INVHED_CANCELED=0  --romoved the date condition
    ---- ORDER BY INVHED_TIME desc
    --order by INVHED_DATETIME desc

    -- past 7 days filteration
    SELECT
        INVHED_INVNO, INVHED_CASHIER, INVHED_TIME, INVHED_MODE, INVHED_NETAMT, INVHED_DISPER, INVHED_GROAMT,
        INVHED_INVOICED, INVHED_MEMBER, INVHED_PRICEMODE
    FROM T_TBLINVHEADER
    WHERE  INVHED_CASHIER = @cashier AND INVHED_CANCELED=0 and INVHED_DATETIME >= DATEADD(DAY, -7, GETDATE())

    --romoved the date condition
    -- ORDER BY INVHED_TIME desc
    order by INVHED_DATETIME desc
END
GO
-------------------------------------------------------------
ALTER TABLE dbo.U_TBLSETUP ADD
    SETUP_STAFFDISC_EXCL_GRP int NULL
GO

-------------------------------------------------------------
CREATE TABLE [dbo].[M_TBLCUSDISC_PARAMS]
(
    [DISC_CUSGROUP] [nvarchar](8) NOT NULL,
    [DISC_MIN_DISC_PER] [numeric](18, 2) NULL,
    [DISC_MIN_COST_VAR] [numeric](18, 2) NULL,
    [DISC_MIN_SELLING_VAR] [numeric](18, 2) NULL,
    [CR_BY] [nvarchar](10) NULL,
    [CR_DATE] [datetime] NULL,
    [MD_BY] [nvarchar](10) NULL,
    [MD_DATE] [datetime] NULL,
    [DTRANS] [int] NULL,
    [DTPROCESS] [int] NULL,
    [DTS_DATE] [datetime] NULL,
    CONSTRAINT [PK_M_TBLCUSDISC_PARAMS] PRIMARY KEY CLUSTERED
(
    [DISC_CUSGROUP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[M_TBLCUSDISC_PARAMS] ADD CONSTRAINT [DF_M_TBLCUSDISC_PARAMS_DTS_DATE] DEFAULT (getdate()) FOR [DTS_DATE]
GO

---------------------------------------------------------
ALTER TABLE dbo.M_TBLCUSGROUPS ADD
    CG_CAL_STAFF_DISC bit NULL
GO

---------------------------------------------------------
ALTER PROCEDURE [dbo].[myPOS_DP_GET_CUSTOMER]
    @code varchar(max)
AS
BEGIN

    DECLARE @totalCredit numeric(18,2) = 0;

    SELECT @code = CM_CODE
    FROM M_TBLCUSTOMER
    WHERE CM_MOBILE1 like '%' + @code OR CM_CODE=@code or CM_LINKREF=@code

    SELECT @totalCredit = SUM(INVHED_DUEAMT)
    FROM T_TBLINVHEADER
    WHERE INVHED_MEMBER = @code

    SELECT top(1)
        CM_CODE, CM_FULLNAME CM_NAME, CM_NIC, CG_DESC as CM_GROUP, CM_MOBILE1 CM_MOBILE, dbo.parseBool(CM_STATUS) CM_ACTIVE, dbo.parseBool(CM_LOYALTY) CM_LOYALTYACTIVE, CM_PHOTO CM_PICTURE, CM_AREA, AM_DESC as AREA_DESC, CM_ADD1, CM_ADD2, CM_EMAIL, CM_DOB, CM_GENDER, dbo.parseBool(CM_EBILL) CM_EBILL, CM_LOYGROUP, CM_TITLE, CM_CREDITLIMIT, convert(numeric,CM_CREDITPERIOD) CM_CREDITPERIOD, CM_GROUP CM_CUSGROUP, @totalCredit as TOTALCREDITS, CM_ANNIVERSARY, 0 CM_INVCOUNT , ISNULL(CT_TAXREG,'') AS CT_TAXREG
    , CG_NOPROMO, CG_OTP_REQUIRED, DS_DISC, ISNULL(CG_CAL_STAFF_DISC,0) AS CG_CAL_STAFF_DISC, isnull(DISC_MIN_DISC_PER,0) as DISC_MIN_DISC_PER, isnull(DISC_MIN_COST_VAR,0) as DISC_MIN_COST_VAR, isnull(DISC_MIN_SELLING_VAR,0) as DISC_MIN_SELLING_VAR
    FROM M_TBLCUSTOMER m
        LEFT JOIN M_TBLCUSGROUPS
        ON CM_GROUP=CG_CODE
        LEFT JOIN M_TBLAREA
        ON CM_AREA=AM_CODE
        LEFT OUTER JOIN (SELECT CT_CUSCODE, MAX(CT_TAXREG) AS CT_TAXREG
        FROM M_TBLCUSTAX
        GROUP BY CT_CUSCODE) TAX
        ON CM_CODE=TAX.CT_CUSCODE
        LEFT OUTER JOIN M_TBLCUSDISCGROUPS
        ON CM_DISCGROUP = DS_CODE
        LEFT OUTER JOIN M_TBLCUSDISC_PARAMS
        ON CM_GROUP=DISC_CUSGROUP
    WHERE CM_CODE = @code or CM_NIC=@code or CM_MOBILE1=@code or CM_LINKREF=@code

END
GO
-------------------------------------------
ALTER PROCEDURE [dbo].[myPOS_DP_SEARCH_CUSTOMER]
    @keyword varchar(max)
AS
BEGIN

    DECLARE @likeStmt varchar(max);

    --    if (@keyword is null or @keyword = '')

    SET @likeStmt = '%'+@keyword+'%';

    DECLARE @totalCredit numeric(18,2) = 0;


    SELECT TOP 50
        CM_CODE, CM_FULLNAME CM_NAME, CM_NIC, CG_DESC as CM_GROUP, CM_MOBILE1 CM_MOBILE, dbo.parseBool(CM_STATUS) CM_ACTIVE, dbo.parseBool(CM_LOYALTY) CM_LOYALTYACTIVE, CM_PHOTO CM_PICTURE, CM_AREA, AM_DESC AREA_DESC, CM_ADD1, CM_ADD2, CM_EMAIL, CM_DOB, CM_GENDER, dbo.parseBool(CM_EBILL) CM_EBILL, CM_LOYGROUP, CM_GROUP CM_CUSGROUP, CM_TITLE, 100.00 CM_CREDITLIMIT, CONVERT(numeric,CM_CREDITPERIOD) CM_CREDITPERIOD, @totalCredit as TOTALCREDITS, 0 CM_INVCOUNT, CM_ANNIVERSARY, ISNULL(CT_TAXREG,'') AS CT_TAXREG,
        CG_NOPROMO, CG_OTP_REQUIRED, DS_DISC, ISNULL(CG_CAL_STAFF_DISC,0) AS CG_CAL_STAFF_DISC, isnull(DISC_MIN_DISC_PER,0) as DISC_MIN_DISC_PER, isnull(DISC_MIN_COST_VAR,0) as DISC_MIN_COST_VAR, isnull(DISC_MIN_SELLING_VAR,0) as DISC_MIN_SELLING_VAR
    FROM M_TBLCUSTOMER m
        LEFT JOIN M_TBLCUSGROUPS
        ON CM_GROUP=CG_CODE
        LEFT JOIN M_TBLAREA
        ON CM_AREA=AM_CODE
        LEFT OUTER JOIN (SELECT CT_CUSCODE, MAX(CT_TAXREG) AS CT_TAXREG
        FROM M_TBLCUSTAX
        GROUP BY CT_CUSCODE) TAX
        ON CM_CODE=TAX.CT_CUSCODE
        left outer join M_TBLCUSDISCGROUPS
        ON CM_DISCGROUP=DS_CODE
        LEFT OUTER JOIN M_TBLCUSDISC_PARAMS
        ON CM_GROUP=DISC_CUSGROUP
    WHERE CM_FULLNAME like @likeStmt
        OR CM_FNAME like @likeStmt
        OR CM_LNAME like @likeStmt
        OR CG_DESC like @likeStmt OR CM_MOBILE1 like @likeStmt OR CM_NIC like @likeStmt OR CM_CODE like @likeStmt OR CM_LINKREF like @likeStmt
    ORDER BY CM_STATUS DESC,CM_FULLNAME
END
GO

-----------------------------------------------
CREATE PROCEDURE [dbo].[myPOS_DP_GET_STAFF_DISC_SKU]
    @json varchar(max)
AS
BEGIN
    declare @grpLevel int
    declare @sql varchar(max)

    select @grpLevel=isnull(SETUP_STAFFDISC_EXCL_GRP,0)
    from u_tblsetup

    if @grpLevel>0
    begin
        SELECT productCode
        INTO #Products
        FROM OPENJSON(@json)
                WITH ( productCode VARCHAR(15))

        set @sql = ' SELECT PLU_CODE, UPPER(ISNULL(GP_DESC,'''')) AS DISC_STATUS FROM M_TBLPROMASTER LEFT OUTER JOIN M_TBLGROUP' + cast(@grpLevel as varchar(2)) +' ON PLU_GROUP'+ cast(@grpLevel as varchar(2)) + '=GP_CODE WHERE PLU_CODE IN (SELECT productCode from #Products)';
        print @sql;
        exec(@sql);
    end
END

GO

------------------------------------------------------
CREATE         PROCEDURE [dbo].[myPOS_DP_SEARCH_INVOICE_HEADER]
    @invNo varchar(max),
    @cashier varchar(max)
AS
BEGIN


    SELECT
        INVHED_INVNO, INVHED_CASHIER, INVHED_TIME, INVHED_MODE, INVHED_NETAMT, INVHED_DISPER, INVHED_GROAMT,
        INVHED_INVOICED, INVHED_MEMBER, INVHED_PRICEMODE
    FROM T_TBLINVHEADER
    WHERE  INVHED_INVNO = @invNo and INVHED_CASHIER = @cashier and INVHED_MODE ='INV' AND INVHED_CANCELED=0 and INVHED_INVOICED = 1
    -- ORDER BY INVHED_TIME desc
    order by INVHED_DATETIME desc


END
GO
-----------------------------------------------------------
ALTER         PROCEDURE [dbo].[myPOS_DP_GET_TODAY_INVOICES]
    @cashier varchar(max)
AS
BEGIN


    SELECT
        INVHED_INVNO, INVHED_CASHIER, INVHED_TIME, INVHED_MODE, INVHED_NETAMT, INVHED_DISPER, INVHED_GROAMT,
        INVHED_INVOICED, INVHED_MEMBER, INVHED_PRICEMODE
    FROM T_TBLINVHEADER
    WHERE  INVHED_CASHIER = @cashier AND INVHED_CANCELED=0 and INVHED_TXNDATE >= DATEADD(DAY, -7, GETDATE())--romoved the date condition
    -- ORDER BY INVHED_TIME desc
    order by INVHED_TXNDATE desc


END
GO
------------------------------------------------------------
CREATE proc [dbo].[myPOS_DP_CHECK_INVOICE]
    @loc_code varchar(10),
    @inv_no varchar(20),
    @inv_mode varchar(5)
as
declare @hed_amount numeric(18,2)
declare @det_amount numeric(18,2)
declare @pay_amount numeric(18,2)
declare @det_count numeric(18,0)
declare @pay_count numeric(18,0)

select @hed_amount=INVHED_NETAMT
from T_TBLINVHEADER
where INVHED_LOCCODE=@loc_code and INVHED_INVNO=@inv_no and INVHED_MODE=@inv_mode

select @det_count=count(INVDET_INVNO),
    @det_amount=sum(
(INVDET_SELLING*INVDET_UNITQTY)-
(
(INVDET_SELLING*INVDET_UNITQTY*INVDET_DISCPER/100) +
INVDET_DISCAMT +
(INVDET_SELLING*INVDET_UNITQTY*INVDET_BILLDISCPER/100) +
(INVDET_SELLING*INVDET_UNITQTY*INVDET_PROMODISCPER/100) +
INVDET_PROMODISCAMT
)
)
from T_TBLINVDETAILS
where INVDET_LOCCODE=@loc_code and INVDET_INVNO=@inv_no and INVDET_MODE=@inv_mode and INVDET_VOID=0

select @pay_count=count(INVPAY_INVNO),
    @pay_amount=sum(INVPAY_PAIDAMOUNT)
from T_TBLINVPAYMENTS
where INVPAY_LOCCODE=@loc_code and INVPAY_INVNO=@inv_no and INVPAY_MODE=@inv_mode

select isNULL(@hed_amount, 0) as HED_AMOUNT, isNULL(@det_amount, 0) AS DET_AMOUNT, isNULL(@pay_amount,0) AS PAY_AMOUNT, isNULL(@det_count,0) AS DET_COUNT, isNULL(@pay_count,0) AS PAY_COUNT
GO
-----------------------------------------------------------------
CREATE proc [dbo].[myPOS_DP_DELETE_INVOICE_LOCAL]
    @loc_code varchar(10),
    @inv_no varchar(20),
    @inv_mode varchar(5)
as

delete from T_TBLINVHEADER where INVHED_LOCCODE=@loc_code and INVHED_INVNO=@inv_no and INVHED_MODE=@inv_mode
delete from T_TBLINVDETAILS where INVDET_LOCCODE=@loc_code and INVDET_INVNO=@inv_no and INVDET_MODE=@inv_mode
delete from T_TBLINVPAYMENTS where INVPAY_LOCCODE=@loc_code and INVPAY_INVNO=@inv_no and INVPAY_MODE=@inv_mode
delete from T_TBLINVFREEISSUES where INVPROMO_LOCCODE=@loc_code and INVPROMO_INVNO=@inv_no
delete from T_TBLINVREMARKS where INVREM_LOCCODE=@loc_code and INVREM_INVNO=@inv_no
delete from T_TBLINVLINEREMARKS where INVREM_LOCCODE=@loc_code and INVREM_INVNO=@inv_no
delete from T_TBLTXNTAX where TXN_LOCCODE=@loc_code and TXN_RUNNO=@inv_no and TXN_MODE=@inv_mode


GO
------------------------------------------------------------------
ALTER proc [dbo].[myPOS_DP_CHECK_INVOICE]
    @loc_code varchar(10),
    @inv_no varchar(20),
    @inv_mode varchar(5)
as
declare @hed_amount numeric(18,2)
declare @det_amount numeric(18,2)
declare @pay_amount numeric(18,2)
declare @hed_count numeric(18,0)
declare @det_count numeric(18,0)
declare @pay_count numeric(18,0)

select @hed_amount=INVHED_NETAMT
from T_TBLINVHEADER
where INVHED_LOCCODE=@loc_code and INVHED_INVNO=@inv_no and INVHED_MODE=@inv_mode

select @hed_count = count(invhed_invno)
from T_TBLINVHEADER
where INVHED_LOCCODE=@loc_code and INVHED_INVNO=@inv_no and INVHED_MODE=@inv_mode

select @det_count=count(INVDET_INVNO),
    @det_amount=sum(
(INVDET_SELLING*INVDET_UNITQTY)-
(
(INVDET_SELLING*INVDET_UNITQTY*INVDET_DISCPER/100) +
INVDET_DISCAMT +
(INVDET_SELLING*INVDET_UNITQTY*INVDET_BILLDISCPER/100) +
(INVDET_SELLING*INVDET_UNITQTY*INVDET_PROMODISCPER/100) +
INVDET_PROMODISCAMT
)
)
from T_TBLINVDETAILS
where INVDET_LOCCODE=@loc_code and INVDET_INVNO=@inv_no and INVDET_MODE=@inv_mode and INVDET_VOID=0

select @pay_count=count(INVPAY_INVNO),
    @pay_amount=sum(INVPAY_PAIDAMOUNT)
from T_TBLINVPAYMENTS
where INVPAY_LOCCODE=@loc_code and INVPAY_INVNO=@inv_no and INVPAY_MODE=@inv_mode

select isNULL(@hed_amount, 0) as HED_AMOUNT, isNULL(@det_amount, 0) AS DET_AMOUNT, isNULL(@pay_amount,0) AS PAY_AMOUNT, isNULL(@hed_count,0) as HED_COUNT, isNULL(@det_count,0) AS DET_COUNT, isNULL(@pay_count,0) AS PAY_COUNT

GO
-------------------------------------------------------------------------
ALTER TABLE M_TBLPROMASTER ADD PLU_MINSELL Numeric(18,2) DEFAULT 0;
GO
-------------------------------------------------------------------------
ALTER TABLE M_TBLPROMASTER ADD PLU_ALLOW_PRICE_CHANGE bit DEFAULT 0;
GO
-------------------------------------------------------------------------
ALTER PROCEDURE [dbo].[myPOS_DP_SEARCH_PRODUCT]
    @keyword varchar(max),
    @loc varchar(40),
    @filterBy int = 1,
    @page int = 0,
    @count int = 50,
    @byFirstLetter int =0,
    @combineSearch int =0
AS
BEGIN

    DECLARE @likeStmt varchar(max);
    if @byFirstLetter=0
	begin
        SET @likeStmt  = '''%'+@keyword+'%''';
    end
	else
	begin
        SET @likeStmt  = ''''+@keyword+'%''';
    end

    DECLARE @sqlSelect varchar(max);
    DECLARE @sqlEnd varchar(max);
    DECLARE @sqlWhere varchar(max);

    SET @sqlSelect = 'SELECT TOP('+ cast(@count as varchar(7))  +')
		INV.IPLU_PRODUCTCODE  PLU_CODE,IPLU_DESC PLU_POSDESC,
		case when PLU_BATCHENABLE=0 AND PLU_VARIANTANABLE=0 THEN plu.PLU_STOCKCODE ELSE inv.IPLU_PRODUCTCODE END PLU_STOCKCODE,
		dbo.parseBool(plu.PLU_ACTIVE) PLU_ACTIVE,dbo.parseBool(plu.PLU_NODISC) PLU_NODISC,plu.PLU_CS CASE_SIZE,u.UM_DESC PLU_UNIT,dbo.parseBool(plu.PLU_OPEN) PLU_OPEN,
		inv.IPLU_SELL SELLING_PRICE,inv.IPLU_SIH SIH,inv.IPLU_AVGCOST PLU_AVGCOST,inv.IPLU_COST PLU_COST, '+ '''''' +' SCAN_CODE,
		gp2.gp_desc PLU_SUB_DEPARTMENT,gp1.gp_desc PLU_DEPARTMENT,PLU_PICTURE IMAGE_PATH, '+ '''''' +' as Status,PLU_PICTURE_HASH,PLU_MAXDISCPER,PLU_MAXDISCAMT,dbo.parseBool(PLU_DECIMAL) PLU_DECIMAL, dbo.parseBool(PLU_MINUSALLOW)  PLU_MINUSALLOW, 0.0 PLU_MAXVOLUME, '+ '''''' +'  PLU_MAXVOLUME_GRP, '+ '''''' +'  PLU_MAXVOLUME_GRPLV, 0.0 PLU_VOLUME, 0 PLU_VARIENT_POPUP,PLU_EXCHANGABLE,cast(IPLU_ACTIVE as bit) AS PLU_POSACTIVE, PLU_VENDORPLU,PLU_RETURN,PLU_VARIANTANABLE,PLU_BATCHENABLE,isnull(PLU_EMPTY,0) as PLU_EMPTY, isNULL(PLU_MINSELL, 0) PLU_MINSELL, isNULL(PLU_ALLOW_PRICE_CHANGE, 0) PLU_ALLOW_PRICE_CHANGE
		FROM M_TBLPROMASTER plu
		INNER JOIN M_TBLPROINVENTORY inv
		ON  inv.IPLU_CODE= plu.PLU_CODE
		INNER JOIN M_TBLUNITS u
		ON plu.PLU_UNIT = u.UM_CODE
		LEFT JOIN VIEW_PRODUCT_GROUP1 gp1
		ON gp1.GPLU_CODE = plu.PLU_CODE
		LEFT JOIN VIEW_PRODUCT_GROUP2 gp2
		ON gp2.GPLU_CODE = plu.PLU_CODE
		WHERE inv.IPLU_LOCCODE =  ''' + @loc + '''  AND PLU_RAWITEM=0 AND IPLU_ACTIVE=1 AND PLU_ACTIVE=1 AND ';

    SET @sqlEnd = ' GROUP BY 
			plu.PLU_CODE,plu.PLU_POSDESC,plu.PLU_STOCKCODE,plu.PLU_ACTIVE,plu.PLU_NODISC,plu.PLU_CS,plu.PLU_UNIT,plu.PLU_OPEN,
		inv.IPLU_SELL,inv.IPLU_SIH,inv.IPLU_AVGCOST,inv.IPLU_COST, 
		PLU_PICTURE,PLU_PICTURE_HASH,IPLU_PRODUCTCODE,PLU_MAXDISCPER,PLU_MAXDISCAMT,PLU_DECIMAL, PLU_MINUSALLOW ,IPLU_DESC,UM_DESC,PLU_EXCHANGABLE,IPLU_ACTIVE,gp2.gp_desc,gp1.gp_desc,PLU_VENDORPLU,PLU_RETURN,PLU_VARIANTANABLE,PLU_BATCHENABLE,isnull(PLU_EMPTY,0), isNULL(PLU_MINSELL, 0),isNULL(PLU_ALLOW_PRICE_CHANGE, 0)
		';
    --ORDER BY PLU_POSDESC,PLU_CODE

    if @combineSearch=0
		begin
        IF @filterBy = 0
			BEGIN
            SET @sqlWhere = ' IPLU_PRODUCTCODE like ' +@likeStmt;
        END
			ELSE IF @filterBy=1
			BEGIN
            SET @sqlWhere = ' IPLU_DESC like ' +@likeStmt;
        END
			ELSE IF @filterBy=2
			BEGIN
            SET @sqlWhere = ' PLU_UNIT like ' +@likeStmt;
        END
			ELSE IF @filterBy=3
			BEGIN
            SET @sqlWhere = ' PLU_CS like ' +@likeStmt;
        END
			ELSE IF @filterBy=4
			BEGIN
            SET @sqlWhere = ' IPLU_SELL like ' +@likeStmt;
        END
			ELSE IF @filterBy=5
			BEGIN
            SET @sqlWhere = ' gp1.gp_desc like ' +@likeStmt;
        END
			ELSE IF @filterBy=6
			BEGIN
            SET @sqlWhere = ' gp2.gp_desc like ' +@likeStmt;
        END
    end
		else
		begin
        SET @sqlWhere = '( IPLU_PRODUCTCODE like ' +@likeStmt+ ' or IPLU_DESC like '+@likeStmt+' )';
    end

    EXEC (@sqlSelect + @sqlWhere + @sqlEnd)
    PRINT (@sqlSelect + @sqlWhere + @sqlEnd)
END
GO
--------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE [dbo].[myPOS_DP_GET_WEIGHTED_PRODUCTS]
    @groupCode varchar(10),
    @groupNo varchar(10),
    @loc varchar(10)
AS
BEGIN

    SELECT
        IPLU_PRODUCTCODE PLU_CODE, IPLU_DESC PLU_POSDESC, case when PLU_BATCHENABLE=0 AND PLU_VARIANTANABLE=0 THEN PLU_STOCKCODE ELSE IPLU_PRODUCTCODE END PLU_STOCKCODE, dbo.parseBool(PLU_ACTIVE) PLU_ACTIVE, dbo.parseBool(PLU_NODISC) PLU_NODISC, PLU_COST, PLU_AVGCOST, PLU_UNIT, dbo.parseBool(PLU_OPEN)PLU_OPEN, i.IPLU_SELL as SELLING_PRICE,
        PLU_CS as CASE_SIZE, '' SCAN_CODE, PLU_PICTURE IMAGE_PATH, i.IPLU_SIH as SIH,
        'available' as status, gp1.GP_CODE as PLU_DEPARTMENT, '' PLU_SUB_DEPARTMENT, PLU_PICTURE_HASH, PLU_MAXDISCPER, PLU_MAXDISCAMT, dbo.parseBool(PLU_DECIMAL) PLU_DECIMAL, PLU_MINUSALLOW , 0.0 PLU_MAXVOLUME, '' PLU_MAXVOLUME_GRP, '' PLU_MAXVOLUME_GRPLV, 0.0 PLU_VOLUME, 0 PLU_VARIENT_POPUP, PLU_EXCHANGABLE, cast(IPLU_ACTIVE as bit) AS PLU_POSACTIVE, PLU_VENDORPLU, PLU_RETURN, PLU_VARIANTANABLE, PLU_BATCHENABLE, isnull(PLU_EMPTY,0) as PLU_EMPTY, isNULL(PLU_MINSELL, 0) PLU_MINSELL, isNULL(PLU_ALLOW_PRICE_CHANGE, 0) PLU_ALLOW_PRICE_CHANGE
    FROM M_TBLPROMASTER
        JOIN M_TBLPROGROUPS pr
        ON pr.GPLU_CODE=PLU_CODE
        JOIN M_TBLGROUP1 gp1
        ON gp1.GP_CODE=pr.GPLU_GROUPCODE1
        JOIN M_TBLPROINVENTORY i
        ON PLU_CODE = i.IPLU_CODE
    WHERE 
	gp1.GP_CODE=@groupCode
        AND i.IPLU_LOCCODE=@loc
        AND PLU_FASTMOVE = 1
        AND PLU_ACTIVE=1
        AND PLU_RAWITEM=0
        AND IPLU_ACTIVE=1
    GROUP BY PLU_CODE,PLU_POSDESC,PLU_STOCKCODE,PLU_ACTIVE,PLU_NODISC,PLU_COST,PLU_AVGCOST,PLU_UNIT,PLU_OPEN,i.IPLU_SELL,PLU_CS,i.IPLU_SIH,gp1.GP_CODE,PLU_PICTURE,PLU_PICTURE_HASH,PLU_MAXDISCPER,PLU_MAXDISCAMT,PLU_DECIMAL,PLU_MINUSALLOW ,IPLU_DESC,IPLU_PRODUCTCODE,PLU_EXCHANGABLE, IPLU_ACTIVE,PLU_VENDORPLU,PLU_RETURN,PLU_BATCHENABLE,PLU_VARIANTANABLE,isnull(PLU_EMPTY,0),isNULL(PLU_MINSELL, 0),isNULL(PLU_ALLOW_PRICE_CHANGE, 0)
END
GO
---------------------------------------------------------------------------------------------------------------
ALTER PROCEDURE [dbo].[myPOS_DP_GET_WEIGHTED_PRODUCT_BY_ID]
    @code varchar(50),
    @loc varchar(10),
    @priceMode varchar(15)
AS
BEGIN
    DECLARE @pluCode varchar(max);
    DECLARE @posDesc varchar(max);
    DECLARE @stockCode varchar(max);
    DECLARE @noDisc bit;
    DECLARE @active bit;
    DECLARE @minus bit;
    DECLARE @pluOpen bit=0;
    DECLARE @pluDecimal bit=0;
    DECLARE @sih numeric(18,3);
    DECLARE @selling numeric(18,2);
    DECLARE @temp int;
    DECLARE @caseSize numeric(18,2);
    DECLARE @maxDisc numeric(18,2);
    DECLARE @maxDiscAmt numeric(18,2);
    DECLARE @cost numeric(18,2);
    DECLARE @avgCost numeric(18,2);
    DECLARE @pluUnit varchar(50);
    DECLARE @department varchar(50);
    DECLARE @subDepartment varchar(50);
    DECLARE @pluLen int;
    DECLARE @typeLen int;
    -- typed pro code length
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
    DECLARE @posactive bit =0;
    declare @vendorplu varchar(30);
    declare @EmptyBtlCode varchar(20);
    declare @variantEnable bit=0;
    DECLARE @motherCode varchar(max);
    declare @batchEnable bit=0;
    declare @CompanyVariantEnable bit=0;
    declare @ActMotherCode varchar(max);
    declare @isEmptyCode int;
    declare @minSell decimal(18,2);
    declare @allowPriceChange bit = 0;
    select @CompanyVariantEnable= SETUP_VARIANT
    from U_TBLSETUP

    --- get special price link with price mode table 
    SELECT @hasSpecialPrice = PRM_LINKWITHSPECIAL
    FROM M_TBLPRICEMODES
    WHERE PRM_CODE= @priceMode

    --casier orignally entered code
    SET @searchCode= @code;

    --search in the product table
    SELECT @pluCode=PLU_CODE, @posDesc = PLU_POSDESC, @active= PLU_ACTIVE, @noDisc=PLU_NODISC, @caseSize=PLU_CS, @pluUnit=PLU_UNIT, @pluOpen = PLU_OPEN, @picture=PLU_PICTURE , @imageHash=PLU_PICTURE_HASH, @maxDisc=PLU_MAXDISCPER, @maxDiscAmt=PLU_MAXDISCAMT, @pluDecimal = PLU_DECIMAL, @minus=PLU_MINUSALLOW, @maxQty = PLU_ALLOWQTY, @exchangable=PLU_EXCHANGABLE, @posactive=PLU_POSACTIVE, @vendorplu=PLU_VENDORPLU, @EmptyBtlCode=PLU_RETURN, @variantEnable=PLU_VARIANTANABLE, @motherCode=PLU_STOCKCODE, @batchEnable=PLU_BATCHENABLE, @isEmptyCode=PLU_EMPTY, @minSell = PLU_MINSELL, @allowPriceChange = PLU_ALLOW_PRICE_CHANGE
    FROM M_TBLPROMASTER p
    WHERE (PLU_CODE = @searchCode OR PLU_REF1 = @searchCode OR PLU_REF2=@searchCode OR PLU_REF3=@searchCode
        OR PLU_VENDORPLU=@searchCode OR PLU_REF4 = @searchCode OR PLU_REF5=@searchCode) AND PLU_RAWITEM=0 AND PLU_ACTIVE=1 AND PLU_FASTMOVE=1
    -- if the product is not found in pro master
    IF @@ROWCOUNT = 0
	BEGIN
        --check ref table
        SET @proMasterSearched = 0;
        SELECT @pluCode=RPLU_CODE
        FROM M_TBLPROREFERENCES
        WHERE RPLU_REFCODE=@searchCode AND RPLU_LOCCODE=@loc AND RPLU_ACTIVE=1
        IF @@ROWCOUNT = 0
		--still empty then check with auto filled numberes
		BEGIN
            -- append prefix to cashier entered code
            SELECT @pluPrefix=MASTER_PREFIX, @pluCharLen=CONVERT(int,MASTER_CODELENGTH)
            FROM U_TBLMASTERFORMAT
            WHERE  MASTER_MENUTAG='M00502'

            SET @pluLen= LEN(@pluPrefix) + @pluCharLen

            SET @typeLen= LEN(@code)
            SET @createdPluCode = @code

            IF @typeLen != @pluLen
            BEGIN
                DECLARE @i int;
                SET @i = 0;
                DECLARE @loop int;
                SET @loop = SUM(@pluCharLen-@typeLen-1);

                WHILE @i <= @loop
                BEGIN
                    SET @createdPluCode = '0'+@createdPluCode
                    SET @i = @i + 1;
                END
                SET @createdPluCode = @pluPrefix+@createdPluCode
            END
            SELECT @code=@createdPluCode,
                @pluCode=PLU_CODE, @posDesc = PLU_POSDESC, @active= PLU_ACTIVE, @noDisc=PLU_NODISC, @caseSize=PLU_CS, @pluUnit=PLU_UNIT, @pluOpen = PLU_OPEN, @picture=PLU_PICTURE , @imageHash=PLU_PICTURE_HASH, @maxDisc=PLU_MAXDISCPER, @maxDiscAmt=PLU_MAXDISCAMT, @pluDecimal = PLU_DECIMAL, @minus=PLU_MINUSALLOW, @maxQty = PLU_ALLOWQTY, @exchangable=PLU_EXCHANGABLE, @posactive=PLU_POSACTIVE, @vendorplu=PLU_VENDORPLU, @EmptyBtlCode=PLU_RETURN, @variantEnable=PLU_VARIANTANABLE, @motherCode=PLU_STOCKCODE, @batchEnable=PLU_BATCHENABLE, @isEmptyCode=PLU_EMPTY, @minSell = PLU_MINSELL, @allowPriceChange = PLU_ALLOW_PRICE_CHANGE
            FROM M_TBLPROMASTER p
            WHERE PLU_CODE = @createdPluCode AND
                PLU_RAWITEM=0 AND PLU_ACTIVE=1 AND PLU_FASTMOVE=1
            IF @@ROWCOUNT = 0
			-- if still cannot find product mean its maybe a varient code or batch code
			BEGIN
                SET @proMasterSearched = 0;
                SELECT @selling=IPLU_SELL, @sih = IPLU_SIH, @plucode = IPLU_CODE, @avgCost = IPLU_AVGCOST,
                    @stockCode=IPLU_PRODUCTCODE, @cost=IPLU_COST , @posDesc = IPLU_DESC, @specialPrice = IPLU_SPECIALPRICE, @posactive=CAST(IPLU_ACTIVE AS BIT)
                FROM M_TBLPROINVENTORY
                WHERE 
                (IPLU_PRODUCTCODE=@searchCode OR IPLU_PRODUCTCODE=@createdPluCode+'00000001')
                    AND IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1
                -- if still product is not found means its lost
                IF @@ROWCOUNT=0
                BEGIN
                    SET @status='lost_product'
                END
				ELSE
				BEGIN
                    SET @inventorySearched = 1;
                END
            END
        END
    END

    IF @status IS NULL
    BEGIN

        IF @proMasterSearched = 0
        BEGIN
            SELECT @pluCode=PLU_CODE, @active= PLU_ACTIVE, @noDisc=PLU_NODISC, @caseSize=PLU_CS, @pluUnit=PLU_UNIT, @pluOpen = PLU_OPEN, @picture=PLU_PICTURE , @imageHash=PLU_PICTURE_HASH, @maxDisc=PLU_MAXDISCPER, @maxDiscAmt=PLU_MAXDISCAMT, @pluDecimal = PLU_DECIMAL, @minus=PLU_MINUSALLOW, @maxQty = PLU_ALLOWQTY, @exchangable=PLU_EXCHANGABLE, @posactive=PLU_POSACTIVE, @vendorplu=PLU_VENDORPLU, @EmptyBtlCode=PLU_RETURN, @variantEnable=PLU_VARIANTANABLE, @motherCode=PLU_STOCKCODE, @batchEnable=PLU_BATCHENABLE, @isEmptyCode=PLU_EMPTY, @minSell = PLU_MINSELL, @allowPriceChange = PLU_ALLOW_PRICE_CHANGE
            FROM M_TBLPROMASTER p
            WHERE PLU_CODE = @pluCode AND PLU_FASTMOVE=1
        END

        if @CompanyVariantEnable=1
		begin
            set @ActMotherCode = @motherCode+'0000'
        end
		else
		begin
            set @ActMotherCode = @motherCode
        end

        -- fetech inventory details
        IF @inventorySearched = 0
        BEGIN
            SELECT @selling=IPLU_SELL, @sih = IPLU_SIH, @plucode = IPLU_CODE, @avgCost = IPLU_AVGCOST,
                @stockCode=IPLU_PRODUCTCODE, @cost=IPLU_COST, @posDesc = IPLU_DESC, @specialPrice = IPLU_SPECIALPRICE, @posactive=CAST(IPLU_ACTIVE AS BIT)
            FROM M_TBLPROINVENTORY
            WHERE IPLU_CODE=@pluCode
                AND IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1

        END

        -- SELECT PRODUCT VOLUME AND GROUP
        SELECT @volume=UM_VOLUME
        FROM M_TBLUNITS u
        WHERE u.UM_CODE = @pluUnit
        SELECT @maxQty=a.VL_TOTALCAPACITY, @maxQtyGrp=a.VL_GROUPCODE, @maxQtyGrpLvl=a.VL_GROUPLEVEL
        FROM U_TBLMAXALLOWED a
        WHERE a.VL_UOM= @pluUnit
    END
    IF @hasSpecialPrice = 1 
	BEGIN
        SET @selling = @specialPrice
    END
    SELECT @stockCode SCAN_CODE, @pluCode as PLU_CODE, @posDesc  as  PLU_POSDESC, case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end  as PLU_STOCKCODE, @active as  PLU_ACTIVE, @noDisc as PLU_NODISC, @selling as SELLING_PRICE, @sih as SIH, @caseSize as CASE_SIZE, @cost as PLU_COST, @avgCost as PLU_AVGCOST, @pluUnit as PLU_UNIT, @department PLU_DEPARTMENT, @subDepartment PLU_SUB_DEPARTMENT, @picture IMAGE_PATH, @pluDecimal as PLU_DECIMAL, @status as status, @pluOpen as PLU_OPEN, @imageHash PLU_PICTURE_HASH, @maxDisc PLU_MAXDISCPER, @maxDiscAmt PLU_MAXDISCAMT, @minus PLU_MINUSALLOW, @maxQty PLU_MAXVOLUME, @maxQtyGrp PLU_MAXVOLUME_GRP, @maxQtyGrpLvl PLU_MAXVOLUME_GRPLV, @volume PLU_VOLUME, '' GP_CODE, '' GP_DESC, '' GP_TABLE, @exchangable PLU_EXCHANGABLE, @posactive PLU_POSACTIVE, @vendorplu PLU_VENDORPLU , @EmptyBtlCode PLU_RETURN, @variantEnable PLU_VARIANTANABLE, @batchEnable PLU_BATCHENABLE, isnull(@isEmptyCode,0) PLU_EMPTY, isNULL(@minSell, 0) PLU_MINSELL, isNULL(@allowPriceChange, 0) PLU_ALLOW_PRICE_CHANGE



/*

	SELECT 
	p.PLU_CODE,PLU_POSDESC,PLU_STOCKCODE,dbo.parseBool(PLU_ACTIVE) PLU_ACTIVE,dbo.parseBool(PLU_NODISC) PLU_NODISC,PLU_COST,PLU_AVGCOST,PLU_UNIT,dbo.parseBool(PLU_OPEN)PLU_OPEN,i.IPLU_SELL as SELLING_PRICE,
	PLU_CS as CASE_SIZE,dbo.parseBool(PLU_DECIMAL) PLU_DECIMAL,
	'' SCAN_CODE,PLU_PICTURE IMAGE_PATH,i.IPLU_SIH as SIH,PLU_MINUSALLOW,
	'available' as status,gp1.GP_CODE  as PLU_DEPARTMENT,'' PLU_SUB_DEPARTMENT,gp1.GP_CODE GP_CODE,gp1.gp_desc GP_DESC,'' as GP_TABLE,PLU_PICTURE_HASH,PLU_MAXDISCPER,PLU_MAXDISCAMT, 0.0 PLU_MAXVOLUME,'' PLU_MAXVOLUME_GRP,'' PLU_MAXVOLUME_GRPLV,0.0 PLU_VOLUME
	FROM M_TBLPROMASTER p 
		JOIN M_TBLPROGROUPS pr
	ON pr.GPLU_CODE=PLU_CODE
	JOIN M_TBLGROUP1 gp1
	ON gp1.GP_CODE=pr.GPLU_GROUPCODE1
	JOIN M_TBLPROINVENTORY i
	ON PLU_CODE = i.IPLU_CODE
	WHERE 
	(PLU_CODE=@code OR PLU_REF1=@code  OR PLU_REF2=@code OR PLU_REF3=@code OR PLU_REF4 = @code OR PLU_REF5=@code)
	AND i.IPLU_LOCCODE=@loc
	AND PLU_DECIMAL=1
	AND PLU_ACTIVE=1
	AND PLU_RAWITEM=0
	AND IPLU_ACTIVE=1
	GROUP BY p.PLU_CODE,PLU_POSDESC,PLU_STOCKCODE,PLU_ACTIVE,PLU_NODISC,PLU_COST,PLU_AVGCOST,PLU_UNIT,PLU_OPEN,i.IPLU_SELL,PLU_CS,i.IPLU_SIH,gp1.GP_CODE,
	gp1.gp_desc,PLU_PICTURE,PLU_PICTURE_HASH,PLU_MAXDISCPER,PLU_MAXDISCAMT,PLU_DECIMAL,PLU_MINUSALLOW 


	*/
END
GO
--------------------------------------------------------------------------------------------------------------
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
    DECLARE @typeLen int;
    -- typed pro code length
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
    SELECT IPLU_PRODUCTCODE SCAN_CODE, PLU_CODE, IPLU_DESC  as  PLU_POSDESC, IPLU_PRODUCTCODE as PLU_STOCKCODE, cast(IPLU_ACTIVE as bit) as  PLU_ACTIVE, cast(PLU_NODISC as bit) as PLU_NODISC,
        IPLU_SELL SELLING_PRICE, IPLU_SIH AS SIH, PLU_CS as CASE_SIZE, IPLU_COST AS PLU_COST, IPLU_AVGCOST AS PLU_AVGCOST, PLU_UNIT as PLU_UNIT,
        '' PLU_DEPARTMENT, '' PLU_SUB_DEPARTMENT, PLU_PICTURE IMAGE_PATH, cast(PLU_DECIMAL as bit) as PLU_DECIMAL, '' as status, cast(PLU_OPEN as bit) as PLU_OPEN, PLU_PICTURE_HASH PLU_PICTURE_HASH,
        PLU_MAXDISCPER, PLU_MAXDISCAMT, PLU_MINUSALLOW, cast(0 as numeric) AS PLU_MAXVOLUME, '' AS PLU_MAXVOLUME_GRP, '' AS PLU_MAXVOLUME_GRPLV, cast(0 as numeric) AS PLU_VOLUME,
        PLU_EXCHANGABLE, PLU_VENDORPLU, PLU_POSACTIVE, PLU_RETURN, PLU_VARIANTANABLE, PLU_BATCHENABLE, isnull(PLU_EMPTY,0) PLU_EMPTY, isNULL(PLU_MINSELL, 0) PLU_MINSELL, isNULL(PLU_ALLOW_PRICE_CHANGE, 0) PLU_ALLOW_PRICE_CHANGE
    FROM M_TBLPROMASTER INNER JOIN M_TBLPROINVENTORY ON PLU_CODE=IPLU_CODE
    WHERE IPLU_LOCCODE=@loc
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
----------------------------------------------------------------------------------------------------
ALTER PROCEDURE [dbo].[myPOS_DP_GET_PRODUCT_BY_ID]
    @code varchar(max),
    @loc varchar(40),
    @priceMode varchar(15)
AS
BEGIN
    DECLARE @pluCode varchar(max);
    DECLARE @posDesc varchar(max);
    DECLARE @stockCode varchar(max);
    DECLARE @noDisc bit;
    DECLARE @active bit;
    DECLARE @minus bit;
    DECLARE @pluOpen bit=0;
    DECLARE @pluDecimal bit=0;
    DECLARE @sih numeric(18,3);
    DECLARE @selling numeric(18,2);
    DECLARE @temp int;
    DECLARE @caseSize numeric(18,2);
    DECLARE @maxDisc numeric(18,2);
    DECLARE @maxDiscAmt numeric(18,2);
    DECLARE @cost numeric(18,2);
    DECLARE @avgCost numeric(18,2);
    DECLARE @pluUnit varchar(50);
    DECLARE @department varchar(50);
    DECLARE @subDepartment varchar(50);
    DECLARE @pluLen int;
    DECLARE @typeLen int;
    -- typed pro code length
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
    declare @minSell decimal(18,2);
    declare @allowPriceChange bit = 0;

    select @CompanyVariantEnable= SETUP_VARIANT
    from U_TBLSETUP

    --- get special price link with price mode table 
    SELECT @hasSpecialPrice = PRM_LINKWITHSPECIAL
    FROM M_TBLPRICEMODES
    WHERE PRM_CODE=@priceMode;

    --casier orignally entered code
    SET @searchCode= @code;

    --search in the product table
    SELECT @pluCode=PLU_CODE, @posDesc = PLU_POSDESC, @active= PLU_ACTIVE, @noDisc=PLU_NODISC, @caseSize=PLU_CS, @pluUnit=PLU_UNIT, @pluOpen = PLU_OPEN, @picture=PLU_PICTURE , @imageHash=PLU_PICTURE_HASH, @maxDisc=PLU_MAXDISCPER, @maxDiscAmt=PLU_MAXDISCAMT, @pluDecimal = PLU_DECIMAL, @minus=PLU_MINUSALLOW, @maxQty = PLU_ALLOWQTY, @exchangable=PLU_EXCHANGABLE, @vendorPlu=PLU_VENDORPLU, @posactive =PLU_POSACTIVE, @emptyBtCode=PLU_RETURN, @variantEnable=PLU_VARIANTANABLE, @motherCode=PLU_STOCKCODE, @batchEnable=PLU_BATCHENABLE, @isEmptyCode=PLU_EMPTY, @minSell = PLU_MINSELL, @allowPriceChange = PLU_ALLOW_PRICE_CHANGE
    FROM M_TBLPROMASTER p
    WHERE (PLU_CODE = @searchCode
        OR PLU_VENDORPLU=@searchCode) AND PLU_RAWITEM=0 AND PLU_ACTIVE=1
    --WHERE (PLU_CODE = @searchCode OR PLU_REF1 = @searchCode OR PLU_REF2=@searchCode OR PLU_REF3=@searchCode 
    --OR PLU_VENDORPLU=@searchCode OR PLU_REF4 = @searchCode OR PLU_REF5=@searchCode)  AND PLU_RAWITEM=0 AND PLU_ACTIVE=1
    -- if the product is not found in pro master
    IF @@ROWCOUNT = 0
	BEGIN
        --check ref table
        SET @proMasterSearched = 0;
        /*
		SELECT @pluCode=RPLU_CODE FROM M_TBLPROREFERENCES 
        WHERE RPLU_REFCODE=@searchCode AND RPLU_LOCCODE=@loc AND RPLU_ACTIVE=1
		*/
        SELECT @pluCode=RPLU_CODE
        FROM M_TBLPROREFERENCES
        WHERE RPLU_REFCODE=@searchCode AND RPLU_ACTIVE=1

        IF @@ROWCOUNT = 0
		--still empty then check with auto filled numberes
		BEGIN
            -- append prefix to cashier entered code
            SELECT @pluPrefix=MASTER_PREFIX, @pluCharLen=CONVERT(int,MASTER_CODELENGTH)
            FROM U_TBLMASTERFORMAT
            WHERE  MASTER_MENUTAG='M00502'

            SET @pluLen= LEN(@pluPrefix) + @pluCharLen

            SET @typeLen= LEN(@code)
            SET @createdPluCode = @code

            IF @typeLen != @pluLen
            BEGIN
                DECLARE @i int;
                SET @i = 0;
                DECLARE @loop int;
                SET @loop = SUM(@pluCharLen-@typeLen-1);

                WHILE @i <= @loop
                BEGIN
                    SET @createdPluCode = '0'+@createdPluCode
                    SET @i = @i + 1;
                END
                SET @createdPluCode = @pluPrefix+@createdPluCode
            END
            SELECT @code=@createdPluCode,
                @pluCode=PLU_CODE, @posDesc = PLU_POSDESC, @active= PLU_ACTIVE, @noDisc=PLU_NODISC, @caseSize=PLU_CS, @pluUnit=PLU_UNIT, @pluOpen = PLU_OPEN, @picture=PLU_PICTURE , @imageHash=PLU_PICTURE_HASH, @maxDisc=PLU_MAXDISCPER, @maxDiscAmt=PLU_MAXDISCAMT, @pluDecimal = PLU_DECIMAL, @minus=PLU_MINUSALLOW, @maxQty = PLU_ALLOWQTY, @exchangable=PLU_EXCHANGABLE, @vendorPlu=PLU_VENDORPLU, @posactive =PLU_POSACTIVE, @emptyBtCode=PLU_RETURN, @variantEnable=PLU_VARIANTANABLE, @motherCode=PLU_STOCKCODE, @batchEnable=PLU_BATCHENABLE, @isEmptyCode=PLU_EMPTY, @minSell = PLU_MINSELL, @allowPriceChange = PLU_ALLOW_PRICE_CHANGE
            FROM M_TBLPROMASTER p
            WHERE PLU_CODE = @createdPluCode AND
                PLU_RAWITEM=0 AND PLU_ACTIVE=1
            IF @@ROWCOUNT = 0
			-- if still cannot find product mean its maybe a varient code or batch code
			BEGIN
                SET @proMasterSearched = 0;
                SELECT @selling=IPLU_SELL, @sih = IPLU_SIH, @plucode = IPLU_CODE, @avgCost = IPLU_AVGCOST,
                    @stockCode=IPLU_PRODUCTCODE, @cost=IPLU_COST , @posDesc = IPLU_DESC, @specialPrice = IPLU_SPECIALPRICE, @posactive=IPLU_ACTIVE
                FROM M_TBLPROINVENTORY
                WHERE 
                (IPLU_PRODUCTCODE=@searchCode OR IPLU_PRODUCTCODE=@createdPluCode+'00000001')
                    AND IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1
                -- if still product is not found means its lost
                IF @@ROWCOUNT=0
                BEGIN
                    SET @status='lost_product'
                END
				ELSE
				BEGIN
                    SET @inventorySearched = 1;
                END
            END
        END
    END

    IF @status IS NULL
    BEGIN
        IF @proMasterSearched = 0
        BEGIN
            SELECT @pluCode=PLU_CODE, @active= PLU_ACTIVE, @noDisc=PLU_NODISC, @caseSize=PLU_CS, @pluUnit=PLU_UNIT, @pluOpen = PLU_OPEN, @picture=PLU_PICTURE , @imageHash=PLU_PICTURE_HASH, @maxDisc=PLU_MAXDISCPER, @maxDiscAmt=PLU_MAXDISCAMT, @pluDecimal = PLU_DECIMAL, @minus=PLU_MINUSALLOW, @maxQty = PLU_ALLOWQTY, @exchangable=PLU_EXCHANGABLE, @vendorPlu=PLU_VENDORPLU, @posactive =PLU_POSACTIVE , @emptyBtCode=PLU_RETURN, @motherCode=PLU_STOCKCODE, @batchEnable=PLU_BATCHENABLE, @variantEnable=PLU_VARIANTANABLE, @isEmptyCode=PLU_EMPTY, @minSell = PLU_MINSELL, @allowPriceChange = PLU_ALLOW_PRICE_CHANGE
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
        SELECT @volume=UM_VOLUME
        FROM M_TBLUNITS u
        WHERE u.UM_CODE = @pluUnit
        SELECT @maxQty=a.VL_TOTALCAPACITY, @maxQtyGrp=a.VL_GROUPCODE, @maxQtyGrpLvl=a.VL_GROUPLEVEL
        FROM U_TBLMAXALLOWED a
        WHERE a.VL_GROUPCODE = (select GPLU_GROUPCODE3
        from M_TBLPROGROUPS
        where GPLU_CODE=@pluCode)
        --and a.VL_UOM= @pluUnit

        -- fetech inventory details
        IF @inventorySearched = 0 
        BEGIN
            SELECT @selling=IPLU_SELL, @sih = IPLU_SIH, @plucode = IPLU_CODE, @avgCost = IPLU_AVGCOST,
                @stockCode=IPLU_PRODUCTCODE,
                @cost=IPLU_COST, @posDesc = IPLU_DESC, @specialPrice = IPLU_SPECIALPRICE, @posactive=CAST(IPLU_ACTIVE AS BIT)
            FROM M_TBLPROINVENTORY
            WHERE IPLU_CODE=@pluCode
                AND IPLU_LOCCODE=@Loc AND IPLU_ACTIVE=1

            IF @hasSpecialPrice = 1 
			BEGIN
                SET @selling = @specialPrice
            END

            SELECT @stockCode SCAN_CODE, @pluCode as PLU_CODE, @posDesc  as  PLU_POSDESC, case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE, @active as  PLU_ACTIVE, @noDisc as PLU_NODISC, @selling as SELLING_PRICE, @sih as SIH,
                @caseSize as CASE_SIZE, @cost as PLU_COST, @avgCost as PLU_AVGCOST, @pluUnit as PLU_UNIT, @department PLU_DEPARTMENT, @subDepartment PLU_SUB_DEPARTMENT, @picture IMAGE_PATH, @pluDecimal as PLU_DECIMAL, @status as status, @pluOpen as PLU_OPEN, @imageHash PLU_PICTURE_HASH, @maxDisc PLU_MAXDISCPER, @maxDiscAmt PLU_MAXDISCAMT, @minus PLU_MINUSALLOW, @maxQty PLU_MAXVOLUME, @maxQtyGrp PLU_MAXVOLUME_GRP, @maxQtyGrpLvl PLU_MAXVOLUME_GRPLV, @volume PLU_VOLUME, @exchangable PLU_EXCHANGABLE, @vendorPlu PLU_VENDORPLU, @posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN, @variantEnable PLU_VARIANTANABLE, @batchEnable PLU_BATCHENABLE, isnull(@isEmptyCode,0) PLU_EMPTY, isNULL(@minSell, 0) PLU_MINSELL, isNULL(@allowPriceChange, 0) PLU_ALLOW_PRICE_CHANGE
        END

        IF @inventorySearched = 1
		BEGIN
            IF @hasSpecialPrice = 1 
			BEGIN
                SET @selling = @specialPrice
            END

            SELECT @stockCode SCAN_CODE, @pluCode as PLU_CODE, @posDesc  as  PLU_POSDESC, case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE, @active as  PLU_ACTIVE, @noDisc as PLU_NODISC, @selling as SELLING_PRICE, @sih as SIH,
                @caseSize as CASE_SIZE, @cost as PLU_COST, @avgCost as PLU_AVGCOST, @pluUnit as PLU_UNIT, @department PLU_DEPARTMENT, @subDepartment PLU_SUB_DEPARTMENT, @picture IMAGE_PATH, @pluDecimal as PLU_DECIMAL, @status as status, @pluOpen as PLU_OPEN, @imageHash PLU_PICTURE_HASH, @maxDisc PLU_MAXDISCPER, @maxDiscAmt PLU_MAXDISCAMT, @minus PLU_MINUSALLOW, @maxQty PLU_MAXVOLUME, @maxQtyGrp PLU_MAXVOLUME_GRP, @maxQtyGrpLvl PLU_MAXVOLUME_GRPLV, @volume PLU_VOLUME, @exchangable PLU_EXCHANGABLE, @vendorPlu PLU_VENDORPLU, @posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN, @variantEnable PLU_VARIANTANABLE, @batchEnable PLU_BATCHENABLE , isnull(@isEmptyCode,0) PLU_EMPTY, isNULL(@minSell, 0) PLU_MINSELL, isNULL(@allowPriceChange, 0) PLU_ALLOW_PRICE_CHANGE
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
            SELECT @selling=IPLU_SELL, @sih = IPLU_SIH, @plucode = IPLU_CODE, @avgCost = IPLU_AVGCOST,
                @stockCode=IPLU_PRODUCTCODE,
                @cost=IPLU_COST, @posDesc = IPLU_DESC, @specialPrice = IPLU_SPECIALPRICE, @posactive=CAST(IPLU_ACTIVE AS BIT)
            FROM M_TBLPROINVENTORY
            WHERE IPLU_CODE=@pluCode
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
        SELECT @stockCode SCAN_CODE, @pluCode as PLU_CODE, @posDesc  as  PLU_POSDESC, case when @pluCode <> @motherCode then @ActMotherCode else  @stockCode end as PLU_STOCKCODE, @active as  PLU_ACTIVE, @noDisc as PLU_NODISC, @selling as SELLING_PRICE, @sih as SIH, @caseSize as CASE_SIZE, @cost as PLU_COST, @avgCost as PLU_AVGCOST, @pluUnit as PLU_UNIT, @department PLU_DEPARTMENT, @subDepartment PLU_SUB_DEPARTMENT, @picture IMAGE_PATH, @pluDecimal as PLU_DECIMAL, @status as status, @pluOpen as PLU_OPEN, @imageHash PLU_PICTURE_HASH, @maxDisc PLU_MAXDISCPER, @maxDiscAmt PLU_MAXDISCAMT, @minus PLU_MINUSALLOW, @maxQty PLU_MAXVOLUME, @maxQtyGrp PLU_MAXVOLUME_GRP, @maxQtyGrpLvl PLU_MAXVOLUME_GRPLV, @volume PLU_VOLUME, @exchangable PLU_EXCHANGABLE, @vendorPlu PLU_VENDORPLU, @posactive PLU_POSACTIVE, @emptyBtCode PLU_RETURN, @variantEnable PLU_VARIANTANABLE, @batchEnable PLU_BATCHENABLE, isnull(@isEmptyCode,0) PLU_EMPTY, isNULL(@minSell, 0) PLU_MINSELL, isNULL(@allowPriceChange, 0) PLU_ALLOW_PRICE_CHANGE
    END
END
GO
----------------------------------------------------------------------------------------------------------------------------------