/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/22/21, 9:53 AM
 * 
 * Editor: TM.Sakir
 * reason: implementing manager sign-off function for other terminals from current single terminal.. I create a new bloc for selected pending user and add the selected user in order to continue the manager sign off for that particular user
 */

import 'package:checkout/models/enum/signon_status.dart';
import 'package:checkout/models/pos/logged_user_result.dart';
import 'package:checkout/models/pos/user_hed.dart';
import 'package:rxdart/rxdart.dart';

class UserBloc {
  final _currentUser = BehaviorSubject<UserHed>();
  final _loginStatus = BehaviorSubject<SignOnStatus>();
  final _userDetails = BehaviorSubject<LoggedUserResult>();
  final _cashier = BehaviorSubject<String>();

  final _pendingUser = BehaviorSubject<UserHed>(); //new change
  Stream<UserHed> get pendingUserStream => _pendingUser.stream; //new change

  Stream<UserHed> get currentUserStream => _currentUser.stream;

  UserHed? get currentUser => _currentUser.valueOrNull;
  UserHed? get pendingUser => _pendingUser.valueOrNull; //new change

  LoggedUserResult? get userDetails => _userDetails.valueOrNull;
  SignOnStatus? get signOnStatus => _loginStatus.value;
  String? get signOnCashierForTemp => _cashier.value;

  void changeCurrentUser(UserHed userHed) {
    _currentUser.sink.add(userHed);
  }

  //new change
  void changePendingUser(UserHed userHed) {
    _pendingUser.sink.add(userHed);
  }

  void changeUserDetails(LoggedUserResult loggedUserResult) {
    _userDetails.sink.add(loggedUserResult);
  }

  void changeSignOnStatus(SignOnStatus status) {
    _loginStatus.sink.add(status);
  }

  void saveCashierCodeForTemp(String code) {
    _cashier.sink.add(code);
  }

  void clear() {
    _currentUser.sink.add(UserHed());
    _loginStatus.sink.add(SignOnStatus.None);
    _userDetails.sink.add(LoggedUserResult());
    _cashier.sink.add("");

    _pendingUser.sink.add(UserHed()); //new change
  }

  void dispose() {
    if (!_currentUser.isClosed) _currentUser.close();
    if (!_loginStatus.isClosed) _loginStatus.close();
    if (!_userDetails.isClosed) _userDetails.close();
    if (!_cashier.isClosed) _cashier.close();

    if (!_pendingUser.isClosed) _pendingUser.close(); //new change
  }
}

final userBloc = UserBloc();
