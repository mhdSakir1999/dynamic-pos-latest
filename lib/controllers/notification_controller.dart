/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/27/22, 5:27 PM
 */

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/models/pos/announcement_result.dart';
import 'package:checkout/models/pos/notification_results.dart';

import '../components/api_client.dart';

class NotificationController {
  Future<NotificationResults?> getNotifications() async {
    final res = await ApiClient.call(
        "notification/${userBloc.currentUser?.uSERHEDUSERCODE}?type=",
        ApiMethod.GET);

    if (res == null || res.data == null) return null;
    return NotificationResults.fromJson(res.data);
  }

  Future<AnnouncementResult?> getAnnouncements() async {
    final res = await ApiClient.call(
        "notification/announcement/all", ApiMethod.GET,
        authorize: false);
    if (res == null || res.data == null) return null;
    return AnnouncementResult.fromJson(res.data);
  }

  Future<void> readNotification(String id) async {
    await ApiClient.call("notification/", ApiMethod.POST,
        data: {"id": id, "userId": userBloc.currentUser?.uSERHEDUSERCODE});
  }
}
