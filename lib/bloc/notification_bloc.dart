/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/27/22, 5:31 PM
 */

import 'package:checkout/controllers/notification_controller.dart';
import 'package:checkout/models/pos/announcement_result.dart';
import 'package:checkout/models/pos/notification_results.dart';
import 'package:rxdart/rxdart.dart';

class NotificationBloc {
  final _notifications = BehaviorSubject<NotificationResults?>();
  final _announcements = BehaviorSubject<List<Announcement>>();

  Stream<NotificationResults?> get notificationStream => _notifications.stream;
  Stream<List<Announcement>> get announcementStream => _announcements.stream;
  NotificationResults? get notificationList => _notifications.valueOrNull;

  void close() {
    _notifications.close();
    _announcements.close();
  }

  Future<void> getNotifications() async {
    final notifications = await NotificationController().getNotifications();
    if (notifications != null) _notifications.sink.add(notifications);
  }

  Future<void> getAnnouncements() async {
    final announcements = await NotificationController().getAnnouncements();
    if (announcements != null)
      _announcements.sink.add(announcements.announcement ?? []);
  }

  void removeAnnouncement(String id) {
    List<Announcement> allAnnouncements = _announcements.valueOrNull ?? [];
    int index = allAnnouncements.indexWhere((element) => element.annOID == id);
    if (index != -1) {
      allAnnouncements.removeAt(index);
      _announcements.sink.add(allAnnouncements);
    }
  }
}

final NotificationBloc notificationBloc = NotificationBloc();
