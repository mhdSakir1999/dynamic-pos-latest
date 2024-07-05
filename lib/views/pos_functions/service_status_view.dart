/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 9/29/22, 1:53 PM
 */

import 'dart:async';

import 'package:checkout/models/pos_config.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/current_theme.dart';
import '../../models/service_status_result.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ServiceStatusView extends StatefulWidget {
  const ServiceStatusView({Key? key}) : super(key: key);

  @override
  State<ServiceStatusView> createState() => _ServiceStatusViewState();
}

class _ServiceStatusViewState extends State<ServiceStatusView> {
  final bool hasError = false;
  final List<_ServerList> _serverList = [];
  late Timer _timer;
  final int _timeFrame = 20;
  DateTime lastUpdate = DateTime.now();
  String checkoutVersion = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    _getPackageInfo();
    addServer(
        "Central POS Server", POSConfig().setup?.centralPOSServer ?? '', false);
    addServer(
        "Central Loyalty Server", POSConfig().loyaltyServerCentral, false);
    addServer("Outlet POS Server", POSConfig().server, false);
    addServer("Outlet Loyalty Server", POSConfig().loyaltyServerOutlet, false);
    addServer("Local POS Server", POSConfig().local, true);
    _handleServerList();
    _timer = Timer.periodic(Duration(seconds: _timeFrame), (timer) async {
      _handleServerList();
    });
  }

  // getting version info of the app
  _getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      checkoutVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void addServer(String name, String url, bool hasDefaultDb) {
    if (url.isNotEmpty) {
      //handle urls
      //add /api
      url += '/api';
      //remove //
      url = url.replaceAll('//', '/');
      //remove duplicate /api
      url = url.replaceAll('/api/api', '/api');
      //add http
      url = url.replaceAll(':/', '://');
      _serverList.add(_ServerList(name, url, hasDefaultDb));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hasError ? "Service Outage Detected" : "Service Status",
          style: CurrentTheme.headline6,
        ),
        if (hasError)
          SizedBox(
              height: 150.w,
              width: 150.w,
              child: const FlareActor(
                'assets/flare/waring.flr',
                animation: 'animate',
                fit: BoxFit.contain,
                isPaused: false,
              )),
        Column(
          children: buildColumn(),
        ),
        Text(
          'Last Updated on: ${DateFormat().format(lastUpdate)}',
          style: CurrentTheme.bodyText1,
        ),
        Text(
          'Checkout Version: $checkoutVersion',
          style: CurrentTheme.bodyText1,
        ),
      ],
    );
  }

  List<Widget> buildColumn() {
    return _serverList.map((e) => _buildServerItem(e)).toList();
  }

  Widget _buildServerItem(_ServerList server) {
    return Row(
      children: [
        _buildIcon(server.serverStatus),
        SizedBox(width: 10.w),
        Tooltip(
            message: server.url,
            child: SizedBox(
              width: 200.w,
              child: Text(server.name,
                  style: CurrentTheme.bodyText2!.copyWith(fontSize: 18.sp)),
            )),
        SizedBox(width: 10.w),
        SizedBox(
          width: 125.w,
          child: Text(
            ' ${server.ping} ms',
            style: CurrentTheme.bodyText1!
                .copyWith(color: _getLatencyColor(server.ping)),
          ),
        ),
        SizedBox(
          width: 200.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'serverSql',
                style: CurrentTheme.bodyText1!.copyWith(
                    color: server.serverDatabaseWorking == true
                        ? Colors.greenAccent
                        : Colors.red),
              ),
              Text(
                'defaultSql',
                style: CurrentTheme.bodyText1!.copyWith(
                    color: server.defaultDatabaseWorking == true
                        ? Colors.greenAccent
                        : Colors.red),
              ),
            ],
          ),
        )
      ],
    );
  }
  // Widget _buildServerItem(_ServerList server) {
  //   return Table(
  //     border: TableBorder.all(), // Add grid lines around the table
  //     children: [
  //       TableRow(
  //         children: [
  //           _buildIcon(server.serverStatus),
  //           // SizedBox(width: 10.w),
  //           Tooltip(
  //             message: server.url,
  //             child: SizedBox(
  //               width: 200.w,
  //               child: Text(
  //                 server.name,
  //                 style: CurrentTheme.bodyText2!.copyWith(fontSize: 18.sp),
  //               ),
  //             ),
  //           ),
  //           // SizedBox(width: 10.w),
  //           SizedBox(
  //             width: 125.w,
  //             child: Text(
  //               ' ${server.ping} ms',
  //               style: CurrentTheme.bodyText1!.copyWith(
  //                 color: _getLatencyColor(server.ping),
  //               ),
  //             ),
  //           ),
  //           SizedBox(
  //             width: 200.w,
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               children: [
  //                 Text(
  //                   'serverSql',
  //                   style: CurrentTheme.bodyText1!.copyWith(
  //                     color: server.serverDatabaseWorking == true
  //                         ? Colors.greenAccent
  //                         : Colors.red,
  //                   ),
  //                 ),
  //                 Text(
  //                   'defaultSql',
  //                   style: CurrentTheme.bodyText1!.copyWith(
  //                     color: server.defaultDatabaseWorking == true
  //                         ? Colors.greenAccent
  //                         : Colors.red,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Color _getLatencyColor(int latency) {
    if (latency == -1) {
      return Color(0xFFb71c1c);
    }
    if (latency < 10) {
      return Color(0xFF1b5e20);
    } else if (latency < 20) {
      return Color(0xFF2e7d32);
    } else if (latency < 30) {
      return Color(0xFF388e3c);
    } else if (latency < 40) {
      return Color(0xFF43a047);
    } else if (latency < 50) {
      return Color(0xFF4caf50);
    } else if (latency < 60) {
      return Color(0xFF66bb6a);
    } else if (latency < 70) {
      return Color(0xFFffeb3b);
    } else if (latency < 80) {
      return Color(0xFFfdd835);
    } else if (latency < 90) {
      return Color(0xFFfbc02d);
    } else if (latency < 100) {
      return Color(0xFFf9a825);
    } else if (latency < 110) {
      return Color(0xFFffb300);
    } else if (latency < 120) {
      return Color(0xFFef5350);
    } else if (latency < 130) {
      return Color(0xFFe53935);
    } else if (latency < 140) {
      return Color(0xFFd32f2f);
    } else if (latency < 150) {
      return Color(0xFFc62828);
    } else {
      return Color(0xFFb71c1c);
    }
  }

  Widget _buildIcon(_ServerStatus status) {
    switch (status) {
      case _ServerStatus.error:
        return const Icon(
          Icons.error,
          color: Colors.red,
        );
      case _ServerStatus.warning:
        return const Icon(Icons.warning, color: Colors.amber);
      case _ServerStatus.success:
        return const Icon(
          Icons.check_circle,
          color: Colors.greenAccent,
        );
      case _ServerStatus.na:
        return const Icon(
          Icons.sync,
          color: Colors.black,
        );
    }
  }

  void _handleServerList() {
    if (mounted) {
      lastUpdate = DateTime.now();
      setState(() {});
    }
    for (int i = 0; i < _serverList.length; i++) {
      _checkServer(_serverList[i], i);
    }
  }

  Future<void> _checkServer(_ServerList server, int index) async {
    //get dio response
    _ServerStatus status = server.serverStatus;
    DateTime startTime = DateTime.now();
    try {
      final res = await Dio().get(server.url);
      print(server.name + ":" + server.url);

      ServiceStatusResult serviceStatus =
          ServiceStatusResult.fromJson(res.data);
      //handle status
      if (serviceStatus.defaultSql != true) {
        status = _ServerStatus.error;
      } else if (serviceStatus.defaultSql == null &&
          serviceStatus.success == true) {
        status = _ServerStatus.success;
      } else if (server.hasServerDatabase && serviceStatus.serverSql != true) {
        status = _ServerStatus.warning;
      } else {
        status = _ServerStatus.success;
      }
      DateTime endTime = DateTime.now();
      server.ping =
          endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch;

      /// new change by [TM.Sakir] -- passing status of sql connections to view it on the dialog box
      server.defaultDatabaseWorking = serviceStatus.defaultSql ?? false;
      server.serverDatabaseWorking = serviceStatus.serverSql ?? false;
    } on Exception catch (e) {
      server.ping = -1;
      status = _ServerStatus.error;
      server.errors.add(e.toString());
    }

    server.serverStatus = status;
    if (mounted) {
      setState(() {
        _serverList[index] = server;
      });
    }
  }
}

class _ServerList {
  final String name;
  final String url;
  final bool hasServerDatabase;
  bool canPing = false;
  bool defaultDatabaseWorking = false;
  bool serverDatabaseWorking = false;
  List<String> errors = [];
  int ping = -1;
  _ServerStatus serverStatus = _ServerStatus.na;

  _ServerList(
    this.name,
    this.url,
    this.hasServerDatabase,
  );
}

enum _ServerStatus { error, warning, success, na }
