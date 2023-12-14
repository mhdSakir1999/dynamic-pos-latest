/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/21/21, 4:51 PM
 */
class POSLogger {
  POSLoggerLevel level;
  String text;
  final loggerTime = DateTime.now();
  POSLogger(this.level, this.text);
}

enum POSLoggerLevel { info, success, error,apiError,apiInfo }
