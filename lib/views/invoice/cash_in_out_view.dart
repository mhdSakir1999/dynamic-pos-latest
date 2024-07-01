/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 7/9/21, 2:36 PM
 */

import 'package:checkout/bloc/paymode_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/recurringApiCalls.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/components/widgets/pay_button.dart';
import 'package:checkout/components/widgets/poskeyboard.dart';
import 'package:checkout/controllers/cash_in_out_controller.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/local_storage_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/controllers/pos_manual_print_controller.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/models/pos/card_details_result.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cash_in_out_result.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos/payment_mode.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/invoice/invoice_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:supercharged/supercharged.dart';
import 'package:checkout/extension/extensions.dart';

class CashInOutView extends StatefulWidget {
  final bool cashIn;
  final String invoiceNo;
  final CashInOutResult cashInOutResult;

  const CashInOutView(
      {Key? key,
      required this.cashIn,
      required this.invoiceNo,
      required this.cashInOutResult})
      : super(key: key);

  @override
  _CashInOutViewState createState() => _CashInOutViewState();
}

class _CashInOutViewState extends State<CashInOutView> {
  final TextEditingController amountEditingController = TextEditingController();
  final TextEditingController detailsEditingController =
      TextEditingController();
  final TextEditingController remarkEditingController = TextEditingController();
  final amountFocus = FocusNode();
  final detailsFocusNode = FocusNode();
  final remarkFocus = FocusNode();
  PayModeHeader? selectedPayModeHeader;
  PayModeDetails? selectedPayModeDetail;
  CashInOutType? selectedCashInOutType;
  final Color selectedColor = CurrentTheme.backgroundColor!;
  String invoiceNo = "";
  bool active = false;
  LocalStorageController _localStorageController = LocalStorageController();
  @override
  void initState() {
    super.initState();
    invoiceNo = widget.invoiceNo;
    amountFocus.requestFocus();
    Future.delayed(Duration(seconds: 1)).then((value) {
      if (mounted)
        setState(() {
          active = true;
        });
    });
  }

