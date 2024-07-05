/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/28/21, 2:19 PM
 */
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/shift_reconciliation/shift_reconciliation_entering_view.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../bloc/user_bloc.dart';

class ShiftReconciliationView extends StatelessWidget {
  static const routeName = "shift_reconciliation_view";
  @override
  Widget build(BuildContext context) {
    return POSBackground(
        child: Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
              child: POSClock(
            centerAlign: true,
          )),
          SizedBox(
            height: 25.h,
          ),
          Card(
            child: Container(
              width: 450.h,
              padding: EdgeInsets.symmetric(vertical: 15.0.r, horizontal: 20.r),
              child: Center(
                  child: Text(
                "shift_reconciliation_view.title".tr(),
                style: CurrentTheme.bodyText2!
                    .copyWith(color: CurrentTheme.primaryColor),
              )),
            ),
          ),
          SizedBox(
            height: 25.h,
          ),
          Container(height: 150.h, child: buildShiftList(context))
        ],
      ),
    ));
  }

  Widget buildShiftList(BuildContext context) {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildCard(context),
          buildCard(context),
          buildCard(context),
          buildCard(context),
          buildCard(context),
        ],
      ),
    );
  }

  Widget buildCard(BuildContext context) {
    final user = userBloc.currentUser;
    final String name = user?.uSERHEDTITLE ?? '';
    final shiftNo = user?.shiftNo ?? "";
    return Container(
      child: Column(
        children: [
          Container(height: 40.h, width: 40.h, child: UserImage()),
          InkWell(
            onTap: () {
              String routeName = ShiftReconciliationEntryView.routeName;
              POSLoggerController.addNewLog(
                  POSLogger(POSLoggerLevel.info, "Navigate to $routeName"));
              Navigator.pushNamed(context, routeName);
            },
            child: Card(
              child: Container(
                  alignment: Alignment.center,
                  padding:
                      EdgeInsets.symmetric(horizontal: 15.r, vertical: 10.r),
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: CurrentTheme.bodyText2!.copyWith(
                            color: CurrentTheme.primaryColor,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "shift_reconciliation_view.shift"
                            .tr(namedArgs: {"shift": shiftNo.toString()}),
                        style: CurrentTheme.subtitle2!.copyWith(
                            color: CurrentTheme.primaryColor,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  )),
            ),
          )
        ],
      ),
    );
  }
}
