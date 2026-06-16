import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pillura_med/core/input_limits.dart';
import 'package:pillura_med/core/listen_errors.dart';
import 'package:pillura_med/core/notification_service.dart';
import 'package:pillura_med/presentation/widgets/input_block.dart';

import '../providers/auth_providers.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  static const _brandColor = Color(0xFF202D85);

  final _formKey = GlobalKey<FormState>();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  String? _name;
  String? _email;
  String? _password;
  String _passwordInput = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _isSigningOut = false;

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _focusNext(FocusNode nextFocus) => nextFocus.requestFocus();

  void _closeKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _upgradeGuestAccount() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authNotifierProvider.notifier).upgradeAnonymousAccount(
            _email!.trim(),
            _password!.trim(),
            _name!.trim(),
          );
      if (!mounted) return;
      final authUser = ref.read(authNotifierProvider).value;
      if (authUser != null &&
          authUser.isAuthenticated &&
          !authUser.isAnonymous) {
        _showMessage('Аккаунт сохранён. Ваши данные остались с вами.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) context.go('/welcomePage');
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;

    listenErrors(context, ref, authNotifierProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мой аккаунт')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isGuest = user.isAnonymous;
    final displayName = (user.name ?? '').trim().isNotEmpty
        ? user.name!.trim()
        : (isGuest ? 'Гость' : 'Пользователь');

    return Scaffold(
          appBar: AppBar(
            title: const Text('Мой аккаунт'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFE8EFFB),
                          child: Icon(
                            isGuest
                                ? Icons.person_outline_rounded
                                : Icons.account_circle_outlined,
                            size: 48,
                            color: _brandColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _brandColor,
                              ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            NotificationService.showInstantNotification(
                              id: 1,
                              profileName: displayName,
                            );
                          },
                          child: const Text('Мгновенное уведомление'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final permissions = await checkPermissions();
                            if (permissions) {
                              await NotificationService.scheduleReminderNotification(
                                id: 1,
                                profileName: displayName,
                              );
                            }
                          },
                          child: const Text('Запланированное уведомление'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isGuest
                              ? 'Гостевой режим'
                              : (user.email ?? 'Без email'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6E6E6E),
                              ),
                        ),
                        if (isGuest) ...[
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE8D4A8)),
                            ),
                            child: Text(
                              'Сейчас вы вошли как гость. Если зарегистрируетесь, '
                              'этот аккаунт будет сохранён: все лекарства и профили '
                              'останутся у вас и не пропадут при выходе.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF5A5A5A),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InputBlock(
                                  title: 'Имя',
                                  hintText: 'Как к вам обращаться',
                                  maxLength: kPersonNameMaxLength,
                                  focusNode: _nameFocusNode,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _focusNext(_emailFocusNode),
                                  validator: validatePersonName,
                                  onSaved: (value) => _name = value,
                                ),
                                const SizedBox(height: 16),
                                InputBlock(
                                  title: 'Email',
                                  hintText: 'example@gmail.com',
                                  keyboardType: TextInputType.emailAddress,
                                  focusNode: _emailFocusNode,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _focusNext(_passwordFocusNode),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Введите email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Введите корректный email';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => _email = value,
                                ),
                                const SizedBox(height: 16),
                                InputBlock(
                                  title: 'Пароль',
                                  hintText: 'Придумайте пароль',
                                  obscureText: _obscurePassword,
                                  focusNode: _passwordFocusNode,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _focusNext(_confirmPasswordFocusNode),
                                  onChanged: (value) => _passwordInput = value,
                                  onToggleObscure: () {
                                    setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    );
                                  },
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Введите пароль';
                                    }
                                    if (value.length < 6) {
                                      return 'Минимум 6 символов';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => _password = value,
                                ),
                                const SizedBox(height: 16),
                                InputBlock(
                                  title: 'Подтверждение пароля',
                                  hintText: 'Повторите пароль',
                                  obscureText: _obscureConfirmPassword,
                                  focusNode: _confirmPasswordFocusNode,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _closeKeyboard(),
                                  onToggleObscure: () {
                                    setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    );
                                  },
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Подтвердите пароль';
                                    }
                                    if (value != _passwordInput) {
                                      return 'Пароли не совпадают';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _brandColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(55),
                                    alignment: Alignment.center,
                                  ),
                                  onPressed: _isSubmitting ? null : _upgradeGuestAccount,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text(
                                          'Зарегистрироваться и сохранить данные',
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: OutlinedButton.icon(
                    onPressed: _isSigningOut || _isSubmitting ? null : _signOut,
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: const Text(
                      'Выйти',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
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