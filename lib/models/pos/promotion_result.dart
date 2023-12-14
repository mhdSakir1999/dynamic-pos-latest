/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/8/22, 1:53 PM
 */

import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/pos/cart_model.dart';

class PromotionResult {
  Promotions? promotions;
  bool? success;

  PromotionResult({this.promotions, this.success});

  PromotionResult.fromJson(Map<String, dynamic> json) {
    promotions = json['promotions'] != null
        ? new Promotions.fromJson(json['promotions'])
        : null;
    success = json['success'];
  }
}

class Promotions {
  double? totalAmount;
  double? netAmount;
  double? promotionAmount;
  int? runningPromotions;
  int? appliedPromotions;
  List<CartModel>? details;

  Promotions(
      {this.totalAmount,
        this.netAmount,
        this.promotionAmount,
        this.runningPromotions,
        this.appliedPromotions,
        this.details});

  Promotions.fromJson(Map<String, dynamic> json) {
    totalAmount = json['totalAmount']?.toString().parseDouble()??0;
    netAmount = json['netAmount']?.toString().parseDouble()??0;
    promotionAmount = json['promotionAmount']?.toString().parseDouble()??0;
    runningPromotions = json['runningPromotions']?.toString().parseDouble().toInt()??0;
    appliedPromotions = json['appliedPromotions']?.toString().parseDouble().toInt()??0;
    if (json['details'] != null) {
      details = <CartModel>[];
      json['details'].forEach((v) {
        details!.add(new CartModel.fromMap(v));
      });
    }
  }

}

