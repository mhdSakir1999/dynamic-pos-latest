/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/21/21, 10:47 AM
 */
import 'dart:ui';

import 'package:checkout/bloc/lock_screen_bloc.dart';
import 'package:checkout/bloc/notification_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/mypos_screen_utils.dart';
import 'package:checkout/components/widgets/commonUse.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/views/authentication/lock_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/pos/announcement_result.dart';

/// This class use to display the background color of the screen
class POSBackground extends StatelessWidget {
  final Widget child;
  final bool showConnection;
  final Alignment alignment;

  const POSBackground(
      {Key? key,
      required this.child,
      this.showConnection = false,
      this.alignment = Alignment.topLeft})
      : super(key: key);
  // POSBackground(
  //     {Key? key,
  //     required this.child,
  //     this.showConnection = false,
  //     this.centralBottom = false})
  //     : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _announcement(),
            _showSubscriptionMessage(),
            Expanded(
              child: StreamBuilder(
                stream: lockScreenBloc.lockScreenStream,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  return buildView(snapshot.data ?? false);
                },
              ),
            ),
          ],
        ),
        if (POSConfig().trainingMode)
          const Positioned(
              right: 10,
              top: 10,
              child: Row(
                children: [
                  const Icon(
                    Icons.circle_rounded,
                    color: const Color.fromARGB(255, 245, 221, 11),
                    size: 12,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  const Text(
                    'Training Mode',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  )
                ],
              ))
      ],
    );
  }

  Widget _announcement() {
    return StreamBuilder(
      stream: notificationBloc.announcementStream,
      builder:
          (BuildContext context, AsyncSnapshot<List<Announcement>> snapshot) {
        final announcements = snapshot.data ?? [];
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: announcements.length,
          itemBuilder: (BuildContext context, int index) {
            Announcement myAnnouncement = announcements[index];
            Color color = Colors.red;
            switch (myAnnouncement.annOTYPE?.toLowerCase()) {
              case "warning":
                color = Color(0xFFf1b44c);
                break;
              case "danger":
                color = Color(0xFFf46a6a);
                break;
              case "success":
                color = Color(0xFF34c38f);
                break;
              case "info":
                color = Color(0xFF50a5f1);
                break;
            }

            return _topNotice(
                text: myAnnouncement.annOMESSAGE ?? '',
                color: color,
                onClick: () => notificationBloc
                    .removeAnnouncement(myAnnouncement.annOID ?? ''));
          },
        );
      },
    );
  }

  Widget _showSubscriptionMessage() {
    return StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        if (POSConfig().licenseMessage.isEmpty) return const SizedBox.shrink();
        return _topNotice(
            text: POSConfig().licenseMessage,
            color: POSConfig().licenseMessageColor,
            onClick: () {
              POSConfig().licenseMessage = '';
              setState(() {});
            });
      },
    );
  }

  Widget _topNotice(
      {required String text,
      required Color color,
      required VoidCallback onClick}) {
    return Tooltip(
      message: text,
      child: Material(
        elevation: 5,
        child: Container(
          width: double.infinity,
          color: color,
          padding: EdgeInsets.symmetric(vertical: 10.r, horizontal: 10.r),
          child: Row(
            children: [
              Text(
                text,
                style: CurrentTheme.bodyText1,
              ),
              const Spacer(),
              InkWell(
                onTap: onClick,
                child: Text(
                  'activation.close'.tr(),
                  style: CurrentTheme.bodyText1,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildView(bool locked) {
    return Stack(
      alignment: alignment,
      children: [
        SizedBox.expand(
          child: Container(
            color: CurrentTheme.backgroundColor,
          ),
        ),
        isMobile ? SafeArea(child: child) : child,
        !locked
            ? const SizedBox.shrink()
            : SizedBox.expand(
                child: BackdropFilter(
                  filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: new BoxDecoration(
                        color: CurrentTheme.backgroundColor!.withOpacity(0.75)),
                    child: LockScreen(),
                  ),
                ),
              ),
        connectionWidget()
      ],
    );
  }

  Widget connectionWidget() {
    if (showConnection) {
      return Positioned(child: connectionWidgetData());
    }
    return const SizedBox.shrink();
  }
}
