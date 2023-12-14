/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/9/21, 6:41 PM
 */
import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/controllers/discount_handler.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/permission_code.dart';

import 'package:flutter/cupertino.dart';

import 'auth_controller.dart';

///handle bill discounts
class BillDiscountHandler {
  List<CartModel> _currentCartList =
      cartBloc.currentCart?.values.toList() ?? [];
  final double discountAmount;
  DiscountHandler _handler = DiscountHandler();

  BillDiscountHandler(this.discountAmount);

  double calculateApplicableTotal() {
    double total = 0;
    _currentCartList.forEach((cart) async {
      if (_handler.canApplyLineDiscount(cart)) {
        total += cart.unitQty * cart.selling;
      }
    });
    return total;
  }

  Future calculateDiscount(
      String user, BuildContext context, double maxDiscountAmount) async {
    double total = 0;
    CartSummaryModel cartSummary = cartBloc.cartSummary ??
        CartSummaryModel(
            invoiceNo: "",
            items: 0,
            qty: 0,
            subTotal: 0,
            startTime: '',
            priceMode: '');

    // check for max discount percentage
    bool shouldAskOverride = false;
    bool canApplyDiscount = true;

    _currentCartList.forEach((cart) {
      double maxDiscPer = maxDiscountAmount;
      if((cart.maxDiscPer ??0)  != 0){
        if(cart.maxDiscPer!>maxDiscPer){
          maxDiscPer = cart.maxDiscPer!;
        }
        if (maxDiscPer < discountAmount) {
          canApplyDiscount = false;
          shouldAskOverride = true;
        }
      }else if((cart.maxDiscAmt??0)!=0){
        //calculate max disc amt
        double maxDiscAmtUser = maxDiscountAmount * cart.selling/100;
        if(maxDiscAmtUser>cart.maxDiscAmt!){
          maxDiscAmtUser = cart.maxDiscAmt!;
        }
        double cartDiscount = cart.amount * discountAmount/100;
        if(maxDiscAmtUser<cartDiscount){
          canApplyDiscount = false;
          shouldAskOverride = true;
        }
      }
    });
    if (maxDiscountAmount < discountAmount) {
      shouldAskOverride = true;
      canApplyDiscount = false;
    }
    if (shouldAskOverride) {
      if (await hasOverridePermission(user, context, cartSummary.invoiceNo)) {
        canApplyDiscount = true;
        // break;
      }
    }
    if (!canApplyDiscount) {
      return;
    }
    _currentCartList.forEach((cart) async {
      if (_handler.canApplyLineDiscount(cart)) {
        final oldAmount = cart.unitQty * cart.selling;
        final newAmount = oldAmount * (1 - (discountAmount / 100.0));
        cart.billDiscPer = discountAmount;
        // cart.amount = newAmount;
        total += newAmount;
        await applyLineDiscount(cart);
      } else {
        if (cart.itemVoid == false) {
          total += cart.amount;
        }
      }
    });
    cartSummary.subTotal = total;
    cartSummary.discPer = discountAmount;
    cartBloc.updateCartSummary(cartSummary);
    await InvoiceController().updateTempCartSummary(cartSummary);
  }

  /// this method will remove the current cart model readd the given one
  Future applyLineDiscount(CartModel cart) async {
    await cartBloc.updateCartItem(cart);
  }

  void clearDiscount() async {
    // final one = double.one;
    // final hundred = double.fromInt(100);
    double currentTotal = 0;
    double newTotal = 0;
    CartSummaryModel cartSummary = cartBloc.cartSummary ??
        CartSummaryModel(
            invoiceNo: "",
            items: 0,
            qty: 0,
            subTotal: 0,
            startTime: '',
            priceMode: '');

    _currentCartList.forEach((cart) async {
      final billDiscPer = cart.billDiscPer ?? 0;
      if (!cart.noDisc && billDiscPer > 0 && cart.itemVoid != true) {
        currentTotal += cart.amount;
        final temp = cart.unitQty * cart.selling;
        newTotal += temp;
        cart.amount = temp;
        cart.billDiscPer = 0;
        await applyLineDiscount(cart);
      }
    });
    cartSummary.discPer = 0;
    cartSummary.subTotal = cartSummary.subTotal - currentTotal + newTotal;
    cartBloc.updateCartSummary(cartSummary);
    await InvoiceController().updateTempCartSummary(cartSummary);
  }

  Future<bool> hasOverridePermission(
      String user, BuildContext context, String invoice) async {
    bool hasPermission = false;
    //check
    final handler = SpecialPermissionHandler(context: context);
    final permissionList =
        await AuthController().getUserPermissionListByUserCode(user);

    bool hasPermissionToOverRide = SpecialPermissionHandler(context: context)
        .hasPermissionInList(permissionList?.userRights ?? [],
            PermissionCode.overrideDiscount, "A", user);

    if (!hasPermissionToOverRide) {
      //  ask
      hasPermission = (await handler.askForPermission(
              refCode: "$invoice%$discountAmount",
              permissionCode: PermissionCode.overrideDiscount,
              accessType: "A"))
          .success;
    } else {
      hasPermission = true;
    }
    return hasPermission;
  }

// Future _removeCartFromDb(CartModel cart) async {
//   await InvoiceController().deleteItemFromTempCart(cart);
// }
//
// Future _addCartToDb(CartModel cart) async {
//   await InvoiceController().saveItemTempCart(cart);
// }
}
