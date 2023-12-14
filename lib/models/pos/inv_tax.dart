/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/20/22, 10:22 AM
 */

class InvTax {
  final String taxCode;
  final String productCode;
  final double grossAmount;
  final double taxAmount;
  final double taxPercentage;
  final double afterTax;
  final bool taxInc;
  final int lineNo;
  final int taxSeq;

  InvTax(
      {required this.taxCode,
      required this.productCode,
      required this.grossAmount,
      required this.taxAmount,
      required this.taxPercentage,
      required this.afterTax,
      required this.taxInc,
      required this.lineNo,required this.taxSeq});

  Map<String,dynamic> toJson() {
    return {
      'taxCode':taxCode,
      'productCode':productCode,
      'grossAmount':grossAmount,
      'taxAmount':taxAmount,
      'taxPercentage':taxPercentage,
      'afterTax':afterTax,
      'taxInc':taxInc,
      'lineNo':lineNo,
      'taxSeq':taxSeq,
    };
  }
}
