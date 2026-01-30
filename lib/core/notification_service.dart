import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillura_med/presentation/providers/medication_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/entities/intake_time.dart';
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

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref: ref);
});

class NotificationService {
  final Ref ref;
  NotificationService({required this.ref});

  /// Инициализация (один раз в main)
  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    await notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) =>
          foregroundNotificationHandler(response, ref),
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationHandler,
    );

    // Create Android channels
    final androidImpl = _androidImplementation;
    if (androidImpl != null) {
      // Channel для мгновенных уведомлений
      const AndroidNotificationChannel instantChannel =
          AndroidNotificationChannel(
            'instant_notification_channel_id',
            'Лекарства',
            description: 'Мгновенные уведомления о приёме лекарств',
            importance: Importance.max,
            enableVibration: true,
            enableLights: true,
          );
      await androidImpl.createNotificationChannel(instantChannel);

      // Channel для запланированных уведомлений
      const AndroidNotificationChannel reminderChannel =
          AndroidNotificationChannel(
            'reminder_notification_channel_id',
            'Напоминания',
            description: 'Запланированные напоминания о приёме лекарств',
            importance: Importance.max,
            enableVibration: true,
            enableLights: true,
          );
      await androidImpl.createNotificationChannel(reminderChannel);
    }
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
        final payloadData = jsonEncode({
          'medId': med.id,
          'hour': date.hour,
          'minute': date.minute,
        });
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
              priority: Priority.max,
              actions: <AndroidNotificationAction>[
                AndroidNotificationAction(
                  'action_take',
                  'Принял',
                  showsUserInterface: true,
                ),
                AndroidNotificationAction(
                  'action_skip',
                  'Пропустить',
                  showsUserInterface: false,
                ),
              ],
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payloadData,
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
    final payloadData = jsonEncode({
      'medId': 'T3eEE31N5mWCuNw1DM4V',
      'hour': 10,
      'minute': 54,
    });
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
          color: const Color(0xFF008080),
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'action_take',
              'Принял',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'action_skip',
              'Пропустить',
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payloadData,
    );
  }

  static Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final currentDateTime = DateTime.now().add(Duration(seconds: 3));
    final scheduledDate = tz.TZDateTime.from(currentDateTime, tz.local);
    final payloadData = jsonEncode({
      'medId': 'T3eEE31N5mWCuNw1DM4V',
      'hour': 10,
      'minute': 54,
    });
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
          autoCancel: false,
          ongoing: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'action_take',
              'Принял',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'action_skip',
              'Пропустить',
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payloadData,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

Future<void> foregroundNotificationHandler(
  NotificationResponse response,
  Ref ref,
) async {
  log('📲 onDidReceiveNotificationResponse: ${response.payload}');
  log('Action ID: ${response.actionId}');
  log('Payload: ${response.payload}');
  final payload = response.payload;
  if (response.actionId == null) {
    // Пользователь просто нажал на уведомление, без выбора действия
    return;
  }
  if (payload == null) {
    log('Payload null!');
    return;
  }

  Map<String, dynamic>? data;
  try {
    data = jsonDecode(payload) as Map<String, dynamic>;
  } catch (e) {
    return;
  }

  final medId = data['medId'];
  final hour = data['hour'];
  final minute = data['minute'];

  ref
      .read(medicationNotifierProvider.notifier)
      .updateIntakeTime(
        medId,
        IntakeTime(
          time: TimeOfDay(hour: hour, minute: minute),
        ),
        response.actionId == 'action_take' ? true : false,
      );
}

@pragma('vm:entry-point')
Future<void> backgroundNotificationHandler(
  NotificationResponse response,
) async {
  log('📲 backgroundNotificationHandler вызвана');
  log('Action ID: ${response.actionId}');
  log('Payload: ${response.payload}');

  final payload = response.payload;
  if (payload == null) {
    log('Payload null!');
    return;
  }

  Map<String, dynamic>? data;
  try {
    data = jsonDecode(payload) as Map<String, dynamic>;
  } catch (e) {
    return;
  }

  final medId = data['medId'];
  final hour = data['hour'];
  final minute = data['minute'];
  final prefs = await SharedPreferences.getInstance();
  final key = 'taken_${medId}_${hour}_$minute';

  if (response.actionId == 'action_take') {
    await prefs.setBool(key, true);
    log('✅ Сохранено в SharedPreferences: $key = true');
  } else if (response.actionId == 'action_skip') {
    await prefs.setBool(key, false);
  }
}
