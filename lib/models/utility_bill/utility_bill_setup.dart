/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/1/22, 3:24 PM
 */
import 'package:checkout/extension/extensions.dart';

class UtilityBillSetupResult {
  bool? success;
  List<UtilityBillSetup>? utilityBillSetup;
  String? message;

  UtilityBillSetupResult({this.success, this.utilityBillSetup, this.message});

  UtilityBillSetupResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool();
    if (json['utility_bill_setup'] != null) {
      utilityBillSetup = <UtilityBillSetup>[];
      json['utility_bill_setup'].forEach((v) {
        utilityBillSetup!.add(new UtilityBillSetup.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.utilityBillSetup != null) {
      data['utility_bill_setup'] =
          this.utilityBillSetup!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class UtilityBillSetup {
  int? uBNO;
  String? uBTYPE;
  String? uBCODE;
  String? uBDESC;
  bool? uBAUTHORIZE;
  String? uBOK;
  String? uBCANCEL;
  String? uBENDPOINT;
  String? uBINVMODE;

  UtilityBillSetup(
      {this.uBNO,
      this.uBTYPE,
      this.uBCODE,
      this.uBDESC,
      this.uBAUTHORIZE,
      this.uBOK,
      this.uBCANCEL,
      this.uBENDPOINT});

  UtilityBillSetup.fromJson(Map<String, dynamic> json) {
    uBNO = json['uB_NO']?.toString().parseDouble().toInt();
    uBTYPE = json['uB_TYPE'];
    uBCODE = json['uB_CCODE'];
    uBDESC = json['uB_DESC'];
    uBAUTHORIZE = json['uB_AUTHORIZE']?.toString().parseBool();
    uBOK = json['uB_OK'];
    uBCANCEL = json['uB_CANCEL'];
    uBENDPOINT = json['uB_ENDPOINT'];
    uBINVMODE = json['uB_INVMODE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uB_NO'] = this.uBNO;
    data['uB_TYPE'] = this.uBTYPE;
    data['uB_CODE'] = this.uBCODE;
    data['uB_DESC'] = this.uBDESC;
    data['uB_AUTHORIZE'] = this.uBAUTHORIZE;
    data['uB_OK'] = this.uBOK;
    data['uB_CANCEL'] = this.uBCANCEL;
    data['uB_ENDPOINT'] = this.uBENDPOINT;
    return data;
  }
}
