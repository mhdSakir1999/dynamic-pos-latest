/*
 * Copyright © 2021  myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 9/7/21, 2:05 PM
 * Description:
 */
import 'package:checkout/extension/extensions.dart';

class GiftVoucherResult {
  GiftVoucherResult({this.success, this.giftVoucher, this.message});

  GiftVoucherResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    giftVoucher = json['gift_voucher'] != null
        ? GiftVoucher.fromJson(json['gift_voucher'])
        : null;
    message = json['message'];
  }

  bool? success;
  GiftVoucher? giftVoucher;
  String? message;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (giftVoucher != null) {
      data['gift_voucher'] = giftVoucher?.toJson();
    }
    data['message'] = message;
    return data;
  }
}

class GiftVoucher {
  GiftVoucher({this.vCNO, this.vCDESC, this.vCVAlUE, this.vCERROR});

  GiftVoucher.fromJson(Map<String, dynamic> json) {
    vCNO = json['vC_NO'];
    vCDESC = json['vC_DESC'];
    vCVAlUE = json['vC_VAlUE']?.toString().parseDouble()??0;
    vCERROR = json['vC_ERROR'];
    expDays = json['vC_EXPDAYS']?.toString().parseDouble().toInt()??0;
    soldDate = json['vC_SOLDDATE']?.toString().parseDateTime()??DateTime.now();
    soldInv = json['vC_SOLDINVNO'];
    returnInv = json['vC_RETURNINVNO'];
    cancelInv = json['vC_CANINVNO'];
    redeemInv = json['vC_REDEEMINVNO'];
  }

  String? vCNO;
  String? vCDESC;
  double? vCVAlUE;
  String? vCERROR;
  String? soldInv;
  String? returnInv;
  String? cancelInv;
  String? redeemInv;
  int? expDays;
  DateTime? soldDate;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['vC_NO'] = vCNO;
    data['vC_DESC'] = vCDESC;
    data['vC_VAlUE'] = vCVAlUE;
    data['vC_ERROR'] = vCERROR;
    return data;
  }
}
