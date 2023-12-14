/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/12/21, 4:19 PM
 */

class AreaResult {
  bool? success;
  List<Area>? areaList;

  AreaResult({this.success, this.areaList});

  AreaResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['area_list'] != null) {
      areaList = [];
      json['area_list'].forEach((v) {
        areaList?.add(new Area.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.areaList != null) {
      data['area_list'] = this.areaList?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Area {
  String? aRCODE;
  String? aRDESC;

  Area({this.aRCODE, this.aRDESC});

  Area.fromJson(Map<String, dynamic> json) {
    aRCODE = json['aR_CODE'];
    aRDESC = json['aR_DESC'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['AR_CODE'] = this.aRCODE;
    data['AR_DESC'] = this.aRDESC;
    return data;
  }
}
