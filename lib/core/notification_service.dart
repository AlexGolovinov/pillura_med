import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'course_schedule.dart';
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

String _intakeActionPrefsKey(String medId, String recordId) =>
    'taken_${medId}_$recordId';

({String medId, String recordId})? _parseIntakeActionPrefsKey(String key) {
  if (!key.startsWith('taken_')) return null;
  final payload = key.substring('taken_'.length);
  final sep = payload.lastIndexOf('_');
  if (sep <= 0) return null;
  return (
    medId: payload.substring(0, sep),
    recordId: payload.substring(sep + 1),
  );
}

Future<void> _saveIntakeActionToPrefs({
  required String medId,
  required String recordId,
  required bool isTaken,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _intakeActionPrefsKey(medId, recordId);
  await prefs.setBool(key, isTaken);
  log('✅ Saved to SharedPreferences: $key = $isTaken');
}

Future<void> _removeIntakeActionFromPrefs({
  required String medId,
  required String recordId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_intakeActionPrefsKey(medId, recordId));
}

Map<String, dynamic>? _decodeNotificationPayload(String? payload) {
  if (payload == null) return null;
  try {
    return jsonDecode(payload) as Map<String, dynamic>;
  } catch (e) {
    log('Failed to decode payload: $e');
    return null;
  }
}

@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(
  NotificationResponse response,
) async {
  log('📲 notificationBackgroundHandler called');
  log('Action ID: ${response.actionId}');
  log('Payload: ${response.payload}');

  final data = _decodeNotificationPayload(response.payload);
  if (data == null) {
    log('Payload null or invalid!');
    return;
  }

  final medId = data['medId'] as String?;
  final recordId = data['intakeRecordId'] as String?;
  if (medId == null || recordId == null) return;

  if (response.actionId == 'action_take') {
    await _saveIntakeActionToPrefs(
      medId: medId,
      recordId: recordId,
      isTaken: true,
    );
  } else if (response.actionId == 'action_skip') {
    await _saveIntakeActionToPrefs(
      medId: medId,
      recordId: recordId,
      isTaken: false,
    );
  }
}

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

// Resolve platform-specific implementation on demand (after initialization)

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final plugin = ref.read(flutterLocalNotificationsProvider);
  return NotificationService(ref: ref, plugin: plugin);
});

