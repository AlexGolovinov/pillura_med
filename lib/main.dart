import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pillura_med/router/app_router.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'core/notification_service.dart';
import 'presentation/providers/medication_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // Отложим проверку разрешений, инициализацию уведомлений и синхронизацию
    // до первого кадра: это позволяет корректно показывать диалоги.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Await permission check so subsequent initialization waits for user's choice
      await ref.read(notificationServiceProvider).init();
    });

    // Register lifecycle listener that uses the same ref
    _listener = AppLifecycleListener(
      onResume: () {
        ref.read(medicationNotifierProvider.notifier).syncTakenFromPrefs();
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
    return const MyApp();
  }
}
