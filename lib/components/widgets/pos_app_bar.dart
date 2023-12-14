/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/22/21, 1:57 PM
 */

import 'package:checkout/bloc/lock_screen_bloc.dart';
import 'package:checkout/bloc/notification_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/views/landing/landing.dart';
import 'package:checkout/views/pos_alerts/notification_alert.dart';
import 'package:checkout/views/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/pos/notification_results.dart';

/// This widget contains the pos system top app bar
class POSAppBar extends StatelessWidget {
  final height = POSConfig().topAppBarSize.h;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: POSConfig().containerSize.w,
        height: height,
        child: Card(
          color: CurrentTheme.primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(POSConfig().rounderBorderRadius2)),
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 5,
                  child: appBarButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) {
                            return SettingView();
                          },
                        );
                      },
                      text: "app_bar.settings".tr(),
                      icon: Icons.settings,
                      context: context),
                ),
                Expanded(
                  flex: 4,
                  child: appBarButton(
                      onPressed: () {
                        DualScreenController().setView('landing');
                        if (userBloc.currentUser != null) //new change
                          Navigator.pushReplacementNamed(
                              context, LandingView.routeName);
                      },
                      text: "app_bar.home".tr(),
                      icon: Icons.home,
                      context: context),
                ),
                Expanded(
                  flex: 4,
                  child: appBarButton(
                      onPressed: () {
                        lockScreenBloc.setLocked(true);
                      },
                      text: "app_bar.lock".tr(),
                      icon: Icons.lock,
                      context: context),
                ),
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      StreamBuilder<NotificationResults?>(
                          stream: notificationBloc.notificationStream,
                          builder: (context,
                              AsyncSnapshot<NotificationResults?> snapshot) {
                            return Positioned(
                                left: 4,
                                top: 10,
                                child: Text(
                                  // (snapshot.data?.count ?? '').toString(),
                                  (snapshot.data?.count == null ||
                                          snapshot.data?.count == 0)
                                      ? ''
                                      : (snapshot.data?.count ?? '').toString(),
                                  style: CurrentTheme.bodyText1?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold),
                                ));
                          }),
                      appBarButton(
                          onPressed: () {
                            if (userBloc.currentUser != null) //new change
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) {
                                  return NotificationAlert();
                                },
                              );
                          },
                          text: "app_bar.notification".tr(),
                          icon: Icons.notifications,
                          context: context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget appBarButton(
      {required VoidCallback onPressed,
      required String text,
      required IconData icon,
      required BuildContext context}) {
    if (ScreenUtil().screenWidth < 700) {
      return Container(
          height: height,
          child: IconButton(icon: Icon(icon), onPressed: onPressed));
    } else {
      return Container(
        height: height,
        child: TextButton.icon(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: CurrentTheme.primaryLightColor,
            ),
            label: Text(
              text,
              style: TextStyle(
                  color: CurrentTheme.primaryLightColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600),
            )),
      );
    }
  }
}
