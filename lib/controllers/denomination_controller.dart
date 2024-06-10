/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: [TM.Sakir] & Shalika Ashan
 * Created At: 7/7/21, 3:24 PM
 */
import 'dart:convert';

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_manual_print_controller.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/models/pos/pos_denomination_model.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class DenominationController {
  Future managerSignOff(
      List<POSDenominationModel> list, bool spot, String? approvedUser,
      {bool pendingSignoff = false}) async {
    //new chang -- passing a flag to identify the current_user of pending_user(get from pending sign off dialog window)
    final user = !pendingSignoff ? userBloc.currentUser : userBloc.pendingUser;

    List<POSDenominationDetail> denominationDetails = [];
    List<POSDenominationModel> denominations = [];

    // going through the list and assigned to the list
    list.forEach((element) {
      element.denominations.forEach((den) {
        if ((den.count ?? 0) > 0) {
          denominationDetails.add(den);
        }
      });

      if (element.totalValue > 0) {
        //element.totalValue not calculated & now it is always 0
        denominations.add(element);
      }
    });

    final map = {
      "spot": spot,
      "denomination": denominations.map((e) => e.toMap()).toList(),
      "denomination_details":
          denominationDetails.map((e) => e.toMap()).toList(),
      "user": user?.uSERHEDUSERCODE ?? "",
      "shift_no": user?.shiftNo?.toString() ?? "0",
      "sign_on_date": user?.uSERHEDSIGNONDATE ?? "",
      "sign_on_time": user?.uSERHEDSIGNONTIME ?? "",
      "location": POSConfig().locCode,
      "terminal_id": user?.uSERHEDSTATIONID ??
          "", //POSConfig().terminalId, //passing the terminal id which is being managerSigned-off
      "approved_user": approvedUser ?? user?.uSERHEDUSERCODE
    };
    print(map.toString());
    await LogWriter().saveLogsToFile('API_Log_', [
      '####################################################################',
      jsonEncode(map),
      '####################################################################'
    ]);

    final res = await ApiClient.call("denomination", ApiMethod.POST, data: map);
    await AuthController().checkUsername(
        userBloc.currentUser?.uSERHEDUSERCODE ?? '',
        authorize: true);
    if (res?.statusCode == 200) {
      POSConfig.localPrintData = res?.data['data'];
      POSConfig.denominations = denominations;
      POSConfig.denominationDet = denominationDetails;
      print(POSConfig.localPrintData);
      EasyLoading.showSuccess('easy_loading.success_save'.tr());

      //new change -- after successfuly manager signed-off, clear the pendinguser bloc
      // if (pendingSignoff) {
      //   userBloc.changePendingUser(UserHed());
      // }

      if (POSConfig.crystalPath != '') {
        await PrintController().printMngSignOffSlip(
            user?.uSERHEDUSERCODE ?? '',
            POSConfig().setupLocation,
            user?.uSERHEDSTATIONID ?? "", //POSConfig().terminalId,
            user?.shiftNo?.toString() ?? "0",
            user?.uSERHEDSIGNONTIME ?? "");
      } else {
        await POSManualPrint().printManagerSlip(
            data: res?.data['data'],
            denominations: denominations,
            denominationDet: denominationDetails,
            spotcheck: spot);
      }
    }
  }

//
  Future<void> reprintManagerSignoff(
      {required String userId,
      required String locCode,
      required String terminalId,
      required String shiftNo,
      required String date}) async {
    EasyLoading.show(status: 'Start Printing...');
    final map = {
      "user": userId,
      "shift_no": shiftNo,
      "sign_on_date": date,
      "location": locCode,
      "terminal_id": terminalId
    };
    final res = await ApiClient.call(
        "denomination/reprint_mngsignoff", ApiMethod.POST,
        data: map);

    if (res?.statusCode == 200 &&
        res?.data != null &&
        res?.data['data'] != null) {
      try {
        var json = jsonDecode(res?.data['data'].toString() ?? '');

        List<POSDenominationDetail> denoDets = List.generate(
            json['Denominations']?.length,
            (index) =>
                POSDenominationDetail.fromMap(json['Denominations'][index]));
        List<POSDenominationModel> denominations = [];

        await POSManualPrint().printManagerSlip(
            data: res?.data['data'],
            denominations: denominations,
            denominationDet: denoDets);
        EasyLoading.dismiss();
        EasyLoading.showSuccess('Print Success');
      } catch (e) {
        print(e.toString());
        EasyLoading.dismiss();
        EasyLoading.showError('Cannot Proceed The Printing Process !!!');
      }
    } else {
      EasyLoading.dismiss();
      EasyLoading.showError('Record Not Found !!!');
    }
  }
}
