/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 5/6/21, 4:33 PM
 */

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/audit_log_controller.dart';
import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:checkout/controllers/eod_controller.dart';
import 'package:checkout/controllers/payment_mode_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_alerts/pos_lottie_alert.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/controllers/pos_manual_print_controller.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/controllers/time_controller.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/main.dart';
import 'package:checkout/models/enum/signon_status.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos/pos_denomination_model.dart';
import 'package:checkout/models/pos/user_hed.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/invoice/cart.dart';
import 'package:checkout/views/landing/landing_alert_controller.dart';
import 'package:checkout/views/shift_reconciliation/shift_reconciliation_entering_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supercharged/supercharged.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'open_float_view.dart';

class LandingHelper {
  final BuildContext _context;
  final AuthController _authController;
  final LandingAlertController _alertController;
  FocusNode alertFocusNode = FocusNode();
  ScrollController scrollController = ScrollController();

  LandingHelper(this._context, this._authController, this._alertController);

  //return false for inactive user
  bool inactiveUserAlert() {
    bool res = _authController.checkUserActiveStatus();
    if (!res) _alertController.showLockAlert("inactive_user_alert", true);
    return res;
  }

  // check user already signed on or not this function will return the terminal id
  String? alreadySignedOnToTerminal() {
    String? stationId = _authController.checkUserAlreadySignedOn();
    if (stationId != null) {
      if (stationId == POSConfig().terminalId)
        _alertController.showErrorAlert("already_sign_in");
      else
        _alertController.showErrorAlert("already_sign_in_another_terminal",
            namedArgs: {"terminalId": stationId});
    }
    return stationId;
  }

  bool sameTerminalSignedOn() {
    String? stationId = _authController.checkUserAlreadySignedOn();
    return stationId == POSConfig().terminalId;
  }

  bool backOfficeSignOff() {
    bool res = _authController.checkManagerSignOff();
    if (!res)
      _alertController.showErrorAlert(
        "manager_sign_off_required",
      );

    return res;
  }

  bool checkSignOff() {
    bool res = _authController.checkSignOff();
    if (!res)
      _alertController.showErrorAlert(
        "not_signed_off",
      );

    return res;
  }

  //return the true if the date is a before date
  Future<bool> validateTheEndDate() async {
    DateTime now = await TimeController().getCurrentServerTime();
    final endDateString = POSConfig().setup?.setupEndDate?.toIso8601String() ??
        userBloc.currentUser?.sETUPENDDATE;
    final format = DateFormat("yyyy-MM-dd");
    if (endDateString != null) {
      final endDate = format.parse(endDateString);
      if (endDate.isAfter(now)) {
        _alertController.showErrorAlert("day_end_error", namedArgs: {
          "date": format.format(endDate),
          "today": format.format(now)
        });
      }
      return endDate.isBefore(now);
    } else {
      return false;
    }
  }

