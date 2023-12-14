/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 9/29/22, 2:15 PM
 */

class ServiceStatusResult {
  bool? success;
  bool? serverSql;
  bool? defaultSql;
  List<String>? errors;

  ServiceStatusResult(
      {this.success, this.serverSql, this.defaultSql, this.errors});

  ServiceStatusResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    serverSql = json['serverSql'];
    defaultSql = json['defaultSql'];
    if (json['errors'] != null) {
      errors = <String>[];
      json['errors'].forEach((v) {
        errors!.add(v.toString());
      });
    }
  }
}
