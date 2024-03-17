/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/8/22, 12:22 PM
 */

//import 'dart:html';

import 'dart:math';

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/bloc/paymode_bloc.dart';
import 'package:checkout/bloc/promotion_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/controllers/setup_controller.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/pos/Inv_appliedPeomotons.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/customer_promotion_result.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos/specific_paymodes.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/views/pos_functions/promotion_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';
import 'package:supercharged/supercharged.dart';

import '../models/loyalty/customer_list_result.dart';
import '../models/pos/promo_cart_item_dto.dart';
import '../models/pos/promotion_details_result.dart';
import '../models/pos/promotion_free_items.dart';
import '../models/pos/promotion_group_bundle_result.dart';
import '../models/pos/promotion_sku_result.dart';
import '../models/pos/selectable_promotion_res.dart';
import '../models/promotion_model.dart';

class PromotionController {
  final BuildContext context;
  final POSPriceCalculator _calculator = POSPriceCalculator();

  double totalBillDiscount = 0;
  double totalLineDiscount = 0;
  List<PromotionFreeItems> promotionFreeItems = [];
  List<PromotionFreeGVs> promotionFreeGVs = [];
  List<PromotionFreeTickets> promotionFreeTickets = [];
  List<InvBillDiscAmountPromo> promotionBillDisc = [];

  PromotionController(this.context);

  Future<void> applyPromotion() async {
    if (POSConfig().clientLicense?.lCMYOFFERS != true || POSConfig().expired) {
      return;
    }

    final CustomerResult? customerResult = customerBloc.currentCustomer;
    List<CartModel> cartList = cartBloc.currentCart?.values.toList() ?? [];
    final summary = cartBloc.cartSummary;
    if (summary == null || cartList.isEmpty) {
      return;
    }
    double billValue = summary.subTotal;
    print('calculating promotions.......');
    EasyLoading.show(status: 'invoice.calculating_promotion'.tr());

    final setup = await SetUpController().getSetupData(POSConfig().server);
    if (!kReleaseMode) await getPromotions();
    List<Promotion> allPromotionList = promotionBloc.promotionList;
    List<Promotion> invalidPromotionList = <Promotion>[];
    List<Promotion> paymentModePromoList = <Promotion>[];
    List<Promotion> couponPromoList = <Promotion>[];
    List<Promotion> otherPromoList = <Promotion>[];

    print('------- Staring promotion loop -------');

    DateTime serverTime = setup?.serverTime ?? DateTime.now();
    for (var promotion in allPromotionList) {
      PromotionStat promoStat = await validatePromotionStep1(
          promotion, billValue, serverTime, customerResult);

      print(promotion.prODESC);
      promotion.status = promoStat;
      switch (promoStat) {
        case PromotionStat.invalid:
          invalidPromotionList.add(promotion);
          print('* Invalid');
          break;
        case PromotionStat.billValue:
        case PromotionStat.item:
          print('* Bill value and other promo');
          otherPromoList.add(promotion);
          break;
        case PromotionStat.payModeBillValue:
        case PromotionStat.payModeItem:
          print('* payment mode promo');
          paymentModePromoList.add(promotion);
          break;
        case PromotionStat.couponRedeem:
          print('* coupon promo');
          couponPromoList.add(promotion);
          break;
      }
      print('--------------------------');
    }

    print('------- summary -------');
    print('#Server Time: ${setup?.serverTime.toString()}');
    print('#all promotions: ${allPromotionList.length}');
    print(
        '#bill value promotions: ${otherPromoList.where((element) => element.status == PromotionStat.billValue).length}');
    print(
        '#item promotions: ${otherPromoList.where((element) => element.status == PromotionStat.item).length}');
    print(
        '#payment mode wise bill bill value promotions: ${paymentModePromoList.where((element) => element.status == PromotionStat.payModeBillValue).length}');
    print(
        '#payment mode wise item promotions: ${paymentModePromoList.where((element) => element.status == PromotionStat.payModeItem).length}');
    print('#invalid promotions: ${invalidPromotionList.length}');
    print('------- end of summary -------');

    // double totalBillDiscount = 0;
    // double totalLineDiscount = 0;
    // List<PromotionFreeItems> promotionFreeItems = [];

    totalBillDiscount = 0;
    totalLineDiscount = 0;
    promotionFreeItems = [];
    promotionBillDisc = [];
    //going through item level and bill value promotions
    for (var promotion in otherPromoList) {
      final String promoCode = promotion.prOCODE ?? '';
      //get promotion5 details
      List<PromotionDetailsList> promotionDetailsList = [];
      final promoDetailsRes = await getPromotionDetails(
          promoCode,
          _buildItems(cartList).values.toList(),
          (promotion.pGPSKUBIDACT ? 1 : 0),
          promotion.pGPRICEMODE,
          promotion.prOPRICEMODE ?? '');
      promotionDetailsList = promoDetailsRes?.promotionDetails ?? [];

      if (promotion.pGINCLACT &&
          (promoDetailsRes?.includeItems ?? []).isEmpty) {
        continue;
      }

      if (promotion.pGPRICEMODE == 1 &&
          (promoDetailsRes?.priceModeItems ?? []).isEmpty) {
        continue;
      }
      cartList = await _calculateItemWisePromotions(
          promoDetailsRes, cartList, promotionDetailsList, promotion);
      /*
      //
      if (promotion.pGINCLACT &&
          (promoDetailsRes?.includeItems ?? []).isNotEmpty &&
          promotion.pGINCLACTITEM &&
          promotion.pGINCLACTQTY &&
          promotion.pGPSKUBIDACT == false &&
          promotion.pGGRPBIDACT == false) {
        cartList = await _calPromoForIncludeBasedOnItemQty(
            promoDetailsRes, cartList, promotionDetailsList, promotion);
        //continue;
      }

      if (promotion.pGINCLACT == false &&
          promotion.pGPSKUBIDACT == true &&
          promotion.pGGRPBIDACT == false) {
        cartList = await _calPromoOfferBasedOnCombinationQty(
            promoDetailsRes, cartList, promotionDetailsList, promotion);
      }

      if (promotion.pGINCLACT &&
          (promoDetailsRes?.includeItems ?? []).isNotEmpty &&
          promotion.pGINCLACTITEM &&
          promotion.pGINCLACTCOMBINATION &&
          promotion.prOSTBILLNET == 0 &&
          promotion.prOENBILLNET == 0 &&
          promotion.pGPSKUBIDACT == false &&
          promotion.pGGRPBIDACT == false) {
        _calPromoForIncludeBasedOnCombinationQty(
            promoDetailsRes, cartList, promotionDetailsList, promotion);
      }

      if (promotion.pGINCLACT &&
          (promoDetailsRes?.includeItems ?? []).isNotEmpty &&
          promotion.pGINCLACTITEM &&
          promotion.pGINCLACTCOMBINATION &&
          promotion.prOSTBILLNET == 0 &&
          promotion.prOENBILLNET == 0 &&
          promotion.pGPSKUBIDACT == true &&
          (promoDetailsRes?.includeItems ?? []).isNotEmpty) {
        _calPromoOfferBasedOnCombinationQty(
            promoDetailsRes, cartList, promotionDetailsList, promotion);
      }
      if (promotion.prOSTBILLNET != 0 &&
          promotion.prOENBILLNET != 0 &&
          promotion.pGPSKUBIDACT == false &&
          promotion.pGGRPBIDACT == false) {
        cartList = await _calBillValPromo(
            promoDetailsRes, cartList, promotionDetailsList, promotion);
      }
      */

      // for (var promotionDetail in promotionDetailsList) {
      //   // calculate promotions
      //   _PromoDiscountResult promotionCalcRes =
      //       await _applyItemLevelNBillValuePromotion(
      //           promotion, promotionDetail, cartList, promoDetailsRes);

      //   cartList = promotionCalcRes.cartList;
      //   totalBillDiscount += promotionCalcRes.totalBillPromotion;
      //   totalLineDiscount += promotionCalcRes.totalLinePromotion;
      //   promotionFreeItems.addAll(promotionCalcRes.promoFreeItems);
      // }
    }

    //going trough all payment mode wise promotion and get the bill amount
    List<SelectablePaymentModeWisePromotions> selectablePromotions = [];
    for (var promotion in paymentModePromoList) {
      selectablePromotions.addAll(await calculatePaymentModePromotion(promotion,
          cartList, promotion.prOCODE ?? '', promotion.prODESC ?? '', false));
    }

    //List<SelectableCouponPromotions> selectableCouponPromotions = [];
    for (var promotion in couponPromoList) {
      selectablePromotions.addAll(await calculateCouponRedeemPromotion(
          promotion,
          cartList,
          promotion.prOCODE ?? '',
          promotion.prODESC ?? '',
          false));
    }

    EasyLoading.dismiss();
    cartBloc.addPromoFreeItems(promotionFreeItems);
    cartBloc.addPromoFreeGVs(promotionFreeGVs);
    cartBloc.addPromoFreeTickets(promotionFreeTickets);
    if (totalBillDiscount == 0 &&
        totalLineDiscount == 0 &&
        selectablePromotions.length == 0 &&
        promotionFreeItems.length == 0 &&
        promotionFreeGVs.length == 0 &&
        promotionFreeTickets.length == 0 &&
        promotionBillDisc.length == 0) return;

    await _showPromotionDiscounts(cartList, totalBillDiscount,
        totalLineDiscount, selectablePromotions, promotionBillDisc);
  }

