/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/22/22, 6:01 PM
 */

import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/paid_model.dart';

import 'ext_module_customer.dart';

abstract class ExtLoyaltyModule{
  Future<void> authenticate();
  Future<double> balanceInquiry(String code);
  Future<bool> validateCustomer(String code);
  Future<bool> registerCustomer(ExtModuleCustomer customer);
  Future<String?> registerCustomerRequest(ExtModuleCustomer customer);
  Future<bool> redeemPoint(CartSummaryModel header,List<CartModel> invDetails,List<PaidModel> payments,double amount,String pinNo);
  Future<bool> earnPoints(CartSummaryModel header, List<CartModel> invDetails,
      List<PaidModel> payments);
  Future<bool> redeemCodeRequest(String code,double amount);
  Future<String> generateNewCardNo();
}


