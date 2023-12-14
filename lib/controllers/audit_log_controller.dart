/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/10/21, 12:53 PM
 */

//this class can update the audit log

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:dio/dio.dart';

class AuditLogController {
  Future<void> updateInvoiceScreenAuditLog() async {
    await ApiClient.call("audit/invoice", ApiMethod.POST,
        successCode: 200,
        formData: FormData.fromMap({
          "username": userBloc.currentUser?.uSERHEDUSERCODE,
          "location": POSConfig().setupLocation
        }));
  }

  Future<void> updateAuditLog(String permissionCode, String action,
      String reference, String reason, String user) async {
    await ApiClient.call("audit", ApiMethod.POST,
        successCode: 200,
        formData: FormData.fromMap({
          "username": user,
          "location": POSConfig().locCode,
          "permission": permissionCode,
          "reference": reference,
          "action": action,
          "reason": reason,
        }));
  }
}
