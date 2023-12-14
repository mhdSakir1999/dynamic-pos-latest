/*
 * Copyright (c) 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 06/01/2022, 15:32
 */

import 'package:checkout/components/api_client.dart';
import 'package:checkout/models/pos/price_mode_result.dart';

class PriceController{
  Future<List<PriceModes>> getPriceModes() async {
    final res = await ApiClient.call(
      'price/modes', ApiMethod.GET,);
    if (res == null || res.data == null) return [];
    List<PriceModes> price = <PriceModes>[];
    if(res.data != null){
      return PriceModeResult.fromJson(res.data).priceModes??<PriceModes>[];
    }
    return price;
  }
}