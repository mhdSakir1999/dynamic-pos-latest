/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/1/22, 3:26 PM
 */

import 'package:checkout/controllers/utility_bill_setup_controller.dart';
import 'package:checkout/models/utility_bill/utility_bill_setup.dart';
import 'package:rxdart/rxdart.dart';

class UtilityBillSetupBloc {
  final _setup = BehaviorSubject<List<UtilityBillSetup>>();
  Stream<List<UtilityBillSetup>> get currentUtilityBillSetupSnapshot =>
      _setup.stream;

  List<UtilityBillSetup>? get currentUtilityBillSetup => _setup.valueOrNull;

  Future<void> getUtilityBillSetup() async {
    final res = await UtilityBillSetupController().getUtilityBillSetup();
    _setup.add(res);
  }

  Future<void> getUtilityBillSetupById(String categoryId) async {
    final res =
        await UtilityBillSetupController().getUtilityBillSetupById(categoryId);
    _setup.add(res);
  }

  Future<void> getUtilityBillSetupBySubId(String subcategoryId) async {
    final res = await UtilityBillSetupController()
        .getUtilityBillSetupBySubId(subcategoryId);
    _setup.add(res);
  }

  void dispose() {
    _setup.close();
  }
}

UtilityBillSetupBloc utilityBillSetupBloc = UtilityBillSetupBloc();
