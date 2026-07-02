import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/google_sign_in_factory.dart';
import '../../core/auth_email_lookup.dart';
import '../../domain/entities/google_sign_in_pending.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/linked_user_access.dart';
import '../../domain/entities/share_invite.dart';
import '../../domain/entities/user_link.dart';
import '../../domain/enums/ward_profile_icon.dart';
import '../../domain/errors/account_link_required_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/input_limits.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository(
    this._firebaseAuth,
    this._firestore, [
    GoogleSignIn? googleSignIn,
  ]) : _googleSignIn = googleSignIn ?? createGoogleSignIn();

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
    await Future.wait([
      _googleSignIn.signOut(),
      _firebaseAuth.signOut(),
    ]);
    return right(null);
  }

  @override
  Future<Either<dynamic, AuthUser>> updateDisplayName(String name) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return left(Exception('Пользователь не авторизован'));
      }

      final normalizedName = name.trim();
      if (normalizedName.isEmpty) {
        return left(Exception('Имя не может быть пустым'));
      }
      if (normalizedName.length > kPersonNameMaxLength) {
        return left(
          Exception('Имя не должно быть длиннее $kPersonNameMaxLength символов'),
        );
      }

      await user.updateDisplayName(normalizedName);

      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      final existing = snapshot.exists
          ? AuthUser.fromJson(snapshot.data()!)
          : AuthUser(
              uid: user.uid,
              email: user.email,
              isAnonymous: user.isAnonymous,
              isAuthenticated: true,
            );

      final updatedUser = AuthUser(
        uid: user.uid,
        email: existing.email ?? user.email,
        name: normalizedName,
        isAnonymous: user.isAnonymous,
        isAuthenticated: true,
        isWard: existing.isWard,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updatedUser.toJson(), SetOptions(merge: true));

      return right(updatedUser);
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return left(Exception('Пользователь не авторизован'));
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        return left(Exception('Email не найден'));
      }

      final hasPasswordProvider = user.providerData.any(
        (provider) => provider.providerId == 'password',
      );
      if (!hasPasswordProvider) {
        return left(
          Exception('Смена пароля недоступна для этого способа входа'),
        );
      }

      if (newPassword.length < 6) {
        return left(Exception('Минимум 6 символов'));
      }

      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return right(null);
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, GoogleSignInPending?>> acquireGoogleSignInPending() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return right(null);
      }

      final googleEmail = googleUser.email.trim();
      if (googleEmail.isEmpty) {
        return left(Exception('Google-аккаунт не содержит email'));
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return right(
        GoogleSignInPending(
          email: googleEmail,
          credential: credential,
          displayName: googleUser.displayName?.trim(),
        ),
      );
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, AuthUser?>> completeGoogleSignIn(
    GoogleSignInPending pending,
  ) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      final isAnonymous = currentUser?.isAnonymous ?? false;

      final userCredential = await _linkOrSignInWithGoogleCredential(
        credential: pending.credential,
        googleEmail: pending.email,
        linkToCurrentUser: isAnonymous,
      );

      return _finalizeGoogleSignIn(
        userCredential.user,
        displayName: pending.displayName,
      );
    } on AccountLinkRequiredException catch (e) {
      return left(e);
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, AuthUser?>> signInWithGoogle() async {
    try {
      final pendingResult = await acquireGoogleSignInPending();
      return await pendingResult.fold(
        (error) async => left(error),
        (pending) async {
          if (pending == null) {
            return right(null);
          }

          final providers = await lookupEmailAuthProviders(pending.email);
          if (providers.needsGoogleLinking) {
            return left(
              AccountLinkRequiredException(
                email: pending.email,
                pendingCredential: pending.credential,
              ),
            );
          }

          return completeGoogleSignIn(pending);
        },
      );
    } catch (e) {
      return left(e);
    }
  }

  @override
  Future<Either<dynamic, AuthUser?>> linkGoogleWithPassword({
    required String email,
    required String password,
    required fb.AuthCredential pendingGoogleCredential,
  }) async {
    try {
      // Сбрасываем возможную Google-only сессию, чтобы войти в email/пароль аккаунт.
      await _firebaseAuth.signOut();

      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final linkedCredential = await _firebaseAuth.currentUser!
          .linkWithCredential(pendingGoogleCredential);

      return _finalizeGoogleSignIn(linkedCredential.user);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        return _finalizeGoogleSignIn(_firebaseAuth.currentUser);
      }
      return left(e);
    } catch (e) {
      return left(e);
    }
  }

  Future<fb.UserCredential> _linkOrSignInWithGoogleCredential({
    required fb.AuthCredential credential,
    required String? googleEmail,
    required bool linkToCurrentUser,
  }) async {
    try {
      if (linkToCurrentUser) {
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser == null || !currentUser.isAnonymous) {
          return await _firebaseAuth.signInWithCredential(credential);
        }
        return await currentUser.linkWithCredential(credential);
      }
      return await _firebaseAuth.signInWithCredential(credential);
    } on fb.FirebaseAuthException catch (e) {
      final linkRequired = _asAccountLinkRequired(
        e,
        fallbackCredential: credential,
        fallbackEmail: googleEmail,
      );
      if (linkRequired != null) {
        throw linkRequired;
      }

      if (linkToCurrentUser &&
          e.code == 'credential-already-in-use' &&
          googleEmail != null &&
          googleEmail.isNotEmpty) {
        throw AccountLinkRequiredException(
          email: googleEmail,
          pendingCredential: credential,
        );
      }

      rethrow;
    }
  }

  AccountLinkRequiredException? _asAccountLinkRequired(
    fb.FirebaseAuthException error, {
    required fb.AuthCredential fallbackCredential,
    required String? fallbackEmail,
  }) {
    const linkRequiredCodes = {
      'account-exists-with-different-credential',
      'email-already-in-use',
    };

    if (!linkRequiredCodes.contains(error.code)) {
      return null;
    }

    final email = error.email ?? fallbackEmail;
    if (email == null || email.isEmpty) {
      return null;
    }

    return AccountLinkRequiredException(
      email: email,
      pendingCredential: error.credential ?? fallbackCredential,
    );
  }

  Future<Either<dynamic, AuthUser?>> _finalizeGoogleSignIn(
    fb.User? user, {
    String? displayName,
  }) async {
    if (user == null) {
      return left(Exception('Не удалось войти через Google'));
    }

    final normalizedName = displayName?.trim();
    final defaultName = normalizedName != null && normalizedName.isNotEmpty
        ? normalizedName
        : 'Аноним';

    final userResult = await getOrCreateUser(user, name: defaultName);
    return await userResult.fold<Future<Either<dynamic, AuthUser?>>>(
      (l) async => left(l),
      (authUser) async {
        if (normalizedName == null || normalizedName.isEmpty) {
          return right(authUser);
        }

        final shouldUpdateName =
            authUser.name == null ||
            authUser.name!.isEmpty ||
            authUser.name == 'Аноним';

        if (!shouldUpdateName) {
          return right(authUser);
        }

        final updatedUser = AuthUser(
          uid: authUser.uid,
          email: authUser.email ?? user.email,
          name: normalizedName,
          isAnonymous: false,
          isAuthenticated: true,
          isWard: authUser.isWard,
        );

        await _firestore
            .collection('users')
            .doc(updatedUser.uid)
            .set(updatedUser.toJson(), SetOptions(merge: true));

        return right(updatedUser);
      },
    );
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
