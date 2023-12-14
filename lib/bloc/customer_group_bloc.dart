/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/12/21, 4:20 PM
 */

import 'package:checkout/controllers/customer_group_controller.dart';
import 'package:checkout/models/loyalty/customer_group_result.dart';
import 'package:checkout/models/loyalty/customer_loyalty_group_result.dart';
import 'package:checkout/models/loyalty/title_result.dart';
import 'package:rxdart/rxdart.dart';

class CustomerGroupBloc {
  final _loyaltyGroup = BehaviorSubject<List<CustomerLoyaltyGroupsList>>();
  final _customerGroup = BehaviorSubject<List<CustomerGroupsList>>();
  final _customerTitles = BehaviorSubject<List<Titles>>();
  Stream<List<CustomerLoyaltyGroupsList>> get loyaltyGroupSnapshot => _loyaltyGroup.stream;
  List<CustomerLoyaltyGroupsList> get loyaltyGroupList => _loyaltyGroup.stream.valueOrNull??<CustomerLoyaltyGroupsList>[];
  Stream<List<CustomerGroupsList>> get customerGroupSnapshot => _customerGroup.stream;
  List<CustomerGroupsList> get customerGroupList => _customerGroup.stream.valueOrNull??<CustomerGroupsList>[];
  Stream<List<Titles>> get customerTitleSnapshot => _customerTitles.stream;
  List<Titles> get customerTitleList => _customerTitles.stream.valueOrNull??<Titles>[];

  Future fetchAll() async {
    //  fetch loyalty group

    //  fetch customer group
    final CustomerGroupController controller = CustomerGroupController();
    final groups = (await controller.fetchCustomerGroups());
    final loyaltyGroups = (await controller.fetchCustomerLoyaltyGroups());
    final titles = (await controller.fetchTitles());
    if(groups != null)
      _customerGroup.sink.add(groups);
    if(loyaltyGroups != null)
      _loyaltyGroup.sink.add(loyaltyGroups);
    if(titles != null)
      _customerTitles.sink.add(titles);


  }

  void dispose() {
    _loyaltyGroup.close();
    _customerGroup.close();
    _customerTitles.close();
  }
}

final CustomerGroupBloc customerGroupBloc = CustomerGroupBloc();
