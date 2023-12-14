/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/1/22, 3:22 PM
 */

import 'package:checkout/components/api_client.dart';
import 'package:checkout/models/utility_bill/utility_bill_setup.dart';
import 'package:checkout/models/utility_bill/utility_bill_sub_category.dart';
import 'package:checkout/models/utility_bill/utility_ui_results.dart';

import '../models/utility_bill/utility_bill_category.dart';

class UtilityBillSetupController {
  Future<List<UtilityBillSetup>> getUtilityBillSetup() async {
    final res = await ApiClient.call('UtilityBillSetup', ApiMethod.GET);
    if (res?.data == null) {
      return <UtilityBillSetup>[];
    }
    return UtilityBillSetupResult.fromJson(res?.data).utilityBillSetup ??
        <UtilityBillSetup>[];
  }

  Future<List<UtilityBillSetup>> getUtilityBillSetupById(
      String cartegoryId) async {
    final res = await ApiClient.call(
        'UtilityBillSetup/category/$cartegoryId', ApiMethod.GET);
    if (res?.data == null) {
      return <UtilityBillSetup>[];
    }
    return UtilityBillSetupResult.fromJson(res?.data).utilityBillSetup ??
        <UtilityBillSetup>[];
  }

  Future<List<UtilityBillSubcategory>> getUtilityBillSubcategoryById(
      String cartegoryId) async {
    final res = await ApiClient.call(
        'UtilityBillSetup/subcategory/$cartegoryId', ApiMethod.GET);
    if (res?.data == null) {
      return <UtilityBillSubcategory>[];
    }
    return UtilityBillSubcategoryResult.fromJson(res?.data)
            .utilityBillSubcategory ??
        <UtilityBillSubcategory>[];
  }

  Future<List<UtilityBillSetup>> getUtilityBillSetupBySubId(
      String cartegoryId) async {
    final res = await ApiClient.call(
        'UtilityBillSetup/subcategory/utility/$cartegoryId', ApiMethod.GET);
    if (res?.data == null) {
      return <UtilityBillSetup>[];
    }
    return UtilityBillSetupResult.fromJson(res?.data).utilityBillSetup ??
        <UtilityBillSetup>[];
  }

  Future<List<UtilityBillCategory>> getUtilityBillCategories() async {
    final res =
        await ApiClient.call('UtilityBillSetup/categories', ApiMethod.GET);
    if (res?.data == null) {
      return <UtilityBillCategory>[];
    }

    return UtilityBillCategoryResult.fromJson(res?.data).utilityBillCategory ??
        <UtilityBillCategory>[];
  }

  Future<UtilityUIResult?> getUtilityUi(String type) async {
    final res = await ApiClient.call('UtilityBillSetup/${type}', ApiMethod.GET);
    if (res?.data != null) {
      return UtilityUIResult.fromJson(res?.data);
    }
    return null;
  }
}
