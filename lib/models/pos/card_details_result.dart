/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/18/21, 4:35 PM
 */

class CardDetailsResult {
  bool? success;
  List<CardDetails>? cardDetails;

  CardDetailsResult({this.success, this.cardDetails});

  CardDetailsResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['card_details'] != null) {
      cardDetails = [];
      json['card_details'].forEach((v) {
        cardDetails?.add(new CardDetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.cardDetails != null) {
      data['card_details'] = this.cardDetails?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CardDetails {
  String? crDHEDDESC;
  String? crDDETCODE;
  String? crDPROVIDER;
  String? crDHEDCODE;
  String? crDSTRING;

  CardDetails(
      {this.crDHEDDESC,
      this.crDDETCODE,
      this.crDPROVIDER,
      this.crDHEDCODE,
      this.crDSTRING});

  CardDetails.fromJson(Map<String, dynamic> json) {
    crDHEDDESC = json['crD_HEDDESC'];
    crDDETCODE = json['crD_DETCODE'];
    crDPROVIDER = json['crD_PROVIDER'];
    crDHEDCODE = json['crD_HEDCODE'];
    crDSTRING = json['crD_STRING'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['crD_HEDDESC'] = this.crDHEDDESC;
    data['crD_DETCODE'] = this.crDDETCODE;
    data['crD_PROVIDER'] = this.crDPROVIDER;
    data['crD_HEDCODE'] = this.crDHEDCODE;
    data['crD_STRING'] = this.crDSTRING;
    return data;
  }
}