  FocusNode errorFocusNode = new FocusNode();
  Future validateSignOn(BuildContext context) async {
    // this is necessary, because if the cashier do signoff,mng signoff and remain in the landing page, he can be able to signon and increase the shift number
    // without validating whether the current user, signon to the different terminal with different shift.
    await _authController
        .checkUsername(userBloc.currentUser?.uSERHEDUSERCODE ?? "");

    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "${userBloc.signOnStatus}"));

    if (userBloc.signOnStatus == SignOnStatus.TempSignOn) return;

    bool active = inactiveUserAlert();
    // if the user is active just do the other sign on process
    if (active) {
      //  check for the terminal sign on process
      String? terminalId = alreadySignedOnToTerminal();
      if (terminalId != null) {
        await showDialog(
            context: context,
            builder: (context) => POSErrorAlert(
                    title: "Shift Ongoing Alert",
                    subtitle:
                        "The logged user: (${userBloc.currentUser?.uSERHEDUSERCODE}) is currently doing a shift on terminal $terminalId \nSo, login again with new cashier Id",
                    actions: [
                      KeyboardListener(
                        focusNode: errorFocusNode,
                        autofocus: true,
                        onKeyEvent: (value) {
                          if (value is KeyDownEvent) {
                            if (value.physicalKey ==
                                    PhysicalKeyboardKey.enter ||
                                value.physicalKey == PhysicalKeyboardKey.keyO) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: AlertDialogButton(
                            onPressed: () => Navigator.pop(context),
                            text: "Okay"),
                      )
                    ])).then((value) {
          RestartWidget.restartApp(_context);
          return;
        });
      }
      //   check  sign off is completed or not
      bool iSignedOff = checkSignOff();
      if (!iSignedOff) return;

      //   check manager sign off is completed or not
      bool isBackofficeSignedOff = backOfficeSignOff();
      if (!isBackofficeSignedOff) return;

      bool endDate = await validateTheEndDate();
      if (!endDate) {
        _alertController.showErrorAlert("landing_eod_already_done_for_today");
        return;
      }

      //get the current user title
      if (await getTheCurrentUser()) return;
      _authController.getUserPermission();
      await _authController
          .checkUsername(userBloc.currentUser?.uSERHEDUSERCODE ?? "");

      // this is for opening the cash drawer for do denomination calculations
      if (POSConfig.crystalPath != '') {
        PrintController()
            .printHandler("", PrintController().openDrawer(), context);
      } else {
        POSManualPrint().openDrawer();
      }

      // sir ask me to remove asking permission for drawer open here
      // SpecialPermissionHandler handler =
      //     SpecialPermissionHandler(context: context!);
      // String code = PermissionCode.openCashDrawer;
      // String type = "A";
      // String refCode = "Drawer open";
      // bool permissionStatus = handler.hasPermission(
      //     permissionCode: code, accessType: type, refCode: refCode);
      // if (!permissionStatus) {
      //   bool success = (await handler.askForPermission(
      //           accessType: type, permissionCode: code, refCode: refCode))
      //       .success;
      //   // if (!success) return;
      //   if (success) {
      //     if (POSConfig.crystalPath != '') {
      //       PrintController()
      //           .printHandler("", PrintController().openDrawer(), context);
      //     } else {
      //       POSManualPrint().openDrawer();
      //     }
      //   } else {
      //     EasyLoading.showError(
      //         'You don\'t have permission for opening the cash drawer');
      //   }
      // } else {
      //   if (POSConfig.crystalPath != '') {
      //     PrintController()
      //         .printHandler("", PrintController().openDrawer(), context);
      //   } else {
      //     POSManualPrint().openDrawer();
      //   }
      // }

      // do the sign on
      String routeName = OpenFloatScreen.routeName;
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.info, "Navigate to $routeName"));
      Navigator.pushNamed(_context, routeName);
    }
  }

  //return true if the user has sign off permission
  bool signOffPermission() {
    bool res = (userBloc.userDetails?.userRights
                ?.indexWhere((element) => element.menuTag == "P00002") ??
            -1) !=
        -1;
    if (!res)
      _alertController.showErrorAlert(
        "permission_error",
      );

    return res;
  }

  // This alert will show if the user is not signed in
  void notSignedOnAlert() {
    _alertController.showLockAlert("not_sign_in", true);
  }

  userSignOff() async {
    //doing a invoice sync before we do sign-off
    EasyLoading.show(status: 'please_wait'.tr(), dismissOnTap: true);
    var result = await InvoiceController().uploadBillData();
    if (result != null) {
      EasyLoading.dismiss();
      EasyLoading.showToast(result['message']);
    }

    alertFocusNode.requestFocus();
    showDialog(
        context: _context,
        builder: (context) => POSFlareAlert(
            title: "sign_off_popup.title".tr(),
            subtitle: "",
            actions: [
              KeyboardListener(
                focusNode: alertFocusNode,
                autofocus: true,
                onKeyEvent: (event) {
                  if (event is KeyDownEvent) {
                    if (event.physicalKey == PhysicalKeyboardKey.keyY) {
                      Navigator.pop(context);
                      validateSignOff();
                    }
                  }
                },
                child: AlertDialogButton(
                    onPressed: () {
                      Navigator.pop(context);
                      validateSignOff();
                    },
                    text: "sign_off_popup.yes".tr()),
              ),
              KeyboardListener(
                focusNode: alertFocusNode,
                autofocus: true,
                onKeyEvent: (event) {
                  if (event is KeyDownEvent) {
                    if (event.physicalKey == PhysicalKeyboardKey.keyN) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: AlertDialogButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    text: "sign_off_popup.no".tr()),
              ),
            ],
            flarePath: "assets/flare/sign_out.flr",
            flareAnimation: "go")

        //
        //     AlertDialog(
        //   title: Text(
        //     "sign_off_popup.title".tr(),
        //     textAlign: TextAlign.center,
        //   ),
        //   content: Container(
        //     height: 150.w,
        //     child: FlareActor(
        //       "assets/flare/sign_out.flr",
        //       animation: "go",
        //     ),
        //   ),
        //   actions: [
        //
        //     ElevatedButton(
        //         style: ElevatedButton.styleFrom(
        //             primary: POSConfig().primaryDarkGrayColor.toColor()),
        //         onPressed: () {
        //           Navigator.pop(context);
        //           validateSignOff();
        //         },
        //         child: Text("sign_off_popup.yes".tr())),
        //     ElevatedButton(
        //         style: ElevatedButton.styleFrom(
        //             primary: POSConfig().primaryDarkGrayColor.toColor()),
        //         onPressed: () => Navigator.pop(context),
        //         child: Text("sign_off_popup.no".tr()))
        //   ],
        // ),
        );
  }

  // sign off process
  void validateSignOff() async {
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "${userBloc.signOnStatus}"));

    if (userBloc.signOnStatus == SignOnStatus.None) {
      notSignedOnAlert();
      return;
    }

    bool active = inactiveUserAlert();
    // if the user is active just do the other sign on process
    if (active) {
      //check permission
      bool perm = signOffPermission();
      if (!perm) return;

      //   check manager sign off is completed or not
      bool isBackofficeSignedOff = backOfficeSignOff();
      if (!isBackofficeSignedOff) return;

      bool endDate = await validateTheEndDate();
      if (!endDate) return;

      // check ongoing order
      bool tempInvoice = await InvoiceController().hasTempInvoice();
      bool holdInvoice =
          (await InvoiceController().getHoldHeaders(isSignOffCheck: 1)).length >
              0;
      final bool byPassHoldInv = SpecialPermissionHandler(context: _context)
          .hasPermission(
              permissionCode: PermissionCode.bypassHoldInvAtSignOff,
              accessType: 'A');

      if (holdInvoice && byPassHoldInv) {
        holdInvoice = false;
      }

      if (tempInvoice || holdInvoice) {
        holdInvoiceAlert();
        return;
      }

      // do the sign off
      if (!_authController.checkSignOff() &&
          _authController.checkUserAlreadySignedOn() ==
              POSConfig().terminalId) {
        POSLoggerController.addNewLog(
            POSLogger(POSLoggerLevel.info, "Start the sign off process"));
        EasyLoading.show(status: 'please_wait'.tr());
        await _authController.signOff();
        customerBloc.changeCurrentCustomer(null);
        final user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
        await _authController.checkUsername(user);
        if (POSConfig().dualScreenWebsite != "")
          DualScreenController().setView('closed');

        if (POSConfig.crystalPath != '') {
          await PrintController().signOffSlip();
        } else {
          await POSManualPrint().printSignSlip(data: '', slipType: 'signoff');
        }

        // userBloc.clear();
        EasyLoading.dismiss();
        cartBloc.resetCart();
        userBloc.changeSignOnStatus(SignOnStatus.None);
        if (userBloc.signOnStatus == SignOnStatus.None) {
          await _authController.checkUsername(user);
          await showDialog(
              context: _context,
              builder: (context) => POSFLottieAlert(
                    title: "sign_off_complete_popup.title".tr(),
                    subtitle: "",
                    actions: [
                      KeyboardListener(
                        focusNode: FocusNode(),
                        autofocus: true,
                        onKeyEvent: (value) {
                          if (value is KeyDownEvent) {
                            if (value.physicalKey ==
                                    PhysicalKeyboardKey.enter ||
                                value.physicalKey == PhysicalKeyboardKey.keyO) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: AlertDialogButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            text: "sign_off_complete_popup.okay".tr()),
                      ),
                    ],
                    lottiePath: "assets/lottie/success.json",
                  ));
        }
      }
    }
  }

  void holdInvoiceAlert() {
    _alertController.showErrorAlert("sign_off_with_hold_invoice");
  }

  //return the true if there is a user title available
  Future<bool> getTheCurrentUser() async {
    EasyLoading.show(status: 'please_wait'.tr());
    final res = await _authController.getCurrentUserTitle();
    EasyLoading.dismiss();
    final title = userBloc.currentUser?.uSERHEDUSERCODE;
    if (res != title && res != null) {
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
          "Ask for the temp sign on: $title, Current User: $res"));

      showDialog(
        context: _context,
        builder: (context) => POSFlareAlert(
            title: "temp_sign_on_alert.title".tr(namedArgs: {"user": res}),
            subtitle: "temp_sign_on_alert.subtitle".tr(),
            actions: [
              AlertDialogButton(
                  onPressed: () => doTempSignOn(res),
                  text: "temp_sign_on_alert.yes".tr()),
              AlertDialogButton(
                  onPressed: () => Navigator.pop(context),
                  text: "temp_sign_on_alert.no".tr()),
            ],
            flarePath: "assets/flare/locker.flr",
            flareAnimation: "lock"),
      );
    }
    return res != null;
  }

  // temp sign on process
  Future doTempSignOn(String cashier) async {
    //check the user permission
    bool hasPermission = false;

    // fetch permission list
    final userCode = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
    final permissionList =
        await AuthController().getUserPermissionListByUserCode(userCode);

    hasPermission = SpecialPermissionHandler(context: _context)
        .hasPermissionInList(permissionList?.userRights ?? [],
            PermissionCode.temporarySignOn, "A", userCode);

    //if user doesnt have the permission
    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: _context)
          .askForPermission(
              permissionCode: PermissionCode.temporarySignOn,
              accessType: "A",
              refCode: DateTime.now().toIso8601String());
      hasPermission = res.success;
    }

    // still havent permission
    if (!hasPermission) {
      return;
    }

    final res = await _authController.tempSignOn();
    userBloc.saveCashierCodeForTemp(cashier);
    Navigator.pop(_context);
    if (res != null)
      showDialog(
        context: _context,
        builder: (context) => POSErrorAlert(
          title: res,
          subtitle: "",
          actions: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        POSConfig().primaryDarkGrayColor.toColor()),
                onPressed: () => Navigator.pop(context),
                child: Text("day_end_error.okay".tr())),
          ],
        ),
      );
    else {
      EasyLoading.show(status: 'please_wait'.tr());
      // getting the user permission
      await _authController.getUserPermission();
      // get the latest user hed details
      await _authController
          .checkUsername(userBloc.currentUser?.uSERHEDUSERCODE ?? "");
      EasyLoading.dismiss();
      userBloc.changeSignOnStatus(SignOnStatus.TempSignOn);
    }
  }

