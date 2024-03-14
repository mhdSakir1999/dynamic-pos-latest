/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/21/21, 4:32 PM
 */
import 'dart:convert';

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';

/// This class contains all user authentication
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/config/shared_preference_controller.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/pos/logged_user_result.dart';
import 'package:checkout/models/pos/user_hed.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:dio/dio.dart';
import 'package:checkout/extension/extensions.dart';

import '../models/pos/login_results.dart';

/// This class contains all user authentication
class AuthController {
  Future<String?> checkUsername(String userName,
      {bool authorize = true}) async {
    final url = "users/validate_user/$userName";
    final res = await ApiClient.call(url, ApiMethod.GET,
        successCode: 200,
        authorize: authorize,
        formData: FormData.fromMap({
          "location": POSConfig().locCode,
          "station": POSConfig().terminalId,
        }));
    if (res == null) return "Something went wrong";
    if (res.statusCode != 200) {
      return res.data["message"];
    } else {
      final userHed = UserHed.fromJson(res.data["user"]);
      if (userHed.uSERHEDACTIVEUSER == false) return "Inactive User";
      userBloc.changeCurrentUser(userHed);
    }
    return null;
  }

  Future<PasswordData?> getUserPasswordPolicy() async {
    final res = await ApiClient.call(
        "users/password_policy/${userBloc.currentUser?.uSERHEDUSERCODE}",
        ApiMethod.GET,
        successCode: 200,
        authorize: false);
    if (res?.data != null && res?.data['passwordPolicy'] != null) {
      return PasswordData.fromJson(res?.data['passwordPolicy']);
    }
    return null;
  }

  Future<LoginResult?> checkPassword(
      String userName, String password, String loccode) async {
    // final userHed = userBloc.currentUser;
    // if (userHed == null) {
    //   POSLoggerController.addNewLog(
    //       POSLogger(POSLoggerLevel.error, "Cannot access the saved user"));
    //   return null;
    // }
    final res = await ApiClient.call(
        "users/password_verification", ApiMethod.POST,
        successCode: 200,
        authorize: false,
        formData: FormData.fromMap(
            {"username": userName, "password": password, "location": loccode}));
    if (res == null) return null;
    if (res.statusCode != 200) {
      // EasyLoading.show(status: LoginResult.fromJson(res.data).toString()); // res.data => null
      return LoginResult.fromJson(res.data);
    } else {
      if (!(res.data["success"]?.toString().parseBool() ?? false)) {
        return LoginResult.fromJson(res.data);
      } else {
        ApiClient.bearerToken = res.data["token"];
        await SharedPreferenceController().getConfig(true);
        await checkUsername(userName, authorize: true);
        return LoginResult.fromJson(res.data);
      }
    }
  }

  Future<String> checkTerminal(String userName, String loccode,
      String terminalID, bool checkPOSGroups) async {
    // get ip address from local api
    final ipAddressRes =
        await ApiClient.call('users/ip_address', ApiMethod.GET, local: true);
    String ipAddress = '';
    try {
      ipAddress = ipAddressRes?.data?['ip_address'];
    } on Exception {}
    print(ipAddress);
    final res =
        await ApiClient.call("users/terminal_verification", ApiMethod.POST,
            successCode: 200,
            authorize: true,
            formData: FormData.fromMap({
              "username": userName,
              "loccode": loccode,
              "terminalID": terminalID,
              'ipAddress': ipAddress,
              'checkPOSGroups': checkPOSGroups
            }));
    if (res == null) return "Terminal Validation Error Occured";
    if (res.statusCode != 200) {
      return res.data['message'];
    } else {
      return res.data['message'];
    }
  }

