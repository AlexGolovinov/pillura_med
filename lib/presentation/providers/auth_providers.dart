import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/entities/linked_user_access.dart';

import '../../domain/repositories/auth_repository.dart';
import 'repository_provider.dart';

class AuthNotifier extends AsyncNotifier<AuthUser> {
  late final AuthRepository _repo;
  StreamSubscription? _authSubscription;

  @override
  Future<AuthUser> build() async {
    _repo = ref.read(authFRepositoryProvider);

    final firstUser = Completer<AuthUser>();
    _authSubscription = _repo.authStateChanges().listen(
      (either) {
        final user = either.fold(
          (_) => AuthUser(uid: '', isAuthenticated: false, isAnonymous: false),
          (r) => r,
        );

        if (!firstUser.isCompleted) {
          firstUser.complete(user);
          return;
        }

        state = AsyncValue.data(user);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!firstUser.isCompleted) {
          firstUser.completeError(error, stackTrace);
          return;
        }
        state = AsyncValue.error(error, stackTrace);
      },
    );
    ref.onDispose(() => _authSubscription?.cancel());

    return firstUser.future;
  }

  Future<AuthUser> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInAnonymously();
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
    state = const AsyncValue.loading();
    final user = await _repo.signInWithEmail(email, password);
    user.fold((l) {
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
        state = AsyncError(userMessage, StackTrace.current);
        return;
      }
      state = AsyncError(l, StackTrace.current);
    }, (_) {});
    //AsyncValue.data(user.fold((l) => null, (r) => r));
  }

  Future<AuthUser> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();
    final user = await _repo.registerWithEmail(email, password, name);
    return user.fold((l) {
      if (l is FirebaseAuthException) {
        final userMessage = switch (l.code) {
          'email-already-in-use' =>
            'Этот email уже используется. Войдите в существующий аккаунт.',
          'invalid-email' => 'Некорректный email',
          'weak-password' => 'Пароль слишком простой. Минимум 6 символов.',
          _ => 'Ошибка регистрации: ${l.message ?? 'неизвестная ошибка'}',
        };
        state = AsyncError(userMessage, StackTrace.current);
      } else {
        state = AsyncError(l, StackTrace.current);
      }
      return AuthUser(uid: '', isAuthenticated: false, isAnonymous: false);
    }, (r) {
      final authUser =
          r ?? AuthUser(uid: '', isAuthenticated: false, isAnonymous: false);
      state = AsyncValue.data(authUser);
      return authUser;
    });
  }

  Future<void> upgradeAnonymousAccount(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();
    final result = await _repo.upgradeAnonymousAccount(email, password, name);
    result.fold((l) {
      if (l is FirebaseAuthException) {
        final userMessage = switch (l.code) {
          'email-already-in-use' =>
            'Этот email уже используется. Войдите в существующий аккаунт.',
          'invalid-email' => 'Некорректный email',
          'weak-password' => 'Пароль слишком простой. Минимум 6 символов.',
          'credential-already-in-use' =>
            'Этот email уже привязан к другому способу входа.',
          _ => 'Ошибка регистрации: ${l.message ?? 'неизвестная ошибка'}',
        };
        state = AsyncError(userMessage, StackTrace.current);
        return;
      }
      state = AsyncError(l, StackTrace.current);
    }, (user) {
      if (user != null) {
        state = AsyncValue.data(user);
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final result = await _repo.signOut();
    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (_) {},
    );
  }

  Future<void> addWard(String wardName) async {
    final currentUser = state.value;
    if (currentUser == null || !currentUser.isAuthenticated) {
      return;
    }

    final result = await _repo.addWard(wardName);
    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (_) {},
    );
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUser>(
  () => AuthNotifier(),
);

final linkedUsersProvider = FutureProvider<List<LinkedUserAccess>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId.isEmpty) {
    return <LinkedUserAccess>[];
  }

  final repo = ref.read(authFRepositoryProvider);
  final result = await repo.getLinkedUsersForUser(userId);
  return result.fold((_) => <LinkedUserAccess>[], (users) => users);
});