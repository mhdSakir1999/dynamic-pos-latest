/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/8/21, 2:54 PM
 */
import 'package:checkout/extension/extensions.dart';


class HoldHeaderResult {
  bool? success;
  List<HoldInvoiceHeaders>? holdInvoiceHeaders;

  HoldHeaderResult({this.success, this.holdInvoiceHeaders});

  HoldHeaderResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['hold_invoice_headers'] != null) {
      holdInvoiceHeaders = [];
      json['hold_invoice_headers'].forEach((v) {
        holdInvoiceHeaders?.add(new HoldInvoiceHeaders.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.holdInvoiceHeaders != null) {
      data['hold_invoice_headers'] =
          this.holdInvoiceHeaders?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class HoldInvoiceHeaders {
  String? invheDINVNO;
  String? invheDCASHIER;
  DateTime? invheDTIME;
  String? invheDMODE;
  double? invheDNETAMT;
  double? invheDDiscPer;
  double? invGroAmt;
  String? memberCode;
  String? priceMode;

  HoldInvoiceHeaders(
      {this.invheDINVNO,
      this.invheDCASHIER,
      this.invheDTIME,
      this.invheDMODE,
      this.invheDNETAMT,
      this.invheDDiscPer,this.priceMode});

  HoldInvoiceHeaders.fromJson(Map<String, dynamic> json) {
    invheDINVNO = json['invheD_INVNO'];
    invheDCASHIER = json['invheD_CASHIER'];
    memberCode = json['invheD_MEMBER'];
    invheDTIME =
        json['invheD_TIME']?.toString().parseDateTime() ?? DateTime.now();
    invheDMODE = json['invheD_MODE'];
    invheDNETAMT =
        json['invheD_NETAMT']?.toString().parseDouble() ?? 0;
    invheDDiscPer =
        json['invheD_DISPER']?.toString().parseDouble() ?? 0;
    invGroAmt = json['invheD_GROAMT']?.toString().parseDouble() ?? 0;
    priceMode = json['invheD_PRICEMODE']?.toString()??'';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['invheD_INVNO'] = this.invheDINVNO;
    data['invheD_CASHIER'] = this.invheDCASHIER;
    data['invheD_TIME'] = this.invheDTIME;
    data['invheD_MODE'] = this.invheDMODE;
    data['invheD_NETAMT'] = this.invheDNETAMT;
    return data;
  }
}
