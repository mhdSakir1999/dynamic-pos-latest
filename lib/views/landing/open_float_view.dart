/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/22/21, 1:23 PM
 */
import 'package:checkout/bloc/keyboard_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/mypos_screen_utils.dart';
import 'package:checkout/components/widgets/poskeyboard.dart';
import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/controllers/master_download_controller.dart';
import 'package:checkout/controllers/pos_manual_print_controller.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/enum/keyboard_type.dart';
import 'package:checkout/models/enum/signon_status.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/landing/landing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool editable = false;
  bool permissionGotAlready = false;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    //Set the pre-defined fixed float in U_TBLSETUP table
    openingFloatController.text = ((POSConfig().setup?.fixedFloat ?? 0) == 0
            ? ''
            : (POSConfig().setup?.fixedFloat ?? 0).toStringAsFixed(2))
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    // final config = POSConfig();
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
                InkWell(
                  onTap: permissionGotAlready
                      ? null
                      : () async {
                          SpecialPermissionHandler handler =
                              SpecialPermissionHandler(context: context);
                          bool permissionStatus = handler.hasPermission(
                              permissionCode: PermissionCode.changeDefaultFloat,
                              accessType: 'A',
                              refCode:
                                  'Float entry ${DateTime.now()}:${POSConfig().terminalId}');
                          if (!permissionStatus) {
                            final permission = await handler.askForPermission(
                                permissionCode:
                                    PermissionCode.changeDefaultFloat,
                                accessType: "A",
                                refCode: '');
                            if (permission.success) {
                              setState(() {
                                editable = true;
                                permissionGotAlready = true;
                              });
                            } else {
                              setState(() {
                                editable = false;
                              });
                            }
                          }
                          if (permissionStatus) {
                            setState(() {
                              editable = true;
                              permissionGotAlready = true;
                              focusNode.requestFocus();
                            });
                          }
                        },
                  child: Card(
                    color: CurrentTheme.primaryColor,
                    child: Container(
                      width: containerWidth,
                      child: editable
                          ? TextField(
                              readOnly: (isMobile && !editable),
                              autofocus: false,
                              textAlign: TextAlign.center,
                              focusNode: focusNode,
                              style: TextStyle(fontWeight: FontWeight.bold),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              onEditingComplete: () async {
                                if (!RegExp(r'^\d+\.?\d{0,2}?$')
                                    .hasMatch(openingFloatController.text)) {
                                  EasyLoading.showError('wrong_format'.tr());
                                  return;
                                }

                                // confirmation dialog when continue with 0 float
                                if (double.parse(openingFloatController.text)
                                        .toStringAsFixed(0) ==
                                    '0') {
                                  bool? continueWithZeroFloat =
                                      await showGeneralDialog<bool?>(
                                          context: context,
                                          transitionDuration:
                                              const Duration(milliseconds: 200),
                                          barrierDismissible: true,
                                          barrierLabel: '',
                                          transitionBuilder: (context, a, b,
                                                  _) =>
                                              Transform.scale(
                                                scale: a.value,
                                                child: AlertDialog(
                                                    content: Text(
                                                        'general_dialog.continue_zero_float'
                                                            .tr()),
                                                    actions: [
                                                      ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  POSConfig()
                                                                      .primaryDarkGrayColor
                                                                      .toColor()),
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context, false);
                                                          },
                                                          child: Text(
                                                              'general_dialog.change'
                                                                  .tr())),
                                                      ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  POSConfig()
                                                                      .primaryDarkGrayColor
                                                                      .toColor()),
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context, true);
                                                          },
                                                          child: Text(
                                                              'general_dialog.yes'
                                                                  .tr()))
                                                    ]),
                                              ),
                                          pageBuilder: (context, animation,
                                              secondaryAnimation) {
                                            return const SizedBox();
                                          });
                                  if (continueWithZeroFloat != true) return;
                                }

                                doSignOn();
                              },
                              // autoFocus: true,
                              // filledColor: CurrentTheme.primaryColor!,
                              controller: openingFloatController,
                              keyboardType: TextInputType.number,
                            )
                          : Center(
                              heightFactor: 2,
                              child: Text(
                                openingFloatController.text,
                                style:const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 10.h,
                ),
                !editable
                    ? const SizedBox.shrink()
                    : Container(
                        width: containerWidth,
                        child: POSKeyBoard(
                            onPressed: () async {
                              openingFloatController.clear();
                            },
                            nextFocusTo: focusNode,
                            normalKeyPress: () {
                              if (openingFloatController.text.contains('.')) {
                                var rational =
                                    openingFloatController.text.split('.')[1];
                                if (rational.length >= 2) {
                                  return 0;
                                }
                              }
                            },
                            onEnter: () async {
                              if (!RegExp(r'^\d+\.?\d{0,2}?$')
                                  .hasMatch(openingFloatController.text)) {
                                EasyLoading.showError('wrong_format'.tr());
                                return;
                              }
                              // confirmation dialog when continue with 0 float
                              if (double.parse(openingFloatController.text)
                                      .toStringAsFixed(0) ==
                                  '0') {
                                bool? continueWithZeroFloat =
                                    await showGeneralDialog<bool?>(
                                        context: context,
                                        transitionDuration:
                                            const Duration(milliseconds: 200),
                                        barrierDismissible: true,
                                        barrierLabel: '',
                                        transitionBuilder: (context, a, b, _) =>
                                            Transform.scale(
                                              scale: a.value,
                                              child: AlertDialog(
                                                  content: Text(
                                                      'general_dialog.continue_zero_float'
                                                          .tr()),
                                                  actions: [
                                                    ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                POSConfig()
                                                                    .primaryDarkGrayColor
                                                                    .toColor()),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context, false);
                                                        },
                                                        child: Text(
                                                            'general_dialog.change'
                                                                .tr())),
                                                    ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                POSConfig()
                                                                    .primaryDarkGrayColor
                                                                    .toColor()),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context, true);
                                                        },
                                                        child: Text(
                                                            'general_dialog.yes'
                                                                .tr()))
                                                  ]),
                                            ),
                                        pageBuilder: (context, animation,
                                            secondaryAnimation) {
                                          return const SizedBox();
                                        });
                                if (continueWithZeroFloat != true) return;
                              }
                              doSignOn();
                            },
                            isInvoiceScreen: false,
                            disableArithmetic: true,
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
                            backgroundColor:
                                POSConfig().primaryDarkGrayColor.toColor()),
                        onPressed: permissionGotAlready
                            ? () {
                                openingFloatController.clear();
                                focusNode.requestFocus();
                              }
                            : () async {
                                SpecialPermissionHandler handler =
                                    SpecialPermissionHandler(context: context);
                                bool permissionStatus = handler.hasPermission(
                                    permissionCode:
                                        PermissionCode.changeDefaultFloat,
                                    accessType: 'A',
                                    refCode: '');
                                if (!permissionStatus) {
                                  final permission = await handler.askForPermission(
                                      permissionCode:
                                          PermissionCode.changeDefaultFloat,
                                      accessType: "A",
                                      refCode:
                                          'Float entry ${DateTime.now()}:${POSConfig().terminalId}');
                                  if (permission.success) {
                                    setState(() {
                                      editable = true;
                                      permissionGotAlready = true;
                                    });
                                    openingFloatController.clear();
                                    focusNode.requestFocus();
                                  }
                                }
                                if (permissionStatus) {
                                  setState(() {
                                    editable = true;
                                    permissionGotAlready = true;
                                  });
                                  openingFloatController.clear();
                                  focusNode.requestFocus();
                                }
                              },
                        child: Text("open_float_view.clear_button".tr())),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                POSConfig().primaryDarkGrayColor.toColor()),
                        onPressed: () async {
                          if (!RegExp(r'^\d+\.?\d{0,2}?$')
                              .hasMatch(openingFloatController.text)) {
                            EasyLoading.showError('wrong_format'.tr());
                            return;
                          }
                          // confirmation dialog when continue with 0 float
                          if (double.parse(openingFloatController.text)
                                  .toStringAsFixed(0) ==
                              '0') {
                            bool? continueWithZeroFloat =
                                await showGeneralDialog<bool?>(
                                    context: context,
                                    transitionDuration:
                                        const Duration(milliseconds: 200),
                                    barrierDismissible: true,
                                    barrierLabel: '',
                                    transitionBuilder: (context, a, b, _) =>
                                        Transform.scale(
                                          scale: a.value,
                                          child: AlertDialog(
                                              content: Text(
                                                  'general_dialog.continue_zero_float'
                                                      .tr()),
                                              actions: [
                                                ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                        backgroundColor: POSConfig()
                                                            .primaryDarkGrayColor
                                                            .toColor()),
                                                    onPressed: () {
                                                      Navigator.pop(
                                                          context, false);
                                                    },
                                                    child: Text(
                                                        'general_dialog.change'
                                                            .tr())),
                                                ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                        backgroundColor: POSConfig()
                                                            .primaryDarkGrayColor
                                                            .toColor()),
                                                    onPressed: () {
                                                      Navigator.pop(
                                                          context, true);
                                                    },
                                                    child: Text(
                                                        'general_dialog.yes'
                                                            .tr()))
                                              ]),
                                        ),
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return const SizedBox();
                                    });
                            if (continueWithZeroFloat != true) return;
                          }
                          doSignOn();
                        },
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
        if (POSConfig.crystalPath != '') {
          await PrintController().signOnSlip(floatAmt);
        } else {
          await POSManualPrint()
              .printSignSlip(data: '', slipType: 'signon', float: floatAmt);
        }
      } on Exception {}
      POSLogger(POSLoggerLevel.info, "Clearing the current root");
      Navigator.of(context).popUntil((route) => route.isFirst);
      final root = LandingView.routeName;
      POSLogger(POSLoggerLevel.info, "Re-navigate to $root");
      Navigator.pushReplacementNamed(context, root);

      if (POSConfig().allowLocalMode == true) {
        //download master tables
        EasyLoading.show(status: 'download_master'.tr());
        final result = await MasterDownloadController().downloadAndSyncMaster();
        if (result != null) {
          EasyLoading.dismiss();
          EasyLoading.showToast(result['message']);
        }
      }
    } else
      setState(() {
        text = res;
      });

    keyBoardBloc.setKey(keyType.None);
  }
}
