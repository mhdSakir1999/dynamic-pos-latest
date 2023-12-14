/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 11/23/21, 3:40 PM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/models/loyalty/customer_group_result.dart';
import 'package:checkout/models/loyalty/customer_loyalty_group_result.dart';
import 'package:checkout/models/loyalty/title_result.dart';

class CustomerGroupController{
  Future<List<CustomerLoyaltyGroupsList>?> fetchCustomerLoyaltyGroups()async{
    final res = await LoyaltyApiClient.call('group/loyalty', ApiMethod.GET);
    if(res?.data != null){
      return CustomerLoyaltyGroupResult.fromJson(res!.data).customerLoyaltyGroups;
    }
    return null;
  }
  Future<List<CustomerGroupsList>?> fetchCustomerGroups()async{
    final res = await LoyaltyApiClient.call('group/customer', ApiMethod.GET);
    if(res?.data != null){
      return CustomerGroupResult.fromJson(res!.data).customerGroups;
    }
    return null;
  }
  Future<List<Titles>?> fetchTitles()async{
    final res = await LoyaltyApiClient.call('group/title', ApiMethod.GET);
    if(res?.data != null){
      return TitleResult.fromJson(res!.data).titles;
    }
    return null;
  }
}