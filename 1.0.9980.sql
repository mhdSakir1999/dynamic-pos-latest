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

select @OpCash = isnull(UH_FLOAT,0) from U_TBLUSERHEAD where UH_ID=@cashier and UH_SHIFTNO=@shift and UH_STATION=@station and UH_SIGNLOC=@location

select @Sales=SUM(INVPAY_PAIDAMOUNT) 
from T_TBLINVHEADER inner join T_TBLINVPAYMENTS on INVHED_LOCCODE=INVPAY_LOCCODE and INVHED_INVNO=INVPAY_INVNO and INVHED_MODE=INVPAY_MODE 
where INVHED_LOCCODE=@location and INVHED_INVOICED=1 and INVHED_CANCELED=0 and INVHED_MODE<>'REC' AND INVHED_MODE<>'WIT' AND INVHED_STATION=@station AND INVHED_CASHIER=@cashier AND 
INVHED_SHITNO= @shift AND INVPAY_PHCODE='CSH' and INVHED_SIGNONDATE=(select UH_SIGNONDATE from U_TBLUSERHEAD where UH_ID=@cashier)

select @CashIn=SUM(INVPAY_PAIDAMOUNT) 
from T_TBLINVHEADER inner join T_TBLINVPAYMENTS on INVHED_LOCCODE=INVPAY_LOCCODE and INVHED_INVNO=INVPAY_INVNO and INVHED_MODE=INVPAY_MODE 
where INVHED_LOCCODE=@location and INVHED_INVOICED=1 and INVHED_CANCELED=0 and INVHED_MODE = 'REC' AND INVHED_STATION=@station AND INVHED_CASHIER=@cashier AND 
INVHED_SHITNO= @shift AND INVPAY_PHCODE='CSH' and INVHED_SIGNONDATE=(select UH_SIGNONDATE from U_TBLUSERHEAD where UH_ID=@cashier)

select @CashOut=SUM(INVPAY_PAIDAMOUNT) 
from T_TBLINVHEADER inner join T_TBLINVPAYMENTS on INVHED_LOCCODE=INVPAY_LOCCODE and INVHED_INVNO=INVPAY_INVNO and INVHED_MODE=INVPAY_MODE 
where INVHED_LOCCODE=@location and INVHED_INVOICED=1 and INVHED_CANCELED=0 AND INVHED_MODE='WIT' AND INVHED_STATION=@station AND INVHED_CASHIER=@cashier AND 
INVHED_SHITNO= @shift AND INVPAY_PHCODE='CSH' and INVHED_SIGNONDATE=(select UH_SIGNONDATE from U_TBLUSERHEAD where UH_ID=@cashier)

set @CurrentSale = isnull(@Sales,0) + isnull(@OpCash,0) + isNull(@CashIn,0)

select isnull(@CurrentSale,0) as Sales, isnull(@CashOut,0) as CashOuts

END
GO

---------------------------------------------