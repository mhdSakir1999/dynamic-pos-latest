/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/18/22, 4:50 PM
 */
import 'package:checkout/extension/extensions.dart';

class PromotionFreeItems {
  final List<PromotionFreeItemDetails> freeItemBundle;
  double remainingQty;
  final double totalQty;
  final String originalItemCode;
  final String bundleCode;
  final String promotionCode;
  final String promotionDesc;
  PromotionFreeItems(
      this.freeItemBundle,
      this.remainingQty,
      this.totalQty,
      this.originalItemCode,
      this.promotionCode,
      this.promotionDesc,
      this.bundleCode);
}

class PromotionFreeItemDetails {
  final String proCode;
  final String proDesc;
  double scannedQty = 0;

  PromotionFreeItemDetails({required this.proCode, required this.proDesc});

  factory PromotionFreeItemDetails.fromMap(Map<String, dynamic> map) {
    return new PromotionFreeItemDetails(
      proCode: map['pluCode']?.toString() ?? "",
      proDesc: map['pluDesc']?.toString() ?? "",
    );
  }
}

class PromotionFreeGVs {
  double remainingQty;
  final double totalQty;
  final String originalItemCode;
  final String promotionCode;
  final String promotionDesc;
  final double gvValue;
  final String gvName;
  double scannedQty = 0;
  List<String> gvCodes = [];
  PromotionFreeGVs(
      this.gvValue,
      this.remainingQty,
      this.totalQty,
      this.originalItemCode,
      this.promotionCode,
      this.promotionDesc,
      this.gvName);
}

class PromotionFreeTickets {
  final String ticketId;
  final String promotionCode;
  final String promotionDesc;
  final double ticketQty;
  final double ticketValue;
  final DateTime ticketRedeemFromDate;
  final DateTime ticketRedeemToDate;
  final double ticketRedeemFromVal;
  final double ticketRedeemToVal;
  final String ticketSerial;
  final String company;

  PromotionFreeTickets(
      this.ticketId,
      this.promotionCode,
      this.promotionDesc,
      this.ticketQty,
      this.ticketValue,
      this.ticketRedeemFromDate,
      this.ticketRedeemToDate,
      this.ticketRedeemFromVal,
      this.ticketRedeemToVal,
      this.ticketSerial,
      this.company);

  Map<String, dynamic> toMap() {
    return {
      'ticketId': this.ticketId,
      'promotionCode': this.promotionCode,
      'promotionDesc': this.promotionDesc,
      'ticketQty': this.ticketQty,
      'ticketValue': this.ticketValue,
      'ticketRedeemFromDate': this.ticketRedeemFromDate.toString(),
      'ticketRedeemToDate': this.ticketRedeemToDate.toString(),
      'ticketRedeemFromVal': this.ticketRedeemFromVal,
      'ticketRedeemToVal': this.ticketRedeemToVal,
      'ticketSerial': this.ticketSerial,
      'company': this.company,
    };
  }
}

class PromotionCoupon {
  late String promoCode;
  late String couponCode;
  late String couponDesc;
  late DateTime fromDate;
  late DateTime toDate;
  late double billValFrom;
  late double billValTo;
  late bool isRedeem;

  PromotionCoupon(
      {required this.promoCode,
      required this.couponCode,
      required this.couponDesc,
      required this.fromDate,
      required this.toDate,
      required this.billValFrom,
      required this.billValTo,
      required this.isRedeem});

  PromotionCoupon.fromJson(Map<String, dynamic> json) {
    promoCode = json['cU_PROCODE']?.toString() ?? "";
    couponCode = json['cU_CODE']?.toString() ?? "";
    couponDesc = json['cU_DESC']?.toString() ?? "";
    fromDate = json['cU_FROMDATE'].toString().parseDateTime();
    toDate = json['cU_TODATE'].toString().parseDateTime();
    billValFrom = json['cU_BILLFROM'].toString().parseDouble();
    billValTo = json['cU_BILLTO'].toString().parseDouble();
    isRedeem = intToBool(json['cU_REDEEM']);
  }
  bool intToBool(dynamic value) {
    return value.toString().parseBool();
  }
}

class RedeemedCoupon {
  late String couponCode;
  late bool uniqueCoupon;
  late String promoCode;
  RedeemedCoupon(
      {required this.couponCode,
      required this.uniqueCoupon,
      required this.promoCode});

  Map<String, dynamic> toMap() {
    return {
      'couponCode': this.couponCode,
      'uniqueCoupon': this.uniqueCoupon,
      'promoCode': this.promoCode,
    };
  }
}
