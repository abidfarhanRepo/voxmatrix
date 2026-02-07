import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/data/datasources/account_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import '../../domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(
    this._accountDataSource,
    this._localDataSource,
    this._logger,
  );

  final AccountRemoteDataSource _accountDataSource;
  final AuthLocalDataSource _localDataSource;
  final Logger _logger;

  Future<_Credentials?> _getCredentials() async {
    try {
      final token = await _localDataSource.getAccessToken();
      final homeserver = await _localDataSource.getHomeserver();
      final userId = await _localDataSource.getUserId();

      if (token == null || homeserver == null || userId == null) {
        return null;
      }

      return _Credentials(
        accessToken: token,
        homeserver: homeserver,
        userId: userId,
      );
    } catch (e) {
      _logger.e('Error getting credentials', error: e);
      return null;
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProfile() async {
    final creds = await _getCredentials();
    if (creds == null) {
      return const Left(AuthFailure(
        message: 'Not authenticated',
        statusCode: 401,
      ));
    }

    return await _accountDataSource.getProfile(
      homeserver: creds.homeserver,
      accessToken: creds.accessToken,
      userId: creds.userId,
    );
  }

  @override
  Future<Either<Failure, void>> setDisplayName(String displayName) async {
    final creds = await _getCredentials();
    if (creds == null) {
      return const Left(AuthFailure(
        message: 'Not authenticated',
        statusCode: 401,
      ));
    }

    final result = await _accountDataSource.setDisplayName(
      homeserver: creds.homeserver,
      accessToken: creds.accessToken,
      userId: creds.userId,
      displayName: displayName,
    );

    return result.fold(
      (failure) => Left(failure),
      (_) {
        // Update local display name if stored
        _updateLocalDisplayName(displayName);
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, void>> setAvatarUrl(String avatarUrl) async {
    final creds = await _getCredentials();
    if (creds == null) {
      return const Left(AuthFailure(
        message: 'Not authenticated',
        statusCode: 401,
      ));
    }

    return await _accountDataSource.setAvatarUrl(
      homeserver: creds.homeserver,
      accessToken: creds.accessToken,
      userId: creds.userId,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<Either<Failure, String>> uploadAvatar({
    required String filePath,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    final creds = await _getCredentials();
    if (creds == null) {
      return const Left(AuthFailure(
        message: 'Not authenticated',
        statusCode: 401,
      ));
    }

    return await _accountDataSource.uploadAvatar(
      homeserver: creds.homeserver,
      accessToken: creds.accessToken,
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
  }

  @override
  Future<Either<Failure, void>> updateAvatar(String filePath) async {
    final creds = await _getCredentials();
    if (creds == null) {
      return const Left(AuthFailure(
        message: 'Not authenticated',
        statusCode: 401,
      ));
    }

    // Read file
    final file = File(filePath);
    if (!await file.exists()) {
      return const Left(ServerFailure(message: 'File not found'));
    }

    final bytes = await file.readAsBytes();
    final fileName = filePath.split('/').last;

    // Detect MIME type
    final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';

    // Upload
    final uploadResult = await uploadAvatar(
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
      contentType: mimeType,
    );

    return uploadResult.fold(
      (failure) => Left(failure),
      (mxcUri) async {
        // Set avatar URL
        final setResult = await setAvatarUrl(mxcUri);
        return setResult;
      },
    );
  }

  Future<void> _updateLocalDisplayName(String displayName) async {
    try {
      // TODO: Update stored user profile
      _logger.i('Updated local display name to: $displayName');
    } catch (e) {
      _logger.e('Error updating local display name', error: e);
    }
  }
}

class _Credentials {
  const _Credentials({
    required this.accessToken,
    required this.homeserver,
    required this.userId,
  });

  final String accessToken;
  final String homeserver;
  final String userId;
}
