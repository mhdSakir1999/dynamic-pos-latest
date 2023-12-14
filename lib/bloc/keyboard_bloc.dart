/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/23/21, 10:57 AM
 */

import 'package:checkout/models/enum/keyboard_type.dart';
import 'package:rxdart/rxdart.dart';

// KeyBoard Bloc for Fire Key Events
class KeyBoardBloc {
  final _pressKey = BehaviorSubject<keyType>();
  Stream<keyType> get currentPressKeyStream => _pressKey.stream;

  // Assign Event for Pressed Key
  void setKey(keyType pressedKey) {
    _pressKey.sink.add(pressedKey);
  }

  // Dispose
  void dispose() {
    if (!_pressKey.isClosed) _pressKey.close();
  }
}

final keyBoardBloc = KeyBoardBloc();
