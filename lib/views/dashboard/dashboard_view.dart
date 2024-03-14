/// Author: [TM.Sakir] at 2024-01-04

import 'dart:convert';

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/dashboard_controller.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:checkout/components/widgets/pos_background.dart';
import 'package:checkout/components/widgets/dashboard/bar_chart_2.dart';
import 'package:checkout/components/widgets/dashboard/line_chart.dart';
import 'package:checkout/components/widgets/dashboard/pie_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:checkout/components/widgets/go_back.dart';

import '../../components/current_theme.dart';
import '../../models/dashboard_model.dart';

class DashboardView extends StatefulWidget {
  static const routeName = "dashboard";

  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // late Dashboard? dashboardData;
  String? dashboardData;
  bool isLoading = true;
  List<CashierMonthlySale>? cashierMonthlySales;
  FocusNode _focusNode = FocusNode();
  TextEditingController dateController = TextEditingController(
      text:
          '${DateFormat("yyyy-MM-dd").parse(DateTime.now().toIso8601String())}');
  int totInvoiceCount = 0;
  int cashierInvCount = 0;
  int loyaltyInvCount = 0;
  int cashierloyaltyInvCount = 0;
  List payModeWiseBillCount = [];
  num totalPayModeInvCount = 0;
  List utilityBillCount = [];

