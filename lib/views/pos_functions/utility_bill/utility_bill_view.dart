/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 3/1/22, 3:34 PM
 */
//import 'dart:html';

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/audit_log_controller.dart';
import 'package:checkout/controllers/cfcintegrator.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/utility_bill/utility_ui_results.dart';
import 'package:checkout/views/pos_functions/utility_bill/utility_payment_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:checkout/extension/extensions.dart';
import '../../../components/current_theme.dart';
import '../../../components/widgets/go_back.dart';
import '../../../components/widgets/pos_app_bar.dart';
import '../../../components/widgets/pos_background.dart';
import '../../../controllers/print_controller.dart';
import '../../../models/pos_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/utility_bill/utility_bill_setup.dart';
import 'package:supercharged/supercharged.dart';

class UtilityBillView extends StatefulWidget {
  const UtilityBillView(
      {Key? key, required this.utilityUiList, required this.utilityBillSetup})
      : super(key: key);
  final List<UtilityUi> utilityUiList;
  final UtilityBillSetup utilityBillSetup;

  @override
  _UtilityBillViewState createState() => _UtilityBillViewState();
}

class _UtilityBillViewState extends State<UtilityBillView> {
  late List<UtilityUi> _utilityUiList;
  List<UtilityWidget> _utilityWidgetList = <UtilityWidget>[];
  TextEditingController _usernameEditingController = TextEditingController();
  TextEditingController _passwordEditingController = TextEditingController();

  int? amountIndex;
  int? payingAmountIndex;
  int? balanceIndex;