//  navigation to invoice screen
  Future invoiceScreen() async {
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "${userBloc.signOnStatus}"));

    if (userBloc.signOnStatus == SignOnStatus.None) {
      notSignedOnAlert();
      return;
    }
    bool active = inactiveUserAlert();
    if (!active) return;

    //  check for permission
    int permission = userBloc.userDetails?.userRights
            ?.indexWhere((element) => element.menuTag == "P00101") ??
        -1;
    if (permission == -1) {
      _alertController.showLockAlert("permission_error", true);
      return;
    }

    //validate terminal
    if (!sameTerminalSignedOn() &&
        userBloc.signOnStatus == SignOnStatus.SignOn) {
      notSignedOnAlert();
      return;
    }

    bool endDate = await validateTheEndDate();
    if (!endDate) return;
    EasyLoading.show(status: 'please_wait'.tr());
    String invoice = "";
    await AuditLogController().updateInvoiceScreenAuditLog();
    if (await InvoiceController().loadCartFromTempTable()) {
      invoice = cartBloc.cartSummary?.invoiceNo ?? '';
    }
    if (invoice.isEmpty) {
      //get invoice no if the temp cart table is empty
      invoice = await InvoiceController().getInvoiceNo();
      print("++++++++++++++++++++s");
      print(invoice);
      cartBloc.updateCartSummary(CartSummaryModel(
          invoiceNo: invoice,
          items: 0,
          startTime: '',
          qty: 0,
          subTotal: 0,
          priceMode: ''));
    }
    EasyLoading.dismiss();
    if (invoice.isEmpty) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Cannot generate a new invoice number"));
      return;
    }
    if (invoice.substring(0, 6) !=
            POSConfig().comCode.getLastNChar(2) +
                POSConfig().locCode.getLastNChar(2) +
                POSConfig().terminalId.getLastNChar(2) ||
        invoice.length != 12) {
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.error,
          "Invalid invoice number. Please adjust the invoice number."));

      await showDialog(
          context: _context,
          builder: (context) => POSErrorAlert(
                title: "landing_invalid_invoice_no.title".tr(),
                subtitle: "landing_invalid_invoice_no.subtitle".tr() +
                    "\nCurrent Invoice No: " +
                    invoice,
                actions: [
                  AlertDialogButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      text: "landing_invalid_invoice_no.okay".tr()),
                ],
              ));
      return;
    }

    final route = Cart.routeName;
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Navigate to $route"));
    Navigator.pushNamed(_context, route);
  }

