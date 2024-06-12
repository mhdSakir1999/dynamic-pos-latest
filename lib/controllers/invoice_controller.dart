/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 5/19/21, 3:43 PM
 */

import 'dart:convert';

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/bloc/customer_coupons_bloc.dart';
import 'package:checkout/bloc/price_mode_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/components/ext_loyalty/ext_module_helper.dart';
import 'package:checkout/controllers/customer_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_manual_print_controller.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/controllers/sms_controller.dart';
import 'package:checkout/models/enum/signon_status.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/ecr_response.dart';
import 'package:checkout/models/pos/hed_remark_model.dart';
import 'package:checkout/models/pos/hold_header_result.dart';
import 'package:checkout/models/pos/inv_remarks.dart';
import 'package:checkout/models/pos/invoice_header_result.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos/price_mode_result.dart';
import 'package:checkout/models/pos/pro_tax.dart';
import 'package:checkout/models/pos_config.dart';

import 'package:checkout/extension/extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../models/pos/invoice_save_res.dart';
import 'dual_screen_controller.dart';
import 'local_storage_controller.dart';

class InvoiceController {
  LocalStorageController _localStorageController = LocalStorageController();

  String getInvPrefix() {
    return POSConfig().comCode.getLastNChar(2) +
        POSConfig().locCode.getLastNChar(2) +
        POSConfig().terminalId.getLastNChar(2);
  }

  Future<String> incrementInvoiceNo(String? invNo) async {
    int invNoInt = 6;
    if (invNo == null || invNo.isEmpty) {
      return getInvPrefix() + "1".padLeft(invNoInt, '0');
    }

    /// if invoice number is not null increment the invoice number
    int currentSeq = int.parse(invNo.replaceAll(getInvPrefix(), ''));
    return getInvPrefix() + (currentSeq + 1).toString().padLeft(invNoInt, '0');
  }

  Future setInvoiceNo(String invNo) async {
    await _localStorageController.setInvoice(invNo);
  }

  Future<String> getInvoiceNo() async {
    String? invNo = await _localStorageController.getInvoice();
    // if the current invoice no is null or empty, then get the last invoice no from the server
    if (invNo == null) {
      invNo = await getMaximumInvNo(getInvPrefix(), 'INV');
    }

    // whatever the invoice number (last invoiced), we save it in local storage
    // this will prevent errors when clear the invoice number
    setInvoiceNo(invNo!);

    String nextInv = await incrementInvoiceNo(invNo);
    //by Pubudu Wijetunge on 15/Sep/2023
    //Comment the setInvoice function calling due to the number skiping issue when clearing the invoice screen.
    //setInvoice will be called when the BillClose is completed.
    //await _localStorageController.setInvoice(nextInv);
    return nextInv;

    // final res = await ApiClient.call("invoice/no", ApiMethod.POST,
    //     local: true,
    //     formData: FormData.fromMap({"terminalNo": POSConfig().terminalId}));
    // return res?.data?["inv_no"]?.toString() ?? "";
  }

  Future<String> getUtilityInvoiceNo(String type) async {
    int? invNo = 0; //change -- from double to int
    int invNoInt = 6;
    String nextInv = "";

    final res = await ApiClient.call(
        'utilitybillsetup/next_utility_bill_no?type=$type&terminal=${POSConfig().terminalId}',
        ApiMethod.GET);
    if (res?.statusCode != 200) {
      return "";
    }
    //new change by TM.Sakir
    // invNo = double.parse(res?.data?["invNo"]); //the response is an int value...
    invNo = res!.data['invNo'];

    nextInv = type +
        POSConfig().comCode.getLastNChar(2) +
        POSConfig().locCode.getLastNChar(2) +
        POSConfig().terminalId.getLastNChar(2) +
        (invNo).toString().padLeft(invNoInt, '0');
    return nextInv;
  }

