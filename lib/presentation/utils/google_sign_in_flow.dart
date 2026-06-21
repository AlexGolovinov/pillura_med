import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pillura_med/core/auth_email_lookup.dart';
import 'package:pillura_med/domain/entities/google_sign_in_pending.dart';
import 'package:pillura_med/domain/errors/account_link_required_exception.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';
import 'package:pillura_med/presentation/widgets/link_account_password_dialog.dart';

typedef AcquireGooglePending = Future<GoogleSignInPending?> Function();
typedef LookupGoogleEmailProviders = Future<EmailAuthProvidersLookup> Function(
  String email,
);
typedef ShowGoogleLinkChoice = Future<GoogleLinkDialogResult?> Function({
  required String email,
  required bool allowGoogleOnly,
});
typedef CompleteGoogleSignIn = Future<void> Function(GoogleSignInPending pending);
typedef LinkGoogleWithPassword = Future<void> Function({
  required String email,
  required String password,
  required AuthCredential pendingGoogleCredential,
});

class GoogleSignInFlowController {
  final AcquireGooglePending acquirePending;
  final LookupGoogleEmailProviders lookupProviders;
  final ShowGoogleLinkChoice showChoice;
  final CompleteGoogleSignIn completeGoogleSignIn;
  final LinkGoogleWithPassword linkGoogleWithPassword;

  const GoogleSignInFlowController({
    required this.acquirePending,
    required this.lookupProviders,
    required this.showChoice,
    required this.completeGoogleSignIn,
    required this.linkGoogleWithPassword,
  });

  Future<void> run() async {
  final pending = await acquirePending();
  if (pending == null) return;

  // Получаем информацию о существующих провайдерах для этого email
  final providers = await lookupProviders(pending.email);

  // 1. Сценарий: Аккаунт уже существует и у него УЖЕ привязан Google
  if (providers.hasGoogleProvider) {
    await completeGoogleSignIn(pending);
    return;
  }

  // 2. Сценарий: Аккаунт существует, но там ТОЛЬКО Email/Пароль (нет Google)
  if (providers.registered && providers.signInMethods.contains('password')) {
    // Принудительно вызываем диалог. Передаем allowGoogleOnly: false,
    // потому что войти "просто через гугл" нельзя — нужно сначала связать с паролем!
    await _runDialog(
      pending: pending,
      allowGoogleOnly: false, 
    );
    return;
  }

  // 3. Сценарий: Абсолютно новый пользователь (нет ни пароля, ни Google)
  if (!providers.registered || providers.signInMethods.isEmpty) {
    try {
      await completeGoogleSignIn(pending);
      return;
    } on AccountLinkRequiredException {
      await _runDialog(pending: pending, allowGoogleOnly: false);
      return;
    }
  }
}

  Future<void> _runDialog({
    required GoogleSignInPending pending,
    required bool allowGoogleOnly,
  }) async {
    final dialogResult = await showChoice(
      email: pending.email,
      allowGoogleOnly: allowGoogleOnly,
    );
    if (dialogResult == null ||
        dialogResult.choice == GoogleLinkDialogChoice.cancel) {
      return;
    }

    if (dialogResult.choice == GoogleLinkDialogChoice.googleOnly) {
      try {
        await completeGoogleSignIn(pending);
      } on AccountLinkRequiredException {
        await _runDialog(pending: pending, allowGoogleOnly: false);
      }
      return;
    }

    final password = dialogResult.password;
    if (password == null || password.isEmpty) return;

    await linkGoogleWithPassword(
      email: pending.email,
      password: password,
      pendingGoogleCredential: pending.credential,
    );
  }
}

Future<void> handleGoogleSignIn({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final notifier = ref.read(authNotifierProvider.notifier);
  await GoogleSignInFlowController(
    acquirePending: notifier.acquireGoogleSignInPending,
    lookupProviders: lookupEmailAuthProviders,
    showChoice: ({
      required String email,
      required bool allowGoogleOnly,
    }) {
      if (!context.mounted) return Future.value(null);
      return showLinkAccountPasswordDialog(
        context: context,
        email: email,
        allowGoogleOnly: allowGoogleOnly,
      );
    },
    completeGoogleSignIn: notifier.completeGoogleSignIn,
    linkGoogleWithPassword: ({
      required String email,
      required String password,
      required AuthCredential pendingGoogleCredential,
    }) {
      return notifier.linkGoogleWithPassword(
        email: email,
        password: password,
        pendingGoogleCredential: pendingGoogleCredential,
      );
    },
  ).run();
}
