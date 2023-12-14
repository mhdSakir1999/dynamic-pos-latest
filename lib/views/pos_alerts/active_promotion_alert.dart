/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/22/21, 9:22 PM
 */

import 'package:checkout/views/pos_alerts/pos_alert_template.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ActivePromotionAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return POSAlertTemplate(
        notifications: [
          "Buy 1 and get 1 free offer for X Brand Shirts – Ends @ 30/04/2021",
          "HSBC Card 20% off on total bill – Ends @ 30/04/2021",
          "Commercial Card 30% off on total bill – Ends @ 30/04/2021",
        ],
        icon: Icons.notifications_active_outlined,
        leftButtonPressed: () {},
        leftButtonText: "notifications.get_my_offers".tr(),
        rightButtonPressed: () {
          Navigator.pop(context);
        },
        rightButtonText: "notifications.done_button".tr(),
        title: "notifications.active_promotion_title".tr(),
        expNotification: false);
  }
}
