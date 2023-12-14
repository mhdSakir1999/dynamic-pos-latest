/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/14/22, 3:25 PM
 */

class TransactionModeResult {
  bool? success;
  List<TransactionModes>? modes;
  String? message;

  TransactionModeResult({this.success, this.modes, this.message});

  TransactionModeResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['modes'] != null) {
      modes = <TransactionModes>[];
      json['modes'].forEach((v) {
        modes!.add(new TransactionModes.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.modes != null) {
      data['modes'] = this.modes!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class TransactionModes {
  String? tXTYPE;
  String? tXDESC;
  String? tXMENUITEM;
  String? tXHEADERTABLE;
  String? tXDETAILTABLE;

  TransactionModes(
      {this.tXTYPE,
        this.tXDESC,
        this.tXMENUITEM,
        this.tXHEADERTABLE,
        this.tXDETAILTABLE});

  TransactionModes.fromJson(Map<String, dynamic> json) {
    tXTYPE = json['tX_TYPE'];
    tXDESC = json['tX_DESC'];
    tXMENUITEM = json['tX_MENUITEM'];
    tXHEADERTABLE = json['tX_HEADERTABLE'];
    tXDETAILTABLE = json['tX_DETAILTABLE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tX_TYPE'] = this.tXTYPE;
    data['tX_DESC'] = this.tXDESC;
    data['tX_MENUITEM'] = this.tXMENUITEM;
    data['tX_HEADERTABLE'] = this.tXHEADERTABLE;
    data['tX_DETAILTABLE'] = this.tXDETAILTABLE;
    return data;
  }
}
