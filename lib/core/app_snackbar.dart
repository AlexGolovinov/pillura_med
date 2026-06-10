import 'package:flutter/material.dart';

class AppSnackBar {
  AppSnackBar._();

  static bool _isVisible = false;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (_isVisible || !context.mounted) return;

    _isVisible = true;
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text(message),
            duration: duration,
          ),
        )
        .closed
        .whenComplete(() => _isVisible = false);
  }
}
