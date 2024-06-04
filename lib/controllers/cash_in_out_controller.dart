/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 7/9/21, 6:22 PM
 */

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/models/enum/signon_status.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cash_in_out_result.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos_config.dart';

import 'package:checkout/extension/extensions.dart';

import 'local_storage_controller.dart';

class CashInOutController {
  LocalStorageController _localStorageController = LocalStorageController();
  String incrementInvoiceNo(String? invNo) {
    int invNoInt = 6;
    String invPrefix = POSConfig().comCode.getLastNChar(2) +
        POSConfig().locCode.getLastNChar(2) +
        POSConfig().terminalId.getLastNChar(2);
    if (invNo == null || invNo.isEmpty) {
      return invPrefix + "1".padLeft(invNoInt, '0');
    }

    /// check if the invoice is avalable for the current inv no
    int currentSeq = int.parse(invNo.replaceAll(invPrefix, ''));
    return invPrefix + (currentSeq + 1).toString().padLeft(invNoInt, '0');
  }

  // this method will return the run no
  Future<String> getInvoiceNo(bool cashIn) async {
    //TODO seperation of number generation for cash in / Out
    String? invNo = await _localStorageController.getWithdrawal();
    if (invNo == null) {
      String? witInvNo = await InvoiceController()
          .getMaximumInvNo(InvoiceController().getInvPrefix(), 'WIT');
      String? retInvNo = await InvoiceController()
          .getMaximumInvNo(InvoiceController().getInvPrefix(), 'REC');
      int maxNo = 0;
      if (witInvNo != null) {
        maxNo = int.parse(
            witInvNo.replaceAll(InvoiceController().getInvPrefix(), ''));
      }
      if (retInvNo != null) {
        int temp = int.parse(
            retInvNo.replaceAll(InvoiceController().getInvPrefix(), ''));
        maxNo = maxNo > temp ? maxNo : temp;
      }
      invNo = InvoiceController().getInvPrefix() +
          (maxNo).toString().padLeft(6, '0');
    }

    String nextInv = incrementInvoiceNo(invNo);
    return nextInv;
  }

  Future<CashInOutResult?> getCashInOutTypes(bool cashIn) async {
    final res = await ApiClient.call(
      "cash_in_out/${cashIn ? "cash_in" : "cash_out"}",
      ApiMethod.GET,
    );
    if (res?.data == null) return null;
    return CashInOutResult.fromJson(res?.data);
  }

  Future<Map<String, dynamic>> saveCashInOut(
      {required bool cashIn,
      required CartModel cart,
      required PaidModel paidModel,
      required String invoice}) async {
    final zero = 0;
    double subTotal = cart.amount.toDouble();
    double grossAmt = subTotal; // without discounts total bill value
    double lineDiscPer = 0;
    double lineDiscAmt = 0;
    final userDetails = userBloc.userDetails!;
    final double netAmt = subTotal;
    final double payAmt = netAmt;
    final double changeAmt = 0;
    final double dueAmt = 0;

    String cashier = userBloc.currentUser?.uSERHEDUSERCODE ?? "UnAuthorized";
    String tempCashier =
        userBloc.currentUser?.uSERHEDUSERCODE ?? "UnAuthorized";

    if (userBloc.signOnStatus == SignOnStatus.TempSignOn) {
      cashier = userBloc.signOnCashierForTemp ?? "";
    }

    // handle entered cartlist
    final cartMap = cart.toMap();
    cartMap['LINE_REMARK'] = '';
    final List<dynamic> cartList = [];
    cartList.add(cartMap);

    final paidMap = paidModel.toMap();
    final List<dynamic> payments = [];
    payments.add(paidMap);

    Map<String, dynamic> temp = {
      "INV_DETAILS": cartList,
      "PAYMENTS": payments,
      "MEMBER_CODE": "",
      "INVOICE_NO": invoice,
      "NET_AMOUNT": netAmt,
      "GROSS_AMOUNT": grossAmt,
      "PAY_AMOUNT": payAmt,
      "CHANGE_AMOUNT": changeAmt,
      "DUE_AMOUNT": dueAmt,
      "TERMINAL": POSConfig().terminalId,
      "SETUP_LOCATION": POSConfig().setupLocation,
      "CASHIER": cashier,
      "TEMP_SIGN_ON": tempCashier,
      "SHIFT_NO": userDetails.shiftNo,
      "SIGN_ON_DATE": userDetails.date,
      "COM_CODE": POSConfig().comCode,
      "LOC_CODE": POSConfig().locCode,
      "BILL_DISC_PER": 0,
      "INVOICED": true,
      "LINE_DISC_PER": lineDiscPer.toDouble(),
      "LINE_DISC_AMT": lineDiscAmt.toDouble(),
      "INV_REF": [],
      "PRO_TAX": [],
      "LINE_REMARKS": [],
      "FREE_ISSUE": [],
      "INV_TICKETS": [],
      'REDEEMED_COUPONS': [],
      'HED_REMARKS': []
    };
    final res = await ApiClient.call(
        "cash_in_out/${cashIn ? "cash_in" : "cash_out"}", ApiMethod.POST,
        data: temp, successCode: 200);
    return {
      "status": res?.data?["success"] == true,
      "returnRes": res?.data?['res']?['result'] ?? ''
    };
  }
}
