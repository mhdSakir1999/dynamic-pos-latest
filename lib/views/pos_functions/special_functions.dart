/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/27/21, 12:49 PM
 */
import 'package:checkout/components/components.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/controllers/promotion_controller.dart';
import 'package:checkout/models/enum/special_function_config.dart';
import 'package:checkout/models/pos/gift_voucher_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:supercharged/supercharged.dart';

import '../../bloc/user_bloc.dart';
import '../../bloc/utility_bill_category_block.dart';
import '../../controllers/gift_voucher_controller.dart';
import '../../controllers/invoice_controller.dart';
import '../../controllers/keyboard_controller.dart';
import '../../controllers/master_download_controller.dart';
import '../../controllers/pos_alerts/pos_error_alert.dart';
import '../../controllers/special_permission_handler.dart';
import '../../models/pos/permission_code.dart';

/// This view is used to enter the opening float value
class SpecialFunctions extends StatefulWidget {
  static const routeName = "special_functions";
  @override
  _SpecialFunctionsState createState() => _SpecialFunctionsState();
}

class _SpecialFunctionsState extends State<SpecialFunctions> {
  TextEditingController voucherFromController = TextEditingController();
  TextEditingController voucherToController = TextEditingController();

  List<GiftVoucher> giftVouchersList = [];
  bool validated = false;
  List voucherDetailsList = [];

  StateSetter? _setState;

  // backup master tables
  Future downloadAndSyncMaster() async {
    EasyLoading.show(status: 'please_wait'.tr(), dismissOnTap: true);
    var result = await MasterDownloadController().downloadAndSyncMaster();
    if (result != null) {
      EasyLoading.dismiss();
      EasyLoading.showToast(result['message']);
    }
  }

  // Validate vouchers
  Future validateGiftVouchers(String startNumber, String endNumber) async {
    EasyLoading.show(status: 'please_wait'.tr(), dismissOnTap: true);
    var result = await GiftVoucherController()
        .validateGiftVouchersList(startNumber, endNumber);
    if (result != null) {
      EasyLoading.dismiss();
      if (result['validation_status'] == 0) {
        String errorMsg = 'special_functions.invalid_voucher_found'.tr();
        List invalidVoucherList = result['vouchers'];
        invalidVoucherList.forEach((element) {
          errorMsg += element['VoucherNo'] + ', ';
        });

        await errorAlert(errorMsg);
      } else {
        _setState!(() {
          result['vouchers'].forEach((element) {
            GiftVoucher giftVoucher = GiftVoucher.fromJson(element);
            giftVouchersList.add(giftVoucher);
          });
          voucherDetailsList = result['vouchers_details'];
          validated = true;
        });
      }
    }
  }

