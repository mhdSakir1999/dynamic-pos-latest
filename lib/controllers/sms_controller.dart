/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/3/21, 3:01 PM
 */

import 'package:checkout/components/components.dart';

/// handle sms from here
class SMSController {
  Future<void> sendOTP(String number, String otp) async {
    await LoyaltyApiClient.call("sms/otp", ApiMethod.POST,
        data: {"otp": otp, "number": number}, successToast: false);
  }

  Future<void> sendOTPCashier(String number, String otp) async {
    await LoyaltyApiClient.call("sms/otp/cashier", ApiMethod.POST,
        data: {"otp": otp, "number": number},
        successToast: false,
        authorize: false);
  }

  Future<void> sendBillSave(String number, double billAmount, String invoiceNo,
      double points, String customer) async {
    await LoyaltyApiClient.call("sms/invoice", ApiMethod.POST,
        data: {
          "billAmount": billAmount.toStringAsFixed(2),
          "number": number,
          "points": points.toStringAsFixed(2),
          "invoiceNo": invoiceNo,
          "customer_name": customer
        },
        successToast: false);
  }
}
