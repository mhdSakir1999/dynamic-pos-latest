import 'package:checkout/models/dashboard_model.dart';

import '../components/api_client.dart';

class DashboardController {
  Future<Dashboard?>? getDashboardData(
      String cashier, String locationCode) async {
    final res = await ApiClient.call(
        "dashboard/$cashier/$locationCode", ApiMethod.GET,
        successCode: 200);
    if (res?.data == null) {
      return null;
    }
    return Dashboard.fromJson(res?.data['result']);
  }
}
