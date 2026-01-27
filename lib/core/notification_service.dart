import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/entities/medication.dart';
import '../domain/enums/course_duration_unit.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;

Future<int> getNextNotificationId() async {
  final counterRef = _firestore
      .collection('notifIds')
      .doc('notification_id_counter');

  return _firestore.runTransaction<int>((transaction) async {
    final snapshot = await transaction.get(counterRef);

    int newValue;
    if (!snapshot.exists) {
      newValue = 1; // или 1000000
      transaction.set(counterRef, {'current': newValue});
    } else {
      final current = snapshot.data()?['current'] as int? ?? 0;
      newValue = current + 1;
      transaction.update(counterRef, {'current': newValue});
    }

    return newValue;
  });
}

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

// Resolve platform-specific implementation on demand (after initialization)
AndroidFlutterLocalNotificationsPlugin? get _androidImplementation =>
    notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

class NotificationService {
  /// Инициализация (один раз в main)
  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    await notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),

      onDidReceiveNotificationResponse: (response) {
        log('Notification tapped: ${response.payload}');
      },
    );

    // Create Android channel if possible
    // final androidImpl = _androidImplementation;
    // if (androidImpl != null) {
    //   const AndroidNotificationChannel channel = AndroidNotificationChannel(
    //     'med_channel',
    //     'Лекарства',
    //     description: 'Уведомления о приёме лекарств',
    //     importance: Importance.max,
    //   );
    //   await androidImpl.createNotificationChannel(channel);
    // }
  }

  /// Перепланировать ВСЕ активные лекарства
  static Future<void> rescheduleAll(List<Medication> meds) async {
    await notifications.cancelAll();

    for (final med in meds) {
      if (med.finishedAt == false) {
        await scheduleMedication(med);
      }
    }
  }

  static List<DateTime> getTimeListFromInterval(Medication med) {
    final dates = <DateTime>[];
    final int totalDays =
        med.durationTaking!.count *
        (med.durationTaking!.unit == CourseDurationUnit.day
            ? 1
            : med.durationTaking!.unit == CourseDurationUnit.week
            ? 7
            : 30);

    for (var i = 0; i < totalDays; i++) {
      for (var j = 0; j < med.intakeTime.length; j++) {
        final date = DateTime(
          med.startDate.year,
          med.startDate.month,
          med.startDate.day + i,
          med.intakeTime[j].time.hour,
          med.intakeTime[j].time.minute,
        );
        dates.add(date);
      }
    }
    return dates;
  }

  /// Запланировать уведомления для одного лекарства
  static Future<void> scheduleMedication(Medication med) async {
    final bool? grantedNotificationPermission = await _androidImplementation
        ?.requestNotificationsPermission();
    final bool? grantedAlarmPermission = await _androidImplementation
        ?.requestExactAlarmsPermission();

    log('Разрешение на уведомления: $grantedNotificationPermission');
    log('Разрешение на точные будильники: $grantedAlarmPermission');
    if (med.finishedAt) return;

    //final dates = _buildRollingSchedule(med, DateTime.now(), _planDaysAhead);
    final notificationIds = <int>[];
    try {
      final dates = getTimeListFromInterval(med);
      for (final date in dates) {
        if (date.isBefore(DateTime.now())) continue;
        final scheduledDate = tz.TZDateTime.from(date, tz.local);
        log('Scheduled TZDateTime: $scheduledDate');
        log('tz.local: ${tz.TZDateTime.now(tz.local)}');
        final notificationId = await getNextNotificationId();
        await notifications.zonedSchedule(
          notificationId,
          'Время принимать лекарство',
          med.name,
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'med_channel',
              'Лекарства',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        notificationIds.add(notificationId);
      }
      if (notificationIds.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('medications')
            .doc(med.id)
            .set({'notificationIds': notificationIds}, SetOptions(merge: true));
      }
    } catch (e) {
      log('Error scheduling notifications: $e');
    }
  }

  /// Отменить все уведомления одного лекарства
  static Future<void> cancelMedication(Medication med) async {
    for (final id in med.notificationIds ?? []) {
      await notifications.cancel(id);
    }
    await FirebaseFirestore.instance
        .collection('medications')
        .doc(med.id)
        .update({'notificationIds': []});
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final pending = await notifications.pendingNotificationRequests();
    for (var n in pending) {
      log(
        'ID: ${n.id}, Title: ${n.title}, Body: ${n.body}, Payload: ${n.payload}',
      );
    }
    await notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notification_channel_id',
          'Лекарства',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          autoCancel: false,
          ongoing: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'action_take', // уникальный id действия
              'Принял', // текст кнопки
              showsUserInterface: true, // открыть приложение при нажатии
            ),
            AndroidNotificationAction(
              'action_skip',
              'Пропустить',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'action_snooze',
              'Через 10 мин',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final currentDateTime = DateTime.now().add(Duration(seconds: 3));
    final scheduledDate = tz.TZDateTime.from(currentDateTime, tz.local);

    await notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_notification_channel_id',
          'Напоминания',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          autoCancel: false,
          ongoing: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'action_take', // уникальный id действия
              'Принял', // текст кнопки
              showsUserInterface: true, // открыть приложение при нажатии
            ),
            AndroidNotificationAction(
              'action_skip',
              'Пропустить',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'action_snooze',
              'Через 10 мин',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
