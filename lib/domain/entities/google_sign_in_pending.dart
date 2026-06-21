import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInPending {
  final String email;
  final AuthCredential credential;
  final String? displayName;

  const GoogleSignInPending({
    required this.email,
    required this.credential,
    this.displayName,
  });
}
