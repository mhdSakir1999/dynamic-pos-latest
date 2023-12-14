/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/22/21, 9:53 AM
 */

import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/customer_controller.dart';
import 'package:checkout/models/loyalty/customer_list_result.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/customer_bundle.dart';

import 'package:rxdart/rxdart.dart';

import '../models/pos/customer_promotion_result.dart';
import 'cart_bloc.dart';

class CustomerBloc {
  final _currentCustomer = BehaviorSubject<CustomerResult?>();
  final _customerBundleBloc = BehaviorSubject<List<CustomerBundles>>();
  final _customerPromotionBloc = BehaviorSubject<List<CustomerPromotion>>();

  Stream<CustomerResult?> get currentCustomerStream => _currentCustomer.stream;

  // Stream<CustomerResult?> get currentCustomerStream => _currentCustomer.stream;

  CustomerResult? get currentCustomer => _currentCustomer.valueOrNull;

  List<CustomerBundles> get customerBundles =>
      _customerBundleBloc.valueOrNull ?? [];
  List<CustomerPromotion> get customerPromotion =>
      _customerPromotionBloc.valueOrNull ?? [];
  final CustomerController _customerController = CustomerController();

  ///
  /// ``` if the update is true customer will be saved in summary
  ///
  Future<void> changeCurrentCustomer(CustomerResult? customer,
      {bool update = true}) async {
    _currentCustomer.sink.add(customer);
    if (update) {
      CartSummaryModel cartSummary = cartBloc.cartSummary ??
          CartSummaryModel(
              invoiceNo: "",
              items: 0,
              qty: 0,
              subTotal: 0,
              startTime: '',
              priceMode: '');
      final controller = InvoiceController();
      controller.updateTempCartSummary(cartSummary);
    }
    final String code = customer?.cMCODE ?? '';
    if (code.isNotEmpty) {
      _customerController.getCustomerByCode(code);
      _customerController
          .getCustomerBundles(code)
          .then((CustomerBundleResult? customerBundleResult) {
        _customerBundleBloc.sink.add(customerBundleResult?.bundles ?? []);
      });
      _customerController
          .getCustomerPromotion(code)
          .then((CustomerPromotionResult? promotionResult) {
        _customerPromotionBloc.sink.add(promotionResult?.promotions ?? []);
      });
    }
  }

  void dispose() {
    if (!_currentCustomer.isClosed) {
      _currentCustomer.close();
      _customerBundleBloc.close();
      _customerPromotionBloc.close();
    }
  }
}

final customerBloc = CustomerBloc();
