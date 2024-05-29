/// Author: [TM.Sakir] on 2024-01-30

import 'dart:async';
import 'dart:convert';

import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serial_port_win32/serial_port_win32.dart';

class UsbSerial {
  static SerialPort? port;
  static var ports = <String>[];
  static Timer? timer;

  void initSerialPort() async {
    try {
      final List<PortInfo> portInfoLists =
          SerialPort.getPortsWithFullMessages();
      ports = SerialPort.getAvailablePorts();

      print(portInfoLists);
      print(ports);
      LogWriter().saveLogsToFile(
          'ERROR_LOG_', ['${portInfoLists.toString()}', ports.toString()]);
      if (ports.isNotEmpty) {
        port = SerialPort(
            /* ports.firstOrElse(() => 'COM3'), */ POSConfig().pollDisplayPort,
            BaudRate: POSConfig().pollDisplayPortBaudRate,
            openNow: true,
            ReadIntervalTimeout: 0,
            ReadTotalTimeoutConstant: 0,
            ByteSize: 8);
        // port.open();
        // print('Port opened:${port.isOpened}');
        // // _send();
        // print(port.writeBytesFromString('^Welcome to Cart^'));
      }
    } catch (e) {
      print(e.toString());
      await LogWriter().saveLogsToFile(
          'ERROR_LOG_', ['Serial port initialization error: ' + e.toString()]);
    }
  }

  void sendToSerialDisplay(String payload) {
    try {
      print('sending payload to display : ' +
          port!
              .writeBytesFromString(payload, includeZeroTerminator: false)
              .toString());
    } catch (e) {
      print(e.toString());
      LogWriter().saveLogsToFile(
          'ERROR_LOG_', ['usb serial port issue : ' + e.toString()]);

      try {
        port = SerialPort(
            /* ports.firstOrElse(() => 'COM3'), */ POSConfig().pollDisplayPort,
            BaudRate: POSConfig().pollDisplayPortBaudRate,
            openNow: true,
            ReadIntervalTimeout: 0,
            ReadTotalTimeoutConstant: 0,
            ByteSize: 8);
        print('sending payload to display : ' +
            port!
                .writeBytesFromString(payload, includeZeroTerminator: false)
                .toString());
      } catch (e) {}
    }
  }

  Future<void> customTimeMessages() async {
    var jsonData;
    try {
      String data = await rootBundle.loadString('assets/appData.json');
      jsonData = jsonDecode(data);
    } catch (e) {
      jsonData = null;
      LogWriter().saveLogsToFile('ERROR_LOG_', [
        'usb serial issue (appData.json read/conversion) : ' + e.toString()
      ]);
    }
    var currentTime = TimeOfDay.now();
    // var formattedTime = DateFormat.Hm().format(DateTime.now());
    if (currentTime.hour >= 5 && currentTime.hour < 12) {
      sendToSerialDisplay(jsonData?['poll_display_message']?['morning'] ??
          "*** GOOD MORNING ***                    ");
    } else if (currentTime.hour >= 12 && currentTime.hour < 17) {
      sendToSerialDisplay(jsonData?['poll_display_message']?['day'] ??
          "  *** GOOD DAY ***                      ");
    } else {
      sendToSerialDisplay(jsonData?['poll_display_message']?['evening'] ??
          "*** GOOD EVENING ***                    ");
    }
  }

  void sendContinuousDataToSerialDisplay(List<String> payload) {
    try {
      timer = Timer.periodic(Duration(milliseconds: 600), (timer) {
        for (String message in payload) {
          print('sending payload to display : ' +
              port!
                  .writeBytesFromString(message, includeZeroTerminator: false)
                  .toString());
        }
      });
    } catch (e) {
      print(e.toString());
      LogWriter().saveLogsToFile('ERROR_LOG_', [e.toString()]);
    }
  }

  void stopUsbSerialTimer() {
    timer?.cancel();
  }

  String addSpacesFront(String inputString, int desiredLength) {
    if (inputString.length == desiredLength) {
      return inputString;
    } else if (inputString.length < desiredLength) {
      int spacesToAdd = desiredLength - inputString.length;
      String spaces = ' ' * spacesToAdd;
      return '$spaces$inputString';
    } else {
      // Handle the case where the inputString is longer than the desiredLength, if needed.
      // You may want to truncate the string or handle it in a way that fits your use case.
      return inputString;
    }
  }

  String addSpacesBack(String inputString, int desiredLength) {
    if (inputString.length == desiredLength) {
      return inputString;
    } else if (inputString.length < desiredLength) {
      int spacesToAdd = desiredLength - inputString.length;
      String spaces = ' ' * spacesToAdd;
      return '$inputString$spaces';
    } else {
      int truncatedLength = desiredLength - 3;
      String truncatedString = inputString.substring(0, truncatedLength);
      return '$truncatedString...';
    }
  }
}

final usbSerial = UsbSerial();

/// CMD commands
/// viewing com port details
/// mode com1
/// setting com port settings using cmd (using device manager to change com port settings is not effective)
/// mode com1:9600,n,8,1
