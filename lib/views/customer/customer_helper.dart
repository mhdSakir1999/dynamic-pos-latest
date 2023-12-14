/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/14/21, 2:03 PM
 */

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:flutter/cupertino.dart';

class CustomerHelper {
  final BuildContext context;
  CustomerHelper(this.context);
  Future<bool> hasCustomerMasterPermission(String code) async {
    bool hasPermission = false;

    // fetch permission list
    final userCode = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
    final permissionList =
    await AuthController().getUserPermissionListByUserCode(userCode);

    hasPermission = SpecialPermissionHandler(context: context)
        .hasPermissionInList(permissionList?.userRights ?? [],
        PermissionCode.customerMaster, "A", userCode);

    //if user doesnt have the permission
    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: context)
          .askForPermission(
          permissionCode: PermissionCode.customerMaster,
          accessType: code,
          refCode: DateTime.now().toIso8601String());
      hasPermission = res.success;
    }
    return hasPermission;
  }
}
