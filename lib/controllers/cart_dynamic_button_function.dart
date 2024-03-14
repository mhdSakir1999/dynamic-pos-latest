/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/27/21, 9:40 AM
 */

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/cash_in_out_controller.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/local_storage_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_error_alert.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/controllers/pos_manual_print_controller.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/controllers/product_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/invoice/bill_cancel_view.dart';
import 'package:checkout/views/invoice/cash_in_out_view.dart';
import 'package:checkout/views/invoice/discount_entry_view.dart';
import 'package:checkout/views/invoice/product_search_view.dart';
import 'package:checkout/views/invoice/recall_view.dart';
import 'package:checkout/views/invoice/reprint_view.dart';
import 'package:checkout/views/invoice/weighted_item_view.dart';
import 'package:checkout/views/pos_functions/special_functions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'auth_controller.dart';
import 'package:supercharged/supercharged.dart';

/// This class will return the function dynamic function for the relevant button
class CartDynamicButtonFunction {
  BuildContext? context;
  final String functionName;
  final TextEditingController controller;

  CartDynamicButtonFunction(this.functionName, this.controller);

  void _specialFunction() {
    String routeName = SpecialFunctions.routeName;
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    }
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Navigate to $routeName"));
    // Navigator.pushNamed(context!, routeName);
    showModalBottomSheet(
      useRootNavigator: true,
      isScrollControlled: true,
      context: context!,
      builder: (context) {
        return SpecialFunctions();
      },
    );
  }

  void searchFunction() async {
    String routeName = ProductSearchView.routeName;
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    }

    bool hasPermission = false;
    hasPermission = SpecialPermissionHandler(context: context!).hasPermission(
        permissionCode: PermissionCode.productSearch, accessType: "A");

    //if user doesnt have the permission
    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: context!)
          .askForPermission(
              permissionCode: PermissionCode.productSearch,
              accessType: "A",
              refCode: cartBloc.cartSummary?.invoiceNo ?? "");
      hasPermission = res.success;
    }

    // still havent permission
    if (!hasPermission) {
      return;
    }

    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Navigate to $routeName"));
    // Navigator.pushNamed(context!, routeName);
    showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      context: context!,
      builder: (context) {
        return ProductSearchView();
      },
    );
  }

  void _lineDiscFunction(CartModel cart) => _navigateToLineDiscount(cart, true);

  void _lineDiscAmtFunction(CartModel cart) =>
      _navigateToLineDiscount(cart, false);

  void _navigateToLineDiscount(CartModel cart, bool discountPercentage) async {
    String routeName = DiscountEntryView.routeName;
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    }

    if (cart.itemVoid == true || cart.noDisc) {
      return;
    }
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Navigate to $routeName"));
    // if(!DiscountHandler().canApplyLineDiscount(cart)){
    //   POSLoggerController.addNewLog(
    //       POSLogger(POSLoggerLevel.error, "Discount already applied"));
    //   return;
    // }

    //if it is already discounted (linewise) preventing the same discount apply
    if (discountPercentage && cart.discPer != 0) {
      EasyLoading.showError('line_discount_entry_view.already_added'
          .tr(namedArgs: {'type': 'Percentage-Wise'}));
      return;
    }
    if (discountPercentage && cart.discAmt != 0) {
      EasyLoading.showError('line_discount_entry_view.already_added'
          .tr(namedArgs: {'type': 'Amount-Wise'}));
      return;
    }
    showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      context: context!,
      builder: (context) {
        return DiscountEntryView(
          cartItem: cart,
          discountPercentage: discountPercentage,
        );
      },
    );
  }

  /// change by [TM.Sakir] on 2023-11-21 09:34AM
  /// put a double comparison(proCode & stockCode) because there are varients for the same product code. In that scenario their proCode are same but stock codes are different.

  Future repeatPlU(CartModel cart) async {
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    }
    final productRes =
        await ProductController().searchProductByBarcode(cart.proCode, 1);

    if (productRes?.product != null && productRes?.product?.length != 0) {
      var actualProduct = productRes?.product!.firstWhere((element) =>
          element.pLUCODE == cart.proCode &&
          element.pLUSTOCKCODE == cart.stockCode);
      POSPriceCalculator().addItemToCart(
        actualProduct!, //productRes!.product!.first,
        1.0,
        context!,
        productRes!.prices,
        productRes.proPrices,
        productRes.proTax,
        secondApiCall: false,
      );
    }
    return;
    // }
  }

  void _backSpace() {
    var text = controller.text;
    var len = text.length;
    if (text.isNotEmpty && len > 0) {
      text = text.substring(0, len - 1);
    }
    controller.text = text;
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));
  }

  void _showErrorAlert(String key, {Map<String, String>? namedArgs}) {
    showDialog(
      context: context!,
      builder: (context) => POSErrorAlert(
          title: "$key.title".tr(namedArgs: namedArgs),
          subtitle: "$key.subtitle".tr(namedArgs: namedArgs),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "$key.okay".tr(),
                style: Theme.of(context).dialogTheme.contentTextStyle,
              ),
            )
          ]),
    );
  }

  Future _holdBill() async {
    /// new change by [TM.Sakir] -- initiating new invoice when holding a invoice
    LocalStorageController _localStorageController = LocalStorageController();
    String? currentSummaryInv = cartBloc.cartSummary?.invoiceNo;

    final cartLen = cartBloc.currentCart?.length ?? 0;
    if (cartLen == 0) {
      if (context == null) {
        POSLoggerController.addNewLog(POSLogger(
            POSLoggerLevel.error, "Field 'context' has not been initialized."));
        return;
      } else {
        _showErrorAlert("hold_cart_empty");
      }
    } else {
      bool hasPermission = false;
      hasPermission = SpecialPermissionHandler(context: context!).hasPermission(
          permissionCode: PermissionCode.billHold, accessType: "A");

      //if user doesnt have the permission
      if (!hasPermission) {
        final res = await SpecialPermissionHandler(context: context!)
            .askForPermission(
                permissionCode: PermissionCode.billHold,
                accessType: "A",
                refCode: cartBloc.cartSummary?.invoiceNo ?? '');
        hasPermission = res.success;
      }

      if (hasPermission) {
        EasyLoading.show(status: 'please_wait'.tr());
        var res = await InvoiceController()
            .billClose(invoiced: false, context: context!);

        // /// new change by [TM.Sakir] -- initializing new invoice when holding a invoice ----------------------------------------------
        // /// comparing the summaryInvNumber(contains hold bill) with actual inv number from local storage.
        // /// if summaryInv > inv: we are holding the invoice for the first time. so we have to initiate next inv to do invoicing.
        // /// else: we are holding a invoice which is recalled (holded before some invoices). so dont do anything
        // String? invNo = await _localStorageController.getInvoice();

        // if (res.success &&
        //     (int.parse(currentSummaryInv ?? '0') > int.parse(invNo ?? '0'))) {
        //   try {
        //     InvoiceController().setInvoiceNo(currentSummaryInv!);
        //   } catch (e) {
        //     print(e);
        //   }
        // }
        // //--------------------------------------------------------------------
        await cartBloc.resetCart();
        EasyLoading.dismiss();
      }
    }
  }

  Future _billCancellation() async {
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    } else {
      final cartLen = cartBloc.currentCart?.length ?? 0;
      if (cartLen == 0) {
        EasyLoading.show(status: 'please_wait'.tr());
        final res = await InvoiceController().getTodayInvoices();
        EasyLoading.dismiss();

        showModalBottomSheet(
          isScrollControlled: true,
          useRootNavigator: true,
          context: context!,
          builder: (context) {
            return BillCancellationView(
              headers: res,
            );
          },
        );
        // Navigator.push(
        //     context!,
        //     MaterialPageRoute(
        //       builder: (context) => BillCancellationView(headers: res),
        //     ));
      } else {
        _showErrorAlert("hold_cart_call_error");
      }
    }
  }

  Future _recall() async {
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    } else {
      final cartLen = cartBloc.currentCart?.length ?? 0;
      if (cartLen == 0) {
        bool hasPermission = false;
        hasPermission = SpecialPermissionHandler(context: context!)
            .hasPermission(
                permissionCode: PermissionCode.billRecall, accessType: "A");

        //if user doesnt have the permission
        if (!hasPermission) {
          final res = await SpecialPermissionHandler(context: context!)
              .askForPermission(
                  permissionCode: PermissionCode.billRecall,
                  accessType: "A",
                  refCode: cartBloc.cartSummary?.invoiceNo ?? '');
          hasPermission = res.success;
        }

        if (hasPermission) {
          EasyLoading.show(status: 'please_wait'.tr());
          final res = await InvoiceController().getHoldHeaders();
          EasyLoading.dismiss();

          showModalBottomSheet(
            isScrollControlled: true,
            useRootNavigator: true,
            context: context!,
            builder: (context) {
              return RecallView(
                headers: res,
              );
            },
          );
        }
      } else {
        _showErrorAlert("hold_cart_call_error");
      }
    }
  }

  Future _reprint() async {
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    } else {
      final cartLen = cartBloc.currentCart?.length ?? 0;
      if (cartLen == 0) {
        EasyLoading.show(status: 'please_wait'.tr());
        final res = await InvoiceController().getTodayInvoices();
        EasyLoading.dismiss();
        //get the inv modes only
        showModalBottomSheet(
          isScrollControlled: true,
          useRootNavigator: true,
          context: context!,
          builder: (context) {
            return ReprintView(
              headers: res
                  .where((element) =>
                      element.invheDMODE == "INV" &&
                      element.invheDINVOICED == true)
                  .toList(),
            );
          },
        );
      }
    }
  }

  Future _netDisc() async {
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    }
    // bool hasPermission = false;
    // hasPermission = SpecialPermissionHandler(context: context!).hasPermission(
    //     permissionCode: PermissionCode.invoiceDiscount, accessType: "A");
    //
    // //if user doesnt have the permission
    // if (!hasPermission) {
    //   final res = await SpecialPermissionHandler(context: context!)
    //       .askForPermission(
    //           permissionCode: PermissionCode.invoiceDiscount,
    //           accessType: "A",
    //           refCode: '');
    //   hasPermission = res.success;
    // }

    // if (hasPermission) {
    showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      context: context!,
      builder: (context) {
        return DiscountEntryView(
          discountPercentage: true,
        );
      },
    );
    // }
  }

  void cashInOutView(bool cashIn) async {
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    }

    bool hasPermission = false;
    String code = cashIn ? PermissionCode.cashIn : PermissionCode.cashOut;
    hasPermission = SpecialPermissionHandler(context: context!)
        .hasPermission(permissionCode: code, accessType: "A");
    String invoice = await CashInOutController().getInvoiceNo(cashIn);

    //if user doesnt have the permission
    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: context!)
          .askForPermission(
              permissionCode: code, accessType: "A", refCode: invoice);
      hasPermission = res.success;
    }
    //still permission denied then stop the function execution
    if (!hasPermission) return;

    EasyLoading.show(status: 'please_wait'.tr());

    //get types
    final cashInRes = await CashInOutController().getCashInOutTypes(cashIn);
    EasyLoading.dismiss();
    if (invoice.isEmpty || cashInRes == null || cashInRes.success == false)
      return;
    showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      context: context!,
      builder: (context) {
        return CashInOutView(
          cashIn: cashIn,
          invoiceNo: invoice,
          cashInOutResult: cashInRes,
        );
      },
    );
  }

  void weightedItem() async {
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    } else {
      showModalBottomSheet(
        isScrollControlled: true,
        useRootNavigator: true,
        context: context!,
        builder: (context) {
          return WeightedItemView();
        },
      );
    }
  }

  Future handleFunction({CartModel? cart, CartModel? lastItem}) async {
    switch (functionName) {
      case "special_function":
        _specialFunction();
        break;
      case "search":
        searchFunction();
        break;
      case "net_disc":
        _netDisc();
        break;
      case "line_disc_per":
        if (cart != null)
          _lineDiscFunction(cart);
        else
          POSLoggerController.addNewLog(
              POSLogger(POSLoggerLevel.info, "Cart Model is empty"));
        break;
      case "line_disc_amt":
        if (cart != null)
          _lineDiscAmtFunction(cart);
        else
          POSLoggerController.addNewLog(
              POSLogger(POSLoggerLevel.info, "Cart Model is empty"));
        break;
      case "repeat_plu":
        if (lastItem != null)
          await repeatPlU(lastItem);
        else
          POSLoggerController.addNewLog(
              POSLogger(POSLoggerLevel.info, "Cart Model is empty"));
        break;
      case "hold":
        await _holdBill();
        if (POSConfig().dualScreenWebsite != "")
          DualScreenController().setLandingScreen();
        break;
      case "recall":
        await _recall();
        break;
      case "bill_cancel":
        await _billCancellation();
        break;
      case "backspace":
        _backSpace();
        break;
      case "cash_in":
        cashInOutView(true);
        break;
      case "cash_out":
        cashInOutView(false);
        break;
      case "categories":
        weightedItem();
        break;
      case "re_print":
        _reprint();
        break;
      case "clear":
        clearInvoice();
        break;
      case "drawer_open":
        openDrawer();
        break;
    }
  }

  Future<void> clearInvoice() async {
    if (context == null) {
      return;
    }
    bool hasPermission = false;

    // fetch permission list
    final userCode = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
    // EasyLoading.show(status: 'please_wait'.tr());
    // final permissionList =
    //     await AuthController().getUserPermissionListByUserCode(userCode);
    // EasyLoading.dismiss();

    // hasPermission = SpecialPermissionHandler(context: context!)
    //     .hasPermissionInList(permissionList?.userRights ?? [],
    //         PermissionCode.resetPOSScreenWithItems, "A", userCode);
    final permissionList = userBloc.userDetails?.userRights;
    hasPermission = SpecialPermissionHandler(context: context!)
        .hasPermissionInList(permissionList ?? [],
            PermissionCode.resetPOSScreenWithItems, "A", userCode);

    //if user doesnt have the permission
    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: context!)
          .askForPermission(
              permissionCode: PermissionCode.resetPOSScreenWithItems,
              accessType: "A",
              refCode: DateTime.now().toIso8601String());
      hasPermission = res.success;
    }

    // still havent permission
    if (!hasPermission) {
      return;
    }

    if (cartBloc.cartSummary?.recallHoldInv == true) {
      EasyLoading.showError('special_functions.HoldBillClearError'.tr());
      return;
    }
    EasyLoading.show(status: 'please_wait'.tr());

    await cartBloc.resetCart();
    if (POSConfig().dualScreenWebsite != "")
      DualScreenController().setLandingScreen();
    EasyLoading.dismiss();
  }

  Future<void> openDrawer() async {
    if (context == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Field 'context' has not been initialized."));
      return;
    }
    SpecialPermissionHandler handler =
        SpecialPermissionHandler(context: context!);
    String code = PermissionCode.openCashDrawer;
    String type = "A";
    String refCode = "Drawer open";
    bool permissionStatus = handler.hasPermission(
        permissionCode: code, accessType: type, refCode: refCode);
    if (!permissionStatus) {
      bool success = (await handler.askForPermission(
              accessType: type, permissionCode: code, refCode: refCode))
          .success;
      if (!success) return;
    }

    if (POSConfig.crystalPath != '') {
      PrintController()
          .printHandler("", PrintController().openDrawer(), context!);
    } else {
      await POSManualPrint().openDrawer();
    }
  }
}
