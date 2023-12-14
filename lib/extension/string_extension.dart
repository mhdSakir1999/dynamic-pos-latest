/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/29/21, 5:11 PM
 */

import 'package:intl/intl.dart';

extension StringExtension on String {
  double parseDouble() =>
      double.tryParse(this) ?? int.tryParse(this)?.toDouble() ?? 0;

  bool parseBool() => this.toLowerCase() == "true" || this == "1";

  DateTime parseDateTime() {
    try {
      return this.isEmpty
          ? DateTime.now()
          : DateFormat("yyyy-MM-ddTHH:mm:ss").parse(this.replaceAll(' ', 'T'));
    } catch (_) {
      return DateTime(1900, 01, 01);
    }
  }

  String removeLastChar() {
    if (this.length > 0) {
      return this.substring(0, this.length - 1);
    }
    return this;
  }

  String getLastNChar(int n) {
    if (this.length > 0) {
      return this.substring(this.length - n, this.length);
    }
    return this;
  }
}