  List<CartModel> applyPromoBillDiscPer(
      {required List<CartModel> cartList,
      required List<String> keyList,
      required double validQty,
      required double discPer,
      required double promoAllowValue,
      required String promoCode,
      required String promoName,
      required double promoOfferedAmt}) {
    double promoRemainQty = validQty;
    CartModel item;
    for (String key in keyList) {
      item = cartList.where((element) => element.key == key).first;
      item.promoCode = promoCode;
      item.promoDesc = promoName;
    }

    double discount = promoAllowValue * discPer / 100;
    discount = (validQty > 0 && validQty < promoAllowValue
        ? validQty * discPer / 100
        : discount);
    //totalBillDiscount = discount;

    promotionBillDisc.add(InvBillDiscAmountPromo(
        POSConfig().locCode,
        promoCode,
        promoName,
        '',
        false,
        discPer,
        discount,
        0,
        '',
        0,
        0,
        0,
        'INV',
        DateTime.now(),
        '',
        '',
        promoOfferedAmt,
        discount));

    if (POSConfig().setup?.addPromoDiscAsItem == true) {
      //Add as an item
      //TODO: store DISCOUNT in a global variable
      final CartModel discItem = CartModel(
          setUpLocation: POSConfig().setupLocation,
          proCode: "DISCOUNT",
          stockCode: "DISCOUNT",
          posDesc: "DISCOUNT",
          lineRemark: [],
          proSelling: discount,
          selling: discount,
          unitQty: -1,
          amount: -1 * discount,
          noDisc: false,
          scanBarcode: "SYSTEM GENERATED",
          maxDiscPer: 0,
          maxDiscAmt: 0);
      discItem.key = '${discItem.proCode}$promoCode';
      discItem.lineNo = cartList.length + 1;
      discItem.promoCode = promoCode;
      discItem.promoDesc = promoName;
      discItem.promoBillDiscPre = discPer;
      discItem.itemVoid = false;
      discItem.discAmt = 0;
      discItem.discPer = 0;
      discItem.billDiscPer = 0;
      cartList.add(discItem);
    } else {
      //Add as a payment mode
      final payModeList = payModeBloc.payModeResult?.payModes ?? [];
      int index =
          payModeList.indexWhere((element) => element.pHLINKPROMO == true);
      if (index != -1) {
        final String phCode = payModeList[index].pHCODE ?? '';
        final String phdesc = payModeList[index].pHDESC ?? '';
        cartBloc.reversePaymentModePromo(promoCode);
        cartBloc.addPayment(PaidModel(discount, discount, false, phCode, phCode,
            promoCode, null, null, phdesc, phdesc));
      }
    }
    return cartList;
  }

  List<CartModel> applyPromoBillDiscAmt(
      {required List<CartModel> cartList,
      required List<String> keyList,
      required double validQty,
      required double discAmt,
      required String promoCode,
      required String promoName,
      required double promoOfferedAmt}) {
    CartModel item;
    for (String key in keyList) {
      item = cartList.where((element) => element.key == key).first;
      item.promoCode = promoCode;
      item.promoDesc = promoName;
    }

    //totalBillDiscount = discAmt;
    promotionBillDisc.add(InvBillDiscAmountPromo(
        POSConfig().locCode,
        promoCode,
        promoName,
        '',
        false,
        0,
        discAmt,
        0,
        '',
        0,
        0,
        0,
        'INV',
        DateTime.now(),
        '',
        '',
        promoOfferedAmt,
        discAmt));
    if (POSConfig().setup?.addPromoDiscAsItem == true) {
      //Add as an item
      //TODO: store DISCOUNT in a global variable
      final CartModel discItem = CartModel(
          setUpLocation: POSConfig().setupLocation,
          proCode: "DISCOUNT",
          stockCode: "DISCOUNT",
          posDesc: "DISCOUNT",
          lineRemark: [],
          proSelling: discAmt,
          selling: discAmt,
          unitQty: -1,
          amount: -1 * discAmt,
          noDisc: false,
          scanBarcode: "SYSTEM GENERATED",
          maxDiscPer: 0,
          maxDiscAmt: 0);
      discItem.key = '${discItem.proCode}$promoCode';
      discItem.lineNo = cartList.length + 1;
      discItem.promoCode = promoCode;
      discItem.promoDesc = promoName;
      discItem.promoBillDiscPre = 0;
      discItem.itemVoid = false;
      discItem.discAmt = 0;
      discItem.discPer = 0;
      discItem.billDiscPer = 0;
      cartList.add(discItem);
    } else {
      //Add as a payment mode
      final payModeList = payModeBloc.payModeResult?.payModes ?? [];
      int index =
          payModeList.indexWhere((element) => element.pHLINKPROMO == true);
      if (index != -1) {
        final String phCode = payModeList[index].pHCODE ?? '';
        final String phdesc = payModeList[index].pHDESC ?? '';
        cartBloc.reversePaymentModePromo(promoCode);
        cartBloc.addPayment(PaidModel(discAmt, discAmt, false, phCode, phCode,
            promoCode, null, null, phdesc, phdesc));
      }
    }
    return cartList;
  }