//  load denominations
  Future dayEnd(DateTime date) async {
    // if (userBloc.signOnStatus == SignOnStatus.None) {
    //   notSignedOnAlert();
    //   return;
    // }

    bool hasPermission = false;

    // fetch permission list
    final userCode = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
    EasyLoading.show(status: 'please_wait'.tr());
    final permissionList =
        await AuthController().getUserPermissionListByUserCode(userCode);

    hasPermission = SpecialPermissionHandler(context: _context)
        .hasPermissionInList(permissionList?.userRights ?? [],
            PermissionCode.eod, "A", userCode);
    EasyLoading.dismiss();
    //if user doesnt have the permission
    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: _context)
          .askForPermission(
              permissionCode: PermissionCode.eod,
              accessType: "A",
              refCode: DateTime.now().toIso8601String());
      hasPermission = res.success;
    }

    // still havent permission
    if (!hasPermission) {
      return;
    }

    //eod validation
    final eodValidation = await EodController().validateEodProcess(date);
    if (eodValidation == null) {
      _alertController.showErrorAlert("eod_alert_unknown");
      return;
    }
    bool doEod = eodValidation.success == true;
    if (eodValidation.success == false) {
      switch (eodValidation.message) {
        case "sign_on":
          _alertController.showErrorAlert("eod_alert_sign_on", namedArgs: {
            "users": eodValidation.users
                    ?.map((e) => e.userheDTITLE)
                    .toList()
                    .join(", ") ??
                ""
          });
          break;
        case "invoice":
          if (!SpecialPermissionHandler(context: _context).hasPermission(
              permissionCode: PermissionCode.bypassHoldInvAtSignOff,
              accessType: 'A')) {
            _alertController.showErrorAlert("eod_alert_hold_invoice");
          } else {
            doEod = true;
          }
          break;
        default:
          _alertController.showErrorAlert("eod_alert_already_done",
              namedArgs: {"day": eodValidation.message ?? ""});
      }
    }
    if (doEod) {
      var res = await EodController().doEOD(date);
      await _authController
          .checkUsername(userBloc.currentUser?.uSERHEDUSERCODE ?? "");
      if (res == true)
        RestartWidget.restartApp(
            _context); // restarting the app after success of eod....this may cause error (unstability of widget tree issue)
    }
  }

  // manager sign off function
  Future managerSignOff(
      BuildContext context, bool isCurrentTerminalSignedoff) async {
    //new change
    /* 
    * Author: TM.Sakir
    * Created: 2023-09-21
    * Reason:  showing pending managersignoff terminals and sign-off them
    */
//----------------------------------------------------------------------//
    var size = MediaQuery.of(context).size;
    var list = await _authController.getPendingManagerSignOff();

    //getting a map from new pending manager signoff window
    Map<String, dynamic>? _continue = await pendingSignOffDialog(
        context, list, size, isCurrentTerminalSignedoff);

    if (_continue != null && _continue.isNotEmpty) {
//----------------------------------------------------------------------//
      //validation process
      await AuthController()
          .checkUsername(userBloc.currentUser?.uSERHEDUSERCODE ?? "");

      //I create a new bloc for selected pending user and add the selected user in order to continue the manager sign off for that particular user
      if (_continue['type'] == 'pending_user') {
        userBloc.changePendingUser(list![_continue['selected_index']]);
      }

      // bool signOffRes = (_continue['type'] == 'current_user')
      //     ? checkSignOff()
      //     : list![_continue['selected_index']].uSERHEDISSIGNEDOFF!;

      // if (signOffRes) {
      //   bool res = (_continue['type'] == 'current_user')
      //       ? _authController.checkManagerSignOff()
      //       : list![_continue['selected_index']].uSERHEDISMANAGERSIGNEDOFF!;

      if (/* !res */ true) {
        EasyLoading.show(status: 'please_wait'.tr());
        final list = await PaymentModeController().getDenominationList();
        EasyLoading.dismiss();
        final route = ShiftReconciliationEntryView.routeName;
        POSLoggerController.addNewLog(
            POSLogger(POSLoggerLevel.info, "Navigate to $route"));

        // going through the  denominations
        List<POSDenominationModel> temp = [];
        list.forEach((element) {
          var val = POSDenominationModel(element.code ?? "",
              element.detailCode ?? "", element.description ?? "", 0);
          val.denominations = [];

          element.denominations?.forEach((den) {
            val.denominations.add(POSDenominationDetail(element.code ?? "",
                den.deNCODE ?? "", 0, den.deNDENVALUE ?? 0));
          });

          temp.add(val);
        });

        // this is for opening the cash drawer for do denomination calculations
        SpecialPermissionHandler handler =
            SpecialPermissionHandler(context: context);
        String code = PermissionCode.openCashDrawer;
        String type = "A";
        String refCode = "Drawer open";
        bool permissionStatus = handler.hasPermission(
            permissionCode: code, accessType: type, refCode: refCode);
        if (!permissionStatus) {
          bool success = (await handler.askForPermission(
                  accessType: type, permissionCode: code, refCode: refCode))
              .success;
          // if (!success) return;
          if (success) {
            if (POSConfig.crystalPath != '') {
              PrintController()
                  .printHandler("", PrintController().openDrawer(), context);
            } else {
              POSManualPrint().openDrawer();
            }
          } else {
            EasyLoading.showError(
                'You don\'t have permission for opening the cash drawer');
          }
        } else {
          if (POSConfig.crystalPath != '') {
            PrintController()
                .printHandler("", PrintController().openDrawer(), context);
          } else {
            POSManualPrint().openDrawer();
          }
        }

        await Navigator.push(
            _context,
            MaterialPageRoute(
              builder: (context) => ShiftReconciliationEntryView(
                pendingSignoff: (_continue['type'] == 'pending_user')
                    ? true
                    : false, //new change -- passing a flag to identify the current_user of pending_user(get from pending sign off dialog window)
                denominationsList: temp,
              ),
            ));
      }
      // }
    }
  }

  Future<Map<String, dynamic>?> pendingSignOffDialog(BuildContext context,
      List<UserHed>? list, Size size, bool isCurrentTerminalSignedoff) {
    int len = list?.length ?? 0;
    return showGeneralDialog(
      context: context,
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          Transform.scale(
              scale: animation.value,
              child: Padding(
                padding: EdgeInsets.fromLTRB(size.width * 0.1,
                    size.height * 0.18, size.width * 0.1, size.height * 0.18),
                child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    color: Theme.of(context).primaryColor,
                    elevation: 5,
                    shadowColor: Theme.of(context).primaryColor,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: 20.0, left: 20, right: 40, bottom: 0),
                      child: Center(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                'landing_view.pending_signoff'.tr(),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 30),
                              ),
                            ),
                            Divider(),
                            Column(
                              children: [
                                Container(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'User ID',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: size.height / 30),
                                        ),
                                        flex: 2,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Name',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: size.height / 30),
                                        ),
                                        flex: 2,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Station',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: size.height / 30),
                                        ),
                                        flex: 2,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Sign-On \nDate',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: size.height / 35),
                                        ),
                                        flex: 2,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Sign-Off \nDate',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: size.height / 35),
                                        ),
                                        flex: 2,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Shift',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: size.height / 30),
                                        ),
                                        flex: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: size.height / 30,
                                )
                              ],
                            ),
                            Scrollbar(
                              controller: scrollController,
                              thumbVisibility: true,
                              thickness: 25,
                              child: Container(
                                height: size.height * 0.3,
                                child: (list != null && len > 0)
                                    ? ListView.builder(
                                        physics: BouncingScrollPhysics(),
                                        controller: scrollController,
                                        itemCount: len,
                                        itemBuilder: (context, index) {
                                          return InkWell(
                                            onTap: (() {
                                              Navigator.pop(context, {
                                                'type': 'pending_user',
                                                'selected_index': index
                                              });
                                            }),
                                            child: Container(
                                              height: (size.height * 0.3) / 4,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                        list[index]
                                                                .uSERHEDUSERCODE ??
                                                            '--',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontSize: 20)),
                                                    flex: 2,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                        list[index]
                                                                .uSERHEDTITLE ??
                                                            '--',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontSize: 20)),
                                                    flex: 2,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      list[index]
                                                              .uSERHEDSTATIONID ??
                                                          '--',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 20),
                                                    ),
                                                    flex: 2,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                        (list[index].uSERHEDSIGNONDATE ??
                                                                '-- 00:00:00')
                                                            .replaceAll(
                                                                " 00:00:00",
                                                                ""),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontSize: 20)),
                                                    flex: 2,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                        list[index]
                                                                .uSERHEDSIGNOFFDATE ??
                                                            '--',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontSize: 20)),
                                                    flex: 2,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                        list[index].shiftNo ??
                                                            '--',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            fontSize: 20)),
                                                    flex: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        })
                                    : Center(
                                        child: Text(
                                            'landing_view.no_mng_signoff'.tr()),
                                      ),
                              ),
                            ),
                            SizedBox(
                              height: size.height / 30,
                            ),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 20.h),
                                  backgroundColor: Colors.grey,
                                ),
                                onPressed: isCurrentTerminalSignedoff
                                    ? () => Navigator.pop(context, {
                                          'type': 'current_user',
                                          'selected_index': null
                                        })
                                    : null,
                                child: Text(
                                    'landing_view.current_mng_signoff'.tr()))
                          ],
                        ),
                      ),
                    )),
              )),
    );
  }

  Future spotCheck() async {
    //validation process
    await AuthController()
        .checkUsername(userBloc.currentUser?.uSERHEDUSERCODE ?? "");
    bool signOffRes = !_authController.checkSignOff();

    if (signOffRes) {
      EasyLoading.show(status: 'please_wait'.tr());
      final list = await PaymentModeController().getDenominationList();
      EasyLoading.dismiss();
      final route = ShiftReconciliationEntryView.routeName;
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.info, "Navigate to $route"));

      // going through the  denominations
      List<POSDenominationModel> temp = [];
      list.forEach((element) {
        var val = POSDenominationModel(element.code ?? "",
            element.detailCode ?? "", element.description ?? "", 0);
        val.denominations = [];

        element.denominations?.forEach((den) {
          val.denominations.add(POSDenominationDetail(
              element.code ?? "", den.deNCODE ?? "", 0, den.deNDENVALUE ?? 0));
        });

        temp.add(val);
      });

      /// permission request
      final permissionRes = await SpecialPermissionHandler(context: _context)
          .askForPermission(
              permissionCode: PermissionCode.spotCheck,
              accessType: "A",
              refCode: DateTime.now().toIso8601String());

      if (permissionRes.success) {
        await Navigator.push(
            _context,
            MaterialPageRoute(
              builder: (context) => ShiftReconciliationEntryView(
                denominationsList: temp,
                spotCheck: true,
                approvedUser: permissionRes.user,
              ),
            ));
      }
    }
  }
}
