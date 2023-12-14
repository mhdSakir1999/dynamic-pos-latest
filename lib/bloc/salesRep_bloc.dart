import 'package:checkout/components/api_client.dart';
import 'package:checkout/models/loyalty/salesRep_list_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:rxdart/rxdart.dart';

/// Author: [TM.Sakir]
/// Created At: 2023-11-21, 1:38 PM

class SalesRepBloc {
  final _currentSalesRep = BehaviorSubject<List<SalesRepResult>?>();

  Stream<List<SalesRepResult>?> get currentSalesRepStream =>
      _currentSalesRep.stream;
  List<SalesRepResult>? get currentSalesRep => _currentSalesRep.valueOrNull;

  Future<SalesRepListResult?> getSalesReps() async {
    final res = await ApiClient.call(
        "salesrep/${POSConfig().locCode}", ApiMethod.GET,
        successCode: 200);
    if (res?.statusCode != 200) return null;
    if (res != null && res.data != null) {
      _currentSalesRep.sink.add(SalesRepListResult.fromJson(res.data).repList);
      return SalesRepListResult.fromJson(res.data);
    } else {
      return null;
    }
  }

  void dispose() {
    if (!_currentSalesRep.isClosed) {
      _currentSalesRep.close();
    }
  }
}

final salesRepBloc = SalesRepBloc();
