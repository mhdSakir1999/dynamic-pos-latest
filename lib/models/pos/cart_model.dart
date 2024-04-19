/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/15/21, 9:10 AM
 */

import 'dart:convert';

import 'package:checkout/models/pos/promotion_free_items.dart';
import 'package:checkout/models/pos_config.dart';

import 'package:checkout/extension/extensions.dart';

import 'pro_tax.dart';

class CartModel {
  late String key;
  final String setUpLocation;
  final String locCode = POSConfig().locCode;
  final String comCode = POSConfig().comCode;
  int? lineNo;
  bool? allowMinus;
  String? saleman;
  bool? itemVoid;
  String proCode;
  String stockCode;
  final String posDesc;
  String? proUnit;
  int? proCaseSize;
  double? proCost;
  final double proSelling;
  double? proAvgCost;
  double selling;
  double? discPer;
  double? discAmt;
  double? billDiscPer;
  double? billDiscAmt;
  double? caseQty;
  double unitQty;
  double? caseFreeQty;
  double? unitFreeQty;
  double amount;
  double? freeQty;
  bool noDisc;
  final String scanBarcode;
  String? image;
  String? discountReason;
  DateTime? dateTime;
  bool? isVoucher;
  double? maxDiscAmt;
  double? maxDiscPer;
  List<String> lineRemark = [];
  String? maxVolumeGroup;
  String? maxVolumeGroupLvl;
  double? volume;
  double? maxVolume;
  double? promoDiscAmt;
  double? promoDiscPre;
  double? promoBillDiscPre;
  String? promoCode;
  String? promoDesc;
  double? promoFreeQty;
  String? promoOriginalItem;
  String? priceMode;
  double? promoDiscValue;

  bool? varientEnabled;
  bool? batchEnabled;

  bool? userAllowedMinus;

  bool? isTaxCalculated;

  /// this is used for fixed price items
  bool? allowDiscount;
  bool? allowLoyalty;
  List<ProTax> proTax = [];
  List<PromotionFreeItemDetails> promoFreeItems = [];
  List<PromotionFreeGVs> promoFreeGVs = [];

