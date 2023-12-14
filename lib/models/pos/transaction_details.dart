/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/14/22, 4:46 PM
 */
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos_config.dart';

class TransactionDetailsResults {
  bool? success;
  List<TransactionDetail>? details;
  String? message;

  TransactionDetailsResults({this.success, this.details, this.message});

  TransactionDetailsResults.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['details'] != null) {
      details = <TransactionDetail>[];
      json['details'].forEach((v) {
        details!.add(new TransactionDetail.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.details != null) {
      data['details'] = this.details!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class TransactionDetail {
  String? deTPROCODE;
  String? deTPRODESC;
  String? deTUNIT;
  int? deTCS;
  double? deTUNITQTY;
  double? deTSPRICE;
  double? deTCPRICE;
  double? deTAMOUNT;
  double? deTDISCAMT;
  double? deTDISCPER;
  String? deTSTOCKCODE;

  TransactionDetail(
      {this.deTPROCODE,
      this.deTPRODESC,
      this.deTUNIT,
      this.deTCS,
      this.deTUNITQTY,
      this.deTSPRICE,
      this.deTCPRICE,
      this.deTAMOUNT,
      this.deTDISCAMT,
      this.deTDISCPER,
      this.deTSTOCKCODE});

  TransactionDetail.fromJson(Map<String, dynamic> json) {
    deTPROCODE = json['deT_PROCODE'];
    deTPRODESC = json['deT_PRODESC'];
    deTUNIT = json['deT_UNIT'];
    deTCS = json['deT_CS']?.toString().parseDouble().toDouble().toInt();
    deTUNITQTY = json['deT_UNITQTY']?.toString().parseDouble();
    deTSPRICE = json['deT_SPRICE']?.toString().parseDouble();
    deTCPRICE = json['deT_CPRICE']?.toString().parseDouble();
    deTAMOUNT = json['deT_AMOUNT']?.toString().parseDouble();
    deTDISCAMT = json['deT_DISCAMT']?.toString().parseDouble();
    deTDISCPER = json['deT_DISCPER']?.toString().parseDouble();
    deTSTOCKCODE = json['deT_STOCKCODE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['deT_PROCODE'] = this.deTPROCODE;
    data['deT_PRODESC'] = this.deTPRODESC;
    data['deT_UNIT'] = this.deTUNIT;
    data['deT_CS'] = this.deTCS;
    data['deT_UNITQTY'] = this.deTUNITQTY;
    data['deT_SPRICE'] = this.deTSPRICE;
    data['deT_CPRICE'] = this.deTCPRICE;
    data['deT_AMOUNT'] = this.deTAMOUNT;
    data['deT_DISCAMT'] = this.deTDISCAMT;
    data['deT_DISCPER'] = this.deTDISCPER;
    data['deT_STOCKCODE'] = this.deTSTOCKCODE;
    return data;
  }

  CartModel toCartModel(DateTime time, int line) {
    String strkey = "";
    strkey = deTPROCODE ?? '';
    strkey += '-' + line.toStringAsFixed(0);

    final CartModel cartModel = CartModel(
        setUpLocation: POSConfig().setupLocation,
        proCode: deTPROCODE ?? '',
        stockCode: deTSTOCKCODE ?? '',
        posDesc: deTPRODESC ?? '',
        proSelling: deTSPRICE ?? 0,
        selling: deTSPRICE ?? 0,
        unitQty: deTUNITQTY ?? 0,
        amount: deTAMOUNT ?? 0,
        noDisc: true,
        scanBarcode: deTPROCODE ?? '',
        lineRemark: [],
        maxDiscPer: 0,
        maxDiscAmt: 0)
      ..proUnit = deTUNIT
      ..discAmt = deTDISCAMT
      ..discPer = deTDISCPER
      ..itemVoid = false
      ..dateTime = time
      ..lineNo = line
      ..key = strkey;

    return cartModel;
  }
}
