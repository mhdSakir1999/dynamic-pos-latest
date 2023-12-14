/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/12/21, 4:20 PM
 */

import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/bloc/customer_coupons_bloc.dart';
import 'package:checkout/bloc/paymode_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/models/last_invoice_details.dart';
import 'package:checkout/models/pos/Inv_appliedPeomotons.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/ecr_response.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos/promotion_free_items.dart';
import 'package:checkout/models/pos_config.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../controllers/pos_alerts/pos_error_alert.dart';
import '../models/pos/selectable_promotion_res.dart';

class CartBloc {
  final _cartSummary = BehaviorSubject<CartSummaryModel>();
  final _paidList = BehaviorSubject<List<PaidModel>>();
  final _invAppliedPromo = BehaviorSubject<List<InvAppliedPromotion>>();
  final _invRefList = BehaviorSubject<List<EcrCard>>();
  final _promoFreeItems = BehaviorSubject<List<PromotionFreeItems>>();
  final _currentCartLst = BehaviorSubject<Map<String, CartModel>>();
  final _lastInvoiceData = BehaviorSubject<LastInvoiceDetails>();
  final _specificPayMode =
      BehaviorSubject<SelectablePaymentModeWisePromotions?>();
  final _promoFreeGVs = BehaviorSubject<List<PromotionFreeGVs>>();
  final _promoFreeTickets = BehaviorSubject<List<PromotionFreeTickets>>();

  BuildContext? context;

  Stream<CartSummaryModel> get cartSummarySnapshot => _cartSummary.stream;
  Stream<LastInvoiceDetails> get lastInvoiceDetails => _lastInvoiceData.stream;
  Stream<List<PromotionFreeItems>> get promotionFreeItem =>
      _promoFreeItems.stream;
  Stream<List<PromotionFreeGVs>> get PromotionFreeGV => _promoFreeGVs.stream;
  Stream<List<PromotionFreeTickets>> get PromotionFreeTicket =>
      _promoFreeTickets.stream;
  Stream<Map<String, CartModel>> get currentCartSnapshot =>
      _currentCartLst.stream;
  Stream<List<PaidModel>> get paidListStream => _paidList.stream;
  Stream<List<InvAppliedPromotion>> get promoAppliedStream =>
      _invAppliedPromo.stream;

  CartSummaryModel? get cartSummary => _cartSummary.valueOrNull;
  SelectablePaymentModeWisePromotions? get specificPayMode =>
      _specificPayMode.valueOrNull;
  Map<String, CartModel>? get currentCart => _currentCartLst.valueOrNull;
  List<PaidModel>? get paidList => _paidList.valueOrNull;
  List<InvAppliedPromotion>? get promoAppliedList =>
      _invAppliedPromo.valueOrNull;
  List<EcrCard>? get invReference => _invRefList.valueOrNull;
  List<PromotionFreeItems>? get promoFreeItems => _promoFreeItems.valueOrNull;
  List<PromotionFreeGVs>? get promoFreeGVs => _promoFreeGVs.valueOrNull;
  List<PromotionFreeTickets>? get promoFreeTickets =>
      _promoFreeTickets.valueOrNull;

  //add free item
  void addPromoFreeItems(List<PromotionFreeItems> promotionFreeItems) {
    _promoFreeItems.sink.add(promotionFreeItems);
  }

  void addPromoFreeGVs(List<PromotionFreeGVs> promotionFreeGVs) {
    _promoFreeGVs.sink.add(promotionFreeGVs);
  }

  void addPromoFreeTickets(List<PromotionFreeTickets> promotionFreeTickets) {
    _promoFreeTickets.sink.add(promotionFreeTickets);
  }

  void addSpecificPayMode(SelectablePaymentModeWisePromotions? payMode) {
    _specificPayMode.sink.add(payMode);
  }

