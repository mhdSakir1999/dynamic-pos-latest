/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/12/21, 7:12 PM
 */

import 'package:checkout/components/api_client.dart';
import 'package:checkout/models/pos/GroupResults.dart';

class GroupController {
  // Future<List<Groups>> getDepartments() async {
  //   final res = await ApiClient.call("groups/departments", ApiMethod.GET);
  //   if (res?.data == null) return [];
  //   final data = GroupResults.fromJson(res?.data);
  //   return data.groups ?? [];
  // }
  Future<GroupResults?> getDepartments() async {
    final res = await ApiClient.call("groups/departments", ApiMethod.GET);
    if (res?.data == null) return null;
    if (!res?.data["success"]) return null;
    final data = GroupResults.fromJson(res?.data);
    return data;
  }
}
