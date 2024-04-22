/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/21/21, 12:18 PM
 */

import 'package:checkout/extension/extensions.dart';
import 'package:intl/intl.dart';

class PaidModel {
  late DateTime paidDateTime = DateTime.now();
  late double paidAmount;
  late double amount;
  late bool canceled;
  late String pdCode;
  late String phCode;
  late String refNo;
  late bool isGv;
  double? frAmount;
  DateTime? selectedDate;
  double? rate;
  late double pointRate;
  String? phDesc;
  String? pdDesc;

  PaidModel(
      this.paidAmount,
      this.amount,
      this.canceled,
      this.pdCode,
      this.phCode,
      this.refNo,
      this.selectedDate,
      this.rate,
      this.phDesc,
      this.pdDesc,
      {this.isGv = false,
      this.pointRate = 0,
      this.frAmount});

  PaidModel.fromMap(Map<String, dynamic> map) {
    final tempDate = map['date_time'];
    try {
      paidDateTime = DateFormat().parse(tempDate);
    } on Exception catch (_) {
      paidDateTime = DateTime.now();
    }

    String? date = map['date']?.toString() ?? "";
    if (date.isEmpty) {
      date = null;
    }

    paidAmount = map['paid_amount']?.toString().parseDouble() ?? 0;
    amount = map['amount']?.toString().parseDouble() ?? 0;
    canceled = map['canceled']?.toString() == "true";
    pdCode = map['pd_code'];
    phCode = map['ph_code'];
    refNo = map['ref_no'];
    isGv = map['is_gv'];
    selectedDate = date?.toString().replaceAll(" ", "T").parseDateTime();
    rate = map['rate']?.toString().parseDouble() ?? 0;
    pointRate = map['point_rate']?.toString().parseDouble() ?? 0;
    phDesc = map['ph_desc'];
    pdDesc = map['pd_desc'];
    frAmount = map['framount'] ?? 0;

    // return new PaidModel(
    //   paidDateTime: map['paidDateTime'] as DateTime,
    //   paidAmount: map['paidAmount'] as double,
    //   amount: map['amount'] as double,
    //   canceled: map['canceled'] as bool,
    //   pdCode: map['pdCode'] as String,
    //   phCode: map['phCode'] as String,
    //   refNo: map['refNo'] as String,
    // );
  }

  Map<String, dynamic> toMap() {
    return {
      'paid_amount': this.paidAmount.toDouble(),
      'date_time': this.paidDateTime.toString(),
      'amount': this.amount.toDouble(),
      'canceled': this.canceled,
      'pd_code': this.pdCode,
      'ph_code': this.phCode,
      'ref_no': this.refNo,
      'is_gv': this.isGv,
      'date': this.selectedDate?.toString(),
      'rate': this.rate?.toDouble(),
      'point_rate': this.pointRate.toDouble(),
      'pd_desc': this.pdDesc,
      'ph_desc': this.phDesc,
      'framount': this.frAmount
    };
  }
}
