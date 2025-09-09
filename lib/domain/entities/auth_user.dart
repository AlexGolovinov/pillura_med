import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthUser {
  final String uid;
  final String? email;
  final String? name;
  final bool isAnonymous;

  AuthUser({
    required this.uid,
    this.email,
    this.name,
    required this.isAnonymous,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: json['uid'],
      email: json['email'],
      name: json['name'],
      isAnonymous: json['isAnonymous'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'isAnonymous': isAnonymous,
    };
  }

  static FutureOr<AuthUser?> fromFirebase(User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      name: user.displayName,
      isAnonymous: user.isAnonymous,
    );
  }
}
