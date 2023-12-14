/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/26/22, 5:22 PM
 */
import 'package:checkout/extension/extensions.dart';

class LocationWiseStockResult {
  bool? success;
  List<LocationStocks>? stocks;
  String? message;

  LocationWiseStockResult({this.success, this.stocks, this.message});

  LocationWiseStockResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool()??false;
    if (json['stocks'] != null) {
      stocks = <LocationStocks>[];
      json['stocks'].forEach((v) {
        stocks!.add(new LocationStocks.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.stocks != null) {
      data['stocks'] = this.stocks!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class LocationStocks {
  String? iplUCODE;
  String? loCDESC;
  double? iplUSIH;
  double? iplUSELL;

  LocationStocks({this.iplUCODE, this.loCDESC, this.iplUSIH, this.iplUSELL});

  LocationStocks.fromJson(Map<String, dynamic> json) {
    iplUCODE = json['iplU_CODE'];
    loCDESC = json['loC_DESC'];
    iplUSIH = json['iplU_SIH']?.toString().parseDouble()??0;
    iplUSELL = json['iplU_SELL']?.toString().parseDouble()??0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['iplU_CODE'] = this.iplUCODE;
    data['loC_DESC'] = this.loCDESC;
    data['iplU_SIH'] = this.iplUSIH;
    data['iplU_SELL'] = this.iplUSELL;
    return data;
  }
}
