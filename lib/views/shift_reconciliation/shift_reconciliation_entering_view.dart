/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/28/21, 1:30 PM
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/components/widgets/poskeyboard.dart';
import 'package:checkout/controllers/denomination_controller.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/pos/pos_denomination_model.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:supercharged/supercharged.dart';

class ShiftReconciliationEntryView extends StatefulWidget {
  static const routeName = "shift_reconciliation_entering_view";
  final List<POSDenominationModel> denominationsList;
  final bool spotCheck;
  final String? approvedUser;
  final bool pendingSignoff;
  const ShiftReconciliationEntryView(
      {Key? key,
      required this.denominationsList,
      this.spotCheck = false,
      this.approvedUser,
      this.pendingSignoff = false})
      : super(key: key);

  @override
  _ShiftReconciliationEntryViewState createState() =>
      _ShiftReconciliationEntryViewState();
}

class _ShiftReconciliationEntryViewState
    extends State<ShiftReconciliationEntryView> {
  final itemCodeFocus = FocusNode();
  double height = 60;
  TextEditingController textEditingController = TextEditingController();
  double spacing = 3;

  double totalCash = 0;
  double totalNonCash = 0;

  POSDenominationModel? selectedDenomination;
  List<POSDenominationModel> denominationsList = [];
  List<TextEditingController> controllerList = [];
  List<FocusNode> focusNodeList = [];
  int selectedDenominationIndex = -1;
  FocusNode textFieldFocus = FocusNode();
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    denominationsList = widget.denominationsList;
  }

  @override
  Widget build(BuildContext context) {
    handleCalculation();
    return POSBackground(
        child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildBody(),
      ),
    ));
  }

  Widget buildBody() {
    return Column(
      children: [POSAppBar(), Expanded(child: buildContent())],
    );
  }

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

  // this is the default lhs in the app
  Widget buildDefaultLHS() {
    final textStyle =
        CurrentTheme.bodyText2!.copyWith(color: CurrentTheme.primaryColor);
    final user =
        !widget.pendingSignoff ? userBloc.currentUser : userBloc.pendingUser;
    String name = user?.uSERHEDTITLE ?? '';
    final shiftNo = user?.shiftNo ?? "";
    final len = selectedDenomination?.denominations.length ?? 0;
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: height.h,
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 1.r),
              child: Row(
                children: [
                  GoBackIconButton(
                    onPressed: handleBackButtonPress,
                  ),
                  Text(
                    "shift_reconciliation_view.title".tr(),
                    style: textStyle,
                  ),
                  Spacer(),
                  // new change -- showing user code
                  buildShiftCard(user?.uSERHEDUSERCODE ?? '', textStyle,
                      Color(0xFFfff2cc)),
                  SizedBox(
                    width: 2.h,
                  ),
                  buildShiftCard(name, textStyle, Color(0xFFfff2cc)),
                  SizedBox(
                    width: 2.h,
                  ),
                  buildShiftCard(
                      "shift_reconciliation_view.shift"
                          .tr(namedArgs: {"shift": shiftNo}),
                      textStyle,
                      Color(0xFFdeebf7)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
            child: Scrollbar(
                controller: scrollController,
                child: len > 0
                    ? buildDenominationEntryView()
                    : buildPaymentButtonList()))
      ],
    );
  }

  Widget buildShiftCard(String text, TextStyle textStyle, Color color) {
    final config = POSConfig();
    final padding = 14.r;
    return Container(
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(config.rounderBorderRadiusBottomLeft),
            bottomRight: Radius.circular(config.rounderBorderRadiusBottomRight),
            topRight: Radius.circular(config.rounderBorderRadiusTopRight),
            topLeft: Radius.circular(config.rounderBorderRadiusTopLeft),
          ),
          border: Border.all(color: Colors.redAccent)),
      height: double.infinity,
      margin: EdgeInsets.zero,
      child: Center(
          child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Text(
          text,
          style: textStyle,
        ),
      )),
    );
  }

  Widget buildPaymentButtonList() {
    final config = POSConfig();
    final list = denominationsList;
    return Container(
      child: Column(
        children: [
          Expanded(
            child: ResponsiveGridList(
              scroll: true,
              desiredItemWidth: config.paymentDynamicButtonWidth.w,
              children: list.map((payButton) {
                bool selected = false;

                if (selectedDenomination != null)
                  selected =
                      selectedDenomination!.detailCode == payButton.detailCode;

                return Container(
                  margin:
                      EdgeInsets.all(POSConfig().paymentDynamicButtonPadding),
                  height: config.paymentDynamicButtonHeight.h,
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                      bottomLeft:
                          Radius.circular(config.rounderBorderRadiusBottomLeft),
                      bottomRight: Radius.circular(
                          config.rounderBorderRadiusBottomRight),
                      topRight:
                          Radius.circular(config.rounderBorderRadiusTopRight),
                      topLeft:
                          Radius.circular(config.rounderBorderRadiusTopLeft),
                    )),
                    color: selected
                        ? CurrentTheme.backgroundColor
                        : CurrentTheme.primaryColor,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 15.w,
                        ),
                        Text(
                          payButton.description,
                          style: TextStyle(
                            fontSize: 24.sp,
                            color: CurrentTheme.primaryLightColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Spacer(),
                        Container(
                          width: config.paymentDynamicButtonHeight * 0.7.h,
                          child: CachedNetworkImage(
                            httpHeaders: {'Access-Control-Allow-Origin': '*'},
                            imageUrl:
                                "${POSConfig().posImageServer}images/pay_modes/${payButton.detailCode.toLowerCase()}.png",
                            errorWidget: (context, url, error) =>
                                SizedBox.shrink(),
                          ),
                        ),
                        SizedBox(
                          width: 15.w,
                        ),
                      ],
                    ),
                    // style: ElevatedButton.styleFrom(
                    //     primary: posButton.buttonNormalColor.toColor()),
                    onPressed: () {
                      POSLoggerController.addNewLog(POSLogger(
                          POSLoggerLevel.info,
                          "${payButton.detailCode}(${payButton.description}) button pressed"));
                      if (payButton.totalValue != 0) {
                        textEditingController.text =
                            payButton.totalValue.toString();
                        textEditingController.selection =
                            TextSelection.fromPosition(TextPosition(
                                offset: textEditingController.text.length));
                      } else {
                        textEditingController.clear();
                      }
                      if (payButton.denominations.length > 0) {
                        controllerList = List.generate(
                            payButton.denominations.length,
                            (index) => TextEditingController());
                        focusNodeList = List.generate(
                            payButton.denominations.length,
                            (index) => FocusNode());
                        focusNodeList.first.requestFocus();
                        selectedDenominationIndex = 0;
                      } else {
                        textFieldFocus.requestFocus();
                        selectedDenominationIndex = -1;
                      }
                      if (mounted)
                        setState(() {
                          selectedDenomination = payButton;
                        });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
              width: double.infinity,
              padding: EdgeInsets.all(5.r),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        POSConfig().primaryDarkGrayColor.toColor()),
                onPressed: () async {
                  bool? confirm = await showGeneralDialog<bool?>(
                      context: context,
                      transitionDuration: const Duration(milliseconds: 200),
                      barrierDismissible: true,
                      barrierLabel: '',
                      transitionBuilder: (context, a, b, _) => Transform.scale(
                            scale: a.value,
                            child: AlertDialog(
                                content: Text(
                                    'general_dialog.mngSignOff_confirm'.tr()),
                                actions: [
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: POSConfig()
                                              .primaryDarkGrayColor
                                              .toColor()),
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      },
                                      child:
                                          Text('general_dialog.change'.tr())),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: POSConfig()
                                              .primaryDarkGrayColor
                                              .toColor()),
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: Text('general_dialog.yes'.tr()))
                                ]),
                          ),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return SizedBox();
                      });
                  if (confirm != true) return;
                  saveManagerSignOff(
                      pendingSignoff: widget
                          .pendingSignoff); //new change -- passing a flag to identify the current_user of pending_user(get from pending sign off dialog window)

                  if (POSConfig().dualScreenWebsite != "")
                    DualScreenController().setView(
                        'closed'); //coppied it from printManagerSignOff() because this method is going to be commented
                  // printManagerSignOff(); //comment this because the same function is called inside the saveManagerSignOff(). so it is no longer needed to call it again
                  Navigator.pop(context);
                  // await DenominationController().managerSignOff(denominationsList,widget.spotCheck,widget.approvedUser);
                  // Navigator.pop(context);
                },
                child: Text("shift_reconciliation_view.done".tr()),
              ))
        ],
      ),
    );
  }

  //commented because it is already used inside saveManagerSignOff() -> managerSignOff()
  // void printManagerSignOff() async {
  //   DualScreenController().setView('closed');
  //   await PrintController().printMngSignOffSlip(
  //       userBloc.currentUser?.uSERHEDUSERCODE?.toString() ?? '',
  //       POSConfig().setupLocation,
  //       POSConfig().terminalId,
  //       userBloc.currentUser?.shiftNo?.toString() ?? '0',
  //       userBloc.currentUser?.uSERHEDSIGNONDATE?.toString() ?? '');
  // }

  void saveManagerSignOff({bool pendingSignoff = false}) async {
    //new chang -- passing a flag to identify the current_user of pending_user(get from pending sign off dialog window)
    await DenominationController().managerSignOff(
        denominationsList, widget.spotCheck, widget.approvedUser,
        pendingSignoff: pendingSignoff);
  }

