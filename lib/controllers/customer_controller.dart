/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/12/21, 6:10 PM
 */

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_alerts/pos_error_alert.dart';
import 'package:checkout/controllers/usb_serial_controller.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/loyalty/customer_list_result.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http_parser/http_parser.dart';
import 'package:lottie/lottie.dart';

import '../bloc/cart_bloc.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_coupons_bloc.dart';
import '../components/ext_loyalty/ext_module_helper.dart';
import '../components/widgets/poskeyboard.dart';
import '../models/loyalty/customer_coupons_result.dart';
import '../models/loyalty/form_validation_result.dart';
import '../models/pos/customer_bundle.dart';
import '../models/pos/customer_promotion_result.dart';
import '../views/customer/customer_search_view.dart';
import 'activation/activation_controller.dart';

class CustomerController {
  Future<String?> createOrUpdateCustomer(
      Map<String, dynamic> data, bool update) async {
    data["update"] = update ? 1 : 0;
    print(data.toString());
    final res = await LoyaltyApiClient.call(
      "customers",
      update ? ApiMethod.PUT : ApiMethod.POST,
      data: data,
      successCode: update ? 200 : 200,
    );

    if (res != null && res.data != null)
      return res.data["code"]?.toString();
    else
      return null;
  }

  Future<bool> updateCustomerImage(String code, Uint8List image) async {
    final file = MultipartFile.fromBytes(image,
        filename: "text.jpg", contentType: MediaType('image', 'jpg'));
    FormData data = FormData.fromMap({
      "code": code,
      "user": userBloc.currentUser?.uSERHEDUSERCODE,
      'image': file,
      'id': POSConfig().setup?.clientLicense
    });
    final res = await LoyaltyApiClient.call(
      "customers/picture",
      ApiMethod.PUT,
      formData: data,
      successCode: 200,
    );
    if (res != null && res.data != null) {
      return res.data["success"]?.toString().parseBool() ?? false;
    } else
      return false;
  }

  Future<CustomerListResult?> searchCustomer(String keyword) async {
    final res = await LoyaltyApiClient.call(
        "customers/key=${keyword.isEmpty ? " " : keyword}", ApiMethod.GET,
        successCode: 200, recallOutlet: true);
    if (res != null && res.data != null)
      return CustomerListResult.fromJson(res.data);
    else
      return null;
  }

  Future<CustomerResult?> getCustomerByCode(String code) async {
    final res = await LoyaltyApiClient.call("customers/$code", ApiMethod.GET,
        successCode: 200, recallOutlet: true);
    if (res?.statusCode != 200) return null;
    if (res != null && res.data != null)
      return CustomerResult.fromJson(res.data["customer"]);
    else
      return null;
  }

  /* get customer available coupons by customer code*/
  /* by dinuka 2022/08/17 */
  Future<CustomerCouponsResult?> getAvailableCoupons(
      String customerCode) async {
    final res = await LoyaltyApiClient.call(
        "customers/coupons/$customerCode", ApiMethod.GET,
        successCode: 200);
    if (res?.statusCode != 200) return null;
    if (res != null && res.data != null)
      return CustomerCouponsResult.fromJson(res.data);
    else
      return null;
  }

  Future<String?> generateCustomerCode() async {
    final res = await LoyaltyApiClient.call(
      "customers/id",
      ApiMethod.GET,
      successCode: 200,
    );
    return res?.data['code'];
  }

  Future<FormValidationResult?> getValidationResult() async {
    final res = await LoyaltyApiClient.call(
        "customers/validation/${PermissionCode.customerMaster}", ApiMethod.GET,
        successCode: 200);
    if (res?.statusCode != 200) return null;
    if (res != null && res.data != null)
      return FormValidationResult.fromJson(res.data);
    else
      return null;
  }

  /// get customer bundles
  Future<CustomerBundleResult?> getCustomerBundles(String code) async {
    final response =
        await ApiClient.call('customer/bundles/$code', ApiMethod.GET);
    if (response?.statusCode == 200 && response?.data != null) {
      return CustomerBundleResult.fromJson(response!.data);
    }
    return null;
  }

