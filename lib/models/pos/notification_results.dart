/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/27/22, 5:26 PM
 */

class NotificationResults {
  bool? success;
  List<Notifications>? notifications;
  int? count;

  NotificationResults({this.success, this.notifications, this.count});

  NotificationResults.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['notifications'] != null) {
      notifications = <Notifications>[];
      json['notifications'].forEach((v) {
        notifications!.add(new Notifications.fromJson(v));
      });
    }
    count = json['count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.notifications != null) {
      data['notifications'] =
          this.notifications!.map((v) => v.toJson()).toList();
    }
    data['count'] = this.count;
    return data;
  }
}

class Notifications {
  int? notIID;
  String? notIMESSAGE;
  String? notITYPE;
  String? cRBY;
  String? cRDATE;
  String? notIEXPIRE;

  Notifications(
      {this.notIID,
      this.notIMESSAGE,
      this.notITYPE,
      this.cRBY,
      this.cRDATE,
      this.notIEXPIRE});

  Notifications.fromJson(Map<String, dynamic> json) {
    notIID = json['notI_ID'];
    notIMESSAGE = json['notI_MESSAGE'];
    notITYPE = json['notI_TYPE'];
    cRBY = json['cR_BY'];
    cRDATE = json['cR_DATE'];
    notIEXPIRE = json['notI_EXPIRE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['notI_ID'] = this.notIID;
    data['notI_MESSAGE'] = this.notIMESSAGE;
    data['notI_TYPE'] = this.notITYPE;
    data['cR_BY'] = this.cRBY;
    data['cR_DATE'] = this.cRDATE;
    data['notI_EXPIRE'] = this.notIEXPIRE;
    return data;
  }
}
