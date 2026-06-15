import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'input_block.dart';

class AuthPageTitle extends StatelessWidget {
  static const brandColor = Color(0xFF202D85);

  final String title;

  const AuthPageTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: brandColor,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
    );
  }
}

class AuthEmailField extends StatelessWidget {
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String> onFieldSubmitted;
  final FormFieldSetter<String> onSaved;

  const AuthEmailField({
    super.key,
    required this.focusNode,
    required this.textInputAction,
    required this.onFieldSubmitted,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return InputBlock(
      title: 'Логин',
      hintText: 'example@gmail.com',
      keyboardType: TextInputType.emailAddress,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validateEmail,
      onSaved: onSaved,
    );
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите email';
    }
    if (!value.contains('@')) {
      return 'Введите корректный email';
    }
    return null;
  }
}

class AuthPasswordField extends StatelessWidget {
  final String title;
  final String hintText;
  final bool obscureText;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String> onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback onToggleObscure;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;

  const AuthPasswordField({
    super.key,
    this.title = 'Пароль',
    this.hintText = 'Введите пароль',
    required this.obscureText,
    required this.focusNode,
    required this.textInputAction,
    required this.onFieldSubmitted,
    this.onChanged,
    required this.onToggleObscure,
    this.validator,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return InputBlock(
      title: title,
      hintText: hintText,
      obscureText: obscureText,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      onToggleObscure: onToggleObscure,
      validator: validator ?? validateRequiredPassword,
      onSaved: onSaved,
    );
  }

  static String? validateRequiredPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите пароль';
    }
    return null;
  }
}

class LoadingButtonContent extends StatelessWidget {
  final bool isLoading;
  final String label;

  const LoadingButtonContent({
    super.key,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return Text(label);

    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD9D9D9))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'или',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6E6E6E)),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD9D9D9))),
      ],
    );
  }
}

class GoogleAuthButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const GoogleAuthButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : SvgPicture.asset('assets/icons/google.svg', width: 20, height: 20),
      label: Text(isLoading ? 'Вход...' : 'Войти с google аккаунта'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6E6E6E),
        side: const BorderSide(color: Color(0xFFD9D9D9)),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
