// ignore_for_file: deprecated_member_use

/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/27/21, 1:43 PM
 */

import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/bloc/keyboard_bloc.dart';
import 'package:checkout/bloc/paymode_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/common_regex.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/ext_loyalty/ext_module_helper.dart';
import 'package:checkout/components/mypos_screen_utils.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/components/widgets/pay_button.dart';
import 'package:checkout/components/widgets/poskeyboard.dart';
import 'package:checkout/controllers/config/shared_preference_controller.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:checkout/controllers/ecr_controller.dart';
import 'package:checkout/controllers/email_controller.dart';
import 'package:checkout/controllers/gift_voucher_controller.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/loyalty_controller.dart';
import 'package:checkout/controllers/otp_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/controllers/pos_manual_print_controller.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/controllers/usb_serial_controller.dart';
import 'package:checkout/models/enum/keyboard_type.dart';
import 'package:checkout/models/last_invoice_details.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/ecr_response.dart';
import 'package:checkout/models/pos/gift_voucher_result.dart';
import 'package:checkout/models/pos/invoice_save_res.dart';
import 'package:checkout/models/pos/payment_mode.dart';
import 'package:checkout/models/pos/card_details_result.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/invoice/cart.dart';
import 'package:checkout/views/invoice/discount_breakdown.dart';
import 'package:checkout/views/invoice/payment_breakdown.dart';
import 'package:checkout/views/invoice/tax_breakdown_view.dart';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:overlay_tutorial/overlay_tutorial.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:supercharged/supercharged.dart';

import '../../bloc/customer_coupons_bloc.dart';
import '../../controllers/activation/activation_controller.dart';
import '../../controllers/sms_controller.dart';
import '../../controllers/special_permission_handler.dart';
import '../../models/loyalty/customer_coupons_result.dart';
import '../../models/pos/permission_code.dart';
import 'invoice_app_bar.dart';

class PaymentView extends StatefulWidget {
  static const routeName = "payment_view";

  @override
  _PaymentViewState createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  double height = 60;
  PayModeHeader? selectedPayModeHeader;
  PayModeDetails? selectedPayModeDetail;
  TextEditingController dueBalanceEditingController = TextEditingController();
  TextEditingController detailsEditingController = TextEditingController();
  double paid = 0;
  final focusNode = FocusNode();
  final errorNode = FocusNode();
  final balanceFocus = FocusNode();
  final detailsFocusNode = FocusNode();
  double balanceDue = 0;
  double subTotal = 0;
  double currentRate = 1;
  CardDetails? enteredCard;
  String? _textMask;
  bool _ecr = false;
  int _ecrTimeOut = 60;
  Timer? _timer;
  double spacing = 3;
  bool dontPop = false;
  bool loaded = false;
  bool billCloseClicked = false;
  double saving = 0;
  double _maximumLoyaltyAmount = 0;

  bool isFocusPayment = true;
  ExtLoyaltyModuleHelper _loyaltyModuleHelper = ExtLoyaltyModuleHelper();
  String? _otpCode;
  String? _referenceNumber;
  double _burnedPoints = 0;
  GlobalKey keyTextField = GlobalKey();
  bool _showGvTutorial = false;

  /* customer coupon variables */
  /* by dinuka 2022-08-19 */
  Coupons? selectedCoupon;

  @override
  void initState() {
    super.initState();

    viewListeners();
    double lineTotal = 0;
    double absolute = 0;
    cartBloc.currentCart?.values.forEach((element) {
      lineTotal += element.amount;
      absolute += (element.selling * element.unitQty);
    });
    final payModes = payModeBloc.payModeResult?.payModes ?? [];
    int defaultPayModeIndex =
        payModes.indexWhere((element) => element.defaultPaymentMode == true);
    if (defaultPayModeIndex != -1 && cartBloc.specificPayMode == null) {
      selectedPayModeHeader = payModes[defaultPayModeIndex];
    }
    saving = absolute - lineTotal;

    if (POSConfig().dualScreenWebsite != "")
      DualScreenController()
          .sendPayment(paid.toDouble(), subTotal.toDouble(), saving.toDouble());

    if (POSConfig().enablePollDisplay == 'true')
      usbSerial.sendToSerialDisplay(
          'TOTAL AMOUNT        ${usbSerial.addSpacesFront(lineTotal.toStringAsFixed(2), 20)}');
  }

