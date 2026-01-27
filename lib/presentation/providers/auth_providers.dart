import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_user.dart';

import '../../domain/repositories/auth_repository.dart';
import 'repository_provider.dart';

class AuthNotifier extends AsyncNotifier<AuthUser> {
  late final AuthRepository _repo;

  @override
  Future<AuthUser> build() async {
    _repo = ref.read(authFRepositoryProvider);

    // ставим загрузку
    state = const AsyncValue.loading();
    final either = await _repo.authStateChanges().first;

    // подписываемся на изменения аутентификации
    return either.fold(
      (l) => AuthUser(uid: '', isAuthenticated: false, isAnonymous: false),
      (r) => r,
    );
  }

  Future<AuthUser> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInAnonymously();
      state = AsyncValue.data(
        user.fold(
          (l) => AuthUser(uid: '', isAuthenticated: false, isAnonymous: false),
          (r) => r!,
        ),
      );
      return user.fold(
        (l) => AuthUser(uid: '', isAnonymous: false, isAuthenticated: false),
        (r) => r!,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return AuthUser(uid: '', isAnonymous: false, isAuthenticated: false);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    final user = await _repo.signInWithEmail(email, password);
    state = user.fold((l) {
      if (l is FirebaseAuthException) {
        String userMessage;

        switch (l.code) {
          case 'invalid-credential':
          case 'user-not-found':
          case 'wrong-password':
            userMessage = 'Неверный email или пароль';
            break;

          case 'too-many-requests':
            userMessage =
                'Слишком много попыток. Аккаунт временно заблокирован.\n'
                'Попробуйте снова через 30–60 минут или смените интернет-сеть (Wi-Fi → мобильный или наоборот).';
            break;

          case 'user-disabled':
            userMessage = 'Аккаунт заблокирован. Обратитесь в поддержку.';
            break;

          default:
            userMessage = 'Ошибка входа: ${l.message ?? 'неизвестная ошибка'}';
        }
        return AsyncError(userMessage, StackTrace.current);
      }
      return AsyncError(l, StackTrace.current);
    }, (r) => AsyncData(r!));
    //AsyncValue.data(user.fold((l) => null, (r) => r));
  }

  Future<AuthUser> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.registerWithEmail(email, password, name);
      state = AsyncValue.data(
        user.fold(
          (l) => AuthUser(uid: '', isAuthenticated: false, isAnonymous: false),
          (r) => r!,
        ),
      );
      return user.fold(
        (l) => AuthUser(uid: '', isAuthenticated: false, isAnonymous: false),
        (r) => r!,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return AuthUser(uid: '', isAuthenticated: false, isAnonymous: false);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = AsyncValue.data(
      AuthUser(uid: '', isAuthenticated: false, isAnonymous: false),
    );
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUser>(
  () => AuthNotifier(),
);
