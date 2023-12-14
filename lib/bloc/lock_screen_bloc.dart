/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/23/21, 10:57 AM
 */

import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:rxdart/rxdart.dart';

// KeyBoard Bloc for Fire Key Events
class LockScreenBloc {
  final _locked = BehaviorSubject<bool>();
  Stream<bool> get lockScreenStream => _locked.stream;

  // Assign Event for Pressed Key
  void setLocked(bool locked) {
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "POS Screen locked: $locked"));
    _locked.sink.add(locked);
  }

  // Dispose
  void dispose() {
    if (!_locked.isClosed) _locked.close();
  }
}

final lockScreenBloc = LockScreenBloc();
