/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/14/22, 4:00 PM
 */

import 'package:checkout/extension/extensions.dart';
class TransactionHeaderResult {
  bool? success;
  List<TransactionHeader>? headers;
  String? message;

  TransactionHeaderResult({this.success, this.headers, this.message});

  TransactionHeaderResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['headers'] != null) {
      headers = <TransactionHeader>[];
      json['headers'].forEach((v) {
        headers!.add(new TransactionHeader.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.headers != null) {
      data['headers'] = this.headers!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class TransactionHeader {
  String? heDTYPE;
  String? heDRUNNO;
  String? heDCOMCODE;
  String? heDTIME;
  String? heDPROCDATE;
  String? heDCUSCODE;
  double? heDGROAMT;
  double? heDDISCPER;
  double? heDNETAMT;
  String? heDCRBY;
  bool? heDEDITABLE;

  TransactionHeader(
      {this.heDTYPE,
        this.heDRUNNO,
        this.heDCOMCODE,
        this.heDTIME,
        this.heDPROCDATE,
        this.heDCUSCODE,
        this.heDGROAMT,
        this.heDDISCPER,
        this.heDNETAMT,
        this.heDCRBY,
        this.heDEDITABLE});

  TransactionHeader.fromJson(Map<String, dynamic> json) {
    heDTYPE = json['heD_TYPE'];
    heDRUNNO = json['heD_RUNNO'];
    heDCOMCODE = json['heD_COMCODE'];
    heDTIME = json['heD_TIME'];
    heDPROCDATE = json['heD_PROCDATE'];
    heDCUSCODE = json['heD_CUSCODE'];
    heDGROAMT = json['heD_GROAMT']?.toString().parseDouble();
    heDDISCPER = json['heD_DISCPER']?.toString().parseDouble();
    heDNETAMT = json['heD_NETAMT']?.toString().parseDouble();
    heDCRBY = json['heD_CRBY'];
    heDEDITABLE = json['heD_EDITABLE']?.toString().parseBool();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['heD_TYPE'] = this.heDTYPE;
    data['heD_RUNNO'] = this.heDRUNNO;
    data['heD_COMCODE'] = this.heDCOMCODE;
    data['heD_TIME'] = this.heDTIME;
    data['heD_PROCDATE'] = this.heDPROCDATE;
    data['heD_CUSCODE'] = this.heDCUSCODE;
    data['heD_GROAMT'] = this.heDGROAMT;
    data['heD_DISCPER'] = this.heDDISCPER;
    data['heD_NETAMT'] = this.heDNETAMT;
    data['heD_CRBY'] = this.heDCRBY;
    data['heD_EDITABLE'] = this.heDEDITABLE;
    return data;
  }
}

