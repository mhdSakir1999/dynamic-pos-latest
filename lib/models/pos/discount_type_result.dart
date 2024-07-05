/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: TM.Sakir && Shalika Ashan
 * Created At: 6/4/21, 6:29 PM
 */
import 'package:checkout/extension/extensions.dart';

class DiscountTypeResult {
  bool? success;
  List<DiscountTypes>? discountTypes;

  DiscountTypeResult({this.success, this.discountTypes});

  DiscountTypeResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    if (json['discount_types'] != null) {
      discountTypes = [];
      json['discount_types']?.forEach((v) {
        discountTypes?.add(new DiscountTypes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.discountTypes != null) {
      data['discount_types'] =
          this.discountTypes?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DiscountTypes {
  String? diSCODE;
  String? diSDISCRIPTION;
  bool? rcDisc;
  bool? rcReqAut;
  bool? rcNetPer;
  bool? rcCancel;
  bool? rcReturn;
  double? rcDiscAmt;
  double? rcDiscPer;

  DiscountTypes({this.diSCODE, this.diSDISCRIPTION});

  DiscountTypes.fromJson(Map<String, dynamic> json) {
    diSCODE = json['diS_CODE'];
    diSDISCRIPTION = json['diS_DISCRIPTION'];
    rcDisc = json['rC_DISC']?.toString().parseBool() ?? false;
    rcReqAut = json['rC_REQAUT']?.toString().parseBool() ?? false;
    rcNetPer = json['rC_NETPER']?.toString().parseBool() ?? false;
    rcCancel = json['rC_CANCEL']?.toString().parseBool() ?? false;
    rcReturn = json['rC_RETURN']?.toString().parseBool() ?? false;
    rcDiscAmt = json['rC_DISCAMT']?.toString().parseDouble() ?? 0;
    rcDiscPer = json['rC_DISCPER']?.toString().parseDouble() ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['diS_CODE'] = this.diSCODE;
    data['diS_DISCRIPTION'] = this.diSDISCRIPTION;
    return data;
  }
}

class ProductDiscountStatus {
  late String proCode;
  late String status;

  ProductDiscountStatus({required this.proCode, required this.status});

  ProductDiscountStatus.fromJson(Map<String, dynamic> json) {
    proCode = json['plU_CODE'] ?? "";
    status = json['disC_STATUS'] ?? "";
  }
}
