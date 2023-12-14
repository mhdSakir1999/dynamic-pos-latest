/// Author: [TM.Sakir]
/// Created At: 2023-11-21, 12:45 PM

import 'package:checkout/extension/extensions.dart';

class SalesRepListResult {
  bool? success;
  List<SalesRepResult>? repList;

  SalesRepListResult({this.success, this.repList});

  SalesRepListResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    if (json['salesreps'] != null) {
      repList = [];
      json['salesreps'].forEach((v) {
        repList?.add(new SalesRepResult.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.repList != null) {
      data['salesreps'] = this.repList?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SalesRepResult {
  String? sACODE;
  String? sATITLE;
  String? sAFNAME;
  String? sALNAME;
  String? sAFULLNAME;
  String? sAGROUP;
  String? sANIC;
  String? sALOC;

  SalesRepResult(
      {this.sACODE,
      this.sAFNAME,
      this.sAFULLNAME,
      this.sAGROUP,
      this.sALNAME,
      this.sALOC,
      this.sANIC,
      this.sATITLE});

  SalesRepResult.fromJson(Map<String, dynamic> json) {
    sACODE = json['sA_CODE'];
    sATITLE = json['sA_TITLE'];
    sAFNAME = json['sA_FNAME'];
    sALNAME = json['sA_LNAME'];
    sAFULLNAME = json['sA_FULLNAME'];
    sAGROUP = json['sA_GROUP'];
    sANIC = json['sA_NIC'];
    sALOC = json['sA_LOC'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = new Map<String, dynamic>();
    json['sA_CODE'] = this.sACODE;
    json['sA_TITLE'] = this.sATITLE;
    json['sA_FNAME'] = this.sAFNAME;
    json['sA_LNAME'] = this.sALNAME;
    json['sA_FULLNAME'] = this.sAFULLNAME;
    json['sA_GROUP'] = this.sAGROUP;
    json['sA_NIC'] = this.sANIC;
    json['sA_LOC'] = this.sALOC;
    return json;
  }
}
