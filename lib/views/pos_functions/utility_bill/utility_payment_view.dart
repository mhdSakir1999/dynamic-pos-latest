/// Copyright © 2021 myPOS Software Solutions.  All rights reserved.
/// Author: [TM.Sakir]
/// Payment view for utility bills

import 'dart:async';

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
import 'package:checkout/controllers/otp_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/models/enum/keyboard_type.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/ecr_response.dart';
import 'package:checkout/models/pos/gift_voucher_result.dart';
import 'package:checkout/models/pos/payment_mode.dart';
import 'package:checkout/models/pos/card_details_result.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/models/utility_bill/utility_ui_results.dart';
import 'package:checkout/views/invoice/payment_breakdown.dart';
import 'package:checkout/views/invoice/tax_breakdown_view.dart';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:overlay_tutorial/overlay_tutorial.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:supercharged/supercharged.dart';

import '../../../controllers/sms_controller.dart';
import '../../../controllers/special_permission_handler.dart';
import '../../../models/loyalty/customer_coupons_result.dart';
import '../../../models/pos/permission_code.dart';
import '../../invoice/invoice_app_bar.dart';

class UtilityBillPaymentView extends StatefulWidget {
  static const routeName = "payment_view";
  final dynamic dataMap;
  final UtilityData utilityData;
  const UtilityBillPaymentView(
      {Key? key, required this.dataMap, required this.utilityData})
      : super(key: key);

  @override
  _UtilityBillPaymentViewState createState() => _UtilityBillPaymentViewState();
}

class _UtilityBillPaymentViewState extends State<UtilityBillPaymentView> {
  double height = 60;
  PayModeHeader? selectedPayModeHeader;
  PayModeDetails? selectedPayModeDetail;
  TextEditingController dueBalanceEditingController = TextEditingController();
  TextEditingController detailsEditingController = TextEditingController();
  double paid = 0;
  final focusNode = FocusNode();
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
  List<PayModeHeader> payModes = [];
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
    payModes = payModeBloc.payModeResult?.payModes
            ?.where((element) => element.pHCODE == widget.utilityData.phCode)
            .toList() ??
        [];
    int defaultPayModeIndex = payModes
        .indexWhere((element) => element.pHCODE == widget.utilityData.phCode);
    if (defaultPayModeIndex != -1) {
      selectedPayModeHeader = payModes[defaultPayModeIndex];
    }
    saving = absolute - lineTotal;

