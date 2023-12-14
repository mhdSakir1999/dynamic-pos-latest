/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 10/3/22, 4:39 PM
 */
import 'package:checkout/extension/extensions.dart';

class InvoiceLineRemarks{
  int? lineNo;
  String? lineRemark;


  InvoiceLineRemarks({this.lineNo, this.lineRemark});

  Map<String, dynamic> toMap() {
    return {
      'LINE_NO':lineNo,
      'LINE_REMARK':lineRemark
    };
  }
  factory InvoiceLineRemarks.fromMap(Map<String, dynamic> map) {
    return new InvoiceLineRemarks(
      lineNo:   map['linE_NO']?.toString().parseDouble().toInt()??0,
      lineRemark: map['linE_REMARK']
    );
  }
}
