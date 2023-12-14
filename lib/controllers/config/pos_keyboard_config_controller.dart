/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/6/21, 10:37 AM
 */

import 'package:shared_preferences/shared_preferences.dart';

class POSKeyboardConfigController {
  String _background = "pos_keyboard_background";
  String _gradient1 = "pos_keyboard_gradient1";
  String _gradient2 = "pos_keyboard_gradient2";
  String _gradient3 = "pos_keyboard_gradient3";
  String _borderColor = "pos_keyboard_border";
  String _enterColor = "pos_keyboard_enter";
  String _enterTxtColor = "pos_keyboard_enter_txt";
  String _voidColor = "pos_keyboard_void";
  String _voidTxtColor = "pos_keyboard_void_txt";
  String _exactColor = "pos_keyboard_exact";
  String _exactTxtColor = "pos_keyboard_exact_txt";
  SharedPreferences _preferences;

  POSKeyboardConfigController(this._preferences);

  Future setBackgroundColor(String color) async {
    return _preferences.setString(_background, color);
  }

  Future setGradient1Color(String color) async {
    return _preferences.setString(_gradient1, color);
  }

  Future setGradient2Color(String color) async {
    return _preferences.setString(_gradient2, color);
  }

  Future setGradient3Color(String color) async {
    return _preferences.setString(_gradient3, color);
  }

  Future setBorderColor(String color) async {
    return _preferences.setString(_borderColor, color);
  }

  Future setEnterKeyColor(String color) async {
    return _preferences.setString(_enterColor, color);
  }

  Future setEnterKeyTxtColor(String color) async {
    return _preferences.setString(_enterTxtColor, color);
  }

  Future setVoidKeyColor(String color) async {
    return _preferences.setString(_voidColor, color);
  }

  Future setVoidKeyTxtColor(String color) async {
    return _preferences.setString(_voidTxtColor, color);
  }

  Future setExactKeyColor(String color) async {
    return _preferences.setString(_exactColor, color);
  }

  Future setExactKeyTxtColor(String color) async {
    return _preferences.setString(_exactTxtColor, color);
  }

  String? getBackgroundColor() {
    return _preferences.getString(_background);
  }

  String? getGradient1Color() {
    return _preferences.getString(_gradient1);
  }

  String? getGradient2Color() {
    return _preferences.getString(_gradient2);
  }

  String? getGradient3Color() {
    return _preferences.getString(_gradient3);
  }

  String? getBorderColor() {
    return _preferences.getString(_borderColor);
  }

  String? getEnterKeyColor() {
    return _preferences.getString(_enterColor);
  }

  String? getEnterKeyTxtColor() {
    return _preferences.getString(_enterTxtColor);
  }

  String? getVoidKeyColor() {
    return _preferences.getString(_voidColor);
  }

  String? getVoidKeyTxtColor() {
    return _preferences.getString(_voidTxtColor);
  }

  String? getExactKeyColor() {
    return _preferences.getString(_exactColor);
  }

  String? getExactKeyTxtColor() {
    return _preferences.getString(_exactTxtColor);
  }
}
