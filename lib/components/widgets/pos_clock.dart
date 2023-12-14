/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/22/21, 9:52 PM
 */

//This is the default clock ui use in app
import 'package:checkout/components/components.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class POSClock extends StatelessWidget {
  final bool centerAlign;
  final double timeFontSize;
  final double dateFontSize;

  const POSClock({Key? key, this.centerAlign = false,this.timeFontSize=27,this.dateFontSize=13}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TimerBuilder.periodic(
      Duration(seconds: 1),
      builder: (context) {
        var now = new DateTime.now();
        final date = DateFormat.yMMMMEEEEd().format(now);
        final time = DateFormat("hh:mm:ss aa").format(now);
        return Column(
          crossAxisAlignment:
              centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: CurrentTheme.headline4!
                  .copyWith(fontWeight: FontWeight.bold, fontSize: timeFontSize.sp),
            ),
            Text(
              date,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: dateFontSize.sp),
            ),
          ],
        );
      },
    );
  }
}
