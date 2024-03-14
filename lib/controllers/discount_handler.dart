/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 6/4/21, 10:22 AM
 */
import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/discount_type_result.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/cupertino.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class DiscountHandler {
  Future<double> manualLineDiscount(
      CartModel cart,
      double enteredDiscount,
      bool discountPercentage,
      double maxDiscountPre,
      BuildContext context,
      String user,
      DiscountTypes discountType) async {
    // check override amount
    double discountVal = 0;
    final currentLineTotal = cart.amount;
    // bool canNavigate = false;
    var tempVal = enteredDiscount;

    // var exactLineAmount =
    //     ((cart.unitQty * cart.selling) - (cart.discAmt ?? 0)).toDouble();
    var exactLineAmount = (cart.unitQty *
        cart.selling); // the total amount should be the gross amount(selling*qty) when do percentage discounts

    if (!discountPercentage) {
      //  calculate
      tempVal = (enteredDiscount / exactLineAmount) * 100.0;
    }

    //check for item's max discount
    bool isProductMaxDiscountExceed = false;
    bool alreadyOverride = false;
    if (discountPercentage) {
      //assign maximum discount amount to product's max disc
      if (cart.maxDiscPer! > maxDiscountPre) {
        maxDiscountPre = cart.maxDiscPer!;
      }

      if ((cart.maxDiscPer ?? 0) == 0) {
        isProductMaxDiscountExceed = false;
      } else if (enteredDiscount > maxDiscountPre) {
        isProductMaxDiscountExceed = true;
      }
      // check the discount type's maximum discount percentage
    } else {
      if ((cart.maxDiscAmt ?? 0) == 0) {
        isProductMaxDiscountExceed = false;
      } else {
        double productMaxDiscAmt = (cart.maxDiscAmt ?? 0) * cart.unitQty;
        double userMaxDiscAmt = maxDiscountPre * cart.amount / 100;
        if (userMaxDiscAmt > productMaxDiscAmt) {
          productMaxDiscAmt = userMaxDiscAmt;
        }
        if (enteredDiscount > productMaxDiscAmt) {
          isProductMaxDiscountExceed = true;
        }
      }
    }
    if (isProductMaxDiscountExceed) {
      bool hasPermission =
          await hasOverridePermission(user, cart, context, enteredDiscount);
      if (hasPermission) {
        alreadyOverride = true;
        discountVal = enteredDiscount;
      } else {
        return 0;
      }
    }

    //If User Max discount % is less than the offered discount %
    if (enteredDiscount > maxDiscountPre) {
      bool hasPermission =
          await hasOverridePermission(user, cart, context, enteredDiscount);
      if (hasPermission) {
        alreadyOverride = true;
        discountVal = enteredDiscount;
      } else {
        return 0;
      }
    }

    print(maxDiscountPre);
    discountVal = enteredDiscount;

    if (discountPercentage) {
      if (discountVal > 100) {
        discountVal = 100;
      }
      cart.discPer = discountVal.toString().parseDouble();
      discountVal = ((exactLineAmount * discountVal) / 100);
    } else {
      final per = cart.discPer ?? 0;
      if (per > 0) {
        exactLineAmount = cart.amount.toDouble();
      }
      cart.discAmt = discountVal.toString().parseDouble();
    }
    cart.billDiscPer = 0;

    // cart.amount = (exactLineAmount - discountVal).toString().parseDouble();  // this is wrong calculation
    cart.amount = (cart.amount >= 0 || discountPercentage)
        ? (cart.amount - discountVal)
        : (cart.amount + discountVal); // this is the correct one

    cartBloc.updateCartItem(cart);
    cartBloc.updateCartSummaryPrice(-1 * currentLineTotal);
    cartBloc.updateCartSummaryPrice(cart.amount);
    return discountVal;
  }

  Future<bool> hasOverridePermission(String user, CartModel cart,
      BuildContext context, double enteredDiscount) async {
    // EasyLoading.show(status: 'please_wait'.tr());
    bool hasPermission = false;
    //check
    final handler = SpecialPermissionHandler(context: context);

    // final permissionList =
    //     await AuthController().getUserPermissionListByUserCode(user);

    // bool hasPermissionToOverRide = SpecialPermissionHandler(context: context)
    //     .hasPermissionInList(permissionList?.userRights ?? [],
    //         PermissionCode.overrideDiscount, "A", user);
    final permissionList = userBloc.userDetails?.userRights;

    bool hasPermissionToOverRide = SpecialPermissionHandler(context: context)
        .hasPermissionInList(
            permissionList ?? [], PermissionCode.overrideDiscount, "A", user);

    // EasyLoading.dismiss();
    if (!hasPermissionToOverRide) {
      //  ask
      hasPermission = (await handler.askForPermission(
              refCode:
                  "${cart.proCode}@${cart.unitQty}@${enteredDiscount.toStringAsFixed(2)}",
              permissionCode: PermissionCode.overrideDiscount,
              accessType: "A"))
          .success;
    } else {
      hasPermission = true;
    }
    return hasPermission;
  }

  bool canApplyLineDiscount(CartModel cart) {
    return !cart.noDisc &&
        cart.allowDiscount == true &&
        (cart.itemVoid == false) &&
        cart.unitQty > 0 &&
        (cart.discAmt == null || cart.discAmt == 0) &&
        (cart.discPer == null || cart.discPer == 0);
  }

  Future clearDiscount(bool percentage, CartModel cart) async {
    final currentAmount = cart.amount;
    final lineNetAmount = cart.unitQty * cart.selling;
    var change = 0.0;

    if (percentage) {
      change = (lineNetAmount * (cart.discPer ?? 0) / 100.0);
      cart.discPer = 0;
    } else {
      change = cart.discAmt ?? 0;
      cart.discAmt = 0;
    }

    cart.amount = currentAmount + change;
    cart.discountReason = '';
    cartBloc.updateCartItem(cart);
    cartBloc.updateCartSummaryPrice(change);
    // cartBloc.updateCartSummaryPrice(cart.amount);
  }
}
