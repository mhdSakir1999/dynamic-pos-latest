/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/7/21, 5:55 PM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/models/pos/setup_result.dart';
import 'package:checkout/models/pos_config.dart';

class SetUpController {
  Future<Setup?> getSetupData(String url) async {
    final res = await ApiClient.call(
        "setup?loc=${POSConfig().locCode}", ApiMethod.GET,
        overrideUrl: url, local: POSConfig().localMode);
    if (res?.data == null) return null;
    return SetUpResult.fromJson(res?.data).setup;
  }
}
