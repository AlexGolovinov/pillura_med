import 'package:google_sign_in/google_sign_in.dart';

import 'google_sign_in_config.dart';

GoogleSignIn createGoogleSignIn() {
  return GoogleSignIn(
    scopes: const ['email'],
    serverClientId: GoogleSignInConfig.webClientId,
  );
}
