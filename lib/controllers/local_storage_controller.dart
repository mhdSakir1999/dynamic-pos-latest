/*
 * Copyright (c) 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 07/02/2022, 09:46
 */

import 'dart:convert';

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/ecr_response.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageController {
  final String _cartSummary = 'cart_summary';
  final String _tempCart = 'temp_cart';
  final String _tempPayments = 'temp_payments';
  final String _paymentReference = 'payment_reference';
  final String _invNo = 'invoice_no';
  final String _cashWithdrawal = 'withdrawal';
  final String _cashReceipt = 'receipt';
  //TODO Implement CashIn number

  SharedPreferences? _sharedPreferences;

  Future<void> _getInstance() async {
    if (_sharedPreferences == null) {
      _sharedPreferences = await SharedPreferences.getInstance();
    }
  }

  // return null or object
  dynamic _decodeString(String str) {
    if (str.isEmpty) {
      return null;
    }
    final String val = utf8.decode(base64.decode(str));

    return jsonDecode(val);
  }

  String _encodeString(String str) {
    return base64.encode(utf8.encode(str));
  }

  Future<bool> _setPreferences(String key, Map value) async {
    await _getInstance();
    return _sharedPreferences!.setString(key, _encodeString(jsonEncode(value)));
  }

  Future<bool> updateCartSummary(CartSummaryModel cartSummaryModel) async {
    cartSummaryModel.invoiceNo =
        cartBloc.cartSummary?.invoiceNo ?? cartSummaryModel.invoiceNo;
    print('Saved cartSummary: ${cartSummaryModel.toMap()}');
    return await _setPreferences(_cartSummary, cartSummaryModel.toMap());
  }

  // new change -- clearing cart summary with invoice clear button
  Future<bool> clearCartSummary() async {
    var res = await _sharedPreferences!.setString(_cartSummary, '');
    return res;
  }

  Future<CartSummaryModel?> getCartSummary() async {
    await _getInstance();
    final dynamic cartSummary =
        _decodeString(_sharedPreferences!.getString(_cartSummary) ?? '');
    if (cartSummary == null) {
      return null;
    }
    print('cartSummary: $cartSummary');
    return CartSummaryModel.fromMap(cartSummary);
  }

  Future<List<CartModel>> getCartItems() async {
    await _getInstance();
    List<CartModel> cartItems = [];
    final String? cartItemsStr = _sharedPreferences!.getString(_tempCart);
    if (cartItemsStr == null) {
      return cartItems;
    }
    dynamic decodedRes = _decodeString(cartItemsStr);
    if (decodedRes != null) {
      List<dynamic> cartItemsMap = decodedRes;
      for (var item in cartItemsMap) {
        cartItems.add(CartModel.fromLocalMap(item));
      }
    }
    return cartItems;
  }

  Future<bool> saveItemToTempCart(CartModel item) async {
    await _getInstance();
    List<CartModel> cartItems = [];
    dynamic res = _decodeString(_sharedPreferences!.getString(_tempCart) ?? '');
    // get current cart items and check
    List<dynamic> cartItemsMap = res ?? [];
    if (res != null) {
      for (var item in cartItemsMap) {
        cartItems.add(CartModel.fromLocalMap(item));
      }
    }
    cartItemsMap = [];
    cartItems.add(item);
    cartItemsMap.addAll(cartItems.map((e) => e.toMap()).toList());
    return _sharedPreferences!
        .setString(_tempCart, _encodeString(jsonEncode(cartItemsMap)));
  }

  Future<void> removeItemFromTempCart(String key) async {
    await _getInstance();
    List<CartModel> cartItems = [];
    dynamic res = _decodeString(_sharedPreferences!.getString(_tempCart) ?? '');
    // get current cart items and check
    List<dynamic> cartItemsMap = res ?? [];
    if (res != null) {
      for (var item in cartItemsMap) {
        cartItems.add(CartModel.fromLocalMap(item));
      }
    }
    cartItemsMap = [];
    int index = cartItems.indexWhere((e) => e.key == key);
    if (index != -1) {
      cartItems.removeAt(index);
    }
    cartItemsMap.addAll(cartItems.map((e) => e.toMap()).toList());
    _sharedPreferences!
        .setString(_tempCart, _encodeString(jsonEncode(cartItemsMap)));
  }

  Future<bool> updateTempCartItem(CartModel item) async {
    await _getInstance();
    List<CartModel> cartItems = [];
    dynamic res = _decodeString(_sharedPreferences!.getString(_tempCart) ?? '');
    // get current cart items and check
    List<dynamic> cartItemsMap = res ?? [];
    if (res != null) {
      for (var item in cartItemsMap) {
        cartItems.add(CartModel.fromLocalMap(item));
      }
    }
    cartItemsMap = [];
    int index = cartItems.indexWhere((e) => e.key == item.key);
    if (index != -1) {
      cartItems[index] = item;
    }
    cartItemsMap.addAll(cartItems.map((e) => e.toMap()).toList());
    return await _sharedPreferences!
        .setString(_tempCart, _encodeString(jsonEncode(cartItemsMap)));
  }

  Future<void> clearTemp() async {
    await _getInstance();
    _sharedPreferences!.setString(_tempPayments, '');
    _sharedPreferences!.setString(_tempCart, '');
    _sharedPreferences!.setString(_cartSummary, '');
    _sharedPreferences!.setString(_paymentReference, '');
  }

  Future<List<PaidModel>> getPaidList() async {
    await _getInstance();
    List<PaidModel> paidItems = [];
    final String? cartItemsStr = _sharedPreferences!.getString(_tempPayments);
    if (cartItemsStr == null || cartItemsStr.isEmpty) {
      return paidItems;
    }
    List<dynamic> paymentListMap = _decodeString(cartItemsStr);
    for (var item in paymentListMap) {
      paidItems.add(PaidModel.fromMap(item));
    }
    return paidItems;
  }

  Future<List<EcrCard>> getPaymentReference() async {
    await _getInstance();
    List<EcrCard> paidItems = [];
    final String? cartItemsStr =
        _sharedPreferences!.getString(_paymentReference);
    if (cartItemsStr == null || cartItemsStr.isEmpty) {
      return paidItems;
    }
    List<dynamic> paymentListMap = _decodeString(cartItemsStr);
    for (var item in paymentListMap) {
      paidItems.add(EcrCard.fromJson(item));
    }
    return paidItems;
  }

  Future<bool> saveTempPayment(PaidModel paidModel) async {
    await _getInstance();
    List<PaidModel> paidItems = [];
    dynamic res =
        _decodeString(_sharedPreferences!.getString(_tempPayments) ?? '');
    // get current cart items and check
    List<dynamic> paymentListMap = res ?? [];
    if (res != null) {
      for (var item in paymentListMap) {
        paidItems.add(PaidModel.fromMap(item));
      }
    }
    paymentListMap = [];
    paidItems.add(paidModel);
    paymentListMap.addAll(paidItems.map((e) => e.toMap()).toList());
    return _sharedPreferences!
        .setString(_tempPayments, _encodeString(jsonEncode(paymentListMap)));
  }

  Future<bool> savePaymentReference(EcrCard card) async {
    await _getInstance();
    List<EcrCard> paidItems = [];
    dynamic res =
        _decodeString(_sharedPreferences!.getString(_paymentReference) ?? '');
    // get current cart items and check
    List<dynamic> paymentListMap = res ?? [];
    if (res != null) {
      for (var item in paymentListMap) {
        paidItems.add(EcrCard.fromJson(item));
      }
    }
    paymentListMap = [];
    paidItems.add(card);
    paymentListMap.addAll(paidItems.map((e) => e.toJson()).toList());
    return _sharedPreferences!.setString(
        _paymentReference, _encodeString(jsonEncode(paymentListMap)));
  }

  Future<bool> clearTempPayment() async {
    await _getInstance();
    return _sharedPreferences!.setString(_tempPayments, '');
  }

  Future<bool> setInvoice(String invoiceNo) async {
    await _getInstance();
    return _sharedPreferences!.setString(_invNo, invoiceNo);
  }

  Future<bool> clearInvoiceNo() async {
    try {
      await _getInstance();
      await clearCartSummary(); //new change -- clearing the existing cart summary as well
      var res = _sharedPreferences!.setString(_invNo, '');
      return res;
    } catch (e) {
      EasyLoading.showInfo('$e', duration: Duration(seconds: 2));
      return false;
    }
  }

  Future<bool> clearWithdrawal() async {
    await _getInstance();
    return _sharedPreferences!.setString(_cashWithdrawal, '');
  }

  //get invoice
  Future<String?> getInvoice() async {
    await _getInstance();
    String? inv = _sharedPreferences!.getString(_invNo);
    if (inv != null && inv.isEmpty) {
      inv = null;
    }
    return inv;
  }

  Future<String?> getWithdrawal() async {
    await _getInstance();
    String? inv = _sharedPreferences!.getString(_cashWithdrawal);
    if (inv != null && inv.isEmpty) {
      inv = null;
    }
    return inv;
  }

  Future<bool> setWithdrawal(String withdrawal) async {
    await _getInstance();
    return _sharedPreferences!.setString(_cashWithdrawal, withdrawal);
  }
}
