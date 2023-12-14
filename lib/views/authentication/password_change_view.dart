/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/27/21, 3:48 PM
 */

import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/models/pos/login_results.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/views/pos_alerts/pos_alert_template.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:supercharged/supercharged.dart';

class PasswordChangeView extends StatefulWidget {
  final String user;
  final PasswordData passwordData;

  const PasswordChangeView(
      {Key? key, required this.user, required this.passwordData})
      : super(key: key);

  @override
  _PasswordChangeViewState createState() => _PasswordChangeViewState();
}

class _PasswordChangeViewState extends State<PasswordChangeView> {
  String permissionName = "";
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return POSAlertTemplate(
      showAppBar: false,
      notifications: [
        error ?? '',
        //'password_change.title'.tr(),
        widget.passwordData.passworDPOLICYDESC ?? ''
      ],
      icon: Icons.admin_panel_settings_outlined,
      leftButtonPressed: () => Navigator.pop(context),
      rightButtonPressed: _validation,
      leftButtonText: "password_change.cancel".tr(),
      rightButtonText: "password_change.update".tr(),
      title: 'password_change.title'.tr(),
      expNotification: true,
      hideTextField2: false,
      hideTextField3: false,
      hideTextField1: true,
      textFeild1: "password_change.current_password".tr(),
      textFeild2: "password_change.new_password".tr(),
      textFeild3: "password_change.retype_password".tr(),
      textEditingController1: currentPasswordController,
      textEditingController2: passwordController,
      textEditingController3: confirmPasswordController,
      obscure1: true,
      obscure2: true,
      obscure3: true,
      firstColor: Colors.yellow,
      style: TextStyle(
          color: error == null
              ? POSConfig().primaryLightColor.toColor()
              : Colors.redAccent),
    );
  }

  Future<void> _validation() async {
    final String policy = widget.passwordData.passworDPOLICY ?? '';
    //final String policy = POSConfig().setup?.passwordPolicy ?? '';
    bool validPassword = policy.isEmpty;
    String newPassword = passwordController.text;
    String confirmPassword = confirmPasswordController.text;
    setState(() {
      error = null;
    });

    //do validation
    if (!validPassword) {
      final regex = RegExp(policy);
      validPassword = regex.hasMatch(newPassword);
      if (!validPassword) {
        setState(() {
          error =
              "Your password doesn't match with the company password policy. Please contact the system administrator for more info";
        });
      }
    }

    if (validPassword) {
      //check password match
      if (newPassword != confirmPassword) {
        setState(() {
          error = "Your password and confirmation password do not match";
        });
      } else {
        //do the password change process
        EasyLoading.show(status: 'please_wait'.tr());
        String res = (await AuthController()
                .updatePassword(widget.user, '', newPassword)) ??
            '';
        EasyLoading.dismiss();
        if (res.isEmpty) {
          Navigator.pop(context);
        } else {
          EasyLoading.showError(res);
          setState(() {
            error = res;
          });
        }
      }
    }
  }
}