  factory CartModel.fromMap(Map<String, dynamic> map) {
    List<dynamic> dyPromoFreeItems = [];
    List<PromotionFreeGVs> dyPromoFreeGVs = [];
    if (map['promO_FREE_ITEMS'] != null) {
      dyPromoFreeItems = map['promO_FREE_ITEMS'];
    }
    if (map['promO_FREE_GVS'] != null) {
      dyPromoFreeGVs = map['promO_FREE_GVS'];
    }
    // List<dynamic> dyLineRemarks = [];
    // if(map['linE_REMARK'] != null){
    // dyLineRemarks = map['linE_REMARK'];
    // }
    return new CartModel(
      setUpLocation: map['setuP_LOCATION'] as String,
      lineNo: map['linE_NO'].toString().parseDouble().toInt(),
      saleman: map['saleman'] as String?,
      itemVoid: map['iteM_VOID']?.toString().parseBool() ?? false,
      isVoucher: map['iS_VOUCHER']?.toString().parseBool() ?? false,
      proCode: map['prO_CODE'] as String,
      stockCode: map['stocK_CODE'] as String,
      posDesc: map['poS_DESC'] as String,
      proUnit: map['prO_UNIT'] as String?,
      lineRemark: [],
      proCaseSize: map['prO_CASE_SIZE'].toString().parseDouble().toInt(),
      proCost: map['prO_COST']?.toString().parseDouble() ?? 0,
      proSelling: map['prO_SELLING']?.toString().parseDouble() ?? 0,
      proAvgCost: map['prO_AVG_COST']?.toString().parseDouble() ?? 0,
      selling: map['selling']?.toString().parseDouble() ?? 0,
      discPer: map['disC_PRE']?.toString().parseDouble() ?? 0,
      discAmt: map['disC_AMT']?.toString().parseDouble() ?? 0,
      billDiscPer: map['bilL_DISC_PRE']?.toString().parseDouble() ?? 0,
      billDiscAmt: map['bilL_DISC_AMT']?.toString().parseDouble() ?? 0,
      caseQty: map['casE_QTY']?.toString().parseDouble() ?? 0,
      unitQty: map['uniT_QTY']?.toString().parseDouble() ?? 0,
      caseFreeQty: map['casE_FREE_QTY']?.toString().parseDouble() ?? 0,
      unitFreeQty: map['uniT_FREE_QTY']?.toString().parseDouble() ?? 0,
      amount: map['amount']?.toString().parseDouble() ?? 0,
      freeQty: map['freE_QTY']?.toString().parseDouble() ?? 0,
      noDisc: map['nO_DISC']?.toString().parseBool() ?? false,
      scanBarcode: map['scaN_BARCODE'] as String,
      discountReason: map['invdeT_DISTYPE'] as String,
      maxDiscAmt: map['maxdisC_AMT']?.toString().parseDouble() ?? 0,
      //maxdisC_PER
      maxDiscPer:
          map['maxdisC_PER']?.toString().parseDouble() ?? 0, //maxdisC_AMT
    )
      ..key = map["temP_KEY"].toString()
      ..dateTime =
          map["datE_TIME"]?.toString().replaceAll(' ', 'T').parseDateTime()
      ..image =
          POSConfig().posImageServer + "images/products/${map['prO_CODE']}.png"
      ..promoBillDiscPre =
          map['promO_BILL_DISC_PRE']?.toString().parseDouble() ?? 0
      ..promoDiscAmt = map['promO_DISCAMT']?.toString().parseDouble() ?? 0
      ..promoDiscPre = map['promO_DISCPER']?.toString().parseDouble() ?? 0
      ..promoFreeQty = map['promO_FREE_ITEM_QTY']?.toString().parseDouble() ?? 0
      ..promoCode = map['promO_CODE']?.toString() ?? ""
      ..promoDesc = map["promO_DESC"]?.toString() ?? ''
      ..promoFreeItems = dyPromoFreeItems
          .map((e) => PromotionFreeItemDetails.fromMap(e))
          .toList()
      ..promoFreeGVs = dyPromoFreeGVs
      ..promoDiscValue = map['promO_DISC_VALUE']?.toString().parseDouble() ?? 0;
  }

