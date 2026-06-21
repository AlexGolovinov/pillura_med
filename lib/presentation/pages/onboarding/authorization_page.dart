import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/core/app_snackbar.dart';
import 'package:pillura_med/core/listen_errors.dart';
import 'package:pillura_med/presentation/utils/google_sign_in_flow.dart';
import 'package:pillura_med/presentation/widgets/auth_form_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_providers.dart';

class AuthorizationPage extends ConsumerStatefulWidget {
  const AuthorizationPage({super.key});

  @override
  ConsumerState<AuthorizationPage> createState() => _AuthorizationPageState();
}

class _AuthorizationPageState extends ConsumerState<AuthorizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  String? _email;
  String? _password;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _focusNext(FocusNode nextFocus) => nextFocus.requestFocus();

  void _closeKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  bool get _isBusy => _isSubmitting || _isGoogleSubmitting;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signInWithEmail(_email!.trim(), _password!.trim());
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

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', false);
    if (mounted) {
      AppSnackBar.show(context, 'Onboarding сброшен (seen_onboarding = false)');
    }
  }

  @override
  Widget build(BuildContext context) {
    listenErrors(context, ref, authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthPageTitle(title: 'Авторизация'),
                      const SizedBox(height: 40),
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
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _closeKeyboard(),
                        onToggleObscure: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        onSaved: (value) => _password = value,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isBusy ? null : _submit,
                        child: LoadingButtonContent(
                          isLoading: _isSubmitting,
                          label: 'Войти',
                        ),
                      ),
                      const SizedBox(height: 28),
                      const OrDivider(),
                      const SizedBox(height: 28),
                      GoogleAuthButton(
                        isLoading: _isGoogleSubmitting,
                        onPressed: _isBusy ? null : _signInWithGoogle,
                      ),
                      const SizedBox(height: 32),
                      TextButton(
                        onPressed: _isBusy
                            ? null
                            : () => context.push('/register'),
                        child: const Text('Зарегистрироваться'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: TextButton(
                onPressed: _resetOnboarding,
                child: const Text('Сбросить onboarding'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
