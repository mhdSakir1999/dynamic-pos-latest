/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/12/21, 4:20 PM
 */

import 'package:checkout/controllers/price_controller.dart';
import 'package:checkout/models/pos/price_mode_result.dart';
import 'package:rxdart/rxdart.dart';

class PriceModeBloc {
  final _priceModes = BehaviorSubject<List<PriceModes>>();
  Stream<List<PriceModes>> get priceModesSnapshot => _priceModes.stream;
  List<PriceModes> get priceModes => _priceModes.valueOrNull??<PriceModes>[];

  Future<void> fetchPriceModes() async {
    //  fetch area
    final List<PriceModes> priceModeList= await PriceController().getPriceModes();
    _priceModes.sink.add(priceModeList);
  }

  void dispose() {
    _priceModes.close();
  }
}

final priceModeBloc = PriceModeBloc();
