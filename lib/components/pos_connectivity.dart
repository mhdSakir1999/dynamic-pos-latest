/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 5/8/21, 12:54 PM
 */
import 'dart:async';
import 'dart:io';

import 'package:checkout/components/api_client.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/enum/pos_connectivity_status.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supercharged/supercharged.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/special_permission_handler.dart';
import '../models/pos/permission_code.dart';

class POSConnectivity {
  final connectivityStream = BehaviorSubject<POSConnectivityStatus>();
  final connectionAvailabilityStream = BehaviorSubject<POSConnectivityStatus>();
  Timer? _timer;
  BuildContext? context;
  bool localConfirmed = false;
  FocusNode _focusNode = FocusNode();
  VoidCallback? onUpdate;

  setContext(BuildContext context) {
    this.context = context;
  }

  setVoidCallback(VoidCallback func) {
    this.onUpdate = func;
  }

  startListen() {
    handleConnection();
    _timer = Timer.periodic(Duration(seconds: 15), (timer) async {
      handleConnection();
    });
  }

  handleConnection({bool manualLocalModeSwitch = false}) async {
    bool serverRes = await pingToServer(time: 15);
    if (serverRes) {
      connectionAvailabilityStream.sink.add(POSConnectivityStatus.Server);
    } else {
      connectionAvailabilityStream.sink.add(POSConnectivityStatus.None);
    }
    if (serverRes && !manualLocalModeSwitch) {
      print('connected to server');
      if (!localConfirmed) {
        POSLogger(POSLoggerLevel.info, "You are connected to server");
        ApiClient.url = POSConfig().server;
        connectivityStream.sink.add(POSConnectivityStatus.Server);
        localConfirmed = false;
        POSConfig().localMode = false;
      }
    } else {
      if (POSConfig().allowLocalMode) {
        print('not connected to server');
        POSLogger(POSLoggerLevel.error, "Something went wrong");
        bool localRes = await _pingToLocalServer();
        if (!serverRes && localRes) {
          connectionAvailabilityStream.sink.add(POSConnectivityStatus.Local);
        } else if (!serverRes && !localRes) {
          connectionAvailabilityStream.sink.add(POSConnectivityStatus.None);
        }
        if (localRes) {
          if (localConfirmed) {
            POSLogger(POSLoggerLevel.info, "You are connected to local");
            connectivityStream.sink.add(POSConnectivityStatus.Local);
            ApiClient.url = POSConfig().local;
            POSConfig().localMode = true;
          } else {
            if (_timer == null) return;
            if (context != null) {
              _timer?.cancel();
              _focusNode.requestFocus();
              manualLocalModeSwitch
                  ? await switchingLocal(context!, manualLocalModeSwitch)
                  : await showDialog(
                      barrierDismissible: false,
                      context: context!,
                      builder: (context) => POSErrorAlert(
                          title: "server_error.title".tr(),
                          subtitle: "server_error.subtitle".tr(),
                          actions: [
                            KeyboardListener(
                              autofocus: true,
                              focusNode: _focusNode,
                              onKeyEvent: (value) async {
                                if (value is KeyDownEvent) {
                                  if (value.physicalKey ==
                                          PhysicalKeyboardKey.enter ||
                                      value.physicalKey ==
                                          PhysicalKeyboardKey.keyO) {
                                    await switchingLocal(
                                        context, manualLocalModeSwitch);
                                  }
                                }
                              },
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: POSConfig()
                                        .primaryDarkGrayColor
                                        .toColor()),
                                onPressed: () async {
                                  await switchingLocal(
                                      context, manualLocalModeSwitch);
                                },
                                child: RichText(
                                    text: TextSpan(
                                        text: "",
                                        style: Theme.of(context)
                                            .dialogTheme
                                            .contentTextStyle,
                                        children: [
                                      TextSpan(
                                        text: "loyalty_server_error.okay"
                                            .tr()
                                            .substring(0, 1),
                                        style: TextStyle(
                                          decoration: TextDecoration
                                              .underline, // Apply underline to the first letter
                                        ),
                                      ),
                                      TextSpan(
                                        text: "loyalty_server_error.okay"
                                            .tr()
                                            .substring(1),
                                      ),
                                    ])),
                                // Text(
                                //   "loyalty_server_error.okay".tr(),
                                //   style: Theme.of(context).dialogTheme.contentTextStyle,
                                // ),
                              ),
                            )
                          ]),
                    );
            }
          }
        } else {
          POSConfig().localMode = false;
          POSLogger(POSLoggerLevel.error, "Something went wrong");
          connectivityStream.sink.add(POSConnectivityStatus.None);
        }
      } else {
        POSConfig().localMode = false;
        POSLogger(POSLoggerLevel.error, "Something went wrong");
        connectivityStream.sink.add(POSConnectivityStatus.None);
      }
    }
  }

  Future<void> switchingLocal(BuildContext context, bool manual) async {
    EasyLoading.show(status: 'Please wait...');
    bool hasPermission = false;
    if (!manual) {
      hasPermission = SpecialPermissionHandler(context: context).hasPermission(
          permissionCode: PermissionCode.disconnectedMode,
          accessType: "A",
          refCode: "");
    }
    EasyLoading.dismiss();

    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: context)
          .askForPermission(
              permissionCode: PermissionCode.disconnectedMode,
              accessType: "A",
              refCode: "",
              localConnection: true);
      hasPermission = res.success;
    }
    if (!hasPermission) {
      if (!manual) Navigator.pop(context);
      Future.delayed(Duration(seconds: 10), () {
        startListen();
      });
    } else {
      if (!manual) Navigator.pop(context);
      localConfirmed = true;
      POSConfig().localMode = true;
      connectivityStream.sink.add(POSConnectivityStatus.Local);
      ApiClient.url = POSConfig().local;
      onUpdate?.call();
      startListen();
    }
  }

  Future<bool> pingToServer({int time = 15}) async {
    final server = POSConfig().server;

    // final beforeReq = DateTime.now();
    bool res = await _checkConnection(server, time: time);
    // final afterReq = DateTime.now();
    // POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
    //     "Check the connectivity to: $server - Latency: ${afterReq.millisecondsSinceEpoch - beforeReq.millisecondsSinceEpoch}ms"));
    return res;
  }

  Future<bool> _pingToLocalServer({int time = 15}) async {
    // if (!POSConfig().localMode) return false;
    final server = POSConfig().local;
    POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
        "Check the connectivity to local server: $server"));
    return await _checkConnection(server, time: time);
  }

  Future<bool> _checkConnection(String ip, {int time = 15}) async {
    Dio dio = Dio();
    try {
      final response =
          await dio.head(ip).timeout(Duration(seconds: time), onTimeout: () {
        throw TimeoutException(
            'The connection has timed out, Please try again!');
      });
      bool status = (response.statusCode ?? 500) < 500;
      EasyLoading.dismiss();
      return status;
    } on SocketException {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.error, "You are not connected to internet"));
      return false;
    } on TimeoutException {
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.error,
          "The connection has timed out, Please try again!"));
      return false;
    } on HandshakeException {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.error, "Handshake error in client"));
      return false;
    } on Exception {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.error, "Undefined connection error"));
      return false;
    }
  }

  Future<bool> pingToLoyaltyServer() async {
    final server = POSConfig().loyaltyServerCentral;
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Check the connectivity to: $server"));
    return await _checkConnection(server);
  }

  dispose() {
    _timer?.cancel();
    connectivityStream.close();
  }
}

final posConnectivity = POSConnectivity();
