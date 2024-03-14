/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 6/8/21, 2:18 PM
 */

import 'dart:async';

import 'package:checkout/components/components.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_warning_alert.dart';
import 'package:checkout/controllers/pos_manual_print_controller.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/models/pos/invoice_header_result.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supercharged/supercharged.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/loyalty_controller.dart';

class ReprintView extends StatefulWidget {
  final List<InvoiceHeader> headers;

  const ReprintView({Key? key, required this.headers}) : super(key: key);

  @override
  _ReprintViewState createState() => _ReprintViewState();
}

class _ReprintViewState extends State<ReprintView> {
  final searchController = TextEditingController();
  final scrollController = ScrollController();
  late List<InvoiceHeader> headers;
  bool clicked = false;

  @override
  void initState() {
    super.initState();
    headers = widget.headers;
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
        child: Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 5.r,
              ),
              GoBackIconButton(),
              SizedBox(
                width: 5.r,
              ),
              Expanded(
                child: Container(
                  child: TextField(
                    onChanged: (value) {
                      if (value.length <= 1 && mounted)
                        setState(() {
                          headers = widget.headers;
                        });
                    },
                    onEditingComplete: search,
                    autofocus: true,
                    controller: searchController,
                    decoration: InputDecoration(
                        // prefixIcon: Icon(MaterialCommunityIcons.barcode),
                        filled: true,
                        hintText: "reprint_view.scan_barcode".tr()),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 15.h,
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              controller: scrollController,
              child: SingleChildScrollView(
                controller: scrollController,
                child: DataTable(
                  dataRowMinHeight: 50.r,
                  headingRowColor: MaterialStateColor.resolveWith(
                    (states) {
                      return CurrentTheme.primaryColor!;
                    },
                  ),
                  columns: [
                    DataColumn(label: Text("reprint_view.invoice_no".tr())),
                    DataColumn(label: Text("reprint_view.mode".tr())),
                    DataColumn(label: Text("reprint_view.time".tr())),
                    DataColumn(label: Text("reprint_view.amount".tr())),
                    DataColumn(label: Text("reprint_view.cashier".tr())),
                    DataColumn(label: Text("reprint_view.member_code".tr())),
                    DataColumn(label: Text("reprint_view.status".tr())),
                    DataColumn(label: Text("")),
                  ],
                  rows: headers.map((e) => item(e)).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  // search cart details by text
  void search() {
    final search = searchController.text;
    // apply  the search condition
    headers = widget.headers
        .where((element) => search == element.invheDINVNO)
        .toList();
    if (mounted) {
      setState(() {});
    }
  }

  DataRow item(InvoiceHeader header) {
    String member = header.invheDMEMBER ?? "N/A";
    if (member.isEmpty) {
      member = "N/A";
    }
    return DataRow(cells: [
      DataCell(Text(header.invheDINVNO ?? "")),
      DataCell(Text(header.invheDMODE ?? "")),
      DataCell(Text(
          DateFormat("hh:mm aa").format(header.invheDTIME ?? DateTime.now()))),
      DataCell(
          Text(NumberFormat('#,##,000.00').format(header.invheDNETAMT ?? 0))),
      DataCell(Text(header.invheDCASHIER ?? "")),
      DataCell(Text(member)),
      DataCell(Text(
          "reprint_view.${header.invheDINVOICED == true ? 'invoiced' : 'hold'}"
              .tr())),
      DataCell(
        Container(
          child: GestureDetector(
            onTap: () => onReprintButtonClick(header),
            child: Card(
              color: POSConfig().primaryDarkGrayColor.toColor(),
              child: Container(
                height: 120.r,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 15.r, vertical: 5.r),
                child: Text(
                  "reprint_view.reprint".tr(),
                  style:
                      TextStyle(color: POSConfig().primaryLightColor.toColor()),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  // handle the selected row
  void onReprintButtonClick(InvoiceHeader header) async {
    if (clicked) return;
    setState(() {
      clicked = true;
    });
    final invNo = header.invheDINVNO;
    if (invNo == null || invNo.isEmpty) return;
    await showConfirmationDialog(invNo, header.invheDMEMBER ?? '');
    if (mounted)
      setState(() {
        clicked = false;
      });
  }

  Future showConfirmationDialog(String invoice, String memberCode) async {
    await showDialog(
      context: context,
      builder: (context) {
        return POSWarningAlert(
            title: "reprint_warning.title".tr(),
            subtitle:
                "reprint_warning.subtitle".tr(namedArgs: {"inv": invoice}),
            showFlare: false,
            actions: [
              ElevatedButton(
                  onPressed: () => reprintBill(invoice, memberCode),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor()),
                  child: Text("reprint_warning.yes".tr())),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor()),
                  child: Text("reprint_warning.no".tr())),
            ]);
      },
    );
  }

  reprintBill(String invoice, String customerCode) async {
    Navigator.pop(context);
    // check permission
    bool hasPermission = SpecialPermissionHandler(context: context)
        .hasPermission(
            accessType: "A",
            permissionCode: PermissionCode.invoiceReprint,
            refCode: invoice);
    // ask permission
    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: context)
          .askForPermission(
              permissionCode: PermissionCode.invoiceReprint,
              accessType: "A",
              refCode: invoice);
      hasPermission = res.success;
    }

    //if permission granted
    if (hasPermission) {
      var res = await InvoiceController().reprintInvoice(invoice);
      double loyaltyPoints = 0;
      if (customerCode.isNotEmpty) {
        var customerRes =
            await LoyaltyController().getLoyaltySummary(customerCode);
        loyaltyPoints = customerRes?.pOINTSUMMARY ?? 0;
      }

      if (POSConfig.crystalPath != '') {
        // await PrintController().printHandler(invoice,
        //     PrintController().rePrintInvoice(invoice, loyaltyPoints), context);
      } else {
        POSManualPrint()
            .printInvoice(data: res, points: loyaltyPoints, reprint: true);
      }

      setState(() {
        clicked = false;
      });
      // if (res) Navigator.pop(context);
    }
  }
}
