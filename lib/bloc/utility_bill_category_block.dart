/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Dinuka Kulathunga
 * Created At: 7/7/22, 09:02 PM
 */

import 'package:checkout/controllers/utility_bill_setup_controller.dart';
import 'package:rxdart/rxdart.dart';

import '../models/utility_bill/utility_bill_category.dart';

class UtilityBillCategoryBloc {
  final _setup = BehaviorSubject<List<UtilityBillCategory>>();
  Stream<List<UtilityBillCategory>> get currentUtilityBillCategory =>
      _setup.stream;

  Future<void> getUtilityBillCategories() async {
    final res = await UtilityBillSetupController().getUtilityBillCategories();
    _setup.add(res);
  }

  void dispose() {
    _setup.close();
  }
}

UtilityBillCategoryBloc utilityBillCategoryBloc = UtilityBillCategoryBloc();
