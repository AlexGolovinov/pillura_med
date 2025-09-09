import 'package:pillura_med/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  Future<AuthUser?> signInAnonymously();
  Future<AuthUser?> registerWithEmail(
    String email,
    String password,
    String name,
  );
  Future<AuthUser?> signInWithEmail(String email, String password);
  Future<void> signOut();
}
