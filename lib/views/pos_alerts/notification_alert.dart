/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/23/21, 10:31 AM
 */
import 'package:checkout/bloc/notification_bloc.dart';
import 'package:checkout/controllers/notification_controller.dart';
import 'package:checkout/models/pos/notification_results.dart';
import 'package:checkout/views/pos_alerts/pos_alert_template.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/current_theme.dart';
import '../../models/pos_config.dart';
import 'package:checkout/extension/extensions.dart';

/// This is the notification screen for app
class NotificationAlert extends StatefulWidget {
  const NotificationAlert({Key? key}) : super(key: key);

  @override
  _NotificationAlertState createState() => _NotificationAlertState();
}

class _NotificationAlertState extends State<NotificationAlert> {
  @override
  Widget build(BuildContext context) {
    final style2 =
        CurrentTheme.bodyText1?.copyWith(color: CurrentTheme.primaryLightColor);
    notificationBloc.getNotifications();
    return StreamBuilder(
      stream: notificationBloc.notificationStream,
      builder:
          (BuildContext context, AsyncSnapshot<NotificationResults?> snapshot) {
        final List<Notifications> notifications =
            snapshot.data?.notifications ?? [];
        if (notifications.isEmpty) {
          return POSAlertTemplate(
            icon: Icons.notifications_active_outlined,
            rightButtonPressed: () {
              Navigator.pop(context);
            },
            rightButtonText: "notifications.done_button".tr(),
            title: "notifications.notification_title".tr(),
            expNotification: false,
          );
        }

        return POSAlertTemplate(
          expNotificationSpacer: false,
          widgets: notifications.map((e) {
            String date = e.cRDATE ?? '';
            if (date.isNotEmpty) {
              date =
                  DateFormat("dd/MM/yyyy HH:mm").format(date.parseDateTime());
            }
            return SizedBox(
                width: POSConfig().containerSize.w,
                child: Dismissible(
                  background: _slideBackground(false),
                  secondaryBackground: _slideBackground(true),
                  confirmDismiss: (dir) async {
                    await _readNotification(e.notIID?.toString() ?? "-1");
                    return true;
                  },
                  key: Key(e.notIID?.toString() ?? "-1"),
                  child: Card(
                    color: CurrentTheme.primaryColor,
                    child: Padding(
                        padding: EdgeInsets.all(25.r),
                        child: Column(
                          children: [
                            Text(e.notIMESSAGE?.trim() ?? ''),
                            Align(
                              alignment: Alignment.centerRight,
                              child: RichText(
                                  text: TextSpan(style: style2, children: [
                                if (e.cRBY != null)
                                  TextSpan(
                                      text: "By ",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: e.cRBY,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                if (e.cRBY != null) TextSpan(text: "- "),
                                TextSpan(text: date)
                              ])),
                            )
                          ],
                        )),
                  ),
                ));
          }).toList(),
          icon: Icons.notifications_active_outlined,

          /// change by [TM.Sakir]
          rightButtonPressed: () {
            // since, the id passed, is not a correct id of the actual notifications
            // _readNotification("-1");

            // So, this approach can clear all messages by iteratively passing notification ids
            notifications.forEach((element) async =>
                await _readNotification(element.notIID.toString()));
            EasyLoading.showSuccess('app_bar.notification_clear'.tr());
            Navigator.pop(context);
          },
          rightButtonText: "notifications.done_button".tr(),
          title: "notifications.notification_title".tr(),
          expNotification: false,
        );
      },
    );
  }

  /// right side background of dismissible widget
  Widget _slideBackground(bool secondary) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft:
              Radius.circular(POSConfig().rounderBorderRadiusBottomLeft),
          bottomRight:
              Radius.circular(POSConfig().rounderBorderRadiusBottomRight),
          topLeft: Radius.circular(POSConfig().rounderBorderRadiusTopLeft),
          topRight: Radius.circular(POSConfig().rounderBorderRadiusTopRight),
        ),
      ),
      child: Align(
        child: Row(
          mainAxisAlignment:
              secondary ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(
              width: 20,
            ),
            const Icon(
              Icons.delete,
              color: Colors.amber,
            ),
            Text(
              " ${"notifications.clear".tr()}",
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(
              width: 20,
            ),
          ],
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Future<void> _readNotification(String id) async {
    await NotificationController().readNotification(id);
    notificationBloc.getNotifications();
    if (mounted) {
      setState(() {});
    }
  }
}
