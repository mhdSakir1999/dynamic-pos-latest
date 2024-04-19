/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/24/21, 2:07 PM
 */

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/audit_log_controller.dart';
import 'package:checkout/controllers/permission_controller.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/pos/logged_user_result.dart';
import 'package:checkout/models/pos/permission_approval_status.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/authentication/approval_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class SpecialPermissionHandler {
  final BuildContext context;

  SpecialPermissionHandler({required this.context});

  // This function return the true for success and false for no permission
  bool hasPermission(
      {String? permissionCode, String? accessType, String? refCode}) {
    POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
        "Check for the permission: $permissionCode- $accessType"));
    if (permissionCode == null ||
        accessType == null ||
        permissionCode.isEmpty ||
        accessType.isEmpty) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Permission code or access type is empty"));
      return true;
    }
    final list = userBloc.userDetails?.userRights ?? [];

    return hasPermissionInList(list, permissionCode, accessType,
        userBloc.currentUser?.uSERHEDUSERCODE ?? "",
        refCode: refCode);
  }

  Future _writeToAuditLog(
      String permission, String type, String user, String refCode) async {
    if (!POSConfig().trainingMode)
      AuditLogController().updateAuditLog(permission, type, refCode,
          'Automatically permission approved. ', user);
  }

  bool hasPermissionInList(List<UserPermissions> list, String permissionCode,
      String accessType, String user,
      {bool checkOptional = true, String? refCode}) {
    final res =
        (list.indexWhere((element) => element.menuTag == "$permissionCode"));
    if (res == -1) {
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.error,
          "Don't have a permission to perform this action"));

      return false;
    }
    if ((list[res].mENUITEMMENURIGHT?.contains(accessType) ?? false)) {
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
          "Permission granted: $permissionCode- $accessType"));

      if (!checkOptional) {
        // _writeToAuditLog(permissionCode, accessType, user,refCode??"");
        return true;
      }
      if (list[res].menuOptional == false) {
        return false;
      } else {
        _writeToAuditLog(permissionCode, accessType, user, refCode ?? "");
        return true;
      }
    }
    POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.error,
        "Don't have a permission to perform this action"));

    return false;
  }

  /// Permission code and accessCode (A-C-D-M) required for this method and
  /// this method will reurn null for the success permission
  /// and otherwise will return the reason
  Future<PermissionApprovalStatus> askForPermission(
      {String? permissionCode,
      String? accessType,
      required String refCode,
      bool localConnection = false}) async {
    POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
        "Ask for the permission: $permissionCode- $accessType"));

    if (permissionCode == null ||
        accessType == null ||
        permissionCode.isEmpty ||
        accessType.isEmpty)
      return PermissionApprovalStatus(false, "", "Rejected");
    else {
      EasyLoading.show(status: 'Please wait...');
      final permission = await PermissionController()
          .getPermissionByyId(permissionCode, local: localConnection);
      // if this is required to ask
      bool sameUser = false;
      if (permission?.menuOptional == false) {
        final list = userBloc.userDetails?.userRights ?? [];
        sameUser = hasPermissionInList(list, permissionCode, accessType,
            userBloc.currentUser?.uSERHEDUSERCODE ?? "",
            checkOptional: false);
      }
      EasyLoading.dismiss();
      final res = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => ApprovalAlert(
          accessType: accessType,
          permissionCode: permissionCode,
          refCode: refCode,
          permissionName: permission?.mENUITEMMENUNAME ?? "",
          sameUser: sameUser,
          localConnection: localConnection,
        ),
      );

      return res ?? PermissionApprovalStatus(false, "", "rejected");
    }
  }
}
