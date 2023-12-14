/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/24/21, 5:11 PM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/models/pos/logged_user_result.dart';
import 'package:checkout/models/pos/permission_approval_status.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:dio/dio.dart';
import 'package:checkout/extension/extensions.dart';

class PermissionController {
  Future<UserPermissions?> getPermissionByyId(String id,
      {bool local = false}) async {
    final res = await ApiClient.call("permission/$id", ApiMethod.GET,
        local: local, writeLog: true);
    if (res == null || res.data == null || res.data?["permission"] == null)
      return null;
    return UserPermissions.fromJson(res.data["permission"]);
  }

  // return null for success
  Future<PermissionApprovalStatus> approveOrReject(
      String permission,
      String type,
      String password,
      String refCode,
      String reason,
      bool local) async {
    final res = await ApiClient.call("permission", ApiMethod.POST,
        formData: FormData.fromMap({
          "permission": permission,
          "type": type,
          "password": password,
          "ref_code": refCode,
          "location": POSConfig().setupLocation,
          "reason": reason,
        }),
        local: local);
    final error = "Something went wrong";
    if (res == null || res.data == null)
      return PermissionApprovalStatus(false, "", error);
    if ((res.data?["success"]?.toString().parseBool() ?? false)) {
      return PermissionApprovalStatus(true, res.data["user"] ?? "", "Approved");
    }
    return PermissionApprovalStatus(false, "", res.data?["message"] ?? error);
  }
}