  @override
  void initState() {
    super.initState();
    _utilityUiList = widget.utilityUiList;
    // going through all widgets and build list
    _utilityUiList.forEach((UtilityUi utilityUi) {
      utilityUi.components?.forEach((UtilityComponents components) {
        components.widget?.forEach((element) {
          _utilityWidgetList.add(element);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
        child: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.0.w),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                child: Column(
                  children: [
                    SizedBox(
                      height: POSConfig().topMargin.h,
                    ),
                    POSAppBar(),
                    SizedBox(
                      height: 8.h,
                    ),
                    // Container(
                    //   child: Row(
                    //     children: [
                    //       Expanded(
                    //           child: UserCard(
                    //         text: "",
                    //         shift: true,
                    //       )),
                    //       POSClock(),
                    //     ],
                    //   ),
                    // ),
                    SizedBox(
                      height: 8.h,
                    ),
                    specialFuctionElementTitle(),
                  ],
                ),
              ),
              Expanded(child: _buildUtilityUi()),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildUtilityUi() {
    ScrollController controller = ScrollController();
    int len = _utilityUiList.length;
    final String okay = widget.utilityBillSetup.uBOK ?? '';
    final String cancel = widget.utilityBillSetup.uBCANCEL ?? '';
    bool bottomButton = false;
    if (cancel.isNotEmpty ||
        okay.isNotEmpty ||
        widget.utilityBillSetup.uBAUTHORIZE == true) {
      bottomButton = true;
      len += 1;
    }

    return Scrollbar(
      controller: controller,
      thickness: 25,
      thumbVisibility: true,
      child: ListView.builder(
        controller: controller,
        itemCount: len,
        itemBuilder: (BuildContext context, int index) {
          if (index == len - 1 && bottomButton) {
            return Column(
              children: [
                if (widget.utilityBillSetup.uBAUTHORIZE == true)
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: POSConfig().primaryDarkGrayColor.toColor())),
                    padding:
                        EdgeInsets.symmetric(vertical: 15.h, horizontal: 5.w),
                    margin:
                        EdgeInsets.symmetric(vertical: 15.h, horizontal: 5.w),
                    child: Column(
                      children: [
                        Text('Authorized person only'),
                        SizedBox(
                          height: 15.h,
                        ),
                        _authorizeTextField(
                            'username', _usernameEditingController),
                        _authorizeTextField(
                            'Password', _passwordEditingController),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    if (okay.isNotEmpty)
                      Expanded(
                          child: ElevatedButton(
                              onPressed: () => _onOkay(_utilityWidgetList),
                              child: Text(okay))),
                    SizedBox(
                      width: 15.w,
                    ),
                    if (cancel.isNotEmpty)
                      Expanded(
                          child: ElevatedButton(
                              onPressed: _onCancel, child: Text(cancel))),
                  ],
                ),
              ],
            );
          }
          return _buildUtilityUiSection(_utilityUiList[index]);
        },
      ),
    );
  }

  Widget _buildUtilityUiSection(UtilityUi utilityUiList) {
    final components = utilityUiList.components ?? [];
    final button1 = utilityUiList.ubSBUTTON1 ?? '';
    final button2 = utilityUiList.ubSBUTTON2 ?? '';
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: POSConfig().primaryDarkGrayColor.toColor())),
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 5.w),
      margin: EdgeInsets.symmetric(vertical: 15.h, horizontal: 5.w),
      child: Column(
        children: [
          if (utilityUiList.ubSSHOWSECTION == true)
            Text(utilityUiList.ubSDESC ?? ''),
          ResponsiveGridList(
              scroll: false,
              desiredItemWidth: ScreenUtil().screenWidth / 3,
              children:
                  components.map((e) => _buildUtilityUiElementRow(e)).toList()),
          //section buttons
          Theme(
            data: CurrentTheme.themeData!.copyWith(),
            child: ButtonBar(
              children: [
                if (button1.isNotEmpty)
                  ElevatedButton(
                      onPressed: () {
                        final List<UtilityWidget> myWidgets = [];

                        for (int i = 0; i < components.length; i++) {
                          final List<UtilityWidget>? temp =
                              components[i].widget;
                          if (temp != null) {
                            myWidgets.addAll(temp);
                          }
                        }

                        _onOkay(myWidgets);
                      },
                      child: Text(button1),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green)),
                if (button2.isNotEmpty)
                  ElevatedButton(onPressed: () {}, child: Text(button2))
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUtilityUiElementRow(UtilityComponents component) {
    final myWidgets = component.widget ?? [];

    if (myWidgets.isEmpty) {
      return SizedBox.shrink();
    }

    return Visibility(
      visible: myWidgets.first.ubUINPUTTYPE != "HIDDEN",
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 3.r),
        child: Row(
          children: [
            Expanded(
                flex: 2,
                child: Card(
                  color: CurrentTheme.primaryColor,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
                    child: Text(
                      myWidgets.first.ubUNAME ?? '',
                      style: CurrentTheme.subtitle2!
                          .copyWith(color: CurrentTheme.primaryLightColor),
                      textAlign: TextAlign.left,
                    ),
                  ),
                )),
            SizedBox(
              width: 8.w,
            ),
            Expanded(
                flex: 3,
                child: Row(
                  children: myWidgets.map((e) => _myWidget(e)).toList(),
                ))
          ],
        ),
      ),
    );
  }

  Widget _myWidget(UtilityWidget utilityWidget) {
    //new change by TM.Sakir-- in some cases it duplicate the same widget when comparing only column name
    //example: _utilityWidgetList[2],_utilityWidgetList[3] are both have the same utilityWidget.ubUCOLUMNNAME
    //so, the compiler picks _utilityWidgetList[2] in cases like _utilityWidgetList[3] must be picked.
    // final index = _utilityWidgetList.indexWhere(
    //     (element) => element.ubUCOLUMNNAME == utilityWidget.ubUCOLUMNNAME);
    final index = _utilityWidgetList.indexWhere((element) =>
        ((element.ubUCOLUMNNAME == utilityWidget.ubUCOLUMNNAME) &&
            (element.ubUNAME == utilityWidget.ubUNAME)));

    final style =
        CurrentTheme.bodyText2!.copyWith(color: CurrentTheme.primaryColor);
    switch (utilityWidget.ubUINPUTTYPE) {
      case 'TEXT':
        return _myTextField(index, style, utilityWidget);
      case 'HIDDEN':
        return _myTextField(index, style, utilityWidget, disabled: true);
      case 'DROPDOWN':
        return _myDropdown(index, style, utilityWidget);
      case 'TEXTDISABLED':
        return _myTextField(index, style, utilityWidget, disabled: true);
      default:
        return SizedBox();
    }
  }

  Widget _myTextField(int index, TextStyle style, UtilityWidget utilityWidget,
      {bool disabled = false}) {
    String regex = utilityWidget.ubUREGEX ?? '';
    // var maskFormatter = new MaskTextInputFormatter(
    //     mask: utilityWidget.ubUMASK, filter: {"0": RegExp('$regex')});
    //is amount
    bool isAmount =
        utilityWidget.ubUCOLUMNNAME?.toLowerCase().contains("amount") ?? false;
    // save amount texteditor index
    if (utilityWidget.ubUCOLUMNNAME == "TransactionAmount") amountIndex = index;

    if (utilityWidget.ubUCOLUMNNAME == "PayingAmount")
      payingAmountIndex = index;

    if (utilityWidget.ubUCOLUMNNAME == "BalanceAmount") {
      _utilityWidgetList[index].textEditingController.text = '0.00';
      balanceIndex = index;
    }

    /* check if the field is commision rate */
    if (utilityWidget.ubUCOLUMNNAME == "CommissionRate") {
      String? rate = utilityWidget.ubUDATAFROM ?? '0.00';

      String commissionAmount;

      if (rate.contains('%') || rate.contains('.')) {
        commissionAmount = rate;
      } else {
        commissionAmount = '$rate.00';
      }

      _utilityWidgetList[index].textEditingController.text = commissionAmount;
    }

    return Expanded(
        child: SizedBox(
      child: Theme(
        data: CurrentTheme.themeData!.copyWith(
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor:
                  CurrentTheme.primaryLightColor, // button text color
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    if (amountIndex != null &&
                        payingAmountIndex != null &&
                        balanceIndex != null) {
                      String amount = _utilityWidgetList[amountIndex!]
                          .textEditingController
                          .text;
                      String payingAmount =
                          _utilityWidgetList[payingAmountIndex!]
                              .textEditingController
                              .text;
                      double? amountValue = double.tryParse(amount);
                      double? payingAmountValue = double.tryParse(payingAmount);

                      if (amountValue != null && payingAmountValue != null) {
                        double balanceAmount =
                            (payingAmountValue - amountValue);
                        if (balanceAmount.isNegative) {
                          _utilityWidgetList[balanceIndex!]
                              .textEditingController
                              .text = "Invalid Amount";
                          EasyLoading.showToast("easy_loading.invalid_amount".tr());
                        } else {
                          _utilityWidgetList[balanceIndex!]
                              .textEditingController
                              .text = balanceAmount.toStringAsFixed(2);
                        }
                      }
                    }
                  }
                },
                child: TextField(
                  onTap: () {
                    if (disabled) return;
                    KeyBoardController().dismiss();
                    KeyBoardController().showBottomDPKeyBoard(
                      _utilityWidgetList[index].textEditingController,
                      onEnter: () {
                        String text = _utilityWidgetList[index]
                            .textEditingController
                            .text;
                        if (isAmount && !text.contains('.')) {
                          _utilityWidgetList[index].textEditingController.text =
                              '$text.00';
                        }

                        /* check mask is available */
                        /* by dinuka 2022-09-29 */
                        if (_utilityWidgetList[index].ubUMASK != null) {
                          _utilityWidgetList[index].originalText =
                              _utilityWidgetList[index]
                                  .textEditingController
                                  .text;

                          if (_utilityWidgetList[index].originalText != null) {
                            _utilityWidgetList[index]
                                .textEditingController
                                .text = _utilityWidgetList[index].ubUMASK!;
                          }
                        }
                        if (amountIndex != null &&
                            payingAmountIndex != null &&
                            balanceIndex != null) {
                          String amount = _utilityWidgetList[amountIndex!]
                              .textEditingController
                              .text;
                          String payingAmount =
                              _utilityWidgetList[payingAmountIndex!]
                                  .textEditingController
                                  .text;
                          double? amountValue = double.tryParse(amount);
                          double? payingAmountValue =
                              double.tryParse(payingAmount);

                          if (amountValue != null &&
                              payingAmountValue != null) {
                            double balanceAmount =
                                (payingAmountValue - amountValue);
                            if (balanceAmount.isNegative) {
                              _utilityWidgetList[balanceIndex!]
                                  .textEditingController
                                  .text = "Invalid Amount";
                              EasyLoading.showToast("easy_loading.invalid_amount".tr());
                            } else {
                              _utilityWidgetList[balanceIndex!]
                                  .textEditingController
                                  .text = balanceAmount.toStringAsFixed(2);
                            }
                          }
                        }
                        KeyBoardController().dismiss();
                        _utilityWidgetList[index + 1].focusNode.requestFocus();
                      },
                      // mask: _utilityWidgetList[index].ubUMASK
                    );
                  },
                  controller: _utilityWidgetList[index].textEditingController,
                  focusNode: _utilityWidgetList[index].focusNode,
                  style: style,
                  enabled: !disabled,
                  textAlign: isAmount ? TextAlign.right : TextAlign.left,
                  onEditingComplete: () {
                    String text =
                        _utilityWidgetList[index].textEditingController.text;
                    if (isAmount && !text.contains('.')) {
                      _utilityWidgetList[index].textEditingController.text =
                          '$text.00';
                    }

                    _utilityWidgetList[index + 1].focusNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    filled: true,
                    alignLabelWithHint: true,
                    isDense: true,
                    hintText: utilityWidget.ubUHINT ?? '',
                    hintStyle: style,
                    contentPadding: EdgeInsets.all(10),
                  ),
                  // inputFormatters: [maskFormatter],
                ),
              ),
            ),
            Text(
              '   ' + ((utilityWidget.ubUREGEX ?? '').isEmpty ? ' ' : '*'),
              style: TextStyle(color: Colors.redAccent),
            )
          ],
        ),
      ),
    ));
  }

  Widget _authorizeTextField(String text, TextEditingController controller) {
    final style =
        CurrentTheme.bodyText2!.copyWith(color: CurrentTheme.primaryColor);

    return SizedBox(
      child: Theme(
        data: CurrentTheme.themeData!.copyWith(
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor:
                  CurrentTheme.primaryLightColor, // button text color
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
                flex: 1,
                child: Card(
                  color: CurrentTheme.primaryColor,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
                    child: Text(
                      text,
                      style: CurrentTheme.subtitle2!
                          .copyWith(color: CurrentTheme.primaryLightColor),
                      textAlign: TextAlign.left,
                    ),
                  ),
                )),
            SizedBox(
              width: 8.w,
            ),
            Expanded(
              flex: 3,
              child: TextField(
                controller: controller,
                onChanged: (value) {},
                style: style,
                decoration: InputDecoration(
                  filled: true,
                  alignLabelWithHint: true,
                  isDense: true,
                  hintText: text,
                  hintStyle: style,
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _myDropdown(int index, TextStyle style, UtilityWidget utilityWidget) {
    return Expanded(
        child: SizedBox(
      child: Theme(
        data: CurrentTheme.themeData!.copyWith(
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor:
                  CurrentTheme.primaryLightColor, // button text color
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<UtilityData>(
                  style: style,
                  focusColor: CurrentTheme.primaryLightColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(
                        POSConfig().rounderBorderRadiusBottomLeft),
                    bottomRight: Radius.circular(
                        POSConfig().rounderBorderRadiusBottomRight),
                    topRight: Radius.circular(
                        POSConfig().rounderBorderRadiusTopRight),
                    topLeft:
                        Radius.circular(POSConfig().rounderBorderRadiusTopLeft),
                  ),
                  value: utilityWidget.selectedData,
                  items: utilityWidget.utilityData
                      .map((e) => DropdownMenuItem<UtilityData>(
                          value: e,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(e.name ?? ''),
                          )))
                      .toList(),
                  onChanged: (UtilityData? value) async {
                    utilityWidget.textEditingController.text =
                        value?.id.toString() ?? '';
                    utilityWidget.selectedData = value;
                    // phCode =
                    //     utilityWidget.textEditingController.text.split('-')[0];
                    // pdCode =
                    //     utilityWidget.textEditingController.text.split('-')[1];
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
            Text(
              '   ' + ((utilityWidget.ubUREGEX ?? '').isEmpty ? ' ' : '*'),
              style: TextStyle(color: Colors.redAccent),
            )
          ],
        ),
      ),
    ));
  }

  Container specialFuctionElementTitle() {
    return Container(
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              SizedBox(
                width: 20.r,
              ),
              GoBackIconButton(),
              Spacer(),
              Text(
                widget.utilityBillSetup.uBDESC ?? '',
                style: CurrentTheme.headline6!
                    .copyWith(color: CurrentTheme.primaryColor),
                textAlign: TextAlign.center,
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  Future<void> _onOkay(List<UtilityWidget> list) async {
    //validating
    EasyLoading.show(status: 'Validating.....');
    String? error;
    final String invNo = await InvoiceController().getUtilityInvoiceNo(
        widget.utilityBillSetup.uBINVMODE ??
            ''); //new change-- passing uBINVMODE instead of uBTYPE..
    late UtilityData paymentData;

    Map<String, dynamic> formData = <String, dynamic>{};
    for (int i = 0; i < list.length; i++) {
      UtilityWidget myWidget = list[i];
      String value = '';
      if (myWidget.ubUMASK != null && myWidget.originalText != null) {
        value = myWidget.originalText!;
      } else {
        value = myWidget.textEditingController.text;
      }
      // String value = myWidget.textEditingController.text;
      String key = myWidget.ubUCOLUMNNAME ?? '';
      String strRegex = myWidget.ubUREGEX ?? '';
      if (myWidget.selectedData != null) {
        paymentData = myWidget.selectedData!;
      }
      if (key.isEmpty) {
        error =
            "Some fields doesn't have required keys. Please contact your system administrator";
        break;
      }

      //if regex is not empty create regex object
      if (strRegex.isNotEmpty) {
        RegExp regex = RegExp(strRegex);
        if (!regex.hasMatch(value)) {
          error = "Invalid value for ${myWidget.ubUNAME ?? ''}";
          break;
        }
      }
      //check RE Type Numbers
      if (key.toLowerCase().startsWith("re_")) {
        //replace re
        key = key.replaceFirst("Re_", "");
        //check values match or not
        if (myWidget.ubUDATAFROM == "Decimal") {
          if (value != "" && formData[key] != double.parse(value)) {
            error = "Invalid value for ${myWidget.ubUNAME ?? ''}";
            break;
          }
        } else if (formData[key].toString() != value) {
          error = "Invalid value for ${myWidget.ubUNAME ?? ''}";
          break;
        }
      } else {
        if (myWidget.ubUEXCLUDEREQUEST == null ||
            myWidget.ubUEXCLUDEREQUEST == false) {
          //if (myWidget.ubUINPUTTYPE == "HIDDEN") {
          if (myWidget.ubUDATAFROM == "InvNo") {
            formData[key] = invNo.toString();
          } else if (myWidget.ubUDATAFROM == "AuditNo") {
            formData[key] = invNo.toString();
          } else if (myWidget.ubUDATAFROM == "Date" ||
              myWidget.ubUDATAFROM == "Time") {
            var formatter = DateFormat(myWidget.ubUHINT);
            formData[key] = formatter.format(DateTime.now());
          } else if (myWidget.ubUDATAFROM == "Decimal") {
            formData[key] = double.parse(value.trim());
          } else {
            formData[key] = value.trim();
          }
          //}
        }
      }
    }

    /* check refrence invoice number */
    /* by dinuka 2022/10/17 */
    if (formData.containsKey('RefInvoiceNo')) {
      final String? refInv = await InvoiceController().checkReferenceInvNo(
          formData['RefInvoiceNo'], POSConfig().locCode, 'INV');

      error = refInv == null ? 'Reference invoice number is invalid!' : null;
    }
    EasyLoading.dismiss();

    if (error != null) {
      EasyLoading.showError(error);
      return;
    }
    POSPriceCalculator calculator = POSPriceCalculator();
    String desc = widget.utilityBillSetup.uBDESC ?? '';

    // save invoice
    final amount = formData["TransactionAmount"].toString().parseDouble();

    final String accNo = formData["PrimaryAccountOrCardNo"];

    /* check commision rate is available */
    /* by dinuka 2022/10/21 */
    if (formData.containsKey("CommissionRate")) {
      String commission = formData["CommissionRate"];
      double commissionAmount;
      double calculatedCommission;
      String comDesc;
      double invAmount = 0.00;

      if (commission.contains('%')) {
        commissionAmount = commission.removeLastChar().parseDouble();
        calculatedCommission = (amount * commissionAmount) / 100;
        comDesc = ' Commission(%)';
        invAmount = amount - ((amount * commissionAmount) / 100);
      } else {
        commissionAmount = commission.parseDouble();
        comDesc = ' Commission';
        invAmount = (amount - commissionAmount);
        calculatedCommission = commissionAmount;
      }

      await calculator.addUtilityBill(
          desc, accNo, invAmount, widget.utilityBillSetup.uBTYPE ?? '');

      await calculator.addUtilityBill(desc + comDesc, '999999',
          calculatedCommission, widget.utilityBillSetup.uBTYPE ?? '');
    } else {
      await calculator.addUtilityBill(
          desc, accNo, amount, widget.utilityBillSetup.uBTYPE ?? '');
    }
    cartBloc.addPayment(PaidModel(
        0,
        amount,
        false,
        paymentData.pdCode ?? '',
        paymentData.phCode ?? '',
        "",
        null,
        1,
        paymentData.phDesc ?? '',
        paymentData.pdDesc ?? ''));

    var finished = await showModalBottomSheet(
      isScrollControlled: true,
      enableDrag: false,
      context: context,
      builder: (context) {
        return UtilityBillPaymentView(
          dataMap: formData,
          utilityData: paymentData,
        );
      },
    );

    if (!finished) {
      await cartBloc.resetCart();
      return;
    }
    await InvoiceController().billClose(invoiced: true, context: context);

    await PrintController().printHandler(
        invNo, PrintController().printUtilityBill(invNo), context);
    await cartBloc.resetCart();

    final res = await CfcIntegrator().makeRequest(
        widget.utilityBillSetup.uBTYPE ?? '', invNo, desc, formData);
    final bool hasError = res != null;

    if (hasError) {
      EasyLoading.showError(res, duration: Duration(seconds: 2));
      AuditLogController().updateAuditLog(
          PermissionCode.invoiceCancellation,
          "A",
          invNo,
          'Cancelled By EDI - $res',
          userBloc.currentUser?.uSERHEDUSERCODE ?? '');
      await InvoiceController().cancelInvoice(invNo, context, print: false);
      return;
    } else {
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }
}