  /// get customer bundles
  Future<CustomerPromotionResult?> getCustomerPromotion(String code) async {
    final response =
        await LoyaltyApiClient.call('customers/promotion/$code', ApiMethod.GET);
    if (response?.statusCode == 200 && response?.data != null) {
      return CustomerPromotionResult.fromJson(response!.data);
    }
    return null;
  }

  TextEditingController _customerCodeEditingController =
      TextEditingController();

  Future<void> showCustomerPicker(BuildContext context) async {
    if (POSConfig().clientLicense?.lCMYREWARDS != true || POSConfig().expired) {
      ActivationController().showModuleBuy(context, "myRewards");
      return;
    }
    if (cartBloc.cartSummary?.editable != true) {
      EasyLoading.showError('backend_invoice_view.item_add_error'.tr());
      return;
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: SizedBox(
            width: 520.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                    )),
                SizedBox(
                  height: 10.h,
                ),
                Tooltip(
                  message: 'customer_search_view.hint'.tr(),
                  child: TextField(
                    onEditingComplete: () => _getCustomerByCode(context),
                    controller: _customerCodeEditingController,
                    autofocus: true,
                    decoration: InputDecoration(
                        hintStyle: CurrentTheme.headline6!
                            .copyWith(color: CurrentTheme.primaryDarkColor),
                        hintText: 'customer_search_view.number'.tr(),
                        filled: true),
                  ),
                ),
                SizedBox(
                  height: 10.h,
                ),
                POSKeyBoard(
                  color: Colors.transparent,
                  onPressed: () {
                    //_customerCodeEditingController.clear();
                    if (_customerCodeEditingController.text.length != 0) {
                      _customerCodeEditingController.text =
                          _customerCodeEditingController.text.substring(0,
                              _customerCodeEditingController.text.length - 1);
                    }
                  },
                  clearButton: true,
                  isInvoiceScreen: false,
                  disableArithmetic: true,
                  onEnter: () => _getCustomerByCode(context),
                  controller: _customerCodeEditingController,
                ),
                SizedBox(
                  height: 10.h,
                ),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) {
                              return CustomerSearchView();
                            },
                          );
                        },
                        child: Text('customer_search_view.search'.tr())))
              ],
            ),
          ),
        );
      },
    );
    _customerCodeEditingController.clear();
  }

  Future<void> _getCustomerByCode(BuildContext context) async {
    EasyLoading.show(status: 'please_wait'.tr());
    final res = await CustomerController()
        .getCustomerByCode(_customerCodeEditingController.text);
    EasyLoading.dismiss();
    if (res == null) {
      EasyLoading.showError('customer_search_view.notfound'.tr());
    } else if (res.cMACTIVE != true) {
      EasyLoading.showError('Inactive customer');
    } else {
      //get individual customer data
      ExtLoyaltyModuleHelper extModules = ExtLoyaltyModuleHelper();
      bool valid = false;
      if (extModules.extLoyaltyModuleActive) {
        EasyLoading.show(status: 'Validating...');
        valid = (await extModules.validateCustomer(
              res.cMMOBILE ?? '',
            )) ??
            false;
        EasyLoading.dismiss();
      } else {
        valid = true;
      }
      if (valid) {
        customerBloc.changeCurrentCustomer(res, update: true);

        // show customer info in poll display
        if (POSConfig().enablePollDisplay == 'true') {
          try {
            usbSerial.sendToSerialDisplay(
                '${usbSerial.addSpacesBack((res.cMNAME ?? 'UNKNOWN').toUpperCase(), 20)}');
            usbSerial.sendToSerialDisplay(
                '${usbSerial.addSpacesBack((res.loyaltyGroup ?? 'LOYALTY GROUP: N/A').toUpperCase(), 20)}');
          } catch (e) {
            LogWriter().saveLogsToFile('ERROR_LOG_', [e.toString()]);
          }
        }
        //new change -- notify to dual display when customer is entered in cart
        if (POSConfig().dualScreenWebsite != "")
          DualScreenController().setCustomer(res);
        //get customer bundles

        Navigator.pop(context);

        /* show coupons if available for the customer */
        /* by dinuka 2022/08/17 */
        // await getAvailableCoupons();
        await customerCouponBloc.getAvailableCoupons();
        var availableCouponsResult = customerCouponBloc.availableCoupons;
        var couponsList = customerCouponBloc.availableCoupons?.couponsList;
        if (availableCouponsResult != null && couponsList!.isNotEmpty) {
          await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  scrollable: true,
                  content: Column(
                    children: [
                      SizedBox(
                        height: 150.h,
                        child: OverflowBox(
                          minHeight: 250.h,
                          maxHeight: 250.h,
                          child: Lottie.asset('assets/lottie/coupon.json',
                              fit: BoxFit.fill),
                        ),
                      ),
                      Text(
                        'customer_coupons_popup_view.title'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      StreamBuilder(
                          stream: customerCouponBloc.allCouponsList,
                          builder: (context,
                              AsyncSnapshot<CustomerCouponsResult?> snapshot) {
                            if (!snapshot.hasData) return Container();
                            List<Coupons> coupons =
                                snapshot.data?.couponsList ?? [];
                            return DataTable(showBottomBorder: false, columns: [
                              DataColumn(
                                  label: Text(
                                'customer_coupons_popup_view.voucher_no'.tr(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                              DataColumn(
                                  label: Text(
                                'customer_coupons_popup_view.amount'.tr(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                              DataColumn(
                                  label: Text(
                                'customer_coupons_popup_view.expire'.tr(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                            ], rows: [
                              for (var item in coupons) ...[
                                DataRow(cells: [
                                  DataCell(Text(item.vCVOUCHERNO!)),
                                  DataCell(Text(item.vCVOUCHERVALUE!)),
                                  DataCell(Text(DateFormat("yyyy-MM-dd")
                                      .format(item.vCVALIDUNTIL!)))
                                ]),
                              ]
                            ]);
                          }),
                      SizedBox(
                        height: 10.h,
                      ),
                      AlertDialogButton(
                          onPressed: () => Navigator.pop(context),
                          text: 'customer_coupons_popup_view.noted'.tr())
                    ],
                  ),
                );
              });
        }
      }
    }

    /* check customer has vouchers to redeem */
    /* by dinuka 2022/08/17 */
    Future<void> getAvailableCoupons() async {
      String code = customerBloc.currentCustomer?.cMCODE ?? '0';
      EasyLoading.show(status: 'please_wait'.tr(), dismissOnTap: true);
      final res = await CustomerController().getAvailableCoupons(code);
      EasyLoading.dismiss();
      if (res != null && res.couponsList != null) {
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                scrollable: true,
                content: Column(
                  children: [
                    SizedBox(
                      height: 150.h,
                      child: OverflowBox(
                        minHeight: 250.h,
                        maxHeight: 250.h,
                        child: Lottie.network(
                          'https://assets6.lottiefiles.com/packages/lf20_n0jeixzn.json',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Text(
                      'customer_coupons_popup_view.title'.tr(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    DataTable(showBottomBorder: false, columns: [
                      DataColumn(
                          label: Text(
                        'customer_coupons_popup_view.voucher_no'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                      DataColumn(
                          label: Text(
                        'customer_coupons_popup_view.amount'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                      DataColumn(
                          label: Text(
                        'customer_coupons_popup_view.expire'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                    ], rows: [
                      for (var item in res.couponsList!) ...[
                        DataRow(cells: [
                          DataCell(Text(item.vCVOUCHERNO!)),
                          DataCell(Text(item.vCVOUCHERVALUE!)),
                          DataCell(Text(DateFormat("yyyy-MM-dd")
                              .format(item.vCVALIDUNTIL!)))
                        ]),
                      ]
                    ]),
                    SizedBox(
                      height: 10.h,
                    ),
                    AlertDialogButton(
                        onPressed: () => Navigator.pop(context),
                        text: 'customer_coupons_popup_view.noted'.tr())
                  ],
                ),
              );
            });
      }
    }

    Widget buildUserImage(CustomerResult customer) {
      final titleStyle = CurrentTheme.headline6!
          .copyWith(color: CurrentTheme.primaryLightColor);
      final subtitleStyle = CurrentTheme.bodyText2!
          .copyWith(color: CurrentTheme.primaryLightColor);
      bool smallDevice = ScreenUtil().screenWidth < 600;
      return smallDevice
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
  }
}