  bool updatePromoFreeItem(List<PromotionFreeItems> promotionFreeItems,
      int headerIndex, int detailsIndex, double qty) {
    //check the scanned qty with given qty
    PromotionFreeItems freeItem = promotionFreeItems[headerIndex];
    if (freeItem.remainingQty < qty) {
      EasyLoading.showError('promo.invalid_qty'.tr());
      return false;
    } else {
      freeItem.remainingQty -= qty;
      freeItem.freeItemBundle[detailsIndex].scannedQty += qty;
      promotionFreeItems[headerIndex] = freeItem;
      _promoFreeItems.sink.add(promotionFreeItems);
      return true;
    }
  }

  bool updatePromoFreeGV(List<PromotionFreeGVs> promotionFreeGVs,
      int headerIndex, int detailsIndex, double qty) {
    //check the scanned qty with given qty
    PromotionFreeGVs freeGV = promotionFreeGVs[headerIndex];
    if (freeGV.remainingQty < qty) {
      EasyLoading.showError('promo.invalid_qty'.tr());
      return false;
    } else {
      freeGV.remainingQty -= qty;
      freeGV.scannedQty += qty;
      promotionFreeGVs[headerIndex] = freeGV;
      _promoFreeGVs.sink.add(promotionFreeGVs);
      return true;
    }
  }

  bool updatePromoFreeTickets(List<PromotionFreeTickets> promotionFreeTickets,
      int headerIndex, int detailsIndex, double qty) {
    //check the scanned qty with given qty
    PromotionFreeTickets freeTicket = promotionFreeTickets[headerIndex];
    if (qty <= 0) {
      EasyLoading.showError('promo.invalid_qty'.tr());
      return false;
    } else {
      promotionFreeTickets[headerIndex] = freeTicket;
      _promoFreeTickets.sink.add(promotionFreeTickets);
      return true;
    }
  }

  // This method updates the  cart summary
  void updateCartSummary(CartSummaryModel cartSummary) async {
    _cartSummary.sink.add(cartSummary);
    DualScreenController().sendLastProduct(null);
  }

  void addBillPromotionToSummary(double discPre, String promoCode) async {
    final cartSummary = _cartSummary.valueOrNull;
    if (cartSummary != null) {
      cartSummary.promoCode = promoCode;
      cartSummary.promoDiscountPre = discPre;
      _cartSummary.sink.add(cartSummary);
    }
    DualScreenController().sendLastProduct(null);
  }

  void updateCartSummaryPrice(double amount) async {
    var cart = _cartSummary.valueOrNull ??
        CartSummaryModel(
            invoiceNo: "",
            items: 0,
            qty: 0,
            subTotal: 0,
            startTime: '',
            priceMode: '');
    cart.subTotal += amount;
    await InvoiceController().updateTempCartSummary(cart);
    _cartSummary.sink.add(cart);
    DualScreenController().sendLastProduct(null);
  }

  final invController = InvoiceController();

  // THis method will update the current cart
  Future<bool> updateCurrentCart(CartModel cartModel, bool alreadyAdded) async {
    Map<String, CartModel> currentMap = _currentCartLst.valueOrNull ?? {};
    bool minus = cartModel.unitQty.toDouble() < 0;
    bool result = false;
    cartModel.dateTime = DateTime.now();
    if (!POSConfig().cartBatchItem) {
      final lineNo = DateTime.now().microsecondsSinceEpoch.toString() +
          "--" +
          cartModel.lineNo.toString();
      String key = "$lineNo";

      cartModel.key = key;
      //save to db
      final res = await invController.saveItemTempCart(cartModel);
      if (res) currentMap[key] = cartModel;
      result = res;
    } else {
      final code = "${cartModel.stockCode}_${cartModel.selling}";
      cartModel.key = code;
      if (!alreadyAdded && !minus) {
        //save to db
        final res = await invController.saveItemTempCart(cartModel);
        if (res) currentMap[code] = cartModel;
        result = res;
      } else {
        if (minus) {
          cartModel.key = code + "minus";
          final res = await invController.saveItemTempCart(cartModel);
          if (res) currentMap[cartModel.key] = cartModel;
          result = res;
        } else {
          final temp = currentMap[code];
          //  adding the qty
          cartModel.unitQty += temp!.unitQty;
          cartModel.amount += temp.amount;
          currentMap.remove(code);
          //delete from db
          invController.deleteItemFromTempCart(cartModel);
          final res = await invController.saveItemTempCart(cartModel);
          if (res) currentMap[code] = cartModel;
          result = res;
        }
      }
    }
    _currentCartLst.sink.add(currentMap);
    DualScreenController().sendLastProduct(cartModel);
    return result;
  }