  void _ecrTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_ecrTimeOut == 0) {
          setState(() {
            _ecr = false;
            timer.cancel();
            _ecrTimeOut = 60;
          });
        } else {
          setState(() {
            _ecrTimeOut--;
          });
        }
      },
    );
  }

  void loadPaidData() {
//Auto Round off the amount
    subTotal = cartBloc.cartSummary?.subTotal ?? 0;
    if (POSConfig().setup?.autoRoundOff ?? false == true) {
      double roundOffAmt = subTotal % (POSConfig().setup?.autoRoundoffTo ?? 0);
      if (roundOffAmt > 0) {
        roundOffAmt = double.parse(roundOffAmt.toStringAsFixed(2));
        final payModeList = payModeBloc.payModeResult?.payModes ?? [];
        int index =
            payModeList.indexWhere((element) => element.pHCODE == 'RND');
        if (index != -1) {
          final String phCode = payModeList[index].pHCODE ?? '';
          final String phdesc = payModeList[index].pHDESC ?? '';
          cartBloc.addPayment(PaidModel(roundOffAmt, subTotal, false, phCode,
              phCode, '', null, null, phdesc, phdesc));
        }
      }
    }

    final list = cartBloc.paidList ?? [];
    list.forEach((element) {
      paid += double.parse(element.paidAmount.toStringAsFixed(2) ?? '0');
    });
    subTotal = cartBloc.cartSummary?.subTotal ?? 0;
    balanceDue = double.parse((subTotal - paid).toStringAsFixed(2) ?? '0');
    if (list.length != 0) {
      loaded = true;
    }
    if (POSConfig().dualScreenWebsite != "")
      DualScreenController()
          .sendPayment(paid.toDouble(), subTotal.toDouble(), saving.toDouble());
    dueBalanceEditingController.text = balanceDue.toStringAsFixed(2);
    if (mounted) setState(() {});
  }

  bool active = false;

  void viewListeners() {
    // POSPriceCalculator().taxCalculation();
    // cartBloc.cartSummarySnapshot.listen((event) {
    // subTotal = event.subTotal;
    // if (!loaded) balanceDue = event.subTotal;
    // loaded = true;
    // if (selectedPayModeHeader?.defaultPaymentMode == true) {
    //   dueBalanceEditingController.text = balanceDue.toStringAsFixed(2);
    // }

    // if (mounted) setState(() {});
    // });
    subTotal = cartBloc.cartSummary?.subTotal ?? 0;
    if (!loaded) balanceDue = cartBloc.cartSummary?.subTotal ?? 0;
    loaded = true;
    if (selectedPayModeHeader?.defaultPaymentMode != true) {
      dueBalanceEditingController.text = balanceDue.toStringAsFixed(2);
    }

    if (mounted) setState(() {});
    loadPaidData();

    Future.delayed(
      Duration(seconds: 1),
    ).then((value) {
      setState(() {
        active = true;
      });
    });
  }

  bool emptyMask() {
    final format = selectedPayModeDetail?.pdMask ?? '';

    return format.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedPayModeHeader == null && !dontPop) {
          POSPriceCalculator().clearPayments();
          return true;
        }
        return false;
      },
      child: KeyboardListener(
        autofocus: true,
        onKeyEvent: (value) async {
          if (value.logicalKey == LogicalKeyboardKey.escape) {
            if (mounted)
              setState(() {
                dontPop = selectedPayModeHeader?.pHDETAIL ?? false;
                selectedPayModeHeader = null;
                selectedPayModeDetail = null;
              });
          }
          if (value is KeyDownEvent) {
            if (!HardwareKeyboard.instance.isShiftPressed &&
                value.logicalKey == LogicalKeyboardKey.f5) {
              billClose();
            }
            if (value.physicalKey == PhysicalKeyboardKey.numpadAdd) {
              //clear entered values
              if (selectedPayModeHeader?.pHCODE != "CSH") {
                if (!emptyMask()) {
                  detailsEditingController.clear();
                  isFocusPayment = false;
                  detailsFocusNode.requestFocus();
                  if (mounted) setState(() {});
                }
                dueBalanceEditingController.clear();
              } else {
                //if the pressed button is exact
                if (mounted)
                  setState(() {
                    dueBalanceEditingController.text =
                        balanceDue.toStringAsFixed(2);
                  });
                await handleEnterPress();
                //billClose();
              }
            }
          }
          // else{
          //   if(!emptyMask()){
          //     detailsFocusNode.requestFocus();
          //   }else{
          //     balanceFocus.requestFocus();
          //   }
          // }
        },
        focusNode: focusNode,
        child: POSBackground(
            child: Scaffold(
          body: OverlayTutorialScope(
            enabled: _showGvTutorial,
            child: AbsorbPointer(
              absorbing: _showGvTutorial,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildBody(),
              ),
            ),
          ),
        )),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    detailsEditingController.dispose();
    dueBalanceEditingController.dispose();
    focusNode.dispose();
    errorNode.dispose();
    balanceFocus.dispose();
    detailsFocusNode.dispose();
    super.dispose();
  }

  Widget buildBody() {
    return Column(
      children: [
        POSInvoiceAppBar(hideCustomer: true),
        Expanded(child: buildContent())
      ],
    );
  }

  void _maximumExceedError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return POSErrorAlert(
            title: 'payment_view.maximum_exceed_title'.tr(),
            subtitle: 'payment_view.maximum_exceed_subtitle'.tr(namedArgs: {
              'amount': _maximumLoyaltyAmount.toStringAsFixed(2)
            }),
            actions: [
              AlertDialogButton(
                  onPressed: () => Navigator.pop(context),
                  text: 'payment_view.okay'.tr())
            ]);
      },
    );
  }

  Future<bool> _handleAdvancePayment() async {
    final String advanceSlipNumber = dueBalanceEditingController.text;
    if (advanceSlipNumber.isEmpty) {
      _advancePaymentError('advance_pay_error.empty'.tr());
      return false;
    }
    // check if its already added or not
    if ((cartBloc.paidList?.indexWhere((element) =>
                element.phCode == selectedPayModeHeader?.pHCODE &&
                element.refNo == advanceSlipNumber) ??
            -1) !=
        -1) {
      _advancePaymentError('advance_pay_error.already_added'.tr());
      dueBalanceEditingController.clear();
      return false;
    }

    final advPaymentRes = await ApiClient.call(
      'invoice/validate_advance/?advance_no=$advanceSlipNumber',
      ApiMethod.GET,
    );
    if (advPaymentRes?.statusCode != 200 ||
        advPaymentRes?.data == null ||
        advPaymentRes?.data['success'] == false) {
      _advancePaymentError(
          advPaymentRes?.data['message'] ?? 'advance_pay_error.not_found'.tr());
      return false;
    } else {
      double amount = advPaymentRes?.data['advance_pay']?['adV_AMOUNT'] ?? 0;
      if (amount != 0) {
        dueBalanceEditingController.text = amount.toStringAsFixed(2);
        detailsEditingController.text = advanceSlipNumber;
      } else {
        _advancePaymentError('advance_pay_error.zero_amount'.tr());
        return false;
      }
    }

    return true;
  }

  /// handle cashier entered gift vouchers
  Future<bool> _handleEnteredGv() async {
    //if selected one is gv
    if (selectedPayModeHeader?.isGv == true) {
      //validate gv
      final String gv = dueBalanceEditingController.text;
      if (gv.isEmpty) {
        _gvError('gv_error.empty'.tr());
        return false;
      }

      // check if its already added or not
      if ((cartBloc.paidList?.indexWhere((element) =>
                  element.phCode == selectedPayModeHeader?.pHCODE &&
                  element.refNo == gv) ??
              -1) !=
          -1) {
        _gvError('gv_error.already_added'.tr());
        dueBalanceEditingController.clear();
        return false;
      }

      //gift voucher
      final GiftVoucherResult? voucherRes = await GiftVoucherController()
          .validateGiftVoucherRedemption(gv, subTotal);
      if (voucherRes == null ||
          voucherRes.success != true && voucherRes.giftVoucher != null) {
        // show error
        final String error = voucherRes?.message ?? 'gv_error.not_found'.tr();
        _gvError(error);
        return false;
      } else {
        final GiftVoucher voucher = voucherRes.giftVoucher!;
        //still not finished we have to check exp date
        final DateTime now = DateTime.now();
        final DateTime sold = voucher.soldDate ?? now;
        final DateTime expDate = sold.add(Duration(days: voucher.expDays ?? 0));
        if (expDate.isBefore(now)) {
          bool expVcRes = await _gvErrorExpired(voucher.vCNO ?? '');
          if (!expVcRes) {
            return false;
          }
        }
        //lets check the user permissions for gv redemption
        String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
        String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';

        String refCode = '$invoiceNo@${user}RED${voucher.vCNO}';
        bool hasPermission = false;
        hasPermission = SpecialPermissionHandler(context: context)
            .hasPermission(
                permissionCode: PermissionCode.giftVoucherRedeem,
                accessType: "A",
                refCode: refCode);

        //if user doesnt have the permission
        if (!hasPermission) {
          final res = await SpecialPermissionHandler(context: context)
              .askForPermission(
                  permissionCode: PermissionCode.giftVoucherRedeem,
                  accessType: "A",
                  refCode: refCode);
          hasPermission = res.success;
          user = res.user;
        }
        if (!hasPermission) {
          return false;
        }

        dueBalanceEditingController.text = (voucher.vCVAlUE ?? 0).toString();
        detailsEditingController.text = voucher.vCNO ?? gv;
      }
    }
    return true;
  }

  /// handle cashier entered credit customer
  Future<bool> _handleCredit() async {
    if (selectedPayModeHeader?.pHLINKCREDIT == true &&
        customerBloc.currentCustomer != null) {
      String customer = customerBloc.currentCustomer?.cMCODE ?? '';
      //check permission first
      String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
      String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';

      String refCode = '$invoiceNo@$user@$customer';
      bool hasPermission = false;
      hasPermission = SpecialPermissionHandler(context: context).hasPermission(
          permissionCode: PermissionCode.creditSales,
          accessType: "A",
          refCode: refCode);

      if (!hasPermission) {
        final res = await SpecialPermissionHandler(context: context)
            .askForPermission(
                permissionCode: PermissionCode.creditSales,
                accessType: "A",
                refCode: refCode);
        hasPermission = res.success;
        user = res.user;
      }
      if (!hasPermission) {
        return false;
      }

      //validate customer credit limit totalcredits
      double availableToSpend = customerBloc.currentCustomer?.creditLimit ?? 0;
      double previousBalance = customerBloc.currentCustomer?.totalCredits ?? 0;
      double enteredAmount = dueBalanceEditingController.text.parseDouble();
      if (availableToSpend < (previousBalance + enteredAmount)) {
        return await _creditLimitExceed(availableToSpend - previousBalance);
      }
    }
    return true;
  }

  Future<bool> _creditLimitExceed(double creditLimit) async {
    bool canGo = false;
    bool? res = await showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: "payment_view.credit_limit_exceed".tr(),
          subtitle: "payment_view.credit_limit_exceed_content"
              .tr(namedArgs: {"credit_limit": creditLimit.toStringAsFixed(2)}),
          actions: [
            AlertDialogButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              text: "payment_view.yes".tr(),
            ),
            AlertDialogButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              text: "payment_view.no".tr(),
            ),
          ]),
    );
    if (res == true) {
      String customer = customerBloc.currentCustomer?.cMCODE ?? '';
      //check permission first
      String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
      String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';

      String refCode = '$invoiceNo@$user@$customer';
      bool hasPermission = false;
      hasPermission = SpecialPermissionHandler(context: context).hasPermission(
          permissionCode: PermissionCode.byPassCreditValidation,
          accessType: "A",
          refCode: refCode);

      if (!hasPermission) {
        final res = await SpecialPermissionHandler(context: context)
            .askForPermission(
                permissionCode: PermissionCode.byPassCreditValidation,
                accessType: "A",
                refCode: refCode);
        hasPermission = res.success;
        user = res.user;
      }
      if (!hasPermission) {
        return false;
      } else {
        return true;
      }
    } else {
      canGo = false;
    }
    return canGo;
  }

  //handle cashier entered loyalty
  Future<bool> _handleEnteredLoyalty() async {
    double enteredAmount = dueBalanceEditingController.text.parseDouble();
    if (selectedPayModeHeader?.pHLINKLOYALTY == true) {
      //if entered amount is greater than payable amount
      if (enteredAmount.toDouble() > _maximumLoyaltyAmount) {
        _maximumExceedError();
        dueBalanceEditingController.text = _maximumLoyaltyAmount.toString();
        setState(() {});
        return false;
      }

      //validating process
      bool verified = false;
      String mobile = customerBloc.currentCustomer?.cMMOBILE ?? '';
      OTPController otpController = OTPController();
      if (!_loyaltyModuleHelper.extLoyaltyModuleActive) {
        final otp = otpController.generateOTP();
        await SMSController().sendOTP(mobile, otp);
        await otpController.verifyOTP(context);
        verified = otpController.validOtp;
      } else {
        await _loyaltyModuleHelper.redemptionPinRequest(
            mobile, enteredAmount.toDouble());
        _otpCode = await otpController.enter3rdPartyOTP(context);
        verified = true;
      }
      //so lets reduce the maximum amount according to the entered amount
      if (verified) {
        _burnedPoints += enteredAmount.toDouble();
        _maximumLoyaltyAmount -= enteredAmount.toDouble();
        setState(() {});
      }
    }
    return true;
  }

  Future<void> handleEnterPress() async {
    //heandling advanced payments
    if (selectedPayModeHeader?.pHLINKADVANCE == true &&
        !(await _handleAdvancePayment())) {
      return;
    }
    //handle gv
    if (!(await _handleEnteredGv())) {
      return;
    }
    double enteredAmount = dueBalanceEditingController.text.parseDouble();
    if (enteredAmount == 0) {
      return;
    }
    if (!(await _handleEnteredLoyalty())) {
      return;
    }
    if (!(await _handleCredit())) {
      return;
    }

    if (enteredAmount == 0) {
      if (isFocusPayment)
        return;
      else {
        balanceFocus.requestFocus();
        isFocusPayment = true;
        if (mounted) setState(() {});
        return;
      }
    }
    bool hasDetails = (selectedPayModeHeader?.pHDETAIL ?? false);
    if (selectedPayModeHeader == null) {
      showErrorDialog();
      return;
    } else if (hasDetails && selectedPayModeDetail == null && !_ecr) {
      showErrorDialog();
      return;
    } else {
      handleCalculation();
    }
  }

  ///
  /// return true anyway cashies want to  proceed the voucher
  Future<bool> _gvErrorExpired(String voucher) async {
    bool? res = await showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: 'gv_error.expired'.tr(),
          subtitle: 'gv_error.expired_content'.tr(),
          actions: <Widget>[
            AlertDialogButton(
              onPressed: () => Navigator.pop(context, false),
              text: 'gv_error.no'.tr(),
            ),
            AlertDialogButton(
              onPressed: () => Navigator.pop(context, true),
              text: 'gv_error.yes'.tr(),
            )
          ]),
    );

    //check permission
    if (res == true) {
      String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
      String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';

      String refCode = '$invoiceNo@${user}ExpVc$voucher';
      bool hasPermission = false;
      hasPermission = SpecialPermissionHandler(context: context).hasPermission(
          permissionCode: PermissionCode.acceptExpiredVouchers,
          accessType: "A",
          refCode: refCode);

      if (!hasPermission) {
        final res = await SpecialPermissionHandler(context: context)
            .askForPermission(
                permissionCode: PermissionCode.acceptExpiredVouchers,
                accessType: "A",
                refCode: refCode);
        hasPermission = res.success;
        user = res.user;
      }
      res = hasPermission;
    }

    return res ?? false;
  }

  void _gvError(String error) {
    showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: 'gv_error.title'.tr(),
          subtitle: error,
          actions: <Widget>[
            AlertDialogButton(
              onPressed: () => Navigator.pop(context),
              text: 'gv_error.okay'.tr(),
            )
          ]),
    );
  }

  void _advancePaymentError(String error) {
    showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: 'advance_pay_error.title'.tr(),
          subtitle: error,
          actions: <Widget>[
            AlertDialogButton(
              onPressed: () => Navigator.pop(context),
              text: 'advance_pay_error.okay'.tr(),
            )
          ]),
    );
  }

  void handleCalculation() async {
    double entered =
        dueBalanceEditingController.text.parseDouble() * currentRate;
    double temp = balanceDue - entered;

    temp = double.parse(temp.toStringAsFixed(2));

    // if (temp < 0 && temp <= 0.1) {
    //   temp = 0;
    // }

    if (!(selectedPayModeHeader?.pHOVERPAY ?? false) && temp < 0) {
      showOverPayErrorDialog();
      return;
    }

    ///if reference mode available handle it
    if ((selectedPayModeHeader?.reference ?? '').isNotEmpty) {
      _handleReferencedPayMode(entered);
      return;
    }

    bool cantGo = false;
    DateTime? dateTime;
    //req date if cheque selected
    if (selectedPayModeDetail?.pDREQDATE == true) {
      cantGo = true;
      dateTime = await datePicker();
      if (dateTime != null) {
        cantGo = false;
      }
    }

    //TODO : ecr integration
    //if (_ecr) {
    // if (selectedPayModeDetail?.pDPHCODE == 'CRC' && POSConfig().ecr) {
    //   final EcrResponse? ecr = await EcrController().doSale(entered);
    //   String bin = ecr?.ecrCard?.strTxnCardBin ?? '';
    //   String lastDigits = ecr?.ecrCard?.strTxnCardLastDigits ?? '';
    //   if (ecr?.ecrCard != null) cartBloc.addNewReference(ecr!.ecrCard!);
    //   formatCardNoFromEcr(bin, lastDigits);
    //   _ecr = false;
    //   _ecrTimeOut = 60;
    //   _timer?.cancel();
    // }

    if ((selectedPayModeDetail?.pdMask ?? '') != '' &&
        (detailsEditingController.text == '' ||
            detailsEditingController.text.length !=
                selectedPayModeDetail?.pdMask?.length)) {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.error, "Enter a valid card number"));
      showCardNoNotEnteredErrorDialog();
      return;
    }

    // not allowing to pay from exact same crc multiple time (more than once)
    if (cartBloc.paidList != null && cartBloc.paidList!.length > 0) {
      for (var paid in cartBloc.paidList!) {
        if (selectedPayModeHeader?.pHCODE == 'CRC' &&
            detailsEditingController.text == paid.refNo) {
          EasyLoading.showError('payment_view.duplicate_card'.tr());
          return;
        }
      }
    }

    if (cantGo) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Date field required for proceed the payment"));
      return;
    }
    //check entered bin
    final bool binRes = _checkCardBin(detailsEditingController.text);
    if (!binRes) {
      return;
    }
    balanceDue = temp;
    final balanceDueTemp = balanceDue;
    entered = dueBalanceEditingController.text.parseDouble() * currentRate;
    // temp = balanceDue - entered;

    paid += entered;
    String phCode = selectedPayModeHeader?.pHCODE ?? "";
    String pdCode = selectedPayModeDetail?.pDCODE ?? phCode;
    String phDesc = selectedPayModeHeader?.pHDESC ?? "";
    String pdDesc = selectedPayModeDetail?.pDDESC ?? phDesc;
    final tot = cartBloc.cartSummary?.subTotal ?? 0;

    if (/* phCode == 'CSH' && */ temp < 0) {
      entered = entered + temp;
    }
    if (POSConfig().dualScreenWebsite != "")
      DualScreenController()
          .sendPayment(paid.toDouble(), subTotal.toDouble(), saving.toDouble());
    cartBloc.addPayment(PaidModel(
        // temp < 0 ? balanceDueTemp : entered,
        //entered > balanceDue ? balanceDueTemp : entered,
        entered,
        entered,
        false,
        pdCode,
        phCode,
        detailsEditingController.text,
        dateTime,
        selectedPayModeDetail?.pDRATE,
        phDesc,
        pdDesc,
        frAmount: dueBalanceEditingController.text.parseDouble(),
        isGv: selectedPayModeHeader?.isGv ?? false,
        pointRate: selectedPayModeHeader?.pointRate ?? 0));
    dueBalanceEditingController.clear();
    detailsEditingController.clear();
    _ecr = false;

    if (selectedPayModeHeader?.isGv == true && balanceDue > 0) {
    } else {
      selectedPayModeDetail = null;
      selectedPayModeHeader = null;
    }

    // should reset the current rate
    currentRate = 1.0;
    if (mounted) setState(() {});
  }

  /// check entered crd bin for promotion
  bool _checkCardBin(String enteredBin) {
    final requiredBins = cartBloc.specificPayMode?.cardBin ?? [];
    enteredBin = enteredBin.replaceAll('-', '');
    if (requiredBins.isNotEmpty) {
      if (requiredBins
          .where((element) => enteredBin.contains((element.pBCARDBIN ?? '')))
          .isNotEmpty) {
        if (dueBalanceEditingController.text.toDouble() != balanceDue) {
          dueBalanceEditingController.text = balanceDue.toStringAsFixed(2);
        }
        return true;
      }
    } else {
      return true;
    }

    // Commented reverse promotion by PW to allow user to retry
    // reverse the promotion
    // final double promoAmount = cartBloc.reversePaymentModePromo();
    // balanceDue += promoAmount;
    // paid -= promoAmount;
    if (mounted) {
      setState(() {});
    }
    showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: "payment_view.invalid_promotion_card_bin_title".tr(),
          subtitle: "payment_view.invalid_promotion_card_bin_subtitle".tr(),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "payment_mode_empty.okay".tr(),
                style: Theme.of(context).dialogTheme.contentTextStyle,
              ),
            )
          ]),
    );
    return false;
  }

  Future<DateTime?> datePicker() async {
    return await showRoundedDatePicker(
        context: context,
        firstDate: DateTime.now().subtract(Duration(days: 1)),
        lastDate: DateTime.now().add(Duration(days: 364)),
        borderRadius: 8,
        styleDatePicker: MaterialRoundedDatePickerStyle(
          textStyleDayButton: TextStyle(fontSize: 36, color: Colors.white),
          textStyleYearButton: TextStyle(
            fontSize: 30.sp,
            color: Colors.white,
          ),
          textStyleDayHeader: TextStyle(
            fontSize: 24.sp,
            color: Colors.white,
          ),
          textStyleMonthYearHeader: TextStyle(fontSize: 28.sp),
          sizeArrow: 20.sp,
          textStyleButtonNegative: TextStyle(fontSize: 16.sp),
          textStyleButtonPositive: TextStyle(fontSize: 16.sp),
          textStyleDayOnCalendar: TextStyle(fontSize: 18.sp),
          textStyleCurrentDayOnCalendar:
              TextStyle(fontSize: 18.sp, color: Colors.green),
          textStyleDayOnCalendarSelected: TextStyle(fontSize: 18.sp),
          textStyleDayOnCalendarDisabled:
              TextStyle(fontSize: 18.sp, color: Colors.grey),
        ));

    // return await showDatePicker(
    //     context: context,
    //     initialDate: DateTime.now(),
    //     builder: (context, child) {
    //       final size = 750.r;
    //       return Column(
    //         children: [
    //           SizedBox(
    //             width: size,
    //             height: size,
    //             child: Theme(
    //                 data: CurrentTheme.themeData!.copyWith(
    //                   textTheme: TextTheme(
    //                     caption: TextStyle(
    //                       color: Colors.red,
    //                       fontSize: 24.sp,
    //                     ),
    //                   ),
    //                 ),
    //                 child: child!),
    //           ),
    //         ],
    //       );
    //     },
    //     firstDate: DateTime.now(),
    //     lastDate: DateTime.now().add(Duration(days: 364)));
  }

  void showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: "payment_mode_empty.title".tr(),
          subtitle: "payment_mode_empty.subtitle".tr(),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "payment_mode_empty.okay".tr(),
                style: Theme.of(context).dialogTheme.contentTextStyle,
              ),
            )
          ]),
    );
  }

  void showOverPayErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: "over_pay_error.title".tr(),
          subtitle: "over_pay_error.subtitle".tr(),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "over_pay_error.okay".tr(),
                style: Theme.of(context).dialogTheme.contentTextStyle,
              ),
            )
          ]),
    );
  }

  void showCardNoNotEnteredErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: "payment_view.card_not_entered_title".tr(),
          subtitle: "payment_view.card_not_entered".tr(),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "over_pay_error.okay".tr(),
                style: Theme.of(context).dialogTheme.contentTextStyle,
              ),
            )
          ]),
    );
  }

  void handleMultipleBalance() {}

  Widget buildContent() {
    if (POSConfig().defaultCheckoutLSH)
      return Row(
        children: [
          Expanded(child: buildDefaultLHS()),
          Expanded(child: buildDefaultRHS()),
        ],
      );
    else
      return Row(
        children: [
          Expanded(child: buildDefaultRHS()),
          Expanded(child: buildDefaultLHS()),
        ],
      );
  }

  void clearTempPayment() {
    if (POSConfig().dualScreenWebsite != "")
      DualScreenController().setView('invoice');
    if (selectedPayModeHeader == null) {
      POSPriceCalculator().clearPayments();
      Navigator.pop(context);
    } else {
      calculateToLocal();
      detailsEditingController.clear();
      dueBalanceEditingController.clear();
      setState(() {
        selectedPayModeHeader = null;
        selectedPayModeDetail = null;
      });
    }
  }

  // this is the default lhs in the app
  Widget buildDefaultLHS() {
    String payModeText = selectedPayModeHeader == null
        ? "payment_view.select_payment_mode".tr()
        : "payment_view.selected_payment_mode".tr(namedArgs: {
            "pay_mode": (selectedPayModeHeader?.pHDESC ?? "") +
                (selectedPayModeDetail != null
                    ? " ( ${selectedPayModeDetail?.pDDESC ?? ""})"
                    : "")
          });
    if (_ecr == true) {
      payModeText = '$payModeText ($_ecrTimeOut)';
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: height.h,
          child: Card(
            child: Row(
              children: [
                SizedBox(
                  width: 15.r,
                ),
                POSConfig().defaultCheckoutLSH
                    ? GoBackIconButton(
                        onPressed: _ecr ? () {} : clearTempPayment,
                      )
                    : Spacer(),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
                  child: Center(
                      child: Text(
                    payModeText,
                    style: CurrentTheme.bodyText2!
                        .copyWith(color: CurrentTheme.primaryColor),
                  )),
                ),
                POSConfig().defaultCheckoutLSH
                    ? Spacer()
                    : GoBackIconButton(onPressed: clearTempPayment),
                SizedBox(
                  width: 15.r,
                ),
              ],
            ),
          ),
        ),
        Expanded(
            child: Scrollbar(
                controller: payModeScroll, child: buildPaymentButtonList())),
        Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        POSConfig().primaryDarkGrayColor.toColor()),
                onPressed: billClose,
                child: Text("payment_view.bill_close".tr())))
      ],
    );
  }

  Future<void> billClose() async {
    errorNode.requestFocus();
    if ((balanceDue * 100).truncate() / 100 > 0) {
      showDialog(
        context: context,
        builder: (context) {
          return POSErrorAlert(
              title: "due_amount_error.title".tr(),
              subtitle: "due_amount_error.subtitle"
                  .tr(namedArgs: {"due": balanceDue.toStringAsFixed(3)}),
              actions: [
                KeyboardListener(
                  focusNode: errorNode,
                  autofocus: true,
                  onKeyEvent: (value) {
                    if (value is KeyDownEvent) {
                      if (value.physicalKey == PhysicalKeyboardKey.enter ||
                          value.physicalKey == PhysicalKeyboardKey.keyO) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              POSConfig().primaryDarkGrayColor.toColor()),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: RichText(
                          text: TextSpan(text: '', children: [
                        TextSpan(
                            text: "due_amount_error.okay".tr().substring(0, 1),
                            style: TextStyle(
                                decoration: TextDecoration.underline)),
                        TextSpan(
                            text: "due_amount_error.okay".tr().substring(1))
                      ]))
                      //  Text(
                      //   "due_amount_error.okay".tr(),
                      //   style: Theme.of(context).dialogTheme.contentTextStyle,
                      // ),
                      ),
                )
              ]);
        },
      );
      return;
    }

    if (customerBloc.currentCustomer?.sendOTP == true) {
      OTPController otpController = OTPController();
      final otp = otpController.generateOTP();
      await SMSController()
          .sendOTP(customerBloc.currentCustomer?.cMMOBILE ?? '', otp);
      await otpController.verifyOTP(context);
      bool verified = otpController.validOtp;
      if (verified == false) {
        return;
      }
    }

    if (!billCloseClicked) {
      setState(() {
        billCloseClicked = true;
      });

      //check the due amount and gift voucher codes
      //get the gvs in payment modes
      int gvIndex =
          cartBloc.paidList?.indexWhere((element) => element.isGv) ?? -2;
      if (gvIndex >= 0 && balanceDue < 0) {
        final double? exVoucherRes = await showDialog<double?>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('exchange_voucher.title'.tr()),
              content: Text('exchange_voucher.subtitle'.tr()),
              actions: [
                Row(
                  children: [
                    AlertDialogButton(
                        onPressed: () =>
                            Navigator.pop(context, (balanceDue) * -1),
                        text: 'exchange_voucher.cash'.tr(namedArgs: {
                          'value': (balanceDue * -1).toStringAsFixed(2)
                        })),
                    const SizedBox(
                      width: 25,
                    ),
                    AlertDialogButton(
                        onPressed: () async {
                          Navigator.pop(context, 0.0);
                        },
                        text: 'exchange_voucher.exchange'.tr(namedArgs: {
                          'value': (balanceDue * -1).toStringAsFixed(2)
                        })),
                  ],
                )
              ],
            );
          },
        );

        if ((exVoucherRes ?? 0) == 0) {
          String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
          String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';

          String refCode = '$invoiceNo@${user}Ex$balanceDue';
          bool hasPermission = false;
          hasPermission = SpecialPermissionHandler(context: context)
              .hasPermission(
                  permissionCode: PermissionCode.generateExchangeVoucher,
                  accessType: "A",
                  refCode: refCode);

          //if user doesnt have the permission
          if (!hasPermission) {
            final res = await SpecialPermissionHandler(context: context)
                .askForPermission(
                    permissionCode: PermissionCode.generateExchangeVoucher,
                    accessType: "A",
                    refCode: refCode);
            hasPermission = res.success;
            user = res.user;
          }
          if (hasPermission) {
            final voucher = GiftVoucher(
                vCDESC: 'Exchange Voucher',
                vCNO: 'exchange_999999_voucher',
                vCVAlUE: (balanceDue * -1));

            await POSPriceCalculator()
                .addGv(voucher, 1, context, permission: false);
          } else {
            return;
          }
        }
      }

      EasyLoading.show(status: 'please_wait'.tr());
      var res;
      if (!POSConfig().trainingMode) {
        res = await InvoiceController().billClose(
            invoiced: true,
            context: context,
            otp: _otpCode,
            referenceNo: _referenceNumber,
            changeAmt: balanceDue * -1,
            payAmt: paid,
            burnedPoints: _burnedPoints);
      } else {
        res = InvoiceSaveRes(true, 0, '');
      }
      //navigate back and clear all
      EasyLoading.dismiss();
      if (!res.success) {
        setState(() {
          billCloseClicked = false;
        });
      }

      if (res.success) {
        try {
          if (!POSConfig().trainingMode) {
            if (res?.resReturn == null ||
                res.resReturn == '' ||
                res.resReturn == '{}') {
              EasyLoading.show(status: 'please_wait'.tr());
              final invDataCheckRes = await ApiClient.call(
                  "invoice/get_invoice_det/${cartBloc.cartSummary?.invoiceNo ?? ""}/${POSConfig().locCode}/INV",
                  // "invoice/get_invoice_det/010910000025/${POSConfig().locCode}/INV",
                  ApiMethod.GET,
                  successCode: 200);
              EasyLoading.dismiss();
              if (invDataCheckRes == null ||
                  invDataCheckRes.data['success'] != true ||
                  invDataCheckRes.data['res'] == null) {
                final bool? retry = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => POSErrorAlert(
                            title: 'easy_loading.cant_save_inv'.tr(),
                            subtitle:
                                "An error occured when saving the invoice ${cartBloc.cartSummary?.invoiceNo ?? ""}\nDo you want to retry?",
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: POSConfig()
                                        .primaryDarkGrayColor
                                        .toColor()),
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: Text(
                                  'Retry',
                                  style: Theme.of(context)
                                      .dialogTheme
                                      .contentTextStyle,
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: POSConfig()
                                        .primaryDarkGrayColor
                                        .toColor()),
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: Text(
                                  'Cancel',
                                  style: Theme.of(context)
                                      .dialogTheme
                                      .contentTextStyle,
                                ),
                              ),
                            ]));
                if (retry != true) {
                  return;
                } else {
                  await billClose();
                  return;
                }
              } else {
                var det;
                try {
                  det = jsonDecode(
                      (invDataCheckRes.data?['res'] ?? "").toString());
                } catch (e) {
                  det = {"T_TBLINVHEADER": []};
                }
                if ((det?['T_TBLINVHEADER'] ?? []).isEmpty) {
                  // EasyLoading.showError(
                  //     'Invoice not saved... try saving the invoice again !!!');
                  final bool? retry = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => POSErrorAlert(
                              title: 'easy_loading.cant_save_inv'.tr(),
                              subtitle:
                                  "An error occured when saving the invoice ${cartBloc.cartSummary?.invoiceNo ?? ""}\nDo you want to retry?",
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: POSConfig()
                                          .primaryDarkGrayColor
                                          .toColor()),
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                  },
                                  child: Text(
                                    'Retry',
                                    style: Theme.of(context)
                                        .dialogTheme
                                        .contentTextStyle,
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: POSConfig()
                                          .primaryDarkGrayColor
                                          .toColor()),
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: Text(
                                    'Cancel',
                                    style: Theme.of(context)
                                        .dialogTheme
                                        .contentTextStyle,
                                  ),
                                ),
                              ]));
                  if (retry != true) {
                    EasyLoading.showError('easy_loading.cant_save_inv'.tr());
                    return;
                  } else {
                    await billClose();
                    return;
                  }
                } else {
                  res.resReturn = invDataCheckRes.data?['res'].toString() ?? '';
                }
              }
            }

            if (POSConfig().dualScreenWebsite != "")
              DualScreenController().completeInvoice(paid.toDouble(),
                  balanceDue.toDouble(), balanceDue.toDouble(), 0);

            String invoice = cartBloc.cartSummary?.invoiceNo ?? "";
            String latestInvoiceNumber = invoice;
            String lastInvNo = await InvoiceController().getInvoiceNo();

            String lastInvPrefix = lastInvNo.substring(0, 6);
            String lastInvSuffix = lastInvNo.substring(6);

            int lengthOfSuffixInt =
                (int.parse(lastInvSuffix) - 1).toString().length;
            int zeroLength = 6 - lengthOfSuffixInt;

            if (int.parse(invoice) < int.parse(lastInvNo)) {
              latestInvoiceNumber = lastInvPrefix +
                  ('0' * zeroLength) +
                  (int.parse(lastInvSuffix) - 1).toString();
            }
            InvoiceController().setInvoiceNo(latestInvoiceNumber);
            LastInvoiceDetails lastInvoice = LastInvoiceDetails(
                invoiceNo: invoice,
                billAmount: subTotal.toStringAsFixed(2),
                dueAmount: balanceDue.toStringAsFixed(2),
                paidAmount: paid.toStringAsFixed(2));
            cartBloc.updateLastInvoice(lastInvoice);

            //print invoice

            final customerEmail = customerBloc.currentCustomer?.cMEMAIL ?? '';
            final ebillActive = customerBloc.currentCustomer?.cMEBILL ?? false;

            bool canPrint = true;
            if (ebillActive && customerEmail.isNotEmpty) {
              if (await sendEbillAlert(invoice)) {
                canPrint = false;
              }
            }

            if (canPrint) {
              try {
                double loyaltyPoints = 0;
                final String customerCode =
                    customerBloc.currentCustomer?.cMCODE ?? '';
                if (customerCode.isNotEmpty &&
                    customerBloc.currentCustomer?.cMLOYALTY == true) {
                  var customerRes =
                      await LoyaltyController().getLoyaltySummary(customerCode);
                  loyaltyPoints = customerRes?.pOINTSUMMARY ?? 0;
                }

                if (customerBloc.currentCustomer?.taxRegNo != '' &&
                    customerBloc.currentCustomer?.taxRegNo != null) {
                  final bool? canPrintTaxBill = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          'invoice.tax_bill_print_title'.tr(),
                          textAlign: TextAlign.center,
                        ),
                        content: Text('invoice.tax_bill_print_content'.tr()),
                        actions: [
                          AlertDialogButton(
                              onPressed: () => Navigator.pop(context, false),
                              text: 'invoice.tax_bill_print_yes'.tr()),
                          AlertDialogButton(
                              onPressed: () => Navigator.pop(context, false),
                              text: 'invoice.tax_bill_print_no'.tr()),
                        ],
                      );
                    },
                  );
                  if (canPrintTaxBill ?? false)
                    await printInvoice(invoice, res.earnedPoints, loyaltyPoints,
                        true, res.resReturn);
                  else
                    await printInvoice(invoice, res.earnedPoints, loyaltyPoints,
                        false, res.resReturn);
                } else {
                  await printInvoice(invoice, res.earnedPoints, loyaltyPoints,
                      false, res.resReturn);
                }
              } catch (e) {
                EasyLoading.showError('easy_loading.cant_print_inv'.tr());
              }
            }
          }
        } catch (e) {
          setState(() {
            billCloseClicked = false;
          });
        }
        setState(() {
          billCloseClicked = false;
        });
        cartBloc.context = context;
        await cartBloc.resetCart();
        Navigator.pushReplacementNamed(context, Cart.routeName);
      }
    }
  }

  Future<bool> sendEbillAlert(String invoiceNo) async {
    final bool? res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('payment_view.e_bill_title'.tr()),
        actions: <Widget>[
          AlertDialogButton(
              onPressed: () async {
                EasyLoading.show(status: 'please_wait'.tr());
                bool res = await EmailController().sendEbill(invoiceNo);
                EasyLoading.dismiss();
                Navigator.pop(context, res);
              },
              text: 'payment_view.yes'.tr()),
          AlertDialogButton(
              onPressed: () => Navigator.pop(context, false),
              text: 'payment_view.no'.tr()),
        ],
      ),
    );
    return res ?? false;
  }

  Future printInvoice(String invoiceNo, double earnedPoints, double totalPoints,
      bool taxbill, String? resReturn) async {
    if (POSConfig.crystalPath != '') {
      await PrintController().printHandler(
          invoiceNo,
          PrintController().printInvoice(
              invoiceNo, earnedPoints, totalPoints, taxbill, resReturn),
          context);
    } else {
      POSConfig.localPrintData = resReturn!;
      var stopwatch = Stopwatch();

      stopwatch.start();
      POSManualPrint().printInvoice(data: resReturn, points: totalPoints);
      stopwatch.stop();
      print(stopwatch.elapsed.toString());
    }

    if (POSConfig().enablePollDisplay == 'true')
      await usbSerial.customTimeMessages();

    // var result = await PrintController().printInvoice(invoiceNo);
    // var tempRes = PrintStatus(true, true, "");
    // while (!result.goBack) {
    //   bool showView = result.showViewButton;
    //   result = await showDialog(
    //     context: context,
    //     builder: (context) {
    //       return POSErrorAlert(
    //           title: "pos_printer_not_found.title".tr(),
    //           subtitle: "pos_printer_not_found.subtitle".tr(),
    //           actions: [
    //             ElevatedButton(
    //                 style: ElevatedButton.styleFrom(
    //                     primary: POSConfig().primaryDarkGrayColor.toColor()),
    //                 onPressed: () async {
    //                   var result =
    //                       await PrintController().printInvoice(invoiceNo);
    //                   Navigator.pop(context, result);
    //                 },
    //                 child: Text("pos_printer_not_found.retry".tr())),
    //             !showView
    //                 ? SizedBox.shrink()
    //                 : ElevatedButton(
    //                     style: ElevatedButton.styleFrom(
    //                         primary:
    //                             POSConfig().primaryDarkGrayColor.toColor()),
    //                     onPressed: () async {
    //                       Navigator.pop(context, tempRes);
    //                       PrintController().launchPdf(result.urlPath);
    //                     },
    //                     child: Text("pos_printer_not_found.view".tr())),
    //             ElevatedButton(
    //                 style: ElevatedButton.styleFrom(
    //                     primary: POSConfig().primaryDarkGrayColor.toColor()),
    //                 onPressed: () {
    //                   Navigator.pop(context, tempRes);
    //                 },
    //                 child: Text("pos_printer_not_found.cancel".tr()))
    //           ]);
    //     },
    //   );
    // }
  }

  Widget buildPaymentButtonList() {
    if ((selectedPayModeHeader?.pDDETAILSLIST?.length ?? 0) == 0)
      return buildPaymentButtonHeaderList();
    return buildPaymentButtonDetailList();
  }

  ScrollController payModeScroll = ScrollController();
  Widget buildPaymentButtonHeaderList() {
    final config = POSConfig();
    return Container(
      child: StreamBuilder<PayModeResult?>(
          stream: payModeBloc.payModeSnapshot,
          builder: (context, AsyncSnapshot<PayModeResult?> snapshot) {
            if (!snapshot.hasData) return Container();
            List<PayModeHeader> dynamicButtonList =
                snapshot.data?.payModes ?? [];
            // removing payment modes
            if (POSConfig().localMode == true) {
              dynamicButtonList
                  .removeWhere((element) => element.pHLOCALMODE == false);
            }
            return ResponsiveGridList(
              controller: payModeScroll,
              scroll: true,
              desiredItemWidth: config.paymentDynamicButtonWidth.w,
              children: dynamicButtonList.map((payButton) {
                bool clickable = true;
                final specificPayMode = cartBloc.specificPayMode;
                if (specificPayMode != null) {
                  if (specificPayMode.phCode != payButton.pHCODE) {
                    clickable = false;
                  }
                }
                Color? color = payButton.pHCODE == selectedPayModeHeader?.pHCODE
                    ? CurrentTheme.accentColor
                    : CurrentTheme.primaryColor;
                if (!clickable) {
                  color = color?.withOpacity(0.5);
                }
                return PayButton(
                  code: payButton.pHCODE ?? "",
                  desc: payButton.pHDESC ?? "",
                  color: color,
                  onPressed: () {
                    if (clickable) {
                      onPayModeHeadClick(payButton);
                    }
                  },
                );
              }).toList(),
            );
          }),
    );
  }

  Future<void> onPayModeHeadClick(PayModeHeader payButton) async {
    // resetting current rate first for safety   : we encountered issue when did payments after a foriegn currency payment
    currentRate = 1.0;

    if (balanceDue <= 0) {
      EasyLoading.showError('payment_view.pay_amount_reached'.tr());
      return;
    }
    _textMask = null;
    POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
        "${payButton.pHDESC}(${payButton.pHCODE}) button pressed"));

    //check for reserved payment modes
    print(payButton.pHLINKPROMO);
    if (payButton.pHLINKPROMO == true) {
      _errorPaymentMode();
      return;
    }

    //check for duplicate records
    final int duplicateIndex = cartBloc.paidList?.indexWhere((element) =>
            element.phCode == payButton.pHCODE &&
            element.isGv == false &&
            payButton.pHDETAIL == false) ??
        -1;
    if (duplicateIndex != -1) {
      EasyLoading.showError('payment_view.duplicate'.tr());
      return;
    }

    //disable gv module
    if (payButton.isGv == true) {
      if ((POSConfig().clientLicense?.lCMYVOUCHERS != true ||
          POSConfig().expired)) {
        ActivationController().showModuleBuy(context, "myVouchers");
        return;
      }
      //show tutorial
      //showTutorial(true);
      if (POSConfig().localMode && payButton.pHLOCALMODE == true) {
        EasyLoading.showError('local_mode_func_disable'.tr());
        return;
      }

      if (mounted) {
        setState(() {
          selectedPayModeHeader = payButton;
        });
      }
      // dueBalanceEditingController.text = '';
      dueBalanceEditingController.clear();
      balanceFocus.requestFocus();
      return;
    }

    if (payButton.pHDETAIL != true) {
      balanceFocus.requestFocus();
    }
    if (payButton.pHOVERPAY != true) {
      dueBalanceEditingController.text = balanceDue.toStringAsFixed(2);
    }
    if (mounted) {
      setState(() {
        selectedPayModeHeader = payButton;
      });
    }

    //Removed this line to change the single swipe process
    /// if credit card payment mode and ecr enabled then ask for get data from ecr machine
    // if (payButton.pHCODE == 'CRC' && POSConfig().ecr) {
    //   _ecrDialog(context);
    // }

    //handle loyalty
    if (payButton.pHLINKLOYALTY == true) {
      if (POSConfig().localMode && payButton.pHLOCALMODE == true) {
        EasyLoading.showError('local_mode_func_disable'.tr());
        return;
      }
      _handleLoyalty();
    }

    if (payButton.pHLINKCREDIT == true &&
        POSConfig().localMode &&
        payButton.pHLOCALMODE == true) {
      EasyLoading.showError('local_mode_func_disable'.tr());
      return;
    }

    if (payButton.pHLINKCREDIT == true &&
        customerBloc.currentCustomer == null) {
      setState(() {
        selectedPayModeHeader = null;
      });
      _errorPaymentMode();
      return;
    }

    if (payButton.pHLINKADVANCE == true) {
      dueBalanceEditingController.clear();
      return;
    }
    if (payButton.pHQRPAY == true) {
      if (POSConfig().singleSwipeActive) {
        EcrResponse? ecrResponse =
            await singleSwipeAlert(false, balanceDue, true);
        if (ecrResponse == null)
          print("Switchiing to manual mode");
        else {
          if (ecrResponse.ecrCard != null)
            cartBloc.addNewReference(ecrResponse.ecrCard!);
          formatCardNoFromEcr(ecrResponse.ecrCard?.strTxnCardBin ?? '', '****');
          dueBalanceEditingController.text = balanceDue.toStringAsFixed(2);
          handleCalculation();
        }
      }
    }
  }

  Future showTutorial(bool show) async {
    if (show) {
      if (POSConfig().showedGiftVoucherTutorials) {
        return;
      }
    } else {
      await SharedPreferenceController.init();
      SharedPreferenceController().setGvTutorial(true);
      POSConfig().showedGiftVoucherTutorials = true;
    }
    _showGvTutorial = show;
    if (mounted) {
      setState(() {});
    }
  }

  Widget buildPaymentButtonDetailList() {
    var buttonList = selectedPayModeHeader?.pDDETAILSLIST ?? [];
    if (selectedPayModeDetail == null) {
      final index =
          buttonList.indexWhere((element) => element.pDCODE == "go_back");
      if (index == -1)
        buttonList.add(PayModeDetails(
            pDCODE: "go_back", pDDESC: "payment_view.go_back".tr()));
    }

    final config = POSConfig();
    return Container(
      child: ResponsiveGridList(
        scroll: true,
        desiredItemWidth: config.paymentDynamicButtonWidth.w,
        children: buttonList.map((payButton) {
          final specificPayMode = cartBloc.specificPayMode;
          bool clickable = true;
          if (specificPayMode != null) {
            if (specificPayMode.pdCode != payButton.pDCODE) {
              clickable = false;
            }
          }
          Color? color = payButton.pDPHCODE == selectedPayModeHeader?.pHCODE &&
                  payButton.pDCODE == selectedPayModeDetail?.pDCODE
              ? CurrentTheme.accentColor
              : CurrentTheme.primaryColor;
          if (!clickable) {
            color = color?.withOpacity(0.5);
          }
          return PayButton(
            code: payButton.pDCODE ?? "",
            desc: payButton.pDDESC ?? "",
            color: color,
            onPressed: () async {
              if (!clickable || _ecr) {
                return;
              }
              POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
                  "${payButton.pDDESC}(${payButton.pDCODE}) button pressed"));
              _textMask = payButton.pdMask;
              calculateToLocal();

              if (payButton.pDCODE == "go_back") {
                selectedPayModeDetail = null;
                selectedPayModeHeader = null;
                detailsEditingController.clear();
                dueBalanceEditingController.clear();
              } else
                selectedPayModeDetail = payButton;
              final one = 1.0;
              // if pd Rate has

              var fr = payButton.pDRATE ?? one;

              if (fr <= 0) {
                fr = one;
              } else if (payButton.pDRATE != null) {
                dueBalanceEditingController.text = (balanceDue / fr).roundUp();
              }

              currentRate = fr;

              if (emptyMask()) {
                isFocusPayment = true;
                balanceFocus.requestFocus();
              } else {
                isFocusPayment = false;
                detailsFocusNode.requestFocus();
              }
              if (payButton.pDPHCODE == 'CRC' &&
                  POSConfig().singleSwipeActive) {
                EcrResponse? ecrResponse =
                    await singleSwipeAlert(false, balanceDue, false);
                if (ecrResponse == null)
                  print("Switchiing to manual mode");
                else {
                  if (ecrResponse.ecrCard != null)
                    cartBloc.addNewReference(ecrResponse.ecrCard!);
                  formatCardNoFromEcr(
                      ecrResponse.ecrCard?.strTxnCardBin ?? '', '****');
                  // dueBalanceEditingController.text =
                  //     balanceDue.toStringAsFixed(2);
                  handleCalculation();
                }
              }
              if (mounted) setState(() {});
              /* Customer coupon pop up */
              /* by dinuka 2022/08/19 */
              if (payButton.pDCODE == 'CCOU') {
                await getAvailableCoupons();
              }
            },
          );
        }).toList(),
      ),
    );
  }

