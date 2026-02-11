import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/notification_service.dart';
import '../providers/auth_providers.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Авторизация")),
      body: Center(
        child: authState.when(
          data: (user) {
            if (!user.isAuthenticated) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => ref
                        .read(authNotifierProvider.notifier)
                        .signInAnonymously(),
                    child: Text("Войти как гость"),
                  ),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(authNotifierProvider.notifier)
                        .signInWithEmail("test@mail.com", "password!"),
                    child: Text("Войти с email"),
                  ),
                ],
              );
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Привет, ${user.isAnonymous ? "Гость" : user.email}"),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(authNotifierProvider.notifier).signOut(),
                    child: Text("Выйти"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      NotificationService.showInstantNotification(
                        id: 1,
                        title: "Тестовое уведомление",
                        body: "Это мгновенное уведомление",
                      );
                    },
                    child: Text("Мгновенное уведомление"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final permissions = await checkPermissions();
                      if (permissions) {
                        NotificationService.scheduleReminderNotification(
                          id: 1,
                          title: "Тестовое уведомление",
                          body: "Это запланированное уведомление",
                        );
                      }
                    },
                    child: Text("Запланированное уведомление"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final permissions = await checkPermissions();
                      if (permissions) {
                        NotificationService.checkPendingNotifications();
                      }
                    },
                    child: Text("Проверить активные уведомления"),
                  ),
                ],
              );
            }
          },
          loading: () => CircularProgressIndicator(),
          error: (err, _) => Text("Ошибка: $err"),
        ),
      ),
    );
  }
}

Future<bool> checkPermissions() async {
  if (await Permission.scheduleExactAlarm.isDenied) {
    // Это откроет специальную страницу настроек "Доступ к точным будильникам"
    await Permission.scheduleExactAlarm.request();
  }
  return await Permission.scheduleExactAlarm.isGranted;
}
