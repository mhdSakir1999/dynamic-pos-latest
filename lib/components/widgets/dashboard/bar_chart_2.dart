import 'package:checkout/components/widgets/dashboard/legend_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarChartSample2 extends StatefulWidget {
  const BarChartSample2({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BarChartSample2State();
}

class BarChartSample2State extends State<BarChartSample2> {
  final Color topBarColor = const Color(0xff53fdd7);
  final Color bottomBarColor = const Color(0xffff5182);
  final double width = 10;

  late List<BarChartGroupData> rawBarGroups;
  late List<BarChartGroupData> showingBarGroups;

  int touchedGroupIndex = -1;

  @override
  void initState() {
    super.initState();
    final barGroup1 = makeGroupData(0, 5, 12);
    final barGroup2 = makeGroupData(1, 8, 9);
    final barGroup3 = makeGroupData(2, 4, 5);
    // final barGroup4 = makeGroupData(3, 6, 5);
    // final barGroup5 = makeGroupData(4, 10, 11);
    // final barGroup6 = makeGroupData(5, 4, 1.5);
    // final barGroup7 = makeGroupData(6, 5, 1.5);
    // final barGroup8 = makeGroupData(7, 8, 1.5);
    // final barGroup9 = makeGroupData(8, 10, 1.5);
    // final barGroup10 = makeGroupData(9, 7, 1.5);
    // final barGroup11 = makeGroupData(10, 4, 1.5);
    // final barGroup12 = makeGroupData(11, 9, 1.5);

    final items = [
      barGroup1,
      barGroup2,
      barGroup3,
      // barGroup4,
      // barGroup5,
      // barGroup6,
      // barGroup7,
      // barGroup8,
      // barGroup9,
      // barGroup10,
      // barGroup11,
      // barGroup12
    ];

    rawBarGroups = items;

    showingBarGroups = rawBarGroups;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: const Color(0xff2c4260),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    width: 38,
                  ),
                  const Text(
                    'Sales',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  const Spacer(),
                  LegendsListWidget(
                    legends: [
                      Legend("Yesterday", topBarColor),
                      Legend("Today", bottomBarColor),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 38,
              ),
              Expanded(
                child: BarChart(
                  BarChartData(
                    maxY: 20,
                    barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.grey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String weekDay;
                            switch (group.x.toInt()) {
                              case 0:
                                weekDay = 'January';
                                break;
                              case 1:
                                weekDay = 'February';
                                break;
                              case 2:
                                weekDay = 'February';
                                break;
                              case 3:
                                weekDay = 'April';
                                break;
                              case 4:
                                weekDay = 'May';
                                break;
                              case 5:
                                weekDay = 'June';
                                break;
                              case 6:
                                weekDay = 'July';
                                break;
                              case 7:
                                weekDay = 'August';
                                break;
                              case 8:
                                weekDay = 'September';
                                break;
                              case 9:
                                weekDay = 'October';
                                break;
                              case 10:
                                weekDay = 'November';
                                break;
                              case 11:
                                weekDay = 'December';
                                break;
                              default:
                                throw Error();
                            }
                            return BarTooltipItem(
                              weekDay + '\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: (rod.toY - rod.fromY).toString(),
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        touchCallback: (FlTouchEvent event, response) {
                          if (response == null || response.spot == null) {
                            setState(() {
                              touchedGroupIndex = -1;
                              showingBarGroups = List.of(rawBarGroups);
                            });
                            return;
                          }

                          touchedGroupIndex =
                              response.spot!.touchedBarGroupIndex;
                        }),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: bottomTitles,
                          reservedSize: 42,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: leftTitles,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    barGroups: showingBarGroups,
                    gridData: FlGridData(show: false),
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    if (value == 0) {
      text = '1K';
    } else if (value == 10) {
      text = '5K';
    } else if (value == 19) {
      text = '10K';
    } else {
      return Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 0,
      child: Text(text, style: style),
    );
  }

  int index = 0;

  Widget bottomTitles(double value, TitleMeta meta) {
    List<String> titles = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];

    Widget text = Text(
      titles[value.toInt()],
      style: const TextStyle(
        color: Color(0xff7589a2),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16, //margin top
      child: text,
    );
  }

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
        groupVertically: true,
        barsSpace: 4,
        x: x,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: y1,
            color: topBarColor,
            width: width,
          ),
          BarChartRodData(
            fromY: y1,
            toY: y1 + y2,
            color: bottomBarColor,
            width: width,
          ),
        ]);
  }

  Widget makeTransactionsIcon() {
    const width = 4.5;
    const space = 3.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 42,
          color: Colors.white.withOpacity(1),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
      ],
    );
  }
}