  Future updateTempCartSummary(CartSummaryModel cartSummaryModel) async {
    final cmCode = customerBloc.currentCustomer?.cMCODE;
    if (cmCode != null) {
      if (cartSummaryModel.items > 0) cartSummaryModel.customerCode = cmCode;
    }
    _localStorageController.updateCartSummary(cartSummaryModel);
    // await ApiClient.call("invoice/temp/update_summary", ApiMethod.POST,
    //     local: true, data: temp, successCode: 204,errorToast: false);
  }

  Future clearTemp() async {
    _localStorageController.clearTemp();
    // await ApiClient.call("invoice/temp/clear", ApiMethod.DELETE,
    //     local: true, successCode: 204);
  }

  Future<bool> saveItemTempCart(CartModel cartModel) async {
    // Map<String, dynamic> temp = cartModel.toMap();
    // temp["INVOICE_NO"] = cartBloc.cartSummary?.invoiceNo ?? "";

    // final res = await ApiClient.call("invoice/temp/save", ApiMethod.POST,
    //     local: true, data: temp, successCode: 204);
    return _localStorageController.saveItemToTempCart(cartModel);
  }

  Future<bool> updateTempCartItem(CartModel cartModel) async {
    return _localStorageController.updateTempCartItem(cartModel);
  }

  // Future updateCartItem(CartModel cartModel)async{
  //   Map<String,dynamic> temp = cartModel.toMap();
  //   temp["INVOICE_NO"] = cartBloc.cartSummary?.invoiceNo??"";
  //
  //   await ApiClient.call("invoice/temp/update", ApiMethod.POST,data: temp,successCode: 204);
  // }
  Future deleteItemFromTempCart(CartModel cartModel) async {
    // Map<String, dynamic> temp = {
    //   "INVOICE_NO": cartBloc.cartSummary?.invoiceNo ?? "",
    //   "TEMP_KEY": cartModel.key
    // };
    _localStorageController.removeItemFromTempCart(cartModel.key);
    // await ApiClient.call("invoice/temp/delete", ApiMethod.POST,
    //     local: true, data: temp, successCode: 204);
  }

  Future<bool> hasTempInvoice() async {
    // final res = await ApiClient.call("invoice/temp", ApiMethod.GET,
    //     local: true, errorToast: false);
    //
    final res = await _localStorageController.getCartSummary();
    if (res == null) {
      return false;
    }
    return (await _localStorageController.getCartItems()).length > 0;
  }

