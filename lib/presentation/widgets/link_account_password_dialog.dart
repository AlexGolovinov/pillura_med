import 'package:flutter/material.dart';
import 'package:pillura_med/presentation/widgets/auth_form_widgets.dart';

enum GoogleLinkDialogChoice {
  cancel,
  googleOnly,
  linkWithPassword,
}

class GoogleLinkDialogResult {
  final GoogleLinkDialogChoice choice;
  final String? password;

  const GoogleLinkDialogResult({
    required this.choice,
    this.password,
  });
}

Future<GoogleLinkDialogResult?> showLinkAccountPasswordDialog({
  required BuildContext context,
  required String email,
  required bool allowGoogleOnly,
}) {
  return showDialog<GoogleLinkDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => LinkAccountPasswordDialog(
      email: email,
      allowGoogleOnly: allowGoogleOnly,
    ),
  );
}

class LinkAccountPasswordDialog extends StatefulWidget {
  final String email;
  final bool allowGoogleOnly;

  const LinkAccountPasswordDialog({
    super.key,
    required this.email,
    this.allowGoogleOnly = true,
  });

  @override
  State<LinkAccountPasswordDialog> createState() =>
      _LinkAccountPasswordDialogState();
}

class _LinkAccountPasswordDialogState extends State<LinkAccountPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();
  String? _password;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submitLink() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    Navigator.of(context).pop(
      GoogleLinkDialogResult(
        choice: GoogleLinkDialogChoice.linkWithPassword,
        password: _password?.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Вход через Google'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.allowGoogleOnly
                  ? 'Если вы уже регистрировались через ${widget.email} с паролем — '
                      'введите его, чтобы связать Google (один раз). '
                      'Иначе нажмите «Только Google».'
                  : 'Аккаунт ${widget.email} уже зарегистрирован с паролем. '
                      'Введите пароль, чтобы связать Google — это нужно сделать один раз.',
            ),
            const SizedBox(height: 16),
            AuthPasswordField(
              obscureText: _obscurePassword,
              focusNode: _passwordFocusNode,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitLink(),
              onToggleObscure: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              onSaved: (value) => _password = value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const GoogleLinkDialogResult(choice: GoogleLinkDialogChoice.cancel),
          ),
          child: const Text('Отмена'),
        ),
        if (widget.allowGoogleOnly)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const GoogleLinkDialogResult(
                choice: GoogleLinkDialogChoice.googleOnly,
              ),
            ),
            child: const Text('Только Google'),
          ),
        FilledButton(
          onPressed: _submitLink,
          child: const Text('Связать'),
        ),
      ],
    );
  }
}
