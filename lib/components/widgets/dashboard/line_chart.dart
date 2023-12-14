import 'package:checkout/models/dashboard_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineChartView extends StatelessWidget {
  List<FlSpot>? thisMonthSalePoints;
  List<FlSpot>? lastMonthSalesPoints;

  LineChartView(
      {Key? key,
      required this.thisMonthSalePoints,
      required this.lastMonthSalesPoints})
      : super(key: key);

  LineChartData get sampleData1 => LineChartData(
        lineTouchData: lineTouchData1,
        lineBarsData: lineBarsData1,
        gridData: gridData,
        titlesData: titlesData1,
        borderData: borderData,
        minX: 0,
        maxX: 32,
        maxY: 100,
        minY: 0,
      );

  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                double sale = flSpot.y * 1000;
                return LineTooltipItem(
                  'Rs. $sale',
                  TextStyle(
                    color: barSpot.bar.gradient?.colors.first ??
                        barSpot.bar.color ??
                        Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            }),
      );

  FlTitlesData get titlesData1 => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: bottomTitles,
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: leftTitles(),
        ),
      );

  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_1,
        // lineChartBarData1_2,
        // lineChartBarData1_3,
      ];

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff75729e),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    switch (value.toInt()) {
      case 10:
        text = '10k';
        break;
      case 20:
        text = '20k';
        break;
      case 30:
        text = '30k';
        break;
      case 40:
        text = '40k';
        break;
      case 50:
        text = '50k';
        break;
      case 60:
        text = '60k';
        break;
      case 70:
        text = '70k';
        break;
      case 80:
        text = '80k';
        break;
      case 90:
        text = '90k';
        break;
      case 100:
        text = '100k';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  SideTitles leftTitles() => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        interval: 1,
        reservedSize: 40,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff72719b),
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    switch (value.toInt()) {
      case 5:
        text = const Text('Day 05', style: style);
        break;
      case 10:
        text = const Text('Day 10', style: style);
        break;
      case 15:
        text = const Text('Day 15', style: style);
        break;
      case 20:
        text = const Text('Day 20', style: style);
        break;
      case 25:
        text = const Text('Day 25', style: style);
        break;
      case 30:
        text = const Text('Day 30', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  FlGridData get gridData => FlGridData(show: false);

  FlBorderData get borderData => FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Color(0xff4e4965), width: 4),
          left: BorderSide(color: Colors.transparent),
          right: BorderSide(color: Colors.transparent),
          top: BorderSide(color: Colors.transparent),
        ),
      );

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
        isCurved: true,
        color: const Color(0xff4af699),
        barWidth: 8,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: const [
          // FlSpot(2, 1),
          // FlSpot(3, 1.5),
          // FlSpot(5, 1.4),
          // FlSpot(7, 3.4),
          // FlSpot(10, 2),
          // FlSpot(12, 2.2),
          // FlSpot(13, 1.8),

          // FlSpot(8.0, 4751.0),
          // FlSpot(10.0, 13502.0),
          // FlSpot(22.0, 3040.24),
          // FlSpot(23.0, 2752.0),
          // FlSpot(24.0, 51427.6),
          // FlSpot(27.0, 2234.4),
          // FlSpot(29.0, 20837.0),
          // FlSpot(30.0, 14495.65)

          FlSpot(8.0, 4.751),
          FlSpot(10.0, 13.502),
          FlSpot(22.0, 3.04024),
          FlSpot(23.0, 2.752),
          FlSpot(24.0, 51.4276),
          FlSpot(27.0, 2.2344),
          FlSpot(29.0, 20.8370),
          FlSpot(30.0, 14.49565)
        ],
        // spots: lastMonthSalesPoints,
      );

  // LineChartBarData get lineChartBarData1_2 => LineChartBarData(
  //       isCurved: true,
  //       color: const Color(0xffaa4cfc),
  //       barWidth: 8,
  //       isStrokeCapRound: true,
  //       dotData: FlDotData(show: false),
  //       belowBarData: BarAreaData(
  //         show: false,
  //         color: const Color(0x00aa4cfc),
  //       ),
  //       spots: const [
  //         FlSpot(1, 1),
  //         FlSpot(3, 2.8),
  //         FlSpot(7, 1.2),
  //         FlSpot(10, 2.8),
  //         FlSpot(12, 2.6),
  //         FlSpot(13, 3.9),
  //       ],
  //     );

  // LineChartBarData get lineChartBarData1_3 => LineChartBarData(
  //       isCurved: true,
  //       color: const Color(0xff27b6fc),
  //       barWidth: 8,
  //       isStrokeCapRound: true,
  //       dotData: FlDotData(show: false),
  //       belowBarData: BarAreaData(show: false),
  //       spots: const [
  //         FlSpot(1, 2.8),
  //         FlSpot(3, 1.9),
  //         FlSpot(6, 3),
  //         FlSpot(10, 1.3),
  //         FlSpot(13, 2.5),
  //       ],
  //     );

  @override
  Widget build(BuildContext context) {
    return LineChart(
      sampleData1,
     // swapAnimationDuration: const Duration(milliseconds: 250),
     duration: const Duration(milliseconds: 250),
    );
  }
}

class LineChartSample1 extends StatefulWidget {
  final List<CashierMonthlySale>? cashierMonthlySales;

  const LineChartSample1({Key? key, required this.cashierMonthlySales})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      LineChartSample1State(this.cashierMonthlySales);
}

class LineChartSample1State extends State<LineChartSample1> {
  final List<CashierMonthlySale>? cashierMonthlySales;

  late bool isShowingMainData;

  List<FlSpot> thisMonthSalePoints = [];
  List<FlSpot> lastMonthSalesPoints = [];

  LineChartSample1State(this.cashierMonthlySales);

  void getallSalesPoints() {
    if (cashierMonthlySales != null) {
      final int currentMonth = DateTime.now().month;

      for (var sale in cashierMonthlySales!) {
        if (sale.transactionDate?.month == currentMonth) {
          thisMonthSalePoints
              .add(FlSpot(sale.transactionDate!.day.toDouble(), sale.sales!));
        } else {
          lastMonthSalesPoints
              .add(FlSpot(sale.transactionDate!.day.toDouble(), sale.sales!));
        }
      }

      setState(() {});

      // print(thisMonthSalePoints);
      print(lastMonthSalesPoints);
    }
  }

  @override
  void initState() {
    super.initState();
    isShowingMainData = true;
    getallSalesPoints();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        gradient: LinearGradient(
          colors: [
            Color(0xff2c274c),
            Color(0xff46426c),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(
                height: 37,
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                'Monthly Sales',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 37,
              ),
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, left: 6.0),
                    child: LineChartView(
                        thisMonthSalePoints: thisMonthSalePoints,
                        lastMonthSalesPoints: lastMonthSalesPoints)),
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white.withOpacity(isShowingMainData ? 1.0 : 0.5),
            ),
            onPressed: () {
              setState(() {
                isShowingMainData = !isShowingMainData;
              });
            },
          )
        ],
      ),
    );
  }
}
