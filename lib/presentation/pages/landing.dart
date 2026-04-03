import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';

class Landing extends ConsumerStatefulWidget {
  const Landing({super.key});

  @override
  ConsumerState<Landing> createState() => _LandingState();
}

class _LandingState extends ConsumerState<Landing> {
  late Future<void> _initFuture;
  @override
  void initState() {
    super.initState();
    // Инициализируем один раз и храним ссылку на Future
    _initFuture = _prepareApp();
  }

  Future<void> _prepareApp() async {
    await checkPermissionsAndProceed(ref, context);
    await ref.read(authNotifierProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Ошибка: ${snapshot.error}');

        if (snapshot.connectionState == ConnectionState.done) {
          // Навигация выносится в слушатель или срабатывает здесь
          _navigateToNextScreen();
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  void _navigateToNextScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(authNotifierProvider).value;
      user?.isAuthenticated == true
          ? context.go('/profilePage')
          : context.go('/welcomePage');
    });
  }
}

Future<void> checkPermissionsAndProceed(
  WidgetRef ref,
  BuildContext context,
) async {
  // Кроссплатформенная проверка разрешения на уведомления (iOS и Android 13+)
  final notifPermissionStatus = await Permission.notification.status;
  // Разрешение на точные будильники (Android)
  var scheduleStatus = await Permission.scheduleExactAlarm.status;

  if (context.mounted) {
    if (!notifPermissionStatus.isGranted || !scheduleStatus.isGranted) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Доступ к уведомлениям'),
          content: const Text(
            'Вам нужно предоставить доступ к уведомлениям, так как это основная функция приложения.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // Возвращаем false
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // OK
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (result == true) {
        if (!scheduleStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }
        if (!notifPermissionStatus.isGranted) {
          await Permission.notification.request();
        }
      }
      final newNotif = await Permission.notification.status;
      scheduleStatus = await Permission.scheduleExactAlarm.status;

      if (!newNotif.isGranted || !scheduleStatus.isGranted) {
        SystemNavigator.pop(); // закрыть приложение
        return;
      }
    }
  }
}
