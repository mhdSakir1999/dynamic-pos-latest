/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: TM.Sakir
 * Created At: 15/7/24, 11:30 AM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InvoiceCompareView extends StatefulWidget {
  const InvoiceCompareView({Key? key}) : super(key: key);

  @override
  _InvoiceCompareViewState createState() => _InvoiceCompareViewState();
}

class _InvoiceCompareViewState extends State<InvoiceCompareView> {
  final searchController = TextEditingController();
  Map? serverInvDet;
  Map? localInvDet;
  String invoiceNo = '';
  KeyBoardController keyBoardController = KeyBoardController();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    var textStyle = TextStyle(color: Colors.black, fontWeight: FontWeight.bold);
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
                    onTap: () {
                      keyBoardController.init(context);
                      keyBoardController.showBottomDPKeyBoard(searchController,
                          onEnter: () async {
                        invoiceNo = '';
                        EasyLoading.show(status: 'please_wait'.tr());
                        serverInvDet = await InvoiceController()
                            .getInvdetFromBothDb(searchController.text, false);
                        localInvDet = await InvoiceController()
                            .getInvdetFromBothDb(searchController.text, true);
                        EasyLoading.dismiss();
                        if (localInvDet != null) {
                          invoiceNo = searchController.text;
                        }
                        setState(() {});
                      }, buildContext: context);
                    },
                    onEditingComplete: () async {
                      invoiceNo = '';
                      EasyLoading.show(status: 'please_wait'.tr());
                      serverInvDet = await InvoiceController()
                          .getInvdetFromBothDb(searchController.text, false);
                      localInvDet = await InvoiceController()
                          .getInvdetFromBothDb(searchController.text, true);
                      EasyLoading.dismiss();
                      if (localInvDet != null) {
                        invoiceNo = searchController.text;
                      }
                      setState(() {});
                    },
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: height * 0.06,
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                color: CurrentTheme.primaryColor!),
                            child: Center(
                              child: const Text(
                                'Server Invoice Details',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        serverInvDet?['heD_COUNT'] == 0
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  height: height * 0.06,
                                  decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                      color: const Color.fromARGB(
                                          255, 208, 208, 208)),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        const Text(
                                          'Invoice header not found',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                color: Colors.white),
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20.0, 8, 20, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Header Amount            :  ${serverInvDet?['heD_AMOUNT'] ?? 0.00}',
                                      style: textStyle,
                                    ),
                                    Text(
                                      'Detail Amount              :  ${serverInvDet?['deT_AMOUNT'] ?? 0.00}',
                                      style: textStyle,
                                    ),
                                    Text(
                                      'Payment Amount         :  ${serverInvDet?['paY_AMOUNT'] ?? 0.00}',
                                      style: textStyle,
                                    ),
                                    Text(
                                      'Product Count              :  ${serverInvDet?['deT_COUNT'] ?? 0}',
                                      style: textStyle,
                                    ),
                                    Text(
                                      'Payment Mode Count  :  ${serverInvDet?['paY_COUNT'] ?? 0}',
                                      style: textStyle,
                                    )
                                  ],
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          // color: Colors.white,
                        ),
                        // height: height * 0.8,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: height * 0.06,
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                    color: CurrentTheme.primaryColor!),
                                child: Center(
                                  child: const Text(
                                    'Local Invoice Details',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            localInvDet?['heD_COUNT'] == 0
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      height: height * 0.06,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(12)),
                                          color: const Color.fromARGB(
                                              255, 208, 208, 208)),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            const Text(
                                              'Invoice header not found',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox.shrink(),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                    color: Colors.white),
                                child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20.0, 8, 20, 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Header Amount            :  ${localInvDet?['heD_AMOUNT'] ?? 0.00}',
                                          style: textStyle,
                                        ),
                                        Text(
                                          'Detail Amount              :  ${localInvDet?['deT_AMOUNT'] ?? 0.00}',
                                          style: textStyle,
                                        ),
                                        Text(
                                          'Payment Amount         :  ${localInvDet?['paY_AMOUNT'] ?? 0.00}',
                                          style: textStyle,
                                        ),
                                        Text(
                                          'Product Count              :  ${localInvDet?['deT_COUNT'] ?? 0}',
                                          style: textStyle,
                                        ),
                                        Text(
                                          'Payment Mode Count  :  ${localInvDet?['paY_COUNT'] ?? 0}',
                                          style: textStyle,
                                        )
                                      ],
                                    )),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                          onPressed: () async {
                            if (localInvDet?['heD_COUNT'] == 0) {
                              EasyLoading.showError('No invoice data found');
                              return;
                            }
                            EasyLoading.show(status: 'please_wait'.tr());
                            final loc = POSConfig().locCode;
                            final res = await ApiClient.call(
                                "invoice/local_invoice_delete?invNo=$invoiceNo&locCode=$loc&invMode=INV",
                                local: true,
                                ApiMethod.POST);
                            EasyLoading.dismiss();
                            if (res?.data != null &&
                                res?.data != '' &&
                                res?.data['success'] == true) {
                              EasyLoading.showSuccess(
                                  'Successfuly deleted from local database');
                            }
                            EasyLoading.show(status: 'please_wait'.tr());
                            localInvDet = await InvoiceController()
                                .getInvdetFromBothDb(
                                    searchController.text, true);
                            EasyLoading.dismiss();
                            if (localInvDet != null) {
                              invoiceNo = searchController.text;
                            }
                            setState(() {});
                          },
                          child: const Text('Delete'))
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    ));
  }

  // // search cart details by text
  // void search() {
  //   final search = searchController.text;
  //   // apply  the search condition
  //   headers =
  //       widget.headers.where((element) => search == element.invNo).toList();
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }
}
