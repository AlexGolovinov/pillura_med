import 'package:dartz/dartz.dart';
import 'package:pillura_med/domain/entities/auth_user.dart';

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
  Future<Either<dynamic, void>> signOut();
}
