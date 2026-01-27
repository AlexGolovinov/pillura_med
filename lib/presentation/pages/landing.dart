import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';

class Landing extends ConsumerWidget {
  const Landing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      authState.maybeWhen(
        data: (user) {
          if (user.isAuthenticated) {
            context.go('/profilePage');
          } else {
            context.go('/welcomePage');
          }
        },
        orElse: () {},
      );
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // можно логотип/текст
      ),
    );
  }
}
