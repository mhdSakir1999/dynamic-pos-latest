/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/7/21, 5:55 PM
 */

import 'package:checkout/components/api_client.dart';
import 'package:checkout/models/pos/gift_voucher_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class GiftVoucherController {
  late String _url;

  GiftVoucherController() {
    _url =
        '${POSConfig().setup?.centralPOSServer?.replaceFirst('/api/', '')}/api/';
  }
  Future<GiftVoucherResult?> getGiftVoucherById(String id) async {
    EasyLoading.show(
        status: 'Fetching gift voucher details from Central server.');
    final Response<dynamic>? res = await ApiClient.call(
        'gift_vouchers?loc=${POSConfig().locCode}&id=$id', ApiMethod.GET,
        overrideUrl: _url, authorize: false, errorToast: false);
    EasyLoading.dismiss();
    if (res?.statusCode == 400) {
      return null;
    }
    if (res?.data == null) {
      return null;
    }
    return GiftVoucherResult.fromJson(res?.data);
  }

  Future<GiftVoucherResult?> validateGiftVoucherRedemption(
      String id, double netamount) async {
    final Response<dynamic>? res = await ApiClient.call(
      'gift_vouchers/redemption_validation?id=$id&amount=$netamount',
      ApiMethod.GET,
      overrideUrl: _url,
      authorize: false,
      errorToast: false,
    );
    if (res?.statusCode == 400) {
      return null;
    }
    if (res?.data == null) {
      return null;
    }
    return GiftVoucherResult.fromJson(res?.data);
  }

  /* Validate gift vouchers api*/
  /* By dinuka 2022/08/09 */
  Future validateGiftVouchersList(String startNum, String endNum) async {
    final Response<dynamic>? res = await ApiClient.call(
        'gift_vouchers/validate', ApiMethod.POST,
        errorToast: false,
        overrideUrl: _url,
        authorize: false,
        formData:
            FormData.fromMap({"startNumber": startNum, "endNumber": endNum}));
    if (res?.statusCode == 400) {
      return null;
    }
    if (res?.data == null) {
      return null;
    }
    return res?.data['result'];
    // return GiftVoucherResult.fromJson(res?.data);
  }
}
