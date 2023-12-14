/* /*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/22/22, 6:23 PM
 */

import 'dart:io';

import 'package:cargills_loyalty/cargills_loyalty.dart';
import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/ext_loyalty/ext_loyalty_module.dart';
import 'package:checkout/components/ext_loyalty/ext_module_customer.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../controllers/loyalty_controller.dart';
import '../../../controllers/pos_logger_controller.dart';
import '../../../models/pos_logger.dart';

class CargillsLoyaltyModule implements ExtLoyaltyModule {
  final String user;
  final String password;
  final int? port;
  final String? baseUrl;

  late CargillsLoyalty _loyalty;

  CargillsLoyaltyModule(this.user, this.password, this.baseUrl, this.port) {
    _loyalty = new CargillsLoyalty(baseUrl: baseUrl, port: port);
  }

  String _dateFormat = 'yyyy-MM-dd';

  @override
  Future<void> authenticate() async {
    try {
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
          'Cargills Loyalty: Authenticating loyalty module'));
      await _loyalty.v1.auth
          .createSessionWithLogin(user, password, rememberToken: true);
    } on SocketException catch (_) {
      EasyLoading.showError('Could not connect to the ${this.baseUrl}:$port ');
    } on Exception catch (e) {
      EasyLoading.showError(e.toString());
    }
  }

  @override
  Future<double> balanceInquiry(String code) async {
    await authenticate();
    POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
        'Cargills Loyalty: Customer balance inquiry requested'));
    final res = await _loyalty.v1.loyalty.balanceInquiry(code);
    if (res.resCoe != '00') {
      EasyLoading.showError(res.resMessage ??
          'Unknown error occurred while calling balance inquiry');
    }
    return res.result?.redeemableBalance ?? 0;
  }

  Future<String?> registerCustomerRequest(ExtModuleCustomer customer) async {
    //validate customer first
    bool valid =
        await validateCustomer(customer.mobileEntered ?? '', showError: false);
    if (valid) {
      EasyLoading.showError('This customer is already existed');
      return null;
    } else {
      // final String newCardNo = await generateNewCardNo();
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
          'Cargills Loyalty: Customer Registration Request'));
      CargillsLoyaltyRegisterUser req = CargillsLoyaltyRegisterUser(
          branchCode: POSConfig().locCode,
          companyCode: POSConfig().comCode,
          customerCategory: customer.loyaltyGroup ?? '',
          customerType: customer.group ?? '',
          emailId: customer.email ?? '',
          mobileNo: customer.mobileEntered ?? '',
          nic: customer.nic ?? '',
          surname: customer.lastName ?? '');
      final res = await _loyalty.v1.registration.registerRequest(req);
      if (res.resCode == '00') {
        return (res.result?.referenceNumber ?? '').toString();
      } else {
        EasyLoading.showError(res.resMessage ??
            'Unknown error occurred while requesting customer registration');
        return null;
      }
    }
  }

  @override
  Future<bool> registerCustomer(ExtModuleCustomer customer) async {
    await authenticate();

    // final String newCardNo = await generateNewCardNo();
    POSLoggerController.addNewLog(POSLogger(
        POSLoggerLevel.info, 'Cargills Loyalty: Customer Registration commit'));
    CargillsLoyaltyRegisterUserCommit userCommit =
        CargillsLoyaltyRegisterUserCommit(
      branchCode: POSConfig().locCode,
      companyCode: POSConfig().comCode,
      customerCategory: customer.loyaltyGroup ?? '',
      customerType: customer.group ?? '',
      emailId: customer.email ?? '',
      mobileNo: customer.mobileEntered ?? '',
      nic: customer.nic ?? '',
      surname: customer.lastName ?? '',
      customerPin: customer.enteredOtp ?? 1234,
      dateOfBirth: customer.dob ?? '',
      gender: customer.gender ?? '',
      referenceNumber: customer.referenceNumber ?? 0,
    );
    final res = await _loyalty.v1.registration.registerCommit(userCommit);
    if (res.resCode == '00') {
      return true;
    } else {
      EasyLoading.showError(res.resMessage ??
          'Unknown error occurred while committing the customer data');
      return false;
    }
  }

  @override
  Future<bool> validateCustomer(String code, {bool showError = true}) async {
    //create token
    await authenticate();
    POSLoggerController.addNewLog(POSLogger(
        POSLoggerLevel.info, 'Cargills Loyalty: Customer Validation'));
    final res = await _loyalty.v1.loyalty.validateCustomer(code);
    if (res.resCoe == '00') {
      return true;
    } else {
      if (showError)
        EasyLoading.showError(res.resMessage ??
            'Unknown error occurred while validating customer');
      return false;
    }
  }

  @override
  Future<String> generateNewCardNo() async {
    //create token
    await authenticate();
    POSLoggerController.addNewLog(POSLogger(
        POSLoggerLevel.info, 'Cargills Loyalty: Generate card number'));
    final res =
        await _loyalty.v1.loyalty.generateNewCardNo(POSConfig().locCode);
    return res.newCardNo ?? '';
  }

  @override
  Future<bool> redeemCodeRequest(String code, double amount) async {
    await authenticate();
    POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
        'Cargills Loyalty: Loyalty point redemption code request'));
    final res = await _loyalty.v1.loyalty.redemptionPinRequest(code);
    if (res.resCode == '00') {
      return true;
    } else {
      EasyLoading.showError(res.resMessage ??
          'Unknown error occurred while requesting redemption pin');
      return false;
    }
  }

  @override
  Future<bool> redeemPoint(CartSummaryModel header, List<CartModel> invDetails,
      List<PaidModel> payments, double amount, String pin) async {
    await authenticate();
    POSLoggerController.addNewLog(POSLogger(
        POSLoggerLevel.info, 'Cargills Loyalty: Loyalty point redemption'));
    final res = await _loyalty.v1.loyalty.redemptionCommit(
        CargillsLoyaltyRedemptionCommitHeader(
            branchCode: POSConfig().locCode,
            companyCode: POSConfig().comCode,
            mobileNo: customerBloc.currentCustomer?.cMMOBILE ?? '',
            txnDate: DateFormat(_dateFormat).format(DateTime.now()),
            billNo: header.invoiceNo,
            billTotal: header.subTotal.toDouble(),
            payMethod: payments.first.phCode,
            terminalId: POSConfig().terminalId,
            cashierId: userBloc.currentUser?.uSERHEDUSERCODE ?? '',
            totalPointsBurned: amount,
            pinNo: pin,
            item: invDetails
                .map((e) => CargillsLoyaltyInvoiceDetails(
                    itemCode: e.proCode,
                    description: e.posDesc,
                    qty: e.unitQty.toDouble(),
                    unitPrice: e.selling.toDouble(),
                    totalDiscount:
                        ((e.unitQty * e.proSelling) - e.amount).toDouble(),
                    totalTax: 0,
                    lineNo: e.lineNo ?? -1))
                .toList()));
    if (res.resCode == '00') {
      return true;
    } else {
      EasyLoading.showError(res.resMessage ??
          'Unknown error occurred while committing redeeming points');
      return false;
    }
  }

  @override
  Future<bool> earnPoints(CartSummaryModel header, List<CartModel> invDetails,
      List<PaidModel> payments) async {
    await authenticate();
    POSLoggerController.addNewLog(POSLogger(
        POSLoggerLevel.info, 'Cargills Loyalty: Earn Loyalty Points'));
    String mobile = customerBloc.currentCustomer?.cMCODE ?? '';
    final statement = await LoyaltyController().getLoyaltySummary(mobile);

    final res = await _loyalty.v1.loyalty.pointsEarning(
      header.invoiceNo,
      CargillsLoyaltyInvoiceHeader(
          companyCode: POSConfig().comCode,
          branchCode: POSConfig().locCode,
          txnDate: DateFormat(_dateFormat).format(DateTime.now()),
          billNo: header.invoiceNo,
          terminalId: POSConfig().terminalId,
          cashierId: userBloc.currentUser?.uSERHEDUSERCODE ?? '',
          totalPointsEarned: statement?.lastBillAdded ?? 0,
          billTotal: header.subTotal.toDouble(),
          mobileNo: mobile,
          invoiceItems: invDetails
              .map((e) => CargillsLoyaltyInvoiceDetails(
                  itemCode: e.proCode,
                  description: e.posDesc,
                  qty: e.unitQty.toDouble(),
                  unitPrice: e.selling.toDouble(),
                  totalDiscount:
                      ((e.unitQty * e.proSelling) - e.amount).toDouble(),
                  totalTax: 0,
                  lineNo: e.lineNo ?? -1))
              .toList(),
          payMethod: payments.first.phCode),
    );
    if (res.resCoe == '00') {
      return true;
    } else {
      EasyLoading.showError(
          res.resMessage ?? 'Unknown error occurred while earning points');
      return false;
    }
  }
}
 */