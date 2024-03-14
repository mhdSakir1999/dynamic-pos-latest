/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 10/11/22, 4:53 PM
 */

import 'package:checkout/models/pos/promotion_free_items.dart';

import 'specific_paymodes.dart';

class SelectablePaymentModeWisePromotions {
  final String code;
  final String desc;
  final double amount;
  final String phCode;
  final String pdCode;
  final List<PromoCardBin>? cardBin;
  final List<PromotionFreeTickets> cashBackCoupons;
  final bool isCouponPromo;
  late String couponNo;
  final bool uniqueCoupon;
  final double promoEligibleValue;

  SelectablePaymentModeWisePromotions(
      {required this.code,
      required this.desc,
      required this.amount,
      required this.phCode,
      required this.pdCode,
      required this.cardBin,
      required this.discPre,
      required this.cashBackCoupons,
      required this.isCouponPromo,
      required this.couponNo,
      required this.uniqueCoupon,
      required this.promoEligibleValue});

  final double discPre;
}

class SelectableCouponPromotions {
  final String code;
  final String desc;
  final double amount;

  SelectableCouponPromotions({
    required this.code,
    required this.desc,
    required this.amount,
  });
}
