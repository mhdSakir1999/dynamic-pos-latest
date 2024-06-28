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
	INVHED_INVNO,INVHED_CASHIER,INVHED_TIME,INVHED_MODE,INVHED_NETAMT,INVHED_DISPER,INVHED_GROAMT,
	INVHED_INVOICED,INVHED_MEMBER,INVHED_PRICEMODE FROM T_TBLINVHEADER
	WHERE  INVHED_CASHIER = @cashier AND INVHED_CANCELED=0  and INVHED_DATETIME >= DATEADD(DAY, -7, GETDATE())
	
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
CREATE TABLE [dbo].[M_TBLCUSDISC_PARAMS](
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

    SELECT @code = CM_CODE FROM M_TBLCUSTOMER WHERE CM_MOBILE1 like '%' + @code OR CM_CODE=@code or CM_LINKREF=@code

    SELECT @totalCredit = SUM(INVHED_DUEAMT) FROM T_TBLINVHEADER WHERE INVHED_MEMBER = @code

    SELECT top(1) CM_CODE,CM_FULLNAME CM_NAME,CM_NIC,CG_DESC as CM_GROUP,CM_MOBILE1 CM_MOBILE,dbo.parseBool(CM_STATUS) CM_ACTIVE,dbo.parseBool(CM_LOYALTY) CM_LOYALTYACTIVE,CM_PHOTO CM_PICTURE,CM_AREA,AM_DESC as AREA_DESC,CM_ADD1,CM_ADD2,CM_EMAIL,CM_DOB,CM_GENDER,dbo.parseBool(CM_EBILL) CM_EBILL,CM_LOYGROUP,CM_TITLE,CM_CREDITLIMIT,convert(numeric,CM_CREDITPERIOD) CM_CREDITPERIOD,CM_GROUP CM_CUSGROUP,@totalCredit as TOTALCREDITS,CM_ANNIVERSARY,0 CM_INVCOUNT , ISNULL(CT_TAXREG,'') AS CT_TAXREG
    ,CG_NOPROMO, CG_OTP_REQUIRED,DS_DISC,ISNULL(CG_CAL_STAFF_DISC,0) AS CG_CAL_STAFF_DISC,isnull(DISC_MIN_DISC_PER,0) as DISC_MIN_DISC_PER,isnull(DISC_MIN_COST_VAR,0) as DISC_MIN_COST_VAR,isnull(DISC_MIN_SELLING_VAR,0) as DISC_MIN_SELLING_VAR
    FROM M_TBLCUSTOMER m
    LEFT JOIN M_TBLCUSGROUPS
    ON CM_GROUP=CG_CODE
    LEFT JOIN M_TBLAREA
    ON CM_AREA=AM_CODE
    LEFT OUTER JOIN (SELECT CT_CUSCODE,MAX(CT_TAXREG) AS CT_TAXREG FROM M_TBLCUSTAX GROUP BY CT_CUSCODE) TAX
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


    SELECT TOP 50 CM_CODE,CM_FULLNAME CM_NAME,CM_NIC,CG_DESC as CM_GROUP,CM_MOBILE1 CM_MOBILE,dbo.parseBool(CM_STATUS) CM_ACTIVE,dbo.parseBool(CM_LOYALTY) CM_LOYALTYACTIVE,CM_PHOTO CM_PICTURE,CM_AREA,AM_DESC AREA_DESC,CM_ADD1,CM_ADD2,CM_EMAIL,CM_DOB,CM_GENDER,dbo.parseBool(CM_EBILL) CM_EBILL,CM_LOYGROUP,CM_GROUP CM_CUSGROUP,CM_TITLE,100.00 CM_CREDITLIMIT,CONVERT(numeric,CM_CREDITPERIOD) CM_CREDITPERIOD,@totalCredit as TOTALCREDITS,0 CM_INVCOUNT,CM_ANNIVERSARY, ISNULL(CT_TAXREG,'') AS CT_TAXREG,
    CG_NOPROMO, CG_OTP_REQUIRED, DS_DISC,ISNULL(CG_CAL_STAFF_DISC,0) AS CG_CAL_STAFF_DISC,isnull(DISC_MIN_DISC_PER,0) as DISC_MIN_DISC_PER,isnull(DISC_MIN_COST_VAR,0) as DISC_MIN_COST_VAR,isnull(DISC_MIN_SELLING_VAR,0) as DISC_MIN_SELLING_VAR
    FROM M_TBLCUSTOMER m
    LEFT JOIN M_TBLCUSGROUPS
    ON CM_GROUP=CG_CODE
    LEFT JOIN M_TBLAREA
    ON CM_AREA=AM_CODE
    LEFT OUTER JOIN (SELECT CT_CUSCODE,MAX(CT_TAXREG) AS CT_TAXREG FROM M_TBLCUSTAX GROUP BY CT_CUSCODE) TAX
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

    select @grpLevel=isnull(SETUP_STAFFDISC_EXCL_GRP,0) from u_tblsetup

    if @grpLevel>0
    begin
        SELECT productCode INTO #Products FROM OPENJSON(@json)
                WITH ( productCode VARCHAR(15))
        
        set @sql = ' SELECT PLU_CODE, UPPER(ISNULL(GP_DESC,'''')) AS DISC_STATUS FROM M_TBLPROMASTER LEFT OUTER JOIN M_TBLGROUP' + cast(@grpLevel as varchar(2)) +' ON PLU_GROUP'+ cast(@grpLevel as varchar(2)) + '=GP_CODE WHERE PLU_CODE IN (SELECT productCode from #Products)';
        print @sql;
        exec(@sql);
    end
END

GO

------------------------------------------------------