/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/27/22, 1:05 PM
 */

import 'package:checkout/extension/extensions.dart';

class AnnouncementResult {
  bool? success;
  List<Announcement>? announcement;

  AnnouncementResult({this.success, this.announcement});

  AnnouncementResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool();
    if (json['announcement'] != null) {
      announcement = <Announcement>[];
      json['announcement'].forEach((v) {
        announcement!.add(new Announcement.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.announcement != null) {
      data['announcement'] = this.announcement!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Announcement {
  String? annOID;
  String? annOMESSAGE;
  String? annOTYPE;
  String? cRBY;
  String? cRDATE;
  String? annOEXPIRE;

  Announcement(
      {this.annOID,
      this.annOMESSAGE,
      this.annOTYPE,
      this.cRBY,
      this.cRDATE,
      this.annOEXPIRE});

  Announcement.fromJson(Map<String, dynamic> json) {
    annOID = json['annO_ID']?.toString();
    annOMESSAGE = json['annO_MESSAGE'];
    annOTYPE = json['annO_TYPE'];
    cRBY = json['cR_BY'];
    cRDATE = json['cR_DATE'];
    annOEXPIRE = json['annO_EXPIRE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['annO_ID'] = this.annOID;
    data['annO_MESSAGE'] = this.annOMESSAGE;
    data['annO_TYPE'] = this.annOTYPE;
    data['cR_BY'] = this.cRBY;
    data['cR_DATE'] = this.cRDATE;
    data['annO_EXPIRE'] = this.annOEXPIRE;
    return data;
  }
}
