/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/29/22, 2:35 PM
 */

class LoginResult {
  bool? success;
  String? token;
  String? message;
  PasswordData? data;
  LoginAttemptData? loginAttemptData;

  LoginResult({this.success, this.token, this.message, this.data});

  LoginResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    token = json['token'];
    message = json['message'];
    data =
        json['data'] != null ? new PasswordData.fromJson(json['data']) : null;
    loginAttemptData = (json?['login_attempts'] != null &&
            json?['login_attempts']?.length != 0)
        ? LoginAttemptData.fromJson(json?['login_attempts']?.first)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['token'] = this.token;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class PasswordData {
  String? passworDPOLICY;
  String? unblocKAT;
  bool? passworDRESET;
  String? passworDPOLICYDESC;

  PasswordData(
      {this.passworDPOLICY,
      this.unblocKAT,
      this.passworDRESET,
      this.passworDPOLICYDESC});

  PasswordData.fromJson(Map<String, dynamic> json) {
    passworDPOLICY = json['passworD_POLICY'];
    unblocKAT = json['unblocK_AT'];
    passworDRESET = json['passworD_RESET'];
    passworDPOLICYDESC = json['passworD_POLICY_DESC'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['passworD_POLICY'] = this.passworDPOLICY;
    data['unblocK_AT'] = this.unblocKAT;
    data['passworD_RESET'] = this.passworDRESET;
    data['passworD_POLICY_DESC'] = this.passworDPOLICYDESC;
    return data;
  }
}

class LoginAttemptData {
  int? numberOfAttempts;
  int? maxAttempts;
  String? blockedAt;

  LoginAttemptData({this.numberOfAttempts, this.maxAttempts, this.blockedAt});

  LoginAttemptData.fromJson(Map<String, dynamic>? json) {
    if (json != null && json.length != 0) {
      numberOfAttempts = json['totalAttempts'];
      maxAttempts = json['maxAttempts'];
      blockedAt = json['blockedAt'];
    }
  }
}
