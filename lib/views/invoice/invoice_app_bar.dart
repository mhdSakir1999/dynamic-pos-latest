/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/23/21, 12:20 PM
 */

import 'dart:io';

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/customer_controller.dart';
import 'package:checkout/controllers/loyalty_controller.dart';
import 'package:checkout/models/enum/pos_connectivity_status.dart';
import 'package:checkout/models/loyalty/customer_list_result.dart';
import 'package:checkout/models/loyalty/loyalty_summary.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/user_hed.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/views/customer/customer_helper.dart';
import 'package:checkout/views/customer/customer_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supercharged/supercharged.dart';
import 'package:easy_localization/easy_localization.dart';

import '../pos_functions/service_status_view.dart';

/// This is app bar used in invoice screens
class POSInvoiceAppBar extends StatefulWidget {
  final bool showCustomer;

  // if this is not null this will show as invoice no
  final String? overrideInvoiceNo;
  final VoidCallback? onPriceClick;
  final bool hideCustomer;
  final FocusNode customerButtonNode = FocusNode();

  POSInvoiceAppBar(
      {Key? key,
      this.showCustomer = true,
      this.overrideInvoiceNo,
      this.onPriceClick,
      this.hideCustomer = false})
      : super(key: key);

  @override
  _POSInvoiceAppBarState createState() => _POSInvoiceAppBarState();
}

class _POSInvoiceAppBarState extends State<POSInvoiceAppBar> {
  final PageController _controller = PageController();
  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final titleStyle = CurrentTheme.headline6!
        .copyWith(color: CurrentTheme.primaryLightColor, fontSize: 15.sp);

