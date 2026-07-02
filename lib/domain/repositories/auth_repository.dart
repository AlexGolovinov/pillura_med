import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pillura_med/domain/entities/google_sign_in_pending.dart';
import 'package:pillura_med/domain/entities/auth_user.dart';
import 'package:pillura_med/domain/entities/linked_user_access.dart';
import 'package:pillura_med/domain/entities/share_invite.dart';
import 'package:pillura_med/domain/entities/user_link.dart';
import 'package:pillura_med/domain/enums/ward_profile_icon.dart';

abstract class AuthRepository {
  Stream<Either<dynamic, AuthUser>> authStateChanges();
  Future<Either<dynamic, AuthUser?>> signInAnonymously();
  Future<Either<dynamic, AuthUser?>> registerWithEmail(
    String email,
    String password,
    String name,
  );
  Future<Either<dynamic, AuthUser?>> upgradeAnonymousAccount(
    String email,
    String password,
    String name,
  );
  Future<Either<dynamic, AuthUser?>> signInWithEmail(
    String email,
    String password,
  );
  Future<Either<dynamic, AuthUser?>> signInWithGoogle();
  Future<Either<dynamic, GoogleSignInPending?>> acquireGoogleSignInPending();
  Future<Either<dynamic, AuthUser?>> completeGoogleSignIn(
    GoogleSignInPending pending,
  );
  Future<Either<dynamic, AuthUser?>> linkGoogleWithPassword({
    required String email,
    required String password,
    required AuthCredential pendingGoogleCredential,
  });
  Future<Either<dynamic, void>> grantAccessLink({
    required String outUserId,
    required String inUserId,
    required UserLinkPermission permission,
    UserLinkType type,
  });
  Future<Either<dynamic, void>> addWard(
    String wardName, {
    WardProfileIcon profileIcon = WardProfileIcon.person,
  });
  Future<Either<dynamic, void>> revokeUserLink({
    required String linkId,
    required String ownerUserId,
  });
  Future<Either<dynamic, void>> updateLinkDisplayName({
    required String linkId,
    required String ownerUserId,
    required String name,
    WardProfileIcon? profileIcon,
  });
  Future<Either<dynamic, List<LinkedUserAccess>>> getLinkedUsersForUser(
    String userId,
  );
  Future<Either<dynamic, ShareInvite>> regenerateShareInvite({
    required String profileUserId,
    required String generatedByUserId,
    required bool canEdit,
  });
  Future<Either<dynamic, void>> acceptShareInviteCode({
    required String code,
    required String currentUserId,
  });
  Future<Either<dynamic, void>> signOut();
  Future<Either<dynamic, AuthUser>> updateDisplayName(String name);
  Future<Either<dynamic, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
