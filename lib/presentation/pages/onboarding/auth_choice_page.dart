import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';

/// Экран выбора после onboarding — только для первого входа.
/// Гость + регистрация. После выхода из аккаунта используется [WelcomePage].
class AuthChoicePage extends ConsumerWidget {
  const AuthChoicePage({super.key});

  static const _brandColor = Color(0xFF202D85);
  static const _labelColor = Color(0xFF7E9A40);
  static const _accentColor = Color(0xFFE4A46A);

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
                  Text(
                    'Я хочу...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _brandColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                  ),
                  const Spacer(),
                  _AuthChoiceRow(
                    label: 'Я просто посмотреть',
                    buttonText: 'Гость',
                    illustration: const _WalkingStickFigure(),
                    onPressed: isLoading
                        ? null
                        : () => ref
                              .read(authNotifierProvider.notifier)
                              .signInAnonymously(),
                  ),
                  const SizedBox(height: 36),
                  _AuthChoiceRow(
                    label: 'Мне понравилось',
                    buttonText: 'Зарегистрироваться',
                    illustration: const _HeartStickFigure(),
                    onPressed: isLoading
                        ? null
                        : () => context.push('/register'),
                  ),
                  const SizedBox(height: 48),
                  _AuthChoiceRow(
                    label: 'У меня уже есть аккаунт',
                    buttonText: 'Войти',
                    illustration: const _LoginStickFigure(),
                    onPressed: isLoading
                        ? null
                        : () => context.push('/login'),
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

class _AuthChoiceRow extends StatelessWidget {
  final String label;
  final String buttonText;
  final Widget illustration;
  final VoidCallback? onPressed;

  const _AuthChoiceRow({
    required this.label,
    required this.buttonText,
    required this.illustration,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        illustration,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AuthChoicePage._labelColor,
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AuthChoicePage._brandColor,
                  side: const BorderSide(color: AuthChoicePage._brandColor),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalkingStickFigure extends StatelessWidget {
  const _WalkingStickFigure();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 18,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 2,
                  color: AuthChoicePage._accentColor,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: 2,
                  color: AuthChoicePage._accentColor,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 2,
                  color: AuthChoicePage._accentColor,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.directions_walk_rounded,
            size: 42,
            color: Color(0xFF9E9E9E),
          ),
        ],
      ),
    );
  }
}

class _HeartStickFigure extends StatelessWidget {
  const _HeartStickFigure();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            top: 8,
            child: Icon(
              Icons.favorite_border_rounded,
              size: 22,
              color: AuthChoicePage._accentColor,
            ),
          ),
          const Icon(
            Icons.accessibility_new_rounded,
            size: 42,
            color: Color(0xFF9E9E9E),
          ),
        ],
      ),
    );
  }
}

class _LoginStickFigure extends StatelessWidget {
  const _LoginStickFigure();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 2,
            top: 12,
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: AuthChoicePage._accentColor,
            ),
          ),
          const Icon(
            Icons.person_outline_rounded,
            size: 42,
            color: Color(0xFF9E9E9E),
          ),
        ],
      ),
    );
  }
}
