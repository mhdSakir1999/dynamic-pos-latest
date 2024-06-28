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

  Future<List<ProductDiscountStatus>> getProductDiscStatusForGrpDisc(
      List<Map<String, dynamic>> proCodeMap) async {
    var data = Map<String, dynamic>.from({"sku_codes": proCodeMap});
    final res = await ApiClient.call(
        "products/staff_disc_validate", ApiMethod.GET,
        data: data);
    if (res?.data == null && res?.data['data'] == null) return [];
    List resList = res?.data['data'] ?? [];
    if (resList.isEmpty) return [];
    return resList
        .map((element) => ProductDiscountStatus.fromJson(element))
        .toList();
  }
}
