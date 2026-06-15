import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/core/listen_errors.dart';
import 'package:pillura_med/presentation/widgets/input_block.dart';

import '../../providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
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

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _focusNext(FocusNode nextFocus) {
    nextFocus.requestFocus();
  }

  void _closeKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authNotifierProvider.notifier).registerWithEmail(
            _email!.trim(),
            _password!.trim(),
            _name!.trim(),
          );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    listenErrors(context, ref, authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Регистрация',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _brandColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 40),
                InputBlock(
                  title: 'Имя',
                  hintText: 'Введите ваше имя',
                  focusNode: _nameFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _focusNext(_emailFocusNode),
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
                  title: 'Логин',
                  hintText: 'example@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _focusNext(_passwordFocusNode),
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
                  hintText: 'Введите пароль',
                  obscureText: _obscurePassword,
                  focusNode: _passwordFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _focusNext(_confirmPasswordFocusNode),
                  onChanged: (value) => _passwordInput = value,
                  onToggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
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
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Готово'),
                ),
                const SizedBox(height: 28),
                const _OrDivider(),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _showMessage(
                            'Вход через Google скоро будет доступен',
                          ),
                  icon: SvgPicture.asset(
                    'assets/icons/google.svg',
                    width: 20,
                    height: 20,
                  ),
                  label: const Text('Войти с google аккаунта'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6E6E6E),
                    side: const BorderSide(color: Color(0xFFD9D9D9)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD9D9D9))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'или',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6E6E6E),
                ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD9D9D9))),
      ],
    );
  }
}
