import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/auth_user.dart';
import '../../domain/entities/linked_user_access.dart';
import '../../domain/entities/user_link.dart';
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
  Future<Either<dynamic, void>> grantAccessLink({
    required String outUserId,
    required String inUserId,
    required UserLinkPermission permission,
    UserLinkType type = UserLinkType.share,
  }) async {
    try {
      final normalizedOutUserId = outUserId.trim();
      final normalizedInUserId = inUserId.trim();

      if (normalizedOutUserId.isEmpty || normalizedInUserId.isEmpty) {
        return left(Exception('outUserId и inUserId обязательны'));
      }

      if (normalizedOutUserId == normalizedInUserId) {
        return left(Exception('Нельзя выдать доступ самому себе'));
      }

      final existing = await _firestore
          .collection('user_links')
          .where('outUserId', isEqualTo: normalizedOutUserId)
          .where('inUserId', isEqualTo: normalizedInUserId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update({
          'permission': permission.name,
          'status': UserLinkStatus.active.name,
          'type': type.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('user_links').add({
          'outUserId': normalizedOutUserId,
          'inUserId': normalizedInUserId,
          'permission': permission.name,
          'status': UserLinkStatus.active.name,
          'type': type.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return right(null);
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, void>> addWard(String wardName) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return left(Exception('Пользователь не авторизован'));
      }

      final normalizedWardName = wardName.trim();
      if (normalizedWardName.isEmpty) {
        return left(Exception('Имя подопечного не может быть пустым'));
      }

      final wardDocRef = _firestore.collection('users').doc();
      final wardId = wardDocRef.id;
      await wardDocRef.set({
        'uid': wardId,
        'email': null,
        'name': normalizedWardName,
        'isAnonymous': false,
        'isAuthenticated': false,
        'isWard': true,
      });

      await _firestore.collection('user_links').add({
        'outUserId': wardId,
        'inUserId': currentUser.uid,
        'permission': UserLinkPermission.editor.name,
        'status': UserLinkStatus.active.name,
        'type': UserLinkType.ward.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return right(null);
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, List<LinkedUserAccess>>> getLinkedUsersForUser(
    String userId,
  ) async {
    try {
      final incomingLinksSnapshot = await _firestore
          .collection('user_links')
          .where('inUserId', isEqualTo: userId)
          .where('status', isEqualTo: UserLinkStatus.active.name)
          .get();

      if (incomingLinksSnapshot.docs.isEmpty) {
        return right(<LinkedUserAccess>[]);
      }

      final links = incomingLinksSnapshot.docs
          .map((doc) => UserLink.fromJson(doc.id, doc.data()))
          .where((link) => link.outUserId != userId)
          .toList();

      final linkedIds = links.map((link) => link.outUserId).toSet().toList();

      if (linkedIds.isEmpty) {
        return right(<LinkedUserAccess>[]);
      }

      final usersSnapshot = await _firestore
          .collection('users')
          .where('uid', whereIn: linkedIds)
          .get();

      final usersById = {
        for (final doc in usersSnapshot.docs) doc.data()['uid'] as String: doc,
      };

      final linkedUsers = <LinkedUserAccess>[];
      for (final link in links) {
        final userDoc = usersById[link.outUserId];
        if (userDoc == null) {
          continue;
        }
        linkedUsers.add(
          LinkedUserAccess(
            user: AuthUser.fromJson(userDoc.data()),
            permission: link.permission,
            linkType: link.type,
          ),
        );
      }

      return right(linkedUsers);
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
