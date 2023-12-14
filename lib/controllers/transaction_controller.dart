/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/14/22, 3:25 PM
 */

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/controllers/customer_controller.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/transaction_mode_results.dart';
import 'package:checkout/models/pos_config.dart';

import 'package:dio/dio.dart';
import 'package:checkout/extension/extensions.dart';
import '../models/pos/transaction_details.dart';
import '../models/pos/transaction_header_result.dart';

class TransactionController {
  Future<List<TransactionModes>> getBackofficeInvoiceModes() async {
    List<TransactionModes> transactionModes = <TransactionModes>[];
    final Response? res =
        await ApiClient.call('transaction/backoffice', ApiMethod.GET);
    if (res?.data != null) {
      transactionModes = TransactionModeResult.fromJson(res?.data).modes ?? [];
    }
    return transactionModes;
  }

  Future<List<TransactionHeader>> getBackofficeInvoiceHeaders(
      TransactionModes transactionModes) async {
    List<TransactionHeader> transactions = <TransactionHeader>[];
    final Response? res = await ApiClient.call(
        'transaction/backoffice/header/${transactionModes.tXHEADERTABLE}/${POSConfig().locCode}/${userBloc.currentUser?.uSERHEDUSERCODE ?? ''}',
        ApiMethod.GET);
    if (res?.data != null) {
      transactions = TransactionHeaderResult.fromJson(res?.data).headers ?? [];
    }
    return transactions;
  }

  Future<List<TransactionDetail>> getBackofficeInvoiceDetails(
      TransactionModes transactionModes, TransactionHeader header) async {
    List<TransactionDetail> transactions = <TransactionDetail>[];
    final Response? res = await ApiClient.call(
        'transaction/backoffice/details/${transactionModes.tXDETAILTABLE}/${header.heDTYPE}/${header.heDRUNNO}',
        ApiMethod.GET);
    if (res?.data != null) {
      transactions =
          TransactionDetailsResults.fromJson(res?.data).details ?? [];
    }
    return transactions;
  }

  Future<void> addTransactionDetailsToInvoice(TransactionHeader header,
      List<TransactionDetail> transactionDetailsList) async {
    String date = header.heDPROCDATE ?? '';
    String time = header.heDTIME ?? '';
    String datetime = '$date $time';
    int items = transactionDetailsList.length;
    double qty = 0.0;
    for (int i = 0; i < transactionDetailsList.length; i++) {
      final CartModel cartModel = transactionDetailsList[i]
          .toCartModel(datetime.parseDateTime(), i + 1);
      qty += cartModel.unitQty;
      cartBloc.updateCartUnconditionally(cartModel);
      await InvoiceController().saveItemTempCart(cartModel);
    }
    CartSummaryModel cartSummaryModel =
        cartBloc.cartSummary ?? cartBloc.defaultSummary;

    cartSummaryModel.refMode = header.heDTYPE;
    cartSummaryModel.refNo = header.heDRUNNO;
    cartSummaryModel.editable = header.heDEDITABLE ?? false;
    cartSummaryModel.subTotal = header.heDNETAMT ?? 0;
    cartSummaryModel.items = items;
    cartSummaryModel.qty = qty;
    cartSummaryModel.customerCode = header.heDCUSCODE;
    if ((cartSummaryModel.customerCode ?? '').isNotEmpty) {
      final customer = await CustomerController()
          .getCustomerByCode(cartSummaryModel.customerCode!);
      customerBloc.changeCurrentCustomer(customer);
    }

    cartBloc.updateCartSummary(cartSummaryModel);
    await InvoiceController().updateTempCartSummary(cartSummaryModel);
  }
}
