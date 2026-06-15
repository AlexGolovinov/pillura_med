import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/auth_choice_widgets.dart';
import '../../widgets/auth_form_widgets.dart';

/// Экран выбора после onboarding — только для первого входа.
/// Гость + регистрация. После выхода из аккаунта используется [AuthorizationPage].
class AuthChoicePage extends ConsumerWidget {
  const AuthChoicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user.isAuthenticated && context.mounted) {
            context.go('/profilePage');
          }
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
          child: authState.when(
            data: (user) {
              if (user.isAuthenticated) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthPageTitle(title: 'Я хочу...'),
                  const Spacer(),
                  AuthChoiceRow(
                    label: 'Я просто посмотреть',
                    buttonText: 'Гость',
                    illustration: const WalkingStickFigure(),
                    onPressed: isLoading
                        ? null
                        : () => ref
                              .read(authNotifierProvider.notifier)
                              .signInAnonymously(),
                  ),
                  const SizedBox(height: 36),
                  AuthChoiceRow(
                    label: 'Мне понравилось',
                    buttonText: 'Зарегистрироваться',
                    illustration: const HeartStickFigure(),
                    onPressed: isLoading
                        ? null
                        : () => context.push('/register'),
                  ),
                  const SizedBox(height: 48),
                  AuthChoiceRow(
                    label: 'У меня уже есть аккаунт',
                    buttonText: 'Войти',
                    illustration: const LoginStickFigure(),
                    onPressed: isLoading ? null : () => context.push('/login'),
                  ),
                  const Spacer(flex: 2),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Ошибка: $err')),
          ),
        ),
      ),
    );
  }
}