  factory CartModel.fromLocalMap(Map<String, dynamic> map) {
    List<ProTax> tax = [];
    if (map['TAX'] != null && map['TAX'].toString().isNotEmpty) {
      List<dynamic> dyTax = jsonDecode(utf8.decode(base64.decode(map['TAX'])));
      print(jsonDecode(utf8.decode(base64.decode(map['TAX']))));
      tax = dyTax.map((e) => ProTax.fromJson(e)).toList();
    }
    List<dynamic> dyLineRemarks = [];
    if (map['LINE_REMARK'] != null &&
        map['LINE_REMARK']
            .runtimeType
            .toString()
            .toLowerCase()
            .contains('list')) {
      dyLineRemarks = map['LINE_REMARK'];
    }
    return new CartModel(
      setUpLocation: map['SETUP_LOCATION'] as String,
      lineNo: map['LINE_NO'].toString().parseDouble().toInt(),
      saleman: map['SALEMAN'] as String?,
      itemVoid: map['ITEM_VOID']?.toString().parseBool() ?? false,
      isVoucher: map['IS_VOUCHER']?.toString().parseBool() ?? false,
      allowDiscount: map['ALLOW_DISCOUNT']?.toString().parseBool() ?? true,
      allowLoyalty: map['ALLOW_LOYALTY']?.toString().parseBool() ?? true,
      proCode: map['PRO_CODE'] as String,
      priceMode: map['PRICE_MODE']?.toString(),
      stockCode: map['STOCK_CODE'] as String,
      posDesc: map['POS_DESC'] as String,
      proUnit: map['PRO_UNIT'] as String?,
      lineRemark: dyLineRemarks.map((e) => e.toString()).toList(),
      proCaseSize: map['PRO_CASE_SIZE'].toString().parseDouble().toInt(),
      proCost: map['PRO_COST']?.toString().parseDouble() ?? 0,
      proSelling: map['PRO_SELLING']?.toString().parseDouble() ?? 0,
      proAvgCost: map['PRO_AVG_COST']?.toString().parseDouble() ?? 0,
      selling: map['SELLING']?.toString().parseDouble() ?? 0,
      discPer: map['DISC_PRE']?.toString().parseDouble() ?? 0,
      discAmt: map['DISC_AMT']?.toString().parseDouble() ?? 0,
      billDiscPer: map['BILL_DISC_PRE']?.toString().parseDouble() ?? 0,
      billDiscAmt: map['BILL_DISC_AMT']?.toString().parseDouble() ?? 0,
      caseQty: map['CASE_QTY']?.toString().parseDouble() ?? 0,
      unitQty: map['UNIT_QTY']?.toString().parseDouble() ?? 0,
      caseFreeQty: map['CASE_FREE_QTY']?.toString().parseDouble() ?? 0,
      unitFreeQty: map['UNIT_FREE_QTY']?.toString().parseDouble() ?? 0,
      amount: map['AMOUNT']?.toString().parseDouble() ?? 0,
      freeQty: map['FREE_QTY']?.toString().parseDouble() ?? 0,
      noDisc: map['NO_DISC']?.toString().parseBool() ?? false,
      scanBarcode: map['SCAN_BARCODE']?.toString() ?? '',
      discountReason: map['INVDET_DISTYPE']?.toString(),
      maxDiscAmt: map['MAXDISC_AMT']?.toString().parseDouble() ?? 0,
      //maxdisC_PER
      maxDiscPer: map['MAXDISC_PER']?.toString().parseDouble() ?? 0,
      //maxdisC_AMT
      volume: map['PLU_VOLUME']?.toString().parseDouble() ?? 0,
      //
      maxVolume: map['PLU_MAXVOLUME']?.toString().parseDouble() ?? 0,
      //
      maxVolumeGroupLvl: map['PLU_MAXVOLUME_GRPLV']?.toString(),
      //maxdisC_AMT
      maxVolumeGroup: map['PLU_MAXVOLUME_GRP']?.toString(),
    )
      ..key = map["TEMP_KEY"].toString()
      ..dateTime =
          map["DATE_TIME"]?.toString().replaceAll(' ', 'T').parseDateTime()
      ..image =
          POSConfig().posImageServer + "images/products/${map['prO_CODE']}.png"
      ..proTax = tax
      ..promoBillDiscPre =
          map['PROMO_BILL_DISC_PRE']?.toString().parseDouble() ?? 0
      ..promoDiscAmt = map['PROMO_DISC_AMT']?.toString().parseDouble() ?? 0
      ..promoDiscPre = map['PROMO_DISC_PRE']?.toString().parseDouble() ?? 0
      ..promoCode = map['PROMO_CODE']?.toString() ?? ""
      ..promoDesc = map["PROMO_DESC"]?.toString() ?? ''
      ..promoDiscPre = map['PROMO_DISC_VALUE']?.toString().parseDouble() ?? 0;
  }

  CartModel(
      {required this.setUpLocation,
      this.lineNo,
      this.saleman,
      this.itemVoid,
      required this.proCode,
      required this.stockCode,
      required this.posDesc,
      this.proUnit,
      required this.lineRemark,
      this.proCaseSize,
      this.proCost,
      required this.proSelling,
      this.proAvgCost,
      required this.selling,
      this.discPer,
      this.discAmt,
      this.billDiscPer,
      this.billDiscAmt,
      this.caseQty,
      required this.unitQty,
      this.caseFreeQty,
      this.unitFreeQty,
      required this.amount,
      this.freeQty,
      required this.noDisc,
      required this.scanBarcode,
      this.discountReason,
      this.isVoucher,
      required this.maxDiscPer,
      required this.maxDiscAmt,
      this.maxVolumeGroup,
      this.maxVolumeGroupLvl,
      this.volume,
      this.maxVolume,
      this.allowDiscount,
      this.priceMode,
      this.allowLoyalty,
      this.isTaxCalculated = false,
      this.batchEnabled,
      this.varientEnabled,
      this.userAllowedMinus,
      this.allowMinus,
      this.dateTime,
      this.promoDiscAmt,
      this.promoDiscPre});

