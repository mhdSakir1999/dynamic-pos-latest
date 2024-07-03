/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 5/13/21, 1:55 PM
 */

import 'dart:async';

import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/ext_loyalty/ext_module_helper.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/controllers/customer_controller.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/loyalty_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/usb_serial_controller.dart';
import 'package:checkout/models/loyalty/customer_list_result.dart';
import 'package:checkout/models/loyalty/loyalty_summary.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/customer/customer_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'customer_helper.dart';
import '../invoice/invoice_app_bar.dart';
import 'package:supercharged/supercharged.dart';

/// This is the product search screen
class CustomerSearchView extends StatefulWidget {
  static const routeName = "customer_search";

  @override
  _CustomerSearchViewState createState() => _CustomerSearchViewState();
}

class _CustomerSearchViewState extends State<CustomerSearchView> {
  TextEditingController searchEditingController = TextEditingController();
  List<CustomerResult>? customerList;
  CustomerResult? selectedCustomer;
  double height = 60;
  bool _sort = true;
  int _sortIndex = 0;
  late Timer _timer;
  final FocusNode _keyboardFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    KeyBoardController().dismiss();
    init();
    if (POSConfig().dualScreenWebsite != "")
      DualScreenController().setView('loyalty');
    // _timer = Timer.periodic(Duration(seconds: 1), (_) => _getDualScreenData());
  }

  /// listen for dual screen input
  Future _getDualScreenData() async {
    final res = await ApiClient.call("invoice/temp", ApiMethod.GET,
        local: true, errorToast: false);
    String memberCode = res?.data["summary"]?["custom"] ?? "";
    if (memberCode.isNotEmpty) {
      await InvoiceController().clearMemberCode();
      // if that is success one
      if (memberCode.contains('code:')) {
        memberCode = memberCode.replaceAll('code:', '');
        searchEditingController.text = memberCode;
        searchCustomer(memberCode);
        //clear field
        _timer.cancel();
      } else {
        //show alert
        await showDialog(
          context: context,
          builder: (context) {
            return POSErrorAlert(
                title: memberCode.replaceAll('message:', ''),
                subtitle: '',
                actions: [
                  AlertDialogButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      text: 'Ok')
                ]);
          },
        );
      }
    }
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    if (POSConfig().dualScreenWebsite != "")
      DualScreenController().setView('invoice');
    _keyboardFocus.dispose();
    searchEditingController.dispose();
    super.dispose();
  }

  Future init() async {
    EasyLoading.show(status: 'loyalty_server_error.checking_connection'.tr());
    final res = await POSConnectivity().pingToLoyaltyServer();
    if (!res && mounted)
      showDialog(
        context: context,
        builder: (context) => POSErrorAlert(
            title: "loyalty_server_error.title".tr(),
            subtitle: "loyalty_server_error.subtitle".tr(),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        POSConfig().primaryDarkGrayColor.toColor()),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "loyalty_server_error.okay".tr(),
                  style: Theme.of(context).dialogTheme.contentTextStyle,
                ),
              )
            ]),
      );
    EasyLoading.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
        child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildBody(),
      ),
    ));
  }

  Future searchCustomer(String keyword) async {
    EasyLoading.show(status: 'please_wait'.tr());
    final res = await CustomerController().searchCustomer(keyword);
    if (res != null) {
      if (mounted) {
        setState(() {
          customerList = res.customerList;
        });
      }
    }
    _keyboardFocus.requestFocus();
    EasyLoading.dismiss();
  }

  Widget buildBody() {
    return Column(
      children: [
        POSInvoiceAppBar(
          showCustomer: false,
        ),
        Expanded(child: buildContent())
      ],
    );
  }

  Widget buildContent() {
    return Container(
      child: Row(
        children: [
          Container(width: ScreenUtil().screenWidth / 2, child: buildLHS()),
          Expanded(child: buildRHS()),
        ],
      ),
    );
  }

  Widget buildLHS() {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 15.r,
            ),
            GoBackIconButton(),
            SizedBox(
              width: 15.r,
            ),
            Expanded(
              child: TextField(
                onTap: () {
                  KeyBoardController().dismiss();
                  KeyBoardController().showBottomDPKeyBoard(
                      searchEditingController,
                      buildContext: context, onEnter: () {
                    searchCustomer(searchEditingController.text);
                    KeyBoardController().dismiss();
                  });
                },
                autofocus: true,
                controller: searchEditingController,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                    fontSize: 22.sp, color: CurrentTheme.primaryColor),
                onEditingComplete: () {
                  searchCustomer(searchEditingController.text);
                },
                decoration: InputDecoration(
                    filled: true,
                    prefixIcon: Icon(
                      MaterialCommunityIcons.magnify,
                      size: 28.sp,
                    ),
                    hintText: "customer_search_view.search_text".tr(),
                    hintStyle: TextStyle(
                        fontSize: 22.sp,
                        color: CurrentTheme.primaryColor,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 10.h,
        ),
        Expanded(child: buildItemList())
      ],
    );
  }

  Widget buildItemList() {
    final headingStyle = TextStyle(
        fontSize: POSConfig().cartDynamicButtonFontSize.sp,
        fontWeight: FontWeight.bold,
        color: CurrentTheme.primaryLightColor);

    return Container(
      width: double.infinity,
      child: KeyboardListener(
        focusNode: _keyboardFocus,
        onKeyEvent: (value) {},
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    _buildTitleItem(
                        text: "customer_search_view.code".tr(), index: 0),
                    _buildTitleItem(
                        text: "customer_search_view.name".tr(),
                        index: 1,
                        flex: 3),
                    _buildTitleItem(
                        text: "customer_search_view.nic".tr(), index: 2),
                    _buildTitleItem(
                        text: "customer_search_view.group".tr(), index: 3),
                    _buildTitleItem(
                        text: "customer_search_view.mobile".tr(), index: 4),
                  ],
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customerList?.length ?? 0,
                  itemBuilder: (context, index) =>
                      buildTableRow(index, customerList![index]),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleItem(
      {required String text, required int index, int flex = 1}) {
    final headingStyle = TextStyle(
        fontSize: POSConfig().cartDynamicButtonFontSize.sp,
        fontWeight: FontWeight.bold,
        color: CurrentTheme.primaryLightColor);

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _sortField(index),
        child: Row(
          children: [
            const Spacer(),
            Text(
              text,
              style: headingStyle,
              textAlign: TextAlign.center,
            ),
            if (_sortIndex == index)
              Icon(
                Icons.arrow_downward,
                color: POSConfig().primaryLightColor.toColor(),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // _sortByCode(int columnIndex, bool ascending) {
  //   if (columnIndex == 0) {
  //     if (ascending) {
  //       customerList
  //           ?.sort((a, b) => (a.cMCODE ?? "").compareTo(b.cMCODE ?? ""));
  //     } else {
  //       customerList
  //           ?.sort((a, b) => (b.cMCODE ?? "").compareTo(a.cMCODE ?? ""));
  //     }
  //     setState(() {
  //       _sortIndex = columnIndex;
  //       _sort = !_sort;
  //     });
  //   }
  // }
  void _sortField(int index) {
    if (mounted) {
      _sortIndex = index;
      setState(() {});
    }
  }

  // _sortByName(int columnIndex, bool ascending) {
  //   if (columnIndex == 1) {
  //     if (ascending) {
  //       customerList
  //           ?.sort((a, b) => (a.cMNAME ?? "").compareTo(b.cMNAME ?? ""));
  //     } else {
  //       customerList
  //           ?.sort((a, b) => (b.cMNAME ?? "").compareTo(a.cMNAME ?? ""));
  //     }
  //     setState(() {
  //       _sortIndex = columnIndex;
  //       _sort = !_sort;
  //     });
  //   }
  // }
  //
  // _sortByNIC(int columnIndex, bool ascending) {
  //   if (columnIndex == 2) {
  //     if (ascending) {
  //       customerList?.sort((a, b) => (a.cMNIC ?? "").compareTo(b.cMNIC ?? ""));
  //     } else {
  //       customerList?.sort((a, b) => (b.cMNIC ?? "").compareTo(a.cMNIC ?? ""));
  //     }
  //     setState(() {
  //       _sortIndex = columnIndex;
  //       _sort = !_sort;
  //     });
  //   }
  // }
  //
  // _sortByGroup(int columnIndex, bool ascending) {
  //   if (columnIndex == 3) {
  //     if (ascending) {
  //       customerList
  //           ?.sort((a, b) => (a.cMGROUP ?? "").compareTo(b.cMGROUP ?? ""));
  //     } else {
  //       customerList
  //           ?.sort((a, b) => (b.cMGROUP ?? "").compareTo(a.cMGROUP ?? ""));
  //     }
  //     setState(() {
  //       _sortIndex = columnIndex;
  //       _sort = !_sort;
  //     });
  //   }
  // }
  //
  // _sortByMobile(int columnIndex, bool ascending) {
  //   if (columnIndex == 4) {
  //     if (ascending) {
  //       customerList
  //           ?.sort((a, b) => (a.cMMOBILE ?? "").compareTo(b.cMMOBILE ?? ""));
  //     } else {
  //       customerList
  //           ?.sort((a, b) => (b.cMMOBILE ?? "").compareTo(a.cMMOBILE ?? ""));
  //     }
  //     setState(() {
  //       _sortIndex = columnIndex;
  //       _sort = !_sort;
  //     });
  //   }
  // }

  Widget buildTableRow(int index, CustomerResult customer) {
    bool selected = customer.cMCODE == selectedCustomer?.cMCODE;
    final dataStyle = TextStyle(
        fontSize: POSConfig().cartDynamicButtonFontSize.sp,
        color: CurrentTheme.primaryLightColor);
    return Column(
      children: [
        ListTile(
          selected: selected,
          selectedTileColor: CurrentTheme.primaryColor,
          onTap: () {
            if (mounted)
              setState(() {
                selectedCustomer = customer;
              });
          },
          title: Row(children: [
            Expanded(
                child: Text(
              (customer.cMCODE ?? 'N/A'),
              textAlign: TextAlign.center,
              style: dataStyle,
            )),
            Expanded(
              flex: 3,
              child: Text(
                customer.cMNAME ?? 'N/A',
                style: dataStyle,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
                child: Text(
              customer.cMNIC ?? 'N/A',
              textAlign: TextAlign.center,
              style: dataStyle,
            )),
            Expanded(
                child: Text(
              customer.cMGROUP ?? 'N/A',
              textAlign: TextAlign.center,
              style: dataStyle,
            )),
            Expanded(
                child: Text(
              customer.cMMOBILE ?? 'N/A',
              textAlign: TextAlign.center,
              style: dataStyle,
            )),
          ]),
        ),
        const Divider()
      ],
    );
  }

  Widget buildRHS() {
    // final style = CurrentTheme.subtitle2!.copyWith(color: CurrentTheme.primaryDarkColor);
    String customerName = selectedCustomer?.cMNAME ?? "N/A";
    String customerId = selectedCustomer?.cMCODE ?? "N/A";
    String customerGroup = selectedCustomer?.cMGROUP ?? "N/A";
    bool customerActive = selectedCustomer?.cMACTIVE ?? false;

    // ignore: dead_code
    String activeText = customerActive
        ? "customer_search_view.active"
        : "customer_search_view.inactive";
    // ignore: dead_code
    Color activeColor = customerActive ? Colors.green : Colors.redAccent;

    final idStyle = CurrentTheme.bodyText2;
    final nameStyle =
        CurrentTheme.bodyText1!.copyWith(fontWeight: FontWeight.w600);
    final buttonStyle = CurrentTheme.bodyText2;
    final buttonWidth = 280.w;

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 450.w,
            child: Card(
              color: CurrentTheme.primaryColor,
              child: Padding(
                padding: EdgeInsets.all(15.r),
                child: selectedCustomer == null
                    ? SizedBox(
                        height: 150.h,
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                  width: 150.r,
                                  height: 150.r,
                                  child: CustomerImage(
                                    imagePath: selectedCustomer?.cMPICTURE,
                                  )),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      customerId,
                                      style: idStyle,
                                    ),
                                    Text(
                                      customerName,
                                      style: nameStyle,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          buildCard(
                              customerGroup,
                              buttonStyle!
                                  .copyWith(color: CurrentTheme.primaryColor),
                              CurrentTheme.primaryLightColor!),
                          buildCard(
                              activeText.tr(),
                              buttonStyle.copyWith(color: Colors.white),
                              activeColor),
                        ],
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 25.h,
          ),
          Row(
            children: [
              const Spacer(),
              Container(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    searchCustomer("");
                    searchEditingController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor()),
                  child: Text("customer_search_view.reset_button".tr()),
                ),
              ),
              const Spacer(),
              Container(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedCustomer != null) {
                      //get individual customer data
                      final customer = await CustomerController()
                          .getCustomerByCode(selectedCustomer!.cMCODE!);
                      //validation for external loyalty modules
                      ExtLoyaltyModuleHelper extModules =
                          ExtLoyaltyModuleHelper();
                      bool valid = false;
                      if (extModules.extLoyaltyModuleActive) {
                        EasyLoading.show(status: 'Validating...');
                        valid = (await extModules.validateCustomer(
                              selectedCustomer!.cMMOBILE ?? '',
                            )) ??
                            false;
                        EasyLoading.dismiss();
                      } else {
                        valid = true;
                      }

                      if (valid && selectedCustomer!.cMACTIVE!) {
                        POSLogger(POSLoggerLevel.info,
                            "Selected Customer: ${selectedCustomer!.cMCODE}");
                        customerBloc.changeCurrentCustomer(
                            customer ?? selectedCustomer!);
                        // show customer info in poll display
                        if (POSConfig().enablePollDisplay == 'true') {
                          try {
                            usbSerial.sendToSerialDisplay(
                                '${usbSerial.addSpacesBack((customer?.cMNAME ?? 'UNKNOWN').toUpperCase(), 20)}');
                            usbSerial.sendToSerialDisplay(
                                '${usbSerial.addSpacesBack((customer?.loyaltyGroup ?? 'LOYALTY GROUP: N/A').toUpperCase(), 20)}');
                          } catch (e) {
                            LogWriter()
                                .saveLogsToFile('ERROR_LOG_', [e.toString()]);
                          }
                        }
                        if (POSConfig().dualScreenWebsite != "")
                          DualScreenController()
                              .setCustomer(customer ?? selectedCustomer!);
                        Navigator.pop(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor()),
                  child: Text(
                    "customer_search_view.select".tr(),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            children: [
              const Spacer(),
              Container(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () async {
                    LoyaltySummary? res;
                    bool permission = await hasPermission("A");
                    //ask

                    if (selectedCustomer != null && permission) {
                      EasyLoading.show(status: 'please_wait'.tr());
                      res = await LoyaltyController()
                          .getLoyaltySummary(selectedCustomer?.cMCODE ?? "");
                      EasyLoading.dismiss();

                      await showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (context) {
                          return CustomerProfile(
                            selectedCustomer,
                            loyaltySummary: res,
                          );
                        },
                      );

                      await searchCustomer(searchEditingController.text);
                      final temp = selectedCustomer!;
                      selectedCustomer = customerList?.firstWhere(
                          (element) => element.cMCODE == temp.cMCODE);
                      if (mounted) setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor()),
                  child: Text(
                    "customer_search_view.view".tr(),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () async {
                    if (await hasPermission("C"))
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (context) {
                          return CustomerProfile(null);
                        },
                      );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor()),
                  child: Text(
                    "customer_search_view.create".tr(),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> hasPermission(String code) async {
    final res = await CustomerHelper(context).hasCustomerMasterPermission(code);
    return res;
  }

  Widget buildCard(String text, TextStyle textStyle, Color color) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 200.w,
        child: Card(
          color: color,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.r, horizontal: 5.r),
            child: Center(
                child: Text(
              text,
              style: textStyle,
            )),
          ),
        ),
      ),
    );
  }
}