NotificationResponse? _pendingLaunchNotificationResponse;
String? _pendingNavigationUserId;

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;
  final Ref ref;
  NotificationService({required this.ref, required this.plugin});

  static const String _darwinCategoryId = 'medication_intake_actions';
  static const String _intakePayloadVersion = '3';
  static final Map<String, String> _userNameCache = <String, String>{};

  static String? get pendingNavigationUserId => _pendingNavigationUserId;

  static String _formatIntakeNotificationTitle({
    required String medicationName,
    required double dosage,
    required String dosageLabel,
  }) =>
      '$medicationName - $dosage $dosageLabel';

  static String _formatIntakeNotificationBody({
    required String profileName,
    required DateTime intakeTime,
  }) {
    final timeLabel = DateFormat('HH:mm').format(intakeTime);
    return 'кому: $profileName / время: $timeLabel';
  }

  static NotificationDetails _intakeNotificationDetails({
    required String channelId,
    String channelName = 'Лекарства',
    String? channelDescription,
    bool ongoing = false,
    bool autoCancel = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        ongoing: ongoing,
        autoCancel: autoCancel,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'action_take',
            '🟢 Принял',
            showsUserInterface: true,
            titleColor: Color(0xFF1B5E20),
          ),
          AndroidNotificationAction(
            'action_skip',
            '🔴 Пропустить',
            showsUserInterface: false,
            titleColor: Color(0xFFC62828),
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(categoryIdentifier: _darwinCategoryId),
    );
  }

  static Future<String?> _resolveUserName(String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return null;

    final cached = _userNameCache[trimmed];
    if (cached != null) return cached;

    try {
      final doc = await _firestore.collection('users').doc(trimmed).get();
      final name = doc.data()?['name'] as String?;
      final normalized = name?.trim();
      if (normalized == null || normalized.isEmpty) return null;
      _userNameCache[trimmed] = normalized;
      return normalized;
    } catch (e) {
      log('Failed to resolve user name for $trimmed: $e');
      return null;
    }
  }

  static Future<String?> resolveMedicationOwnerId(String medId) async {
    final medDoc = await _firestore.collection('medications').doc(medId).get();
    final ownerId = medDoc.data()?['userId'] as String?;
    if (ownerId != null && ownerId.isNotEmpty) {
      return ownerId;
    }
    return null;
  }

  /// Синхронизирует отметки приёма из SharedPreferences (фоновые действия).
  /// Работает и для своего профиля, и для подопечных.
  Future<void> syncPendingIntakeActionsFromPrefs() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null || currentUserId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('taken_'))
        .toList();
    if (keys.isEmpty) return;

    for (final key in keys) {
      final parsed = _parseIntakeActionPrefsKey(key);
      if (parsed == null) continue;

      final isTaken = prefs.getBool(key);
      if (isTaken == null) continue;

      var targetUserId = currentUserId;
      final ownerId = await resolveMedicationOwnerId(parsed.medId);
      if (ownerId != null) {
        targetUserId = ownerId;
      }

      try {
        final notifier = ref.read(
          medicationNotifierProvider(targetUserId).notifier,
        );
        final record = await notifier.getIntakeRecordById(parsed.recordId);
        await notifier.updateIntakeTimeFromRecord(record, isTaken);
        await prefs.remove(key);
        log(
          'syncPendingIntakeActionsFromPrefs: $key → '
          '${isTaken ? "принят" : "пропущен"} (user=$targetUserId)',
        );
      } catch (e) {
        log('syncPendingIntakeActionsFromPrefs error for $key: $e');
      }
    }
  }

  Future<void> processPendingLaunchAndNavigation() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null || currentUserId.isEmpty) return;

    await syncPendingIntakeActionsFromPrefs();

    final pendingResponse = _pendingLaunchNotificationResponse;
    if (pendingResponse != null) {
      _pendingLaunchNotificationResponse = null;
      await processNotificationResponse(pendingResponse);
      return;
    }

    final pendingUserId = _pendingNavigationUserId;
    if (pendingUserId != null) {
      _pendingNavigationUserId = null;
      _navigateToProfile(pendingUserId);
    }
  }

  void _rememberProfileNavigation(String targetUserId) {
    final currentUserId = ref.read(currentUserIdProvider);
    if (targetUserId.isEmpty) return;

    ref.read(pendingNotificationProfileIdProvider.notifier).setProfileId(
      targetUserId,
    );
    if (currentUserId != null && targetUserId != currentUserId) {
      _pendingNavigationUserId = targetUserId;
    } else {
      _pendingNavigationUserId = null;
    }
  }

  void _navigateToProfile(String? targetUserId) {
    if (targetUserId == null || targetUserId.isEmpty) return;

    _rememberProfileNavigation(targetUserId);

    final currentUserId = ref.read(currentUserIdProvider);

    void go() {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final router = GoRouter.of(context);
      if (currentUserId != null && targetUserId != currentUserId) {
        router.go('/profilePage?profileUserId=$targetUserId');
      } else {
        router.go('/profilePage');
      }
    }

    if (navigatorKey.currentContext != null) {
      go();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => go());
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidImplementation => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Инициализация (один раз в main)
  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final List<DarwinNotificationCategory> darwinNotificationCategories =
        <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        _darwinCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'action_take',
            '🟢 Принял',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            'action_skip',
            '🔴 Пропустить',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.destructive,
            },
          ),
        ],
      ),
    ];

    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      notificationCategories: darwinNotificationCategories,
    );

    await notifications.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) =>
          foregroundNotificationHandler(response, ref),
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    final launchDetails = await notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response != null) {
        _pendingLaunchNotificationResponse = response;
        log('📲 App launched from notification: ${response.payload}');

        final data = _decodeNotificationPayload(response.payload);
        final medId = data?['medId'] as String?;
        if (medId != null) {
          final ownerId = await resolveMedicationOwnerId(medId);
          if (ownerId != null) {
            _rememberProfileNavigation(ownerId);
          }
        }
      }
    }

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

        // Если формат уведомления устарел (после изменений в UI/тексте),
        // отменяем и дадим расписателю создать новое уведомление.
        final formatVersion = data['formatVersion'] as String?;
        if (formatVersion != _intakePayloadVersion) {
          await notifications.cancel(req.id);
          cancelledCount++;
          continue;
        }

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
    return isMedicationCourseActive(med, now);
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
  }) async {
    if (record.id == null) return;

    final scheduledDate = tz.TZDateTime.from(record.scheduledDateTime, tz.local);
    final payloadData = jsonEncode({
      'medId': med.id,
      'intakeRecordId': record.id,
      'formatVersion': _intakePayloadVersion,
    });
    final notificationId = await getNextNotificationId();

    // Формат уведомления:
    // 1) "Лекарство - дозировка"
    // 2) "кому: <имя>" + "когда: <HH:mm>"
    final ownerName = await _resolveUserName(med.userId) ?? 'Профиль';
    final intakeTime = tz.TZDateTime.from(record.scheduledDateTime, tz.local);
    final title = _formatIntakeNotificationTitle(
      medicationName: med.name,
      dosage: med.dosage,
      dosageLabel: med.dosageType.shortLabel,
    );
    final body = _formatIntakeNotificationBody(
      profileName: ownerName,
      intakeTime: intakeTime,
    );

    await notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      _intakeNotificationDetails(channelId: 'med_channel'),
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
    final pending = _pendingLaunchNotificationResponse;
    if (pending != null &&
        pending.payload == response.payload &&
        pending.actionId == response.actionId) {
      log('Skipping duplicate launch notification response');
      return;
    }
    await processNotificationResponse(response);
  }

  Future<void> processNotificationResponse(NotificationResponse response) async {
    final d0 = DateTime.now();
    log('📲 processNotificationResponse: ${response.payload}');
    log('Action ID: ${response.actionId}');

    final data = _decodeNotificationPayload(response.payload);
    final currentUserId = ref.read(currentUserIdProvider);

    String? targetUserId = currentUserId;
    if (data != null) {
      final medId = data['medId'] as String?;
      if (medId != null) {
        final ownerId = await resolveMedicationOwnerId(medId);
        if (ownerId != null) {
          targetUserId = ownerId;
        }
      }
    }

    if (response.actionId == null) {
      if (currentUserId != null) {
        _navigateToProfile(targetUserId);
      } else if (targetUserId != null) {
        _rememberProfileNavigation(targetUserId);
      }
      return;
    }

    if (data == null) {
      log('Payload null or invalid!');
      return;
    }

    final recordId = data['intakeRecordId'] as String?;
    final medId = data['medId'] as String?;
    if (recordId == null || medId == null) {
      log('Payload does not contain intakeRecordId or medId');
      return;
    }

    final isTaken = response.actionId == 'action_take';

    if (currentUserId == null) {
      await _saveIntakeActionToPrefs(
        medId: medId,
        recordId: recordId,
        isTaken: isTaken,
      );
      if (targetUserId != null) {
        _rememberProfileNavigation(targetUserId);
      }
      log('Auth not ready — saved to prefs, navigation deferred');
      return;
    }

    final notifier = ref.read(
      medicationNotifierProvider(targetUserId!).notifier,
    );
    final record = await notifier.getIntakeRecordById(recordId);
    log(
      'Получена запись приёма: ${record.id} (затрачено: ${DateTime.now().difference(d0).inMilliseconds} ms)',
    );
    final t1 = DateTime.now();
    await notifier.updateIntakeTimeFromRecord(record, isTaken);
    await _removeIntakeActionFromPrefs(medId: medId, recordId: recordId);
    log(
      'Приём помечен как ${isTaken ? "принят" : "пропущен"} (затрачено: ${DateTime.now().difference(t1).inMilliseconds} ms)',
    );
    _navigateToProfile(targetUserId);
  }

  // removed instance background handler — use top-level handler below

  // Временная функция для тестирования мгновенных уведомлений
  static Future<void> showInstantNotification({
    required int id,
    required String profileName,
    String medicationName = 'Аспирин',
    double dosage = 1,
    String dosageLabel = 'таб.',
    DateTime? intakeTime,
  }) async {
    final scheduledAt = intakeTime ?? DateTime.now();
    final title = _formatIntakeNotificationTitle(
      medicationName: medicationName,
      dosage: dosage,
      dosageLabel: dosageLabel,
    );
    final body = _formatIntakeNotificationBody(
      profileName: profileName,
      intakeTime: scheduledAt,
    );
    final payloadData = jsonEncode({
      'medId': 'GEPejOCRiiiQswkv8Nkq',
      'intakeRecordId': 'zo9nPVQjqXsFLbPwTPfJ',
      'formatVersion': _intakePayloadVersion,
    });

    await notifications.show(
      id,
      title,
      body,
      _intakeNotificationDetails(
        channelId: 'instant_notification_channel_id',
        channelDescription: 'Мгновенные уведомления о приёме лекарств',
      ),
      payload: payloadData,
    );
  }

  // Временная функция для тестирования запланированных уведомлений
  static Future<void> scheduleReminderNotification({
    required int id,
    required String profileName,
    String medicationName = 'Аспирин',
    double dosage = 1,
    String dosageLabel = 'таб.',
    DateTime? intakeTime,
  }) async {
    final scheduledAt = intakeTime ?? DateTime.now().add(const Duration(seconds: 3));
    final scheduledDate = tz.TZDateTime.from(scheduledAt, tz.local);
    final title = _formatIntakeNotificationTitle(
      medicationName: medicationName,
      dosage: dosage,
      dosageLabel: dosageLabel,
    );
    final body = _formatIntakeNotificationBody(
      profileName: profileName,
      intakeTime: scheduledAt,
    );
    final payloadData = jsonEncode({
      'medId': 'GEPejOCRiiiQswkv8Nkq',
      'intakeRecordId': 'zo9nPVQjqXsFLbPwTPfJ',
      'formatVersion': _intakePayloadVersion,
    });

    await notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _intakeNotificationDetails(
        channelId: 'reminder_notification_channel_id',
        channelName: 'Напоминания',
        channelDescription: 'Запланированные напоминания о приёме лекарств',
        ongoing: true,
        autoCancel: false,
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