// this is the default rhs in the app
  Widget buildDefaultRHS() {
    final len = selectedDenomination?.denominations.length ?? 0;
    return Container(
      child: Column(
        children: [
          len != 0
              ? SizedBox.shrink()
              : Column(
                  children: [
                    buildCard("shift_reconciliation_view.total_cash".tr(),
                        totalCash.thousandsSeparator()),
                    buildCard("shift_reconciliation_view.total_none_cash".tr(),
                        totalNonCash.thousandsSeparator()),
                    buildCard("shift_reconciliation_view.total_collection".tr(),
                        (totalCash + totalNonCash).thousandsSeparator()),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: spacing.r),
                      child: TextField(
                        onEditingComplete: handleEnteredValue,
                        textAlign: TextAlign.end,
                        decoration: InputDecoration(
                          filled: true,
                        ),
                        controller: textEditingController,
                        enabled: selectedDenominationIndex == -1,
                        focusNode: textFieldFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                  ],
                ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: spacing.r),
              child: POSKeyBoard(
                onEnter: handleEnterKeyPress,
                onPressed: handleClearKey,
                isInvoiceScreen: true,
                clearButton: true,
                disableArithmetic: true,
                controller: selectedDenominationIndex == -1
                    ? textEditingController
                    : controllerList[selectedDenominationIndex],
                normalKeyPress: () {
                  if (selectedDenominationIndex == -1 &&
                      textEditingController.text.contains('.')) {
                    var rational = textEditingController.text.split('.')[1];
                    if (rational.length >= 2) {
                      return 0;
                    }
                  } else if (selectedDenominationIndex != -1 &&
                      controllerList[selectedDenominationIndex]
                          .text
                          .contains('.')) {
                    var rational = controllerList[selectedDenominationIndex]
                        .text
                        .split('.')[1];
                    if (rational.length >= 0) {
                      EasyLoading.showInfo(
                          'Entered format is wrong \nRemove the symbol');
                      return 0;
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard(String title, String amount) {
    return Container(
      width: double.infinity,
      height: height.h,
      margin: EdgeInsets.symmetric(vertical: spacing.r),
      child: Card(
        color: CurrentTheme.primaryColor,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
          child: Row(
            children: [
              Spacer(
                flex: 8,
              ),
              Text(
                title,
                style: CurrentTheme.headline6!.copyWith(
                    color: CurrentTheme.primaryLightColor,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                width: 120.w,
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

  Widget buildDenominationEntryView() {
    final denominationList = selectedDenomination?.denominations ?? [];
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      thickness: 25,
      child: Container(
        child: Row(
          children: [
            Expanded(
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                controller: scrollController,
                itemCount: denominationList.length + 1,
                itemBuilder: (context, index) {
                  if (index == denominationList.length) {
                    return Padding(
                      padding: EdgeInsets.all(5.r),
                      child: ElevatedButton(
                          onPressed: handleBackButtonPress,
                          child: Text("shift_reconciliation_view.done".tr())),
                    );
                  }

                  final denomination = denominationList[index];
                  final denoVal = denomination.value.toStringAsFixed(2);
                  return Card(
                    color: CurrentTheme.primaryColor,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 15.r,
                        ),
                        Text(
                          "$denoVal * ${denomination.count} = ${denomination.value * denomination.count}",
                          style: CurrentTheme.headline6,
                        ),
                        Spacer(),
                        Container(
                          width: 300.w,
                          padding: EdgeInsets.all(5.r),
                          child: TextField(
                            onTap: () {
                              if (mounted)
                                setState(() {
                                  selectedDenominationIndex = index;
                                });
                            },
                            focusNode: focusNodeList[index],
                            onEditingComplete: () {
                              handleEnteredDenominationValue();
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            controller: controllerList[index],
                            textInputAction: TextInputAction.next,
                            // controller: denomination.count == 0?null: TextEditingController(text: denomination.count.toString()),
                            decoration: InputDecoration(
                              filled: true,
                              // hintText: denomination.deNDENOCODE ?? "2"
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // POSKeyBoard(isInvoiceScreen: false)
          ],
        ),
      ),
    );
  }

  void handleClearKey() {
    textEditingController.clear();
    if (selectedDenominationIndex != -1)
      controllerList[selectedDenominationIndex].clear();
  }

  void handleEnterKeyPress() {
    if (RegExp(r'^\d+\.?\d{0,2}?$').hasMatch(textEditingController.text) ||
        RegExp(r'^\d*?$')
            .hasMatch(controllerList[selectedDenominationIndex].text)) {
      if (selectedDenomination == null) return;
      if (selectedDenomination!.denominations.length == 0) {
        handleEnteredValue();
      } else {
        handleEnteredDenominationValue();
      }
    } else {
      EasyLoading.showError('wrong_format'.tr());
    }
  }

  void handleEnteredDenominationValue() {
    // search the denomination index
    int findAt = getListIndex();

    if (findAt != -1) {
      // set the entered value
      this
              .denominationsList[findAt]
              .denominations[selectedDenominationIndex]
              .count =
          controllerList[selectedDenominationIndex].text.parseDouble().toInt();
    }
    var denominationList = selectedDenomination!.denominations;
    if ((selectedDenominationIndex + 1) < denominationList.length && mounted) {
      focusNodeList[selectedDenominationIndex + 1].requestFocus();
      selectedDenominationIndex++;
    }

    if (mounted) setState(() {});
  }

  void handleEnteredValue() {
    int index = getListIndex();
    if (index != -1 && mounted) {
      this.denominationsList[index].totalValue =
          textEditingController.text.parseDouble();
      textEditingController.clear();
      selectedDenomination = null;
      setState(() {});
    }
  }

  int getListIndex() {
    return this.denominationsList.indexWhere(
        (element) => element.detailCode == selectedDenomination?.detailCode);
  }

  void handleCalculation() {
    double cash = 0;
    double nonCash = 0;
    this.denominationsList.forEach((e) {
      bool isCash = (e.detailCode == "CSH");
      double denoCount = 0;
      e.denominations.forEach((ee) => (denoCount += (ee.count) * (ee.value)));
      double total = e.totalValue.toString().parseDouble();
      if (isCash) {
        cash += (denoCount.toString().parseDouble()) + total;
      } else {
        nonCash += (denoCount.toString().parseDouble()) + total;
      }
    });

    totalCash = cash;
    totalNonCash = nonCash;
  }

  void handleBackButtonPress() {
    selectedDenominationIndex = -1;
    if (selectedDenomination == null)
      Navigator.pop(context);
    else {
      if (mounted)
        setState(() {
          selectedDenomination = null;
        });
    }
  }
}
