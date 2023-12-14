/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/12/21, 1:54 PM
 */
import 'dart:math';

import 'package:checkout/components/components.dart';
import 'package:checkout/components/widgets/custom_otp_input.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:easy_localization/easy_localization.dart';

import 'pos_logger_controller.dart';
import 'package:supercharged/supercharged.dart';

/// This class will generate the otp code and send it to the server via secured method
class OTPController {
  // his method will return the random otp number
  String? _otp;
  bool validOtp = false;
  String _enteredText = "";

  String generateOTP() {
    int min = 100000; //min and max values act as your 6 digit range
    int max = 999999;
    var randomizer = new Random();
    _otp = (min + randomizer.nextInt(max - min)).toString();
    if (!kReleaseMode) {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.success, "OTP: $_otp"));
    }

    return _otp!;
  }

  Future verifyOTP(BuildContext context,
      {String? cusCode, String? mobile}) async {
    await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) {
                return POSFlareAlert(
                  title: "customer_profile.number_not_verify".tr(),
                  subtitle: "",
                  content: CustomOTPInput(),
                  // content: OTPTextField(
                  //   keyboardType: TextInputType.number,
                  //   length: 6,
                  //   width: MediaQuery.of(context).size.width,
                  //   fieldWidth: 60,
                  //   style: TextStyle(color: CurrentTheme.primaryLightColor),
                  //   textFieldAlignment: MainAxisAlignment.spaceAround,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       _enteredText = value;
                  //     });
                  //   },
                  //   fieldStyle: FieldStyle.underline,
                  //   onCompleted: (pin) {
                  //     _validateOTP(pin, context);
                  //     setState(() {});
                  //     if (validOtp) Navigator.pop(context);
                  //   },
                  // ),
                  actions: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                POSConfig().primaryDarkGrayColor.toColor()),
                        onPressed: () {
                          _enteredText = POSConfig.validateOTP;
                          _validateOTP(_enteredText, context);
                          if (validOtp) Navigator.pop(context, _enteredText);
                          POSConfig.validateOTP = '';
                        },
                        child: Text("customer_profile.verify".tr())),
                    ElevatedButton(
                        onPressed: () async {
                          EasyLoading.show(status: 'please_wait'.tr());
                          SpecialPermissionHandler handler =
                              SpecialPermissionHandler(context: context);
                          bool permissionStatus = handler.hasPermission(
                              permissionCode:
                                  PermissionCode.skipOtpForRegistration,
                              accessType: 'A',
                              refCode: '$cusCode@$mobile');
                          if (!permissionStatus) {
                            final permission = await handler.askForPermission(
                                permissionCode:
                                    PermissionCode.skipOtpForRegistration,
                                accessType: "A",
                                refCode: '$cusCode@$mobile');
                            if (permission.success) {
                              validOtp = true;
                              Navigator.pop(context, _enteredText);
                            }
                          } else {
                            validOtp = true;
                            Navigator.pop(context, _enteredText);
                          }
                          EasyLoading.dismiss();
                        },
                        child: Text("customer_profile.skip".tr())),
                  ],
                  flarePath: "assets/flare/otp.flr",
                  flareAnimation: "otp",
                );
              },
            ));
  }

  Future enter3rdPartyOTP(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) {
                return POSFlareAlert(
                  title: "customer_profile.number_not_verify".tr(),
                  subtitle: "",
                  content: OTPTextField(
                    length: 6,
                    width: MediaQuery.of(context).size.width,
                    fieldWidth: 80,
                    style: TextStyle(color: CurrentTheme.primaryLightColor),
                    textFieldAlignment: MainAxisAlignment.spaceAround,
                    onChanged: (value) {
                      setState(() {
                        _enteredText = value;
                      });
                    },
                    fieldStyle: FieldStyle.underline,
                    onCompleted: (pin) {
                      Navigator.pop(context, pin);
                    },
                  ),
                  actions: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                POSConfig().primaryDarkGrayColor.toColor()),
                        onPressed: () {
                          Navigator.pop(context, _enteredText);
                        },
                        child: Text("customer_profile.verify".tr()))
                  ],
                  flarePath: "assets/flare/otp.flr",
                  flareAnimation: "otp",
                );
              },
            ));
  }

  void _validateOTP(String text, BuildContext context) {
    validOtp = text == _otp;
    if (!validOtp)
      showDialog(
        context: context,
        builder: (context) {
          return POSErrorAlert(
              title: "customer_profile.verify_error".tr(),
              subtitle: "",
              actions: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            POSConfig().primaryDarkGrayColor.toColor()),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("customer_profile.very_error_okay".tr()))
              ]);
        },
      );
  }
}