  Future<String?> signOnProcess(String floatValue) async {
    final userHed = userBloc.currentUser;

    if (userHed == null) {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.error, "Cannot access the saved user"));
      return "Something went wrong";
    }
    final res = await ApiClient.call("users/sign_on", ApiMethod.POST,
        successCode: 200,
        formData: FormData.fromMap({
          "userName": userHed.uSERHEDUSERCODE,
          "terminalId": POSConfig().terminalId,
          "location": POSConfig().locCode,
          "floatVal": floatValue,
        }));
    if (res == null) return "Something went wrong";
    if (res.statusCode != 200) {
      return "Something went wrong";
    } else {
      await getUserPermission();
      return null;
    }
  }

  Future<String?> getUserPermission() async {
    final userHed = userBloc.currentUser;

    if (userHed == null) {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.error, "Cannot access the saved user"));
      return "Something went wrong";
    }
    final res = await ApiClient.call(
        "users/user_permission/${userHed.uSERHEDUSERCODE}", ApiMethod.GET,
        successCode: 200);
    if (res == null) return "Something went wrong";
    if (res.statusCode != 200) {
      return "Something went wrong";
    } else {
      userBloc.changeUserDetails(LoggedUserResult.fromJson(res.data["data"]));
      return null;
    }
  }

  Future<LoggedUserResult?> getUserPermissionListByUserCode(String code) async {
    final res = await ApiClient.call(
        "users/user_permission/$code", ApiMethod.GET,
        successCode: 200);
    if (res == null) return null;
    return LoggedUserResult.fromJson(res.data["data"]);
  }

  Future<String?> getCurrentUserTitle() async {
    final res = await ApiClient.call(
        "users/logged_user/${POSConfig().setupLocation}/${POSConfig().terminalId}",
        ApiMethod.GET,
        errorToast: false,
        successCode: 200);
    if (res == null) return null;
    return res.data["user"];
  }

  /// Temp sign on
  Future<String?> tempSignOn() async {
    final userHed = userBloc.currentUser;

    final res = await ApiClient.call("users/temp_sign_on", ApiMethod.POST,
        formData: FormData.fromMap({"username": userHed?.uSERHEDUSERCODE}),
        successCode: 200);
    if (res == null) return "Something went wrong";
    if (res.statusCode == 403) return res.data["message"];
    return null;
  }

  /// Temp sign on

  Future<bool> signOff() async {
    final userHed = userBloc.currentUser;
    final res = await ApiClient.call("users/sign_off", ApiMethod.POST,
        formData: FormData.fromMap(
          {
            "username": userHed?.uSERHEDUSERCODE,
            "terminal_id": POSConfig().terminalId
          },
        ),
        successCode: 200,
        errorToast: false);
    if (res == null) return false;
    if (res.statusCode == 200) return true;
    return false;
  }

  //if the user is active return the true
  bool checkUserActiveStatus() {
    final userHed = userBloc.currentUser;

    bool res = userHed?.uSERHEDACTIVEUSER ?? false;
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "User Active Status: $res"));
    return res;
  }

  //new change
  /* 
    * Author: TM.Sakir
    * Created: 2023-09-21 5:40PM
    * Reason:  getting pending manager signoff/s
    */
  Future<List<UserHed>?> getPendingManagerSignOff() async {
    List<UserHed>? list;
    var res = await ApiClient.call(
        'denomination/get_pending_signoff/${POSConfig().locCode}',
        ApiMethod.GET);
    if (res!.data != null) {
      var parsed = jsonDecode(res.toString())['data'];
      list = (parsed as List).map((e) => UserHed.fromJson(e)).toList();
      return list;
    }
    return list;
  }

  //  if this is false the user is not sign off
  bool checkManagerSignOff() {
    final userHed = userBloc.currentUser;

    bool res = userHed?.uSERHEDISMANAGERSIGNEDOFF ?? true;
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Backoffice Sign off: $res"));
    return res;
  }

  //  if this is false the user is not sign off
  bool checkSignOff() {
    final userHed = userBloc.currentUser;

    bool res = userHed?.uSERHEDISSIGNEDOFF ?? false;
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Sign off: $res"));
    return res;
  }

  //return the station id or null
  String? checkUserAlreadySignedOn() {
    final userHed = userBloc.currentUser;
    bool res = userHed?.uSERHEDISSIGNEDON ?? false;
    String? stationId;
    if (res) {
      stationId = userHed?.uSERHEDSTATIONID ?? "";
    }

    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Station Id: $stationId"));
    return stationId;
  }

  Future<double> getMaxDiscountForUser(String user) async {
    double discount = 0;
    final res = await ApiClient.call("users/max_discount/$user", ApiMethod.GET,
        authorize: true);
    discount = res?.data?["amount"]?.toString().parseDouble() ?? 0;
    return discount;
  }

  Future<String?> updatePassword(
      String user, String oldPassword, String newPassword) async {
    final res = await ApiClient.call('users/password/$user', ApiMethod.PUT,
        authorize: false,
        formData: FormData.fromMap(
            {'password': oldPassword, 'newPassword': newPassword}));
    return res?.data['message'] ?? 'Something went wrong';
  }
}