  Map<String, dynamic> toMap() {
    return {
      'TEMP_KEY': this.key,
      'SETUP_LOCATION': this.setUpLocation,
      'LOC_CODE': this.locCode,
      'COM_CODE': this.comCode,
      'LINE_NO': this.lineNo,
      'SALEMAN': this.saleman ?? "",
      'ITEM_VOID': this.itemVoid ?? false,
      'PRO_CODE': this.proCode,
      'STOCK_CODE': this.stockCode,
      'POS_DESC': this.posDesc,
      'PRO_UNIT': this.proUnit,
      'PRO_CASE_SIZE': this.proCaseSize ?? 1,
      'PRO_COST': this.proCost?.toDouble() ?? 0,
      'PRO_SELLING': this.proSelling.toDouble(),
      'PRO_AVG_COST': this.proAvgCost?.toDouble() ?? 0,
      'SELLING': this.selling.toDouble(),
      'DISC_PRE': this.discPer?.toDouble() ?? 0,
      'DISC_AMT': this.discAmt?.toDouble() ?? 0,
      'BILL_DISC_PRE': this.billDiscPer?.toDouble() ?? 0,
      'BILL_DISC_AMT': this.billDiscAmt?.toDouble() ?? 0,
      'CASE_QTY': this.caseQty?.toDouble() ?? 0,
      'UNIT_QTY': this.unitQty.toDouble(),
      'CASE_FREE_QTY': this.caseFreeQty?.toDouble() ?? 0,
      'UNIT_FREE_QTY': this.unitFreeQty?.toDouble() ?? 0,
      'AMOUNT': this.amount.toDouble(),
      'FREE_QTY': this.freeQty?.toDouble() ?? 0,
      'NO_DISC': this.noDisc,
      'SCAN_BARCODE': this.scanBarcode,
      'INVDET_DISTYPE': this.discountReason,
      'DATE_TIME': dateTime?.toString(),
      'IS_VOUCHER': isVoucher ?? false,
      'MAXDISC_PER': maxDiscPer?.toDouble() ?? 0,
      'MAXDISC_AMT': maxDiscAmt?.toDouble() ?? 0,
      'PLU_VOLUME': volume?.toDouble() ?? 0,
      'PLU_MAXVOLUME': maxVolume?.toDouble() ?? 0,
      'LINE_REMARK': lineRemark, // wrong --
      // 'LINE_REMARK': lineRemark.map((e) => e.toString()).toList().first,
      'PLU_MAXVOLUME_GRP': maxVolumeGroup,
      'PLU_MAXVOLUME_GRPLV': maxVolumeGroupLvl,
      'PROMO_CODE': promoCode,
      'PROMO_DISC_AMT': promoDiscAmt,
      'PROMO_DISC_PRE': promoDiscPre,
      'PROMO_BILL_DISC_PRE': promoBillDiscPre,
      'TAX': base64.encode(
          utf8.encode(jsonEncode(proTax.map((e) => e.toJson()).toList()))),
      'PROMO_ORIGINAL_ITEM': promoOriginalItem,
      'PRICE_MODE': priceMode,
      'ALLOW_DISCOUNT': allowDiscount,
      'ALLOW_LOYALTY': allowLoyalty,
      'PROMO_DISC_VALUE': promoDiscValue,
      // 'LINE_REMARK': '' //not use in system
    };
  }
}
