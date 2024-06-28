/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/22/21, 1:15 PM
 */

import 'dart:async';
import 'dart:io';

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/discount_bloc.dart';
import 'package:checkout/bloc/group_bloc.dart';
import 'package:checkout/bloc/notification_bloc.dart';
import 'package:checkout/bloc/paymode_bloc.dart';
import 'package:checkout/bloc/price_mode_bloc.dart';
import 'package:checkout/bloc/salesRep_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/mypos_screen_utils.dart';
import 'package:checkout/components/recurringApiCalls.dart';
import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/controllers/backup_controller.dart';
import 'package:checkout/controllers/config/shared_preference_controller.dart';
import 'package:checkout/controllers/denomination_controller.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/local_storage_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/controllers/promotion_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/controllers/usb_serial_controller.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/enum/pos_connectivity_status.dart';
import 'package:checkout/models/enum/signon_status.dart';
import 'package:checkout/models/pos/pos_denomination_model.dart';
import 'package:checkout/models/pos/user_hed.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/authentication/exit_screen.dart';
import 'package:checkout/views/landing/landing_alert_controller.dart';
import 'package:checkout/views/landing/landing_helper.dart';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:checkout/views/dashboard/dashboard_view.dart';
import 'package:supercharged/supercharged.dart';
import '../../controllers/invoice_controller.dart';
import '../../controllers/pos_alerts/pos_warning_alert.dart';
import '../../models/pos/permission_code.dart';
import '../../models/promotion_model.dart';
import '../pos_functions/service_status_view.dart';

/// This is the landing screen of the application. This page contains sign on,
/// sign off, invoice, day end manager sign off and turn off the system
class LandingView extends StatefulWidget {
  static const routeName = "landing";
  final bool? showPromotion;

  LandingView({Key? key, this.showPromotion}) : super(key: key);

  @override
  _LandingViewState createState() => _LandingViewState(showPromotion);
}

class _LandingViewState extends State<LandingView> {
  final bool? showPromotion;
  FocusNode _focusNode = FocusNode();
  FocusNode _promoFocusNode = FocusNode();
  FocusNode _eodFocusNode = FocusNode();

  _LandingViewState(this.showPromotion);

  DateTime? _eodDateTime;
  bool isEOD_Pending = false;

  @override
  void initState() {
    super.initState();
    POSConfig().bypassEodValidation = false;
    notificationBloc.getNotifications();
    saveConfig();
    _focusNode.requestFocus();
    if (POSConfig().enablePollDisplay == 'true') {
      try {
        // usbSerial.sendToSerialDisplay('     HELLO !!!      ');
        // usbSerial.sendToSerialDisplay('  WELCOME TO SPAR   ');
        usbSerial.showCustomMessages('hello');
        usbSerial.showCustomMessages('welcome');
      } catch (e) {
        LogWriter().saveLogsToFile('ERROR_LOG_', [e.toString()]);
      }
    }
    payModeBloc.getPayModeList();
    payModeBloc.getCardDetails();
    discountBloc.getDiscountTypes();
    groupBloc.getDepartments();
    priceModeBloc.fetchPriceModes();
    salesRepBloc.getSalesReps(); //fetching salesreps and save it in bloc/stream
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _promoFocusNode.dispose();
    _eodFocusNode.dispose();
    userCtrl.dispose();
    locCtrl.dispose();
    shiftCtrl.dispose();
    stationCtrl.dispose();
    dateCtrl.dispose();
    userFocus.dispose();
    locFocus.dispose();
    shiftFocus.dispose();
    stationFocus.dispose();
    dateFocus.dispose();
    super.dispose();
  }

  Future<void> saveConfig() async {
    SharedPreferenceController sharedPreferenceController =
        SharedPreferenceController();
    sharedPreferenceController.saveConfigLocal();
    if (showPromotion != null) {
      initFunctions();
    }
  }

  /* load promotions and sync bill data */
  /* By dinuka 2022/08/03 */
  initFunctions() async {
    await getPromotions();
    if (POSConfig().allowLocalMode && POSConfig().allow_sync_bills)
      await uploadBillData();
  }

  final authController = AuthController();
  final alertController = LandingAlertController();
  late LandingHelper landingHelper;

