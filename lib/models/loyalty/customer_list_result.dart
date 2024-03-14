/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/13/21, 2:23 PM
 */
import 'package:checkout/extension/extensions.dart';

// this list result will used  in the customer search view
class CustomerListResult {
  bool? success;
  List<CustomerResult>? customerList;

  CustomerListResult({this.success, this.customerList});

  CustomerListResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    if (json['customer_list'] != null) {
      customerList = [];
      json['customer_list'].forEach((v) {
        customerList?.add(new CustomerResult.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.customerList != null) {
      data['customer_list'] =
          this.customerList?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CustomerResult {
  String? cMCODE;
  String? cMNAME;
  String? cMNIC;
  String? cMGROUP;
  String? cMMOBILE;
  bool? cMACTIVE;
  bool? cMEBILL;
  bool? cMLOYALTY;
  String? cMPICTURE;
  String? cMAREA;
  String? aREADESC;
  String? cMADD1;
  String? cMADD2;
  String? cMEMAIL;
  String? cMDOB;
  String? gender;
  String? cusGroup;
  String? loyaltyGroup;
  String? title;
  double? creditLimit;
  double? creditPeriod;
  double? totalCredits;
  DateTime? anniversary;
  DateTime? birthDay;
  int? invoiceCount;
  String? taxRegNo;
  bool? noPromo;
  bool? sendOTP;
  double? defaultDiscount;

  CustomerResult(
      {this.cMCODE,
      this.cMNAME,
      this.cMNIC,
      this.cMGROUP,
      this.cMMOBILE,
      this.cMACTIVE,
      this.cMPICTURE,
      this.cMAREA,
      this.aREADESC,
      this.cMADD1,
      this.cMADD2,
      this.cMLOYALTY,
      this.gender,
      this.cMEMAIL,
      this.cMEBILL,
      this.birthDay,
      this.cMDOB,
      this.taxRegNo,
      this.noPromo,
      this.sendOTP,
      this.defaultDiscount});

  CustomerResult.fromJson(Map<String, dynamic> json) {
    cMCODE = json['cM_CODE'];
    cMNAME = json['cM_NAME'];
    cMNIC = json['cM_NIC'];
    cMGROUP = json['cM_GROUP'];
    cMMOBILE = json['cM_MOBILE'];
    cMACTIVE = json['cM_ACTIVE']?.toString().parseBool() ?? false;
    cMLOYALTY = json['cM_LOYALTYACTIVE']?.toString().parseBool() ?? false;
    gender = json['cM_GENDER'];
    cMPICTURE = json['cM_PICTURE'];
    cMAREA = json['cM_AREA'];
    aREADESC = json['areA_DESC'];
    cMADD1 = json['cM_ADD1'];
    cMADD2 = json['cM_ADD2'];
    cMEMAIL = json['cM_EMAIL'];
    cMDOB = json['cM_DOB'];
    anniversary = json['cM_ANNIVERSARY'].toString().parseDateTime();
    birthDay = json['cM_DOB'].toString().parseDateTime();
    cMEBILL = json['cM_EBILL']?.toString().parseBool() ?? false;
    loyaltyGroup = json['cM_LOYGROUP'];
    cusGroup = json['cM_CUSGROUP'];
    title = json['cM_TITLE'];
    creditLimit = json['cM_CREDITLIMIT']?.toString().parseDouble();
    creditPeriod = json['cM_CREDITPERIOD']?.toString().parseDouble();
    totalCredits = json['totalcredits']?.toString().parseDouble();
    invoiceCount = json['cM_INVCOUNT']?.toString().parseDouble().toInt();
    taxRegNo = json['cT_TAXREG'];
    noPromo = json['cG_NOPROMO'];
    sendOTP = json['cG_OTP_REQUIRED'];
    try {
      defaultDiscount = json['dS_DISC']?.toString().parseDouble() ?? 0;
    } catch (e) {
      defaultDiscount = 0;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['CM_CODE'] = this.cMCODE;
    data['CM_NAME'] = this.cMNAME;
    data['CM_NIC'] = this.cMNIC;
    data['CM_GROUP'] = this.cMGROUP;
    data['CM_MOBILE'] = this.cMMOBILE;
    data['CM_ACTIVE'] = this.cMACTIVE;
    data['CM_PICTURE'] = this.cMPICTURE;
    data['CM_AREA'] = this.cMAREA;
    data['AREA_DESC'] = this.aREADESC;
    data['CM_ADD1'] = this.cMADD1;
    data['CM_ADD2'] = this.cMADD2;
    data['CM_EMAIL'] = this.cMEMAIL;
    data['CM_DOB'] = this.cMDOB;
    return data;
  }
}
