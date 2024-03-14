/*
 * Copyright (c) 2023 myPOS Software Solutions.  All rights reserved.
 * Author: TM.Sakir
 * Created At: 9/25/2023, 1:49 PM
 * Trying to record the logs of every api call
 */

import 'package:logger/logger.dart';
import 'dart:io';

class LogWriter {
  static var logger = Logger(level: Level.all);

  Future<void> saveLogsToFile(String fileName, List<String> logs) async {
    try {
      Directory currentDirectory = Directory.current;
      var dirName = fileName +
          DateTime.now().toLocal().toString().split(' ')[0].replaceAll('-',
              ''); // 2023-09-25 15:02:27.772424 --> 2023-09-25 --> 20230925
      final file = File('${currentDirectory.path}\\logs\\$dirName');

      // Check if the file already exists
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }

      // Open the file in append mode
      IOSink sink = file.openWrite(mode: FileMode.append);

      // // Write logs to the file
      // sink.writeln('\n' + DateTime.now().toLocal().toString());
      for (String log in logs) {
        sink.writeln(DateTime.now().toLocal().toString() + ' : ' + log);
      }

      // Close the file
      await sink.close();
      logger.i('Logs saved to ${file.path}');
    } catch (e) {
      logger.e('Error saving logs: $e');
    }
  }
}