    bool mediumDevice = ScreenUtil().screenWidth < 1200;
    return Row(
      children: [
        !widget.showCustomer
            ? Spacer(
                flex: 2,
              )
            : Expanded(
                flex: 4,
                child: Row(
                  children: <Widget>[
                    Expanded(child: buildCustomer()),
                    SizedBox(
                      width: 5.w,
                    ),
                    StreamBuilder<CartSummaryModel>(
                        stream: cartBloc.cartSummarySnapshot,
                        builder: (context,
                            AsyncSnapshot<CartSummaryModel> snapshot) {
                          String text = '';
                          if (snapshot.hasData) {
                            text = snapshot.data?.priceModeDesc ?? '';
                          }
                          if (text.isEmpty) {
                            text = "app_bar.price_mode".tr();
                          }

                          return Expanded(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 30.w, vertical: 25.h),
                                    backgroundColor: POSConfig()
                                        .primaryDarkGrayColor
                                        .toColor()),
                                onPressed: widget.onPriceClick,
                                child: Text(
                                  text,
                                )),
                          );
                        })
                  ],
                )),
        Container(
          height: POSConfig().topAppBarSize.h,
          width: POSConfig().containerSize.w,
          child: PageView(
            controller: _controller,
            children: [
              StreamBuilder<POSConnectivityStatus>(
                  stream: posConnectivity.connectivityStream,
                  builder:
                      (context, AsyncSnapshot<POSConnectivityStatus> snapshot) {
                    bool status = false;
                    if (snapshot.hasData) {
                      status = snapshot.data == POSConnectivityStatus.Server;
                    }
                    return buildInvoiceInfo(status);
                  }),
              POSAppBar(),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: StreamBuilder<UserHed>(
              stream: userBloc.currentUserStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Text(
                    "UnAuthorized Access",
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                    textAlign: TextAlign.center,
                  );
                return InkWell(
                  onTap: () {
                    final double? page = _controller.page;
                    switch (page?.toInt()) {
                      case 0:
                        _controller.jumpToPage(1);
                        break;
                      case 1:
                        _controller.jumpToPage(0);
                    }
                  },
                  child: Row(
                    children: [
                      SizedBox(width: 60.r, height: 60.r, child: UserImage()),
                      Expanded(
                        child: Text(
                          // 'WWWWWWWWWW',
                          snapshot.data?.uSERHEDUSERCODE ?? "",
                          style: titleStyle,
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ),
        POSClock()
      ],
    );
  }

  Widget buildCustomer() {
    return StreamBuilder(
      stream: customerBloc.currentCustomerStream,
      builder: (context, AsyncSnapshot<CustomerResult?> snapshot) {
        if (!snapshot.hasData)
          return ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.w, vertical: 25.h),
                  backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
              onPressed: (widget.hideCustomer || POSConfig().localMode)
                  ? null
                  : () {
                      CustomerController().showCustomerPicker(context);
                    },
              child: Text(
                "app_bar.select_customer".tr(),
              ));
        else {
          return GestureDetector(
              onTap: widget.hideCustomer
                  ? null
                  : () {
                      CustomerController().showCustomerPicker(context);
                    },
              child: buildUserImage(snapshot.data!));
        }
      },
    );
  }

  Future<bool> hasPermission(String code) async {
    final res = await CustomerHelper(context).hasCustomerMasterPermission(code);
    return res;
  }

  /// editor: [TM.Sakir] 25/09/2023 4:31 PM
  /// new change -- adding a dialog window to clear/view the selected customer in cartView
  Widget buildUserImage(CustomerResult customer) {
    final titleStyle =
        CurrentTheme.headline6!.copyWith(color: CurrentTheme.primaryLightColor);
    final subtitleStyle =
        CurrentTheme.bodyText2!.copyWith(color: CurrentTheme.primaryLightColor);
    bool smallDevice = ScreenUtil().screenWidth < 600;
    return InkWell(
      onTap: () async {
        focusNode.requestFocus();
        showGeneralDialog(
            context: context,
            transitionDuration: const Duration(milliseconds: 200),
            barrierDismissible: true,
            barrierLabel: '',
            transitionBuilder: (context, a, b, _) => RawKeyboardListener(
                  focusNode: focusNode,
                  onKey: (value) async {
                    if (value is RawKeyDownEvent) {
                      if (value.physicalKey == PhysicalKeyboardKey.keyV) {
                        LoyaltySummary? res;
                        bool permission = await hasPermission("A");
                        //ask

                        if (permission) {
                          EasyLoading.show(status: 'please_wait'.tr());
                          res = await LoyaltyController()
                              .getLoyaltySummary(customer.cMCODE ?? "");
                          EasyLoading.dismiss();

                          await showModalBottomSheet(
                            isScrollControlled: true,
                            context: context,
                            builder: (context) {
                              return CustomerProfile(
                                customer,
                                loyaltySummary: res,
                              );
                            },
                          );
                          Navigator.pop(
                              context); //closing the showdialog box at the end
                        }
                      }
                      if (value.physicalKey == PhysicalKeyboardKey.keyN) {
                        Navigator.pop(context);
                      }
                      if (value.physicalKey == PhysicalKeyboardKey.keyY) {
                        Navigator.pop(context);
                        var cartSum = cartBloc.cartSummary;
                        if (cartSum != null) {
                          cartSum.customerCode = '';
                          cartBloc.updateCartSummary(cartSum);
                        }
                        customerBloc.changeCurrentCustomer(null);
                        CustomerController().showCustomerPicker(context);
                      }
                    }
                  },
                  child: Transform.scale(
                    scale: a.value,
                    child: AlertDialog(
                        title: Text('general_dialog.handle_cust'.tr()),
                        content: Text('general_dialog.handle_cust_desc'.tr()),
                        actions: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: POSConfig()
                                      .primaryDarkGrayColor
                                      .toColor()),
                              onPressed: () async {
                                LoyaltySummary? res;
                                bool permission = await hasPermission("A");
                                //ask

                                if (permission) {
                                  EasyLoading.show(status: 'please_wait'.tr());
                                  res = await LoyaltyController()
                                      .getLoyaltySummary(customer.cMCODE ?? "");
                                  EasyLoading.dismiss();

                                  await showModalBottomSheet(
                                    isScrollControlled: true,
                                    context: context,
                                    builder: (context) {
                                      return CustomerProfile(
                                        customer,
                                        loyaltySummary: res,
                                      );
                                    },
                                  );
                                  Navigator.pop(
                                      context); //closing the showdialog box at the end
                                }
                              },
                              child: RichText(
                                  text: TextSpan(text: '', children: [
                                TextSpan(
                                    text: 'general_dialog.view_profile'
                                        .tr()
                                        .substring(0, 1),
                                    style: TextStyle(
                                        decoration: TextDecoration.underline)),
                                TextSpan(
                                    text: 'general_dialog.view_profile'
                                        .tr()
                                        .substring(1))
                              ]))),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: POSConfig()
                                      .primaryDarkGrayColor
                                      .toColor()),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: RichText(
                                  text: TextSpan(text: '', children: [
                                TextSpan(
                                    text: 'general_dialog.no'
                                        .tr()
                                        .substring(0, 1),
                                    style: TextStyle(
                                        decoration: TextDecoration.underline)),
                                TextSpan(
                                    text: 'general_dialog.no'.tr().substring(1))
                              ]))),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: POSConfig()
                                      .primaryDarkGrayColor
                                      .toColor()),
                              onPressed: () {
                                Navigator.pop(context);
                                var cartSum = cartBloc.cartSummary;
                                if (cartSum != null) {
                                  cartSum.customerCode = '';
                                  cartBloc.updateCartSummary(cartSum);
                                }
                                customerBloc.changeCurrentCustomer(null);
                                CustomerController()
                                    .showCustomerPicker(context);
                              },
                              child: RichText(
                                  text: TextSpan(text: '', children: [
                                TextSpan(
                                    text: 'general_dialog.yes'
                                        .tr()
                                        .substring(0, 1),
                                    style: TextStyle(
                                        decoration: TextDecoration.underline)),
                                TextSpan(
                                    text:
                                        'general_dialog.yes'.tr().substring(1))
                              ])))
                        ]),
                  ),
                ),
            pageBuilder: (context, animation, secondaryAnimation) {
              return SizedBox();
            });
      },
      child: smallDevice
          ? Column(
              children: [
                Text(
                  customer.cMNAME ?? "",
                  style: titleStyle,
                ),
                Text(
                  customer.cMCODE ?? "",
                  style: subtitleStyle,
                )
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60.r,
                  height: 60.r,
                  child: CustomerImage(
                    imagePath: customer.cMPICTURE,
                  ),
                ),
                SizedBox(
                  width: 10.r,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.cMNAME ?? "",
                        maxLines: 1,
                        style: titleStyle,
                      ),
                      Text(
                        customer.cMCODE ?? "",
                        style: subtitleStyle,
                      )
                    ],
                  ),
                )
              ],
            ),
    );

    // ListTile(
    //         leading: CustomerImage(imagePath: customer.cMPICTURE,),
    //         title: Text(
    //           customer.cMNAME??"",
    //           style: titleStyle,
    //         ),
    //         subtitle: Text(
    //           customer.cMCODE??"",
    //           style: subtitleStyle,
    //         ),
    //       );
  }

  Widget buildInvoiceInfo(bool serverConnection) {
    final space1 = SizedBox(
      width: 15.w,
    );
    String terminalId = POSConfig().terminalId;
    String location = POSConfig().setupLocationName;
    Color iconColor = CurrentTheme.primaryLightColor!;
    String tooltip = "Online";
    Color terminalColor = Colors.greenAccent;
    if (!serverConnection) {
      terminalColor = Colors.redAccent;
      tooltip = "Local Mode";
    }

    double fontSize = 18.sp;
    return StreamBuilder<CartSummaryModel>(
        stream: cartBloc.cartSummarySnapshot,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();
          String invoiceNo = snapshot.data?.invoiceNo ?? "";

          return Container(
            width: POSConfig().containerSize.w,
            child: Card(
              color: CurrentTheme.primaryColor,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.r),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Spacer(),
                    Tooltip(
                      message: tooltip,
                      child: Icon(
                        FontAwesome5Solid.desktop,
                        color: terminalColor,
                      ),
                    ),
                    space1,
                    GestureDetector(
                      onTap: () => _checkServerStatus(context),
                      child: Tooltip(
                        message: "Terminal ID",
                        child: Text(
                          terminalId,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: fontSize),
                        ),
                      ),
                    ),
                    Spacer(),
                    Icon(
                      FontAwesome5.clipboard,
                      color: iconColor,
                    ),
                    space1,
                    Tooltip(
                      message: "Invoice Number",
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: invoiceNo));
                        },
                        child: Text(
                          widget.overrideInvoiceNo ?? invoiceNo,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: fontSize),
                        ),
                      ),
                    ),
                    Spacer(),
                    Icon(
                      FontAwesome5Solid.map_marker_alt,
                      color: iconColor,
                    ),
                    space1,
                    Tooltip(
                      message: "Location",
                      child: Text(
                        location,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: fontSize),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () {
                        if (Platform.isWindows) {
                          Process.run('calc.exe', []);
                        } else {
                          throw Exception(
                              'This function only works on Windows.');
                        }
                      },
                      icon: Icon(
                        FontAwesome.calculator,
                      ),
                      iconSize: 30.r,
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Future<void> _checkServerStatus(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: ServiceStatusView(),
        );
      },
    );
  }
}
