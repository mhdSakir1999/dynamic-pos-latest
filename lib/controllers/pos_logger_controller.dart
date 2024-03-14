/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/21/21, 4:50 PM
 */

import 'package:ansicolor/ansicolor.dart';
import 'package:checkout/components/pos_platform.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:flutter/foundation.dart';

/// This class is used to log every event done in the app level
class POSLoggerController {
  static final POSLoggerController _singleton = POSLoggerController._internal();
  factory POSLoggerController() {
    return _singleton;
  }
  POSLoggerController._internal();
  static List<POSLogger> logList = [];
  // add logger to list
  static void addNewLog(POSLogger logger) {
    AnsiPen pen = AnsiPen();

    switch (logger.level) {
      case POSLoggerLevel.info:
      case POSLoggerLevel.apiInfo:
        pen = AnsiPen()..blue(bold: true);
        break;
      case POSLoggerLevel.success:
        pen = AnsiPen()..green(bold: true);
        break;
      case POSLoggerLevel.error:
      case POSLoggerLevel.apiError:
        pen = AnsiPen()..red(bold: true);
        break;
    }

    final text =
        "[${logger.level}] [${logger.loggerTime}] [${POSPlatform().getPlatformName()}] [${kReleaseMode ? "Release" : "Debug"}] ${logger.text}";

    writeToFile(logger.level, text);

    if (!kReleaseMode &&
        (logger.level != POSLoggerLevel.apiInfo &&
            logger.level != POSLoggerLevel.apiError)) print(pen(text));
    logList.add(logger);
  }

  static Future writeToFile(POSLoggerLevel logger, String text) async {
    if (logger == POSLoggerLevel.error)
      await LogWriter().saveLogsToFile('ERROR_Log_', [text]);
    // if(!POSConfig().saas)
    // await ApiClient.call("poslog", ApiMethod.POST,
    //     formData: FormData.fromMap({"type": logger, "message": text}),
    //     writeLog: false,
    //     local: true,
    //     authorize: false,
    //     successCode: 204);
  }
}
