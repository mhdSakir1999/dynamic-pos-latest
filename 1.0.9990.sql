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