/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/12/21, 7:11 PM
 */
import 'package:checkout/extension/extensions.dart';

class GroupResults {
  bool? success;
  List<Groups>? groups;

  GroupResults({this.success, this.groups});

  GroupResults.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    if (json['groups'] != null) {
      groups = [];
      json['groups'].forEach((v) {
        groups?.add(new Groups.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.groups != null) {
      data['groups'] = this.groups?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Groups {
  String? gPCODE;
  String? gPDESC;
  String? gPTABLE;

  Groups({this.gPCODE, this.gPDESC, this.gPTABLE});

  Groups.fromJson(Map<String, dynamic> json) {
    gPCODE = json['gP_CODE'];
    gPDESC = json['gP_DESC'];
    gPTABLE = json['gP_TABLE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['gP_CODE'] = this.gPCODE;
    data['gP_DESC'] = this.gPDESC;
    data['gP_TABLE'] = this.gPTABLE;
    return data;
  }
}
