/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/4/21, 4:37 PM
 */

import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class LandingAlertController {
  late BuildContext context;
  FocusNode focusNode = FocusNode();
  FocusNode errorFocusNode = new FocusNode();

  init(BuildContext context) {
    this.context = context;
  }

  showLockAlert(String key, bool lock) {
    showDialog(
      context: context,
      builder: (context) => POSFlareAlert(
          title: "$key.title".tr(),
          subtitle: "$key.subtitle".tr(),
          actions: [
            KeyboardListener(
              focusNode: focusNode,
              autofocus: true,
              onKeyEvent: (value) {
                // if (value is KeyDownEvent) {
                //   if (value.physicalKey == PhysicalKeyboardKey.enter ||
                //       value.physicalKey == PhysicalKeyboardKey.keyO) {
                //     Navigator.pop(context);
                //   }
                // }
              },
              child: AlertDialogButton(
                  onPressed: () => Navigator.pop(context),
                  text: "$key.okay".tr()),
            )
            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //       primary: POSConfig().primaryDarkGrayColor.toColor()),
            //   onPressed: () {
            //     Navigator.pop(context);
            //   },
            //   child: Text(
            //     "$key.okay".tr(),
            //     style: Theme.of(context).dialogTheme.contentTextStyle,
            //   ),
            // )
          ],
          flarePath: "assets/flare/locker.flr",
          flareAnimation: lock ? "lock" : "unlock"),
    );
  }

  showErrorAlert(String key, {Map<String, String>? namedArgs}) {
    errorFocusNode.requestFocus();
    showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: "$key.title".tr(namedArgs: namedArgs),
          subtitle: "$key.subtitle".tr(namedArgs: namedArgs),
          actions: [
            KeyboardListener(
              focusNode: errorFocusNode,
              autofocus: true,
              onKeyEvent: (value) {
                if (value is KeyDownEvent) {
                  if (value.physicalKey == PhysicalKeyboardKey.enter ||
                      value.physicalKey == PhysicalKeyboardKey.keyO) {
                    Navigator.pop(context);
                  }
                }
              },
              child: AlertDialogButton(
                  onPressed: () => Navigator.pop(context),
                  text: "$key.okay".tr()),
            )
          ]),
    );
  }
}
