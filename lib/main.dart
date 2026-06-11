import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pillura_med/router/app_router.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/theme/app_theme.dart';
import 'domain/entities/linked_user_access.dart';
import 'domain/entities/user_link.dart';
import 'firebase_options.dart';
import 'core/notification_service.dart';
import 'presentation/providers/medication_provider.dart';
import 'presentation/providers/repository_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  TimezoneInfo? timezone = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timezone.identifier));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: AppRoot()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Pillura Med',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Root widget that has access to the current `Ref` and registers
/// lifecycle listener and performs initial sync using that `Ref`.
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  AppLifecycleListener? _listener;

  Future<void> _reconcileNotificationAlarms() async {
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

    await NotificationService.reconcileNotifications(
      currentUserId: userId,
      wardUserIds: wardIds,
    );
  }

  @override
  void initState() {
    super.initState();
    // Отложим проверку разрешений, инициализацию уведомлений и синхронизацию
    // до первого кадра: это позволяет корректно показывать диалоги.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(notificationServiceProvider).init();
      await _reconcileNotificationAlarms();
    });

    // Register lifecycle listener that uses the same ref
    _listener = AppLifecycleListener(
      onResume: () {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) return;
        ref
            .read(medicationNotifierProvider(userId).notifier)
            .syncTakenFromPrefs();
        unawaited(_reconcileNotificationAlarms());
      },
    );
  }

  @override
  void dispose() {
    _listener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (next != null && next != previous) {
        unawaited(_reconcileNotificationAlarms());
      } else if (previous != null && next == null) {
        unawaited(NotificationService.cancelAllScheduledNotifications());
      }
    });
    return const MyApp();
  }
}