//Single Swipe Alert dialog box
  Future<EcrResponse?> singleSwipeAlert(
      bool doBinRequest, double payAmount, bool qrPay) async {
    EcrResponse? ecr;
    final TextEditingController amountEditingController =
        TextEditingController();
    amountEditingController.text = payAmount.toStringAsFixed(2);
    final String? price = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        // title: Text(
        //   'Single Swipe',
        //   textAlign: TextAlign.center,
        // ),
        backgroundColor: CurrentTheme.backgroundColor,

        content: SizedBox(
          //height: double.infinity,
          height: ScreenUtil().screenHeight * 0.65,
          width: ScreenUtil().screenWidth * 0.75,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'payment_view.ecr_display_name'.tr(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                      alignment: Alignment.centerRight,
                      onPressed: () async {
                        String user =
                            userBloc.currentUser?.uSERHEDUSERCODE ?? "";
                        String invNo = cartBloc.cartSummary?.invoiceNo ?? "";
                        String refCode =
                            '${POSConfig().locCode}-${POSConfig().terminalId}-@$user-$invNo';
                        bool hasPermission = false;
                        hasPermission = SpecialPermissionHandler(
                                context: context)
                            .hasPermission(
                                permissionCode: PermissionCode.skipSingleSwipe,
                                accessType: "A",
                                refCode: refCode);

                        //if user doesnt have the permission
                        if (!hasPermission) {
                          final res =
                              await SpecialPermissionHandler(context: context)
                                  .askForPermission(
                                      permissionCode:
                                          PermissionCode.skipSingleSwipe,
                                      accessType: "A",
                                      refCode: refCode);
                          hasPermission = res.success;
                          user = res.user;
                        }
                        if (hasPermission) {
                          Navigator.pop(context);
                        } else {
                          // Navigator.pop(context, false);
                        }
                      },

                      // Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      )),
                ],
              ),
              SizedBox(
                height: 10.h,
              ),
              Expanded(
                child: Row(
                  //mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [
                                      // BoxShadow(
                                      //   color: Colors.black,
                                      //   offset: Offset(4.0, 4.0),
                                      //   blurRadius: 4.0,
                                      //   spreadRadius: 0.0,
                                      // )
                                    ]),
                                child: IconButton(
                                  padding: const EdgeInsets.all(0),
                                  color: Colors.black,
                                  onPressed: qrPay
                                      ? null
                                      : () async {
                                          if (!RegExp(r'^\d+\.?\d{0,2}?$')
                                              .hasMatch(amountEditingController
                                                  .text)) {
                                            EasyLoading.showError(
                                                'wrong_format'.tr());
                                            return;
                                          }
                                          if (double.parse(
                                                  amountEditingController
                                                      .text) >
                                              double.parse(balanceDue
                                                  .toStringAsFixed(2))) {
                                            EasyLoading.showError(
                                                'payment_view.no_overpay'.tr());
                                            return;
                                          }
                                          //Call ECR Integration
                                          final ecrAmount =
                                              amountEditingController.text
                                                  .toDouble();
                                          if (ecrAmount == 0) return;

                                          bool validBin = true;
                                          try {
                                            final requiredBins = cartBloc
                                                    .specificPayMode?.cardBin ??
                                                [];
                                            String refString = '';
                                            // bin request & validation for crc promotion related payments
                                            if (requiredBins.length > 0) {
                                              EasyLoading.show(
                                                  status: 'please_wait'.tr());
                                              final EcrResponse? ecrBin =
                                                  await EcrController()
                                                      .binRequest();
                                              EasyLoading.dismiss();
                                              if (ecrBin?.success == true) {
                                                EasyLoading.showInfo(
                                                    "Successfully fetch the card details");
                                                _ecr = true;
                                                formatCardNoFromEcr(
                                                    ecrBin?.ecrCard
                                                            ?.strTxnCardBin ??
                                                        '',
                                                    '****');
                                                _ecrTimer();
                                                if (mounted) {
                                                  setState(() {});
                                                }
                                                validBin = _checkCardBin(
                                                    detailsEditingController
                                                        .text);
                                                if (validBin) {
                                                  refString = ecrBin?.ecrCard
                                                          ?.strBinRef ??
                                                      '';
                                                }
                                              } else {
                                                EasyLoading.showInfo(
                                                    "Something error happens when fetching the card details");
                                                return;
                                              }
                                            }
                                            if (validBin) {
                                              EasyLoading.show(
                                                  status: 'please_wait'.tr());
                                              if (requiredBins.length == 0) {
                                                ecr = await EcrController()
                                                    .doSale(ecrAmount!,
                                                        refNo: refString);
                                              } else {
                                                ecr = await EcrController()
                                                    .binSaleRequest(ecrAmount!,
                                                        refNo: refString);
                                              }
                                              // _ecr = false;
                                              // _ecrTimeOut = 60;
                                              // _timer?.cancel();
                                              EasyLoading.dismiss();
                                            } else {
                                              return;
                                            }
                                            if (ecr != null) {
                                              dueBalanceEditingController.text =
                                                  ecrAmount.toString();
                                              Navigator.pop(context);
                                              return;
                                            }
                                          } catch (e) {
                                            print('An error occurred: $e');
                                          }
                                        },
                                  icon: Image.asset("assets/images/Swipe.png"),
                                ),
                              ),
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [
                                      // BoxShadow(
                                      //   color: Colors.black,
                                      //   offset: Offset(4.0, 4.0),
                                      //   blurRadius: 4.0,
                                      //   spreadRadius: 0.0,
                                      // )
                                    ]),
                                child: IconButton(
                                  padding: const EdgeInsets.all(0),
                                  onPressed: !qrPay
                                      ? null
                                      : () async {
                                          // Action for button 2
                                          if (!RegExp(r'^\d+\.?\d{0,2}?$')
                                              .hasMatch(amountEditingController
                                                  .text)) {
                                            EasyLoading.showError(
                                                'wrong_format'.tr());
                                            return;
                                          }
                                          if (double.parse(
                                                  amountEditingController
                                                      .text) >
                                              balanceDue) {
                                            EasyLoading.showError(
                                                'payment_view.no_overpay'.tr());
                                            return;
                                          }
                                          //Call ECR Integration
                                          final ecrAmount =
                                              amountEditingController.text
                                                  .toDouble();
                                          if (ecrAmount == 0) return;
                                          try {
                                            EasyLoading.show(
                                                status: 'please_wait'.tr());
                                            ecr = await EcrController()
                                                .QrSaleRequest(ecrAmount!,
                                                    refNo: '');
                                            EasyLoading.dismiss();
                                            if (ecr != null) {
                                              Navigator.pop(context);
                                              return;
                                            }
                                          } catch (e) {
                                            print('An error occurred: $e');
                                          }
                                        },
                                  icon: Image.asset("assets/images/Scanme.png"),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Expanded(
                            child: Card(
                              shadowColor: Colors.black,
                              color: CurrentTheme.backgroundColor,
                              elevation: 8.0,
                              child: Container(
                                //height: double.infinity,
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text('Enter the Amount to pay'),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Container(
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: TextField(
                                        onTap: () {
                                          amountEditingController.clear();
                                        },
                                        enabled: true,
                                        style: CurrentTheme.bodyText2!.copyWith(
                                            color: CurrentTheme.primaryColor,
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold),
                                        controller: amountEditingController,
                                        textInputAction: TextInputAction.next,
                                        textAlign: TextAlign.center,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d{0,2}')),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              shadowColor: Colors.black,
                              color: CurrentTheme.backgroundColor,
                              elevation: 8.0,
                              child: Container(
                                //height: 100,
                                width: double.infinity,
                                child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        'Total Outstanding Amount',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 30),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        balanceDue.toStringAsFixed(2),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 50),
                                      ),
                                    ]),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: POSKeyBoard(
                              color: Colors.transparent,
                              onPressed: () {
                                if (amountEditingController.text.length != 0) {
                                  amountEditingController.text =
                                      amountEditingController.text.substring(
                                          0,
                                          amountEditingController.text.length -
                                              1);
                                }
                              },
                              clearButton: true,
                              isInvoiceScreen: false,
                              disableArithmetic: true,
                              onEnter: () {},
                              controller: amountEditingController,
                              normalKeyPress: () {
                                if (amountEditingController.text
                                    .contains('.')) {
                                  var rational = amountEditingController.text
                                      .split('.')[1];
                                  if (rational.length >= 2) {
                                    return 0;
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return ecr;
  }

  /* check customer has vouchers to redeem */
  /* by dinuka 2022/08/17 */
  Future<void> getAvailableCoupons() async {
    var availableCouponsResult = customerCouponBloc.availableCoupons;
    var couponsList = customerCouponBloc.availableCoupons?.couponsList;
    if (availableCouponsResult != null && couponsList!.isNotEmpty) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              scrollable: true,
              content: Column(
                children: [
                  SizedBox(
                    height: 150.h,
                    child: OverflowBox(
                      minHeight: 250.h,
                      maxHeight: 250.h,
                      child: Lottie.asset('assets/lottie/coupon.json',
                          fit: BoxFit.fill),
                    ),
                  ),
                  Text(
                    'customer_coupons_popup_view.title'.tr(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  StreamBuilder(
                      stream: customerCouponBloc.allCouponsList,
                      builder: (context,
                          AsyncSnapshot<CustomerCouponsResult?> snapshot) {
                        if (!snapshot.hasData) return Container();
                        List<Coupons> coupons =
                            snapshot.data?.couponsList ?? [];
                        return DataTable(
                            showCheckboxColumn: false,
                            showBottomBorder: false,
                            columns: [
                              DataColumn(
                                  label: Text(
                                'customer_coupons_popup_view.voucher_no'.tr(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                              DataColumn(
                                  label: Text(
                                'customer_coupons_popup_view.amount'.tr(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                              DataColumn(
                                  label: Text(
                                'customer_coupons_popup_view.expire'.tr(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                            ],
                            rows: [
                              for (var item in coupons) ...[
                                DataRow(
                                  cells: [
                                    DataCell(Text(item.vCVOUCHERNO!)),
                                    DataCell(Text(item.vCVOUCHERVALUE!)),
                                    DataCell(Text(DateFormat("yyyy-MM-dd")
                                        .format(item.vCVALIDUNTIL!)))
                                  ],
                                  onSelectChanged: (value) {
                                    detailsEditingController.text =
                                        item.vCVOUCHERNO ?? '';
                                    dueBalanceEditingController.text =
                                        item.vCVOUCHERVALUE ?? '';
                                    selectedCoupon = item;
                                    Navigator.pop(context);
                                  },
                                ),
                              ]
                            ]);
                      }),
                  SizedBox(
                    height: 10.h,
                  ),
                ],
              ),
            );
          });
    } else {
      EasyLoading.showToast("easy_loading.no_coupon".tr(),
          duration: Duration(seconds: 2), dismissOnTap: true);
      selectedPayModeDetail = null;
      if (mounted) setState(() {});
    }
  }

  void calculateToLocal() {
    currentRate = 1;
  }

  Future<void> _handleLoyalty() async {
    //get loyalty points
    dueBalanceEditingController.text = "0";
    String code = customerBloc.currentCustomer?.cMCODE ?? '';
    bool disableButton = true;
    if (code.isNotEmpty) {
      disableButton = false;

      if (_loyaltyModuleHelper.extLoyaltyModuleActive) {
        _maximumLoyaltyAmount = await _loyaltyModuleHelper
                .pointBalance(customerBloc.currentCustomer?.cMMOBILE ?? '') ??
            0;
      } else {
        final statement = await LoyaltyController().getLoyaltySummary(code);
        if (_maximumLoyaltyAmount <= 0) {
          _maximumLoyaltyAmount = statement?.pOINTSUMMARY ?? 0;
        }
      }
      setState(() {});

      dueBalanceEditingController.text = _maximumLoyaltyAmount.toString();
    }
    if (disableButton) {
      selectedPayModeHeader = null;
      _errorPaymentMode();
    }
    setState(() {});
  }

  void _errorPaymentMode() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return POSErrorAlert(
            title: 'payment_view.invalid_title'.tr(),
            actions: [
              AlertDialogButton(
                  onPressed: () => Navigator.pop(context),
                  text: 'payment_view.okay'.tr())
            ],
            subtitle: 'payment_view.invalid'.tr(),
          );
        });
  }

// this is the default rhs in the app
  Widget buildDefaultRHS() {
    double totalNetDisc = 0;
    double totalLineDisc = 0;
    double netDiscAmount = 0;
    double lineDiscAmtFromPer = 0;
    double lineDiscAmtFromAmt = 0;
    double promoDiscount = (cartBloc.cartSummary?.promoDiscount ?? 0);
    List<CartModel?> item = [];
    cartBloc.currentCart?.forEach((key, value) {
      item.add(value);
    });
    for (int i = 0; i < item.length; i++) {
      if (item.isNotEmpty && (item[i]!.itemVoid! != true)
          // &&
          // (item[i]?.billDiscPer != 0 ||
          //     item[i]?.discPer != 0 ||
          //     item[i]?.discAmt != 0)

          ) {
        double grossAmount =
            (item[i]?.unitQty ?? 0) * (item[i]?.proSelling ?? 0);
        netDiscAmount = ((item[i]?.billDiscPer ?? 0) * grossAmount) / 100;
        lineDiscAmtFromPer = ((item[i]?.discPer ?? 0) * grossAmount) / 100;
        lineDiscAmtFromAmt = (item[i]?.discAmt ?? 0);

        totalNetDisc += netDiscAmount;
        totalLineDisc += (lineDiscAmtFromPer + lineDiscAmtFromAmt);
      }
    }

    return Container(
      child: Column(
        children: [
          Row(
            children: [
              // if (promoDiscount > 0)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _showDiscList,
                        child: buildCard(
                            "payment_view.discount".tr(),
                            (totalLineDisc + totalNetDisc + promoDiscount)
                                .thousandsSeparator(),
                            color: Colors.green),
                      ),
                    ),
                    SizedBox(
                      width: 10.w,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: buildCard("payment_view.sub_total".tr(),
                    subTotal.thousandsSeparator()),
              ),
            ],
          ),
          (selectedPayModeDetail?.pDRATE ?? 0) <= 0
              ? SizedBox.shrink()
              : buildCard(
                  "payment_view.foreign_currency".tr(
                      namedArgs: {"frc": selectedPayModeDetail!.pDCODE ?? ""}),
                  (subTotal / currentRate).roundUp()),
          StreamBuilder<CartSummaryModel>(
              stream: cartBloc.cartSummarySnapshot,
              builder: (context, snapshot) {
                final double taxExc = snapshot.data?.taxExc ?? 0;
                final double taxInc = snapshot.data?.taxInc ?? 0;

                if (taxExc.toDouble() + taxInc.toDouble() == 0) {
                  return SizedBox.shrink();
                }

                /* added comment block t show only the exclusive and NOT Display only tax value */
                //final double tax = taxExc + taxInc;
                /* */
                final double tax = taxExc;

                return GestureDetector(
                  onTap: _showTax,
                  child: buildCard(
                      "payment_view.tax".tr(), tax.thousandsSeparator()),
                );
              }),
          GestureDetector(
              onTap: _showPaidList,
              child: buildCard(
                  "payment_view.paid".tr(), paid.thousandsSeparator())),
          buildCard(
              "payment_view.balance_due".tr(), balanceDue.thousandsSeparator()),
          Container(
              margin: EdgeInsets.symmetric(vertical: spacing.r),
              child: buildTextField()),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: spacing.r),
              child: StreamBuilder(
                  stream: keyBoardBloc.currentPressKeyStream,
                  builder:
                      (BuildContext context, AsyncSnapshot<keyType> snapshot) {
                    return POSKeyBoard(
                        disableArithmetic: true,
                        mask: isFocusPayment ? null : _textMask,
                        onEnter: () {
                          if (selectedPayModeDetail?.pDCODE == "CCOU") {
                            customerCouponBloc.removeCoupon(selectedCoupon);
                          }
                          handleEnterPress();
                        },
                        onPressed: () async {
                          //clear entered values
                          if (selectedPayModeHeader?.pHCODE != "CSH") {
                            if (!emptyMask()) {
                              detailsEditingController.clear();
                              isFocusPayment = false;
                              detailsFocusNode.requestFocus();
                              if (mounted) setState(() {});
                            }
                            dueBalanceEditingController.clear();
                          } else {
                            //if the pressed button is exact
                            if (mounted)
                              setState(() {
                                dueBalanceEditingController.text =
                                    balanceDue.toStringAsFixed(2);
                              });
                            await handleEnterPress();
                            //billClose();
                          }
                        },
                        isInvoiceScreen: true,
                        clearButton: selectedPayModeHeader?.pHCODE != "CSH",
                        controller: !isFocusPayment
                            ? detailsEditingController
                            : dueBalanceEditingController);
                  }),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard(String title, String amount, {Color? color}) {
    return Container(
      width: double.infinity,
      height: height.h,
      margin: EdgeInsets.symmetric(vertical: spacing.r),
      child: Card(
        color: color ?? CurrentTheme.primaryColor,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
          child: Row(
            children: [
              Spacer(),
              Text(
                title,
                style: CurrentTheme.headline6!.copyWith(
                    color: CurrentTheme.primaryLightColor,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 10.w,
              ),
              Container(
                child: Text(
                  amount,
                  textAlign: TextAlign.end,
                  style: CurrentTheme.headline6!
                      .copyWith(color: CurrentTheme.primaryLightColor),
                ),
              ),
              SizedBox(
                width: 10.w,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField() {
    return Row(
      children: [
        maskField(),
        Expanded(
          child: OverlayTutorialHole(
            enabled: true,
            overlayTutorialEntry: OverlayTutorialRectEntry(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              radius: const Radius.circular(16.0),
              overlayTutorialHints: <OverlayTutorialWidgetHint>[
                OverlayTutorialWidgetHint(
                  position: (rect) => Offset(0, rect.bottom),
                  builder: (context, entryRect) {
                    return Column(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Enter gift voucher number here',
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                            onPressed: () {
                              showTutorial(false);
                            },
                            child: Text('Got it'))
                      ],
                    );
                  },
                ),
              ],
            ),
            child: TextField(
              key: keyTextField,
              readOnly: isMobile,
              focusNode: balanceFocus,
              onEditingComplete: () => handleEnterPress(),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                filled: true,
              ),
              onTap: () {
                dueBalanceEditingController.clear();
                if (mounted) {
                  setState(() {
                    isFocusPayment = true;
                  });
                }
              },
              controller: dueBalanceEditingController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                if (selectedPayModeHeader?.isGv != true)
                  FilteringTextInputFormatter.allow(CommonRegExp.decimalRegExp),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget maskField() {
    if (selectedPayModeDetail == null)
      return SizedBox.shrink();
    else {
      final detail = selectedPayModeDetail!;
      if (emptyMask()) {
        return SizedBox.shrink();
      }

      final mask = detail.pdMask;
      var maskFormatter = new MaskTextInputFormatter(
          mask: mask, filter: {"0": RegExp(r'[0-9]')});

      return Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextFormField(
              readOnly: isMobile,
              onEditingComplete: () {
                detailsFocusNode.unfocus();
                matchResult(detailsEditingController.text);
                balanceFocus.requestFocus();
              },
              onTap: () {
                if (mounted) {
                  setState(() {
                    isFocusPayment = false;
                  });
                }
              },
              focusNode: detailsFocusNode,
              decoration: InputDecoration(
                  filled: true,
                  hintText: mask,
                  suffixIcon: Container(
                    height: 35.h,
                    child: CachedNetworkImage(
                      imageUrl: POSConfig().posImageServer +
                          "images/bank/" +
                          (enteredCard?.crDHEDDESC ?? "") +
                          ".png",
                      httpHeaders: {'Access-Control-Allow-Origin': '*'},
                      errorWidget: (context, url, error) => SizedBox.shrink(),
                      placeholder: (context, url) => SizedBox.shrink(),
                    ),
                  )),
              onChanged: (value) {
                detailsEditingController.selection = TextSelection.fromPosition(
                    TextPosition(offset: detailsEditingController.text.length));
              },
              controller: detailsEditingController,
              inputFormatters: [maskFormatter],
            ),
          ));
    }
  }

  void _ecrDialog(BuildContext _context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('ecr.read'.tr()),
            actions: <Widget>[
              AlertDialogButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    EasyLoading.show(status: 'please_wait'.tr());
                    final EcrResponse? ecr = await EcrController().binRequest();
                    EasyLoading.dismiss();
                    if (ecr?.success == true) {
                      EasyLoading.showInfo(
                          "Successfully fetch the card details");
                      _ecr = true;
                      formatCardNoFromEcr(
                          ecr?.ecrCard?.strTxnCardBin ?? '', '****');
                      _ecrTimer();
                      if (mounted) {
                        setState(() {});
                      }

                      //TODO: handle promotion
                    } else {
                      String error = ecr?.ecrCard?.strErrorDesc ?? '';
                      if (error.isEmpty) {
                        error =
                            'Unknown Error - ${ecr?.ecrCard?.strErrorCode ?? ''}';
                      }
                      EasyLoading.showError(error);
                    }
                  },
                  text: 'ecr.yes'.tr()),
              AlertDialogButton(
                  onPressed: () => Navigator.pop(context), text: 'ecr.no'.tr())
            ],
          );
        });
  }

  String formatCardNoFromEcr(String bin, String last) {
    if (bin.isNotEmpty) {
      if (bin.length == 6) {
        bin = bin.substring(0, 4) + '-' + bin.substring(4, 6) + '**-****-$last';
      }
      if (bin.length == 16) {
        bin = bin.substring(0, 4) +
            '-' +
            bin.substring(4, 6) +
            '**-****-' +
            bin.substring(12, 16);
      }
    }
    detailsEditingController.text = bin;
    return bin;
  }

  void matchResult(String text) {
    String formatted = text.replaceAll("-", "");

    if (formatted.length > 6) {
      formatted = formatted.substring(0, 6);
    }
    final list = payModeBloc.cardDetailsList;
    int index = list
        .indexWhere((CardDetails element) => element.crDSTRING == formatted);
    if (index == -1) return null;
    final card = list[index];
    print('entered card details: ${card.crDHEDDESC} - ${card.crDPROVIDER}');
    setState(() {
      enteredCard = card;
      detailsEditingController.text = text;
    });
  }

  void _showTax() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'tax.tax_title'.tr(),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(width: double.infinity, child: TaxBreakdownView()),
        );
      },
    );
  }

  void _showPaidList() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'paid_list.pay_title'.tr(),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(width: double.infinity, child: PaymentBreakdown()),
        );
      },
    );
  }

  void _showDiscList() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'discount_list.disc_title'.tr(),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(width: double.infinity, child: DiscountBreakdown()),
        );
      },
    );
  }

  Future<void> _handleReferencedPayMode(double amount) async {
    String reference = selectedPayModeHeader?.reference ?? '';
    switch (reference.toLowerCase()) {
      case 'lankaqr':
        if (POSConfig().dualScreenWebsite != "")
          DualScreenController().sendLankaQr(amount);
        break;
      default:
        if (mounted) {
          selectedPayModeHeader = null;
        }
        _errorPaymentMode();
    }
  }
}
