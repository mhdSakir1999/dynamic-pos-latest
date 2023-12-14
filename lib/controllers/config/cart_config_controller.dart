/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/3/21, 10:20 AM
 */

import 'package:shared_preferences/shared_preferences.dart';

class CartConfigController {
  SharedPreferences _preferences;
  CartConfigController(this._preferences);
  String _cardIdLength = "cart_card_id_length";
  String _cardNameLength = "cart_card_name_length";
  String _cardPriceLength = "cart_card_price_length";
  String _cardQtyLength = "cart_card_qty_length";
  String _cardTotalLength = "cart_card_total_price_length";
  String _cardFontSize = "cart_card_fontSize_length";
  String _cardButtonWidth = "cart_button_width";
  String _cardButtonHeight = "cart_button_height";
  String _cardButtonSpace = "cart_button_space";
  String _cardButtonFontSize = "cart_button_font_size";
  String _cardLhsMode = "cart_mode";
  String _cardTableView = "cart_table_view";
  String _cardTableFontSize = "cart_table_font_size";
  String _cartBatch = "cart_batch";

  Future<bool> setCardIdLength(double length) async {
    return await _preferences.setDouble(_cardIdLength, length);
  }

  Future<bool> setCardNameLength(double length) async {
    return await _preferences.setDouble(_cardNameLength, length);
  }

  Future<bool> setCardPriceLength(double length) async {
    return await _preferences.setDouble(_cardPriceLength, length);
  }

  Future<bool> setCardQtyLength(double length) async {
    return await _preferences.setDouble(_cardQtyLength, length);
  }

  Future<bool> setCardTotalLength(double length) async {
    return await _preferences.setDouble(_cardTotalLength, length);
  }

  Future<bool> setCardFontSizeLength(double length) async {
    return await _preferences.setDouble(_cardFontSize, length);
  }

  Future<bool> setButtonWidth(double length) async {
    return await _preferences.setDouble(_cardButtonWidth, length);
  }

  Future<bool> setButtonHeight(double length) async {
    return await _preferences.setDouble(_cardButtonHeight, length);
  }

  Future<bool> setButtonFontSize(double length) async {
    return await _preferences.setDouble(_cardButtonFontSize, length);
  }

  Future<bool> setButtonSpaceBetween(double length) async {
    return await _preferences.setDouble(_cardButtonSpace, length);
  }

  Future<bool> setLHSMode(bool enabled) async {
    return await _preferences.setBool(_cardLhsMode, enabled);
  }

  Future<bool> setTableView(bool enabled) async {
    return await _preferences.setBool(_cardTableView, enabled);
  }

  Future<bool> setDataTableFontSize(double length) async {
    return await _preferences.setDouble(_cardTableFontSize, length);
  }

  Future<bool> setCartBatch(bool enabled) async {
    return await _preferences.setBool(_cartBatch, enabled);
  }

  double? getCardIdLength() {
    return _preferences.getDouble(_cardIdLength);
  }

  double? getCardNameLength() {
    return _preferences.getDouble(_cardNameLength);
  }

  double? getCardPriceLength() {
    return _preferences.getDouble(_cardPriceLength);
  }

  double? getCardQtyLength() {
    return _preferences.getDouble(_cardQtyLength);
  }

  double? getCardTotalLength() {
    return _preferences.getDouble(_cardTotalLength);
  }

  double? getCardFontSizeLength() {
    return _preferences.getDouble(_cardFontSize);
  }

  double? getButtonWidth() {
    return _preferences.getDouble(_cardButtonWidth);
  }

  double? getButtonHeight() {
    return _preferences.getDouble(_cardButtonHeight);
  }

  double? getButtonSpace() {
    return _preferences.getDouble(_cardButtonSpace);
  }

  double? getButtonFontSize() {
    return _preferences.getDouble(_cardButtonFontSize);
  }

  double? getTableFontSize() {
    return _preferences.getDouble(_cardTableFontSize);
  }

  bool? getTableView() {
    return _preferences.getBool(_cardTableView);
  }

  bool? getLhsMod() {
    return _preferences.getBool(_cardLhsMode);
  }

  bool? getCartBatch() {
    return _preferences.getBool(_cartBatch);
  }
}
