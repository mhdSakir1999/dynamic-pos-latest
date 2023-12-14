/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/4/21, 4:45 PM
 */
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:supercharged/supercharged.dart';

class POSErrorAlert extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextAlign? subtitleAlign;
  final List<Widget> actions;
  final bool extraWidth;

  const POSErrorAlert(
      {Key? key,
      required this.title,
      required this.subtitle,
      this.subtitleAlign,
      required this.actions,
      this.extraWidth = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return POSFlareAlert(
        title: title,
        subtitle: subtitle,
        subtitleAlign: subtitleAlign,
        actions: actions,
        extraWidth: extraWidth,
        flarePath: "assets/flare/error.flr",
        flareAnimation: "error");
  }
}

class AlertDialogButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const AlertDialogButton(
      {Key? key, required this.onPressed, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 60, minWidth: 100),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      POSConfig().rounderBorderRadiusBottomLeft)),
              backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
          onPressed: onPressed,
          child: RichText(
              text: TextSpan(text: '', children: [
            TextSpan(
                text: text.substring(0, 1),
                style: CurrentTheme.headline6
                    ?.copyWith(decoration: TextDecoration.underline)),
            TextSpan(text: text.substring(1), style: CurrentTheme.headline6)
          ]))

          // Text(
          //   text,
          //   style: CurrentTheme.headline6,
          // ),
          ),
    );
  }
}
