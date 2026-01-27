import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository(this._firebaseAuth, this._firestore);

  @override
  Stream<Either<dynamic, AuthUser>> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return right(
          AuthUser(uid: '', isAuthenticated: false, isAnonymous: false),
        );
      }
      return (await getOrCreateUser(
        user,
      )).fold((l) => left(l), (r) => right(r));
    });
  }

  @override
  Future<Either<dynamic, AuthUser?>> signInAnonymously() async {
    final cred = await _firebaseAuth.signInAnonymously();
    final user = cred.user;
    return (await getOrCreateUser(user)).fold((l) => left(l), (r) => right(r));
  }

  @override
  Future<Either<dynamic, AuthUser?>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return (await getOrCreateUser(
        cred.user,
      )).fold((l) => left(l), (r) => right(r));
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, AuthUser?>> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    return (await getOrCreateUser(
      user,
      name: name,
    )).fold((l) => left(l), (r) => right(r));
  }

  @override
  Future<Either<dynamic, void>> signOut() async {
    await _firebaseAuth.signOut();
    return right(null);
  }

  Future<Either<dynamic, AuthUser?>> upgradeAnonymousAccount(
    String email,
    String password,
    String name,
  ) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw Exception("Нет анонимного пользователя для апгрейда");
    }

    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    final cred = await user.linkWithCredential(credential);

    final authUser = AuthUser(
      uid: cred.user!.uid,
      email: email,
      name: name,
      isAnonymous: false,
      isAuthenticated: true,
    );

    await _firestore
        .collection('users')
        .doc(authUser.uid)
        .set(authUser.toJson());

    return right(authUser);
  }

  Future<Either<dynamic, AuthUser>> getOrCreateUser(
    fb.User? user, {
    String name = 'Аноним',
  }) async {
    final doc = _firestore.collection('users').doc(user?.uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      final authUser = AuthUser(
        uid: user!.uid,
        email: user.email,
        name: name,
        isAnonymous: user.isAnonymous,
        isAuthenticated: true,
      );
      await doc.set(authUser.toJson());
      return right(authUser);
    }
    return right(AuthUser.fromJson(snapshot.data()!));
  }
}
