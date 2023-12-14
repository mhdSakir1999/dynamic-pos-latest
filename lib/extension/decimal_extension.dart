/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/29/21, 5:11 PM
 */


import 'package:checkout/models/pos_config.dart';
import 'package:intl/intl.dart';

extension doubleExtension on double {
  String roundUp() {

    return (((this * 100).ceil()) / 100).toDouble().toStringAsFixed(2);
  }

  String thousandsSeparator() {
    NumberFormat numberFormat =
        NumberFormat.currency(decimalDigits: POSConfig().setup?.amountDecimalPoints??2, symbol: ' ');
    return numberFormat.format(this);
  }
  String qtyFormatter() {
    NumberFormat numberFormat =
        NumberFormat.currency(decimalDigits: POSConfig().setup?.qtyDecimalPoints??3, symbol: '');
    return numberFormat.format(this);
  }
}
