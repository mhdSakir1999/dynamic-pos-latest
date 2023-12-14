/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/12/21, 4:20 PM
 */

import 'package:checkout/controllers/payment_mode_controller.dart';
import 'package:checkout/models/pos/payment_mode.dart';
import 'package:checkout/models/pos/card_details_result.dart';
import 'package:rxdart/rxdart.dart';

class PayModeBloc {
  final _payMode = BehaviorSubject<PayModeResult?>();
  final _cardDetails = BehaviorSubject<List<CardDetails>?>();
  Stream<PayModeResult?> get payModeSnapshot => _payMode.stream;
  PayModeResult? get payModeResult => _payMode.valueOrNull;
  Stream<List<CardDetails>?> get cardDetailsSnapshot => _cardDetails.stream;
  List<CardDetails> get cardDetailsList => _cardDetails.valueOrNull ?? [];

  void getPayModeList() async {
    final res = await PaymentModeController().getAvailablePaymentMode();
    _payMode.sink.add(res);
  }

  void getCardDetails() async {
    final res = await PaymentModeController().getCardDetails();
    _cardDetails.sink.add(res?.cardDetails ?? []);
  }

  void dispose() {
    _payMode.close();
    _cardDetails.close();
  }
}

final payModeBloc = PayModeBloc();
