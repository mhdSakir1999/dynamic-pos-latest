/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Dinuka Kulathunga
 * Created At: 9/9/22, 11:33 AM
 */

import 'package:checkout/controllers/utility_bill_setup_controller.dart';
import 'package:rxdart/rxdart.dart';

import '../models/utility_bill/utility_bill_sub_category.dart';

class UtilityBillSubcategoryBloc {
  final _subcategory = BehaviorSubject<List<UtilityBillSubcategory>>();
  Stream<List<UtilityBillSubcategory>>
      get currentUtilityBillSubcategorySnapshot => _subcategory.stream;

  List<UtilityBillSubcategory>? get currentSubCategory =>
      _subcategory.valueOrNull;

  Future<void> getUtilityBillSubcategoryById(String categoryId) async {
    final res = await UtilityBillSetupController()
        .getUtilityBillSubcategoryById(categoryId);
    _subcategory.sink.add(res);
  }

  void dispose() {
    _subcategory.close();
  }
}

UtilityBillSubcategoryBloc utilityBillSubCategoryBloc =
    UtilityBillSubcategoryBloc();
