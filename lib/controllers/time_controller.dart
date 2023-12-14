/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/4/21, 6:06 PM
 */

import 'package:checkout/components/api_client.dart';
import 'package:checkout/extension/extensions.dart';

class TimeController {
  Future<DateTime> getCurrentServerTime() async {
    final res = await ApiClient.call("time/current_time", ApiMethod.GET);
    if (res?.data == null)
      return DateTime.now();
    else {
      return res?.data["date"].toString().parseDateTime()??DateTime.now();
    }
  }
}
