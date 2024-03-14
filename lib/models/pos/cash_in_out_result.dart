/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 7/10/21, 10:40 AM
 */
import 'package:checkout/extension/extensions.dart';

class CashInOutResult {
  bool? success;
  List<CashInOutType>? cashInOutType;

  CashInOutResult({this.success, this.cashInOutType});

  CashInOutResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    if (json['cash_in_out_type'] != null) {
      cashInOutType = [];
      json['cash_in_out_type'].forEach((v) {
        cashInOutType?.add(new CashInOutType.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.cashInOutType != null) {
      data['cash_in_out_type'] =
          this.cashInOutType?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CashInOutType {
  String? rWCODE;
  String? rWDESC;
  int? rWADVANCE;

  CashInOutType({this.rWCODE, this.rWDESC, this.rWADVANCE});

  CashInOutType.fromJson(Map<String, dynamic> json) {
    rWCODE = json['rW_CODE'];
    rWDESC = json['rW_DESC'];
    rWADVANCE = json['rW_ADVANCE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['rW_CODE'] = this.rWCODE;
    data['rW_DESC'] = this.rWDESC;
    data['rW_ADVANCE'] = this.rWADVANCE ?? 0;
    return data;
  }
}
