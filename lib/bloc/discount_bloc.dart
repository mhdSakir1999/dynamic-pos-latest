/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/4/21, 6:52 PM
 */

import 'package:checkout/controllers/discount_controller.dart';
import 'package:checkout/models/pos/discount_type_result.dart';
import 'package:rxdart/rxdart.dart';

class DiscountBloc {
  final _discountTypes = BehaviorSubject<List<DiscountTypes>>();
  Stream<List<DiscountTypes>> get discountTypeSteam => _discountTypes.stream;
  void getDiscountTypes() async {
    final res = await DiscountController().getDiscountTypes();
    if (res != null) {
      _discountTypes.sink.add(res.discountTypes ?? []);
    }
  }

  void dispose() {
    _discountTypes.close();
  }
}

final discountBloc = DiscountBloc();
