/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/12/21, 4:28 PM
 */
import 'package:checkout/components/api_client.dart';
import 'package:checkout/components/loyalty_client.dart';
import 'package:checkout/models/loyalty/area_result.dart';

class AreaController {
  // This method will return the all available areas
  Future<AreaResult?> getAreaList() async {
    final res = await LoyaltyApiClient.call(
      "area",
      ApiMethod.GET,
      successCode: 200,
    );
    if (res != null && res.data != null)
      return AreaResult.fromJson(res.data);
    else
      return null;
  }
}
