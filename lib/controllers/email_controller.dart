/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 11/2/21, 5:16 PM
 */

import 'package:checkout/components/api_client.dart';
import 'package:checkout/extension/extensions.dart';
class EmailController{
  Future<bool> sendEbill(String invoiceNo) async {
    final res = await ApiClient.call("email/invoice/$invoiceNo", ApiMethod.GET);
    if (res?.data == null)
      return false;
    else
      return res?.data["success"]?.toString().parseBool()??false;
  }

}