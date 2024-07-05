/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: TM.Sakir
 * Created At: 25/6/24, 10:58 AM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/models/pos/invoice_header_result.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CODPendingInvoiceView extends StatefulWidget {
  final List<CODInvoiceHeader> headers;

  const CODPendingInvoiceView({Key? key, required this.headers})
      : super(key: key);

  @override
  _CODPendingInvoiceViewState createState() => _CODPendingInvoiceViewState();
}

class _CODPendingInvoiceViewState extends State<CODPendingInvoiceView> {
  final searchController = TextEditingController();
  late List<CODInvoiceHeader> headers;
  bool selected = false;
  int selectedIndex = -1;
  String remark = 'Select a header to view remarks';
  KeyBoardController keyBoardController = KeyBoardController();
  @override
  void initState() {
    super.initState();
    headers = widget.headers;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DataTable(
                        dataRowMinHeight: 50.r,
                        headingRowColor: WidgetStateColor.resolveWith(
                          (states) {
                            return CurrentTheme.primaryColor!;
                          },
                        ),
                        columns: [
                          DataColumn(
                              label: Text(
                                  "cod_pendingInvoice_view.invoice_no".tr())),
                          DataColumn(
                              label: Text("cod_pendingInvoice_view.date".tr())),
                          DataColumn(
                              label:
                                  Text("cod_pendingInvoice_view.cashier".tr())),
                          DataColumn(
                              label:
                                  Text("cod_pendingInvoice_view.amount".tr())),
                        ],
                        rows: headers.map((e) => item(e)).toList(),
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                              // color: Colors.white,
                            ),
                            height: height * 0.8,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    height: height * 0.06,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        color: CurrentTheme.primaryColor!),
                                    child: Center(
                                      child:const Text(
                                        'Invoice Remarks',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    // height: height * 0.4,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                        color: Colors.white),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          remark,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // child: ,
                          ),
                        ))
                  ],
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
    headers =
        widget.headers.where((element) => search == element.invNo).toList();
    if (mounted) {
      setState(() {});
    }
  }

  DataRow item(CODInvoiceHeader header) {
    return DataRow(
      color: headers.indexOf(header) == selectedIndex
          ? WidgetStatePropertyAll(CurrentTheme.primaryDarkColor)
          : WidgetStatePropertyAll(Colors.transparent),
      cells: [
        DataCell(Text(header.invNo ?? "")),
        DataCell(Text(header.date ?? "")),
        DataCell(Text(header.cashier ?? "")),
        DataCell(Text(header.paidAmount.toString() ?? "")),
      ],
      onSelectChanged: (value) {
        if (value == true) {
          var index = headers.indexOf(header);
          String rems = (header.rem1 ?? '') +
              '\n' +
              (header.rem2 ?? '') +
              '\n' +
              (header.rem3 ?? '') +
              '\n' +
              (header.rem4 ?? '') +
              '\n' +
              (header.rem5 ?? '');
          rems = rems.trim();
          setState(() {
            selectedIndex = index == -1 ? 0 : index;
            remark = rems == '' ? 'No Remarks Available' : rems;
          });
        }
      },
    );
  }
}
