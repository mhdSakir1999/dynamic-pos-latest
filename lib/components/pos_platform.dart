/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/3/21, 11:12 AM
 */

import 'dart:io';

import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class POSPlatform {
  bool isDesktop() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  String getPlatformName() {
    if (kIsWeb)
      return "Web";
    else {
      if (Platform.isLinux) return "Linux";
      if (Platform.isWindows) return "Windows";
      if (Platform.isMacOS) return "OSX";
      if (Platform.isAndroid) return "Android";
      if (Platform.isIOS) return "IOS";
      if (Platform.isFuchsia) return "Fuchsia";
      return 'N/A';
    }
  }

  Future writePlatformInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    await POSLoggerController.writeToFile(POSLoggerLevel.info,
        "------------------------------------------------------- Begin of Platform Info ----------------------------------------------------------");
    if (kIsWeb) {
      WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
      String browserName =
          webBrowserInfo.browserName.toString().split(".").last;
      //print("[${webBrowserInfo.platform}] [$browserName] [${webBrowserInfo.appVersion}]");
      POSLoggerController.writeToFile(POSLoggerLevel.info,
          "[${webBrowserInfo.platform}] [$browserName] [${webBrowserInfo.appVersion}]");
    } else {
      //print("[${Platform.operatingSystemVersion}] [Locale: ${Platform.localeName}] [Cores: ${Platform.numberOfProcessors}]");
      await POSLoggerController.writeToFile(POSLoggerLevel.info,
          "[${Platform.operatingSystemVersion}] [Locale: ${Platform.localeName}] [Cores: ${Platform.numberOfProcessors}]");
    }
    await POSLoggerController.writeToFile(POSLoggerLevel.info,
        "------------------------------------------------------- End of Platform Info ----------------------------------------------------------");
  }
}
