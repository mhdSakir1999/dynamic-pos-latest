/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 2/28/22, 4:10 PM
 */

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/models/pos/ecr_response.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

class EcrController {
  Future<EcrResponse?> binRequest() async {
    final res = await ApiClient.call(
        'ecr?amount=${cartBloc.cartSummary?.subTotal.toStringAsFixed(2) ?? '1.00'}&txnNo=${cartBloc.cartSummary?.invoiceNo ?? ''}',
        ApiMethod.GET,
        local: true);
    if (res?.statusCode == 200) {
      final EcrResponse ecrResponse = EcrResponse.fromJson(res?.data);
      return ecrResponse;
    }
    return null;
  }

  Future<EcrResponse?> doSale(double amount) async {
    final res = await ApiClient.call('ecr', ApiMethod.POST, local: true, data: {
      'amount': amount.toStringAsFixed(2),
      'txnNo': cartBloc.cartSummary?.invoiceNo ?? ''
    });
    if (res?.statusCode == 200) {
      final EcrResponse ecrResponse = EcrResponse.fromJson(res?.data);
      return ecrResponse;
    }
    if (res?.statusCode == 403) {
      final EcrErrorResponse ecrErrorResponse =
          EcrErrorResponse.fromJson(res?.data);
      EasyLoading.showError(ecrErrorResponse.error ?? '');
    }

    return null;
  }
}
