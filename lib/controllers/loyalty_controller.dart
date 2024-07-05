/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/12/21, 6:10 PM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/models/loyalty/loyalty_summary.dart';

class LoyaltyController {
  Future<LoyaltySummary?> getLoyaltySummary(String code) async {
    final res = await LoyaltyApiClient.call(
      "loyaltypoint/$code",
      ApiMethod.GET,
      successCode: 200,
    );
    try {
      if (res != null &&
          res.data != null &&
          res.data["loyalty_summary"] != null)
        return LoyaltySummary.fromJson(res.data["loyalty_summary"]);
    } on Exception catch (_) {
      return null;
    }
    return null;
  }
}