  // get dashboard data
  Future getDashbordData() async {
    EasyLoading.show(status: 'please_wait'.tr());
    try {
      final String? username = userBloc.currentUser?.uSERHEDUSERCODE;
      final String terminalId = POSConfig().terminalId;
      final String? shift = userBloc.currentUser?.shiftNo;
      final String? signOnDate = userBloc.currentUser?.uSERHEDSIGNONDATE;
      final String? salesDate = dateController.text.isEmpty
          ? DateFormat("yyyy-MM-dd")
              .parse(DateTime.now().toIso8601String())
              .toString()
          : dateController.text;
      final String? locationCode = POSConfig().locCode;

      dashboardData = await DashboardController().getDashboardData(
          cashier: username,
          locationCode: locationCode,
          shift: int.parse(shift ?? "0"),
          terminal: terminalId,
          signOnDate: signOnDate,
          salesDate: salesDate);

      setState(() {
        totInvoiceCount =
            jsonDecode(dashboardData!)['SummaryInfo'].first['TotInvCount'];
        cashierInvCount = jsonDecode(dashboardData!)['SummaryInfo']
            .first['TotInvCount_Cashier'];
        loyaltyInvCount = jsonDecode(dashboardData!)['SummaryInfo']
            .first['TotInvCount_Loyalty'];
        cashierloyaltyInvCount = jsonDecode(dashboardData!)['SummaryInfo']
            .first['TotInvCount_Cashier_Loyalty'];
        var x = jsonDecode(dashboardData!)['PayModeWiseBillCount'];
        payModeWiseBillCount =
            jsonDecode(dashboardData!)['PayModeWiseBillCount'];
        totalPayModeInvCount = 0;
        payModeWiseBillCount!.forEach(
            (element) => totalPayModeInvCount += element['TotalCount']);
        utilityBillCount = jsonDecode(dashboardData!)['UtilityBillCount'];
      });
    } catch (e) {
      print(e);
    }
    if (mounted)
      setState(() {
        // cashierMonthlySales = dashboardData?.cashierMonthlySales;
        isLoading = false;
      });
    EasyLoading.dismiss();
  }

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat("yyyy-MM-dd")
        .parse(DateTime.now().toString())
        .toString()
        .split(' ')[0];
    getDashbordData();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    final currentHeight = MediaQuery.of(context).size.height;
    return POSBackground(
      child: Scaffold(
        body: isLoading
            ? Container()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Center(
                    //   child: Text('Height : $currentHeight'),
                    // ),
                    // Center(
                    //   child: Text('Width : $currentWidth'),
                    // ),

                    Card(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 15.r,
                          ),
                          RawKeyboardListener(
                              focusNode: _focusNode,
                              onKey: (value) {
                                if (value is RawKeyDownEvent) {
                                  if (value.physicalKey ==
                                      PhysicalKeyboardKey.escape) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              child: GoBackIconButton()),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.r, vertical: 10.r),
                            child: Center(
                                child: Text(
                              "dashboard_view.home".tr(),
                              style: CurrentTheme.bodyText2!
                                  .copyWith(color: CurrentTheme.primaryColor),
                            )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: currentWidth * 0.34,
                        child: Card(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 25,
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Container(
                                // padding: EdgeInsets.only(right: 10),
                                // height: currentHeight * 0.1,
                                width: currentWidth * 0.2,
                                child: DateTimeField(
                                  controller: dateController,
                                  enabled: true,
                                  format: DateFormat("yyyy-MM-dd"),
                                  initialValue: dateController.text.isEmpty
                                      ? DateFormat("yyyy-MM-dd")
                                          .parse(DateTime.now().toString())
                                      : DateFormat("yyyy-MM-dd")
                                          .parse(dateController.text),
                                  style: TextStyle(
                                      color: CurrentTheme.primaryColor,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold),
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
                                      dateController.text =
                                          DateFormat("yyyy-MM-dd").format(date);
                                    // return date;
                                    await getDashbordData();
                                    setState(() {});
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              IconButton(
                                  onPressed: () async {
                                    await getDashbordData();
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.loop))
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: cardWidget(
                              // Colors.purple,
                              // Colors.purpleAccent,
                              Colors.blue,
                              Colors.blueAccent,
                              "dashboard_view.tot_Inv_Count".tr(),
                              totInvoiceCount),
                        ),
                        SizedBox(width: 20.0),
                        Expanded(
                            child: cardWidget(
                                Colors.blue,
                                Colors.blueAccent,
                                "dashboard_view.cashier_Inv_Count".tr(),
                                cashierInvCount)),
                        SizedBox(width: 10.0),
                        Expanded(
                            child: cardWidget(
                                Colors.blue,
                                Colors.blueAccent,
                                // Colors.orange,
                                // Colors.orangeAccent,
                                "dashboard_view.loyalty_Inv_Count".tr(),
                                // (dashboardData?.valueOfLoyaltyTransactions)
                                //         ?.toStringAsFixed(2) ??
                                loyaltyInvCount)),
                        SizedBox(width: 10.0),
                        Expanded(
                            child: cardWidget(
                                Colors.blue,
                                Colors.blueAccent,
                                // Colors.green, Colors.greenAccent,
                                'dashboard_view.cashier_loyalty_Inv_Count'.tr(),
                                cashierloyaltyInvCount)),
                      ],
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Expanded(
                    //       child: cardWidget(
                    //           // Colors.purple,
                    //           // Colors.purpleAccent,
                    //           Colors.blue,
                    //           Colors.blueAccent,
                    //           "PayModeWiseBillCount".tr(),
                    //           0),
                    //     ),
                    //     SizedBox(width: 20.0),
                    //     Expanded(
                    //         child: cardWidget(Colors.blue, Colors.blueAccent,
                    //             "PayModeWiseBillCount".tr(), 0)),
                    //   ],
                    // ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Card(
                          margin: EdgeInsets.all(16),
                          elevation: 3,
                          color: Colors.blueAccent,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  "Invoices (Terminal wise)",
                                ),
                                totInvoiceCount != 0
                                    ? PieChartSample(
                                        legendData: [
                                          'My Non-Loyalty',
                                          'My Loyalty',
                                          "Other's Non-Loyalty",
                                          "Other's Loyalty"
                                        ],
                                        chartData: {
                                          'My Non-Loyalty': cashierInvCount -
                                              cashierloyaltyInvCount,
                                          'My Loyalty': cashierloyaltyInvCount,
                                          "Other's Non-Loyalty": totInvoiceCount -
                                              (loyaltyInvCount +
                                                  (cashierInvCount -
                                                      cashierloyaltyInvCount)),
                                          "Other's Loyalty": loyaltyInvCount -
                                              cashierloyaltyInvCount
                                        },
                                        totalCount: totInvoiceCount,
                                      )
                                    : SizedBox(
                                        height: 250.0,
                                        width: 250.0,
                                        child: Center(
                                            child: Text("No data available"))),
                              ],
                            ),
                          ),
                        )),
                        Expanded(
                            child: Card(
                          margin: EdgeInsets.all(16),
                          elevation: 3,
                          color: Colors.blueAccent,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text("Invoices (Payment mode wise)"),
                                payModeWiseBillCount!.length != 0
                                    ? PieChartSample(
                                        legendData: List.generate(
                                            payModeWiseBillCount.length, (i) {
                                          return payModeWiseBillCount[i]
                                                  ?['PH_DESC'] ??
                                              '-';
                                        }),
                                        chartData: Map.fromIterable(
                                          payModeWiseBillCount,
                                          key: (element) => element['PH_DESC'],
                                          value: (element) =>
                                              element['TotalCount'],
                                        ),
                                        totalCount: totalPayModeInvCount,
                                      )
                                    : SizedBox(
                                        height: 250.0,
                                        width: 250.0,
                                        child: Center(
                                            child: Text("No data available"))),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Card(
                          margin: EdgeInsets.all(16),
                          elevation: 3,
                          color: Colors.blueAccent,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text("Bill Collections"),
                                utilityBillCount.length != 0
                                    ? PieChartSample(
                                        legendData: [
                                          'Water Bill',
                                          'Electricity',
                                          "Telephone Bill",
                                          "Dialog",
                                          "Etisalat"
                                        ],
                                        chartData: {
                                          'Water Bill': 0,
                                          'Electricity': 0,
                                          "Telephone Bill": 0,
                                          "Dialog": 0,
                                          "Etisalat": 0
                                        },
                                        totalCount: totInvoiceCount,
                                      )
                                    : SizedBox(
                                        height: 250.0,
                                        width: 250.0,
                                        child: Center(
                                            child: Text("No data available"))),
                              ],
                            ),
                          ),
                        )),
                        Expanded(
                            child: Card(
                          margin: EdgeInsets.all(16),
                          elevation: 3,
                          color: Colors.blueAccent,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text("Bill Collections"),
                                utilityBillCount.length != 0
                                    ? PieChartSample(
                                        legendData: [
                                          'Water Bill',
                                          'Electricity',
                                          "Telephone Bill",
                                          "Dialog",
                                          "Etisalat"
                                        ],
                                        chartData: {
                                          'Water Bill': 0,
                                          'Electricity': 0,
                                          "Telephone Bill": 0,
                                          "Dialog": 0,
                                          "Etisalat": 0
                                        },
                                        totalCount: totInvoiceCount,
                                      )
                                    : SizedBox(
                                        height: 250.0,
                                        width: 250.0,
                                        child: Center(
                                            child: Text("No data available"))),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: SizedBox(
                    //           height: 500.0,
                    //           width: 500.0,
                    //           child: LineChartSample1(
                    //             cashierMonthlySales: cashierMonthlySales,
                    //           )),
                    //     ),
                    //     SizedBox(
                    //       width: 50.00,
                    //     ),
                    //     Expanded(
                    //         child: SizedBox(
                    //             height: 500.0,
                    //             width: 500.0,
                    //             child: LineChartSample1(
                    //               cashierMonthlySales: cashierMonthlySales,
                    //             )))
                    //   ],
                    // ),
                    /* const SizedBox(
                      height: 20.0,
                    ),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        currentWidth < 1500
                            ? Column(
                                children: [
                                  PieChartSample2(),
                                  PieChartSample2()
                                ],
                              )
                            : Expanded(
                                child: Row(
                                  children: const [
                                    Expanded(child: PieChartSample2()),
                                    Expanded(child: PieChartSample2())
                                  ],
                                ),
                              ),
                        const SizedBox(
                          width: 50.0,
                        ),
                        const Expanded(
                            child: SizedBox(
                                height: 500.0,
                                width: 500.0,
                                child: BarChartSample2()))
                      ],
                    ) */
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: SizedBox(
                    //         child: BarChartSample2(),
                    //         height: 500,
                    //       ),
                    //     ),
                    //   ],
                    // )
                  ],
                ),
              ),
      ),
    );
  }
}

Widget cardWidget(Color color1, Color color2, String cardTitle, amount) {
  return Card(
    elevation: 5.0,
    color: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
    child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: [color1, color2])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cardTitle),
            SizedBox(
              height: 10.0,
            ),
            Text('$amount')
          ],
        )),
  );
}
