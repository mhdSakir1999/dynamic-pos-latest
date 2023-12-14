/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/14/21, 12:03 PM
 */
import 'package:checkout/extension/extensions.dart';

class LoyaltySummary {
  double? pOINTADDED;
  double? pOINTDEDUCTED;
  double? pOINTSUMMARY;
  String? lASTVISIT;
  double? tOTALBILL;
  double? aVGBILL;
  double? mAXBILL;
  double? lastBillAdded;
  double? lastBillDeducted;

  LoyaltySummary(
      {this.pOINTADDED,
      this.pOINTDEDUCTED,
      this.pOINTSUMMARY,
      this.lASTVISIT,
      this.tOTALBILL,
      this.aVGBILL,
      this.mAXBILL});

  LoyaltySummary.fromJson(Map<String, dynamic> json) {
    pOINTADDED = json['poinT_ADDED']?.toString().parseDouble() ?? 0;
    pOINTDEDUCTED = json['poinT_DEDUCTED']?.toString().parseDouble() ?? 0;
    pOINTSUMMARY = json['poinT_SUMMARY']?.toString().parseDouble() ?? 0;
    lASTVISIT = json['lasT_VISIT'];
    tOTALBILL = json['totaL_BILL']?.toString().parseDouble() ?? 0;
    aVGBILL = json['avG_BILL']?.toString().parseDouble() ?? 0;
    mAXBILL = json['maX_BILL']?.toString().parseDouble() ?? 0;
    lastBillDeducted = json['lasT_BILL_DEDUCTED']?.toString().parseDouble() ?? 0;
    lastBillAdded = json['lasT_BILL_ADDED']?.toString().parseDouble() ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['POINT_ADDED'] = this.pOINTADDED;
    data['POINT_DEDUCTED'] = this.pOINTDEDUCTED;
    data['POINT_SUMMARYS'] = this.pOINTSUMMARY;
    data['LAST_VISIT'] = this.lASTVISIT;
    data['TOTAL_BILL'] = this.tOTALBILL;
    data['AVG_BILL'] = this.aVGBILL;
    data['MAX_BILL'] = this.mAXBILL;
    return data;
  }
}
