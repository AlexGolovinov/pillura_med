/// Google Sign-In platform configuration.
///
/// 1. Firebase Console → Authentication → Sign-in method → enable Google.
/// 2. Re-download `google-services.json` / `GoogleService-Info.plist`.
/// 3. Set [webClientId] from oauth_client with `client_type: 3` (Android).
/// 4. Set [iosReversedClientId] from `REVERSED_CLIENT_ID` in
///    `GoogleService-Info.plist` and add it to `ios/Runner/Info.plist`
///    under `CFBundleURLSchemes`.
class GoogleSignInConfig {
  GoogleSignInConfig._();

  /// Web client ID (`client_type: 3` in google-services.json). Required on Android.
  static const String webClientId =
      '575904813553-6mrrusdr7sisj5pfqmk40sae6gdmm4jd.apps.googleusercontent.com';

  /// `REVERSED_CLIENT_ID` from GoogleService-Info.plist for iOS URL scheme.
  static const String iosReversedClientId =
      'com.googleusercontent.apps.575904813553-i3fv9mp45l9r9p1ld9v7db3jiansrl1l';
}