  @override
  Widget build(BuildContext context) {
    landingHelper = LandingHelper(context, authController, alertController);
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "${userBloc.signOnStatus}"));

    alertController.init(context);
    posConnectivity.setContext(context);
    recurringApiCalls.setContext(context);
    return POSBackground(
        showConnection: false,
        child: Stack(
          children: [
            Scaffold(
              body: buildBody(context, landingHelper),
            ),
            Positioned(
              right: 5,
              child: Row(
                children: [
                  IconButton(
                      onPressed: () async {
                        if (POSConfig().localMode) {
                          bool serverRes =
                              await POSConnectivity().pingToServer();
                          if (serverRes) {
                            cartBloc.context = context;
                            bool userRes =
                                await cartBloc.serverConnectionPopup();
                            if (userRes == true) {
                              EasyLoading.show(status: 'Please wait...');
                              payModeBloc.getPayModeList();
                              payModeBloc.getCardDetails();
                              discountBloc.getDiscountTypes();
                              groupBloc.getDepartments();
                              priceModeBloc.fetchPriceModes();
                              salesRepBloc.getSalesReps();
                              initFunctions();
                              EasyLoading.dismiss();
                            }
                            setState(() {});
                          }
                        } else {
                          EasyLoading.showInfo(
                              'Server connection already available !!!');
                          return;
                        }
                      },
                      icon: Icon(
                        Icons.wifi_find_outlined,
                        color:
                            POSConfig().localMode ? Colors.red : Colors.green,
                      )),
                  IconButton(
                      onPressed: () => _rePrintDialog(context),
                      icon: Icon(
                        Icons.print_outlined,
                        color: Colors.green,
                      )),
                  IconButton(
                      onPressed: () => _showSpecialOptions(context),
                      icon: Icon(
                        Icons.sync,
                        color: Colors.green,
                      )),
                ],
              ),
            )
          ],
        ));
  }

  /* Upload local invoice data to server */
  /* By Dinuka 2022/07/28 */
  Future uploadBillData() async {
    // EasyLoading.show(status: 'please_wait'.tr(), dismissOnTap: true);
    var result = await InvoiceController().uploadBillData();
    if (result != null) {
      // EasyLoading.dismiss();
      EasyLoading.showToast(result['message']);
    }
  }

  /* Get Promotions function */
  /* By Dinuka 2022/07/28 */
  Future getPromotions() async {
    EasyLoading.show(status: 'landing_view.check_promotions'.tr());
    var response = await PromotionController(context).getPromotions();
    List<Promotion> promotionsList = response?.promotions ?? [];

    if (promotionsList.isNotEmpty) {
      EasyLoading.dismiss();
      await promotionPopup(promotionsList);
    } else {
      EasyLoading.dismiss();
      EasyLoading.showToast('landing_view.no_promotions'.tr());
    }
  }

  /* Promotion Dialog */
  /* By Dinuka 2022/07/28 */
  Future<void> promotionPopup(List<Promotion> promotionList) async {
    final height = MediaQuery.of(context).size.height;
    _promoFocusNode.requestFocus();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('landing_view.promotion_dialog_tile'.tr()),
          content: KeyboardListener(
            focusNode: _promoFocusNode,
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                if (event.physicalKey == PhysicalKeyboardKey.enter ||
                    event.physicalKey == PhysicalKeyboardKey.keyO) {
                  Navigator.pop(context); // Close the dialog on Enter key press
                }
              }
            },
            child:

                // Column(
                //   children: [
                //     Container(
                //       height: height * 0.5,
                //       child: ListView.builder(
                //           itemCount: promotionList.length,
                //           itemBuilder: (context, index) =>
                //               promotionItem(promotionList[index])),
                //     ),
                //     Container(
                //       height: height * 0.2,
                //       child: AlertDialogButton(
                //           onPressed: () => Navigator.pop(context),
                //           text: 'invoice.zero_item_button'.tr()),
                //     )
                //   ],
                // )

                SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var promotion in promotionList)
                        promotionItem(promotion)
                    ],
                  ),
                  AlertDialogButton(
                      onPressed: () => Navigator.pop(context),
                      text: 'invoice.zero_item_button'.tr())
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget promotionItem(Promotion promotion) {
    String startDate = DateFormat("yyyy-MM-dd").format(promotion.prOSTDATE);
    String endDate = DateFormat("yyyy-MM-dd").format(promotion.prOENDATE);
    return ListTile(
      leading: Icon(Icons.circle_rounded),
      title: Text(promotion.prODESC ?? ''),
      subtitle: Text("From : " + startDate + " To : " + endDate),
    );
    // return Card(
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
    //   color: CurrentTheme.primaryColor,
    //   child: Container(
    //     decoration: BoxDecoration(border: Border.all(color: Colors.black)),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text(promotion.proDesc ?? ''),
    //         Text("From : " + startDate + " To : " + endDate),
    //         SizedBox(
    //           height: 10.h,
    //         )
    //       ],
    //     ),
    //   ),
    // );
  }

  Future<void> _showSpecialOptions(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Special Options', textAlign: TextAlign.center),
          content: SizedBox(
            width: ScreenUtil().screenWidth * 0.4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: 25.h),
                AlertDialogButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showStructureChanges(context);
                    },
                    text: 'Structure Changes'),
                SizedBox(height: 15.h),
                AlertDialogButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // if (!POSConfig().localMode)
                      _restInvoiceNo(context);
                    },
                    text: 'Reset Invoice Number'),
                SizedBox(height: 15.h),
                AlertDialogButton(
                    onPressed: () async {
                      EasyLoading.show(status: 'please_wait'.tr());
                      //killing the crystal report instance first, if available
                      try {
                        final result = await Process.run('cmd.exe',
                            ['/c', 'taskkill /F /IM CrystalReport.exe']);
                        LogWriter().saveLogsToFile(
                            'ERROR_Log_', ['Closing CrystalReport...']);

                        print('Exit code: ${result.exitCode}');
                        print('Stdout:\n${result.stdout}');
                        print('Stderr:\n${result.stderr}');
                      } catch (e) {
                        await LogWriter().saveLogsToFile('ERROR_Log_',
                            ['Error Closing CrystalReport: ${e.toString()}']);
                        print('Error: $e');
                      }
                      // launching crystal report plugin
                      try {
                        POSLoggerController.addNewLog(POSLogger(
                            POSLoggerLevel.info,
                            "Starting CrystalReport API..."));
                        String localCrystalPath =
                            dotenv.env['CRYSTAL_REPORT_PATH'] ??
                                'C:\\checkout\\CRYSTAL_REPORT';
                        //  var exec = "${localAPIPath!} dotnet run --urls http://0.0.0.0:71";
                        POSLoggerController.addNewLog(POSLogger(
                            POSLoggerLevel.info, "path: $localCrystalPath"));

                        // var command = Process.run(
                        //     'cmd.exe', ['/c', 'cd $localAPIPath && CrystalReport.exe'],
                        //     runInShell: true);
                        var command = Process.run(
                          'CrystalReport.exe',
                          [],
                          runInShell: true,
                          workingDirectory: localCrystalPath,
                        );
                      } catch (e) {
                        POSLoggerController.addNewLog(POSLogger(
                            POSLoggerLevel.error,
                            "Error starting CrystalReport API: $e"));
                      }
                      EasyLoading.dismiss();
                      Navigator.pop(context);
                    },
                    text: 'Re-Open Crystal Plugin'),
                SizedBox(height: 25.h),
                AlertDialogButton(
                    onPressed: () async {
                      String data = POSConfig.localPrintData;
                      List<POSDenominationModel> denominations =
                          POSConfig.denominations;
                      List<POSDenominationDetail> denominationDet =
                          POSConfig.denominationDet;
                      // await POSManualPrint()
                      //     .printInvoice(data: data, points: 0.0);
                      // await POSManualPrint().printSignSlip(
                      //     data: '', slipType: 'signoff', float: 100);
                      // await POSManualPrint().printManagerSlip(
                      //     data: data,
                      //     denominations: denominations,
                      //     denominationDet: denominationDet);

                      await DenominationController().reprintManagerSignoff(
                          userId: '4626',
                          locCode: '00016',
                          terminalId: '005',
                          shiftNo: '2',
                          date: "2024-05-15 00:00:00.000");

                      // recurringApiCalls.listenPhysicalCash();
                    },
                    text: 'testPrint'),
              ],
            ),
          ),
        );
      },
    );
  }

  TextEditingController userCtrl = TextEditingController();
  TextEditingController locCtrl = TextEditingController();
  TextEditingController shiftCtrl = TextEditingController();
  TextEditingController stationCtrl = TextEditingController();
  TextEditingController dateCtrl = TextEditingController();
  FocusNode userFocus = FocusNode();
  FocusNode locFocus = FocusNode();
  FocusNode shiftFocus = FocusNode();
  FocusNode stationFocus = FocusNode();

  List<FocusNode> nodes = [];
  FocusNode dateFocus = FocusNode();
  Future<void> _rePrintDialog(BuildContext context) async {
    nodes = [userFocus, locFocus, stationFocus, shiftFocus];
    final now = DateTime.now();
    final containerWidth = POSConfig().containerSize.w;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Manager-Signoff Re-Print', textAlign: TextAlign.center),
          content: SizedBox(
            width: ScreenUtil().screenWidth * 0.6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: containerWidth * 1.5,
                        child: Row(
                          children: [
                            labelElement('Cashier Id'),
                            textElement(
                              '',
                              14,
                              userCtrl,
                              focusNode: userFocus,
                              onTap: () {
                                KeyBoardController().dismiss();
                                KeyBoardController().init(context);
                                KeyBoardController().showBottomDPKeyBoard(
                                    userCtrl, onEnter: () async {
                                  KeyBoardController().dismiss();
                                  userFocus.unfocus();
                                  locFocus.requestFocus();
                                  await KeyBoardController().setIsShow();
                                  KeyBoardController().showBottomDPKeyBoard(
                                      locCtrl, onEnter: () async {
                                    KeyBoardController().dismiss();
                                    locFocus.unfocus();
                                    stationFocus.requestFocus();
                                    await KeyBoardController().setIsShow();
                                    KeyBoardController().showBottomDPKeyBoard(
                                        stationCtrl, onEnter: () async {
                                      KeyBoardController().dismiss();
                                      stationFocus.unfocus();
                                      shiftFocus.requestFocus();
                                      await KeyBoardController().setIsShow();
                                      KeyBoardController().showBottomDPKeyBoard(
                                          shiftCtrl, onEnter: () {
                                        KeyBoardController().dismiss();
                                      });
                                    });
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: containerWidth * 1.5,
                        child: Row(
                          children: [
                            labelElement('Location Code'),
                            textElement(
                              '',
                              14,
                              locCtrl,
                              focusNode: locFocus,
                              onTap: () {
                                KeyBoardController().dismiss();
                                KeyBoardController().init(context);
                                KeyBoardController().showBottomDPKeyBoard(
                                    locCtrl, onEnter: () async {
                                  KeyBoardController().dismiss();
                                  locFocus.unfocus();
                                  stationFocus.requestFocus();
                                  await KeyBoardController().setIsShow();
                                  KeyBoardController().showBottomDPKeyBoard(
                                      stationCtrl, onEnter: () async {
                                    KeyBoardController().dismiss();
                                    stationFocus.unfocus();
                                    shiftFocus.requestFocus();
                                    await KeyBoardController().setIsShow();
                                    KeyBoardController().showBottomDPKeyBoard(
                                        shiftCtrl, onEnter: () {
                                      KeyBoardController().dismiss();
                                    });
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: containerWidth * 1.5,
                        child: Row(
                          children: [
                            labelElement('Terminal Number'),
                            textElement(
                              '',
                              14,
                              stationCtrl,
                              focusNode: stationFocus,
                              onTap: () {
                                KeyBoardController().dismiss();
                                KeyBoardController().init(context);
                                KeyBoardController().showBottomDPKeyBoard(
                                    stationCtrl, onEnter: () async {
                                  KeyBoardController().dismiss();
                                  stationFocus.unfocus();
                                  shiftFocus.requestFocus();
                                  await KeyBoardController().setIsShow();
                                  KeyBoardController().showBottomDPKeyBoard(
                                      shiftCtrl, onEnter: () {
                                    KeyBoardController().dismiss();
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: containerWidth * 1.5,
                        child: Row(
                          children: [
                            labelElement('Shift Number'),
                            textElement(
                              '',
                              14,
                              shiftCtrl,
                              focusNode: shiftFocus,
                              onTap: () {
                                KeyBoardController().dismiss();
                                KeyBoardController().init(context);
                                KeyBoardController().showBottomDPKeyBoard(
                                    shiftCtrl, onEnter: () {
                                  KeyBoardController().dismiss();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: containerWidth * 1.5,
                        child: Row(
                          children: [
                            labelElement('Sign-On Date'),
                            wrapper(
                              width: 5.5,
                              child: Theme(
                                data: CurrentTheme.themeData!.copyWith(
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: CurrentTheme
                                          .primaryLightColor, // button text color
                                    ),
                                  ),
                                ),
                                child: DateTimeField(
                                  controller: dateCtrl,
                                  enabled: true,
                                  format: DateFormat("yyyy-MM-dd"),
                                  focusNode: dateFocus,
                                  initialValue: dateCtrl.text.isEmpty
                                      ? DateTime.now()
                                      : DateFormat("yyyy-MM-dd")
                                          .parse(dateCtrl.text),
                                  style: TextStyle(
                                      color: CurrentTheme.primaryColor,
                                      fontSize: 14.sp),
                                  decoration: InputDecoration(
                                    filled: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 15),
                                  ),
                                  onShowPicker: (context, currentValue) async {
                                    final date = await showDatePicker(
                                        context: context,
                                        firstDate: DateTime(1900),
                                        initialDate:
                                            currentValue ?? DateTime.now(),
                                        locale: EasyLocalization.of(context)!
                                            .locale,
                                        lastDate: DateTime.now());
                                    if (date != null)
                                      dateCtrl.text =
                                          DateFormat("yyyy-MM-dd").format(date);
                                    setState(() {});
                                    return date;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        child: Container(
                          child: IconButton(
                              onPressed: () async {
                                if (userCtrl.text.isEmpty) {
                                  EasyLoading.showError(
                                      'Cashier Id is required');
                                  return;
                                }
                                if (locCtrl.text.isEmpty) {
                                  EasyLoading.showError(
                                      'Location code is required');
                                  return;
                                }
                                if (shiftCtrl.text.isEmpty) {
                                  EasyLoading.showError(
                                      'Shift number is required');
                                  return;
                                }
                                if (stationCtrl.text.isEmpty) {
                                  EasyLoading.showError(
                                      'Terminal Id is required');
                                  return;
                                }
                                if (dateCtrl.text.isEmpty) {
                                  EasyLoading.showError(
                                      'Sign-on Date is required');
                                  return;
                                }
                                await DenominationController()
                                    .reprintManagerSignoff(
                                        userId: userCtrl.text,
                                        locCode: locCtrl.text,
                                        terminalId: stationCtrl.text,
                                        shiftNo: shiftCtrl.text,
                                        date: dateCtrl.text);
                              },
                              icon: Icon(
                                Icons.print,
                              )),
                        ),
                      ),
                      Text(
                        'Print Slip',
                        style: CurrentTheme.bodyText2!.copyWith(
                            color: CurrentTheme.primaryDarkColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget textElement(
      String text, double width, TextEditingController controller,
      {bool disabled = false,
      FocusNode? focusNode,
      StringToFunc? validator,
      VoidCallback? onTap,
      List<TextInputFormatter>? inputFormatter}) {
    return wrapper(
      width: width * 0.75,
      child: TextFormField(
        onTap: onTap,
        validator: validator,
        focusNode: focusNode,
        readOnly: disabled,
        textAlign: TextAlign.left,
        inputFormatters: inputFormatter,
        enabled: true,
        style: CurrentTheme.bodyText2!
            .copyWith(color: CurrentTheme.primaryColor, fontSize: 20.sp),
        controller: controller,
        textInputAction: TextInputAction.next,
        onChanged: (String value) {
          if (mounted) setState(() {});
        },
        onEditingComplete: () {
          if (nodes.indexWhere((element) => element == focusNode) < 4) {
            int index = nodes.indexWhere((element) => element == focusNode);
            focusNode?.unfocus();
            nodes[index + 1].requestFocus();
          } else {
            int index = nodes.indexWhere((element) => element == focusNode);
            focusNode?.unfocus();
            dateFocus.requestFocus();
          }
        },
        decoration: InputDecoration(
          filled: true,
          hintText: text,
          alignLabelWithHint: true,
          isDense: true,
          contentPadding: EdgeInsets.all(10),
        ),
      ),
    );
  }

  Widget wrapper({required Widget child, required double width}) {
    final containerWidth = POSConfig().containerSize.w;
    return Container(
      width: containerWidth * width / 14,
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
      child: child,
    );
  }

  Container labelElement(text) {
    final containerWidth = POSConfig().containerSize.w;
    return Container(
      width: (containerWidth) * 3.5 / 12,
      child: Card(
        color: CurrentTheme.primaryColor,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 20.w),
          child: Text(
            text,
            style: CurrentTheme.bodyText2!.copyWith(
                color: CurrentTheme.primaryLightColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }

  Future<void> _showStructureChanges(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              'Do you want to apply latest structure changes from server?'),
          actions: [
            AlertDialogButton(
                onPressed: () {
                  Navigator.pop(context);
                  BackupController().backupStructures();
                },
                text: 'Yes'),
            AlertDialogButton(
                onPressed: () => Navigator.pop(context), text: 'No'),
          ],
        );
      },
    );
  }

  Future<void> _restInvoiceNo(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Do you want to reset invoice number?'),
          actions: [
            AlertDialogButton(
                onPressed: () {
                  Navigator.pop(context);
                  LocalStorageController().clearInvoiceNo();
                  LocalStorageController().clearWithdrawal();
                  EasyLoading.showSuccess('Successfully Reset');
                },
                text: 'Yes'),
            AlertDialogButton(
                onPressed: () => Navigator.pop(context), text: 'No'),
          ],
        );
      },
    );
  }

  Widget buildBody(BuildContext context, LandingHelper landingHelper) {
    // change by Sakir: moved these calls to initstate method
    // payModeBloc.getPayModeList();
    // payModeBloc.getCardDetails();
    // discountBloc.getDiscountTypes();
    // groupBloc.getDepartments();
    // priceModeBloc.fetchPriceModes();
    // salesRepBloc.getSalesReps(); //fetching salesreps and save it in bloc/stream
    final currentUser = userBloc.currentUser;

    String? date = userBloc.userDetails?.date ?? currentUser?.uSERHEDSIGNONTIME;
    String? time = currentUser?.uSERHEDSIGNONTIME;
    date?.replaceAll(" ", "T");
    String loggedUser = currentUser?.uSERHEDTITLE ?? "";
    final format = DateFormat("yyyy-MM-ddTHH:mm:ss");
    String now = DateTime.now().toIso8601String();

    String loggedDate =
        DateFormat.yMMMMEEEEd().format(format.parse(date ?? now));
    String loggedTime =
        DateFormat("hh:mm:ss aa").format(format.parse(time ?? now));
    if (userBloc.signOnStatus == SignOnStatus.SignOn &&
        POSConfig().dualScreenWebsite != "") {
      DualScreenController().setLandingScreen();
    }

    return StreamBuilder<UserHed>(
        stream: userBloc.currentUserStream,
        builder: (context, AsyncSnapshot<UserHed> snapshot) {
          final userHed = snapshot.data;
          final isLogged = userHed?.uSERHEDISSIGNEDON == true ||
              userHed?.uSERHEDISTEMPSIGNON == true;
          final isLoggedOff = userHed?.uSERHEDISSIGNEDOFF == true;
          final isManagerSignOff = userHed?.uSERHEDISMANAGERSIGNEDOFF == true;
          final isActive = userHed?.uSERHEDACTIVEUSER == true;
          final String strEodDate =
              POSConfig().setup?.setupEndDate?.toIso8601String() ??
                  ''; //userHed?.sETUPENDDATE ?? "";
          bool isEod = false;

          if (strEodDate.isNotEmpty) {
            try {
              DateTime eodDate = strEodDate.parseDateTime();
              if (eodDate.isSameDate(DateTime.now())) {
                isEod = true;
              }
              if (!eodDate.isSameDate(DateTime.now().add(Duration(days: -1)))) {
                isEOD_Pending = true;
              }
            } on Exception catch (e) {
              print(e);
            }
          }

          bool activeSignOn = isActive &&
              isLoggedOff &&
              !isLogged &&
              //isManagerSignOff &&
              !isEod;
          bool activeSignOff = isActive && !isLoggedOff && isLogged;
          bool activeInvoice =
              isActive && !isLoggedOff && isLogged && isManagerSignOff;
          bool activeDayEnd = isActive && isLoggedOff && !isLogged && !isEod;
          bool activeManagerSignOff =
              isActive && isLoggedOff && !isLogged && !isManagerSignOff;
          bool activeSpotCheck = isActive && !isLoggedOff && isLogged;
          Color activeColor = POSConfig().primaryColor.toColor();
          Color deActiveColor =
              POSConfig().primaryColor.toColor().withOpacity(0.6);
          return KeyboardListener(
            focusNode: _focusNode,
            onKeyEvent: (value) async {
              if (value is KeyDownEvent) {
                if (POSConfig().localMode != true &&
                    value.logicalKey == LogicalKeyboardKey.f1) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => DashboardView()));
                }
                if (POSConfig().localMode != true &&
                    value.logicalKey == LogicalKeyboardKey.f2) {
                  if (isEOD_Pending == true) {
                    alertController.showErrorAlert(
                        "landing_eod_not_done_for_yersterday",
                        namedArgs: {
                          "date": strEodDate.parseDateTime().toString()
                        });
                    return;
                  } else {
                    await landingHelper.validateSignOn(context);
                    setState(() {});
                  }
                }
                if (POSConfig().localMode != true &&
                    !POSConfig().trainingMode &&
                    value.logicalKey == LogicalKeyboardKey.f3) {
                  landingHelper.userSignOff();
                }
                if (value.logicalKey == LogicalKeyboardKey.f4) {
                  _goToInvoice();
                }
                if (POSConfig().localMode != true &&
                    !POSConfig().trainingMode &&
                    value.logicalKey == LogicalKeyboardKey.f5) {
                  dayEnd();
                }
                if (POSConfig().localMode != true &&
                    !POSConfig().trainingMode &&
                    value.logicalKey == LogicalKeyboardKey.f6) {
                  await landingHelper.managerSignOff(
                      context, activeManagerSignOff);
                  setState(() {});
                }
                if (POSConfig().localMode != true &&
                    !POSConfig().trainingMode &&
                    value.logicalKey == LogicalKeyboardKey.f7) {
                  await landingHelper.spotCheck();
                  setState(() {});
                }
                if (value.logicalKey == LogicalKeyboardKey.escape) {
                  String routeName = ExitScreen.routeName;
                  POSLoggerController.addNewLog(
                      POSLogger(POSLoggerLevel.info, "Navigate to $routeName"));
                  Navigator.pushNamed(context, routeName);
                }
              }
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 60.w,
                  ),
                  LogoWithPoweredBy(),
                  Center(
                      child: SizedBox(
                          width: 150.h, height: 150.h, child: UserImage())),
                  SizedBox(
                    height: 20.h,
                  ),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(style: CurrentTheme.headline6, children: [
                        TextSpan(
                          text: "landing_view.welcome".tr(),
                        ),
                        TextSpan(
                            text: loggedUser,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                  SizedBox(
                    height: 3.h,
                  ),
                  Center(
                    child: Text(
                      "landing_view.last_access".tr(
                          namedArgs: {"date": loggedDate, "time": loggedTime}),
                      style: CurrentTheme.headline6,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: 3.h,
                  ),
                  Center(
                    child: Text(
                      "${POSConfig().comName}",
                      style: CurrentTheme.headline6,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: 3.h,
                  ),
                  Center(
                    child: Text(
                      "${POSConfig().setupLocationName}- ${POSConfig().terminalId}",
                      style: CurrentTheme.headline6,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      landingButton(
                          child: ElevatedButton(
                        child: Text(
                          "dashboard_view.dashboard".tr(),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        onPressed: POSConfig().localMode == true
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DashboardView())),
                      )),
                      landingButton(
                          child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                activeSignOn ? activeColor : deActiveColor),
                        child: Text(
                          "landing_view.sign_on".tr(),
                          textAlign: TextAlign.center,
                        ),
                        onPressed: (POSConfig().localMode == true ||
                                POSConfig().trainingMode)
                            ? null
                            : () async {
                                if (isEOD_Pending == true) {
                                  alertController.showErrorAlert(
                                      "landing_eod_not_done_for_yersterday",
                                      namedArgs: {
                                        "date": strEodDate
                                            .parseDateTime()
                                            .toString()
                                      });
                                  return;
                                } else
                                  await landingHelper.validateSignOn(context);
                                setState(() {});
                              },
                      )),
                      landingButton(
                        child: ElevatedButton(
                          child: Text(
                            "landing_view.sign_off".tr(),
                            textAlign: TextAlign.center,
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  activeSignOff ? activeColor : deActiveColor),
                          onPressed: (POSConfig().localMode == true ||
                                  POSConfig().trainingMode)
                              ? null
                              : () {
                                  landingHelper.userSignOff();
                                },
                        ),
                      ),
                      landingButton(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  activeInvoice ? activeColor : deActiveColor),
                          child: Text(
                            "landing_view.invoice".tr(),
                            textAlign: TextAlign.center,
                          ),
                          onPressed: () {
                            _goToInvoice();
                            // if (isEOD_Pending == true) {
                            //   alertController.showErrorAlert(
                            //       "landing_eod_not_done_for_yersterday",
                            //       namedArgs: {
                            //         "date": DateFormat('dd/MM/yyyy')
                            //             .format(DateTime.parse(strEodDate))
                            //       });

                            //   return;
                            // } else
                            //   landingHelper.invoiceScreen();
                          },
                        ),
                      ),
                      landingButton(
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    activeDayEnd ? activeColor : deActiveColor),
                            child: Text(
                              "landing_view.day_end".tr(),
                              textAlign: TextAlign.center,
                            ),
                            onPressed: (POSConfig().localMode == true ||
                                    POSConfig().trainingMode)
                                ? null
                                : dayEnd),
                      ),
                      landingButton(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: activeManagerSignOff
                                  ? activeColor
                                  : deActiveColor),
                          child: Text(
                            "landing_view.manager_sign_off".tr(),
                            textAlign: TextAlign.center,
                          ),
                          onPressed: (POSConfig().localMode == true ||
                                  POSConfig().trainingMode)
                              ? null
                              : () async {
                                  var x = await landingHelper.managerSignOff(
                                      context, activeManagerSignOff);
                                  setState(() {});
                                },
                        ),
                      ),
                      landingButton(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: activeSpotCheck
                                  ? activeColor
                                  : deActiveColor),
                          child: Text(
                            "landing_view.spot_check".tr(),
                            textAlign: TextAlign.center,
                          ),
                          onPressed: (POSConfig().localMode == true ||
                                  POSConfig().trainingMode)
                              ? null
                              : () async {
                                  await landingHelper.spotCheck();
                                  setState(() {});
                                },
                        ),
                      ),
                      landingButton(
                        child: ElevatedButton(
                          child: Text(
                            "landing_view.turn_off".tr(),
                            textAlign: TextAlign.center,
                          ),
                          onPressed: () {
                            String routeName = ExitScreen.routeName;
                            POSLoggerController.addNewLog(POSLogger(
                                POSLoggerLevel.info, "Navigate to $routeName"));
                            Navigator.pushNamed(context, routeName);
                          },
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<POSConnectivityStatus>(
                    stream: posConnectivity.connectivityStream.stream,
                    builder: (BuildContext context,
                        AsyncSnapshot<POSConnectivityStatus> snapshot) {
                      String text = "";
                      TextStyle style = TextStyle();
                      switch (snapshot.data) {
                        case POSConnectivityStatus.Local:
                          text = "Local";
                          style = TextStyle(color: Colors.yellowAccent);
                          break;
                        case POSConnectivityStatus.Server:
                          text = "Server";
                          style = TextStyle(color: Colors.greenAccent);
                          break;
                        case POSConnectivityStatus.None:
                          text = "None";
                          style = TextStyle(color: Colors.redAccent);
                          break;
                        default:
                          text = "N/A";
                          style = TextStyle(color: Colors.redAccent);
                      }

                      return GestureDetector(
                        onTap: () => _checkServerStatus(context),
                        child: Text(
                          "Connection Mode: $text",
                          style: CurrentTheme.headline6!.copyWith(
                              fontWeight: FontWeight.normal,
                              color: style.color),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future _goToInvoice() async {
    //validate the system end date
    if (!POSConfig().bypassEodValidation) {
      DateTime eodDate = POSConfig().setup?.setupEndDate ?? DateTime.now();
      int validationDuration = POSConfig().setup?.eodValidationDuration ?? -1;
      if (validationDuration <= 0) {
        POSConfig().bypassEodValidation = true;
      } else {
        if (DateTime.now()
            .isAfter(eodDate.add(Duration(hours: validationDuration)))) {
          final bool? canByPassEod = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'invoice.eod_exceed_title'.tr(),
                  textAlign: TextAlign.center,
                ),
                content: Text('invoice.eod_exceed_content'.tr()),
                actions: [
                  AlertDialogButton(
                      onPressed: () async {
                        String user =
                            userBloc.currentUser?.uSERHEDUSERCODE ?? "";
                        String refCode =
                            '${POSConfig().locCode}-${POSConfig().terminalId}-@$user';
                        bool hasPermission = false;
                        hasPermission =
                            SpecialPermissionHandler(context: context)
                                .hasPermission(
                                    permissionCode:
                                        PermissionCode.byPassEodTimeframe,
                                    accessType: "A",
                                    refCode: refCode);

                        //if user doesnt have the permission
                        if (!hasPermission) {
                          final res =
                              await SpecialPermissionHandler(context: context)
                                  .askForPermission(
                                      permissionCode:
                                          PermissionCode.byPassEodTimeframe,
                                      accessType: "A",
                                      refCode: refCode);
                          hasPermission = res.success;
                          user = res.user;
                        }
                        if (hasPermission) {
                          POSConfig().bypassEodValidation = true;
                          Navigator.pop(context, true);
                        } else {
                          Navigator.pop(context, false);
                        }
                      },
                      text: 'invoice.eod_exceed_yes'.tr()),
                  AlertDialogButton(
                      onPressed: () => Navigator.pop(context, false),
                      text: 'invoice.eod_exceed_no'.tr()),
                ],
              );
            },
          );
          if (canByPassEod != true) {
            return;
          }
        }
      }
    }
    landingHelper.invoiceScreen();
  }

  Future<void> _checkServerStatus(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: ServiceStatusView(),
        );
      },
    );
  }

  Widget landingButton({required Widget child}) {
    return Theme(
      data: (CurrentTheme.themeData)!.copyWith(
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  backgroundColor: CurrentTheme.primaryColor,
                  textStyle: TextStyle(fontSize: 18.5 * getFontSize()),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          POSConfig().rounderBorderRadius2))))),
      child: Container(
        height: 60.h,
        margin: EdgeInsets.symmetric(vertical: 5),
        width: getLandingButtonSize(),
        child: child,
      ),
    );
  }

  Future<void> dayEnd() async {
    _eodFocusNode.requestFocus();
    _eodDateTime = DateTime.now();
    DateTime? date = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => POSWarningAlert(
              title: "eod_confirmation.title".tr(),
              subtitle: "eod_confirmation.subtitle".tr(namedArgs: {
                "date": DateFormat("MMM dd, yyyy")
                    .format(_eodDateTime ?? DateTime.now())
              }),
              actions: [
                KeyboardListener(
                  focusNode: _eodFocusNode,
                  autofocus: true,
                  onKeyEvent: (value) {
                    if (value is KeyDownEvent) {
                      if (value.physicalKey == PhysicalKeyboardKey.keyY) {
                        Navigator.pop(context, _eodDateTime);
                      }
                    }
                  },
                  child: AlertDialogButton(
                      onPressed: () async {
                        Navigator.pop(context, _eodDateTime);
                      },
                      text: "eod_confirmation.yes".tr()),
                ),
                KeyboardListener(
                  focusNode: _eodFocusNode,
                  autofocus: true,
                  onKeyEvent: (value) async {
                    if (value is KeyDownEvent) {
                      if (value.physicalKey == PhysicalKeyboardKey.keyP) {
                        print(POSConfig().setup?.serverTime);
                        print(POSConfig().setup?.setupEndDate);
                        print('+++++++++++++++++++++++++++++');
                        DateTime today = DateFormat('yyyy-MM-dd').parse(
                            (POSConfig().setup?.serverTime ?? DateTime.now())
                                .add(Duration(days: -1))
                                .toIso8601String());
                        DateTime? date = await showRoundedDatePicker(
                            context: context,
                            initialDate: today,
                            firstDate: (POSConfig()
                                    .setup
                                    ?.setupEndDate
                                    ?.add(Duration(days: 1)) ??
                                DateTime.now()),
                            lastDate: today);
                        _eodDateTime = DateFormat('yyyy-MM-dd')
                            .parse(date?.toIso8601String() ?? '');
                        setState(() {});
                      }
                    }
                  },
                  child: AlertDialogButton(
                      onPressed: () async {
                        print(POSConfig().setup?.serverTime);
                        print(POSConfig().setup?.setupEndDate);
                        print('+++++++++++++++++++++++++++++');
                        DateTime today = DateFormat('yyyy-MM-dd').parse(
                            (POSConfig().setup?.serverTime ?? DateTime.now())
                                .add(Duration(days: -1))
                                .toIso8601String());
                        DateTime? date = await showRoundedDatePicker(
                            context: context,
                            initialDate: today,
                            firstDate: (POSConfig()
                                    .setup
                                    ?.setupEndDate
                                    ?.add(Duration(days: 1)) ??
                                DateTime.now()),
                            lastDate: today);
                        _eodDateTime = DateFormat('yyyy-MM-dd')
                            .parse(date?.toIso8601String() ?? '');
                        setState(() {});
                      },
                      text: "eod_confirmation.pick".tr()),
                ),
                KeyboardListener(
                  focusNode: _eodFocusNode,
                  autofocus: true,
                  onKeyEvent: (value) {
                    if (value is KeyDownEvent) {
                      if (value.physicalKey == PhysicalKeyboardKey.keyN) {
                        Navigator.pop(context, null);
                      }
                    }
                  },
                  child: AlertDialogButton(
                      onPressed: () {
                        Navigator.pop(context, null);
                      },
                      text: "eod_confirmation.no".tr()),
                ),
              ]),
        );
      },
    );
    if (date != null) {
      landingHelper.dayEnd(date);
    }
  }
}
