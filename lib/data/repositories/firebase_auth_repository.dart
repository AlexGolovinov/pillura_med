import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository(this._firebaseAuth, this._firestore);

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return getOrCreateUser(user);
    });
  }

  @override
  Future<AuthUser?> signInAnonymously() async {
    final cred = await _firebaseAuth.signInAnonymously();
    final user = cred.user;
    return getOrCreateUser(user);
  }

  @override
  Future<AuthUser?> signInWithEmail(String email, String password) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return getOrCreateUser(cred.user);
  }

  @override
  Future<AuthUser?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    return getOrCreateUser(user, name: name);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<AuthUser?> upgradeAnonymousAccount(
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
    );

    await _firestore
        .collection('users')
        .doc(authUser.uid)
        .set(authUser.toJson());

    return authUser;
  }

  Future<AuthUser> getOrCreateUser(
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
      );
      await doc.set(authUser.toJson());
      return authUser;
    }
    return AuthUser.fromJson(snapshot.data()!);
  }
}
