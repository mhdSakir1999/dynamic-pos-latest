import 'package:dio/dio.dart';

import '../components/api_client.dart';

class DashboardController {
  Future<String?>? getDashboardData(
      {String? cashier,
      String? locationCode,
      String? terminal,
      int? shift,
      String? signOnDate,
      String? salesDate}) async {
    final res = await ApiClient.call("users/dashboard", ApiMethod.GET,
        formData: FormData.fromMap({
          "location": locationCode,
          "terminal_id": terminal,
          "cashier": cashier,
          "shift": shift,
          "signOndate": signOnDate,
          "salesDate": salesDate
        }),
        successCode: 200);
    if (res?.data['success'] != true) {
      return null;
    }
    // return Dashboard.fromJson(res?.data['result']);
    return res?.data['data'];
  }
}
