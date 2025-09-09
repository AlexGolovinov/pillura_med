import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            if (user == null) {
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
                        .signInWithEmail("test@mail.com", "password"),
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
