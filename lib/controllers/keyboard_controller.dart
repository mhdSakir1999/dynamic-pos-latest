/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: TM.Sakir & Chathura Priyashad
 * Created At: 4/23/21, 2:27 PM
 * Modified by: TM.Sakir
 */

import 'package:checkout/components/widgets/alphakeyboard.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:flutter/material.dart';

// Bind Keyboard with Text Field.
class KeyBoardController {
  late BuildContext context;
  static bool isShow = false;
  final _name = "POS keyboard";
  KeyBoardController._internal();

  static final KeyBoardController _singleton = KeyBoardController._internal();

  init(BuildContext context) {
    this.context = context;
  }

  factory KeyBoardController() {
    return _singleton;
  }

  void dismiss() {
    if (isShow && POSConfig().touchKeyboardEnabled) {
      POSLogger(POSLoggerLevel.info, "$_name is dismissed");
      isShow = false;
      //if (ModalRoute.of(context)!.canPop)
      try {
        Navigator.pop(context);
      } catch (e) {
        isShow = false;
      }
    }
  }

  // This is used in continueous open and close of pos keyboard. If we dont use this, the new instance of poskeyboard will open before the previous one is closed
  Future<void> setIsShow() async {
    isShow = true;
  }

// Keyboard initiating method
  Future showBottomDPKeyBoard(TextEditingController textEditingController,
      {VoidCallback? onEnter,
      String? mask,
      bool? obscureText,
      BuildContext? buildContext}) async {
    if (isShow) {
      dismiss();
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.error,
          "$_name is already present, Please dismiss the current keyboard"));
    } else {
      if (!POSConfig().touchKeyboardEnabled) return;
      isShow = true;
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.info, "$_name showed"));
      await showModalBottomSheet(
        context: buildContext ?? context,
        builder: (context) {
          return AlphaKeyboard(
            controller: textEditingController,
            onEnter: onEnter,
            mask: mask,
            obscureText: obscureText,
          );
        },
      ).whenComplete(() {
        isShow = false;
      });
    }
  }
}
