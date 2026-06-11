import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pillura_med/domain/enums/course_duration_unit.dart';
import 'package:pillura_med/domain/enums/dosage_type.dart';
import 'package:pillura_med/presentation/providers/medication_provider.dart';
import 'package:pillura_med/presentation/providers/repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/entities/intake_rec/intake_record.dart';
import '../domain/entities/medication.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/linked_user_access.dart';
import '../domain/entities/user_link.dart';
import '../presentation/providers/notification_provider.dart';
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

@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(
  NotificationResponse response,
) async {
  log('📲 notificationBackgroundHandler called');
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
    log('Failed to decode payload: $e');
    return;
  }

  final medId = data['medId'];
  final recordId = data['intakeRecordId'];

  final prefs = await SharedPreferences.getInstance();
  final key = 'taken_${medId}_$recordId';

  if (response.actionId == 'action_take') {
    await prefs.setBool(key, true);
    log('✅ Saved to SharedPreferences: $key = true');
  } else if (response.actionId == 'action_skip') {
    await prefs.setBool(key, false);
  }
}

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

// Resolve platform-specific implementation on demand (after initialization)

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final plugin = ref.read(flutterLocalNotificationsProvider);
  return NotificationService(ref: ref, plugin: plugin);
});

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;
  final Ref ref;
  NotificationService({required this.ref, required this.plugin});

  AndroidFlutterLocalNotificationsPlugin? get _androidImplementation => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

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
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
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

  /// Пересобрать локальные alarm'ы для своего профиля и подопечных (ward).
  static Future<void> reconcileNotifications({
    required String currentUserId,
    required List<String> wardUserIds,
  }) async {
    try {
      final profileIds = {currentUserId, ...wardUserIds};
      final now = DateTime.now();
      final managedMeds = <Medication>[];

      for (final profileId in profileIds) {
        final snapshot = await _firestore
            .collection('medications')
            .where('userId', isEqualTo: profileId)
            .where('repeatRule.type')
            .get();
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            final med = Medication.fromJson({...data, 'id': data['id'] ?? doc.id});
            if (_isMedicationActiveForReminders(med, now)) {
              managedMeds.add(med);
            }
          } catch (e) {
            log('reconcile: пропуск лекарства ${doc.id}: $e');
          }
        }
      }

      final requiredEntries =
          <String, ({Medication med, IntakeRecord record})>{};

      for (final med in managedMeds) {
        final intakesSnapshot = await _firestore
            .collection('intake_records')
            .where('medicationId', isEqualTo: med.id)
            .get();
        for (final doc in intakesSnapshot.docs) {
          final record = IntakeRecord.fromJson({...doc.data(), 'id': doc.id});
          if (record.scheduledDateTime.isAfter(now) && record.isTaken == null) {
            requiredEntries['${med.id}_${record.id}'] = (
              med: med,
              record: record,
            );
          }
        }
      }

      final pending = await notifications.pendingNotificationRequests();
      final pendingKeys = <String>{};
      var cancelledCount = 0;

      for (final req in pending) {
        final payload = req.payload;
        if (payload == null) continue;

        Map<String, dynamic> data;
        try {
          data = jsonDecode(payload) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

        final medId = data['medId'] as String?;
        final recordId = data['intakeRecordId'] as String?;
        if (medId == null || recordId == null) continue;

        final key = '${medId}_$recordId';
        if (requiredEntries.containsKey(key)) {
          if (pendingKeys.contains(key)) {
            await notifications.cancel(req.id);
            cancelledCount++;
          } else {
            pendingKeys.add(key);
          }
        } else {
          await notifications.cancel(req.id);
          cancelledCount++;
        }
      }

      var scheduledCount = 0;
      for (final entry in requiredEntries.entries) {
        if (pendingKeys.contains(entry.key)) continue;
        await _scheduleIntakeNotification(
          med: entry.value.med,
          record: entry.value.record,
          isWard: entry.value.med.userId != currentUserId,
        );
        scheduledCount++;
      }

      log(
        'reconcileNotifications: профилей=${profileIds.length} '
        '(ward=${wardUserIds.length}), '
        'активных лекарств=${managedMeds.length}, нужно=${requiredEntries.length}, '
        'оставлено=${pendingKeys.length}, отменено=$cancelledCount, '
        'запланировано=$scheduledCount',
      );
    } catch (e, st) {
      log('reconcileNotifications error: $e\n$st');
    }
  }

  static bool _isMedicationActiveForReminders(Medication med, DateTime now) {
    if (med.finishedAt) return false;
    if (med.durationTaking == null) return true;

    final startDate = DateTime(
      med.startDate.year,
      med.startDate.month,
      med.startDate.day,
    );
    final totalDays =
        med.durationTaking!.count *
        (med.durationTaking!.unit == CourseDurationUnit.day
            ? 1
            : med.durationTaking!.unit == CourseDurationUnit.week
            ? 7
            : 30);
    final courseEnd = startDate.add(Duration(days: totalDays - 1));
    final today = DateTime(now.year, now.month, now.day);
    return !courseEnd.isBefore(today);
  }

  /// Вызов reconcile для текущего пользователя и его ward-связей.
  static Future<void> triggerNotificationReconcile(Ref ref) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) return;

    final repo = ref.read(authFRepositoryProvider);
    final linkedResult = await repo.getLinkedUsersForUser(userId);
    final linked = linkedResult.fold(
      (_) => <LinkedUserAccess>[],
      (users) => users,
    );
    final wardIds = linked
        .where((link) => link.linkType == UserLinkType.ward)
        .map((link) => link.user.uid)
        .toList();

    await reconcileNotifications(
      currentUserId: userId,
      wardUserIds: wardIds,
    );
  }

  static Future<void> _scheduleIntakeNotification({
    required Medication med,
    required IntakeRecord record,
    required bool isWard,
  }) async {
    if (record.id == null) return;

    final scheduledDate = tz.TZDateTime.from(record.scheduledDateTime, tz.local);
    final payloadData = jsonEncode({
      'medId': med.id,
      'intakeRecordId': record.id,
    });
    final notificationId = await getNextNotificationId();
    final title =
        '${med.name} - ${med.dosage} ${med.dosageType.shortLabel}';
    final body = isWard
        ? 'Подопечный: время принимать лекарство'
        : 'Время принимать лекарство';

    await notifications.zonedSchedule(
      notificationId,
      title,
      body,
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
  }

  /// Отменить все уведомления одного лекарства.
  /// ID берутся из Firestore и дополнительно ищутся среди pending по payload.
  static Future<void> cancelMedication(String medId) async {
    final doc = await FirebaseFirestore.instance
        .collection('medications')
        .doc(medId)
        .get();

    final storedIds = doc.data()?['notificationIds'] as List<dynamic>?;
    final cancelledIds = <int>{};

    for (final id in storedIds ?? const <dynamic>[]) {
      final notificationId = id as int;
      cancelledIds.add(notificationId);
      await notifications.cancel(notificationId);
    }

    final pending = await notifications.pendingNotificationRequests();
    for (final req in pending) {
      final payload = req.payload;
      if (payload == null) continue;
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        if (data['medId'] == medId && cancelledIds.add(req.id)) {
          await notifications.cancel(req.id);
        }
      } catch (_) {}
    }

    if (doc.exists) {
      await FirebaseFirestore.instance
          .collection('medications')
          .doc(medId)
          .update({'notificationIds': []});
    }

    log(
      'Отменено уведомлений для $medId: ${cancelledIds.length}',
    );
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

    final recordId = data['intakeRecordId'] as String?;
    if (recordId == null) {
      log('Payload does not contain intakeRecordId');
      return;
    }
    final medId = data['medId'] as String?;
    String? targetUserId = ref.read(currentUserIdProvider);
    if (medId != null) {
      final medDoc = await _firestore
          .collection('medications')
          .doc(medId)
          .get();
      final ownerId = medDoc.data()?['userId'] as String?;
      if (ownerId != null && ownerId.isNotEmpty) {
        targetUserId = ownerId;
      }
    }
    if (targetUserId == null) {
      log('Cannot resolve target user for notification action');
      return;
    }
    final notifier = ref.read(
      medicationNotifierProvider(targetUserId).notifier,
    );
    final record = await notifier.getIntakeRecordById(recordId);
    log(
      'Получена запись приёма: ${record.id} (затрачено: ${DateTime.now().difference(d0).inMilliseconds} ms)',
    );
    final t1 = DateTime.now();
    await notifier.updateIntakeTimeFromRecord(
      record,
      response.actionId == 'action_take' ? true : false,
    );
    log(
      'Приём помечен как ${response.actionId == 'action_take' ? "принят" : "пропущен"} (затрачено: ${DateTime.now().difference(t1).inMilliseconds} ms)',
    );
  }

  // removed instance background handler — use top-level handler below

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

  /// Отменить все запланированные уведомления (при выходе из аккаунта).
  static Future<void> cancelAllScheduledNotifications() async {
    await notifications.cancelAll();
    log('cancelAllScheduledNotifications: все alarm сняты');
  }

  static Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pending = await notifications
        .pendingNotificationRequests();

    log('Всего запланировано уведомлений: ${pending.length}');

    if (pending.isEmpty) {
      log('Нет запланированных уведомлений');
      return;
    }

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    for (final req in pending) {
      log('─' * 40);
      log('ID:          ${req.id}');
      log('Title:       ${req.title ?? "нет"}');
      log('Body:        ${req.body ?? "нет"}');
      log('Payload:     ${req.payload ?? "нет"}');
      log('Когда:       ${await _scheduledTimeLabel(req.payload, dateFormat)}');
    }
  }

  static Future<String> _scheduledTimeLabel(
    String? payload,
    DateFormat dateFormat,
  ) async {
    if (payload == null) return 'нет payload';

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final recordId = data['intakeRecordId'] as String?;
      if (recordId == null) return 'нет intakeRecordId в payload';

      final doc = await _firestore
          .collection('intake_records')
          .doc(recordId)
          .get();
      if (!doc.exists) return 'запись приёма не найдена';

      final raw = doc.data()?['scheduledDateTime'];
      if (raw is! String) return 'нет scheduledDateTime';

      final scheduledAt = DateTime.parse(raw);
      return dateFormat.format(scheduledAt);
    } catch (e) {
      return 'ошибка чтения времени: $e';
    }
  }
}
