/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/2/21, 3:56 PM
 */

class LastInvoiceDetails {
  final String invoiceNo;
  final String billAmount;
  final String dueAmount;
  final String paidAmount;

  LastInvoiceDetails(
      {required this.invoiceNo,
      required this.billAmount,
      required this.dueAmount,
      required this.paidAmount});
}
