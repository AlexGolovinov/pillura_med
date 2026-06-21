import 'package:firebase_auth/firebase_auth.dart';

class AccountLinkRequiredException implements Exception {
  final String email;
  final AuthCredential pendingCredential;

  const AccountLinkRequiredException({
    required this.email,
    required this.pendingCredential,
  });

  @override
  String toString() =>
      'AccountLinkRequiredException(email: $email)';
}
