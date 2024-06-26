import 'dart:convert';

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/components/current_theme.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/components/widgets/pos_background.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_manual_print_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/views/invoice/reClassification_payment_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supercharged/supercharged.dart';

class PaymentReClassification extends StatefulWidget {
  const PaymentReClassification({super.key});

  @override
  State<PaymentReClassification> createState() =>
      _PaymentReClassificationState();
}

class _PaymentReClassificationState extends State<PaymentReClassification> {
  TextEditingController invController = TextEditingController();
  FocusNode invFocus = FocusNode();
  String invDate = '--';
  num invAmount = 0;
  String invLoc = '--';
  String invStation = '--';
  String invCashier = '--';
  String invCustomer = '--';
  String invRemark = '--';
  List<String> hedRemarks = [];

  num invBalance = 0;

  List<PaidModel> payments = [];
  List<PaidModel> classifiedPayments = [];

  @override
  void initState() {
    super.initState();
    invFocus.requestFocus();
  }

  @override
  void dispose() {
    invController.dispose();
    invFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              goBackBar(),
              Row(
                children: [
                  Expanded(child: invoiceSearch()),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (classifiedPayments.isNotEmpty) {
                          bool? confirm = await confirmationDialog(context,
                              'Do you want to clear the current re-classified payments?');
                          if (confirm != true) return;
                        }
                        cartBloc.clearPayment();
                        await showModalBottomSheet(
                          isScrollControlled: true,
                          enableDrag: false,
                          context: context,
                          builder: (context) {
                            return ReClassificationPaymentView(
                              subTotal: invAmount.toDouble(),
                            );
                          },
                        ).then((value) =>
                            classifiedPayments = cartBloc.paidList ?? []);

                        setState(() {});
                      },
                      child: Text('Re-Classify'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (classifiedPayments.isEmpty) {
                          EasyLoading.showError(
                              'Do payment re-classification before save !!!');
                          return;
                        }

                        final permissionList = userBloc.userDetails?.userRights;
                        bool hasPermission = false;
                        final userCode =
                            userBloc.currentUser?.uSERHEDUSERCODE ?? "";
                        hasPermission =
                            SpecialPermissionHandler(context: context)
                                .hasPermissionInList(
                                    permissionList ?? [],
                                    PermissionCode.reclassification,
                                    "C",
                                    userCode);

                        //if user doesnt have the permission
                        if (!hasPermission) {
                          final res = await SpecialPermissionHandler(
                                  context: context)
                              .askForPermission(
                                  permissionCode:
                                      PermissionCode.reclassification,
                                  accessType: "C",
                                  refCode: DateTime.now().toIso8601String());
                          hasPermission = res.success;
                        }

                        // still havent permission
                        if (!hasPermission) {
                          return;
                        }
                        EasyLoading.show(
                            status: 'please_wait'.tr(), dismissOnTap: true);
                        Map<String, dynamic> temp = {
                          'START_TIME': DateFormat('yyyy-MM-ddTHH:mm:ss.000')
                              .format(DateTime.parse(invDate)),
                          "INV_DETAILS": [],
                          "PAYMENTS":
                              classifiedPayments.map((e) => e.toMap()).toList(),
                          "MEMBER_CODE": invCustomer == '--' ? "" : invCustomer,
                          "INVOICE_NO": invController.text,
                          "NET_AMOUNT": invAmount,
                          "GROSS_AMOUNT": invAmount,
                          "PAY_AMOUNT": invAmount,
                          "CHANGE_AMOUNT": 0,
                          "EARNED_POINTS": 0,
                          "BURNED_POINTS": 0,
                          "DUE_AMOUNT": 0,
                          "TERMINAL": POSConfig().terminalId,
                          "SETUP_LOCATION": POSConfig().setupLocation,
                          "CASHIER": invCashier,
                          "TEMP_SIGN_ON": invCashier,
                          "SHIFT_NO": "",
                          "SIGN_ON_DATE": "",
                          "COM_CODE": POSConfig().comCode,
                          "LOC_CODE": POSConfig().locCode,
                          "BILL_DISC_PER": 0,
                          "INVOICED": true,
                          "LINE_DISC_PER": 0,
                          "LINE_DISC_AMT": 0,
                          "PRICE_MODE": "",
                          'REF_NO': "",
                          'REF_MODE': "",
                          'INV_REF': [],
                          'PRO_TAX': [],
                          'TAX_INC': 0,
                          'TAX_EXC': 0,
                          'PROMO_FREE_ITEMS': [],
                          'LOYALTY_OUTLET': POSConfig().loyaltyServerOutlet,
                          'LINE_REMARKS': [],
                          'PROMO_DISC_PER': 0,
                          'PROMO_CODE': '',
                          'FREE_ISSUE': [],
                          'INV_TICKETS': [],
                          'REDEEMED_COUPONS': [],
                        };

                        await LogWriter().saveLogsToFile('API_Log_', [
                          '####################################################################',
                          jsonEncode(temp),
                          '####################################################################'
                        ]);
                        final res = await ApiClient.call(
                            'invoice/reclassification',
                            ApiMethod
                                .POST, //invoiced ? "invoice/save" : 'invoice/hold_invoice'
                            data: temp,
                            successCode: 200);

                        if (res?.statusCode == 200) {
                          try {
                            // final resReturn = res?.data?["res"].toString();
                            // if (resReturn == null || resReturn == '') return;
                            // POSConfig.localPrintData = resReturn!;
                            // var stopwatch = Stopwatch();

                            // stopwatch.start();
                            // POSManualPrint()
                            //     .printInvoice(data: resReturn!, points: 0);
                            // stopwatch.stop();
                            // print(stopwatch.elapsed.toString());
                            payments.clear();
                            payments.addAll(classifiedPayments);
                            classifiedPayments.clear();
                            EasyLoading.showSuccess('Success !!!');
                            setState(() {});
                          } catch (e) {
                            await LogWriter().saveLogsToFile('ERROR_LOG_', [
                              'Re-Classification save error :' + e.toString()
                            ]);
                          }
                        } else {
                          EasyLoading.showError(
                              'Can\'t be able to re-classify the payments\nPlease try again !!!');
                          EasyLoading.dismiss();
                          return;
                        }
                        EasyLoading.dismiss();
                      },
                      child: Text('Save'),
                      style: ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(Colors.green[800])),
                    ),
                  )
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      invDetailCard(),
                      payments.isEmpty
                          ? SizedBox.shrink()
                          : paymentsCard('OLD PAYMENTS', payments, true),
                      classifiedPayments.isEmpty
                          ? SizedBox.shrink()
                          : paymentsCard('RE-CLASSIFIED PAYMENTS',
                              classifiedPayments, false),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> confirmationDialog(BuildContext context, String content) {
    return showGeneralDialog<bool?>(
        context: context,
        transitionDuration: const Duration(milliseconds: 200),
        barrierDismissible: true,
        barrierLabel: '',
        transitionBuilder: (context, a, b, _) => Transform.scale(
              scale: a.value,
              child: AlertDialog(content: Text(content), actions: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            POSConfig().primaryDarkGrayColor.toColor()),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: Text('general_dialog.no'.tr())),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            POSConfig().primaryDarkGrayColor.toColor()),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: Text('general_dialog.yes'.tr()))
              ]),
            ),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SizedBox();
        });
  }

  Widget paymentsCard(
      String paymentLabel, List<PaidModel> payments, bool isOld) {
    var labelStyle = TextStyle(
        fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black);
    final height = MediaQuery.of(context).size.height;
    return Container(
        width: double.infinity,
        // height: height * 0.23,
        child: Card(
          color: CurrentTheme.primaryColor,
          child: Column(
            children: [
              Text(
                paymentLabel,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        flex: 1,
                        child: Text(
                          '#',
                          textAlign: TextAlign.center,
                          style: labelStyle,
                        )),
                    Expanded(
                        flex: 2,
                        child: Text('Payment Code',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 3,
                        child: Text('Payment Description',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 2,
                        child: Text('Detail Code',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 3,
                        child: Text('Detail Description',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 5,
                        child: Text('Card/Cheque Number',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 3,
                        child: Text('Date',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 3,
                        child: Text('Amount',
                            textAlign: TextAlign.center, style: labelStyle)),
                  ],
                ),
              ),
              SizedBox(
                height: height * 0.001,
              ),
              paymentList(payments),
              SizedBox(
                height: height * 0.001,
              ),
              isOld && invBalance != 0
                  ? Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                              'Balance Amount  :  ${POSManualPrint().formatWithCommas(invBalance)}',
                              style: labelStyle)
                        ],
                      ),
                    )
                  : SizedBox.shrink()
            ],
          ),
        ));
  }

  Widget paymentList(List<PaidModel> payments) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.15,
      child: ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            PaidModel current = payments[index];
            num amount = current.amount;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                    color: CurrentTheme.backgroundColor,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    paymentRowValue(value: (index + 1).toString(), flex: 1),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 2, value: current.phCode),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 3, value: current.phDesc ?? ''),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 2, value: current.pdCode),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 3, value: current.pdDesc ?? ''),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 5, value: current.refNo),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(
                        flex: 3,
                        value: (current.paidDateTime.toString() ?? 'T')
                            .split(' ')
                            .first),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(
                        flex: 3,
                        value: POSManualPrint().formatWithCommas(amount))
                  ],
                ),
              ),
            );
          }),
    );
  }

  Expanded paymentRowValue({int flex = 1, String value = '--'}) {
    var valueStyle = CurrentTheme.bodyText1!.copyWith(
        fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600);
    return Expanded(
        flex: flex,
        child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8))),
            child: Padding(
              padding: const EdgeInsets.only(left: 1.0, right: 1),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: valueStyle,
              ),
            )));
  }

  Widget invDetailCard() {
    return Container(
        width: double.infinity,
        child: Card(
          color: CurrentTheme.primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    invDetailRecords(
                      label: 'Date',
                      value: invDate,
                    ),
                    invDetailRecords(
                      label: 'Invoice Amount',
                      value: POSManualPrint().formatWithCommas(invAmount),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    invDetailRecords(
                      label: 'Terminal',
                      value: invStation,
                    ),
                    invDetailRecords(
                      label: 'Cashier',
                      value: invCashier,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    invDetailRecords(
                      label: 'Location',
                      value: invLoc,
                    ),
                    invDetailRecords(
                      label: 'Customer',
                      value: invCustomer,
                    ),
                  ],
                ),
                Row(
                  children: [
                    invDetailRecords(
                      label: 'Remarks',
                      value: invRemark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget goBackBar() {
    return Container(
      width: double.infinity,
      child: Card(
        child: Row(
          children: [
            SizedBox(
              width: 15.r,
            ),
            GoBackIconButton(onPressed: () => clearReClassification()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
              child: Center(
                  child: Text(
                'Payment Re-Classification',
                style: CurrentTheme.bodyText2!
                    .copyWith(color: CurrentTheme.primaryColor),
              )),
            ),
            SizedBox(
              width: 15.r,
            ),
          ],
        ),
      ),
    );
  }

  void clearReClassification() {
    cartBloc.clearPayment();
    invController.clear();
    Navigator.pop(context);
  }

  Widget invoiceSearch() {
    final textStyle = CurrentTheme.headline6!.copyWith(
        color: CurrentTheme.primaryLightColor, fontWeight: FontWeight.w600);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final config = POSConfig();
    return Container(
      width: width * 0.5,
      child: Card(
        color: CurrentTheme.primaryColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: Row(
                  children: [
                    Text(
                      'Invoice Number',
                      style: textStyle,
                    ),
                    SizedBox(
                      width: width * 0.05,
                    ),
                    Expanded(
                      child: Container(
                        height: height * 0.05,
                        child: TextField(
                          style: textStyle,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            contentPadding:
                                EdgeInsets.only(left: 10, right: 10),
                            border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.black, width: 2)),
                          ),
                          focusNode: invFocus,
                          autofocus: true,
                          controller: invController,
                          onEditingComplete: () async {
                            // EasyLoading.showInfo('Processing !!!');
                            if (classifiedPayments.isNotEmpty) {
                              bool? confirm = await confirmationDialog(context,
                                  'Do you want to clear the re-classified payments for the current invoice?');
                              if (confirm != true) return;
                            }
                            EasyLoading.show(status: 'please_wait'.tr());
                            cartBloc.clearPayment();
                            classifiedPayments.clear();
                            invDate = '--';
                            invAmount = 0;
                            invLoc = '--';
                            invStation = '--';
                            invCashier = '--';
                            invCustomer = '--';
                            invRemark = '--';
                            hedRemarks = [];
                            invBalance = 0;
                            setState(() {});
                            bool isFetched = await getInvoicePayments();
                            if (isFetched) {
                              setState(() {});
                            } else {
                              EasyLoading.showError(
                                  'Failed to get invoice data !!!');
                            }
                            EasyLoading.dismiss();
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width * 0.02,
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      child: Container(
                        child: IconButton(
                            onPressed: () async {
                              if (classifiedPayments.isNotEmpty) {
                                bool? confirm = await confirmationDialog(
                                    context,
                                    'Do you want to clear the re-classified payments for the current invoice?');
                                if (confirm != true) return;
                              }
                              EasyLoading.show(status: 'please_wait'.tr());
                              cartBloc.clearPayment();
                              classifiedPayments.clear();
                              invDate = '--';
                              invAmount = 0;
                              invLoc = '--';
                              invStation = '--';
                              invCashier = '--';
                              invCustomer = '--';
                              invRemark = '--';
                              hedRemarks = [];
                              invBalance = 0;
                              setState(() {});
                              bool isFetched = await getInvoicePayments();
                              if (isFetched) {
                                setState(() {});
                              } else {
                                EasyLoading.showError(
                                    'Failed to get invoice data !!!');
                              }
                              EasyLoading.dismiss();
                            },
                            icon: Icon(
                              Icons.search,
                            )),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> getInvoicePayments() async {
    final invDataCheckRes = await ApiClient.call(
        "invoice/get_invoice_det/${invController.text}/${POSConfig().locCode}/INV",
        ApiMethod.GET,
        successCode: 200);

    if (invDataCheckRes != null &&
        invDataCheckRes.statusCode == 200 &&
        invDataCheckRes.data != null &&
        invDataCheckRes.data['res'] != '') {
      var det;
      try {
        det = jsonDecode((invDataCheckRes.data?['res'] ?? "").toString());
        var header = det['T_TBLINVHEADER'][0];

        invDate = (header['INVHED_TXNDATE'] ?? '--T').toString().split('T')[0];
        invAmount = header['INVHED_NETAMT'] ?? 0.00;
        invCashier = header['INVHED_CASHIER'] ?? '--';
        invCustomer = header['INVHED_MEMBER'] == ''
            ? '--'
            : header['INVHED_MEMBER'] ?? '--';
        invLoc = (header['INVHED_LOCCODE'] +
                ' - ' +
                det['M_TBLLOCATIONS'][0]['LOC_DESC']) ??
            '--';
        invStation = header['INVHED_STATION'] ?? '--';
        invBalance = header['INVHED_CHANGE'] ?? 0;
        // invRemark = det['T_TBLINVLINEREMARKS'].length == 0
        //     ? '--'
        //     : det['T_TBLINVLINEREMARKS'][0]?['INVREM_LINEREMARKS'] ?? '--';
        try {
          if (det['T_TBLINVREMARKS'].isNotEmpty) {
            Map map = det['T_TBLINVREMARKS'].first;
            map.forEach((k, v) {
              if (k.toString().contains('INVREM_REMARKS') &&
                  v?.toString() != '') {
                // hedRemarks.add(v.toString());
                if (invRemark == '--') {
                  invRemark = v.toString();
                } else {
                  invRemark = invRemark + '\n' + v.toString();
                }
              }
            });
          }
        } catch (e) {}
      } catch (e) {
        // return false;
      }
      try {
        var payDet = det['T_TBLINVPAYMENTS'];
        var payModehead = det['M_TBLPAYMODEHEAD'];
        var payModeDet = det['M_TBLPAYMODEDET'];
        payments = [];
        for (var p in payDet) {
          String phCode = p['INVPAY_PHCODE'];
          String phDesc = payModehead
              .firstWhere((element) => element['PH_CODE'] == phCode)['PH_DESC'];
          String pdCode = p['INVPAY_PDCODE'];
          String pdDesc = '--';
          if (phCode != pdCode) {
            pdDesc = payModeDet.firstWhere(
                (element) => element['PD_CODE'] == pdCode)['PD_DESC'];
          } else {
            pdDesc = phDesc;
          }

          double amount = p['INVPAY_PAIDAMOUNT'] ?? 0;
          DateTime date = DateTime.parse(p['INVPAY_DETDATE'].toString());
          String ref =
              p['INVPAY_REFNO'] == "" ? '--' : p['INVPAY_REFNO'] ?? '--';
          bool cancelled = p['INVPAY_CANCELD'] ?? false;

          payments.add(PaidModel(amount, amount, cancelled, pdCode, phCode, ref,
              date, 1, phDesc, pdDesc));
        }
        return true;
      } catch (e) {}
    } else {
      return false;
    }
    return false;
  }
}

class invDetailRecords extends StatelessWidget {
  const invDetailRecords({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textStyle = CurrentTheme.bodyText1!.copyWith(
        color: CurrentTheme.primaryDarkColor, fontWeight: FontWeight.w600);
    return Expanded(
      flex: 1,
      child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
          child: Row(
            children: [
              Container(
                  width: width * 0.15,
                  child:
                      Text(label.toUpperCase(), style: CurrentTheme.bodyText2)),
              SizedBox(
                width: width * 0.02,
                child: Text(':'),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    value,
                    style: textStyle,
                  ),
                ),
              )
            ],
          )),
    );
  }
}
