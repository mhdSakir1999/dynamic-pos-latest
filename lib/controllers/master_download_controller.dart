import 'package:checkout/models/pos_config.dart';
import 'package:flutter/widgets.dart';

import '../components/api_client.dart';

class MasterDownloadController {
  // get table names need to backup
  Future downloadAndSyncMaster() async {
    final res = await ApiClient.call(
        "downloadandsyncmaster/download_master_tables/" + POSConfig().locCode,
        ApiMethod.GET,
        local: true,
        successCode: 200);
    if (res?.data == null) {
      return null;
    }
    debugPrint(res?.data['message']);
    return res?.data;
  }
}