  List<CartModel> applyPromoDiscPer(
      {required List<CartModel> cartList,
      required List<String> keyList,
      required double validQty,
      required double discPer,
      required String promoCode,
      required String promoName,
      required bool checkSKUWiseValidQty}) {
    double promoRemainQty = validQty;
    String appliedPromoCode = '';
    CartModel item;
    if (!checkSKUWiseValidQty) {
      for (String key in keyList) {
        item = cartList.where((element) => element.key == key).first;
        appliedPromoCode = item.promoCode ?? '';
        if (validQty > 0 && item.unitQty > promoRemainQty) {
          if (appliedPromoCode != '') continue;
          double remainQty = item.unitQty - promoRemainQty;
          final newItem = CartModel.fromLocalMap(item.toMap());
          item.unitQty = promoRemainQty;
          item.promoDiscPre = discPer;
          item.amount = (item.unitQty * item.selling) -
              (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
          item.promoCode = promoCode;
          item.promoDesc = promoName;
          totalLineDiscount +=
              (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
          item.promoDiscValue =
              (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
          // add new item to cart

          newItem.unitQty = remainQty;
          newItem.amount = newItem.unitQty * newItem.selling;
          newItem.lineNo = cartList.length;
          newItem.key += 'promo_$remainQty';
          cartList.add(newItem);
          break;
        } else {
          if (appliedPromoCode != '') continue;
          //Apply promo disc
          item.promoDiscPre = discPer;
          item.amount = (item.unitQty * item.selling) -
              (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
          promoRemainQty -= item.unitQty;
          item.promoCode = promoCode;
          item.promoDesc = promoName;

          totalLineDiscount +=
              (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
          item.promoDiscValue =
              (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
          if (promoRemainQty <= 0 && validQty > 0) break;
        }
      }
    } else {
      Map<String, double> discountedQty = {};
      for (String key in keyList) {
        item = cartList.where((element) => element.key == key).first;
        appliedPromoCode = item.promoCode ?? '';
        if (discountedQty.containsKey(item.proCode) &&
            discountedQty[item.proCode]! < validQty) {
          //check whether the unit qty of current cart item is grater than the remaining discount eligible qty so that we have to split the cart item
          if (validQty > 0 &&
              item.unitQty > validQty - discountedQty[item.proCode]!) {
            if (appliedPromoCode != '') continue;

            //get the remaining qty to be discounted for the SKU
            double remainQty =
                item.unitQty - (validQty - discountedQty[item.proCode]!);
            final newItem = CartModel.fromLocalMap(item.toMap());
            item.unitQty = (validQty - discountedQty[item.proCode]!);

            //update the discounted qty by the current qty
            discountedQty[item.proCode] =
                (discountedQty[item.proCode]!) + item.unitQty;

            item.promoDiscPre = discPer;
            item.amount = (item.unitQty * item.selling) -
                (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
            item.promoCode = promoCode;
            item.promoDesc = promoName;
            totalLineDiscount +=
                (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
            item.promoDiscValue =
                (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
            // add new item to cart

            newItem.unitQty = remainQty;
            newItem.amount = newItem.unitQty * newItem.selling;
            newItem.lineNo = cartList.length;
            newItem.key += 'promo_$remainQty';
            cartList.add(newItem);
          } else {
            if (appliedPromoCode != '') continue;
            //Apply promo disc
            item.promoDiscPre = discPer;
            item.amount = (item.unitQty * item.selling) -
                (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);

            //update the discounted qty by the current qty
            discountedQty[item.proCode] =
                (discountedQty[item.proCode]!) + item.unitQty;

            item.promoCode = promoCode;
            item.promoDesc = promoName;

            totalLineDiscount +=
                (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
            item.promoDiscValue =
                (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
          }
        } else {
          if (appliedPromoCode != '') continue;
          if (discountedQty.containsKey(item.proCode)) continue;
          //Apply promo disc
          item.promoDiscPre = discPer;
          item.amount = (item.unitQty * item.selling) -
              (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);

          //update the discounted qty by the current qty
          discountedQty[item.proCode] = item.unitQty;

          item.promoCode = promoCode;
          item.promoDesc = promoName;

          totalLineDiscount +=
              (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
          item.promoDiscValue =
              (item.unitQty * item.selling * (item.promoDiscPre ?? 0) / 100);
        }
      }
    }
    return cartList;
  }

  List<CartModel> applyPromoDiscAmt(
      {required List<CartModel> cartList,
      required List<String> keyList,
      required double validQty,
      required double discAmt,
      required String promoCode,
      required String promoName}) {
    double promoRemainQty = validQty;
    CartModel item;
    for (String key in keyList) {
      item = cartList.where((element) => element.key == key).first;
      if (validQty > 0 && item.unitQty > promoRemainQty) {
        double remainQty = item.unitQty - promoRemainQty;
        final newItem = CartModel.fromLocalMap(item.toMap());
        item.unitQty = promoRemainQty;
        item.promoDiscAmt = (discAmt * item.unitQty);
        item.promoDiscValue = item.promoDiscAmt;
        item.amount = (item.unitQty * item.selling) - (item.promoDiscAmt ?? 0);
        item.promoCode = promoCode;
        item.promoDesc = promoName;
        totalLineDiscount += discAmt;
        // add new item to cart

        newItem.unitQty = remainQty;
        newItem.amount = newItem.unitQty * newItem.selling;
        newItem.lineNo = cartList.length;
        newItem.key += 'promo_$remainQty';
        cartList.add(newItem);
        break;
      } else {
        //Apply promo disc
        item.promoDiscAmt = (discAmt * item.unitQty);
        item.promoDiscValue = item.promoDiscAmt;
        item.amount = (item.unitQty * item.selling) - (item.promoDiscAmt ?? 0);
        promoRemainQty -= item.unitQty;
        item.promoCode = promoCode;
        item.promoDesc = promoName;
        totalLineDiscount += discAmt;
        if (promoRemainQty <= 0 && validQty > 0) break;
      }
    }
    return cartList;
  }

  List<CartModel> applyPromoPriceModeDiscAmt(
      {required List<CartModel> cartList,
      required List<String> keyList,
      required double validQty,
      required double discAmt,
      required String promoCode,
      required String promoName,
      required PromotionPriceModeSKU PriceModeSKUList}) {
    double promoRemainQty = validQty;
    CartModel item;
    for (String key in keyList) {
      item = cartList.where((element) => element.key == key).first;
      if (validQty > 0 && item.unitQty > promoRemainQty) {
        double remainQty = item.unitQty - promoRemainQty;
        final newItem = CartModel.fromLocalMap(item.toMap());
        item.unitQty = promoRemainQty;
        //item.promoDiscAmt = discAmt;
        item.promoDiscAmt = (discAmt * item.unitQty);
        item.promoDiscValue = item.promoDiscAmt;
        item.amount = (item.unitQty * item.selling) -
            ((item.promoDiscAmt ?? 0) * item.unitQty);
        item.promoCode = promoCode;
        item.promoDesc = promoName;
        //totalLineDiscount += discAmt;
        totalLineDiscount += item.promoDiscAmt ?? 0;
        // add new item to cart

        newItem.unitQty = remainQty;
        newItem.amount = newItem.unitQty * newItem.selling;
        newItem.lineNo = cartList.length;
        newItem.key += 'promo_$remainQty';
        cartList.add(newItem);
        break;
      } else {
        //Apply promo disc
        item.promoDiscAmt = (discAmt * item.unitQty);
        item.promoDiscValue = item.promoDiscAmt;
        item.amount = (item.unitQty * item.selling) -
            ((item.promoDiscAmt ?? 0) * item.unitQty);
        promoRemainQty -= item.unitQty;
        item.promoCode = promoCode;
        item.promoDesc = promoName;
        totalLineDiscount += item.promoDiscAmt ?? 0;
        if (promoRemainQty <= 0 && validQty > 0) break;
      }
    }
    return cartList;
  }

  Future<List<CartModel>> applyPromoFreeIssueSKU(
      {required List<CartModel> cartList,
      required List<String> keyList,
      required double freeQty,
      required String freeItemBundle,
      required String promoCode,
      required String promoName}) async {
    bool promoAssigned = false;
    for (String key in keyList) {
      if (!promoAssigned) {
        var freeItems = await getPromotionSku(freeItemBundle);
        promotionFreeItems.add(PromotionFreeItems(
            freeItems
                .map((e) => PromotionFreeItemDetails(
                    proCode: e.pskUPLUCODE ?? '', proDesc: e.pskUDESC ?? ''))
                .toList(),
            freeQty,
            freeQty,
            cartList.where((element) => element.key == key).first.stockCode,
            promoCode,
            promoName,
            freeItemBundle));
        promoAssigned = true;
        final CartModel item =
            cartList.where((element) => element.key == key).first;
        item.promoCode = promoCode;
        item.promoDesc = promoName;
      } else {
        final CartModel item =
            cartList.where((element) => element.key == key).first;
        item.promoCode = promoCode;
        item.promoDesc = promoName;
      }
    }
    return cartList;
  }

  Future<List<CartModel>> applyPromoFreeGV(
      {required List<CartModel> cartList,
      required List<String> keyList,
      required double freeQty,
      required double gvValue,
      required String promoCode,
      required String promoName}) async {
    bool promoAssigned = false;
    for (String key in keyList) {
      if (!promoAssigned) {
        promotionFreeGVs.add(PromotionFreeGVs(
            gvValue,
            freeQty,
            freeQty,
            cartList.where((element) => element.key == key).first.stockCode,
            promoCode,
            promoName,
            'VOUCHER'));
        //TODO: apply GV category name above
        promoAssigned = true;
        final CartModel item =
            cartList.where((element) => element.key == key).first;
        item.promoCode = promoCode;
        item.promoDesc = promoName;
      } else {
        final CartModel item =
            cartList.where((element) => element.key == key).first;
        item.promoCode = promoCode;
        item.promoDesc = promoName;
      }
    }
    return cartList;
  }

  Future<List<CartModel>> applyPromoTickets(
      {required List<CartModel> cartList,
      required List<String> keyList,
      required double freeQty,
      required String ticketId,
      required String promoCode,
      required String promoName,
      required double ticketVal,
      required double ticketBillVal,
      required DateTime ticketRedeemFromDate,
      required DateTime ticketRedeemToDate,
      required double ticketRedeemFromVal,
      required double ticketRedeemToVal,
      required double promoEligibleVal}) async {
    bool promoAssigned = false;
    double ticketOfferValue = 0;

    for (String key in keyList) {
      if (!promoAssigned) {
        if (ticketVal > 0) {
          ticketOfferValue = ticketVal;
        } else if (ticketBillVal > 0) {
          ticketOfferValue = promoEligibleVal * ticketBillVal / 100;
        } else {
          ticketOfferValue = 0;
        }
        var random = Random();
        String ticketSerial = "";
        int numberOfIterations = freeQty.toInt();

        for (int i = 0; i < numberOfIterations; i++) {
          // Generate a random number for voucher
          int randomNumber = random.nextInt(100);
          ticketSerial =
              cartBloc.cartSummary!.invoiceNo + randomNumber.toStringAsFixed(0);
          promotionFreeTickets.add(PromotionFreeTickets(
              ticketId,
              promoCode,
              promoName,
              1,
              ticketOfferValue,
              ticketRedeemFromDate,
              ticketRedeemToDate,
              ticketRedeemFromVal,
              ticketRedeemToVal,
              ticketSerial,
              POSConfig().comCode));
        }

        promoAssigned = true;
        final CartModel item =
            cartList.where((element) => element.key == key).first;
        item.promoCode = promoCode;
        item.promoDesc = promoName;
      } else {
        final CartModel item =
            cartList.where((element) => element.key == key).first;
        item.promoCode = promoCode;
        item.promoDesc = promoName;
      }
    }
    return cartList;
  }

  ///Calculations on payment mode wise promotions
  Future<List<SelectablePaymentModeWisePromotions>>
      calculatePaymentModePromotion(
          Promotion promotion,
          List<CartModel> cartList,
          String promoCode,
          String promoDesc,
          bool apply) async {
    double discountAmount = 0;
    List<PromotionFreeTickets> ticketList = [];
    List<SelectablePaymentModeWisePromotions> selectablePayModePromoList = [];
    //fetch promotion details
    List<PromotionDetailsList> promotionDetailsList = [];
    final promoDetailsRes = await getPromotionDetails(
        promoCode,
        _buildItems(cartList).values.toList(),
        (promotion.pGPSKUBIDACT ? 1 : 0),
        0,
        '');
    promotionDetailsList = promoDetailsRes?.promotionDetails ?? [];

    if (promotion.pGINCLACT && (promoDetailsRes?.includeItems ?? []).isEmpty)
      return selectablePayModePromoList;
    //apply item wise promotions if available
    // for (var promotionDetail in promotionDetailsList) {
    //   _PromoDiscountResult promotionCalcRes =
    //       await _applyItemLevelNBillValuePromotion(
    //     promotion,
    //     promotionDetail,
    //     cartList,
    //     promoDetailsRes,
    //     assign: false,
    //   );
    //   discountAmount += promotionCalcRes.totalLinePromotion;
    // }
    double summarizedTotalQty = 0;
    double summarizedTotalValue = 0;

    if (promotion.pGINCLACT && !promotion.pGINCLACTCOMBINATION) {
      for (PromotionIncludeExcludeSku includeItem
          in promoDetailsRes?.includeItems ?? []) {
        List<CartModel> includeCartItemList = cartList
            .where((element) =>
                element.proCode == includeItem.pluCode &&
                _validForPromotion(element, promoDetailsRes))
            .toList();
        //get the total quantity of valid items
        summarizedTotalQty += includeCartItemList.fold(
            0, (sum, element) => sum + element.unitQty);
        //get the total amount of valid items
        summarizedTotalValue +=
            includeCartItemList.fold(0, (sum, element) => sum + element.amount);
      }
    }
    final payModesPromoList = await getSpecificPayMode(promoCode);

    if (discountAmount > 0) {
      final payModePromo = SelectablePaymentModeWisePromotions(
          code: promoCode,
          desc: promoDesc,
          amount: discountAmount,
          phCode: payModesPromoList.first.proPPHCODE ?? '',
          discPre: payModesPromoList.first.proPDISCPER ?? 0,
          pdCode: payModesPromoList.first.proPPDCODE ?? '',
          cardBin: payModesPromoList.first.promoCardBin,
          cashBackCoupons: ticketList,
          isCouponPromo: false,
          couponNo: '',
          promoEligibleValue: 0,
          uniqueCoupon: promotion.proCOUPONTYPE == 1 ? true : false);
      selectablePayModePromoList.add(payModePromo);
    } else {
      //going through pay mode list
      for (var payMode in payModesPromoList) {
        // going through cart details
        double applicableBillValue = 0;
        discountAmount = 0;
        final double minVal = payMode.proPMIN ?? 0;
        final double maxVal = payMode.proPMAX ?? 0;
        final double discPer = payMode.proPDISCPER ?? 0;
        for (var cartItem in cartList) {
          if (_validForPromotion(cartItem, promoDetailsRes)) {
            applicableBillValue += cartItem.amount;
          }
        }
        if (promotion.pGINCLACT) {
          applicableBillValue = summarizedTotalValue;
        }
        //validate promotion values
        if (minVal > applicableBillValue) {
          continue;
        }
        if (applicableBillValue >= maxVal) {
          applicableBillValue = maxVal;
        }

        //check whether the promotion is a discount offer or cash back coupon
        if (discPer < 0) {
          //Cash back coupon (Ticket)
          PromotionDetailsList? detailsList = promotionDetailsList
              .where((element) =>
                  element.proDMINVAL! <= applicableBillValue &&
                  element.proDMAXVAL! >= applicableBillValue)
              .first;
          discountAmount =
              applicableBillValue * detailsList.ptiCKBILLVALUE! / 100;

          var random = Random();
          String ticketSerial = "";
          int numberOfIterations = detailsList.proDTICKQTY!.toInt();

          for (int i = 0; i < numberOfIterations; i++) {
            // Generate a random number for voucher
            int randomNumber = random.nextInt(100);
            ticketSerial = cartBloc.cartSummary!.invoiceNo +
                randomNumber.toStringAsFixed(0);
            ticketList.add(PromotionFreeTickets(
                detailsList.proDTICKETID!,
                promoCode,
                promoDesc,
                1,
                discountAmount,
                detailsList.ptiCKREDEFROM!,
                detailsList.ptiCKREDETO!,
                detailsList.ptiCKREDEEMBILLVALFROM!,
                detailsList.ptiCKREDEEMBILLVALTO!,
                ticketSerial,
                POSConfig().comCode));
          }

          final payModePromo = SelectablePaymentModeWisePromotions(
              code: promoCode,
              desc: promoDesc,
              amount: discountAmount,
              discPre: payMode.proPDISCPER ?? 0,
              phCode: payMode.proPPHCODE ?? '',
              pdCode: payMode.proPPDCODE ?? '',
              cardBin: payMode.promoCardBin,
              cashBackCoupons: ticketList,
              isCouponPromo: false,
              couponNo: '',
              promoEligibleValue: applicableBillValue,
              uniqueCoupon: promotion.proCOUPONTYPE == 1 ? true : false);
          selectablePayModePromoList.add(payModePromo);
        } else {
          discountAmount = applicableBillValue * discPer / 100;

          final payModePromo = SelectablePaymentModeWisePromotions(
              code: promoCode,
              desc: promoDesc,
              amount: discountAmount,
              discPre: payMode.proPDISCPER ?? 0,
              phCode: payMode.proPPHCODE ?? '',
              pdCode: payMode.proPPDCODE ?? '',
              cardBin: payMode.promoCardBin,
              cashBackCoupons: ticketList,
              isCouponPromo: false,
              couponNo: '',
              promoEligibleValue: applicableBillValue,
              uniqueCoupon: promotion.proCOUPONTYPE == 1 ? true : false);
          selectablePayModePromoList.add(payModePromo);
        }
      }
    }
    return selectablePayModePromoList;
  }

  Future<List<SelectablePaymentModeWisePromotions>>
      calculateCouponRedeemPromotion(
          Promotion promotion,
          List<CartModel> cartList,
          String promoCode,
          String promoDesc,
          bool apply) async {
    double discountAmount = 0;
    List<SelectablePaymentModeWisePromotions> selectableCouponPromos = [];
    //fetch promotion details
    List<PromotionDetailsList> promotionDetailsList = [];

    final promoDetailsRes = await getPromotionDetails(
        promoCode,
        _buildItems(cartList).values.toList(),
        (promotion.pGPSKUBIDACT ? 1 : 0),
        0,
        '');
    promotionDetailsList = promoDetailsRes?.promotionDetails ?? [];

    if (promotion.pGINCLACT && (promoDetailsRes?.includeItems ?? []).isEmpty)
      return selectableCouponPromos;

    double summarizedTotalQty = 0;
    double summarizedTotalValue = 0;

    if (promotion.pGINCLACT && !promotion.pGINCLACTCOMBINATION) {
      for (PromotionIncludeExcludeSku includeItem
          in promoDetailsRes?.includeItems ?? []) {
        List<CartModel> includeCartItemList = cartList
            .where((element) =>
                element.proCode == includeItem.pluCode &&
                _validForPromotion(element, promoDetailsRes))
            .toList();
        //get the total quantity of valid items
        summarizedTotalQty += includeCartItemList.fold(
            0, (sum, element) => sum + element.unitQty);
        //get the total amount of valid items
        summarizedTotalValue +=
            includeCartItemList.fold(0, (sum, element) => sum + element.amount);
      }
    }

    // going through cart details
    double applicableBillValue = 0;
    discountAmount = 0;

    for (var cartItem in cartList) {
      if (_validForPromotion(cartItem, promoDetailsRes)) {
        applicableBillValue += cartItem.amount;
      }
    }
    if (promotion.pGINCLACT) {
      applicableBillValue = summarizedTotalValue;
    }

    PromotionDetailsList? detailsList = promotionDetailsList
        .where((element) =>
            element.proDMINVAL! <= applicableBillValue &&
            element.proDMAXVAL! >= applicableBillValue)
        .firstOrNull;
    if (detailsList == null) return [];
    if (promotion.pGDISCPERACT)
      discountAmount = applicableBillValue * detailsList.proDDISCPER! / 100;
    else if (promotion.pGDISCAMTACT) discountAmount = detailsList.proDDISCAMT!;

    final payModePromo = SelectablePaymentModeWisePromotions(
        code: promoCode,
        desc: promoDesc,
        amount: discountAmount,
        cardBin: [],
        cashBackCoupons: [],
        couponNo: '',
        isCouponPromo: true,
        discPre: detailsList.proDDISCPER!,
        pdCode: '',
        phCode: '',
        promoEligibleValue: applicableBillValue,
        uniqueCoupon: promotion.proCOUPONTYPE == 1 ? true : false);

    selectableCouponPromos.add(payModePromo);

    return selectableCouponPromos;
  }

  /// Calculate item wise and bill value promotions
  /// assign parameter is used to apply promotion to the cart item list
  /// Returns [_PromoDiscountResult]
  Future<_PromoDiscountResult> _applyItemLevelNBillValuePromotion(
      Promotion promotion,
      PromotionDetailsList promotionDetails,
      List<CartModel> paraCartDetailsList,
      PromotionDetailsResult? promoDetailsRes,
      {bool assign = true,
      bool skipvalidation = false}) async {
    double totalLineWiseDiscountAmount = 0;
    double totalBillDiscountAmount = 0;

    final String promoProductCode = promotionDetails.pskUPLUCODE ?? '';
    final String promoGroupBundle = promotionDetails.proGROUPBUNDLEGROUPS ?? '';

    //promotion valid item qty
    final double validQty = promotionDetails.proDVALIDQTY ?? 0;

    List<CartModel> cartDetails = paraCartDetailsList;
    List<PromotionFreeItems> promoFreeItemList = [];
    List<PromotionFreeGVs> promoFreeGVList = [];

    //split cart if there is a valid qty is
    if (validQty > 0) {
      //select the items for relevant product code
      final selectedItems = paraCartDetailsList
          .where((element) =>
              element.proCode == promoProductCode &&
              _validForPromotion(element, promoDetailsRes))
          .toList();
      //going through selected items and split it
      for (var item in List.of(selectedItems)) {
        item = CartModel.fromLocalMap(item.toMap());
        //check the qty is exceeded the valid qty
        if (item.unitQty > validQty) {
          double remainQty = item.unitQty - validQty;
          item.unitQty = validQty;
          item.amount = item.unitQty * item.selling;
          //add changed item to cart details
          int index =
              cartDetails.indexWhere((element) => element.key == item.key);
          cartDetails[index] = item;

          //Reason for using toMap and fromMap( Get rid of object reference of
          //lists
          // add new item to cart
          final newItem = CartModel.fromLocalMap(item.toMap());
          newItem.unitQty = remainQty;
          newItem.amount = newItem.unitQty * newItem.selling;
          newItem.lineNo = cartDetails.length;
          newItem.key += 'promo_$remainQty';
          cartDetails.add(newItem);
        }
      }
    }

    //calculate item wise promotions
    bool promotionApplied = false;
    final double maximumDiscountAmount = promotionDetails.proDMAXVAL ?? 0;
    final double minimumDiscountAmount = promotionDetails.proDMINVAL ?? 0;
    final double discountPre = promotionDetails.proDDISCPER ?? 0;
    final double minQty = promotionDetails.proDMINQTY ?? 0;
    final double maxQty = promotionDetails.proDMAXQTY ?? 0;
    //promotion applied item qty
    double appliedItemCount = 0;

    //check include
    //item based or combination based promo
    bool itemPromo = promotion.pGINCLACTITEM;
    //qty promo or value base promo
    bool qtyPromo = promotion.pGINCLACTQTY;
    List<String> groupBundleItemList = [];
    if (promoGroupBundle.isNotEmpty) {
      //TODO: Assign bundle list to map to increase performance
      groupBundleItemList = await getPromotionGroupBundle(promoGroupBundle);
    }

    for (int i = 0; i < cartDetails.length; i++) {
      promotionApplied = false;
      final item = cartDetails[i];
      bool invalidProduct = true;
      if (groupBundleItemList.isNotEmpty) {
        invalidProduct = !groupBundleItemList.contains(item.proCode);
      } else {
        invalidProduct = promoProductCode != item.proCode;
      }
      // check the promotion is bill value or not
      if (promoProductCode.isEmpty && groupBundleItemList.isEmpty) {
        invalidProduct = false;
      }

      //check item validity for promotion
      if (!_validForPromotion(item, promoDetailsRes) || invalidProduct) {
        continue;
      }

      bool skipPromo = false;

      // calculate item value promotion
      if (promoProductCode.isNotEmpty ||
          promoGroupBundle.isNotEmpty ||
          (promoDetailsRes?.includeItems ?? []).isNotEmpty) {
        // fetch the group bundle

        //check qty or value of the promotion
        if (promotion.pGINCLACT) {
          if (qtyPromo) {
            if (!(minQty <= item.unitQty && item.unitQty <= maxQty)) {
              skipPromo = true;
            }
          } else {
            if (!(minimumDiscountAmount <= item.amount &&
                item.amount <= maximumDiscountAmount)) {
              skipPromo = true;
            }
          }
        } else {
          if (!(minQty <= item.unitQty && item.unitQty <= maxQty)) {
            skipPromo = true;
          }
        }

        //calculate promotion amount
        double discountAmt = promotionDetails.proDDISCAMT ?? 0;
        final String freeItemBundle = promotionDetails.proDFREEITEM ?? '';

        //valid qty available and if the item count exceed it
        if (validQty != 0 && appliedItemCount == validQty) {
          // promotion applied true because of valid qty exceeded
          skipPromo = true;
        }
        //calculate discount amount or percentage for promotion not applied items
        if (!promotionApplied && !skipPromo) {
          if (discountAmt != 0 || discountPre != 0) {
            item.promoDiscAmt = discountAmt;
            item.promoDiscPre = discountPre;
            final double newAmount = _calculateDiscountAmount(
                item.amount, discountAmt, discountPre, maximumDiscountAmount);
            totalLineWiseDiscountAmount += (item.amount - newAmount);
            item.amount = newAmount;
            promotionApplied = true;
            appliedItemCount += item.unitQty;
          } else if (freeItemBundle.isNotEmpty) {
            final double qty = promotionDetails.proDFREEQTY ?? 0;
            var freeItems = await getPromotionSku(freeItemBundle);
            promoFreeItemList.add(PromotionFreeItems(
                freeItems
                    .map((e) => PromotionFreeItemDetails(
                        proCode: e.pskUPLUCODE ?? '',
                        proDesc: e.pskUDESC ?? ''))
                    .toList(),
                qty,
                qty,
                item.proCode,
                promotionDetails.prOCODE ?? '',
                promotionDetails.prODESC ?? '',
                freeItemBundle));
            promotionApplied = false;
          }
        }
      } else {
        //bill value promotion calculation
        final double newAmount = _calculateDiscountAmount(
            item.amount, 0, discountPre, maximumDiscountAmount);
        totalBillDiscountAmount += (item.amount - newAmount);
        item.promoBillDiscPre = discountPre;
        // item.amount = newAmount;
        promotionApplied = true;
        if (assign)
          cartBloc.addBillPromotionToSummary(
              discountPre, promotionDetails.prOCODE ?? '');
      }
      // add promotion code for promotion applied items
      if (promotionApplied) {
        item.promoCode = promotionDetails.prOCODE;
        item.promoDesc = promotionDetails.prODESC;
      }
      if (assign) {
        cartDetails[i] = item;
      }
    }

    return _PromoDiscountResult(totalBillDiscountAmount,
        totalLineWiseDiscountAmount, promoFreeItemList, cartDetails);
  }

  /// calculated discount price
  double _calculateDiscountAmount(double amount, double? discAmount,
      double? discPre, double maxDiscountValue) {
    double calculatedAmount = 0;
    if (discAmount != null && discAmount != 0) {
      calculatedAmount = discAmount;
    } else if (discPre != null && discPre != 0) {
      calculatedAmount = discPre * amount / 100;
    }

    if (maxDiscountValue != 0 && calculatedAmount > maxDiscountValue) {
      calculatedAmount = maxDiscountValue;
    }
    return amount - calculatedAmount;
  }

  ///Summarize all items into an item(key) wise map by adding quantities
  Map<String, PromoCartItemDto> _buildItems(List<CartModel> currentCart) {
    Map<String, PromoCartItemDto> cart = {};
    //merge current cart
    for (var cartItem in currentCart) {
      if (!_validForPromotion(cartItem, null)) {
        continue;
      }

      final String proCode = cartItem.proCode;
      final double qty = cartItem.unitQty;

      //get the dto from map
      PromoCartItemDto? dto = cart[proCode];
      // if dto is null create new object
      if (dto == null) {
        dto = PromoCartItemDto(productCode: proCode);
      }
      dto.qty = qty;
      cart[proCode] = dto;
    }
    return cart;
  }

  /// validate cart item for promotion
  /// return true for valid items
  /// This function will validate whether any kind of discounts is already applied for the item or whether the item is "No Discount Item". if any of these
  /// scenarios are applied, then the item is not eligible for the promotion.
  bool _validForPromotion(
      CartModel item, PromotionDetailsResult? promoDetailsRes) {
    final double billDiscPre = item.billDiscPer ?? 0;
    final double discAmt = item.discAmt ?? 0;
    final double discPer = item.discPer ?? 0;
    final String promoCode = item.promoCode ?? '';

    final List<PromotionIncludeExcludeSku> excludeList =
        promoDetailsRes?.excludeItems ?? [];
    int excludeIndex = -1;
    //check item in exclude list
    if (excludeList.isNotEmpty) {
      excludeIndex =
          excludeList.indexWhere((element) => element.pluCode == item.proCode);
    }

    return excludeIndex == -1 &&
        item.itemVoid == false &&
        item.noDisc == false &&
        item.allowDiscount == true &&
        promoCode.isEmpty &&
        billDiscPre == 0 &&
        discAmt == 0 &&
        discPer == 0;
  }

  /// This method will validate promotion bill value, start end time
  /// and loyalty
  Future<PromotionStat> validatePromotionStep1(Promotion promotion,
      double billValue, DateTime serverTime, CustomerResult? customer) async {
    double startBillValue = promotion.prOSTBILLNET ?? 0;
    double endBillValue = promotion.prOENBILLNET ?? 0;

    //check promotionTime
    final int differenceWithDefaultDate =
        serverTime.difference(DateTime(1900, 01, 01)).inDays;
    final DateTime startTime =
        promotion.prOSTTIME.add(Duration(days: differenceWithDefaultDate));
    final DateTime endTime =
        promotion.prOENTIME.add(Duration(days: differenceWithDefaultDate));
    if (startTime.isBefore(serverTime) && endTime.isAfter(serverTime)) {
      bool billValuePromo = startBillValue != 0 && endBillValue != 0;
      bool validPromo = false;
      if (billValuePromo) {
        validPromo = startBillValue <= billValue && endBillValue >= billValue;
      } else {
        validPromo = true;
      }
      if (!validPromo) return PromotionStat.invalid;

      validPromo =
          await validatePromotionCustomer(promotion, customer, serverTime);
      if (!validPromo) return PromotionStat.invalid;
      if (promotion.pGCOUPONREDEMPTION) {
        return PromotionStat.couponRedeem;
      }
      bool paymentModeWisePromo = await paymentModeWisePromotion(promotion);
      if (!paymentModeWisePromo) {
        if (billValuePromo) {
          return PromotionStat.billValue;
        } else {
          return PromotionStat.item;
        }
      } else {
        if (billValuePromo) {
          return PromotionStat.payModeBillValue;
        } else if (promotion.pGCOUPONREDEMPTION) {
          return PromotionStat.couponRedeem;
        } else {
          return PromotionStat.payModeItem;
        }
      }
    }
    return PromotionStat.invalid;
  }

  /// check whether promotion is for payment modes
  /// return true for payment mode wise promotion
  Future<bool> paymentModeWisePromotion(Promotion promotion) async {
    return promotion.pGPAYACT;
  }

  /// validate promotion for customers
  /// returns true for valid promotions
  Future<bool> validatePromotionCustomer(Promotion promotion,
      CustomerResult? customer, DateTime serverTime) async {
    //check the promotion is for member
    if (!promotion.pGCUSSPECIFIC) {
      return true;
    }

    //customer not available for customer based promotions
    if (customer == null) {
      return false;
    }

    // if this promotion is for loyalty customers
    if (promotion.prOLOYALCUSTOMERS) {
      //loyalty customer not available for loyalty promotion
      if (customer.cMLOYALTY != true) {
        return false;
      }
    }

    //check for customer bundle
    String customerIncBundle = promotion.proICUSGROUPS ?? '';
    String customerExcBundle = promotion.proECUSGROUPS ?? '';
    if (customerIncBundle.isNotEmpty) {
      // check customer is in inclusive bundle
      int index = customerBloc.customerBundles
          .indexWhere((element) => element.bunDCODE == customerIncBundle);
      if (index == -1) {
        return false;
      }
    }
    if (customerExcBundle.isNotEmpty) {
      // check customer is in exclusive bundle
      int index = customerBloc.customerBundles
          .indexWhere((element) => element.bunDCODE == customerExcBundle);
      if (index != -1) {
        return false;
      }
    }

    //check anniversary
    if (promotion.prOANNIVERSARY) {
      final int? month = customer.anniversary?.month;
      final int? day = customer.anniversary?.day;
      //if anniversary is null
      if (day == null || month == null) {
        return false;
      }
      return serverTime.day == day && serverTime.month == month;
    }
    //check birthday
    if (promotion.prOBDAY) {
      //if birthday is null
      if (customer.birthDay == null) {
        return false;
      }

      final int? year = customer.birthDay!.year;
      final int? month = customer.birthDay!.month;
      final int? day = customer.birthDay!.day;

      return serverTime.year == year &&
          serverTime.day == day &&
          serverTime.month == month;
    }

    //check the invoice count
    if (promotion.prOCUSLIMIT != null && promotion.prOCUSLIMIT != 0) {
      final List<CustomerPromotion> result = customerBloc.customerPromotion
          .where((element) => element.prCPROMOCODE == promotion.prOCODE)
          .toList();
      return (result.length < (promotion.prOCUSLIMIT ?? 0));
    }
    return true;
  }

  /// display promotion popup
  Future<void> _showPromotionDiscounts(
      List<CartModel> cartList,
      double totalBillDiscount,
      double totalLineDiscount,
      List<SelectablePaymentModeWisePromotions> selectablePromotions,
      List<InvBillDiscAmountPromo> billDiscPromo) async {
    int canShowSkip = -1;
    SelectablePaymentModeWisePromotions? selectablePayMode = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('promo.title'.tr(), textAlign: TextAlign.center),
          content: SizedBox(
            width: ScreenUtil().screenWidth,
            height: ScreenUtil().screenHeight,
            child: PromotionView(
                cartList: cartList,
                totalBillDiscount: totalBillDiscount,
                totalLineDiscount: totalLineDiscount,
                selectablePromotions: selectablePromotions,
                billDiscPromotions: billDiscPromo),
          ),
          actions: [
            if (canShowSkip != -1)
              AlertDialogButton(
                  onPressed: () {
                    cartBloc.clearPromoTickets();
                    Navigator.pop(context);
                  },
                  text: 'promo.skip'.tr()),
            AlertDialogButton(
                onPressed: () {
                  _calculator.applyPromotions(cartList, totalBillDiscount,
                      totalLineDiscount, billDiscPromo);
                  Navigator.pop(context);
                },
                text: 'promo.continue'.tr())
          ],
        );
      },
    );
    if (selectablePayMode != null) {
      //clear paymode promotions if already applied
      cartBloc.reversePaymentModePromo(selectablePayMode.code);
      //Add line level promotion discount to the cart summary
      _calculator.applyPromotions(
          cartList, totalBillDiscount, totalLineDiscount, billDiscPromo);

      //check whether the Cash back coupon offer or discount offer or coupon redeem offer
      if (selectablePayMode.cashBackCoupons.isEmpty &&
          !selectablePayMode.isCouponPromo) {
        //Discount offer
        //add discount amount to link promo pay mode
        cartBloc.addSpecificPayMode(selectablePayMode);
        final payModeList = payModeBloc.payModeResult?.payModes ?? [];
        int index =
            payModeList.indexWhere((element) => element.pHLINKPROMO == true);
        if (index != -1) {
          final String phCode = payModeList[index].pHCODE ?? '';
          final String phdesc = payModeList[index].pHDESC ?? '';
          cartBloc.addPayment(PaidModel(
              selectablePayMode.amount,
              selectablePayMode.amount,
              false,
              phCode,
              phCode,
              selectablePayMode.code,
              null,
              null,
              phdesc,
              phdesc));
        }
        cartBloc.addBillPromotionToSummary(
            selectablePayMode.discPre, selectablePayMode.code);
        cartBloc.addInvPromotion(InvAppliedPromotion(
            POSConfig().locCode,
            selectablePayMode.code,
            '',
            false,
            selectablePayMode.discPre,
            selectablePayMode.amount,
            0,
            selectablePayMode.phCode,
            0,
            0,
            0,
            'INV',
            DateTime.now(),
            selectablePayMode.pdCode,
            '',
            selectablePayMode.promoEligibleValue,
            selectablePayMode.desc,
            selectablePayMode.amount));
      } else if (selectablePayMode.isCouponPromo) {
        //Coupon redeem offer - No specific payment mode
        TextEditingController coupon_controller = new TextEditingController();
        String couponCode = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Scan/Enter Coupon Numebr',
                    textAlign: TextAlign.center),
                content: SizedBox(
                  width: ScreenUtil().screenWidth / 2,
                  height: ScreenUtil().screenHeight * 0.4,
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/coupon.png",
                        height: 200,
                        width: 200,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: coupon_controller,
                        onEditingComplete: () async {
                          var isValid = await validateCoupon(
                              coupon_controller.text,
                              selectablePayMode.code,
                              selectablePayMode.uniqueCoupon);
                          print('isValid: $isValid');
                          if (isValid) {
                            Navigator.pop(context, coupon_controller.text);
                          } else
                            return;
                        },
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
                actions: [
                  AlertDialogButton(
                      onPressed: () {
                        //cartBloc.clearPromoTickets();
                        Navigator.pop(context, '');
                      },
                      text: 'promo.skip'.tr()),
                  AlertDialogButton(
                      onPressed: () async {
                        var isValid = await validateCoupon(
                            coupon_controller.text,
                            selectablePayMode.code,
                            selectablePayMode.uniqueCoupon);
                        if (isValid) {
                          Navigator.pop(context, coupon_controller.text);
                        } else
                          return;
                      },
                      text: 'promo.continue'.tr())
                ],
              );
            });

        if (couponCode != '') {
          selectablePayMode.couponNo = couponCode;
          final payModeList = payModeBloc.payModeResult?.payModes ?? [];
          int index =
              payModeList.indexWhere((element) => element.pHLINKPROMO == true);
          if (index != -1) {
            final String phCode = payModeList[index].pHCODE ?? '';
            final String phdesc = payModeList[index].pHDESC ?? '';
            cartBloc.addPayment(PaidModel(
                selectablePayMode.amount,
                selectablePayMode.amount,
                false,
                phCode,
                phCode,
                selectablePayMode.code,
                null,
                null,
                phdesc,
                phdesc));
          }

          cartBloc.addInvPromotion(InvAppliedPromotion(
              POSConfig().locCode,
              selectablePayMode.code,
              '',
              false,
              selectablePayMode.discPre,
              selectablePayMode.amount,
              0,
              selectablePayMode.couponNo,
              0,
              0,
              0,
              'INV',
              DateTime.now(),
              selectablePayMode.couponNo,
              '',
              selectablePayMode.promoEligibleValue,
              selectablePayMode.desc,
              selectablePayMode.amount));
          List<RedeemedCoupon> redeemedCouponList = [];
          redeemedCouponList.add(new RedeemedCoupon(
              couponCode: selectablePayMode.couponNo,
              uniqueCoupon: selectablePayMode.uniqueCoupon,
              promoCode: selectablePayMode.code));

          cartBloc.addRedeemedCoupons(redeemedCouponList);
          return;
        }
      } else {
        //Cash back coupon offer
        cartBloc.addSpecificPayMode(selectablePayMode);
        cartBloc.addBillPromotionToSummary(0, selectablePayMode.code);

        for (int i = 0; i < selectablePayMode.cashBackCoupons.length; i++) {
          final item = selectablePayMode.cashBackCoupons[i];
          cartBloc.addInvPromotion(InvAppliedPromotion(
              POSConfig().locCode,
              selectablePayMode.code,
              '',
              false,
              selectablePayMode.discPre,
              selectablePayMode.amount,
              0,
              selectablePayMode.phCode,
              0,
              0,
              0,
              'INV',
              DateTime.now(),
              selectablePayMode.pdCode,
              item.ticketSerial,
              selectablePayMode.promoEligibleValue,
              selectablePayMode.desc,
              selectablePayMode.amount));
        }
        cartBloc.addPromoFreeTickets(selectablePayMode.cashBackCoupons);
      }
    }
  }

  Future<bool> validateCoupon(
      String coupon, String promoCode, bool uniqueCoupon) async {
    if (coupon == '') return false;
    if (!uniqueCoupon) return true;
    PromotionCoupon? res = await getCoupon(coupon, promoCode);
    if (res != null) {
      if (res.isRedeem) {
        EasyLoading.showError('promo.coupon_already_redeem'.tr());
        return false;
      } else {
        return true;
      }
    } else {
      EasyLoading.showError('promo.invalid_coupon'.tr());
      return false;
    }
  }

  /* Get Promotions API */
  /* By Dinuka 2022/07/28 */
  Future<PromotionListResult?> getPromotions() async {
    final res = await ApiClient.call(
        "promotion?loc=${POSConfig().locCode}&comCode=${POSConfig().comCode}",
        ApiMethod.GET,
        successCode: 200);
    if (res?.data == null) {
      return null;
    }
    final promoRes = PromotionListResult.fromJson(res?.data);
    final promotionsList = promoRes.promotions ?? [];
    //
    if (promotionsList.isNotEmpty) {
      promotionBloc.addPromotions(promotionsList);
    }
    return promoRes;
  }

  Future<PromotionCoupon?> getCoupon(String coupon, String promoCode) async {
    final res = await ApiClient.call(
        "promotion/coupon?code=$coupon&promoCode=$promoCode", ApiMethod.GET,
        successCode: 200);
    if (res?.data == null) {
      return null;
    }
    final promoRes = PromotionCoupon.fromJson(res?.data["coupon_info"][0]);
    return promoRes;
  }

  Future<List<PromotionSku>> getPromotionSku(String code) async {
    final res = await ApiClient.call(
        "promotion/bundles/?code=$code", ApiMethod.GET,
        successCode: 200);
    List<PromotionSku> sku = <PromotionSku>[];
    if (res?.data != null) {
      final PromotionSkuResult? skuRes = PromotionSkuResult.fromJson(res!.data);
      sku = skuRes?.promotionSku ?? [];
    }
    return sku;
  }

  ///Get promotion details from server (ITEM WISE / GROUP WISE OFFERS)
  Future<PromotionDetailsResult?> getPromotionDetails(
      String promoCode,
      List<PromoCartItemDto> cart,
      int checkSKU,
      int checkPriceMode,
      String priceMode) async {
    final res = await ApiClient.call("promotion/details", ApiMethod.POST,
        successCode: 200,
        data: {
          'promoCode': promoCode,
          'checkSKU': checkSKU,
          'cart': cart.map((e) => e.toMap()).toList(),
          'priceModeCheck': checkPriceMode,
          'location': POSConfig().locCode,
          'priceMode': priceMode
        });
    if (res?.data != null) {
      final promoRes = PromotionDetailsResult.fromJson(res?.data);
      return promoRes;
    }
  }

  ///Get promotion details from server (ITEM WISE / GROUP WISE OFFERS)
  Future<PromotionDetailsResult?> getPromotionDetailsBillValue(
      String promoCode, double billvalue, List<PromoCartItemDto> cart) async {
    final res = await ApiClient.call("promotion/details", ApiMethod.POST,
        successCode: 200,
        data: {
          'promoCode': promoCode,
          'billvalue': billvalue,
          'cart': cart.map((e) => e.toMap()).toList()
        });
    if (res?.data != null) {
      final promoRes = PromotionDetailsResult.fromJson(res?.data);
      return promoRes;
    }
  }

  /// Get promotion paymodes
  Future<List<SpecificPayMode>> getSpecificPayMode(String promoCode) async {
    final res = await ApiClient.call(
        'promotion/paymodes?code=$promoCode', ApiMethod.GET);
    if (res?.data != null) {
      final specificPayModeRes = SpecificPayModeRes.fromJson(res?.data);
      return specificPayModeRes.paymodes ?? [];
    }
    return [];
  }

  /// Get promotion group bundles
  Future<List<String>> getPromotionGroupBundle(String bundleCode) async {
    final res = await ApiClient.call(
        'promotion/group_bundle?bundleCode=$bundleCode', ApiMethod.GET);
    if (res?.data != null) {
      final groupRes = PromotionGroupBundleResult.fromJson(res?.data);
      return groupRes.groupBundles ?? [];
    }
    return [];
  }

  Future<List<CartModel>> _calculateItemWisePromotions(
      PromotionDetailsResult? promoDetailsRes,
      List<CartModel> cartList,
      List<PromotionDetailsList> promotionDetailsList,
      Promotion promotion) async {
    List<String> keyList = [];
    double summarizedTotalQty = 0;
    double summarizedTotalValue = 0;

    if (promotion.pGPRICEMODE == 1) {
      //check for Price Mode wise promotion
      for (PromotionPriceModeSKU priceModeItem
          in promoDetailsRes?.priceModeItems ?? []) {
        List<CartModel> priceModeCartItemList = cartList
            .where((element) =>
                element.proCode == priceModeItem.pluCode &&
                _validForPromotion(element, promoDetailsRes))
            .toList();
        //get the total quantity of valid items
        summarizedTotalQty += priceModeCartItemList.fold(
            0, (sum, element) => sum + element.unitQty);
        //get the total amount of valid items
        summarizedTotalValue += priceModeCartItemList.fold(
            0, (sum, element) => sum + element.amount);
        keyList.addAll(priceModeCartItemList.map((e) => e.key));
        cartList = await applyPromoPriceModeDiscAmt(
            cartList: cartList,
            keyList: keyList,
            discAmt: priceModeItem.discAmt,
            PriceModeSKUList: priceModeItem,
            promoCode: (promotion.prOCODE ?? ''),
            promoName: (promotion.prODESC ?? ''),
            validQty: 0);
        keyList = [];
        summarizedTotalQty = 0;
        summarizedTotalValue = 0;
      }
    } else if (promotion.pGINCLACT &&
        !promotion.pGINCLACTCOMBINATION &&
        !promotion.pGPSKUBIDACT) {
      //check for Include bundle SKUs (not combinations)
      for (PromotionIncludeExcludeSku includeItem
          in promoDetailsRes?.includeItems ?? []) {
        List<CartModel> includeCartItemList = cartList
            .where((element) =>
                element.proCode == includeItem.pluCode &&
                _validForPromotion(element, promoDetailsRes))
            .toList();
        //get the total quantity of valid items
        summarizedTotalQty += includeCartItemList.fold(
            0, (sum, element) => sum + element.unitQty);
        //get the total amount of valid items
        summarizedTotalValue +=
            includeCartItemList.fold(0, (sum, element) => sum + element.amount);
        keyList.addAll(includeCartItemList.map((e) => e.key));
      }

      cartList = await _chackWithPromoDetailCombinations(
          cartList: cartList,
          keyList: keyList,
          promoDetailsRes: promoDetailsRes,
          promotion: promotion,
          promotionDetailsList: promotionDetailsList,
          summarizedTotalQty: summarizedTotalQty,
          summarizedTotalValue: summarizedTotalValue);
      keyList = [];
      summarizedTotalQty = 0;
      summarizedTotalValue = 0;
      //
      //
    } else if (promotion.pGINCLACT &&
        promotion.pGINCLACTCOMBINATION &&
        !promotion.pGPSKUBIDACT) {
      //get only the promo eligible items to a list by dropping already discounted/promo excluded items/no discount items/void items etc.
      List<CartModel> includeCartItemList = [];
      List<CartModel> includeCartItemList1 = [];
      for (PromotionIncludeExcludeSku includeItem
          in promoDetailsRes?.includeItems ?? []) {
        includeCartItemList = cartList
            .where((element) =>
                element.proCode == includeItem.pluCode &&
                _validForPromotion(element, promoDetailsRes))
            .toList();

        keyList.addAll(includeCartItemList.map((e) => e.key));
        includeCartItemList1.addAll(includeCartItemList);
      }
      //Compairing valid include items in the cart (includeCartItemList) with the include items (promoDetailsRes?.includeItems) and get a distinct list of bundles
      List<dynamic> distinctListOfBundles = includeCartItemList1
          .expand((CartModel) => (promoDetailsRes?.includeItems ?? [])
              .where((PromotionIncludeExcludeSku) =>
                  CartModel.proCode == PromotionIncludeExcludeSku.pluCode)
              .map((PromotionIncludeExcludeSku) =>
                  PromotionIncludeExcludeSku.bundleCode))
          .toSet()
          .toList();
      summarizedTotalQty = distinctListOfBundles.length.toDouble();
      cartList = await _chackWithPromoDetailCombinations(
          cartList: cartList,
          keyList: keyList,
          promoDetailsRes: promoDetailsRes,
          promotion: promotion,
          promotionDetailsList: promotionDetailsList,
          summarizedTotalQty: summarizedTotalQty,
          summarizedTotalValue: summarizedTotalValue);
      keyList = [];
      summarizedTotalQty = 0;
      summarizedTotalValue = 0;
      //
      //
      //
    } else if (promotion.pGPSKUBIDACT) {
      //check for Offer bundles
      List<String?>? bundle_list = promoDetailsRes?.offerItems!
          .map((e) {
            if (e is PromotionOfferSKU) {
              // Replace YourObjectType with the actual type of objects in offerItems
              return e.bundleCode; // Access the property directly
            } else {
              return null;
            }
          })
          .where((element) => element != null)
          .toSet()
          .toList();

      /* Starting a loop on promo valid offer items detected in the cart and calculate total qty and total value of those to check with promo details combinations */
      for (String? offerBundle in bundle_list ?? []) {
        List<PromotionOfferSKU> offerSKUFroBundle =
            (promoDetailsRes?.offerItems ?? [])
                .where((element) => element.bundleCode == offerBundle)
                .toList();
        //get only the promo eligible items to a list by dropping already discounted/promo excluded items/no discount items/void items etc.
        for (PromotionOfferSKU offerItem in offerSKUFroBundle) {
          List<CartModel> offerCartItemList = cartList
              .where((element) =>
                  element.proCode == offerItem.pluCode &&
                  _validForPromotion(element, promoDetailsRes))
              .toList();
          //get the total quantity of valid items
          summarizedTotalQty += offerCartItemList.fold(
              0, (sum, element) => sum + element.unitQty);
          //get the total amount of valid items
          summarizedTotalValue +=
              offerCartItemList.fold(0, (sum, element) => sum + element.amount);
          //get keys of valid items and store them in a list to apply discounts
          keyList.addAll(offerCartItemList.map((e) => e.key));
        }
        cartList = await _chackWithPromoDetailCombinations(
            cartList: cartList,
            keyList: keyList,
            promoDetailsRes: promoDetailsRes,
            promotion: promotion,
            promotionDetailsList: promotionDetailsList,
            summarizedTotalQty: summarizedTotalQty,
            summarizedTotalValue: summarizedTotalValue,
            offerBundleCode: offerBundle ?? '');
        keyList = [];
        summarizedTotalQty = 0;
        summarizedTotalValue = 0;
      }
      //
      //
      //
    } else {
      List<CartModel> promoAllowItemList = cartList
          .where((element) => _validForPromotion(element, promoDetailsRes))
          .toList();
      //get the total quantity of valid items
      summarizedTotalQty +=
          promoAllowItemList.fold(0, (sum, element) => sum + element.unitQty);
      //get the total amount of valid items
      summarizedTotalValue +=
          promoAllowItemList.fold(0, (sum, element) => sum + element.amount);
      //get keys of valid items and store them in a list to apply discounts
      keyList.addAll(promoAllowItemList.map((e) => e.key));
      cartList = await _chackWithPromoDetailCombinations(
          cartList: cartList,
          keyList: keyList,
          promoDetailsRes: promoDetailsRes,
          promotion: promotion,
          promotionDetailsList: promotionDetailsList,
          summarizedTotalQty: summarizedTotalQty,
          summarizedTotalValue: summarizedTotalValue);
      //
      //
      //
    }
    return cartList;
  }

  Future<List<CartModel>> _chackWithPromoDetailCombinations(
      {required PromotionDetailsResult? promoDetailsRes,
      required List<CartModel> cartList,
      required List<PromotionDetailsList> promotionDetailsList,
      required List<String> keyList,
      required Promotion promotion,
      required double summarizedTotalQty,
      required double summarizedTotalValue,
      String offerBundleCode = ""}) async {
    for (PromotionDetailsList promoDet in promotionDetailsList) {
      if ((promoDet.proDMINQTY ?? 0) != 0 && (promoDet.proDMAXQTY ?? 0) != 0) {
        if ((promoDet.proDMINQTY ?? 0) <= summarizedTotalQty &&
            (promoDet.proDMAXQTY ?? 0) >= summarizedTotalQty) {
          //TODO
          if (offerBundleCode != "" && promoDet.pskUCODE != offerBundleCode)
            continue;
          cartList = await _applyOfferDetailsToTheCartItems(
              cartList: cartList,
              promotion: promotion,
              promoDet: promoDet,
              keyList: keyList,
              promoEligibleValue: summarizedTotalValue);
        }
      } else if ((promoDet.proDMINVAL ?? 0) != 0 &&
          (promoDet.proDMAXVAL ?? 0) != 0) {
        if (!promotion.pGEXCLUDEINCLUSIVE &&
            (promoDet.proDMINVAL ?? 0) <= summarizedTotalValue &&
            (promoDet.proDMAXVAL ?? 0) >= summarizedTotalValue) {
          cartList = await _applyOfferDetailsToTheCartItems(
              cartList: cartList,
              promotion: promotion,
              promoDet: promoDet,
              keyList: keyList,
              promoEligibleValue: summarizedTotalValue);
        } else if (promotion.pGEXCLUDEINCLUSIVE &&
            (promoDet.proDMINVAL ?? 0) <=
                cartBloc.cartSummary!.subTotal - summarizedTotalValue &&
            (promoDet.proDMAXVAL ?? 0) >=
                cartBloc.cartSummary!.subTotal - summarizedTotalValue) {
          cartList = await _applyOfferDetailsToTheCartItems(
              cartList: cartList,
              promotion: promotion,
              promoDet: promoDet,
              keyList: keyList,
              promoEligibleValue: summarizedTotalValue);
        }
      }
    }
    return cartList;
  }

  Future<List<CartModel>> _applyOfferDetailsToTheCartItems(
      {required List<CartModel> cartList,
      required List<String> keyList,
      required Promotion promotion,
      required PromotionDetailsList promoDet,
      required double promoEligibleValue}) async {
    if (promotion.pGDISCPERACT) {
      cartList = applyPromoDiscPer(
          cartList: cartList,
          keyList: keyList,
          validQty: promoDet.proDVALIDQTY ?? 0,
          discPer: promoDet.proDDISCPER ?? 0,
          promoCode: promoDet.prOCODE ?? '',
          promoName: promoDet.prODESC ?? '',
          checkSKUWiseValidQty: promotion.pGVALIDQTYCHECKSKU);
      //Discount per
    } else if (promotion.pGDISCAMTACT && !promotion.pGDISCAMTAPPLYTOBILL) {
      //Discount amt
      cartList = applyPromoDiscAmt(
          cartList: cartList,
          keyList: keyList,
          validQty: promoDet.proDVALIDQTY ?? 0,
          discAmt: promoDet.proDDISCAMT ?? 0,
          promoCode: promoDet.prOCODE ?? '',
          promoName: promoDet.prODESC ?? '');
    } else if (promotion.pGDISCAMTACT && promotion.pGDISCAMTAPPLYTOBILL) {
      //Discount amt
      cartList = applyPromoBillDiscAmt(
          cartList: cartList,
          keyList: keyList,
          validQty: promoDet.proDVALIDQTY ?? 0,
          discAmt: promoDet.proDDISCAMT ?? 0,
          promoCode: promoDet.prOCODE ?? '',
          promoName: promoDet.prODESC ?? '',
          promoOfferedAmt: promoEligibleValue);
    } else if (promotion.pGFSKUBIDACT) {
      //Free item
      cartList = await applyPromoFreeIssueSKU(
          cartList: cartList,
          keyList: keyList,
          freeQty: promoDet.proDFREEQTY ?? 0,
          freeItemBundle: promoDet.proDFREEITEM ?? '',
          promoCode: promoDet.prOCODE ?? '',
          promoName: promoDet.prODESC ?? '');
    } else if (promotion.pGVOUACT) {
      cartList = await applyPromoFreeGV(
          cartList: cartList,
          keyList: keyList,
          freeQty: promoDet.proDVOUQTY ?? 0,
          gvValue: promoDet.proDVOUVALUE ?? 0,
          promoCode: promoDet.prOCODE ?? '',
          promoName: promoDet.prODESC ?? '');
    } else if (promotion.pGTICKETACT) {
      cartList = await applyPromoTickets(
          cartList: cartList,
          keyList: keyList,
          freeQty: promoDet.proDTICKQTY ?? 0,
          ticketId: promoDet.proDTICKETID ?? '',
          promoCode: promoDet.prOCODE ?? '',
          promoName: promoDet.prODESC ?? '',
          ticketVal: promoDet.ptiCKVALUE ?? 0,
          ticketBillVal: promoDet.ptiCKBILLVALUE ?? 0,
          ticketRedeemFromDate: (promoDet.ptiCKREDEFROM ?? "01/01/1900")
              .toString()
              .parseDateTime(),
          ticketRedeemToDate:
              (promoDet.ptiCKREDETO ?? "01/01/1900").toString().parseDateTime(),
          ticketRedeemFromVal: promoDet.ptiCKREDEEMBILLVALFROM ?? 0,
          ticketRedeemToVal: promoDet.ptiCKBILLVALUE ?? 0,
          promoEligibleVal: promoEligibleValue);
    }
    return cartList;
  }

  Future<List<CartModel>> _calPromoForIncludeBasedOnItemQty(
      PromotionDetailsResult? promoDetailsRes,
      List<CartModel> cartList,
      List<PromotionDetailsList> promotionDetailsList,
      Promotion promotion) async {
    List<String> keyList = [];
    for (PromotionDetailsList promoDet in promotionDetailsList) {
      for (PromotionIncludeExcludeSku includeItem
          in promoDetailsRes?.includeItems ?? []) {
        List<CartModel> includeCartItemList = cartList
            .where((element) =>
                element.proCode == includeItem.pluCode &&
                _validForPromotion(element, promoDetailsRes))
            .toList();
        //TODO: add keys to a variable
        keyList.addAll(includeCartItemList.map((e) => e.key));
        double summarizedTotalQty = includeCartItemList.fold(
            0, (sum, element) => sum + element.unitQty);
        if ((promoDet.proDMINQTY ?? 0) <= summarizedTotalQty &&
            (promoDet.proDMAXQTY ?? 0) >= summarizedTotalQty) {
          if (promotion.pGDISCPERACT) {
            cartList = applyPromoDiscPer(
                cartList: cartList,
                keyList: keyList,
                validQty: promoDet.proDVALIDQTY ?? 0,
                discPer: promoDet.proDDISCPER ?? 0,
                promoCode: promoDet.prOCODE ?? '',
                promoName: promoDet.prODESC ?? '',
                checkSKUWiseValidQty: promotion.pGVALIDQTYCHECKSKU);
            //Discount per
          } else if (promotion.pGDISCAMTACT) {
            //Discount amt
            cartList = applyPromoDiscAmt(
                cartList: cartList,
                keyList: keyList,
                validQty: promoDet.proDVALIDQTY ?? 0,
                discAmt: promoDet.proDDISCAMT ?? 0,
                promoCode: promoDet.prOCODE ?? '',
                promoName: promoDet.prODESC ?? '');
          } else if (promotion.pGFSKUBIDACT) {
            //Free item
            cartList = await applyPromoFreeIssueSKU(
                cartList: cartList,
                keyList: keyList,
                freeQty: promoDet.proDFREEQTY ?? 0,
                freeItemBundle: promoDet.proDFREEITEM ?? '',
                promoCode: promoDet.prOCODE ?? '',
                promoName: promoDet.prODESC ?? '');
          } else if (promotion.pGVOUACT) {
            cartList = await applyPromoFreeGV(
                cartList: cartList,
                keyList: keyList,
                freeQty: promoDet.proDVOUQTY ?? 0,
                gvValue: promoDet.proDVOUVALUE ?? 0,
                promoCode: promoDet.prOCODE ?? '',
                promoName: promoDet.prODESC ?? '');
          }
        }
      }
    }
    return cartList;
  }

  Future<List<CartModel>> _calPromoForIncludeBasedOnCombinationQty(
      PromotionDetailsResult? promoDetailsRes,
      List<CartModel> cartList,
      List<PromotionDetailsList> promotionDetailsList,
      Promotion promotion) async {
    double summarizedTotalQty = 0;
    List<String> keyList = [];
    for (PromotionIncludeExcludeSku includeItem
        in promoDetailsRes?.includeItems ?? []) {
      List<CartModel> includeCartItemList = cartList
          .where((element) =>
              element.proCode == includeItem.pluCode &&
              _validForPromotion(element, promoDetailsRes))
          .toList();
      summarizedTotalQty +=
          includeCartItemList.fold(0, (sum, element) => sum + element.unitQty);
      keyList.addAll(includeCartItemList.map((e) => e.key));
    }

    for (PromotionDetailsList promoDet in promotionDetailsList) {
      if ((promoDet.proDMINQTY ?? 0) <= summarizedTotalQty &&
          (promoDet.proDMAXQTY ?? 0) >= summarizedTotalQty) {
        if (promotion.pGDISCPERACT) {
          cartList = applyPromoDiscPer(
              cartList: cartList,
              keyList: keyList,
              validQty: promoDet.proDVALIDQTY ?? 0,
              discPer: promoDet.proDDISCPER ?? 0,
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '',
              checkSKUWiseValidQty: promotion.pGVALIDQTYCHECKSKU);
          //Discount per
        } else if (promotion.pGDISCAMTACT) {
          //Discount amt
          cartList = applyPromoDiscAmt(
              cartList: cartList,
              keyList: keyList,
              validQty: promoDet.proDVALIDQTY ?? 0,
              discAmt: promoDet.proDDISCAMT ?? 0,
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '');
        } else if (promotion.pGFSKUBIDACT) {
          //Free item
          cartList = await applyPromoFreeIssueSKU(
              cartList: cartList,
              keyList: keyList,
              freeQty: promoDet.proDFREEQTY ?? 0,
              freeItemBundle: promoDet.proDFREEITEM ?? '',
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '');
        }
      }
    }
    return cartList;
  }

  Future<List<CartModel>> _calPromoOfferBasedOnCombinationQty(
      PromotionDetailsResult? promoDetailsRes,
      List<CartModel> cartList,
      List<PromotionDetailsList> promotionDetailsList,
      Promotion promotion) async {
    List<String> keyList = [];
    double summarizedTotalQty = 0;
    for (PromotionOfferSKU offerItem in promoDetailsRes?.offerItems ?? []) {
      List<CartModel> offerCartItemList = cartList
          .where((element) =>
              element.proCode == offerItem.pluCode &&
              _validForPromotion(element, promoDetailsRes))
          .toList();
      summarizedTotalQty +=
          offerCartItemList.fold(0, (sum, element) => sum + element.unitQty);
      keyList.addAll(offerCartItemList.map((e) => e.key));
    }
    if (summarizedTotalQty == 0) return cartList;
    for (PromotionDetailsList promoDet in promotionDetailsList) {
      if ((promoDet.proDMINQTY ?? 0) <= summarizedTotalQty &&
          (promoDet.proDMAXQTY ?? 0) >= summarizedTotalQty) {
        if (promotion.pGDISCPERACT) {
          cartList = applyPromoDiscPer(
              cartList: cartList,
              keyList: keyList,
              validQty: promoDet.proDVALIDQTY ?? 0,
              discPer: promoDet.proDDISCPER ?? 0,
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '',
              checkSKUWiseValidQty: promotion.pGVALIDQTYCHECKSKU);
          //Discount per
        } else if (promotion.pGDISCAMTACT) {
          //Discount amt
          cartList = applyPromoDiscAmt(
              cartList: cartList,
              keyList: keyList,
              validQty: promoDet.proDVALIDQTY ?? 0,
              discAmt: promoDet.proDDISCAMT ?? 0,
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '');
        } else if (promotion.pGFSKUBIDACT) {
          //Free item
          cartList = await applyPromoFreeIssueSKU(
              cartList: cartList,
              keyList: keyList,
              freeQty: promoDet.proDFREEQTY ?? 0,
              freeItemBundle: promoDet.proDFREEITEM ?? '',
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '');
        } else if (promotion.pGVOUACT) {
          cartList = await applyPromoFreeGV(
              cartList: cartList,
              keyList: keyList,
              freeQty: promoDet.proDVOUQTY ?? 0,
              gvValue: promoDet.proDVOUVALUE ?? 0,
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '');
        }
      }
    }
    return cartList;
  }

  Future<List<CartModel>> _calBillValPromo(
      PromotionDetailsResult? promoDetailsRes,
      List<CartModel> cartList,
      List<PromotionDetailsList> promotionDetailsList,
      Promotion promotion) async {
    List<String> keyList = [];
    double summarizedTotalValue = 0;
    for (PromotionDetailsList promoDet in promotionDetailsList) {
      List<CartModel> promoAllowItemList = cartList
          .where((element) => _validForPromotion(element, promoDetailsRes))
          .toList();
      summarizedTotalValue =
          promoAllowItemList.fold(0, (sum, element) => sum + element.amount);

      keyList.addAll(promoAllowItemList.map((e) => e.key));
      if ((promoDet.proDMINVAL ?? 0) <= summarizedTotalValue &&
          (promoDet.proDMAXVAL ?? 0) >= summarizedTotalValue) {
        if (promotion.pGDISCPERACT) {
          cartList = applyPromoBillDiscPer(
              cartList: cartList,
              keyList: keyList,
              validQty: promoDet.proDVALIDQTY ?? 0,
              discPer: promoDet.proDDISCPER ?? 0,
              promoAllowValue: summarizedTotalValue,
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '',
              promoOfferedAmt: 0);
          //Discount per
        } else if (promotion.pGFSKUBIDACT) {
          //Free item
          cartList = await applyPromoFreeIssueSKU(
              cartList: cartList,
              keyList: keyList,
              freeQty: promoDet.proDFREEQTY ?? 0,
              freeItemBundle: promoDet.proDFREEITEM ?? '',
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '');
        } else if (promotion.pGVOUACT) {
          cartList = await applyPromoFreeGV(
              cartList: cartList,
              keyList: keyList,
              freeQty: promoDet.proDVOUQTY ?? 0,
              gvValue: promoDet.proDVOUVALUE ?? 0,
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '');
        } else if (promotion.pGTICKETACT) {
          cartList = await applyPromoTickets(
              cartList: cartList,
              keyList: keyList,
              freeQty: promoDet.proDTICKQTY ?? 0,
              ticketId: promoDet.proDTICKETID ?? '',
              promoCode: promoDet.prOCODE ?? '',
              promoName: promoDet.prODESC ?? '',
              ticketVal: promoDet.ptiCKVALUE ?? 0,
              ticketBillVal: promoDet.ptiCKBILLVALUE ?? 0,
              ticketRedeemFromDate: (promoDet.ptiCKREDEFROM ?? "01/01/1900")
                  .toString()
                  .parseDateTime(),
              ticketRedeemToDate: (promoDet.ptiCKREDETO ?? "01/01/1900")
                  .toString()
                  .parseDateTime(),
              ticketRedeemFromVal: promoDet.ptiCKREDEEMBILLVALFROM ?? 0,
              ticketRedeemToVal: promoDet.ptiCKBILLVALUE ?? 0,
              promoEligibleVal: 0);
        }
      }
    }
    return cartList;
  }
}

enum PromotionStat {
  invalid,
  billValue,
  item,
  payModeBillValue,
  payModeItem,
  couponRedeem
}

class _PromoDiscountResult {
  final double totalBillPromotion;
  final double totalLinePromotion;
  final List<PromotionFreeItems> promoFreeItems;
  final List<CartModel> cartList;

  _PromoDiscountResult(this.totalBillPromotion, this.totalLinePromotion,
      this.promoFreeItems, this.cartList);
}
