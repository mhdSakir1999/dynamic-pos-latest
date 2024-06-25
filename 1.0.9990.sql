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