  /// this method will call once the the user load the screen
  Future<bool> loadCartFromTempTable() async {
    cartBloc.clearBLoc();
    final summary = await _localStorageController.getCartSummary();
    if (summary == null) {
      return false;
    }
    String memberCode = summary.customerCode ?? '';
    if (memberCode.isNotEmpty) {
      //  fetch customer
      final customer = await CustomerController().getCustomerByCode(memberCode);
      if (customer != null) {
        customerBloc.changeCurrentCustomer(customer, update: false);
      }
    }
    //get cart items from local db
    final items = await _localStorageController.getCartItems();
    int itemCount = 0;
    double qty = 0;
    double subTotal = 0;

    items.forEach((element) {
      final temp = element;
      final cartList = cartBloc.currentCart ?? {};
      //calculate price
      final founded = cartList.values.toList().indexWhere((e) =>
          e.proCode == temp.proCode &&
          e.itemVoid != true &&
          e.unitQty > 0 &&
          e.stockCode == temp.stockCode);
      bool alreadyAdded = founded != -1;
      bool minus = temp.unitQty.toDouble() < 0;
      if (!alreadyAdded && !minus && temp.itemVoid == false) {
        itemCount++;
      }
      if (!minus && temp.itemVoid == false) {
        qty += temp.unitQty;
      }
      var lineAmount =
          temp.amount - (temp.amount * (temp.billDiscPer ?? 0) / 100);
      // final zero =  0;
      // lineAmount -= temp.discAmt??0;
      // lineAmount -= (lineAmount * (temp.discPer??zero))/double.fromInt(100);
      if (temp.itemVoid == false) {
        subTotal += lineAmount;
      }
      cartBloc.updateCartUnconditionally(temp);
    });

    //temporary create copy of current cart summary with calculated total
    final cartSum = CartSummaryModel(
        invoiceNo: summary.invoiceNo,
        items: itemCount,
        qty: qty,
        startTime: summary.startTime,
        subTotal: subTotal,
        discPer: summary.discPer,
        priceMode: summary.priceMode,
        refMode: summary.refMode,
        refNo: summary.refNo);
    if (cartSum.subTotal != summary.subTotal) {
      EasyLoading.showError(
          'Warning...!\nPrice Mismatch detected,Recalculating price...');
      await Future.delayed(Duration(seconds: 2));
    }

    if (cartBloc.cartSummary != null) {
      cartSum.items = cartBloc.cartSummary?.items ?? itemCount;
    }

    // load payments
    final List<PaidModel> payments =
        await LocalStorageController().getPaidList();
    payments.forEach((element) {
      cartBloc.addPayment(element, savePayment: false);
    });

    //load reference
    final List<EcrCard> reference =
        await LocalStorageController().getPaymentReference();
    reference.forEach((element) {
      cartBloc.addNewReference(element, savePayment: false);
    });

    final List<PriceModes> priceModeList = priceModeBloc.priceModes;
    int index = priceModeList
        .indexWhere((element) => element.prMCODE == cartSum.priceMode);
    if (index != -1) {
      cartSum.priceModeDesc = priceModeList[index].prMDESC;
    }

    cartBloc.updateCartSummary(cartSum);
    InvoiceController().updateTempCartSummary(cartSum);

    return true;
  }

  /// Save payments details into temp payment
  Future<bool> saveTempPayment(PaidModel paidModel) async {
    return _localStorageController.saveTempPayment(paidModel);
    // final res = await ApiClient.call("invoice/temp/payment", ApiMethod.POST,
    //     local: true, errorToast: false, data: map);
  }

  /// Save payments details into temp payment
  Future<bool> saveReference(EcrCard card) async {
    return _localStorageController.savePaymentReference(card);
    // final res = await ApiClient.call("invoice/temp/payment", ApiMethod.POST,
    //     local: true, errorToast: false, data: map);
  }

