import 'package:dartz/dartz.dart';
import 'package:voxmatrix/core/error/failures.dart';

abstract class ProfileRepository {
  /// Get the current user's profile
  Future<Either<Failure, Map<String, dynamic>>> getProfile();

  /// Update display name
  Future<Either<Failure, void>> setDisplayName(String displayName);

  /// Update avatar URL
  Future<Either<Failure, void>> setAvatarUrl(String avatarUrl);

  /// Upload avatar and return MXC URI
  Future<Either<Failure, String>> uploadAvatar({
    required String filePath,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  });

  /// Upload avatar from file path and set it
  Future<Either<Failure, void>> updateAvatar(String filePath);
}
