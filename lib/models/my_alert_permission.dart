/*
 * Copyright (c) 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 26/01/2022, 12:26
 */
import 'package:checkout/extension/extensions.dart';
class MyAlertPermission {
  String? deviceToken;
  String? reason;
  String? uuID;
  bool? permission;
  String? menucode;
  String? right;

  MyAlertPermission(
      {this.deviceToken,
        this.reason,
        this.uuID,
        this.permission,
        this.menucode,
        this.right});

  MyAlertPermission.fromJson(Map<String, dynamic> json) {
    deviceToken = json['deviceToken'];
    reason = json['reason'];
    uuID = json['uuID'];
    permission = json['permission']?.toString().parseBool()??false;
    menucode = json['menucode'];
    right = json['right'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['deviceToken'] = this.deviceToken;
    data['reason'] = this.reason;
    data['uuID'] = this.uuID;
    data['permission'] = this.permission;
    data['menucode'] = this.menucode;
    data['right'] = this.right;
    return data;
  }
}

