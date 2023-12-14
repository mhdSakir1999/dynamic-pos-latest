/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/30/21, 11:36 AM
 */
import 'package:flutter/services.dart';
import 'string_extension.dart';

class CustomRangeTextInputFormatter extends TextInputFormatter {
  final double min;
  final double max;
  CustomRangeTextInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text == '')
      return TextEditingValue();
    else if (newValue.text.parseDouble() < min)
      return TextEditingValue().copyWith(text: '${min.toInt()}');

    return newValue.text.parseDouble() > max
        ? TextEditingValue().copyWith(text: '${max.toInt()}')
        : newValue;
  }
}
