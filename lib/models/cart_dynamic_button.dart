/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/27/21, 9:40 AM
 */

/// This model class contains the cart screen RHS button data
class CartDynamicButton {
  String buttonName;
  String functionName;
  String buttonNormalColor;
  String buttonActiveColor;
  String? textColor;
  bool active;

  CartDynamicButton(this.buttonName, this.functionName, this.buttonNormalColor,
      this.buttonActiveColor, this.active,
      [this.textColor]);
}
