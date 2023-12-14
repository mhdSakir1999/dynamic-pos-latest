/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/27/21, 9:40 AM
 */

import 'package:checkout/models/cart_dynamic_button.dart';

/// This class is the controller class of the dynamic buttons in cart screen
class CartDynamicButtonController {
  List<CartDynamicButton> getButtonList() {
    return [
      CartDynamicButton("Special\nFunctions", "special_function", "#ffffff",
          "#d9d9d9", false, "ff0100"),
      CartDynamicButton("Clear", "clear", "#d9d9d9", "#ffffff", false),
      CartDynamicButton("Search", "search", "#d9d9d9", "#ffffff", false),
      CartDynamicButton("Hold", "hold", "#d9d9d9", "#ffffff", false),
      CartDynamicButton("Net Disc", "net_disc", "#d9d9d9", "#ffffff", false),
      CartDynamicButton("Gift Voucher", "gv", "#d9d9d9", "#ffffff", false),
      CartDynamicButton(
          "Repeat PLU", "repeat_plu", "#d9d9d9", "#ffffff", false),
      CartDynamicButton("Re-Print", "re_print", "#d9d9d9", "#ffffff", false),
      CartDynamicButton("Disc %", "line_disc_per", "#d9d9d9", "#ffffff", false),
      CartDynamicButton("Recall", "recall", "#d9d9d9", "#ffffff", false),
      CartDynamicButton("Weighted", "categories", "#d9d9d9", "#ffffff", false),
      CartDynamicButton(
          "Drawer\nOpen", "drawer_open", "#d9d9d9", "#ffffff", false),
      CartDynamicButton(
          "Disc Amt", "line_disc_amt", "#d9d9d9", "#ffffff", false),
      CartDynamicButton(
          "Bill Cancel", "bill_cancel", "#d9d9d9", "#ffffff", false),
      CartDynamicButton("Cash In", "cash_in", "#d9d9d9", "#ffffff", false),
      CartDynamicButton("Cash Out", "cash_out", "#d9d9d9", "#ffffff", false),
    ];
  }
}
