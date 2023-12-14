/*
 * Copyright (c) 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 05/01/2022, 15:31
 */


import 'package:checkout/extension/extensions.dart';
class ProductPriceChanges {
  double? pRSPRICE;
  double? pRCPRICE;
  double? pRPPRICE;
  String? pRVENDOR;
  String? pRDATE;

  ProductPriceChanges(
      {this.pRSPRICE,
        this.pRCPRICE,
        this.pRPPRICE,
        this.pRVENDOR,
        this.pRDATE});

  ProductPriceChanges.fromJson(Map<String, dynamic> json) {
    pRSPRICE = json['pR_SPRICE']?.toString().parseDouble()??0;
    pRCPRICE = json['pR_CPRICE']?.toString().parseDouble()??0;
    pRPPRICE = json['pR_PPRICE']?.toString().parseDouble()??0;
    pRVENDOR = json['pR_VENDOR'];
    pRDATE = json['pR_DATE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pR_SPRICE'] = this.pRSPRICE;
    data['pR_CPRICE'] = this.pRCPRICE;
    data['pR_PPRICE'] = this.pRPPRICE;
    data['pR_VENDOR'] = this.pRVENDOR;
    data['pR_DATE'] = this.pRDATE;
    return data;
  }
}
