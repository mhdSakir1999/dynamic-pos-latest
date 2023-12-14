/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/22/21, 1:23 PM
 */
import 'package:checkout/bloc/keyboard_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/mypos_screen_utils.dart';
import 'package:checkout/components/widgets/colored_textfield.dart';
import 'package:checkout/components/widgets/poskeyboard.dart';
import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/controllers/master_download_controller.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/enum/keyboard_type.dart';
import 'package:checkout/models/enum/signon_status.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/landing/landing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supercharged/supercharged.dart';

/// This view is used to enter the opening float value
class OpenFloatScreen extends StatefulWidget {
  static const routeName = "opening_float";

  @override
  _OpenFloatScreenState createState() => _OpenFloatScreenState();
}

class _OpenFloatScreenState extends State<OpenFloatScreen> {
  final openingFloatController = TextEditingController();
  String? text;

  @override
  void initState() {
    super.initState();
    //Set the pre-defined fixed float in U_TBLSETUP table
    openingFloatController.text = ((POSConfig().setup?.fixedFloat ?? 0) == 0
            ? ''
            : (POSConfig().setup?.fixedFloat ?? 0))
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = userBloc.currentUser;
    //final format = DateFormat("yyyy-MM-dd HH:mm:ss");
    final format = DateFormat("yyyy-MM-dd");
    String loggedDate = DateFormat.yMMMMEEEEd().format(format
        .parse(currentUser?.uSERHEDSIGNONDATE ?? DateTime.now().toString()));
    String loggedTime = DateFormat("hh:mm:ss aa").format(format
        .parse(currentUser?.uSERHEDSIGNONDATE ?? DateTime.now().toString()));
    final containerWidth = POSConfig().containerSize.w;
    return POSBackground(
        child: Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: containerWidth + 45,
            child: Column(
              children: [
                SizedBox(
                  height: POSConfig().topMargin.h,
                ),
                POSAppBar(),
                SizedBox(
                  height: 8.h,
                ),
                UserCard(
                    text: "last_access".tr(
                        namedArgs: {"date": loggedDate, "time": loggedTime})),
                SizedBox(
                  height: 8.h,
                ),
                Container(
                  width: containerWidth,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 25.h),
                      child: Text(
                        text ?? "open_float_view.opening_float".tr(),
                        style: CurrentTheme.headline6!.copyWith(
                            color: text == null
                                ? CurrentTheme.primaryColor
                                : Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 8.h,
                ),
                Container(
                  width: containerWidth,
                  child: ColoredTextField(
                    readOnly: isMobile,
                    onEditingCompleted: doSignOn,
                    autoFocus: true,
                    filledColor: CurrentTheme.primaryColor!,
                    controller: openingFloatController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  height: 10.h,
                ),
                Container(
                  width: containerWidth,
                  child: POSKeyBoard(
                      onPressed: () {
                        openingFloatController.clear();
                      },
                      onEnter: doSignOn,
                      isInvoiceScreen: false,
                      controller: openingFloatController),
                ),
                SizedBox(
                  height: 10.h,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
                        onPressed: () {
                          openingFloatController.clear();
                        },
                        child: Text("open_float_view.clear_button".tr())),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                POSConfig().primaryDarkGrayColor.toColor()),
                        onPressed: () => doSignOn(),
                        child: Text(
                          "open_float_view.confirm_button".tr(),
                          overflow: TextOverflow.fade,
                        )),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    ));
  }

  // This is the sign on process
  Future doSignOn() async {
    AuthController authController = AuthController();
    EasyLoading.show(status: 'please_wait'.tr());
    final res = await authController.signOnProcess(openingFloatController.text);
    await authController
        .checkUsername(userBloc.currentUser?.uSERHEDUSERCODE ?? "");
    EasyLoading.dismiss();

    if (res == null) {
      userBloc.changeSignOnStatus(SignOnStatus.SignOn);
      try {
        double floatAmt = openingFloatController.text.parseDouble();
        await PrintController().signOnSlip(floatAmt);
      } on Exception {}
      POSLogger(POSLoggerLevel.info, "Clearing the current root");
      Navigator.of(context).popUntil((route) => route.isFirst);
      final root = LandingView.routeName;
      POSLogger(POSLoggerLevel.info, "Re-navigate to $root");
      Navigator.pushReplacementNamed(context, root);

      //download master tables
      EasyLoading.show(status: 'download_master'.tr());
      final result = await MasterDownloadController().downloadAndSyncMaster();
      if (result != null) {
        EasyLoading.dismiss();
        EasyLoading.showToast(result['message']);
      }
    } else
      setState(() {
        text = res;
      });

    keyBoardBloc.setKey(keyType.None);
  }
}
