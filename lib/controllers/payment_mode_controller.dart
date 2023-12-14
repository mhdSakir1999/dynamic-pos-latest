/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/27/21, 1:49 PM
 */
import 'package:checkout/components/api_client.dart';
import 'package:checkout/models/pos/payment_mode.dart';
import 'package:checkout/models/pos/card_details_result.dart';
import 'package:checkout/models/pos/denomination_result.dart';

/// This controller class will handle the payment modes
class PaymentModeController {
  Future<PayModeResult?> getAvailablePaymentMode() async {
    final res = await ApiClient.call("paymodes", ApiMethod.GET);
    if (res?.data == null) return null;
    if (!res?.data["success"]) return null;
    return PayModeResult.fromJson(res?.data);
  }

  Future<CardDetailsResult?> getCardDetails() async {
    final res =
        await ApiClient.call("paymodes/card", ApiMethod.GET, authorize: true);
    if (res?.data == null) return null;
    if (!res?.data["success"]) return null;
    return CardDetailsResult.fromJson(res?.data);
  }

  Future<List<DenominationHed>> getDenominationList() async {
    final res = await ApiClient.call("paymodes/denominations", ApiMethod.GET);
    if (res?.data == null) return [];
    final deno = DenominationResult.fromJson(res!.data);

    return deno.denominationHed ?? [];
  }
}
