

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