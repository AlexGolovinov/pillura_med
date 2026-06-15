import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/core/app_snackbar.dart';
import 'package:pillura_med/core/listen_errors.dart';
import 'package:pillura_med/presentation/widgets/auth_form_widgets.dart';

import '../../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  String? _email;
  String? _password;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
          .signInWithEmail(_email!.trim(), _password!.trim());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showGoogleUnavailable() =>
      AppSnackBar.show(context, 'Вход через Google скоро будет доступен');

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
                const AuthPageTitle(title: 'Вход'),
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
                  onPressed: _isSubmitting ? null : _submit,
                  child: LoadingButtonContent(
                    isLoading: _isSubmitting,
                    label: 'Войти',
                  ),
                ),
                const SizedBox(height: 28),
                const OrDivider(),
                const SizedBox(height: 28),
                GoogleAuthButton(
                  isLoading: false,
                  onPressed: _isSubmitting ? null : _showGoogleUnavailable,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
