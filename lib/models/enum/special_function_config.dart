/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/27/21, 2:12 PM
 */
class SpecialFunctionConfig {
  static final SpecialFunctionConfig _singleton =
      SpecialFunctionConfig._internal();

  factory SpecialFunctionConfig() {
    return _singleton;
  }
  SpecialFunctionConfig._internal();

  List spectionFunctionList = [
    "special_functions.utility_bill_payments",
    "special_functions.backoffice_invoice",
  ];
}
