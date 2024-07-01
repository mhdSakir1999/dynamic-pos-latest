/// Author: [TM.Sakir] at 2024-01-04

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'indicator.dart';

class PieChartSample extends StatefulWidget {
  final List<String> legendData;
  final Map<String, dynamic> chartData;
  final num totalCount;
  const PieChartSample(
      {super.key,
      required this.legendData,
      required this.chartData,
      required this.totalCount});

  @override
  PieChartSampleState createState() => PieChartSampleState();
}

class PieChartSampleState extends State<PieChartSample> {
  int touchedIndex = -1;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          height: 250.0,
          width: MediaQuery.of(context).size.width * 0.3,
          child: PieChart(
            PieChartData(
                pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                    print(touchedIndex.toString());
                  });
                }),
                borderData: FlBorderData(
                  show: false,
                ),
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: showingSections(
                    widget.chartData, widget.legendData, widget.totalCount)),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: showingLegends(widget.legendData),
        ),
        const SizedBox(
          width: 28,
        ),
      ],
    );
  }

  List<Widget> showingLegends(List<String> legends) {
    return List.generate(legends.length, (i) {
      switch (i) {
        case 0:
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Indicator(
              color: Color.fromARGB(255, 18, 97, 146),
              text: legends[i],
              textColor: Colors.white,
              isSquare: true,
            ),
          );
        case 1:
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Indicator(
              color: Color(0xfff8b250),
              text: legends[i],
              textColor: Colors.white,
              isSquare: true,
            ),
          );
        case 2:
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Indicator(
              color: Color(0xff845bef),
              text: legends[i],
              textColor: Colors.white,
              isSquare: true,
            ),
          );
        case 3:
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Indicator(
              color: Color(0xff13d38e),
              text: legends[i],
              textColor: Colors.white,
              isSquare: true,
            ),
          );
        case 4:
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Indicator(
              color: Color.fromARGB(255, 153, 19, 211),
              text: legends[i],
              textColor: Colors.white,
              isSquare: true,
            ),
          );
        case 5:
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Indicator(
              color: Color.fromARGB(255, 211, 19, 73),
              text: legends[i],
              textColor: Colors.white,
              isSquare: true,
            ),
          );
        default:
          return const SizedBox.shrink();
      }
    });
  }

  List<PieChartSectionData> showingSections(
      Map<String, dynamic> pieData, List<String> legend, num total) {
    double rate = total != 0 ? 100 / total : 100;
    return List.generate(legend.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      switch (i) {
        case 0:
          return pieSectionWidget(pieData, legend, i, rate, radius, fontSize,
              Color.fromARGB(255, 18, 97, 146));
        case 1:
          return pieSectionWidget(pieData, legend, i, rate, radius, fontSize,
              const Color(0xfff8b250));

        case 2:
          return pieSectionWidget(pieData, legend, i, rate, radius, fontSize,
              const Color(0xff845bef));

        case 3:
          return pieSectionWidget(pieData, legend, i, rate, radius, fontSize,
              const Color(0xff13d38e));
        case 4:
          return pieSectionWidget(pieData, legend, i, rate, radius, fontSize,
              Color.fromARGB(255, 153, 19, 211));
        case 5:
          return pieSectionWidget(pieData, legend, i, rate, radius, fontSize,
              Color.fromARGB(255, 211, 19, 73));
        default:
          throw Error();
      }
    });
  }

  PieChartSectionData pieSectionWidget(
      Map<String, dynamic> pieData,
      List<String> legend,
      int i,
      double rate,
      double radius,
      double fontSize,
      Color color) {
    return PieChartSectionData(
      color: color,
      value:
          (pieData[legend[i]] * rate) != 0 ? pieData[legend[i]] * rate : 0.01,
      title: (pieData[legend[i]]) != 0
          ? (pieData[legend[i]]).toStringAsFixed(0)
          : '',
      radius: radius,
      titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff)),
    );
  }
}
