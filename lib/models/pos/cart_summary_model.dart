/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/15/21, 10:44 AM
 */

import 'package:checkout/models/pos/hed_remark_model.dart';
import 'package:checkout/models/pos/inv_tax.dart';

import 'package:checkout/extension/extensions.dart';

class CartSummaryModel {
  String invoiceNo;
  String startTime;
  int items;
  double qty;
  double subTotal;
  // price without header level deductions
  double? grossTotal;
  double? taxInc;
  double? taxExc;
  double? disTaxInc;
  double? disTaxExc;
  double? discPer;
  double? promoDiscount;
  double? promoDiscountPre;
  String? priceMode;
  String? priceModeDesc;
  String? customerCode;
  bool editable = false;
  String? refNo;
  //reference mode for transaction
  String? refMode;
  //identify hold invocie
  bool? recallHoldInv;
  List<InvTax> invTax = [];
  String? promoCode;
  String invMode;
  HedRemarkModel? hedRem;

  CartSummaryModel(
      {required this.invoiceNo,
      required this.items,
      required this.qty,
      required this.subTotal,
      this.discPer,
      required this.startTime,
      required this.priceMode,
      this.customerCode,
      this.editable = true,
      this.refMode,
      this.refNo,
      this.recallHoldInv,
      this.promoCode,
      this.invMode = "INV",
      this.hedRem});

  factory CartSummaryModel.fromMap(Map<String, dynamic> map) {
    return new CartSummaryModel(
        invoiceNo: map['INVOICE_NO']?.toString() ?? "",
        items: map['ITEMS']?.toString().parseDouble().toInt() ?? 0,
        qty: map['QTY']?.toString().parseDouble() ?? 0,
        subTotal: map['SUB_TOTAL']?.toString().parseDouble() ?? 0,
        discPer: map['DISCOUNT']?.toString().parseDouble() ?? 0,
        startTime: map['START_TIME']?.toString() ?? '',
        priceMode: map['PRICE_MODE']?.toString() ?? '',
        customerCode: map['MEMBER_CODE']?.toString() ?? '',
        editable: map['EDITABLE']?.toString().parseBool() ?? true,
        recallHoldInv: map['RECALL_HOLD_INV']?.toString().parseBool() ?? false,
        refMode: map['REF_MODE']?.toString() ?? '',
        refNo: map['REF_NO']?.toString() ?? '',
        invMode: map['INV_MODE']?.toString() ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'INVOICE_NO': this.invoiceNo,
      'ITEMS': this.items,
      'QTY': this.qty.toDouble(),
      'SUB_TOTAL': this.subTotal.toDouble(),
      'DISCOUNT': this.discPer?.toDouble() ?? 0,
      'PRICE_MODE': this.priceMode,
      'MEMBER_CODE': this.customerCode,
      'EDITABLE': this.editable,
      'REF_MODE': this.refMode,
      'REF_NO': this.refNo,
      'RECALL_HOLD_INV': this.recallHoldInv,
      'INV_MODE': this.invMode,
    };
  }
//    factory CartSummaryModel.fromMap(Map<String, dynamic> map) {
//     return new CartSummaryModel(
//         invoiceNo: map['invoicE_NO']?.toString() ?? "",
//         items: map['items']?.toString().parseDouble().toInt() ?? 0,
//         qty: map['qty']?.toString().parseDouble() ?? 0,
//         subTotal: map['suB_TOTAL']?.toString().parseDouble() ?? 0,
//         discPer: map['discount']?.toString().parseDouble() ?? 0,
//         startTime: map['starT_TIME']?.toString() ?? '',
//         priceMode: map['pricE_MODE']?.toString() ?? '',
//         customerCode: map['MEMBER_CODE']?.toString() ?? '');
//   }
}
