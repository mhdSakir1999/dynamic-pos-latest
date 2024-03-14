/*
 * Copyright © 2023 myPOS Software Solutions.  All rights reserved.
 * Author: Pubudu Wijetunge
 * Created At: 6/21/23, 09:16 AM
 */

import 'package:checkout/extension/extensions.dart';
import 'package:intl/intl.dart';

class InvAppliedPromotion {
  late String Location_code;
  late String promotion_code;
  late String product_code;
  late bool cancelled;
  late double discount_per;
  late double discount_amt;
  late double line_no;
  late String barcode;
  late double free_qty;
  late double selling_price;
  late double invoice_qty;
  late String invoice_mode;
  late DateTime invoice_date;
  late String coupon_code;
  late String promo_product;
  late double beneficial_value;

  InvAppliedPromotion(
      this.Location_code,
      this.promotion_code,
      this.product_code,
      this.cancelled,
      this.discount_per,
      this.discount_amt,
      this.line_no,
      this.barcode,
      this.free_qty,
      this.selling_price,
      this.invoice_qty,
      this.invoice_mode,
      this.invoice_date,
      this.coupon_code,
      this.promo_product,
      this.beneficial_value);

  InvAppliedPromotion.fromMap(Map<String, dynamic> map) {
    final tempDate = map['date_time'];
    try {
      invoice_date = DateFormat().parse(tempDate);
    } on Exception catch (_) {
      invoice_date = DateTime.now();
    }

    String? date = map['date']?.toString() ?? "";
    if (date.isEmpty) {
      date = null;
    }

    Location_code = map['Location_code'];
    promotion_code = map['promotion_code'];
    product_code = map['product_code'];
    cancelled = map['cancelled']?.toString() == "true";
    discount_per = map['discount_per']?.toString().parseDouble() ?? 0;
    discount_amt = map['discount_amt']?.toString().parseDouble() ?? 0;
    line_no = map['line_no']?.toString().parseDouble() ?? 0;
    barcode = map['barcode'];
    free_qty = map['free_qty']?.toString().parseDouble() ?? 0;
    selling_price = map['selling_price']?.toString().parseDouble() ?? 0;
    invoice_qty = map['invoice_qty']?.toString().parseDouble() ?? 0;
    invoice_mode = map['invoice_mode'];
    coupon_code = map['coupon_code'];
    promo_product = map['promo_product'];
    beneficial_value = map['beneficial_value']?.toString().parseDouble() ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'Location_code': this.Location_code,
      'Promotion_code': this.promotion_code,
      'product_code': this.product_code,
      'cancelled': this.cancelled,
      'discount_per': this.discount_per.toDouble(),
      'discount_amt': this.discount_amt.toDouble(),
      'line_no': this.line_no.toDouble(),
      'barcode': this.barcode,
      'free_qty': this.free_qty.toDouble(),
      'selling_price': this.selling_price.toDouble(),
      'invoice_qty': this.invoice_qty.toDouble(),
      'invoice_mode': this.invoice_mode,
      'coupon_code': this.coupon_code,
      'promo_product': this.promo_product,
      'beneficial_value': this.beneficial_value.toDouble(),
      'invoice_date': this.invoice_date.toString(),
    };
  }
}

class InvBillDiscAmountPromo {
  late String Location_code;
  late String promotion_code;
  late String promotion_name;
  late String product_code;
  late bool cancelled;
  late double discount_per;
  late double discount_amt;
  late double line_no;
  late String barcode;
  late double free_qty;
  late double selling_price;
  late double invoice_qty;
  late String invoice_mode;
  late DateTime invoice_date;
  late String coupon_code;
  late String promo_product;
  late double beneficial_value;

  InvBillDiscAmountPromo(
      this.Location_code,
      this.promotion_code,
      this.promotion_name,
      this.product_code,
      this.cancelled,
      this.discount_per,
      this.discount_amt,
      this.line_no,
      this.barcode,
      this.free_qty,
      this.selling_price,
      this.invoice_qty,
      this.invoice_mode,
      this.invoice_date,
      this.coupon_code,
      this.promo_product,
      this.beneficial_value);

  InvBillDiscAmountPromo.fromMap(Map<String, dynamic> map) {
    final tempDate = map['date_time'];
    try {
      invoice_date = DateFormat().parse(tempDate);
    } on Exception catch (_) {
      invoice_date = DateTime.now();
    }

    String? date = map['date']?.toString() ?? "";
    if (date.isEmpty) {
      date = null;
    }

    Location_code = map['Location_code'];
    promotion_code = map['promotion_code'];
    product_code = map['product_code'];
    promotion_name = map['promotion_name'];
    cancelled = map['cancelled']?.toString() == "true";
    discount_per = map['discount_per']?.toString().parseDouble() ?? 0;
    discount_amt = map['discount_amt']?.toString().parseDouble() ?? 0;
    line_no = map['line_no']?.toString().parseDouble() ?? 0;
    barcode = map['barcode'];
    free_qty = map['free_qty']?.toString().parseDouble() ?? 0;
    selling_price = map['selling_price']?.toString().parseDouble() ?? 0;
    invoice_qty = map['invoice_qty']?.toString().parseDouble() ?? 0;
    invoice_mode = map['invoice_mode'];
    coupon_code = map['coupon_code'];
    promo_product = map['promo_product'];
    beneficial_value = map['beneficial_value']?.toString().parseDouble() ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'Location_code': this.Location_code,
      'Promotion_code': this.promotion_code,
      'promotion_name': this.promotion_name,
      'product_code': this.product_code,
      'cancelled': this.cancelled,
      'discount_per': this.discount_per.toDouble(),
      'discount_amt': this.discount_amt.toDouble(),
      'line_no': this.line_no.toDouble(),
      'barcode': this.barcode,
      'free_qty': this.free_qty.toDouble(),
      'selling_price': this.selling_price.toDouble(),
      'invoice_qty': this.invoice_qty.toDouble(),
      'invoice_mode': this.invoice_mode,
      'coupon_code': this.coupon_code,
      'promo_product': this.promo_product,
      'beneficial_value': this.beneficial_value.toDouble(),
      'invoice_date': this.invoice_date.toString(),
    };
  }
}
