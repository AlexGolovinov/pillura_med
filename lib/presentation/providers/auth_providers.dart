import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/auth_user.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final FirebaseAuthRepository _repo;
  @override
  AsyncValue<AuthUser?> build() {
    _repo = FirebaseAuthRepository(
      fb.FirebaseAuth.instance,
      FirebaseFirestore.instance,
    );

    // Подписка на изменения пользователя
    _repo.authStateChanges().listen(
      (user) {
        state = AsyncValue.data(user); // обновляем state, UI перерисуется
      },
      onError: (err, st) {
        state = AsyncValue.error(err, st);
      },
    );

    return const AsyncValue.loading(); // пока не пришло первое значение
  }

  Future<void> listenAuthChanges() async {
    _repo.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  Future<AuthUser?> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInAnonymously();
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<AuthUser?> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInWithEmail(email, password);
      state = AsyncValue.data(user);
      return user;
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
      state = AsyncValue.data(user);
      return user;
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

// // Репозиторий
// final _authRepositoryProvider = Provider<AuthRepository>((ref) {
//   return FirebaseAuthRepository(fb.FirebaseAuth.instance);
// });

// // Stream пользователя (null если не авторизован)
// final authStateProvider = StreamProvider<AuthUser?>((ref) {
//   return ref.watch(_authRepositoryProvider).authStateChanges();
// });

// // Actions (вход/выход)
// class AuthActions {
//   final AuthRepository _repo;
//   AuthActions(this._repo);

//   Future<AuthUser?> signInAnonymously() => _repo.signInAnonymously();
//   Future<AuthUser?> signInWithEmail(String email, String password) =>
//       _repo.signInWithEmail(email, password);
//   Future<AuthUser?> registerWithEmail(String email, String password) =>
//       _repo.registerWithEmail(email, password);
//   Future<void> signOut() => _repo.signOut();
// }

// final authActionsProvider = Provider<AuthActions>((ref) {
//   return AuthActions(ref.watch(_authRepositoryProvider));
// });
