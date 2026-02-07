import 'package:dartz/dartz.dart';
import 'package:voxmatrix/core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
    required String homeserver,
  });

  Future<Either<Failure, UserEntity>> register({
    required String username,
    required String password,
    required String email,
    required String homeserver,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, bool>> isAuthenticated();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, String>> getAccessToken();

  Future<Either<Failure, void>> saveTokens({
    required String accessToken,
    required String userId,
    required String deviceId,
  });

  Stream<Either<Failure, UserEntity>> get authStateChanges;
}
