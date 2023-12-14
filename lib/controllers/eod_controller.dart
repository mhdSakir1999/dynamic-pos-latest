/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/5/21, 3:39 PM
 * Editor: TM.Sakir
 */

import 'package:checkout/components/api_client.dart';
import 'package:checkout/models/pos/eod_validation_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class EodController {
  Future<EoDValidationResult?> validateEodProcess(DateTime eodDate) async {
    final res = await ApiClient.call(
        "eod/validation?date=$eodDate&location=${POSConfig().locCode}", // new change-- passing loc as addition.
        ApiMethod.GET);
    if (res?.data == null)
      return null;
    else
      return EoDValidationResult.fromJson(res!.data);
  }

  Future doEOD(DateTime eodDate) async {
    final res = await ApiClient.call("eod", ApiMethod.POST,
        formData: FormData.fromMap(
            {'date': eodDate, 'location': POSConfig().locCode}));
    if (res?.statusCode == 200) {
      EasyLoading.showSuccess('landing_view.eod_success'.tr());
    }
    return res?.data['success'] ?? false;
  }
}
