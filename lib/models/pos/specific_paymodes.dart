/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 10/11/22, 6:36 PM
 */
import 'package:checkout/extension/extensions.dart';

class SpecificPayModeRes {
  List<SpecificPayMode>? paymodes;
  bool? success;

  SpecificPayModeRes({this.paymodes, this.success});

  SpecificPayModeRes.fromJson(Map<String, dynamic> json) {
    if (json['paymodes'] != null) {
      paymodes = <SpecificPayMode>[];
      json['paymodes'].forEach((v) {
        paymodes!.add(new SpecificPayMode.fromJson(v));
      });
    }
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.paymodes != null) {
      data['paymodes'] = this.paymodes!.map((v) => v.toJson()).toList();
    }
    data['success'] = this.success;
    return data;
  }
}

class SpecificPayMode {
  String? proPPHCODE;
  String? proPPDCODE;
  double? proPMIN;
  double? proPMAX;
  double? proPDISCPER;
  List<PromoCardBin>? promoCardBin;

  SpecificPayMode(
      {this.proPPHCODE,
      this.proPPDCODE,
      this.proPMIN,
      this.proPMAX,
      this.proPDISCPER});

  SpecificPayMode.fromJson(Map<String, dynamic> json) {
    if (json['pB_CARDBIN'] != null) {
      promoCardBin = <PromoCardBin>[];
      json['pB_CARDBIN'].forEach((v) {
        promoCardBin!.add(new PromoCardBin.fromJson(v));
      });
    }
    proPPHCODE = json['proP_PHCODE'];
    proPPDCODE = json['proP_PDCODE'];
    proPMIN = json['proP_MIN']?.toString().parseDouble();
    proPMAX = json['proP_MAX']?.toString().parseDouble();
    proPDISCPER = json['proP_DISCPER']?.toString().parseDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['proP_PHCODE'] = this.proPPHCODE;
    data['proP_PDCODE'] = this.proPPDCODE;
    data['proP_MIN'] = this.proPMIN;
    data['proP_MAX'] = this.proPMAX;
    data['proP_DISCPER'] = this.proPDISCPER;
    return data;
  }
}
class PromoCardBin {
  String? pBPROMOCODE;
  String? pBCARDBIN;

  PromoCardBin({this.pBPROMOCODE, this.pBCARDBIN});

  PromoCardBin.fromJson(Map<String, dynamic> json) {
    pBPROMOCODE = json['pB_PROMOCODE'];
    pBCARDBIN = json['pB_CARDBIN'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pB_PROMOCODE'] = this.pBPROMOCODE;
    data['pB_CARDBIN'] = this.pBCARDBIN;
    return data;
  }
}