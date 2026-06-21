import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/core/input_limits.dart';
import 'package:pillura_med/core/listen_errors.dart';
import 'package:pillura_med/presentation/utils/google_sign_in_flow.dart';
import 'package:pillura_med/presentation/widgets/auth_form_widgets.dart';
import 'package:pillura_med/presentation/widgets/input_block.dart';

import '../../providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
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
  bool _isGoogleSubmitting = false;

  bool get _isBusy => _isSubmitting || _isGoogleSubmitting;

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
      await ref
          .read(authNotifierProvider.notifier)
          .registerWithEmail(_email!.trim(), _password!.trim(), _name!.trim());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleSubmitting = true);
    try {
      await handleGoogleSignIn(context: context, ref: ref);
    } finally {
      if (mounted) setState(() => _isGoogleSubmitting = false);
    }
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
                const AuthPageTitle(title: 'Регистрация'),
                const SizedBox(height: 40),
                InputBlock(
                  title: 'Имя',
                  hintText: 'Введите ваше имя',
                  maxLength: kPersonNameMaxLength,
                  focusNode: _nameFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _focusNext(_emailFocusNode),
                  validator: validatePersonName,
                  onSaved: (value) => _name = value,
                ),
                const SizedBox(height: 16),
                AuthEmailField(
                  focusNode: _emailFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _focusNext(_passwordFocusNode),
                  onSaved: (value) => _email = value,
                ),
                const SizedBox(height: 16),
                AuthPasswordField(
                  obscureText: _obscurePassword,
                  focusNode: _passwordFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      _focusNext(_confirmPasswordFocusNode),
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
                AuthPasswordField(
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
                  onPressed: _isBusy ? null : _submit,
                  child: LoadingButtonContent(
                    isLoading: _isSubmitting,
                    label: 'Готово',
                  ),
                ),
                const SizedBox(height: 28),
                const OrDivider(),
                const SizedBox(height: 28),
                GoogleAuthButton(
                  isLoading: _isGoogleSubmitting,
                  onPressed: _isBusy ? null : _signInWithGoogle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
