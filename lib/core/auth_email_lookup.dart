import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class EmailAuthProvidersLookup {
  final bool registered;
  final List<String> signInMethods;

  const EmailAuthProvidersLookup({
    required this.registered,
    required this.signInMethods,
  });

  bool get hasPasswordProvider => signInMethods.any(
        (method) => method.toLowerCase() == 'password',
      );

  bool get hasGoogleProvider => signInMethods.any(
        (method) => method.toLowerCase().contains('google'),
      );

  /// Email зарегистрирован, но Google ещё не привязан — нужен пароль перед входом.
  bool get needsGoogleLinking => registered && !hasGoogleProvider;
}

Future<EmailAuthProvidersLookup> lookupEmailAuthProviders(String email) async {
  if (email.trim().isEmpty) {
    return const EmailAuthProvidersLookup(registered: false, signInMethods: []);
  }

  if (kIsWeb) {
    return const EmailAuthProvidersLookup(registered: false, signInMethods: []);
  }

  final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
  final client = HttpClient();

  try {
    final request = await client.postUrl(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=$apiKey',
      ),
    );
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'identifier': email.trim(),
        'continueUri': 'https://${DefaultFirebaseOptions.android.projectId}.firebaseapp.com',
      }),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      return const EmailAuthProvidersLookup(
        registered: false,
        signInMethods: [],
      );
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final methods = <String>[
      ...?((json['signinMethods'] as List?)?.cast<String>()),
      ...?((json['allProviders'] as List?)?.cast<String>()),
    ];

    return EmailAuthProvidersLookup(
      registered: json['registered'] as bool? ?? false,
      signInMethods: methods.toSet().toList(),
    );
  } catch (_) {
    return const EmailAuthProvidersLookup(registered: false, signInMethods: []);
  } finally {
    client.close();
  }
}
