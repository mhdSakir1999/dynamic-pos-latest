/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/27/21, 3:48 PM
 */

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/audit_log_controller.dart';
import 'package:checkout/controllers/my_alert_controller.dart';
import 'package:checkout/models/pos/permission_approval_status.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/views/pos_alerts/pos_alert_template.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:checkout/controllers/permission_controller.dart';
import 'package:supercharged/supercharged.dart';


class ApprovalAlert extends StatefulWidget {
  final String accessType;
  final String permissionCode;
  final String refCode;
  final String permissionName;
  final bool sameUser;
  final bool localConnection;

  ApprovalAlert(
      {Key? key,
      required this.accessType,
      required this.permissionCode,
      required this.refCode,
      required this.permissionName,
      required this.sameUser,
      this.localConnection = false})
      : super(key: key);

  @override
  _ApprovalAlertState createState() => _ApprovalAlertState();
}

class _ApprovalAlertState extends State<ApprovalAlert> {
  String permissionName = "";
  TextEditingController reasonController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String? error;
  @override
  void initState() {
    super.initState();
    permissionName = widget.permissionName;
    myAlertProcess();
    // getPermissionName();
  }

  Future<void> myAlertProcess() async {
    if (!widget.sameUser) {
      PermissionApprovalStatus? res = await MyAlertController().myRemoteProcess(
          widget.permissionCode,
          widget.accessType,
          widget.permissionName,
          widget.refCode);
      if (res != null) {
        Navigator.pop(context, res);
      }
    }
  }

  void getPermissionName() async {
    final res =
        await PermissionController().getPermissionByyId(widget.permissionCode);
    if (res != null) {
      if (mounted)
        setState(() {
          permissionName = res.mENUITEMMENUNAME ?? "";
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return POSAlertTemplate(
      showAppBar: false,
      notifications: [
        error ??
            "approval_screen.approve_description".tr(
              namedArgs: {'desc': permissionName},
            ),
      ],
      icon: Icons.admin_panel_settings_outlined,
      leftButtonPressed: () {},
      leftButtonText: "approval_screen.approve_this_remotely".tr(),
      rightButtonPressed: handlePermission,
      rightButtonText: "approval_screen.approve_this_action".tr(),
      title: "approval_screen.approve_title".tr(),
      expNotification: true,
      hideTextField2: widget.sameUser,
      textFeild1: "approval_screen.reason".tr(),
      textFeild2: "approval_screen.enter_password".tr(),
      textEditingController1: reasonController,
      textEditingController2: passwordController,
      obscure2: true,
      style: TextStyle(
          color: error == null
              ? POSConfig().primaryLightColor.toColor()
              : Colors.redAccent),
    );
  }

  void handlePermission() async {
    String reason = reasonController.text;
    String password = passwordController.text;
    if (reason.isEmpty) {
      return;
    }

    if (widget.sameUser) {
      final user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
      try {
        await AuditLogController().updateAuditLog(widget.permissionCode,
            widget.accessType, widget.refCode, reason, user);
      } catch (e) {}

      PermissionApprovalStatus permissionApprovalStatus =
          PermissionApprovalStatus(true, user, "");
      Navigator.pop(context, permissionApprovalStatus);
    } else {
      final res = await PermissionController().approveOrReject(
          widget.permissionCode,
          widget.accessType,
          password,
          widget.refCode,
          reason,
          widget.localConnection);
      setState(() {
        error = res.message;
      });
      if (res.success) Navigator.pop(context, res);
    }
  }
}
