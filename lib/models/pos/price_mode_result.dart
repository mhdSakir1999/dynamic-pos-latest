/*
 * Copyright (c) 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 06/01/2022, 14:50
 */

class PriceModeResult {
  bool? success;
  List<PriceModes>? priceModes;
  String? message;

  PriceModeResult({this.success, this.priceModes, this.message});

  PriceModeResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['price_modes'] != null) {
      priceModes = <PriceModes>[];
      json['price_modes'].forEach((v) {
        priceModes!.add(new PriceModes.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.priceModes != null) {
      data['price_modes'] = this.priceModes!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class PriceModes {
  String? prMCODE;
  String? prMDESC;
  bool? prMFIXED;
  bool? prMlinkWithSpecial;
  bool? allowDiscount;
  bool? allowLoyalty;

  PriceModes({this.prMCODE, this.prMDESC, this.prMFIXED});

  PriceModes.fromJson(Map<String, dynamic> json) {
    prMCODE = json['prM_CODE'];
    prMDESC = json['prM_DESC'];
    prMFIXED = json['prM_FIXED'];
    allowDiscount = json['prM_ALLOW_DISCOUNT'];
    allowLoyalty = json['prM_ALLOW_LOYALTYPOINTS'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['prM_CODE'] = this.prMCODE;
    data['prM_DESC'] = this.prMDESC;
    data['prM_FIXED'] = this.prMFIXED;
    return data;
  }
}
