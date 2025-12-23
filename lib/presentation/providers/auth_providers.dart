import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_user.dart';

import '../../domain/repositories/auth_repository.dart';
import 'repository_provider.dart';

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  late final AuthRepository _repo;

  @override
  Future<AuthUser?> build() async {
    _repo = ref.read(authFRepositoryProvider);

    // ставим загрузку
    state = const AsyncValue.loading();
    final either = await _repo.authStateChanges().first;

    // подписываемся на изменения аутентификации
    return either.fold((l) => null, (r) => r);
  }

  Future<AuthUser?> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInAnonymously();
      state = AsyncValue.data(user.fold((l) => null, (r) => r));
      return user.fold((l) => null, (r) => r);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<AuthUser?> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInWithEmail(email, password);
      state = AsyncValue.data(user.fold((l) => null, (r) => r));
      return user.fold((l) => null, (r) => r);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<AuthUser?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.registerWithEmail(email, password, name);
      state = AsyncValue.data(user.fold((l) => null, (r) => r));
      return user.fold((l) => null, (r) => r);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  () => AuthNotifier(),
);