    // DualScreenController()
    //     .sendPayment(paid.toDouble(), subTotal.toDouble(), saving.toDouble());
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
      paid += element.paidAmount;
    });
    subTotal = cartBloc.cartSummary?.subTotal ?? 0;
    balanceDue = subTotal - paid;
    if (list.length != 0) {
      loaded = true;
    }
    DualScreenController()
        .sendPayment(paid.toDouble(), subTotal.toDouble(), saving.toDouble());
    if (mounted) setState(() {});
  }

  bool active = false;

  void viewListeners() {
    POSPriceCalculator().taxCalculation();
    cartBloc.cartSummarySnapshot.listen((event) {
      subTotal = event.subTotal;
      if (!loaded) balanceDue = event.subTotal;
      loaded = true;
      if (selectedPayModeHeader?.defaultPaymentMode == true) {
        dueBalanceEditingController.text = balanceDue.toStringAsFixed(2);
      }

      if (mounted) setState(() {});
    });

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
      child: RawKeyboardListener(
        autofocus: true,
        onKey: (value) {
          if (value.logicalKey == LogicalKeyboardKey.escape) {
            if (mounted)
              setState(() {
                dontPop = selectedPayModeHeader?.pHDETAIL ?? false;
                selectedPayModeHeader = null;
                selectedPayModeDetail = null;
              });
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

  void handleCalculation() async {
    double entered =
        dueBalanceEditingController.text.parseDouble() * currentRate;
    double temp = balanceDue - entered;

    temp = double.parse(temp.toStringAsFixed(2));
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
        detailsEditingController.text == '') {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.error, "Enter a valid card number"));
      showCardNoNotEnteredErrorDialog();
      return;
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

    final balanceDueTemp = balanceDue;
    entered = dueBalanceEditingController.text.parseDouble() * currentRate;
    temp = balanceDue - entered;

    balanceDue = temp;

    paid += entered;
    String phCode = selectedPayModeHeader?.pHCODE ?? "";
    String pdCode = selectedPayModeDetail?.pDCODE ?? phCode;
    String phDesc = selectedPayModeHeader?.pHDESC ?? "";
    String pdDesc = selectedPayModeDetail?.pDDESC ?? phDesc;
    final tot = cartBloc.cartSummary?.subTotal ?? 0;
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
        isGv: selectedPayModeHeader?.isGv ?? false,
        pointRate: selectedPayModeHeader?.pointRate ?? 0));
    dueBalanceEditingController.clear();
    detailsEditingController.clear();
    _ecr = false;

    if (selectedPayModeHeader?.isGv == true && balanceDue > 0) {
    } else {
      // selectedPayModeDetail = null;
      // selectedPayModeHeader = null;
    }
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
    Navigator.pop(context, false);
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
        Expanded(child: Scrollbar(child: buildPaymentButtonList())),
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
    if ((balanceDue * 100).truncate() / 100 > 0) {
      showDialog(
        context: context,
        builder: (context) {
          return POSErrorAlert(
              title: "due_amount_error.title".tr(),
              subtitle: "due_amount_error.subtitle"
                  .tr(namedArgs: {"due": balanceDue.toStringAsFixed(3)}),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor()),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "due_amount_error.okay".tr(),
                    style: Theme.of(context).dialogTheme.contentTextStyle,
                  ),
                )
              ]);
        },
      );
      return;
    } else {
      Navigator.pop(context, true);
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
      bool taxbill) async {
    await PrintController().printHandler(
        invoiceNo,
        PrintController()
            .printInvoice(invoiceNo, earnedPoints, totalPoints, taxbill, null),
        context);
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

  Widget buildPaymentButtonHeaderList() {
    final config = POSConfig();
    return Container(
      child: ListView.builder(
          itemCount: payModes.length,
          itemBuilder: ((context, index) {
            List<PayModeHeader> dynamicButtonList = payModes;
            return ResponsiveGridList(
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
          })),

      // StreamBuilder<PayModeResult?>(
      //     stream: payModeBloc.payModeSnapshot,
      //     builder: (context, AsyncSnapshot<PayModeResult?> snapshot) {
      //       if (!snapshot.hasData) return Container();
      // List<PayModeHeader> dynamicButtonList =
      //     snapshot.data?.payModes ?? [];
      // return ResponsiveGridList(
      //   scroll: true,
      //   desiredItemWidth: config.paymentDynamicButtonWidth.w,
      //   children: dynamicButtonList.map((payButton) {
      //     bool clickable = true;
      //     final specificPayMode = cartBloc.specificPayMode;
      //     if (specificPayMode != null) {
      //       if (specificPayMode.phCode != payButton.pHCODE) {
      //         clickable = false;
      //       }
      //     }
      //     Color? color = payButton.pHCODE == selectedPayModeHeader?.pHCODE
      //         ? CurrentTheme.accentColor
      //         : CurrentTheme.primaryColor;
      //     if (!clickable) {
      //       color = color?.withOpacity(0.5);
      //     }
      //     return PayButton(
      //       code: payButton.pHCODE ?? "",
      //       desc: payButton.pHDESC ?? "",
      //       color: color,
      //       onPressed: () {
      //         if (clickable) {
      //           onPayModeHeadClick(payButton);
      //         }
      //       },
      //     );
      //   }).toList(),
      // );
      //     }),
    );
  }

  Future<void> onPayModeHeadClick(PayModeHeader payButton) async {
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

    // //disable gv module
    // if (payButton.isGv == true) {
    //   if ((POSConfig().clientLicense?.lCMYVOUCHERS != true ||
    //       POSConfig().expired)) {
    //     ActivationController().showModuleBuy(context, "myVouchers");
    //     return;
    //   }
    //   //show tutorial
    //   //showTutorial(true);
    //   if (POSConfig().localMode && payButton.pHLOCALMODE == true) {
    //     EasyLoading.showError('local_mode_func_disable'.tr());
    //     return;
    //   }
    //   dueBalanceEditingController.text = '';
    // }

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
    var buttonList = selectedPayModeHeader?.pDDETAILSLIST
            ?.where((element) => element.pDCODE == widget.utilityData.pdCode)
            .toList() ??
        [];
    // if (selectedPayModeDetail == null) {
    //   final index =
    //       buttonList.indexWhere((element) => element.pDCODE == "go_back");
    //   if (index == -1)
    //     buttonList.add(PayModeDetails(
    //         pDCODE: "go_back", pDDESC: "payment_view.go_back".tr()));
    // }

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
                    await singleSwipeAlert(false, balanceDue);
                if (ecrResponse == null)
                  print("Switchiing to manual mode");
                else {
                  if (ecrResponse.ecrCard != null)
                    cartBloc.addNewReference(ecrResponse.ecrCard!);
                  formatCardNoFromEcr(
                      ecrResponse.ecrCard?.strTxnCardBin ?? '', '****');
                  dueBalanceEditingController.text =
                      balanceDue.toStringAsFixed(2);
                  handleCalculation();
                }
              }
              if (mounted) setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }

//Single Swipe Alert dialog box
  Future<EcrResponse?> singleSwipeAlert(
      bool doBinRequest, double payAmount) async {
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
                    'ECR Intergrator',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                      alignment: Alignment.centerRight,
                      onPressed: () => Navigator.pop(context),
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
                                  onPressed: () async {
                                    //Call ECR Integration
                                    final ecrAmount =
                                        amountEditingController.text.toDouble();
                                    if (ecrAmount == 0) return;
                                    EasyLoading.show(
                                        status: 'please_wait'.tr());
                                    try {
                                      ecr = await EcrController()
                                          .doSale(ecrAmount!);

                                      // _ecr = false;
                                      // _ecrTimeOut = 60;
                                      // _timer?.cancel();
                                      EasyLoading.dismiss();
                                      if (ecr != null) {
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
                                  onPressed: () {
                                    // Action for button 2
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
                                      child: TextFormField(
                                        enabled: true,
                                        style: CurrentTheme.bodyText2!.copyWith(
                                            color: CurrentTheme.primaryColor,
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold),
                                        controller: amountEditingController,
                                        textInputAction: TextInputAction.next,
                                        textAlign: TextAlign.center,
                                        onChanged: (String value) {
                                          //if (mounted) setState(() {});
                                        },
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
                              onPressed: () {},
                              clearButton: true,
                              isInvoiceScreen: false,
                              disableArithmetic: true,
                              onEnter: () {},
                              controller: amountEditingController,
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

  void calculateToLocal() {
    currentRate = 1;
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
    double discount = (cartBloc.cartSummary?.promoDiscount ?? 0);
    return Container(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: buildCard("payment_view.sub_total".tr(),
                    subTotal.thousandsSeparator()),
              ),
              if (discount > 0)
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10.w,
                      ),
                      Expanded(
                        child: buildCard("payment_view.discount".tr(),
                            discount.thousandsSeparator(),
                            color: Colors.green),
                      ),
                    ],
                  ),
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
                      EasyLoading.showInfo("easy_loading.success_card".tr());
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

  Future<void> _handleReferencedPayMode(double amount) async {
    String reference = selectedPayModeHeader?.reference ?? '';
    switch (reference.toLowerCase()) {
      case 'lankaqr':
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
