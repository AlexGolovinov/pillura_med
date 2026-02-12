import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/presentation/providers/medication_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/entities/intake_rec/intake_record.dart';
import '../domain/entities/medication.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../router/app_router.dart';

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

  /// Запланировать уведомления для одного лекарства
  static Future<void> scheduleMedication(
    List<IntakeRecord> records,
    Medication med,
  ) async {
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
      // final dates = records.map((r) => r.scheduledDateTime).toList();
      for (final rec in records) {
        final date = rec.scheduledDateTime;
        if (date.isBefore(DateTime.now())) continue;
        final scheduledDate = tz.TZDateTime.from(date, tz.local);
        log('Scheduled TZDateTime: $scheduledDate');
        log('tz.local: ${tz.TZDateTime.now(tz.local)}');
        final payloadData = jsonEncode({
          'medId': med.id,
          'intakeRecordId': rec.id,
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

  Future<void> foregroundNotificationHandler(
    NotificationResponse response,
    Ref ref,
  ) async {
    final d0 = DateTime.now();
    log('📲 onDidReceiveNotificationResponse: ${response.payload}');
    log('Action ID: ${response.actionId}');
    log('Payload: ${response.payload}');
    final payload = response.payload;
    // Просто клик на уведомление — можно навигировать на общий список
    if (navigatorKey.currentContext != null) {
      GoRouter.of(
        navigatorKey.currentContext!,
      ).go('/profilePage'); // ваш роут на список лекарств
    } else {
      // Если context ещё не готов (редко), отложить
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentContext != null) {
          GoRouter.of(navigatorKey.currentContext!).go('/profilePage');
        }
      });
    }

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

    final recordId = data['intakeRecordId'];
    final record = await ref
        .read(medicationNotifierProvider.notifier)
        .getIntakeRecordById(recordId!);
    log(
      'Получена запись приёма: ${record.id} (затрачено: ${DateTime.now().difference(d0).inMilliseconds} ms)',
    );
    final t1 = DateTime.now();
    ref
        .read(medicationNotifierProvider.notifier)
        .updateIntakeTimeFromRecord(
          record,
          response.actionId == 'action_take' ? true : false,
        );
    log(
      'Приём помечен как ${response.actionId == 'action_take' ? "принят" : "пропущен"} (затрачено: ${DateTime.now().difference(t1).inMilliseconds} ms)',
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
    final recordId = data['intakeRecordId'];

    final prefs = await SharedPreferences.getInstance();
    final key = 'taken_${medId}_$recordId';

    if (response.actionId == 'action_take') {
      await prefs.setBool(key, true);
      log('✅ Сохранено в SharedPreferences: $key = true');
    } else if (response.actionId == 'action_skip') {
      await prefs.setBool(key, false);
    }
  }

  // Временная функция для тестирования мгновенных уведомлений
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final pending = await notifications.pendingNotificationRequests();
    final jsonRecord = IntakeRecord(
      id: 'zo9nPVQjqXsFLbPwTPfJ',
      medicationId: 'GEPejOCRiiiQswkv8Nkq',
      isTaken: false,
      scheduledDateTime: DateTime.parse('2026-02-11T10:45:00.000Z'),
    );
    final payloadData = jsonEncode({
      'medId': 'GEPejOCRiiiQswkv8Nkq',
      'intakeRecordId': jsonRecord.id,
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

  // Временная функция для тестирования запланированных уведомлений
  static Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final currentDateTime = DateTime.now().add(Duration(seconds: 3));
    final scheduledDate = tz.TZDateTime.from(currentDateTime, tz.local);
    final payloadData = jsonEncode({
      'medId': 'GEPejOCRiiiQswkv8Nkq',
      'intakeRecordId': "zo9nPVQjqXsFLbPwTPfJ",
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

  static Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pending = await notifications
        .pendingNotificationRequests();

    log('Всего запланировано уведомлений: ${pending.length}');

    if (pending.isEmpty) {
      log('Нет запланированных уведомлений');
      return;
    }

    for (final req in pending) {
      log('─' * 40);
      log('ID:          ${req.id}');
      log('Title:       ${req.title ?? "нет"}');
      log('Body:        ${req.body ?? "нет"}');
      log('Payload:     ${req.payload ?? "нет"}');
    }
  }
}
