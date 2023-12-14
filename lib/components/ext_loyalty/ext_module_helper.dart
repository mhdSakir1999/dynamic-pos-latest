/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/22/22, 6:25 PM
 */
import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/components/ext_loyalty/ext_loyalty_module.dart';
import 'package:checkout/components/ext_loyalty/ext_module_customer.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/pos/setup_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';

class ExtLoyaltyModuleHelper {
  ExtLoyaltyModule? loyaltyModule;
  bool extLoyaltyModuleActive = false;
  String module = '';

  ExtLoyaltyModuleHelper() {
    Setup? setup = POSConfig().setup;
    int? port;
    String? url = setup?.loyaltyProviderUrl;
    String? baseUrl = url;
    if ((url ?? '').isNotEmpty) {
      if (url!.contains(':')) {
        baseUrl = url.split(":").first;
        port = int.tryParse(url.split(":").last) ?? 80;
      } else {
        port = 80;
      }
    }
    if (setup != null) {
      switch (setup.loyaltyProvider?.toLowerCase().trim()) {
        case 'cargills':
          // module = 'Star Points';
          // extLoyaltyModuleActive = true;
          // loyaltyModule = CargillsLoyaltyModule(setup.loyaltyProviderUser ?? '',
          //     setup.loyaltyProviderPassword ?? '', baseUrl, port);
          break;
        default:
          POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.error,
              '${setup.loyaltyProvider?.toLowerCase()} is not defined module'));
      }
    } else {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.error, 'Setup is null'));
    }
  }

  Future<String?>? registrationRequest(ExtModuleCustomer customer) {
    customer.mobile = _formatNo(customer.mobile ?? '');
    return loyaltyModule?.registerCustomerRequest(customer);
  }

  Future<bool>? registerCustomer(ExtModuleCustomer customer) {
    customer.mobile = _formatNo(customer.mobile ?? '');
    return loyaltyModule?.registerCustomer(customer);
  }

  Future<double>? pointBalance(String code) {
    code = _formatNo(code);
    return loyaltyModule?.balanceInquiry(code);
  }

  Future<bool>? redemptionPinRequest(String code, double amount) {
    code = _formatNo(code);
    return loyaltyModule?.redeemCodeRequest(code, amount);
  }

  Future<bool>? redemptionCommit(String otpCode, double amount) {
    return loyaltyModule?.redeemPoint(
        cartBloc.cartSummary ?? cartBloc.defaultSummary,
        cartBloc.currentCart?.values.toList() ?? [],
        cartBloc.paidList ?? [],
        amount,
        otpCode);
  }

  Future<bool>? earnLoyaltyPoints(String code) {
    code = _formatNo(code);
    return loyaltyModule?.earnPoints(
      cartBloc.cartSummary ?? cartBloc.defaultSummary,
      cartBloc.currentCart?.values.toList() ?? [],
      cartBloc.paidList ?? [],
    );
  }

  Future<bool>? validateCustomer(String code) {
    code = _formatNo(code);
    return loyaltyModule?.validateCustomer(
      code,
    );
  }

  String _formatNo(String number) {
    number = number.replaceAll('+940', '');
    number = number.replaceFirst('+94', '');
    number = number.replaceFirst('0', '');
    return number;
  }
}
