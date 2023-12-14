/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/12/21, 7:15 PM
 */

import 'package:checkout/controllers/group_controller.dart';
import 'package:checkout/models/pos/GroupResults.dart';
import 'package:rxdart/rxdart.dart';

class GroupBloc {
  final _departments = BehaviorSubject<GroupResults?>();
  Stream<GroupResults?> get getDepartmentSteam => _departments.stream;
  GroupResults? get groupRes => _departments.valueOrNull;

  Future getDepartments() async {
    final res = await GroupController().getDepartments();
    _departments.sink.add(res);
  }

  void dispose() {
    _departments.close();
  }
}

final groupBloc = GroupBloc();
