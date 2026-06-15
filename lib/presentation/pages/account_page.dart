import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    await ref.read(authNotifierProvider.notifier).upgradeAnonymousAccount(
          _email!.trim(),
          _password!.trim(),
          _name!.trim(),
        );
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) context.go('/welcomePage');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user.isAuthenticated &&
              !user.isAnonymous &&
              previous?.value?.isAnonymous == true &&
              context.mounted) {
            _showMessage('Аккаунт сохранён. Ваши данные остались с вами.');
          }
        },
        error: (error, _) {
          if (context.mounted) {
            _showMessage(error.toString());
          }
        },
      );
    });

    return authState.when(
      data: (user) {
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
                                  focusNode: _nameFocusNode,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _focusNext(_emailFocusNode),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Введите имя';
                                    }
                                    return null;
                                  },
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
                                  onPressed: isLoading ? null : _upgradeGuestAccount,
                                  child: const Text(
                                    'Зарегистрироваться и сохранить данные',
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
                  child: TextButton.icon(
                    onPressed: isLoading ? null : _signOut,
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
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Мой аккаунт')),
        body: Center(child: Text('Ошибка: $err')),
      ),
    );
  }
}
