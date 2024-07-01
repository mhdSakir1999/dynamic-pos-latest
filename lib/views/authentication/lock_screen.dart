/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/28/21, 3:49 PM
 */

import 'package:checkout/bloc/lock_screen_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../controllers/keyboard_controller.dart';

class LockScreen extends StatefulWidget {
  LockScreen({Key? key}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final passwordEditingController = TextEditingController();
  String? currentError;
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    lockScreenBloc.lockScreenStream.listen((event) {
      if (event) {
        focusNode.requestFocus();
      } else {
        focusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    passwordEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = POSConfig().containerSize * 0.55.w;
    final padding = EdgeInsets.symmetric(vertical: 10.r);
    return Column(
      children: [
       const Spacer(),
       const Center(
            child: POSClock(
          centerAlign: true,
          dateFontSize: 20,
          timeFontSize: 60,
        )),
        SizedBox(
          height: 40.h,
        ),
        Center(
            child: Container(
                width: width,
                child: UserCard(
                  shift: true,
                  text: "",
                ))),
        Container(
          width: width,
          child: Card(
            color: CurrentTheme.primaryColor,
            child: Container(
                alignment: Alignment.center,
                padding: padding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock,
                      size: CurrentTheme.headline5!.fontSize,
                    ),
                    SizedBox(
                      width: 7.r,
                    ),
                    Text(
                      currentError ?? "LOCKED !",
                      style: CurrentTheme.headline5!.copyWith(
                          color: CurrentTheme.primaryDarkColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                )),
          ),
        ),
        SizedBox(
          height: 7.h,
        ),
        Container(
            width: width,
            child: TextField(
              onTap: () {
                // KeyBoardController().dismiss();
                KeyBoardController().showBottomDPKeyBoard(
                    passwordEditingController,
                    obscureText: true, onEnter: () {
                  KeyBoardController().dismiss();
                  validatePassword();
                }, buildContext: context);
              },
              controller: passwordEditingController,
              obscureText: true,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => validatePassword(),
              decoration: InputDecoration(
                  filled: true,
                  hintText: "Enter your Password",
                  hintStyle: TextStyle(color: CurrentTheme.primaryColor)),
            )),
       const Spacer(
          flex: 3,
        ),
      ],
    );
  }

  Future validatePassword() async {
    final password = passwordEditingController.text;
    passwordEditingController.clear();
    if (password.isEmpty) {
      return;
    }
    if (mounted)
      setState(() {
        currentError = null;
      });
    EasyLoading.show(status: 'please_wait'.tr());
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Password entered"));
    final result = await AuthController().checkPassword(
        userBloc.currentUser?.uSERHEDUSERCODE ?? '',
        password,
        POSConfig().locCode);
    EasyLoading.dismiss();
    if (result?.success == true) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.success, "Password validation success: $result"));
      // Navigator.pop(context);
      lockScreenBloc.setLocked(false);
    } else {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Password validation error: $result"));
      setState(() {
        currentError = "Incorrect Password";
      });
    }
  }
}
