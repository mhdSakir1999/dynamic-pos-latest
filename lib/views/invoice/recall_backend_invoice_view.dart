/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/8/21, 2:18 PM
 */

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/controllers/transaction_controller.dart';
import 'package:checkout/models/pos/transaction_details.dart';
import 'package:checkout/models/pos/transaction_header_result.dart';
import 'package:checkout/models/pos/transaction_mode_results.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:supercharged/supercharged.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecallBackendInvoice extends StatefulWidget {
  const RecallBackendInvoice({Key? key}) : super(key: key);
  static const String routeName = 'special_functions.backoffice_invoice';

  @override
  _RecallBackendInvoiceState createState() => _RecallBackendInvoiceState();
}

class _RecallBackendInvoiceState extends State<RecallBackendInvoice> {
  final searchController = TextEditingController();
  List<TransactionHeader> _filteredHeaders = [];
  List<TransactionHeader> _allHeaders = [];
  List<TransactionModes> _transactionModes = [];
  TransactionModes? _selectedTransactionModes;
  bool clicked = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // check current cart
    if ((cartBloc.currentCart?.length ?? 0) > 0) {
      EasyLoading.showError('backend_invoice_view.already'.tr());
      Navigator.pop(context);
      return;
    }
    _transactionModes =
        await TransactionController().getBackofficeInvoiceModes();
    if (_transactionModes.isNotEmpty) {
      _selectedTransactionModes = _transactionModes.first;
      _getTransactionHeaders();
    }
    if (mounted) setState(() {});
  }

  Future<void> _getTransactionHeaders() async {
    if (_selectedTransactionModes != null) {
      EasyLoading.show(status: 'please_wait'.tr());
      _filteredHeaders = await TransactionController()
          .getBackofficeInvoiceHeaders(_selectedTransactionModes!);
      _allHeaders = _filteredHeaders;
      if (mounted) setState(() {});
      EasyLoading.dismiss();
    }
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
                    onEditingComplete: search,
                    autofocus: true,
                    controller: searchController,
                    decoration: InputDecoration(
                        // prefixIcon: Icon(MaterialCommunityIcons.barcode),
                        filled: true,
                        hintText: "backend_invoice_view.scan_barcode".tr()),
                  ),
                ),
              ),
              SizedBox(
                width: 15.r,
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<TransactionModes>(
                  focusColor: CurrentTheme.primaryColor,
                  dropdownColor: CurrentTheme.primaryColor,
                  style: CurrentTheme.bodyText2,
                  iconEnabledColor: CurrentTheme.primaryLightColor,
                  value: _selectedTransactionModes,
                  items: _transactionModes.map((TransactionModes value) {
                    return DropdownMenuItem<TransactionModes>(
                      value: value,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15.w),
                        child: Text(value.tXDESC ?? ''),
                      ),
                    );
                  }).toList(),
                  onChanged: (TransactionModes? value) {
                    if (mounted) {
                      setState(() {
                        _selectedTransactionModes = value;
                        _getTransactionHeaders();
                      });
                    }
                  },
                ),
              )
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
                  headingRowColor: WidgetStateColor.resolveWith(
                    (states) {
                      return CurrentTheme.primaryColor!;
                    },
                  ),
                  columns: [
                    DataColumn(
                        label: Text("backend_invoice_view.invoice_no".tr())),
                    DataColumn(
                        label: Text("backend_invoice_view.customer".tr())),
                    DataColumn(
                        label: Text("backend_invoice_view.inv_mode".tr())),
                    DataColumn(label: Text("backend_invoice_view.date".tr())),
                    DataColumn(
                        label: Text("backend_invoice_view.bill_disc".tr())),
                    DataColumn(
                        label: Text("backend_invoice_view.net_amount".tr())),
                    DataColumn(label: Text("")),
                  ],
                  rows: _filteredHeaders.map((e) => item(e)).toList(),
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
    if (search.isNotEmpty) {
      _filteredHeaders =
          _allHeaders.where((element) => element.heDRUNNO == search).toList();
    } else {
      _filteredHeaders = _allHeaders;
    }
    if (mounted) {
      setState(() {});
    }
  }

  DataRow item(TransactionHeader header) {
    String date = header.heDPROCDATE ?? '';
    String time = header.heDTIME ?? '';
    String datetime = '$date $time';
    return DataRow(cells: [
      DataCell(Text(header.heDRUNNO ?? "")),
      DataCell(Text(header.heDCUSCODE ?? "")),
      DataCell(Text(header.heDTYPE ?? "")),
      DataCell(Text(datetime)),
      DataCell(Text(header.heDDISCPER?.toStringAsFixed(2) ?? "0.00")),
      DataCell(Text(header.heDNETAMT?.toStringAsFixed(2) ?? "0.00")),
      // DataCell(Text(
      //     DateFormat("hh:mm aa").format(header.hedT ?? DateTime.now()))),
      DataCell(
        Container(
          child: GestureDetector(
            onTap: () => select(header),
            child: Card(
              color: POSConfig().primaryDarkGrayColor.toColor(),
              child: Container(
                height: 120.r,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 15.r, vertical: 5.r),
                child: Text(
                  "backend_invoice_view.select".tr(),
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
  void select(TransactionHeader header) async {
    if (_selectedTransactionModes == null) {
      return;
    }
    if (clicked) return;
    setState(() {
      clicked = true;
    });
    if (mounted)
      setState(() {
        clicked = false;
      });
    EasyLoading.show(status: 'processing'.tr());
    final List<TransactionDetail> transactionDetailList =
        await TransactionController()
            .getBackofficeInvoiceDetails(_selectedTransactionModes!, header);
    await TransactionController()
        .addTransactionDetailsToInvoice(header, transactionDetailList);
    EasyLoading.dismiss();
    Navigator.pop(context);
    Navigator.pop(context);
  }
}
