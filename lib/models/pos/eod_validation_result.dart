/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/5/21, 4:03 PM
 */
import 'package:checkout/extension/extensions.dart';

class EoDValidationResult {
  bool? success;
  List<Users>? users;
  String? message;

  EoDValidationResult({this.success, this.users, this.message});

  EoDValidationResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    if (json['users'] != null) {
      users = [];
      json['users'].forEach((v) {
        users?.add(new Users.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.users != null) {
      data['users'] = this.users?.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class Users {
  int? userheDSHIFTNO;
  String? userheDTITLE;
  String? userheDSIGNONDATE;
  String? userheDSTATIONID;

  Users(
      {this.userheDSHIFTNO,
      this.userheDTITLE,
      this.userheDSIGNONDATE,
      this.userheDSTATIONID});

  Users.fromJson(Map<String, dynamic> json) {
    userheDSHIFTNO =
        json['userheD_SHIFTNO']?.toString().parseDouble().toInt() ?? 0;
    userheDTITLE = json['userheD_TITLE'];
    userheDSIGNONDATE = json['userheD_SIGNONDATE'];
    userheDSTATIONID = json['userheD_STATIONID'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userheD_SHIFTNO'] = this.userheDSHIFTNO;
    data['userheD_TITLE'] = this.userheDTITLE;
    data['userheD_SIGNONDATE'] = this.userheDSIGNONDATE;
    data['userheD_STATIONID'] = this.userheDSTATIONID;
    return data;
  }
}
