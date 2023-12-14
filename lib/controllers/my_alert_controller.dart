/*
 * Copyright (c) 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 26/01/2022, 09:34
 */

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/controllers/audit_log_controller.dart';
import 'package:checkout/models/my_alert_permission.dart';
import 'package:checkout/models/pos/permission_approval_status.dart';
import 'package:checkout/models/pos/setup_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:uuid/uuid.dart';

class MyAlertController {
  Future<PermissionApprovalStatus?> myRemoteProcess(String menuCode,
      String accessType,
      String menuName, String refCode) async {
    final Setup? setup = POSConfig().setup;
    // await SetUpController().getSetupData(POSConfig().server);
    try{
      if (setup != null &&
          setup.myAlertPort != null &&
          setup.backendUrl != null) {
        final String uuid = Uuid().v4();

        //get user groups
        final userGroupRes = await ApiClient.call(
            "Common/RemoteAccept", ApiMethod.POST,
            overrideUrl: setup.backendUrl!,
            backendToken: true,
            data: {
              "strLocCode": POSConfig().locCode,
              "strCompCode": POSConfig().comCode,
              "strMenuCode": menuCode,
              "strMenuRight": accessType
            });

        List<dynamic> userGroupDynamicList = userGroupRes?.data['data'] ?? [];

        List<String> userGroups = [];
        userGroupDynamicList.forEach((element) {
          userGroups.add(element['userGroup']);
        });
        final String requestedDate = DateTime.now().toIso8601String();
        final String apiUrl =
            "${setup.backendUrl}Longpoling/UpdateMessage/$uuid";
        print(apiUrl);
        var jwtObj = {
          "apiURL": apiUrl,
          "menuCode": menuCode,
          "option": accessType,
          "userGroup": userGroups,
          "menuName": menuName,
          "location": POSConfig().setupLocationName,
          "locationCode": POSConfig().locCode,
          "refCode": refCode,
          "user": userBloc.currentUser?.uSERHEDUSERCODE,
          "uuid": uuid,
          "timeout": DateFormat("yyyy-MM-dd HH:mm:ss")
              .format(DateTime.now().add(Duration(minutes: 2))),
          "messageId": uuid,
          "requestedDateTime": requestedDate,
          "requested": true,
          "processed": false
        };

        // Create a json web token
        final jwt = JWT(jwtObj, issuer: POSConfig().server, jwtId: uuid);

        // Sign it (default with HS256 algorithm)
        String token = jwt.sign(SecretKey("myposJWTauthentication"));
        jwtObj["token"] = token;

        ///send notification
        String url = '';
        if((setup.myAlertUrl??'').isEmpty){
          url = setup.backendUrl!.split(":")[1] + ':' +
              (setup.myAlertPort ?? '') +
              '/';
        }
        else{
          url = setup.myAlertUrl! +'/';
        }

        url = url.replaceAll("::", ":").replaceAll("//", "/");
        url = url.replaceAll(':/', '://');

        await ApiClient.call('notification/approval', ApiMethod.POST,
            data: jwtObj, overrideUrl: url, errorToast: false);

        //send publish request
        final pollingRes = await ApiClient.call(
            'Longpoling/PublishMessage', ApiMethod.POST,
            overrideUrl: setup.backendUrl,
            backendToken: true,
            data: {
              "header": {
                "messageId": uuid,
                "requestedDateTime": requestedDate,
                "requested": true,
                "processed": false
              },
              "body": {
                "deviceToken": "",
                "reason": "",
                "uuID": "",
                "permission": "",
                "menucode": "",
                "right": ""
              }
            });

        print(pollingRes?.data);
        print(pollingRes?.statusCode);
        if(pollingRes == null || pollingRes.data == null || pollingRes.data['data']==null){
          return null;
        }
        print('++++++++++++++++++++++');
        final MyAlertPermission permissionRes =
        MyAlertPermission.fromJson(pollingRes.data["data"]["body"]);

        // if permission is true get the approved user data
        print(permissionRes.permission);
        print(permissionRes.deviceToken);
        if (permissionRes.permission == true) {
          final deviceTokenRes = await ApiClient.call(
            "Common/DeviceUser/${permissionRes.deviceToken}",
            ApiMethod.GET,
            overrideUrl: setup.backendUrl!,
            backendToken: true,
          );

          //check the device id is valid
          if (permissionRes.uuID == uuid &&
              deviceTokenRes?.data['success']?.toString().toLowerCase() ==
                  'true') {
            String approvedUser = deviceTokenRes?.data['data'];
            permissionRes.uuID = approvedUser;
            await AuditLogController().updateAuditLog(
                permissionRes.menucode ?? '', accessType, refCode,
                permissionRes.reason ?? '', approvedUser);

            EasyLoading.showSuccess('Permission approved by $approvedUser');
            return PermissionApprovalStatus(
                true, approvedUser, permissionRes.reason ?? '');
          }
        }
        else if (permissionRes.permission == false) {
          EasyLoading.showError('easy_loading.permission_reject'.tr());
          return PermissionApprovalStatus(false, '', permissionRes.reason ?? '');
        }
      }
    }on Exception catch(e){
      print(e.toString());
    }
    return null;
  }
}
