/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/25/22, 12:42 PM
 */
import 'package:checkout/extension/extensions.dart';

class ClientLicenseResult {
  bool? success;
  ClientLicense? license;
  String? message;

  ClientLicenseResult({this.success, this.license, this.message});

  ClientLicenseResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool();
    license = json['license'] != null
        ? new ClientLicense.fromJson(json['license'])
        : null;
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.license != null) {
      data['license'] = this.license!.toJson();
    }
    data['message'] = this.message;
    return data;
  }
}

class ClientLicense {
  String? lCNAME;
  bool? lCSTATUS;
  int? lCUSERS;
  int? lCLOCATIONS;
  int? lCPOS;
  String? lCPOSIMAGE;
  String? lCLICENSEKEY;
  String? lCREGISTERDATE;
  String? lCEXPIRYDATE;
  int? lCBILLINGCYCLE;
  bool? lCMYREWARDS;
  bool? lCMYOFFERS;
  bool? lCMYALERT;
  bool? lCMYVOUCHERS;
  bool? lCMYREPORTS;
  bool? lCMOBILEMAN;
  String? cRDATE;
  String? mDDATE;

  ClientLicense(
      {this.lCNAME,
      this.lCSTATUS,
      this.lCUSERS,
      this.lCLOCATIONS,
      this.lCPOS,
      this.lCPOSIMAGE,
      this.lCLICENSEKEY,
      this.lCREGISTERDATE,
      this.lCEXPIRYDATE,
      this.lCBILLINGCYCLE,
      this.lCMYREWARDS,
      this.lCMYOFFERS,
      this.lCMYALERT,
      this.lCMYVOUCHERS,
      this.lCMYREPORTS,
      this.lCMOBILEMAN,
      this.cRDATE,
      this.mDDATE});

  ClientLicense.fromJson(Map<String, dynamic> json) {
    lCNAME = json['lC_NAME'];
    lCSTATUS = json['lC_STATUS']?.toString().parseBool();
    lCUSERS = json['lC_USERS']?.toString().parseDouble().toInt();
    lCLOCATIONS = json['lC_LOCATIONS']?.toString().parseDouble().toInt();
    lCPOS = json['lC_POS']?.toString().parseDouble().toInt();
    lCPOSIMAGE = json['lC_POSIMAGE'];
    lCLICENSEKEY = json['lC_LICENSEKEY'];
    lCREGISTERDATE = json['lC_REGISTERDATE']?.toString();
    lCEXPIRYDATE = json['lC_EXPIRYDATE']?.toString();
    lCBILLINGCYCLE = json['lC_BILLINGCYCLE']?.toString().parseDouble().toInt();
    lCMYREWARDS = json['lC_MYREWARDS']?.toString().parseBool();
    lCMYOFFERS = json['lC_MYOFFERS']?.toString().parseBool();
    lCMYALERT = json['lC_MYALERT']?.toString().parseBool();
    lCMYVOUCHERS = json['lC_MYVOUCHERS']?.toString().parseBool();
    lCMYREPORTS = json['lC_MYREPORTS']?.toString().parseBool();
    lCMOBILEMAN = json['lC_MOBILEMAN']?.toString().parseBool();
    cRDATE = json['cR_DATE']?.toString();
    mDDATE = json['mD_DATE']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lC_NAME'] = this.lCNAME;
    data['lC_STATUS'] = this.lCSTATUS;
    data['lC_USERS'] = this.lCUSERS;
    data['lC_LOCATIONS'] = this.lCLOCATIONS;
    data['lC_POS'] = this.lCPOS;
    data['lC_POSIMAGE'] = this.lCPOSIMAGE;
    data['lC_LICENSEKEY'] = this.lCLICENSEKEY;
    data['lC_REGISTERDATE'] = this.lCREGISTERDATE;
    data['lC_EXPIRYDATE'] = this.lCEXPIRYDATE;
    data['lC_BILLINGCYCLE'] = this.lCBILLINGCYCLE;
    data['lC_MYREWARDS'] = this.lCMYREWARDS;
    data['lC_MYOFFERS'] = this.lCMYOFFERS;
    data['lC_MYALERT'] = this.lCMYALERT;
    data['lC_MYVOUCHERS'] = this.lCMYVOUCHERS;
    data['lC_MYREPORTS'] = this.lCMYREPORTS;
    data['lC_MOBILEMAN'] = this.lCMOBILEMAN;
    data['cR_DATE'] = this.cRDATE;
    data['mD_DATE'] = this.mDDATE;
    return data;
  }
}
