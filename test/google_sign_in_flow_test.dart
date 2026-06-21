import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillura_med/core/auth_email_lookup.dart';
import 'package:pillura_med/domain/entities/google_sign_in_pending.dart';
import 'package:pillura_med/domain/errors/account_link_required_exception.dart';
import 'package:pillura_med/presentation/utils/google_sign_in_flow.dart';
import 'package:pillura_med/presentation/widgets/link_account_password_dialog.dart';

void main() {
  group('GoogleSignInFlowController', () {
    test(
      'links Google to an existing email/password account before Google sign-in',
      () async {
        final fake = _FakeGoogleSignInFlow(
          providers: const EmailAuthProvidersLookup(
            registered: true,
            signInMethods: ['password'],
          ),
          choices: const [
            GoogleLinkDialogResult(
              choice: GoogleLinkDialogChoice.linkWithPassword,
              password: 'secret123',
            ),
          ],
        );

        await fake.controller.run();

        expect(fake.completedGoogleOnly, isFalse);
        expect(fake.linkedWithPassword, isTrue);
        expect(fake.linkedEmail, 'user@gmail.com');
        expect(fake.linkedPassword, 'secret123');
        expect(fake.dialogAllowGoogleOnlyValues, [false]);
      },
    );

    test(
      'opens forced-link dialog when hidden provider lookup hits conflict',
      () async {
        final fake = _FakeGoogleSignInFlow(
          providers: const EmailAuthProvidersLookup(
            registered: false,
            signInMethods: [],
          ),
          completeThrowsLinkRequired: true,
          choices: const [
            GoogleLinkDialogResult(
              choice: GoogleLinkDialogChoice.linkWithPassword,
              password: 'secret123',
            ),
          ],
        );

        await fake.controller.run();

        expect(fake.completeAttempts, 1);
        expect(fake.linkedWithPassword, isTrue);
        expect(fake.dialogAllowGoogleOnlyValues, [false]);
      },
    );

    test('continues without dialog when provider lookup is hidden but Google works', () async {
      final fake = _FakeGoogleSignInFlow(
        providers: const EmailAuthProvidersLookup(
          registered: false,
          signInMethods: [],
        ),
        choices: const [],
      );

      await fake.controller.run();

      expect(fake.completedGoogleOnly, isTrue);
      expect(fake.linkedWithPassword, isFalse);
      expect(fake.dialogAllowGoogleOnlyValues, isEmpty);
    });

    test('signs in without dialog when Google is already linked', () async {
      final fake = _FakeGoogleSignInFlow(
        providers: const EmailAuthProvidersLookup(
          registered: true,
          signInMethods: ['password', 'google.com'],
        ),
        choices: const [],
      );

      await fake.controller.run();

      expect(fake.completedGoogleOnly, isTrue);
      expect(fake.linkedWithPassword, isFalse);
      expect(fake.dialogAllowGoogleOnlyValues, isEmpty);
    });
  });
}

class _FakeGoogleSignInFlow {
  final EmailAuthProvidersLookup providers;
  final bool completeThrowsLinkRequired;
  final List<GoogleLinkDialogResult> choices;
  final AuthCredential credential = EmailAuthProvider.credential(
    email: 'user@gmail.com',
    password: 'unused',
  );

  final List<bool> dialogAllowGoogleOnlyValues = [];
  var completeAttempts = 0;
  var completedGoogleOnly = false;
  var linkedWithPassword = false;
  String? linkedEmail;
  String? linkedPassword;

  _FakeGoogleSignInFlow({
    required this.providers,
    required this.choices,
    this.completeThrowsLinkRequired = false,
  });

  GoogleSignInFlowController get controller => GoogleSignInFlowController(
        acquirePending: () async => GoogleSignInPending(
          email: 'user@gmail.com',
          credential: credential,
        ),
        lookupProviders: (_) async => providers,
        showChoice: ({
          required String email,
          required bool allowGoogleOnly,
        }) async {
          dialogAllowGoogleOnlyValues.add(allowGoogleOnly);
          return choices[dialogAllowGoogleOnlyValues.length - 1];
        },
        completeGoogleSignIn: (_) async {
          completeAttempts++;
          if (completeThrowsLinkRequired) {
            throw AccountLinkRequiredException(
              email: 'user@gmail.com',
              pendingCredential: credential,
            );
          }
          completedGoogleOnly = true;
        },
        linkGoogleWithPassword: ({
          required String email,
          required String password,
          required AuthCredential pendingGoogleCredential,
        }) async {
          linkedWithPassword = true;
          linkedEmail = email;
          linkedPassword = password;
        },
      );
}
