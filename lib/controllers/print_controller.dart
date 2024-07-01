/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/1/21, 6:10 PM
 */

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/controllers/pos_alerts/pos_error_alert.dart';
import 'package:checkout/models/pos/print_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:supercharged/supercharged.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

/// Print documents
class PrintController {
  Future printHandler(
      String invoiceNo, Future<PrintStatus> method, BuildContext context,
      {String? customError}) async {
    try {
      var result = await method;
      var tempRes = PrintStatus(true, true, "");

      if (POSConfig().reportBasedInvoice) {
        PrintController().launchPdf(result.urlPath);
        return;
      }

      while (!result.goBack) {
        bool showView = result.showViewButton;
        result = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return POSErrorAlert(
                title: "pos_printer_not_found.title".tr(),
                subtitle: "pos_printer_not_found.subtitle".tr(),
                actions: [
                  // ElevatedButton(
                  //     style: ElevatedButton.styleFrom(
                  //         primary: POSConfig().primaryDarkGrayColor.toColor()),
                  //     onPressed: () async {
                  //       var result = await method;
                  //       Navigator.pop(context, result);
                  //     },
                  //     child: Text("pos_printer_not_found.retry".tr())),
                  !showView
                      ? const SizedBox.shrink()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  POSConfig().primaryDarkGrayColor.toColor()),
                          onPressed: () async {
                            Navigator.pop(context, tempRes);
                            PrintController().launchPdf(result.urlPath);
                          },
                          child: Text("pos_printer_not_found.view".tr())),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              POSConfig().primaryDarkGrayColor.toColor()),
                      onPressed: () {
                        Navigator.pop(context, tempRes);
                      },
                      child: Text("pos_printer_not_found.cancel".tr()))
                ]);
          },
        );
      }
    } on Exception catch (_) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return POSErrorAlert(
              title: "pos_printer_not_found.title".tr(),
              subtitle: "pos_printer_not_found.subtitle".tr(),
              actions: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            POSConfig().primaryDarkGrayColor.toColor()),
                    onPressed: () async {
                      var result = await method;
                      Navigator.pop(context, result);
                    },
                    child: Text("pos_printer_not_found.retry".tr())),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            POSConfig().primaryDarkGrayColor.toColor()),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("pos_printer_not_found.cancel".tr()))
              ]);
        },
      );
    }
  }

  Future<PrintStatus> openDrawer() async {
    final res = await ApiClient.call(
        "print/drawer_open?user=${userBloc.currentUser?.uSERHEDUSERCODE}&localMode=${POSConfig().localMode}",
        ApiMethod.GET,
        local: true);
    PrintResult? printRes;
    if (res?.data != null) printRes = PrintResult.fromJson(res?.data);
    return _getPrintStatus(printRes);
  }

  Future<PrintStatus> printInvoice(String invoiceNo, double earnedPoints,
      double totalPoints, bool taxbill, String? resReturn) async {
    final res = await ApiClient.call(
        "print/invoice/$invoiceNo?reportPrint=${POSConfig().reportBasedInvoice}&earnedPoints=${earnedPoints.toStringAsFixed(2)}&localMode=${POSConfig().localMode}&locCode=${POSConfig().locCode}&totalPoints=${totalPoints.toStringAsFixed(2)}&taxbill=$taxbill",
        ApiMethod.POST,
        formData: FormData.fromMap({
          "printdata": resReturn,
        }),
        local: true);
    PrintResult? printRes;
    if (res?.data != null) printRes = PrintResult.fromJson(res?.data);
    return _getPrintStatus(printRes);
  }

  Future<PrintStatus> printUtilityBill(String invoiceNo) async {
    final res = await ApiClient.call(
        "print/utility_bill/$invoiceNo?reportPrint=${POSConfig().reportBasedInvoice}&localMode=${POSConfig().localMode}",
        ApiMethod.GET,
        local: true);
    PrintResult? printRes;
    if (res?.data != null) printRes = PrintResult.fromJson(res?.data);
    return _getPrintStatus(printRes);
  }

  Future<PrintStatus> printCancelInvoice(String invoiceNo) async {
    final res = await ApiClient.call(
        "print/invoice_cancel/$invoiceNo?reportPrint=${POSConfig().reportBasedInvoice}&localMode=${POSConfig().localMode}&locCode=${POSConfig().locCode}",
        ApiMethod.GET,
        local: true);
    PrintResult? printRes;
    if (res?.data != null) printRes = PrintResult.fromJson(res?.data);
    return _getPrintStatus(printRes);
  }

  Future<PrintStatus> cashIn(String invoiceNo, bool cashIn) async {
    final res = await ApiClient.call(
        "print/${cashIn ? "cash_in" : "cash_out"}/$invoiceNo?reportPrint=${POSConfig().reportBasedInvoice}&localMode=${POSConfig().localMode}&locCode=${POSConfig().locCode}",
        ApiMethod.GET,
        local: true);
    PrintResult? printRes;
    if (res?.data != null) printRes = PrintResult.fromJson(res?.data);
    return _getPrintStatus(printRes);
  }

  Future<PrintStatus> printExchangeVoucher(String invoiceNo) async {
    final res = await ApiClient.call(
        "print/exchange_voucher/$invoiceNo?reportPrint=${POSConfig().reportBasedInvoice}&localMode=${POSConfig().localMode}",
        ApiMethod.GET,
        local: true);
    PrintResult? printRes;
    if (res?.data != null) printRes = PrintResult.fromJson(res?.data);
    return _getPrintStatus(printRes);
  }

  Future<PrintStatus> rePrintInvoice(
      String invoiceNo, double loyaltyPoints) async {
    final res = await ApiClient.call(
        "print/reprint_invoice/$invoiceNo?reportPrint=${POSConfig().reportBasedInvoice}&localMode=${POSConfig().localMode}&locCode=${POSConfig().locCode}&loyaltyPoints=${loyaltyPoints.toStringAsFixed(2)}",
        ApiMethod.GET,
        local: true);
    PrintResult? printRes;
    if (res?.data != null) printRes = PrintResult.fromJson(res?.data);
    return _getPrintStatus(printRes);
  }

  Future<PrintStatus> signOnSlip(double amount) async {
    final String user = userBloc.currentUser?.uSERHEDUSERCODE ?? '';

    final res = await ApiClient.call(
        "print/signon/$user?reportPrint=${POSConfig().reportBasedInvoice}&terminal=${POSConfig().terminalId}&localMode=${POSConfig().localMode}&amount=${amount.toStringAsFixed(2)}",
        ApiMethod.GET,
        local: true);
    PrintResult? printRes;
    if (res?.data != null) printRes = PrintResult.fromJson(res?.data);
    return _getPrintStatus(printRes);
  }

  Future<PrintStatus> signOffSlip() async {
    final String user = userBloc.currentUser?.uSERHEDUSERCODE ?? '';
    final res = await ApiClient.call(
        "print/signoff/$user?reportPrint=${POSConfig().reportBasedInvoice}&terminal=${POSConfig().terminalId}&localMode=${POSConfig().localMode}",
        ApiMethod.GET,
        local: true);
    PrintResult? printRes;
    if (res?.data != null) printRes = PrintResult.fromJson(res?.data);
    return _getPrintStatus(printRes);
  }

  Future<PrintStatus> printMngSignOffSlip(String user, String location,
      String terminal, String shift, String signondate) async {
    final res = await ApiClient.call(
        "print/mngsignoff/$user?location=$location&station=$terminal&shift=${shift.toString()}&signOnDate=$signondate",
        ApiMethod.GET,
        local: true);
    PrintResult? printRes;
    if (res?.data != null) printRes = PrintResult.fromJson(res?.data);
    return _getPrintStatus(printRes);
  }

  PrintStatus _getPrintStatus(PrintResult? res) {
    bool success = res?.success ?? false;
    String path = res?.pdf ?? "";
    bool viewButton = path.isNotEmpty;
    if (path.isNotEmpty) {
      success = false;
    }
    return PrintStatus(success, viewButton, path);
  }

  Future<void> launchPdf(String pdf) async {
    // printing
    pdf += ".pdf";
    var data = await http.get(Uri.parse(pdf));

    await Printing.layoutPdf(onLayout: (_) => data.bodyBytes);

    return;
    // String url = POSConfig().local + pdf;
    // url = url.replaceAll("/api/", "/");
    // if (await canLaunch(url)) {
    //   await launch(
    //     url,
    //     forceSafariVC: false,
    //     forceWebView: false,
    //   );
    // } else {
    //   POSLoggerController.addNewLog(
    //       POSLogger(POSLoggerLevel.error, "Could not launch the pdf $url"));
    // }
  }
}
