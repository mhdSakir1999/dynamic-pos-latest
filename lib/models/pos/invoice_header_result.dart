/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/25/21, 1:13 PM
 */
import 'package:checkout/extension/extensions.dart';


class InvoiceHeaderResult {
  bool? success;
  List<InvoiceHeader>? invoiceHeader;

  InvoiceHeaderResult({this.success, this.invoiceHeader});

  InvoiceHeaderResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    if (json['invoice_header'] != null) {
      invoiceHeader = [];
      json['invoice_header'].forEach((v) {
        invoiceHeader?.add(new InvoiceHeader.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.invoiceHeader != null) {
      data['invoice_header'] =
          this.invoiceHeader?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class InvoiceHeader {
  bool? invheDINVOICED;
  String? invheDMEMBER;
  String? invheDINVNO;
  String? invheDCASHIER;
  DateTime? invheDTIME;
  String? invheDMODE;
  double? invheDNETAMT;
  double? invheDDISPER;
  double? invGroAmt;

  InvoiceHeader(
      {this.invheDINVOICED,
      this.invheDMEMBER,
      this.invheDINVNO,
      this.invheDCASHIER,
      this.invheDTIME,
      this.invheDMODE,
      this.invheDNETAMT,
      this.invheDDISPER});

  InvoiceHeader.fromJson(Map<String, dynamic> json) {
    invheDINVOICED = json['invheD_INVOICED'];
    invheDMEMBER = json['invheD_MEMBER'];
    invheDINVNO = json['invheD_INVNO'];
    invheDCASHIER = json['invheD_CASHIER'];
    invheDTIME =
        json['invheD_TIME']?.toString().parseDateTime() ?? DateTime.now();
    invheDMODE = json['invheD_MODE'];
    invheDNETAMT = json['invheD_NETAMT']?.toString().parseDouble() ?? 0;
    invGroAmt = json['invheD_GROAMT']?.toString().parseDouble() ?? 0;
    invheDDISPER = json['invheD_DISPER']?.toString().parseDouble() ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['invheD_INVOICED'] = this.invheDINVOICED;
    data['invheD_MEMBER'] = this.invheDMEMBER;
    data['invheD_INVNO'] = this.invheDINVNO;
    data['invheD_CASHIER'] = this.invheDCASHIER;
    data['invheD_TIME'] = this.invheDTIME;
    data['invheD_MODE'] = this.invheDMODE;
    data['invheD_NETAMT'] = this.invheDNETAMT;
    data['invheD_DISPER'] = this.invheDDISPER;
    return data;
  }
}
