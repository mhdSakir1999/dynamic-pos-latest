/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/8/21, 2:18 PM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/models/pos/hold_header_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supercharged/supercharged.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecallView extends StatefulWidget {
  final List<HoldInvoiceHeaders> headers;

  const RecallView({Key? key, required this.headers}) : super(key: key);

  @override
  _RecallViewState createState() => _RecallViewState();
}

class _RecallViewState extends State<RecallView> {
  final searchController = TextEditingController();
  late List<HoldInvoiceHeaders> headers;
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
                        hintText: "recall_view.scan_barcode".tr()),
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
              child: SingleChildScrollView(
                child: DataTable(
                  dataRowMinHeight: 50.r,
                  headingRowColor: MaterialStateColor.resolveWith(
                    (states) {
                      return CurrentTheme.primaryColor!;
                    },
                  ),
                  columns: [
                    DataColumn(label: Text("recall_view.invoice_no".tr())),
                    DataColumn(label: Text("recall_view.inv_mode".tr())),
                    DataColumn(label: Text("recall_view.time".tr())),
                    DataColumn(label: Text("recall_view.net_amount".tr())),
                    DataColumn(label: Text("recall_view.cashier".tr())),
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

  DataRow item(HoldInvoiceHeaders header) {
    return DataRow(cells: [
      DataCell(Text(header.invheDINVNO ?? "")),
      DataCell(Text(header.invheDMODE ?? "")),
      DataCell(Text(
          DateFormat("hh:mm aa").format(header.invheDTIME ?? DateTime.now()))),
      DataCell(Text(header.invheDNETAMT?.toStringAsFixed(2) ?? "0.00")),
      DataCell(Text(header.invheDCASHIER ?? "")),
      DataCell(
        InkWell(
          onTap: () => select(header),
          child: Card(
            color: POSConfig().primaryDarkGrayColor.toColor(),
            child: Container(
              height: 120.r,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 15.r, vertical: 5.r),
              child: Text(
                "recall_view.select".tr(),
                style:
                    TextStyle(color: POSConfig().primaryLightColor.toColor()),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  // handle the selected row
  void select(HoldInvoiceHeaders header) async {
    if (clicked) return;
    setState(() {
      clicked = true;
    });
    await InvoiceController().getHoldCart(header);
    if (mounted)
      setState(() {
        clicked = false;
      });
    Navigator.pop(context);
  }
}
