/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/27/21, 1:48 PM
 */
import 'package:checkout/extension/extensions.dart';

/// This class contains the all available payment mode in the app
class PayModeResult {
  bool? success;
  List<PayModeHeader>? payModes;

  PayModeResult({this.success, this.payModes});

  PayModeResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    if (json['pay_modes'] != null) {
      payModes = [];
      json['pay_modes'].forEach((v) {
        payModes?.add(new PayModeHeader.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.payModes != null) {
      data['pay_modes'] = this.payModes?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PayModeHeader {
  String? pHCODE;
  String? pHDESC;
  bool? pHDETAIL;
  bool? pHOVERPAY;
  bool? pHLINKCREDIT;
  bool? pHLINKLOYALTY;
  bool? pHLINKPROMO;
  bool? isGv;
  bool? showInSignOff;
  bool? defaultPaymentMode;
  String? apiSp;
  String? reference;
  double? pointRate;
  bool? pHLOCALMODE;
  bool? pHLINKADVANCE;
  bool? pHQRPAY;
  bool? pHCASHINOUT;
  List<PayModeDetails>? pDDETAILSLIST;

  PayModeHeader(
      {this.pHCODE,
      this.pHDESC,
      this.pHDETAIL,
      this.pHOVERPAY,
      this.pHLINKCREDIT,
      this.pHLINKLOYALTY,
      this.reference,
      this.pHLOCALMODE,
      this.pHLINKADVANCE,
      this.pHQRPAY,
      this.pHCASHINOUT,
      this.pDDETAILSLIST});

  PayModeHeader.fromJson(Map<String, dynamic> json) {
    pHCODE = json['pH_CODE'];
    pHDESC = json['pH_DESC'];
    reference = json['pH_REFERENCE'];
    pHDETAIL = json['pH_DETAIL']?.toString().parseBool() ?? false;
    pHOVERPAY = json['pH_OVERPAY']?.toString().parseBool() ?? false;
    pHLINKCREDIT = json['pH_LINKCREDIT']?.toString().parseBool() ?? false;
    pHLINKLOYALTY = json['pH_LINKLOYALTY']?.toString().parseBool() ?? false;
    pHLINKPROMO = json['pH_LINKPROMO']?.toString().parseBool() ?? false;
    defaultPaymentMode = json['pH_DEFAULT']?.toString().parseBool() ?? false;
    pHLOCALMODE = json['pH_LOCALMODE']?.toString().parseBool() ?? false;
    if (json['pD_DETAILS_LIST'] != null) {
      pDDETAILSLIST = [];
      json['pD_DETAILS_LIST'].forEach((v) {
        pDDETAILSLIST?.add(new PayModeDetails.fromJson(v));
      });
    }
    isGv = json['pH_LINKGV']?.toString().parseBool() ?? false;
    showInSignOff = json['pH_SW_SIGNOFF']?.toString().parseBool() ?? false;
    apiSp = json['pH_APISP']?.toString();
    pointRate = json['pH_POINTSPER']?.toString().parseDouble() ?? 0;
    pHLINKADVANCE = json['pH_LINKADVANCE']?.toString().parseBool() ?? false;
    pHQRPAY = json['pH_QRPAY']?.toString().parseBool() ?? false;
    pHCASHINOUT = json['pH_CASHINOUT'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['PH_CODE'] = this.pHCODE;
    data['PH_DESC'] = this.pHDESC;
    data['PH_DETAIL'] = this.pHDETAIL;
    data['PH_OVERPAY'] = this.pHOVERPAY;
    data['PH_LINKCREDIT'] = this.pHLINKCREDIT;
    data['PH_LINKLOYALTY'] = this.pHLINKLOYALTY;
    data['pH_LOCALMODE'] = this.pHLOCALMODE;
    data['pH_LINKADVANCE'] = this.pHLINKADVANCE;
    data['pH_QRPAY'] = this.pHQRPAY;
    if (this.pDDETAILSLIST != null) {
      data['PD_DETAILS_LIST'] =
          this.pDDETAILSLIST?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PayModeDetails {
  String? pDPHCODE;
  String? pDCODE;
  String? pDDESC;
  double? pDRATE;
  String? pdMask;
  bool? pDREQDATE;

  PayModeDetails(
      {this.pDPHCODE,
      this.pDCODE,
      this.pDDESC,
      this.pDRATE,
      this.pdMask,
      this.pDREQDATE});

  PayModeDetails.fromJson(Map<String, dynamic> json) {
    pDPHCODE = json['pD_PHCODE'];
    pDCODE = json['pD_CODE'];
    pDDESC = json['pD_DESC'];
    pdMask = json['pD_MASK'];
    pDREQDATE = json['pD_REQDATE']?.toString().parseBool() ?? false;
    pDRATE = json['pD_RATE']?.toString().parseDouble() ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['PD_PHCODE'] = this.pDPHCODE;
    data['PD_CODE'] = this.pDCODE;
    data['PD_DESC'] = this.pDDESC;
    data['PD_RATE'] = this.pDRATE;
    return data;
  }
}
