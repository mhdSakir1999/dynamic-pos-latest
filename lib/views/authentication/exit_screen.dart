/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/28/21, 4:59 PM
 * Edit/correction/new functions: TM.Sakir
 */

import 'dart:io';

import 'package:checkout/components/components.dart';
import 'package:checkout/components/pos_platform.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/views/pos_alerts/pos_alert_template.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class ExitScreen extends StatelessWidget {
  static const routeName = "exit_screen";
  final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    /* 
          * Author: TM.Sakir
          * Date: 2023/11/15 09:49AM
          * change: adding shortcut key events
          */
    //---------------------
    focusNode.requestFocus();
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (value) async {
        if (value is KeyDownEvent) {
          if (value.physicalKey == PhysicalKeyboardKey.keyN) {
            Navigator.pop(context);
          }
          if (value.physicalKey == PhysicalKeyboardKey.keyY) {
            await exitTasks();
          }
        }
      },
      child: POSAlertTemplate(
        body: "exit_screen.exit".tr(),
        icon: MaterialCommunityIcons.help_circle,
        style: CurrentTheme.headline5,
        leftButtonPressed: () async {
          await exitTasks();
          //---------------------
        },
        leftButtonText: "exit_screen.yes".tr(),
        rightButtonPressed: () {
          Navigator.pop(context);
        },
        rightButtonText: "exit_screen.no".tr(),
        title: "exit_screen.system_message".tr(),
        expNotification: false,
      ),
    );
  }

  /* 
          * Author: TM.Sakir
          * Date: 2023/9/19 09:49AM
          * change: this is to close the dualDisplay app, local api, crystal when closing the pos -- "taskkill /F /IM name.exe"
          */
  Future<void> exitTasks() async {
    EasyLoading.show(status: 'please_wait'.tr());
    try {
      final result = await Process.run(
          'cmd.exe', ['/c', 'taskkill /F /IM dual_screen_windows.exe']);

      print('Exit code: ${result.exitCode}');
      print('Stdout:\n${result.stdout}');
      print('Stderr:\n${result.stderr}');
    } catch (e) {
      print('Error: $e');
    }
    try {
      final result = await Process.run(
          'cmd.exe', ['/c', 'taskkill /F /IM Dynamic_POS_REST_API.exe']);
      LogWriter().saveLogsToFile('ERROR_Log_', ['Closing previous api...']);
    } catch (e) {
      await LogWriter().saveLogsToFile(
          'ERROR_Log_', ['Error Closing previous api: ${e.toString()}']);
      print('Error: $e');
    }
    try {
      final result = await Process.run(
          'cmd.exe', ['/c', 'taskkill /F /IM CrystalReport.exe']);
      LogWriter().saveLogsToFile('ERROR_Log_', ['Closing previous api...']);
    } catch (e) {
      await LogWriter().saveLogsToFile(
          'ERROR_Log_', ['Error Closing previous api: ${e.toString()}']);
      print('Error: $e');
    }
    EasyLoading.dismiss();
    //------------------------------------
    SystemNavigator.pop();

    if (POSPlatform().isDesktop()) {
      appWindow.close();
    } else if (kIsWeb) {
      SystemNavigator.pop();
    } else {
      SystemNavigator.pop();
    }
  }
}
