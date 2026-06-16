import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final flutterLocalNotificationsProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

/// Целевой профиль (свой или подопечного) после действия из уведомления.
class PendingNotificationProfileIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setProfileId(String? userId) => state = userId;

  void clear() => state = null;
}

final pendingNotificationProfileIdProvider =
    NotifierProvider<PendingNotificationProfileIdNotifier, String?>(
      PendingNotificationProfileIdNotifier.new,
    );
