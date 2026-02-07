import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/data/datasources/auth_remote_datasource.dart';
import 'package:voxmatrix/data/models/user_model.dart';
import 'package:voxmatrix/domain/entities/user_entity.dart';
import 'package:voxmatrix/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );

  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
    required String homeserver,
  }) async {
    final result = await _remoteDataSource.login(
      username: username,
      password: password,
      homeserver: homeserver,
    );

    return result.fold(
      (failure) => Left(failure),
      (data) {
        final user = UserModel(
          id: data['user_id'] as String? ?? '@$username:homeserver',
          username: username,
          displayName: username,
          isActive: true,
        );

        _localDataSource.saveAccessToken(data['access_token'] as String? ?? '');
        _localDataSource.saveUserId(data['user_id'] as String? ?? '');
        _localDataSource.saveDeviceId(data['device_id'] as String? ?? '');
        _localDataSource.saveHomeserver(_normalizeHomeserver(homeserver));

        return Right(user.toEntity());
      },
    );
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String username,
    required String password,
    required String email,
    required String homeserver,
  }) async {
    final result = await _remoteDataSource.register(
      username: username,
      password: password,
      email: email,
      homeserver: homeserver,
    );

    return result.fold(
      (failure) => Left(failure),
      (data) {
        final user = UserModel(
          id: data['user_id'] as String? ?? '@$username:homeserver',
          username: username,
          displayName: username,
          email: email,
          isActive: true,
        );

        _localDataSource.saveAccessToken(data['access_token'] as String? ?? '');
        _localDataSource.saveUserId(data['user_id'] as String? ?? '');
        _localDataSource.saveDeviceId(data['device_id'] as String? ?? '');
        _localDataSource.saveHomeserver(_normalizeHomeserver(homeserver));

        return Right(user.toEntity());
      },
    );
  }

  String _normalizeHomeserver(String homeserver) {
    final trimmed = homeserver.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'http://$trimmed';
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Get stored credentials before clearing
      final token = await _localDataSource.getAccessToken();
      final homeserver = await _localDataSource.getHomeserver();

      // Call remote logout if we have credentials
      if (token != null && homeserver != null) {
        final result = await _remoteDataSource.logout(
          homeserver: homeserver,
          accessToken: token,
        );
        // Continue with local cleanup even if remote logout fails
        result.fold(
          (failure) => null, // Log but don't fail
          (_) => null,
        );
      }

      // Clear local storage
      await _localDataSource.clearAll();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final hasTokens = await _localDataSource.hasTokens();
      return Right(hasTokens);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userId = await _localDataSource.getUserId();
      if (userId == null) {
        return const Left(AuthFailure(
          message: 'No user logged in',
          statusCode: 401,
        ));
      }

      final user = UserModel(
        id: userId,
        username: userId,
        displayName: userId,
        isActive: true,
      );

      return Right(user.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Either<Failure, String>> getAccessToken() async {
    try {
      final token = await _localDataSource.getAccessToken();
      if (token == null) {
        return const Left(AuthFailure(
          message: 'No access token found',
          statusCode: 401,
        ));
      }
      return Right(token);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Either<Failure, void>> saveTokens({
    required String accessToken,
    required String userId,
    required String deviceId,
  }) async {
    try {
      await _localDataSource.saveAccessToken(accessToken);
      await _localDataSource.saveUserId(userId);
      await _localDataSource.saveDeviceId(deviceId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(CacheFailure(message: e.toString(), statusCode: 500));
    }
  }

  @override
  Stream<Either<Failure, UserEntity>> get authStateChanges {
    return Stream.value(
      const Right(UserEntity(
        id: '',
        username: '',
        displayName: '',
        isActive: true,
      )),
    );
  }
}
