/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/4/21, 8:50 AM
 */

class PermissionCode {
  static const overrideDiscount = "P00016";
  static const lineDiscount = "P00177";
  static const billHold = "P00005";
  static const billRecall = "P00005";
  static const invoiceReprint = "P00114";
  static const invoiceDiscount = "P00014";
  static const invoiceCancellation = "P00012";
  static const itemVoid = "P00008";
  static const productSearch = "P00146";
  static const eod = "P00021";
  static const cashIn = "P00006";
  static const cashOut = "P00007";
  static const cashRefund = "P00009";
  static const salesReturn = "P00106";
  static const customerMaster = "C00060";
  static const stockBypass = "P00126";
  static const spotCheck = "P00200";
  static const bypassHoldInvAtSignOff = "P00199";
  static const openCashDrawer = "P00134";
  static const generateExchangeVoucher = 'P00136';
  static const acceptExpiredVouchers = 'P00193';
  static const giftVoucherSalesReturn = 'P00158';
  static const giftVoucherRedeem = 'P01005';
  static const giftVoucherSales = 'P01006';
  static const byPassEodTimeframe = 'P01007';
  static const viewLocationWiseStock = 'P01008';
  static const creditSales = 'P00018';
  static const byPassCreditValidation = 'P00155';
  static const resetPOSScreenWithItems = 'P00153';
  static const temporarySignOn = 'P00129';
  static const disconnectedMode = 'P00011';
  static const skipOrgInvInTReturns = 'P00150';
  static const skipOtpForRegistration = 'P00201';
}
