import 'package:flutter/material.dart';
import 'package:pillura_med/core/input_limits.dart';
import 'package:pillura_med/presentation/widgets/input_block.dart';

typedef ChangePasswordSubmit = Future<String?> Function({
  required String currentPassword,
  required String newPassword,
});

Future<String?> showEditDisplayNameDialog({
  required BuildContext context,
  required String currentName,
}) {
  final formKey = GlobalKey<FormState>();
  String? newName;

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Изменить имя'),
      content: Form(
        key: formKey,
        child: TextFormField(
          initialValue: currentName,
          maxLength: kPersonNameMaxLength,
          decoration: const InputDecoration(
            labelText: 'Имя',
            hintText: 'Как к вам обращаться',
            counterText: '',
          ),
          textInputAction: TextInputAction.done,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validatePersonName,
          onSaved: (value) => newName = value?.trim(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            formKey.currentState!.save();
            Navigator.pop(dialogContext, newName);
          },
          child: const Text('Сохранить'),
        ),
      ],
    ),
  );
}

Future<bool> showChangePasswordDialog({
  required BuildContext context,
  required ChangePasswordSubmit onSubmit,
}) {
  return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _ChangePasswordDialog(onSubmit: onSubmit),
      ).then((value) => value ?? false);
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.onSubmit});

  final ChangePasswordSubmit onSubmit;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  String? _currentPassword;
  String? _newPassword;
  String _newPasswordInput = '';
  String? _submitError;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  static const _wrongPasswordMessage = 'Неверный текущий пароль';

  @override
  void dispose() {
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final error = await widget.onSubmit(
      currentPassword: _currentPassword!.trim(),
      newPassword: _newPassword!.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _submitError = error;
    });

    if (error == _wrongPasswordMessage) {
      _currentPasswordFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сменить пароль'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_submitError != null) ...[
                Text(
                  _submitError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              InputBlock(
                title: 'Текущий пароль',
                hintText: 'Введите текущий пароль',
                obscureText: _obscureCurrentPassword,
                focusNode: _currentPasswordFocusNode,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _newPasswordFocusNode.requestFocus(),
                onToggleObscure: () {
                  setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите текущий пароль';
                  }
                  return null;
                },
                onSaved: (value) => _currentPassword = value,
              ),
              const SizedBox(height: 16),
              InputBlock(
                title: 'Новый пароль',
                hintText: 'Придумайте новый пароль',
                obscureText: _obscureNewPassword,
                focusNode: _newPasswordFocusNode,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                onChanged: (value) => _newPasswordInput = value,
                onToggleObscure: () {
                  setState(() => _obscureNewPassword = !_obscureNewPassword);
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите новый пароль';
                  }
                  if (value.length < 6) {
                    return 'Минимум 6 символов';
                  }
                  return null;
                },
                onSaved: (value) => _newPassword = value,
              ),
              const SizedBox(height: 16),
              InputBlock(
                title: 'Подтверждение пароля',
                hintText: 'Повторите новый пароль',
                obscureText: _obscureConfirmPassword,
                focusNode: _confirmPasswordFocusNode,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                onToggleObscure: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Подтвердите пароль';
                  }
                  if (value != _newPasswordInput) {
                    return 'Пароли не совпадают';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
