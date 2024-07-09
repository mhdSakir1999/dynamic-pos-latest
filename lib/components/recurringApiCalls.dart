/// Author: [TM.Sakir] on 2024-02-06

import 'dart:async';

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_alerts/pos_error_alert.dart';
import 'package:checkout/controllers/pos_alerts/pos_warning_alert.dart';
import 'package:checkout/models/pos/user_hed.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RecurringApiCalls {
  Timer? maxCashTimer;
  Timer? invSyncTimer;
  BuildContext? context;

  setContext(BuildContext context) {
    this.context = context;
  }

  listenPhysicalCash() {
    handlePhysicalCash();
    maxCashTimer = Timer.periodic(Duration(hours: 1), (timer) {
      handlePhysicalCash();
    });
  }

  frequentInvoiceSync() {
    handleInvoiceSync();
    invSyncTimer = Timer.periodic(Duration(minutes: 15), (timer) {
      handleInvoiceSync();
    });
  }

  handlePhysicalCash() async {
    try {
      var res = await getCashDetails();
      if (res != null) {
        double cashSales = res[0]['sales'] ?? 0;
        double cashouts = res[0]['cashOuts'] ?? 0;
        double remainingCash = cashSales - cashouts;

        double cashLimit = POSConfig().setup!.maxCashLimit!;

        if (cashLimit > 0 && remainingCash >= cashLimit) {
          maxCashTimer?.cancel();
          var ignore = await showDialog(
              barrierDismissible: false,
              context: context!,
              builder: (context) => POSWarningAlert(
                    title: 'Physical Cash Limit Alert',
                    subtitle:
                        'Drawer amount: (${remainingCash.toStringAsFixed(2)}) has reached/exeeded the maximum limit: (${cashLimit.toStringAsFixed(2)})',
                    actions: [
                      AlertDialogButton(
                          onPressed: () => Navigator.pop(context, true),
                          text: "login_view.okay".tr()),
                    ],
                    showFlare: true,
                  ));
          if (ignore) {
            await Future.delayed(Duration(minutes: 30), () {
              listenPhysicalCash();
            });
          }
        }
      }
    } catch (e) {
      await LogWriter().saveLogsToFile('ERROR_LOG_', [e.toString()]);
    }
  }

  Future getCashDetails() async {
    final url = "users/cashout_alert";
    UserHed? user = userBloc.currentUser;
    final res = await ApiClient.call(url, ApiMethod.GET,
        successCode: 200,
        authorize: false,
        formData: FormData.fromMap({
          "location": POSConfig().locCode,
          "station": POSConfig().terminalId,
          "shift": user?.shiftNo,
          "cashier": user?.uSERHEDUSERCODE
        }));
    if (res == null) return null;
    if (res.data['success'] == true) {
      return res.data['data'];
    } else {
      return null;
    }
  }

  handleInvoiceSync() {
    if (!POSConfig().localMode &&
        POSConfig().allow_sync_bills &&
        POSConfig().saveInvoiceLocal) {
      try {
        LogWriter().saveLogsToFile('ERROR_LOG_', [
          '*********************** frequentInvoiceSync Started ****************************'
        ]);
        InvoiceController().uploadBillData().then((value) {
          LogWriter().saveLogsToFile('ERROR_LOG_', [
            '*********************** frequentInvoiceSync Finished ****************************',
            value != null
                ? (value?['message'] ?? 'No invoices to sync')
                : 'No invoices to sync'
          ]);
        });
      } catch (e) {
        LogWriter().saveLogsToFile('ERROR_LOG_', [e.toString()]);
      }
    }
  }
}

final recurringApiCalls = RecurringApiCalls();
