/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/4/21, 6:31 PM
 */
import 'package:checkout/components/api_client.dart';
import 'package:checkout/models/pos/discount_type_result.dart';

class DiscountController {
  Future<DiscountTypeResult?> getDiscountTypes() async {
    final res = await ApiClient.call("discount/types", ApiMethod.GET);
    if (res?.data == null) return null;
    return DiscountTypeResult.fromJson(res?.data);
  }
}
