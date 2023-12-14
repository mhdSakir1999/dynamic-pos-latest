/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/12/21, 4:20 PM
 */

import 'package:checkout/controllers/area_controller.dart';
import 'package:checkout/models/loyalty/area_result.dart';
import 'package:rxdart/rxdart.dart';

class AreaBloc {
  final _area = BehaviorSubject<List<Area>>();
  Stream<List<Area>> get areaListSnapshot => _area.stream;


  Future getAreaList() async {
    //  fetch area
    final res = await AreaController().getAreaList();
    _area.sink.add(res?.areaList ?? []);
  }


  void dispose() {
    _area.close();
  }
}

final areaBloc = AreaBloc();
