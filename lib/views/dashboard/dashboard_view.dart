import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/dashboard_controller.dart';
import 'package:checkout/models/pos_config.dart';
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
  late Dashboard? dashboardData;
  bool isLoading = true;
  List<CashierMonthlySale>? cashierMonthlySales;
  FocusNode _focusNode = FocusNode();

  // get dashboard data
  Future getDashbordData() async {
    EasyLoading.show(status: 'please_wait'.tr());
    final String? username = userBloc.currentUser?.uSERHEDUSERCODE;
    final String? locationCode = POSConfig().locCode;

    dashboardData = await DashboardController()
        .getDashboardData(username ?? '', locationCode ?? '');

    if (mounted)
      setState(() {
        cashierMonthlySales = dashboardData?.cashierMonthlySales;
        isLoading = false;
      });
    EasyLoading.dismiss();
  }

  @override
  void initState() {
    super.initState();
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
                              "dashboard_view.no_of_loyality_customers".tr(),
                              dashboardData?.noOfLoyaltyRegistrations ?? 0),
                        ),
                        SizedBox(width: 20.0),
                        Expanded(
                            child: cardWidget(
                                Colors.blue,
                                Colors.blueAccent,
                                "dashboard_view.no_of_ebill_reg".tr(),
                                dashboardData?.noOfEbillRegistrations ?? 0)),
                        SizedBox(width: 10.0),
                        Expanded(
                            child: cardWidget(
                                Colors.blue,
                                Colors.blueAccent,
                                // Colors.orange,
                                // Colors.orangeAccent,
                                "dashboard_view.value_of_loyality_trans".tr(),
                                (dashboardData?.valueOfLoyaltyTransactions)
                                        ?.toStringAsFixed(2) ??
                                    0.00.toStringAsFixed(2))),
                        SizedBox(width: 10.0),
                        Expanded(
                            child: cardWidget(
                                Colors.blue,
                                Colors.blueAccent,
                                // Colors.green, Colors.greenAccent,
                                'Test Card 4',
                                0.0)),
                      ],
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                              height: 500.0,
                              width: 500.0,
                              child: LineChartSample1(
                                cashierMonthlySales: cashierMonthlySales,
                              )),
                        ),
                        SizedBox(
                          width: 50.00,
                        ),
                        Expanded(
                            child: SizedBox(
                                height: 500.0,
                                width: 500.0,
                                child: LineChartSample1(
                                  cashierMonthlySales: cashierMonthlySales,
                                )))
                      ],
                    ),
                    const SizedBox(
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
                    )
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
