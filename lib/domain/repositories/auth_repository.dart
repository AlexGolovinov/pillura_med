import 'package:dartz/dartz.dart';
import 'package:pillura_med/domain/entities/auth_user.dart';
import 'package:pillura_med/domain/entities/linked_user_access.dart';
import 'package:pillura_med/domain/entities/share_invite.dart';
import 'package:pillura_med/domain/entities/user_link.dart';

abstract class AuthRepository {
  Stream<Either<dynamic, AuthUser>> authStateChanges();
  Future<Either<dynamic, AuthUser?>> signInAnonymously();
  Future<Either<dynamic, AuthUser?>> registerWithEmail(
    String email,
    String password,
    String name,
  );
  Future<Either<dynamic, AuthUser?>> signInWithEmail(
    String email,
    String password,
  );
  Future<Either<dynamic, void>> grantAccessLink({
    required String outUserId,
    required String inUserId,
    required UserLinkPermission permission,
    UserLinkType type,
  });
  Future<Either<dynamic, void>> addWard(String wardName);
  Future<Either<dynamic, List<LinkedUserAccess>>> getLinkedUsersForUser(
    String userId,
  );
  Future<Either<dynamic, ShareInvite>> regenerateShareInvite({
    required String profileUserId,
    required String generatedByUserId,
    required bool canEdit,
  });
  Future<Either<dynamic, void>> signOut();
}