  @override
  void dispose() {
    amountFocus.dispose();
    remarkFocus.dispose();
    amountEditingController.dispose();
    remarkEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    KeyBoardController().init(context);
    return POSBackground(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: buildBody(),
    ));
  }

  Widget buildBody() {
    return Column(
      children: [
        POSInvoiceAppBar(
          overrideInvoiceNo: invoiceNo,
          showCustomer: false,
        ),
        SizedBox(
          height: 8.h,
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: buildLHS()),
              SizedBox(
                width: 8.w,
              ),
              Expanded(child: buildRHS()),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildRHS() {
    return Column(
      children: [
        SizedBox(
          height: 8.h,
        ),
        Expanded(child: buildCashInOutButtonList()),
        SizedBox(
          height: 8.h,
        ),
        Expanded(
          child: POSKeyBoard(
            onEnter: () {
              if (mounted && active) handleEnter();
            },
            onPressed: () {
              if (mounted && active) clear();
            },
            isInvoiceScreen: false,
            clearButton: true,
            controller: amountEditingController,
          ),
        )
      ],
    );
  }

  Widget buildLHS() {
    return Column(
      children: [
        SizedBox(
          height: 8.h,
        ),
        Card(
          color: CurrentTheme.primaryColor,
          margin: EdgeInsets.zero,
          child: Container(
              width: double.infinity,
              height: 60.h,
              alignment: Alignment.center,
              child: Row(
                children: [
                  SizedBox(
                    width: 8.w,
                  ),
                  GoBackIconButton(),
                  Spacer(),
                  Text(
                    "cash_in_out_view.${widget.cashIn ? "cash_in" : "cash_out"}"
                        .tr(),
                    style: CurrentTheme.headline6!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                ],
              )),
        ),
        SizedBox(
          height: 8.h,
        ),
        Container(
          child: TextField(
            focusNode: amountFocus,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
            ],
            onEditingComplete: () {
              // KeyBoardController().dismiss();
              // setState(() {
              // KeyBoardController().showBottomDPKeyBoard(remarkEditingController,
              //     onEnter: () {
              //   KeyBoardController().dismiss();
              //   handleEnter();
              // }, buildContext: context);
              // remarkFocus.requestFocus();
              // });
              if (selectedPayModeDetail != null &&
                  (selectedPayModeDetail?.pdMask ?? '').isNotEmpty) {
                detailsFocusNode.requestFocus();
              } else {
                remarkFocus.requestFocus();
              }
            },
            onTap: () async {
              await KeyBoardController().showBottomDPKeyBoard(
                  amountEditingController, onEnter: () async {
                KeyBoardController().dismiss();
                if (selectedPayModeDetail != null &&
                    (selectedPayModeDetail?.pdMask ?? '').isNotEmpty) {
                  detailsFocusNode.requestFocus();
                } else {
                  remarkFocus.requestFocus();
                }
                // setState(() {
                await KeyBoardController()
                    .showBottomDPKeyBoard(remarkEditingController, onEnter: () {
                  KeyBoardController().dismiss();
                  if (POSConfig().touchKeyboardEnabled) {
                    Navigator.pop(context);
                  }
                  handleEnter();
                }, buildContext: context);
                // });
              }, buildContext: context);
            },
            controller: amountEditingController,
            decoration: InputDecoration(
                filled: true, hintText: "cash_in_out_view.amount".tr()),
          ),
        ),
        maskField(),
        SizedBox(
          height: 8.h,
        ),
        Container(
          child: TextField(
            onEditingComplete: () {
              KeyBoardController().dismiss();
              handleEnter();
            },
            // onChanged: (value) {
            //   if (value.contains("\n")) {
            //     KeyBoardController().dismiss();
            //     handleEnter();
            //   }
            // },
            onTap: () {
              KeyBoardController().showBottomDPKeyBoard(remarkEditingController,
                  onEnter: () {
                KeyBoardController().dismiss();
                handleEnter();
              }, buildContext: context);
            },
            focusNode: remarkFocus,
            controller: remarkEditingController,
            minLines: 3,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
                filled: true, hintText: "cash_in_out_view.remark".tr()),
          ),
        ),
        SizedBox(
          height: 8.h,
        ),
        Expanded(child: buildPaymentButtonList()),
      ],
    );
  }

  Widget buildPaymentButtonList() {
    if ((selectedPayModeHeader?.pDDETAILSLIST?.length ?? 0) == 0)
      return buildPaymentButtonHeaderList();
    return buildPaymentButtonDetailList();
  }

  Widget buildCashInOutButtonList() {
    final config = POSConfig();
    return ResponsiveGridList(
      scroll: true,
      desiredItemWidth: config.paymentDynamicButtonWidth.w,
      children: (widget.cashInOutResult.cashInOutType ?? []).map((payButton) {
        bool selected = selectedCashInOutType?.rWCODE == payButton.rWCODE;
        return PayButton(
          code: payButton.rWCODE ?? "",
          desc: payButton.rWDESC ?? "",
          color: selected ? selectedColor : CurrentTheme.primaryColor,
          onPressed: () {
            POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
                "${payButton.rWCODE}(${payButton.rWDESC}) button pressed"));
            selectedCashInOutType = selected ? null : payButton;
            if (mounted) setState(() {});
          },
        );
      }).toList(),
    );
  }

  Widget buildPaymentButtonHeaderList() {
    final config = POSConfig();
    return Container(
      child: StreamBuilder<PayModeResult?>(
          stream: payModeBloc.payModeSnapshot,
          builder: (context, AsyncSnapshot<PayModeResult?> snapshot) {
            if (!snapshot.hasData) return Container();
            // List<PayModeHeader> dynamicButtonList = snapshot.data?.payModes
            //         ?.where((element) =>
            //             element.pHCODE == 'CSH' || element.pHCODE == 'CRC')
            //         .toList() ??
            //     [];
            List<PayModeHeader> dynamicButtonList = [];
            if (widget.cashIn == true) {
              dynamicButtonList = snapshot.data?.payModes
                      ?.where((element) => element.pHCASHINOUT == true)
                      .toList() ??
                  [];
            } else {
              dynamicButtonList = snapshot.data?.payModes
                      ?.where((element) =>
                          element.pHCASHINOUT == true &&
                          (element.pHCODE == 'CSH' || element.pHCODE == 'FCR'))
                      .toList() ??
                  [];
            }
            return ResponsiveGridList(
              scroll: true,
              desiredItemWidth: config.paymentDynamicButtonWidth.w,
              children: dynamicButtonList.map((payButton) {
                // bool disabled =
                //     payButton.pHCODE != "CSH" && payButton.pHCODE != "CRC";
                bool selected =
                    selectedPayModeHeader?.pHCODE == payButton.pHCODE;
                // if (disabled) return SizedBox.shrink();
                return PayButton(
                  code: payButton.pHCODE ?? "",
                  desc: payButton.pHDESC ?? "",
                  color: false
                      ? POSConfig().primaryDarkGrayColor.toColor()
                      : selected
                          ? selectedColor
                          : CurrentTheme.primaryColor,
                  onPressed: () {
                    // if (disabled) return;
                    POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
                        "${payButton.pHDESC}(${payButton.pHCODE}) button pressed"));
                    selectedPayModeHeader = selected ? null : payButton;
                    if (mounted) setState(() {});
                  },
                );
              }).toList(),
            );
          }),
    );
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
          Color? color = payButton.pDPHCODE == selectedPayModeHeader?.pHCODE &&
                  payButton.pDCODE == selectedPayModeDetail?.pDCODE
              ? CurrentTheme.accentColor
              : CurrentTheme.primaryColor;

          return PayButton(
            code: payButton.pDCODE ?? "",
            desc: payButton.pDDESC ?? "",
            color: color,
            onPressed: () async {
              POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
                  "${payButton.pDDESC}(${payButton.pDCODE}) button pressed"));

              if (payButton.pDCODE == "go_back") {
                selectedPayModeDetail = null;
                selectedPayModeHeader = null;
              } else {
                selectedPayModeDetail = payButton;
              }
              if (mounted) setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }

  Widget maskField() {
    if (selectedPayModeDetail == null)
      return const SizedBox.shrink();
    else {
      final detail = selectedPayModeDetail!;
      if ((detail.pdMask ?? '').isEmpty) {
        return const SizedBox.shrink();
      }

      final mask = detail.pdMask;
      var maskFormatter = new MaskTextInputFormatter(
          mask: mask, filter: {"0": RegExp(r'[0-9]')});

      return Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: TextFormField(
          onEditingComplete: () {
            matchResult(detailsEditingController.text);
            remarkFocus.requestFocus();
          },
          focusNode: detailsFocusNode,
          decoration: InputDecoration(
            filled: true,
            hintText: mask,
          ),
          onChanged: (value) {
            detailsEditingController.selection = TextSelection.fromPosition(
                TextPosition(offset: detailsEditingController.text.length));
          },
          controller: detailsEditingController,
          inputFormatters: [maskFormatter],
        ),
      );
    }
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
      // enteredCard = card;
      detailsEditingController.text = text;
    });
  }
  // Widget buildPaymentButtonDetailList() {
  //   var buttonList = selectedPayModeHeader?.pDDETAILSLIST ?? [];
  //   if (selectedPayModeDetail == null) {
  //     final index =
  //     buttonList.indexWhere((element) => element.pDCODE == "go_back");
  //     if (index == -1)
  //       buttonList.add(PayModeDetails(
  //           pDCODE: "go_back", pDDESC: "payment_view.go_back".tr()));
  //   }
  //
  //   final config = POSConfig();
  //   return Container(
  //     child: ResponsiveGridList(
  //       scroll: true,
  //       desiredItemWidth: config.paymentDynamicButtonWidth.w,
  //       children: buttonList.map((payButton) {
  //         return PayButton(
  //           code: payButton.pDCODE ?? "",
  //           desc: payButton.pDDESC ?? "",
  //           onPressed: () {
  // POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
  //     "${payButton.pDDESC}(${payButton.pDCODE}) button pressed"));

  // if (payButton.pDCODE == "go_back") {
  //   selectedPayModeDetail = null;
  //   selectedPayModeHeader = null;
  // }
  // if (mounted) setState(() {});
  //           },
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  ///clear the entered values
  void clear() {
    amountEditingController.clear();
    remarkEditingController.clear();
    remarkFocus.unfocus();
    amountFocus.unfocus();
    selectedCashInOutType = null;
    selectedPayModeHeader = null;
    if (mounted) setState(() {});
  }

  ///handle enter button press
  void handleEnter() async {
    //validation process

    // check cash type first
    if (selectedPayModeHeader == null && selectedPayModeDetail == null) {
      showAlert("pay_mode_required");
      return;
    }
    // cash in out type
    if (selectedCashInOutType == null) {
      showAlert("type_required");
      return;
    }
    // so far no validation issue then convert amounts
    double amount = amountEditingController.text.parseDouble();

    if (amount == 0) {
      showAlert("amount_required");
      return;
    }

    // if (selectedPayModeDetail != null &&
    //     (detailsEditingController.text ?? '').isEmpty) {
    //   showAlert("payment_details_required");
    //   return;
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
    // if it is the advanced payment then the remark field is mendetory
    if (selectedCashInOutType?.rWADVANCE == 1 &&
        remarkEditingController.text.isEmpty) {
      showAlert("remark_required");
      return;
    }

    if (!widget.cashIn) {
      var phyCshRes = await RecurringApiCalls().getCashDetails();
      if (phyCshRes != null) {
        double cashSales = phyCshRes[0]['sales'] ?? 0;
        double cashouts = phyCshRes[0]['cashOuts'] ?? 0;
        double remainingCash = cashSales - cashouts;

        if (amount > remainingCash) {
          EasyLoading.showError(
              'Drawer amount is lower than entered amount\nCannot do cashouts !!!');
          return;
        }
      } else {
        EasyLoading.showError(
            'Something error happened when calculating available cash amount !!!');
      }
    }

    // continue the cash in out option
    final cartModel = CartModel(
        setUpLocation: POSConfig().setupLocation,
        proCode: selectedCashInOutType?.rWCODE ?? "",
        stockCode: "",
        posDesc: selectedCashInOutType?.rWDESC ?? "",
        proSelling: 0,
        selling: amount,
        unitQty: 1,
        amount: amount,
        noDisc: false,
        billDiscAmt: 0,
        discountReason: remarkEditingController.text,
        discPer: 0,
        discAmt: 0,
        proAvgCost: 0,
        proCost: 0,
        itemVoid: false,
        maxDiscAmt: 0,
        maxDiscPer: 0,
        proCaseSize: 0,
        billDiscPer: 0,
        caseFreeQty: 0,
        caseQty: 0,
        freeQty: 0,
        lineNo: 1,
        proUnit: "",
        saleman: "",
        lineRemark: [],
        unitFreeQty: 0,
        scanBarcode: "")
      ..key = "";

    Map<String, dynamic> res = await CashInOutController().saveCashInOut(
      cashIn: widget.cashIn,
      cart: cartModel,
      paidModel: PaidModel(
          amount,
          amount,
          false,
          selectedPayModeDetail?.pDCODE ?? selectedPayModeHeader?.pHCODE ?? "",
          selectedPayModeHeader?.pHCODE ?? "",
          selectedPayModeDetail?.pdMask ?? "",
          null,
          selectedPayModeDetail?.pDRATE ?? 0,
          selectedPayModeDetail?.pDDESC ?? selectedPayModeHeader?.pHDESC ?? "",
          selectedPayModeHeader?.pHDESC ?? "",
          frAmount: 0),
      invoice: invoiceNo,
    );
    //
    if (res['status'] == true) {
      if (POSConfig.crystalPath != '') {
        PrintController().cashIn(
          invoiceNo,
          widget.cashIn,
        );
      } else {
        POSManualPrint().printCashReceiptSlip(
            data: res['returnRes'],
            cashIn: widget.cashIn,
            runno: invoiceNo,
            isAdvance: selectedCashInOutType?.rWADVANCE == 1);
      }

      EasyLoading.showSuccess('easy_loading.success_save'.tr());
      // invoiceNo = await CashInOutController().getInvoiceNo(widget.cashIn);
      await _localStorageController.setWithdrawal(invoiceNo);
      //clear the fields
      clear();

      Navigator.pop(context);
    } else {
      EasyLoading.showError('Something went wrong');
    }
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

  void showAlert(String key) {
    showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: "cash_in_out_view.$key".tr(),
          subtitle: "",
          actions: [
            AlertDialogButton(
              text: 'cash_in_out_view.okay'.tr(),
              onPressed: () => Navigator.pop(context),
            )
          ]),
    );
  }
}
