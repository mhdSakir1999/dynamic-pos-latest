/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/8/21, 2:18 PM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_warning_alert.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/models/pos/invoice_header_result.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:supercharged/supercharged.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BillCancellationView extends StatefulWidget {
  final List<InvoiceHeader> headers;

  const BillCancellationView({Key? key, required this.headers})
      : super(key: key);

  @override
  _BillCancellationViewState createState() => _BillCancellationViewState();
}

class _BillCancellationViewState extends State<BillCancellationView> {
  final searchController = TextEditingController();
  late List<InvoiceHeader> headers;
  bool clicked = false;
  ScrollController scrollController = ScrollController();
  KeyBoardController keyBoardController = KeyBoardController();
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
                    onTap: () {
                      keyBoardController.init(context);
                      keyBoardController.showBottomDPKeyBoard(searchController,
                          onEnter: () {
                        search();
                      }, buildContext: context);
                    },
                    onEditingComplete: search,
                    autofocus: true,
                    controller: searchController,
                    decoration: InputDecoration(
                        // prefixIcon: Icon(MaterialCommunityIcons.barcode),
                        filled: true,
                        hintText: "bill_cancel_view.scan_barcode".tr()),
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
              thickness: 20,
              child: SingleChildScrollView(
                controller: scrollController,
                child: DataTable(
                  dataRowMinHeight: 50.r,
                  dataRowMaxHeight: 75.r,
                  headingRowColor: WidgetStateColor.resolveWith(
                    (states) {
                      return CurrentTheme.primaryColor!;
                    },
                  ),
                  columns: [
                    DataColumn(label: Text("bill_cancel_view.invoice_no".tr())),
                    DataColumn(label: Text("bill_cancel_view.mode".tr())),
                    DataColumn(label: Text("bill_cancel_view.time".tr())),
                    DataColumn(label: Text("bill_cancel_view.amount".tr())),
                    DataColumn(label: Text("bill_cancel_view.cashier".tr())),
                    DataColumn(
                        label: Text("bill_cancel_view.member_code".tr())),
                    DataColumn(label: Text("bill_cancel_view.status".tr())),
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
      DataCell(Text(header.invheDNETAMT?.toStringAsFixed(2) ?? "0.00")),
      DataCell(Text(header.invheDCASHIER ?? "")),
      DataCell(Text(member)),
      DataCell(Text(
          "bill_cancel_view.${header.invheDINVOICED == true ? 'invoiced' : 'hold'}"
              .tr())),
      DataCell(
        Container(
          child: InkWell(
            onTap: () => onCancelButtonClick(header),
            child: Card(
              color: Colors.redAccent,
              child: Container(
                height: 70.r,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 15.r, vertical: 5.r),
                child: Text(
                  "bill_cancel_view.cancel".tr(),
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
  void onCancelButtonClick(InvoiceHeader header) async {
    if (clicked) return;
    setState(() {
      clicked = true;
    });
    final invNo = header.invheDINVNO;
    if (invNo == null || invNo.isEmpty) return;
    await showConfirmationDialog(invNo);
    if (mounted)
      setState(() {
        clicked = false;
      });
  }

  Future showConfirmationDialog(String invoice) async {
    await showDialog(
      context: context,
      builder: (context) {
        return POSWarningAlert(
            title: "bill_cancellation_warning.title".tr(),
            subtitle: "bill_cancellation_warning.subtitle"
                .tr(namedArgs: {"inv": invoice}),
            showFlare: false,
            actions: [
              ElevatedButton(
                  onPressed: () => cancelBill(invoice),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor()),
                  child: Text("bill_cancellation_warning.yes".tr())),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor()),
                  child: Text("bill_cancellation_warning.no".tr())),
            ]);
      },
    );
  }

  cancelBill(String invoice) async {
    Navigator.pop(context);
    // check permission
    bool hasPermission = SpecialPermissionHandler(context: context)
        .hasPermission(
            accessType: "A",
            permissionCode: PermissionCode.invoiceCancellation);
    // ask permission
    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: context)
          .askForPermission(
              permissionCode: PermissionCode.invoiceCancellation,
              accessType: "A",
              refCode: invoice);
      hasPermission = res.success;
    }

    //if permission granted
    if (hasPermission) {
      EasyLoading.show(status: 'please_wait'.tr());
      final res = await InvoiceController().cancelInvoice(invoice, context);
      EasyLoading.dismiss();
      setState(() {
        clicked = false;
      });
      if (res) Navigator.pop(context);
    }
  }
}