  // close the bill
  Future<InvoiceSaveRes> billClose(
      {required bool invoiced,
      required BuildContext context,
      String? otp,
      String? referenceNo,
      double burnedPoints = 0,
      double payAmt = 0,
      double changeAmt = 0}) async {
    int lineNo = 0;
    double grossAmt = 0; // without discounts total bill value
    double lineDiscPer = 0;
    double lineDiscAmt = 0;
    bool hasExVoucher = false;
    List<dynamic> lineRemarks = [];

    final List<dynamic> cartList =
        cartBloc.currentCart?.values.toList().map((e) {
              //add to line remarks
              if (e.lineRemark.isNotEmpty) {
                for (var lineRemark in e.lineRemark) {
                  lineRemarks.add(InvoiceLineRemarks(
                          lineRemark: lineRemark, lineNo: e.lineNo)
                      .toMap());
                }
              }

              if (e.proCode.toLowerCase().startsWith('ex')) {
                hasExVoucher = true;
              }
              lineNo++;
              e.lineNo = lineNo;
              if (e.itemVoid == false) {
                grossAmt += (e.unitQty * e.selling).toDouble();
                lineDiscPer += (e.discPer ?? 0) + (e.promoDiscPre ?? 0);
                lineDiscAmt += e.discAmt ?? 0 + (e.promoDiscAmt ?? 0);
              }

              Map<String, dynamic> map = e.toMap();
              map['LINE_REMARK'] = '';
              return map;
            }).toList() ??
            [];

    double earnedLoyaltyPoints = 0;
    final List<dynamic> payments = cartBloc.paidList?.map((e) {
          earnedLoyaltyPoints += e.paidAmount * e.pointRate / 100;
          return e.toMap();
        }).toList() ??
        [];

    if (customerBloc.currentCustomer?.cMLOYALTY == false)
      earnedLoyaltyPoints = 0;

    final cartSummary = cartBloc.cartSummary!;
    final userDetails = userBloc.userDetails!;
    final double netAmt = cartSummary.subTotal;
    final double dueAmt = 0;
//--------------------------------------------------------------------------------------------------------------------------------
    /// validation by: [TM.Sakir]
    // Adding a validation for check whether the net amount and pro detail amounts are tallying
    // double calculatedDetNet = 0;
    // for (var pro in cartBloc.currentCart!.values.toList()) {
    //   // double tempBillDisc = 0;
    //   // if (pro.billDiscPer != null || pro.billDiscPer != 0) {
    //   //   tempBillDisc = (pro.unitQty * pro.selling).toDouble() *
    //   //       (pro.billDiscPer ?? 0) /
    //   //       100;
    //   // }
    //   // calculatedDetNet += pro.amount - tempBillDisc;

    //   if (pro.itemVoid != true) {
    //     double tempBillDisc =
    //         (pro.unitQty * pro.selling) * (pro.billDiscPer ?? 0) / 100;
    //     double tempLineDiscAmt = pro.discAmt ?? 0;
    //     double tempLineDiscPer =
    //         (pro.unitQty * pro.selling) * (pro.discPer ?? 0) / 100;
    //     double tempPromoDiscPer =
    //         (pro.unitQty * pro.selling) * (pro.promoDiscPre ?? 0) / 100;
    //     double tempPromoDiscAmt = pro.promoDiscAmt ?? 0;

    //     calculatedDetNet += (pro.unitQty * pro.selling) -
    //         (tempBillDisc +
    //             tempLineDiscAmt +
    //             tempLineDiscPer +
    //             tempPromoDiscPer +
    //             tempPromoDiscAmt);
    //   }
    // }
    // if (netAmt != calculatedDetNet) {
    //   EasyLoading.showError('Net amount calculation error');
    //   return InvoiceSaveRes(false, 0, null);
    // }
    // if (cartBloc.paidList != null && cartBloc.paidList != []) {
    //   double tempPaidTotal = 0;
    //   for (var paid in cartBloc.paidList!) {
    //     tempPaidTotal += paid.paidAmount;
    //   }
    //   if (netAmt != tempPaidTotal) {
    //     EasyLoading.showError('Paid amount calculation error');
    //     return InvoiceSaveRes(false, 0, null);
    //   }
    // }
//--------------------------------------------------------------------------------------------------------------------------------
    String cashier = userBloc.currentUser?.uSERHEDUSERCODE ?? "UnAuthorized";
    String tempCashier =
        userBloc.currentUser?.uSERHEDUSERCODE ?? "UnAuthorized";

    if (userBloc.signOnStatus == SignOnStatus.TempSignOn) {
      cashier = userBloc.signOnCashierForTemp ?? "";
    }
    String mobile = customerBloc.currentCustomer?.cMMOBILE ?? '';

    ///check start time
    String startTime = cartSummary.startTime;
    if (startTime.isEmpty) {
      final res = await _localStorageController.getCartSummary();
      startTime = res?.startTime ?? '';
      //still empty
    }
    print('+++++++++++++++++++++++++++++++++++++++++++');
    print(startTime);
    print('+++++++++++++++++++++++++++++++++++++++++++');

    Map<String, dynamic> temp = {
      'START_TIME': DateFormat('yyyy-MM-ddTHH:mm:ss.000')
          .format(startTime.parseDateTime()),
      "INV_DETAILS": cartList,
      "PAYMENTS": invoiced ? payments : [],
      "MEMBER_CODE": customerBloc.currentCustomer?.cMCODE ?? "",
      "INVOICE_NO": invoiced
          ? cartSummary.invoiceNo
          : 'HOLD_${cartSummary.invoiceNo + '_' + DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      "NET_AMOUNT": netAmt,
      "GROSS_AMOUNT": grossAmt,
      "PAY_AMOUNT": payAmt,
      "CHANGE_AMOUNT": changeAmt,
      "EARNED_POINTS": mobile.isNotEmpty ? earnedLoyaltyPoints : 0,
      "BURNED_POINTS": mobile.isNotEmpty ? burnedPoints : 0,
      "DUE_AMOUNT": dueAmt,
      "TERMINAL": POSConfig().terminalId,
      "SETUP_LOCATION": POSConfig().setupLocation,
      "CASHIER": cashier,
      "TEMP_SIGN_ON": tempCashier,
      "SHIFT_NO": userDetails.shiftNo,
      "SIGN_ON_DATE": userDetails.date,
      "COM_CODE": POSConfig().comCode,
      "LOC_CODE": POSConfig().locCode,
      "BILL_DISC_PER": cartSummary.discPer?.toDouble() ?? 0,
      "INVOICED": invoiced,
      "LINE_DISC_PER": lineDiscPer.toDouble(),
      "LINE_DISC_AMT": lineDiscAmt.toDouble(),
      "PRICE_MODE": cartSummary.priceMode,
      'REF_NO': cartSummary.refNo,
      'REF_MODE': cartSummary.refMode,
      'INV_REF': cartBloc.invReference?.map((e) => e.toJson()).toList() ?? [],
      'PRO_TAX': cartSummary.invTax.map((e) => e.toJson()).toList(),
      'TAX_INC': cartSummary.taxInc ?? 0,
      'TAX_EXC': cartSummary.taxExc ?? 0,
      'PROMO_FREE_ITEMS': [],
      'LOYALTY_OUTLET': POSConfig().loyaltyServerOutlet,
      'LINE_REMARKS': lineRemarks,
      'PROMO_DISC_PER': cartSummary.promoDiscountPre,
      'PROMO_CODE': cartSummary.promoCode ?? '',
      'FREE_ISSUE':
          cartBloc.promoAppliedList?.map((e) => e.toMap()).toList() ?? [],
      'INV_TICKETS':
          cartBloc.promoFreeTickets?.map((e) => e.toMap()).toList() ?? [],
      'REDEEMED_COUPONS':
          cartBloc.redeemedCoupon?.map((e) => e.toMap()).toList() ?? [],
      'HED_REMARKS': cartBloc.cartSummary?.hedRem == null
          ? []
          : [cartBloc.cartSummary?.hedRem!.toMap()]
    };

    // saving our sending data to log files
    List<String> result = [
      '--------------------Invoice map data (sending to \'invoice/save endpoint\')--------------------------------'
    ];
    await LogWriter().saveLogsToFile('API_Log_', [
      '####################################################################',
      jsonEncode(temp),
      '####################################################################'
    ]);
    temp.forEach((key, value) {
      result.add('$key: $value');
    });
    await LogWriter().saveLogsToFile('API_Log_', result);

    final res = await ApiClient.call(
        invoiced ? "invoice/save" : 'invoice/hold_invoice',
        ApiMethod.POST, //invoiced ? "invoice/save" : 'invoice/hold_invoice'
        data: temp,
        successCode: 200);

    if (hasExVoucher) {
      var resp = await ApiClient.call(
          "print/exchange_voucher/${cartSummary.invoiceNo}?reportPrint=${POSConfig().reportBasedInvoice}",
          ApiMethod.GET,
          local: true);
    }
    if (res?.statusCode != 200) {
      EasyLoading.showError('easy_loading.cant_save_inv'.tr());
      return InvoiceSaveRes(false, 0, null);
    }
    final success = res?.data?["success"] == true;
    final resReturn = res?.data?["res"].toString();

    if (success) {
      if (POSConfig().dualScreenWebsite != "")
        DualScreenController().setView('thank_you');
    } else {
      EasyLoading.showError(res?.data?['res']);
    }

    //handle third party loyalty modules
    ExtLoyaltyModuleHelper helper = ExtLoyaltyModuleHelper();
    if (helper.extLoyaltyModuleActive && mobile.isNotEmpty && invoiced) {
      //handle redemptions first
      if (burnedPoints > 0) {
        await helper.redemptionCommit(otp ?? '', burnedPoints);
      }
      //earn loyalty points
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('payment_view.earn_loyalty'
                  .tr(namedArgs: {'module': helper.module})),
              actions: [
                AlertDialogButton(
                    onPressed: () {
                      helper.earnLoyaltyPoints(mobile);
                      Navigator.pop(context);
                    },
                    text: 'payment_view.yes'.tr()),
                AlertDialogButton(
                    onPressed: () => Navigator.pop(context),
                    text: 'payment_view.no'.tr())
              ],
            );
          });
    } else if (mobile.isNotEmpty &&
        customerBloc.currentCustomer?.cMLOYALTY == true) {
      SMSController().sendBillSave(mobile, netAmt, cartSummary.invoiceNo,
          earnedLoyaltyPoints, customerBloc.currentCustomer?.cMNAME ?? '');
    }

    return InvoiceSaveRes(
        success, earnedLoyaltyPoints, /* kDebugMode ? '{}' : */ resReturn);
  }

  // clear the temp payments
  Future<bool> clearTempPayment() async {
    String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? "";
    bool val = await _localStorageController.clearTempPayment();
    print('clear temp payment');
    print('Get Customer Coupons');
    customerCouponBloc.getAvailableCoupons();
    if (val) {
      cartBloc.clearPayment();
    }
    return val;
  }

  /// get hold cart headers
  /// new change: instead of sending cashier, now we are passing loc code
  Future<List<HoldInvoiceHeaders>> getHoldHeaders(
      {int isSignOffCheck = 0}) async {
    final cashier = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
    final res = await ApiClient.call(
        "invoice/hold/$cashier/${POSConfig().locCode}/$isSignOffCheck",
        ApiMethod.GET,
        errorToast: false);

    if (res?.data == null || res?.data == '')
      return [];
    else {
      return HoldHeaderResult.fromJson(res?.data).holdInvoiceHeaders ?? [];
    }
  }

  Future getHoldCart(HoldInvoiceHeaders header) async {
    // get the hold cart details
    String invoice = header.invheDINVNO ?? "";
    final map = await getCartDetails(invoice, isHoldInv: true);

    final List<CartModel> holdDetails = map['cartModels'];
    final HedRemarkModel? hedRem = map['hedRemarks'];

    int lineNo = 0;
    int itemCount = 0;
    double qty = 0;
    double subTotal = 0;

    holdDetails.forEach((element) async {
      // added this block to set the allowDiscount flag using (noDisc, unitQty) since we dont get any priceLists details along with the api call
      if (element.noDisc == false && element.unitQty > 0) {
        element.allowDiscount = true;
      }

      // this is to remove all the promotion related discounts (if it mistakely added)
      if (element.unitQty > 0) {
        // this condition prevent clearing promotion disc amount for returned item (promotion applied)
        element.promoDiscAmt = 0;
        element.promoDiscPre = 0;
        element.promoBillDiscPre = 0;
        element.promoCode = '';
        element.promoDesc = '';
        element.promoDiscValue = 0;

        element.amount = (element.selling * element.unitQty) -
            ((element.discAmt ?? 0) +
                (element.selling / 100 * (element.discPer ?? 0)));
      }

      CartModel cart = element;
      if (POSConfig().cartBatchItem) {
        cart.key = cart.proCode;
      } else {
        cart.key = DateTime.now().microsecondsSinceEpoch.toString() +
            "-" +
            cart.lineNo.toString();
      }
      cart.lineNo = ++lineNo;
      //calculation
      var lineAmount = element.amount;
      // final zero =  0;
      // lineAmount -= element.discAmt??0;
      // lineAmount -= (lineAmount * (element.discPer??zero))/double.fromInt(100);
      if (cart.itemVoid == false) {
        subTotal += lineAmount;
      }

      final cartList = cartBloc.currentCart ?? {};

      //calculate price
      final founded = cartList.values.toList().indexWhere((e) =>
          e.proCode == element.proCode &&
          e.itemVoid != true &&
          e.unitQty > 0 &&
          e.stockCode == element.stockCode);
      bool alreadyAdded = founded != -1;
      bool minus = element.unitQty.toDouble() < 0;
      if (!alreadyAdded && !minus) {
        itemCount++;
      }
      if (!minus) {
        qty += element.unitQty;
      }

      //load customer
      if ((header.memberCode ?? "").isNotEmpty) {
        final customer = await CustomerController()
            .getCustomerByCode(header.memberCode ?? "");
        if (customer != null) {
          customerBloc.changeCurrentCustomer(customer, update: false);
        }
      }
      cartBloc.updateCartUnconditionally(element);
      await InvoiceController().saveItemTempCart(element);
    });

    // now we should assign a current inv number for recalled inv header
    // final invoiceNo = invoice;
    final invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';

    //   update cart summary
    final cartSum = CartSummaryModel(
        invoiceNo: invoiceNo,
        items: itemCount,
        qty: qty,
        subTotal: subTotal,
        startTime: '',
        discPer: header.invheDDiscPer,
        priceMode: header.priceMode,
        recallHoldInv: true,
        hedRem: hedRem);
    final List<PriceModes> priceModeList = priceModeBloc.priceModes;
    int index = priceModeList
        .indexWhere((element) => element.prMCODE == cartSum.priceMode);
    if (index != -1) {
      cartSum.priceModeDesc = priceModeList[index].prMDESC;
    }
    cartBloc.updateCartSummary(cartSum);

    await InvoiceController().updateTempCartSummary(cartSum);
    //clear the hold record
    await ApiClient.call("invoice/hold/$invoice", ApiMethod.DELETE);

    //  update the time
    final time =
        DateFormat("HH:mm:ss").format(header.invheDTIME ?? DateTime.now());
    final date = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final formattedString = date + "T" + time;
    DateTime dateTime = DateTime.parse(formattedString);

    cartSum.startTime = formattedString;
    _localStorageController.updateCartSummary(cartSum);

    // await ApiClient.call("invoice/temp/summary/$invoiceNo", ApiMethod.PUT,
    //     local: true, formData: FormData.fromMap({"time": dateTime}));
  }

  /// get cart details by id
  Future<Map<String, dynamic>> getCartDetails(String invoice,
      {bool isHoldInv = false}) async {
    // getting hold invoice details endpoint is changed
    final res = await ApiClient.call(
        isHoldInv
            ? "invoice/details_hold/$invoice"
            : "invoice/details/$invoice",
        ApiMethod.GET);
    if (res?.data == null)
      return {"cartModels": [], "hedRemarks": null};
    else {
      final List data = res?.data?["details"] ?? [];
      final List remarkList = res?.data?["remarks"] ?? [];
      final HedRemarkModel? hedRem = res?.data?["hed_remarks"].isNotEmpty
          ? HedRemarkModel().fromMap(res?.data?["hed_remarks"].first)
          : null;
      if (data.length == 0) return {"cartModels": [], "hedRemarks": null};
      final myList = data.map((e) => CartModel.fromMap(e)).toList();

      /// tax mapping by [TM.Sakir]
      try {
        if (myList.isNotEmpty && res?.data['taxDet'].isNotEmpty) {
          List<dynamic> taxdet = res?.data['taxDet'];
          for (int i = 0; i < taxdet.length; i++) {
            int proIndex =
                myList.indexWhere((e) => e.proCode == taxdet[i]['proCode']);
            if (proIndex != -1) {
              final List taxes = taxdet[i]['proTaxList'] ?? [];
              myList[proIndex].proTax =
                  taxes.map((e) => ProTax.fromJson(e)).toList();
            }
          }
        }
      } catch (e) {
        print(e.toString());
      }

      //going through remark
      for (var dyRemark in remarkList) {
        final remark = InvoiceLineRemarks.fromMap(dyRemark);
        //find relevant item in cart list
        final index = myList.indexWhere((element) =>
            element.lineNo?.toString() == remark.lineNo.toString());
        if (index != -1) {
          myList[index].lineRemark.add(remark.lineRemark ?? '');
        }
      }
      return {"cartModels": myList, "hedRemarks": hedRem};
    }
  }

  // get today invoices
  Future<List<InvoiceHeader>> getTodayInvoices() async {
    final cashier = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
    final res = await ApiClient.call("invoice/today/$cashier", ApiMethod.GET);
    if (res?.data == null)
      return [];
    else {
      return InvoiceHeaderResult.fromJson(res?.data).invoiceHeader ?? [];
    }
  }

  /// cancel a invoice by id
  Future<bool> cancelInvoice(String invoice, BuildContext context,
      {bool print = true}) async {
    final cashier = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
    final res = await ApiClient.call(
        "invoice/$invoice/$cashier/?locCode=${POSConfig().locCode}&invMode=INV",
        ApiMethod.DELETE);
    bool result = res?.data?["success"].toString().parseBool() ?? false;
    if (result && print) {
      if (POSConfig.crystalPath != '') {
        await PrintController().printHandler(
            invoice, PrintController().printCancelInvoice(invoice), context);
      } else {
        await POSManualPrint()
            .printInvoice(data: res?.data?["data"], cancel: true);
      }
    }

    return result;
  }

  Future<String> reprintInvoice(String invoice) async {
    final res = await ApiClient.call(
        "invoice/reprint_invoice/$invoice?locCode=${POSConfig().locCode}&invMode=INV",
        ApiMethod.GET);
    if ((res?.data?["success"].toString().parseBool() ?? false) &&
        res?.statusCode == 200) {
      return res?.data['data'];
    } else {
      return '';
    }
  }

  Future<bool> clearMemberCode() async {
    final cartSum = await _localStorageController.getCartSummary();
    if (cartSum != null) {
      cartSum.customerCode = "";
      return _localStorageController.updateCartSummary(cartSum);
    }
    return false;
  }

  Future<String?> getMaximumInvNo(String invPrefix, String mode) async {
    final res = await ApiClient.call(
        'invoice/max_invoice_no?invoiceNo=$invPrefix&invMode=$mode',
        ApiMethod.GET);
    if (res?.statusCode != 200) {
      return null;
    }
    return res?.data?["invNo"]?.toString();
  }

  // Upload local bill data to server
  Future uploadBillData() async {
    final res = await ApiClient.call(
        "invoice/sync_bill_data/" + POSConfig().terminalId, ApiMethod.POST,
        local: true, successCode: 200);
    if (res?.data == null) {
      return null;
    }
    return res?.data;
  }

  /* check refernece invoice is available */
  /* by dinuka 2022/10/17 */
  Future<String?> checkReferenceInvNo(
      String inoviceNo, String locCode, String invMode) async {
    final res = await ApiClient.call(
        "invoice/ref_invoice?invNo=$inoviceNo&locCode=$locCode&invMode=$invMode",
        ApiMethod.GET,
        successCode: 200);
    if (res?.statusCode != 200) {
      return null;
    }
    return res?.data?["invNo"]?.toString();
  }
}
