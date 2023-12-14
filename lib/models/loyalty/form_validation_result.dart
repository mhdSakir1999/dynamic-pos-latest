/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 9/14/22, 4:32 PM
 */

class FormValidationResult {
  bool? success;
  List<FormValidations>? validation;

  FormValidationResult({this.success, this.validation});

  FormValidationResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['validation'] != null) {
      validation = <FormValidations>[];
      json['validation'].forEach((v) {
        validation!.add(new FormValidations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.validation != null) {
      data['validation'] = this.validation!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FormValidations {
  String? fVMENUCODE;
  String? fVFIELDNAME;
  String? fVREGEX;

  FormValidations({this.fVMENUCODE, this.fVFIELDNAME, this.fVREGEX});

  FormValidations.fromJson(Map<String, dynamic> json) {
    fVMENUCODE = json['fV_MENU_CODE'];
    fVFIELDNAME = json['fV_FIELDNAME'];
    fVREGEX = json['fV_REGEX'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['fV_MENU_CODE'] = this.fVMENUCODE;
    data['fV_FIELDNAME'] = this.fVFIELDNAME;
    data['fV_REGEX'] = this.fVREGEX;
    return data;
  }
}
