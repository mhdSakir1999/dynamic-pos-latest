/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/4/21, 4:45 PM
 */
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:flutter/material.dart';

class POSWarningAlert extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool showFlare;

  const POSWarningAlert(
      {Key? key,
      required this.title,
      required this.subtitle,
      required this.actions,
      this.showFlare = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return POSFlareAlert(
      title: title,
      subtitle: subtitle,
      actions: actions,
      flarePath: "assets/flare/waring.flr",
      flareAnimation: "animate",
      showFlare: showFlare,
    );
  }
}
