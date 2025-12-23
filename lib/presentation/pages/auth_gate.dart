import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillura_med/presentation/pages/profile_page.dart';

import '../providers/auth_providers.dart';
import 'medication_page.dart';
import 'welcome_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (user) {
        if (user != null) return const ProfilePage();
        return WelcomePage();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) {
        log('Ошибка авторизации: $e, $st');
        return Scaffold(body: Center(child: Text('Ошибка авторизации: $e')));
      },
    );
  }
}
