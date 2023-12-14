/*
 * Copyright (c) 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 31/01/2022, 11:35
 */

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/extension/string_extension.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class BackupController{
  Future<void> backupStructures()async{
    EasyLoading.show(status: 'Updating...');
    final String user = userBloc.currentUser?.uSERHEDUSERCODE??'';
    final Response? response  = await ApiClient.call('backup/structure_changes?user=$user', ApiMethod.GET);

    bool? res = response?.data?['success']?.toString().parseBool();
    EasyLoading.dismiss();

    if(res == true){
      EasyLoading.showSuccess('easy_loading.success_update'.tr());
    }else{
      EasyLoading.showError('easy_loading.wrong_and_contact'.tr());
    }
  }
}
