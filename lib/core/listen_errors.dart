import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

void listenErrors(
  BuildContext context,
  WidgetRef ref,
  ProviderListenable<AsyncValue<dynamic>> provider,
) {
  ref.listen<AsyncValue<dynamic>>(provider, (prev, next) {
    final isError = next.hasError;
    if (isError) {
      final String errorMessage;
      errorMessage = next.error.toString();

      // 3. Отображаем SnackBar (единая точка вызова)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  });
}
