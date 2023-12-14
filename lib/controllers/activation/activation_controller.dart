/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/25/21, 9:42 AM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/config/shared_preference_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/pos/client_license_results.dart';

class ActivationController {
  /// get client license from server
  Future<ClientLicense?> getClientLicense() async {
    final res = await ApiClient.call(
        "setup/license?secret=${POSConfig().setup?.clientLicense}",
        ApiMethod.GET,
        authorize: false);
    if (res?.data == null) return null;
    final ClientLicense? license =
        ClientLicenseResult.fromJson(res?.data).license;
    POSConfig().clientLicense = license;
    return license;
  }

  /// return true if the all validations are pass
  Future<bool> process(BuildContext context) async {
    print('checking whether client code is null');
    if (POSConfig().clientLicense != null) {
      print('client code is not null');
      ClientLicense license = POSConfig().clientLicense!;
      if (license.lCSTATUS != true) {
        print('license status is false');
        unauthorizedAccess(context, "1006");
        return false;
      }
      //set the background image
      String image = license.lCPOSIMAGE ?? '';
      SharedPreferenceController sharedPreferenceController =
          SharedPreferenceController();
      if (image.isNotEmpty) {
        sharedPreferenceController.setBackgroundImage(image);
        POSConfig().backgroundImage = image;
      }
      if (POSConfig().saas == false) {
        sharedPreferenceController.setBackgroundImage("");
        POSConfig().backgroundImage = "";
      }
      String strDbRegDate = license.lCREGISTERDATE ?? '';
      print('reg. Date $strDbRegDate');
      String strDbExpDate = license.lCEXPIRYDATE ?? '';
      print('exp. date $strDbExpDate');
      int billingCycle = license.lCBILLINGCYCLE ?? 0;

      //If the installation is not SAAS, skip validating SAAS conditions and proceed.
      if (POSConfig().saas == false) return true;

      //check the db date times
      if (strDbRegDate.isEmpty) {
        print('db reg. date is empty');
        unauthorizedAccess(context, "1003");
        return false;
      }
      if (strDbExpDate.isEmpty) {
        print('db exp. date is empty');
        unauthorizedAccess(context, "1004");
        return false;
      }

      DateTime dbRegDate = strDbRegDate.parseDateTime();
      DateTime dbExpDate = strDbExpDate.parseDateTime();
      DateTime crDate = (license.cRDATE ?? '').parseDateTime();
      DateTime startDate = DateTime(2021, 1, 1);
      print('cast reg.date $dbRegDate');
      print('cast exp.date $dbExpDate');
      print('cast cr.date $crDate');
      print('cast start.date $startDate');

      if (billingCycle == 0) {
        print('billing cycle is 0');
        unauthorizedAccess(context, "1005");
        return false;
      }
      String secret = POSConfig().setup?.clientLicense ?? '';
      print('secret $secret');
      String strJwtKey = secret +
          (crDate.millisecondsSinceEpoch - startDate.millisecondsSinceEpoch)
              .toString();
      print('jwtkey $strJwtKey');
      //check the db values with jwt
      String strLicense = license.lCLICENSEKEY ?? '';
      print('license $strLicense');
      // debugPrint('-----------------------------------');
      // debugPrint(strLicense);
      // debugPrint('-----------------------------------');
      if (strLicense.isEmpty) {
        print('license is empty');
        unauthorizedAccess(context, "1002");
        return false;
      }
      try {
        print('start verify jwt');

        final jwtVerify = JWT.verify(strLicense.trim(), SecretKey(strJwtKey));
        print('verify jwt $jwtVerify');

        final payload = jwtVerify.payload;
        print('payload $payload');

        if (payload['registered_date']
                ?.toString()
                .parseDateTime()
                .isAtSameMomentAs(dbRegDate) !=
            true) {
          print(
              'payload reg.date not match ${payload['registered_date']?.toString()}');
          unauthorizedAccess(context, "1003");
          return false;
        }
        if (payload['expiry_date']
                ?.toString()
                .parseDateTime()
                .isAtSameMomentAs(dbExpDate) !=
            true) {
          print(
              'payload exp.date not match ${payload['expiry_date']?.toString()}');
          unauthorizedAccess(context, "1004");
          return false;
        }
        if (billingCycle.toString() == payload['billing_cycle']) {
          print(
              'payload billing cycle not match ${payload['billing_cycle']?.toString()}');
          unauthorizedAccess(context, "1005");
          return false;
        }
      } on Exception catch (e) {
        print('error occured');
        print(e);
        unauthorizedAccess(context, "1002");
        return false;
      }
      //check the license expire date
      int remainingDays = dbExpDate.difference(DateTime.now()).inDays;
      if (remainingDays < 0) {
        POSConfig().licenseMessage = 'activation.expired'.tr() +
            ". " +
            'activation.expired_content'.tr();
        POSConfig().licenseMessageColor = Colors.red;
        POSConfig().expired = true;
        await expireAlert(context);
      } else if (remainingDays < 14) {
        POSConfig().licenseMessage = 'activation.expire_soon'.tr();
        POSConfig().licenseMessageColor = Colors.amber;
        await subscriptionReminder(context, remainingDays);
      }
      return true;
    } else {
      unauthorizedAccess(context, "1001");
      return false;
    }
  }

  void unauthorizedAccess(BuildContext context, String errorCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return POSErrorAlert(
            title: 'activation.unauthorized'.tr(),
            subtitle: 'activation.unknown'.tr(namedArgs: {"code": errorCode}),
            actions: [
              AlertDialogButton(
                onPressed: () => Navigator.pop(context),
                text: 'activation.learn_more'.tr(),
              )
            ]);
      },
    );
  }

  Future expireAlert(
    BuildContext context,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return POSErrorAlert(
            title: 'activation.expired'.tr(),
            subtitle: 'activation.expired_content'.tr(),
            actions: [
              AlertDialogButton(
                onPressed: () => Navigator.pop(context),
                text: 'activation.learn_more'.tr(),
              )
            ]);
      },
    );
  }

  Future<void> subscriptionReminder(BuildContext context, int days) async {
    String myDays = days.toString();
    if (days < 10) {
      myDays = "0$days";
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final EdgeInsets padding = EdgeInsets.all(25.r);
        final TextStyle style = CurrentTheme.headline3!
            .copyWith(color: CurrentTheme.primaryDarkColor);
        return AlertDialog(
          title: Text('activation.subscription_reminder'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    child: Padding(
                        padding: padding,
                        child: Text(
                          myDays[0],
                          style: style,
                        )),
                  ),
                  Card(
                    child: Padding(
                      padding: padding,
                      child: Text(
                        myDays[1],
                        style: style,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'activation.remaining'.tr(),
                style: CurrentTheme.headline6,
              )
            ],
          ),
          actions: [
            AlertDialogButton(
              onPressed: () => Navigator.pop(context),
              text: 'activation.learn_more'.tr(),
            )
          ],
        );
      },
    );
  }

  Future<void> showModuleBuy(BuildContext context, String module) async {
    if (POSConfig().expired) {
      await expireAlert(context);
      return;
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return POSFlareAlert(
            flarePath: 'assets/flare/buying.flr',
            flareAnimation: 'empty',
            title: module,
            subtitle: 'activation.not_buy'.tr(namedArgs: {"module": module}),
            actions: [
              AlertDialogButton(
                onPressed: () => Navigator.pop(context),
                text: 'activation.learn_more'.tr(),
              )
            ]);
      },
    );
  }
}