  void updateCartUnconditionally(CartModel cartModel) async {
    Map<String, CartModel> currentMap = _currentCartLst.valueOrNull ?? {};
    currentMap[cartModel.key] = cartModel;
    print(cartModel.key);
    DualScreenController().sendLastProduct(cartModel);
    _currentCartLst.sink.add(currentMap);
  }

  void updateCartList(List<CartModel> cartList) async {
    Map<String, CartModel> currentMap = {};
    cartList.forEach((cartModel) {
      currentMap[cartModel.key] = cartModel;
    });
    _currentCartLst.sink.add(currentMap);
  }

  Future<bool> voidCartItem(CartModel cartModel) async {
    Map<String, CartModel> currentMap = _currentCartLst.valueOrNull ?? {};
    cartModel.itemVoid = true;
    //delete record
    invController.deleteItemFromTempCart(cartModel);

    // if the cart is batch wise then do this
    if (POSConfig().cartBatchItem) {
      currentMap.remove(cartModel.key);

      //add new
      cartModel.key = "void" +
          DateTime.now().microsecondsSinceEpoch.toString() +
          cartModel.key;
    }

    final res = await invController.saveItemTempCart(cartModel);
    if (res) currentMap[cartModel.key] = cartModel;
    _currentCartLst.sink.add(currentMap);
    DualScreenController().sendLastProduct(cartModel);
    return res;
  }

  Future<bool> updateCartItem(CartModel cartModel) async {
    Map<String, CartModel> currentMap = _currentCartLst.valueOrNull ?? {};
    // //delete record
    // invController.deleteItemFromTempCart(cartModel);
    // currentMap.remove(cartModel.key);
    //update record
    final res = await invController.updateTempCartItem(cartModel);
    if (res) currentMap[cartModel.key] = cartModel;
    _currentCartLst.sink.add(currentMap);
    DualScreenController().sendLastProduct(cartModel);
    return res;
  }

  Future<void> updateCartForPromo(List<CartModel> cartItems) async {
    Map<String, CartModel> currentMap = _currentCartLst.valueOrNull ?? {};
    // final oldMap = _currentCartLst.valueOrNull??{};
    double discPer = 0;
    double billDiscPer = 0;

    for (var cartModel in cartItems) {
      final CartModel? currentItem = cartModel;
      if (currentItem != null) {
        currentMap[cartModel.key] = currentItem;
        if (currentItem.promoCode != null && currentItem.promoCode != '') {
          discPer = currentItem.promoDiscPre ?? 0;
          billDiscPer = currentItem.promoBillDiscPre ?? 0;
          addInvPromotion(new InvAppliedPromotion(
              currentItem.locCode,
              currentItem.promoCode ?? '',
              currentItem.proCode,
              false,
              (discPer != 0 ? discPer : billDiscPer),
              currentItem.promoDiscAmt ?? 0,
              (currentItem.lineNo ?? 0).toDouble(),
              currentItem.scanBarcode,
              currentItem.promoFreeQty ?? 0,
              currentItem.selling,
              currentItem.unitQty,
              'INV',
              DateTime.now(),
              '',
              currentItem.promoOriginalItem ?? '',
              0));
        }
      }
    }
    _currentCartLst.sink.add(currentMap);
  }

  void addPayment(PaidModel paid, {bool savePayment = true}) {
    final currentList = _paidList.valueOrNull ?? [];
    currentList.add(paid);
    _paidList.sink.add(currentList);
    if (savePayment) InvoiceController().saveTempPayment(paid);
  }

