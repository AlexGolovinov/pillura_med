import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/auth_user.dart';
import '../../domain/entities/linked_user_access.dart';
import '../../domain/entities/share_invite.dart';
import '../../domain/entities/user_link.dart';
import '../../domain/enums/ward_profile_icon.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/input_limits.dart';

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
  Future<Either<dynamic, void>> addWard(
    String wardName, {
    WardProfileIcon profileIcon = WardProfileIcon.person,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return left(Exception('Пользователь не авторизован'));
      }

      final normalizedWardName = wardName.trim();
      if (normalizedWardName.isEmpty) {
        return left(Exception('Имя подопечного не может быть пустым'));
      }
      if (normalizedWardName.length > kPersonNameMaxLength) {
        return left(Exception('Имя не должно быть длиннее $kPersonNameMaxLength символов'));
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
        'displayName': normalizedWardName,
        'profileIcon': profileIcon.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return right(null);
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, void>> revokeUserLink({
    required String linkId,
    required String ownerUserId,
  }) async {
    try {
      final doc = await _firestore.collection('user_links').doc(linkId).get();
      if (!doc.exists) {
        return left(Exception('Связь не найдена'));
      }

      final link = UserLink.fromJson(doc.id, doc.data()!);
      if (link.inUserId != ownerUserId) {
        return left(Exception('Нет доступа'));
      }
      if (link.status != UserLinkStatus.active) {
        return left(Exception('Связь уже отключена'));
      }

      await doc.reference.update({'status': UserLinkStatus.revoked.name});
      return right(null);
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, void>> updateLinkDisplayName({
    required String linkId,
    required String ownerUserId,
    required String name,
    WardProfileIcon? profileIcon,
  }) async {
    try {
      final normalizedName = name.trim();
      if (normalizedName.isEmpty) {
        return left(Exception('Имя не может быть пустым'));
      }
      if (normalizedName.length > kPersonNameMaxLength) {
        return left(
          Exception('Имя не должно быть длиннее $kPersonNameMaxLength символов'),
        );
      }

      final doc = await _firestore.collection('user_links').doc(linkId).get();
      if (!doc.exists) {
        return left(Exception('Связь не найдена'));
      }

      final link = UserLink.fromJson(doc.id, doc.data()!);
      if (link.inUserId != ownerUserId) {
        return left(Exception('Нет доступа'));
      }
      if (link.status != UserLinkStatus.active) {
        return left(Exception('Связь неактивна'));
      }

      final updates = <String, dynamic>{'displayName': normalizedName};
      if (profileIcon != null) {
        if (link.type != UserLinkType.ward) {
          return left(Exception('Иконку можно менять только у подопечного'));
        }
        updates['profileIcon'] = profileIcon.name;
      }

      await doc.reference.update(updates);
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
            linkId: link.id,
            user: AuthUser.fromJson(userDoc.data()),
            permission: link.permission,
            linkType: link.type,
            displayName: link.displayName,
            profileIcon: link.profileIcon,
          ),
        );
      }

      return right(linkedUsers);
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, ShareInvite>> regenerateShareInvite({
    required String profileUserId,
    required String generatedByUserId,
    required bool canEdit,
  }) async {
    try {
      final normalizedProfileUserId = profileUserId.trim();
      final normalizedGeneratedByUserId = generatedByUserId.trim();
      if (normalizedProfileUserId.isEmpty || normalizedGeneratedByUserId.isEmpty) {
        return left(Exception('profileUserId и generatedByUserId обязательны'));
      }
      final canGenerate = await _canGenerateInviteForProfile(
        profileUserId: normalizedProfileUserId,
        generatedByUserId: normalizedGeneratedByUserId,
      );
      if (!canGenerate) {
        return left(
          Exception(
            'Этим профилем нельзя поделиться. Вы можете делиться только своим профилем и своими подопечными.',
          ),
        );
      }

      final profileDocRef = _firestore
          .collection('share_invites_by_profile')
          .doc(normalizedProfileUserId);
      final profileSnapshot = await profileDocRef.get();
      final oldCode = profileSnapshot.data()?['code'] as String?;

      String newCode;
      DocumentReference<Map<String, dynamic>> lookupDocRef;
      var attempts = 0;
      do {
        attempts++;
        newCode = _buildInviteCode();
        lookupDocRef = _firestore
            .collection('share_invites_lookup')
            .doc(newCode);
      } while ((await lookupDocRef.get()).exists && attempts < 20);

      if ((await lookupDocRef.get()).exists) {
        return left(Exception('Не удалось сгенерировать уникальный код'));
      }

      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      if (oldCode != null && oldCode.isNotEmpty) {
        final oldLookupRef = _firestore
            .collection('share_invites_lookup')
            .doc(oldCode);
        batch.delete(oldLookupRef);
      }

      batch.set(profileDocRef, {
        'profileUserId': normalizedProfileUserId,
        'generatedByUserId': normalizedGeneratedByUserId,
        'code': newCode,
        'canEdit': canEdit,
        'createdAt': now,
      });

      batch.set(lookupDocRef, {
        'profileUserId': normalizedProfileUserId,
        'generatedByUserId': normalizedGeneratedByUserId,
        'code': newCode,
        'canEdit': canEdit,
        'createdAt': now,
      });

      await batch.commit();

      return right(
        ShareInvite(
          code: newCode,
          profileUserId: normalizedProfileUserId,
          generatedByUserId: normalizedGeneratedByUserId,
          canEdit: canEdit,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return left(e);
    }
  }

  String _buildInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final first = List.generate(
      3,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    final second = List.generate(
      5,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return '$first-$second';
  }

  Future<bool> _canGenerateInviteForProfile({
    required String profileUserId,
    required String generatedByUserId,
  }) async {
    if (profileUserId == generatedByUserId) {
      return true;
    }

    final linksSnapshot = await _firestore
        .collection('user_links')
        .where('outUserId', isEqualTo: profileUserId)
        .where('inUserId', isEqualTo: generatedByUserId)
        .get();

    for (final doc in linksSnapshot.docs) {
      final data = doc.data();
      final isWard = data['type'] == UserLinkType.ward.name;
      final isActive = data['status'] == UserLinkStatus.active.name;
      final canEdit = data['permission'] == UserLinkPermission.editor.name;
      if (isWard && isActive && canEdit) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<Either<dynamic, AuthUser?>> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        return left(Exception('Не удалось создать пользователя'));
      }

      final normalizedName = name.trim();
      if (normalizedName.isEmpty) {
        return left(Exception('Имя не может быть пустым'));
      }
      if (normalizedName.length > kPersonNameMaxLength) {
        return left(Exception('Имя не должно быть длиннее $kPersonNameMaxLength символов'));
      }
      final authUser = AuthUser(
        uid: user.uid,
        email: user.email,
        name: normalizedName,
        isAnonymous: false,
        isAuthenticated: true,
      );

      // authStateChanges может успеть создать users/{uid} с именем "Аноним".
      // При регистрации явно перезаписываем профиль данными из формы.
      await _firestore
          .collection('users')
          .doc(authUser.uid)
          .set(authUser.toJson(), SetOptions(merge: true));

      return right(authUser);
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, void>> signOut() async {
    await _firebaseAuth.signOut();
    return right(null);
  }

  @override
  Future<Either<dynamic, AuthUser?>> upgradeAnonymousAccount(
    String email,
    String password,
    String name,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || !user.isAnonymous) {
        return left(Exception('Нет гостевого аккаунта для привязки'));
      }

      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final cred = await user.linkWithCredential(credential);

      final normalizedName = name.trim();
      if (normalizedName.isEmpty) {
        return left(Exception('Имя не может быть пустым'));
      }
      if (normalizedName.length > kPersonNameMaxLength) {
        return left(Exception('Имя не должно быть длиннее $kPersonNameMaxLength символов'));
      }

      final authUser = AuthUser(
        uid: cred.user!.uid,
        email: email,
        name: normalizedName,
        isAnonymous: false,
        isAuthenticated: true,
      );

      await _firestore
          .collection('users')
          .doc(authUser.uid)
          .set(authUser.toJson(), SetOptions(merge: true));

      return right(authUser);
    } catch (e) {
      return left(e);
    }
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
