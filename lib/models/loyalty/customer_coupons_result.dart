/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Dinuka Kulathunga
 * Created At: 17/08/22, 12:23 PM
 */

class CustomerCouponsResult {
  bool? success;
  List<Coupons>? couponsList;

  CustomerCouponsResult({this.success, this.couponsList});

  CustomerCouponsResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['coupons'] != null) {
      couponsList = [];
      json['coupons'].forEach((v) {
        couponsList?.add(new Coupons.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.couponsList != null) {
      data['coupons'] = this.couponsList?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Coupons {
  String? vCVOUCHERNO;
  String? vCCUSCODE;
  String? vCVOUCHERVALUE;
  DateTime? vCVALIDUNTIL;
  bool? vCSTATUS;
  DateTime? cRDATE;
  String? cRBY;
  DateTime? mDDATE;
  String? mDBY;
  DateTime? dTSDATE;

  Coupons(
      {this.vCVOUCHERNO,
      this.vCCUSCODE,
      this.vCVOUCHERVALUE,
      this.vCVALIDUNTIL,
      this.vCSTATUS,
      this.cRDATE,
      this.cRBY,
      this.mDDATE,
      this.mDBY,
      this.dTSDATE});

  Coupons.fromJson(Map<String, dynamic> json) {
    vCVOUCHERNO = json['vC_VOUCHERNO'];
    vCCUSCODE = json['vC_CUSCODE'];
    vCVOUCHERVALUE = json['vC_VOUCHERVALUE'].toStringAsFixed(2);
    vCVALIDUNTIL = DateTime.tryParse(json['vC_VALIDUNTIL']);
    vCSTATUS = json['vC_STATUS'];
    cRDATE = json['cR_DATE'];
    cRBY = json['cR_BY'];
    mDDATE = json['mD_DATE'];
    mDBY = json['mD_BY'];
    dTSDATE = json['dTS_DATE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['VC_VOUCHERNO'] = this.vCVOUCHERNO;
    data['VC_CUSCODE'] = this.vCCUSCODE;
    data['VC_VOUCHERVALUE'] = this.vCVOUCHERVALUE;
    data['VC_VALIDUNTIL'] = this.vCVALIDUNTIL;
    data['VC_STATUS'] = this.vCSTATUS;
    data['CR_DATE'] = this.cRDATE;
    data['CR_BY'] = this.cRBY;
    data['MD_DATE'] = this.mDDATE;
    data['MD_BY'] = this.mDBY;
    data['DTS_DATE'] = this.dTSDATE;
    return data;
  }
}
