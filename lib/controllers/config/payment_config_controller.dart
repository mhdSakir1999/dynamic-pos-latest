/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/3/21, 10:20 AM
 */

import 'package:shared_preferences/shared_preferences.dart';

class PaymentConfigController {
  SharedPreferences _preferences;
  PaymentConfigController(this._preferences);
  String _paymentButtonWidth = "payment_button_width";
  String _paymentButtonHeight = "payment_button_height";
  String _paymentButtonSpace = "payment_button_space";
  String _paymentButtonFontSize = "payment_button_font_size";

  Future<bool> setButtonWidth(double length) async {
    return await _preferences.setDouble(_paymentButtonWidth, length);
  }

  Future<bool> setButtonHeight(double length) async {
    return await _preferences.setDouble(_paymentButtonHeight, length);
  }

  Future<bool> setButtonFontSize(double length) async {
    return await _preferences.setDouble(_paymentButtonFontSize, length);
  }

  Future<bool> setButtonSpaceBetween(double length) async {
    return await _preferences.setDouble(_paymentButtonSpace, length);
  }

  double? getButtonWidth() {
    return _preferences.getDouble(_paymentButtonWidth);
  }

  double? getButtonHeight() {
    return _preferences.getDouble(_paymentButtonHeight);
  }

  double? getButtonSpace() {
    return _preferences.getDouble(_paymentButtonSpace);
  }

  double? getButtonFontSize() {
    return _preferences.getDouble(_paymentButtonFontSize);
  }
}