  void addInvPromotion(InvAppliedPromotion promo, {bool savePayment = true}) {
    final currentList = _invAppliedPromo.valueOrNull ?? [];
    currentList.add(promo);
    _invAppliedPromo.sink.add(currentList);
    //if (savePayment) InvoiceController().saveTempPayment(promo);
  }

  void addNewReference(EcrCard card, {bool savePayment = true}) {
    final currentList = _invRefList.valueOrNull ?? [];
    currentList.add(card);
    _invRefList.sink.add(currentList);
    if (savePayment) InvoiceController().saveReference(card);
  }

  void dispose() {
    _cartSummary.close();
    _currentCartLst.close();
    _paidList.close();
    _lastInvoiceData.close();
    _invRefList.close();
    _promoFreeItems.close();
    _promoFreeGVs.close();
    _invAppliedPromo.close();
    _promoFreeTickets.close();
  }

  Future resetCart() async {
    await InvoiceController().clearTemp();

    /* check connection is server */
    if (POSConfig().localMode) {
      bool serverRes = await POSConnectivity().pingToServer();
      if (serverRes) await serverConnectionPopup();
    }

    final zero = 0;
    final inv = await InvoiceController().getInvoiceNo();
    _cartSummary.sink.add(CartSummaryModel(
        startTime: '',
        invoiceNo: inv,
        items: 0,
        qty: 0,
        subTotal: 0,
        priceMode: ''));
    _currentCartLst.sink.add({});
    customerBloc.changeCurrentCustomer(null, update: false);
    _paidList.sink.add([]);
    _invAppliedPromo.sink.add([]);
    _invRefList.sink.add([]);
    customerCouponBloc.clearCoupons();
    _specificPayMode.add(null);
  }

  /* Server connection confirmation dialog*/
  /* By Dinuka 2022/08/02 */
  Future<void> serverConnectionPopup() async {
    if (context != null) {
      return showDialog<void>(
        context: context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title:
                Text('payment_view.server_connection_confirmation_title'.tr()),
            content: Text('payment_view.server_connection_confirmation'.tr()),
            actions: [
              AlertDialogButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  text: 'payment_view.no'.tr()),
              AlertDialogButton(
                  onPressed: () {
                    posConnectivity.localConfirmed = false;
                    POSConfig().localMode = false;
                    posConnectivity.handleConnection();
                    Navigator.pop(context);
                  },
                  text: 'payment_view.yes'.tr())
            ],
          );
        },
      );
    } else {
      return null;
    }
  }

  //return reveresed payment amount
  double reversePaymentModePromo() {
    final cartSummary = _cartSummary.valueOrNull;
    if (cartSummary != null) {
      cartSummary.promoCode = null;
      cartSummary.promoDiscount = null;
      _cartSummary.sink.add(cartSummary);
    }

    //remove payment mode
    final payModeList = payModeBloc.payModeResult?.payModes ?? [];
    int index =
        payModeList.indexWhere((element) => element.pHLINKPROMO == true);
    if (index != -1) {
      final String phCode = payModeList[index].pHCODE ?? '';
      final paidList = _paidList.valueOrNull ?? [];
      int paidIndex =
          paidList.indexWhere((element) => element.phCode == phCode);
      if (paidIndex != -1) {
        double amount = paidList[paidIndex].paidAmount;
        paidList.removeAt(paidIndex);
        _paidList.sink.add(paidList);
        return amount;
      }
    }
    return 0;
  }

  void clearBLoc() {
    _currentCartLst.sink.add({});
    _paidList.sink.add([]);
    _invAppliedPromo.sink.add([]);
  }

  void clearCartList() {
    _currentCartLst.sink.add({});
  }

  clearPayment() {
    _paidList.sink.add([]);
    _specificPayMode.add(null);
  }

  clearPromoTickets() {
    _promoFreeTickets.sink.add([]);
  }

  void updateLastInvoice(LastInvoiceDetails details) {
    _lastInvoiceData.add(details);
  }

  CartSummaryModel get defaultSummary => CartSummaryModel(
      invoiceNo: "",
      items: 0,
      qty: 0,
      subTotal: 0,
      startTime: '',
      priceMode: '');
}

final cartBloc = CartBloc();