  // Upload local bill data to server
  Future uploadBillData() async {
    EasyLoading.show(status: 'please_wait'.tr(), dismissOnTap: true);
    var result = await InvoiceController().uploadBillData();
    if (result != null) {
      EasyLoading.dismiss();
      EasyLoading.showToast(result['message']);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    voucherFromController.dispose();
    voucherToController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    utilityBillCategoryBloc.getUtilityBillCategories();
    final containerWidth = POSConfig().containerSize.w;
    List functionList = SpecialFunctionConfig().spectionFunctionList;
    return POSBackground(
        child: Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: containerWidth,
            child: Column(
              children: [
                SizedBox(
                  height: POSConfig().topMargin.h,
                ),
                POSAppBar(),
                SizedBox(
                  height: 8.h,
                ),
                Container(
                  width: containerWidth,
                  child: Row(
                    children: [
                      Expanded(
                          child: UserCard(
                        text: "",
                        shift: true,
                      )),
                      POSClock(),
                    ],
                  ),
                ),
                SizedBox(
                  height: 8.h,
                ),
                specialFuctionElementTitle(
                    "special_functions.select_special_function".tr()),
                Column(
                  children: functionList.map<Widget>((e) {
                    return (
                        // Call Key Distributor Method With Single Dimension Array
                        specialFuctionElement(e));
                  }).toList(),
                ),
                Column(
                  children: [
                    SizedBox(
                      height: 10.h,
                    ),
                    Container(
                      width: containerWidth,
                      child: ElevatedButton(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Text(
                              "special_functions.download_and_sync_data".tr()),
                        ),
                        onPressed: () {
                          downloadAndSyncMaster();
                        },
                      ),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Container(
                      width: containerWidth,
                      child: ElevatedButton(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child:
                              Text("special_functions.upload_bill_data".tr()),
                        ),
                        onPressed: () {
                          uploadBillData();
                        },
                      ),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Container(
                      width: containerWidth,
                      child: ElevatedButton(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Text("special_functions.voucher_bulk".tr()),
                        ),
                        onPressed: () async {
                          String user =
                              userBloc.currentUser?.uSERHEDUSERCODE ?? "";

                          String refCode = 'bulk_voucher';
                          bool hasPermission = false;
                          hasPermission =
                              SpecialPermissionHandler(context: context)
                                  .hasPermission(
                                      permissionCode:
                                          PermissionCode.giftVoucherSales,
                                      accessType: "A",
                                      refCode: refCode);

                          //if user doesnt have the permission
                          if (!hasPermission) {
                            final res =
                                await SpecialPermissionHandler(context: context)
                                    .askForPermission(
                                        permissionCode:
                                            PermissionCode.giftVoucherSales,
                                        accessType: "A",
                                        refCode: refCode);
                            hasPermission = res.success;
                            user = res.user;
                          }
                          if (!hasPermission) {
                            return;
                          }
                          await voucherBulkPopup();
                        },
                      ),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Container(
                      width: containerWidth,
                      child: ElevatedButton(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Text('tool_tip.promo_refresh'.tr()),
                        ),
                        onPressed: () async {
                          EasyLoading.show(status: 'please_wait'.tr());
                          var res = await PromotionController(context)
                              .getPromotions();
                          EasyLoading.dismiss();
                          res?.success == true
                              ? EasyLoading.showSuccess(
                                  'invoice.promo_loaded'.tr())
                              : EasyLoading.showError(
                                  'No new promotions available');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    ));
  }

  /* Voucher bulk Dialog */
  /* By Dinuka 2022/08/05 */
  Future<void> voucherBulkPopup() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          _setState = setState;
          return AlertDialog(
            scrollable: true,
            title: Text('special_functions.voucher_bulk'.tr()),
            content: Container(
              width: ScreenUtil().screenWidth * 0.30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextField(
                    readOnly: validated ? true : false,
                    controller: voucherFromController,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        filled: true,
                        alignLabelWithHint: true,
                        hintText: 'special_functions.voucher_bulk_from'.tr()),
                    onTap: () {
                      if (!validated && mounted)
                        setState(() {
                          KeyBoardController().dismiss();
                          KeyBoardController().showBottomDPKeyBoard(
                              voucherFromController, onEnter: () {
                            KeyBoardController().dismiss();
                          });
                        });
                    },
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  TextField(
                    readOnly: validated ? true : false,
                    controller: voucherToController,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        filled: true,
                        alignLabelWithHint: true,
                        hintText: 'special_functions.voucher_bulk_to'.tr()),
                    onTap: () {
                      if (!validated && mounted)
                        setState(() {
                          KeyBoardController().dismiss();
                          KeyBoardController().showBottomDPKeyBoard(
                              voucherToController, onEnter: () {
                            KeyBoardController().dismiss();
                          });
                        });
                    },
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  if (voucherDetailsList.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 90.w,
                              child: Text('Value',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      decoration: TextDecoration.underline)),
                            ),
                            Text('Count',
                                style: TextStyle(
                                    decoration: TextDecoration.underline))
                          ],
                        ),
                        for (var item in voucherDetailsList)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 90.w,
                                    child: Text(
                                      item['VoucherValue'],
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                  Text(item['VoucherCount'])
                                ],
                              ),
                            ],
                          )
                      ],
                    )
                  ]
                ],
              ),
            ),
            actions: [
              if (validated)
                AlertDialogButton(
                    onPressed: () async {
                      setState(() {
                        voucherDetailsList.clear();
                        validated = false;
                        giftVouchersList.clear();
                      });
                    },
                    text: 'special_functions.voucher_reset'.tr()),
              AlertDialogButton(
                  onPressed: () async {
                    if (!validated) {
                      if (voucherFromController.text.isNotEmpty &&
                          voucherToController.text.isNotEmpty) {
                        String startNumber = voucherFromController.text;
                        String endNumber = voucherToController.text;

                        if ((startNumber == endNumber) ||
                            (int.parse(startNumber) > int.parse(endNumber))) {
                          await errorAlert(
                              'special_functions.invalid_voucher_number'.tr());
                        } else {
                          await validateGiftVouchers(startNumber, endNumber);
                        }
                      }
                    } else {
                      for (var element in giftVouchersList) {
                        await POSPriceCalculator()
                            .addGv(element, 1, context, permission: false);
                      }
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                  text: (voucherDetailsList.isNotEmpty)
                      ? 'special_functions.okay'.tr()
                      : 'special_functions.continue_button'.tr())
            ],
          );
        });
      },
    ).then((value) {
      voucherFromController.clear();
      voucherToController.clear();
      voucherDetailsList.clear();
      validated = false;
      giftVouchersList.clear();
    });
  }

  /* Error Alert */
  /* by dinuka 2022/08/09 */
  Future<void> errorAlert(String erroMsg) async {
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => POSErrorAlert(
                title: "special_functions.voucher_error_title".tr(),
                subtitle: erroMsg,
                subtitleAlign: TextAlign.start,
                extraWidth: true,
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            POSConfig().primaryDarkGrayColor.toColor()),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "special_functions.okay".tr(),
                      style: Theme.of(context).dialogTheme.contentTextStyle,
                    ),
                  )
                ]));
  }

  Column specialFuctionElement(String text) {
    final containerWidth = POSConfig().containerSize.w;
    return Column(
      children: [
        SizedBox(
          height: 10.h,
        ),
        Container(
          width: containerWidth,
          child: ElevatedButton(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Text(text.tr()),
            ),
            onPressed: () {
              Navigator.pushNamed(context, text);
            },
          ),
        ),
        SizedBox(
          height: 10.h,
        ),
      ],
    );
  }

  Container specialFuctionElementTitle(text) {
    final containerWidth = POSConfig().containerSize.w;
    return Container(
      width: containerWidth,
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              SizedBox(
                width: 20.r,
              ),
              GoBackIconButton(),
              Spacer(),
              Text(
                text,
                style: CurrentTheme.headline6!
                    .copyWith(color: CurrentTheme.primaryColor),
                textAlign: TextAlign.center,
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
