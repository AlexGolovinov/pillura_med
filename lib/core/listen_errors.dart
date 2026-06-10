import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:pillura_med/core/app_snackbar.dart';

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

      AppSnackBar.show(context, errorMessage);
    }
  });
}
