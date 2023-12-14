/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/5/21, 1:55 PM
 */
import 'package:checkout/extension/extensions.dart';

class LoggedUserResult {
  String? shiftNo;
  String? date;
  List<UserPermissions>? userRights = [];

  LoggedUserResult({this.shiftNo, this.date, this.userRights});

  LoggedUserResult.fromJson(Map<String, dynamic> json) {
    shiftNo = json['shift_no'].toString();
    date = json['date'];
    if (json['user_rights'] != null && json['user_rights'] is List) {
      userRights = [];
      json['user_rights']?.forEach((v) {
        userRights?.add(new UserPermissions.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['shift_no'] = this.shiftNo;
    data['date'] = this.date;
    if (this.userRights != null) {
      data['user_rights'] = this.userRights?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UserPermissions {
  String? menuTag;
  String? mENUITEMMENUNAME;
  String? mENUITEMMENURIGHT;
  bool? menuOptional;

  UserPermissions(
      {this.menuTag,
      this.mENUITEMMENUNAME,
      this.mENUITEMMENURIGHT,
      this.menuOptional});

  UserPermissions.fromJson(Map<String, dynamic> json) {
    String? temp = json['userdeT_MENUTAG'];
    if (temp == null) {
      temp = json['menuiteM_MENUTAG'];
    }
    menuTag = temp;
    mENUITEMMENUNAME = json['menuiteM_MENUNAME'];
    mENUITEMMENURIGHT = json['menuiteM_MENURIGHT'];
    menuOptional =
        json['menuiteM_MENUOPTIONAL']?.toString().parseBool() ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['USERDET_MENUTAG'] = this.menuTag;
    data['MENUITEM_MENUNAME'] = this.mENUITEMMENUNAME;
    return data;
  }
}
