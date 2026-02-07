import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';

/// Auth remote datasource - implements Matrix Client-Server API
/// See: https://spec.matrix.org/v1.11/client-server-api/
class AuthRemoteDataSource {
  const AuthRemoteDataSource();

  /// Normalize homeserver URL to ensure it has a protocol
  String _normalizeHomeserverUrl(String homeserver) {
    if (homeserver.startsWith('http://') || homeserver.startsWith('https://')) {
      return homeserver;
    }
    // Default to https for external servers, http for local
    if (homeserver.contains('localhost') ||
        homeserver.contains('127.0.0.1') ||
        homeserver.contains('.local')) {
      return 'http://$homeserver';
    }
    return 'https://$homeserver';
  }

  /// Get the _matrix client URL for a homeserver
  String _getMatrixUrl(String homeserver) {
    final url = _normalizeHomeserverUrl(homeserver);
    // Remove trailing slash
    final cleanUrl = url.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/client/v3';
  }

  /// Login with username and password
  /// POST /_matrix/client/v3/login
  Future<Either<Failure, Map<String, dynamic>>> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final url = Uri.parse('$baseUrl/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'm.login.password',
          'user': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right({
          ...data,
          'homeserver': _normalizeHomeserverUrl(homeserver),
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException(
          message: 'Invalid username or password',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 404) {
        throw ServerException(
          message: 'Homeserver not found',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Register a new account
  /// POST /_matrix/client/v3/register
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String homeserver,
    required String username,
    required String password,
    String? email,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final url = Uri.parse('$baseUrl/register');

      // First, check what registration flows are available
      final registerUrl = Uri.parse('$baseUrl/register');

      final response = await http.post(
        registerUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'auth': {'type': 'm.login.dummy'},
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right({
          ...data,
          'homeserver': _normalizeHomeserverUrl(homeserver),
        });
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw ValidationException(
          message: error['error'] as String? ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        final error = jsonDecode(response.body);
        throw AuthException(
          message: error['error'] as String? ?? 'Registration forbidden',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message, statusCode: e.statusCode));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Logout
  /// POST /_matrix/client/v3/logout
  Future<Either<Failure, void>> logout({
    required String homeserver,
    required String accessToken,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final url = Uri.parse('$baseUrl/logout');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return const Right(null);
      } else {
        throw ServerException(
          message: 'Logout failed',
          statusCode: response.statusCode,
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get the user's profile
  /// GET /_matrix/client/v3/profile/{userId}
  Future<Either<Failure, Map<String, dynamic>>> getUserProfile({
    required String homeserver,
    required String accessToken,
    required String userId,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final url = Uri.parse('$baseUrl/profile/$userId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else {
        throw ServerException(
          message: 'Failed to fetch profile',
          statusCode: response.statusCode,
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Verify the homeserver is accessible
  /// GET /_matrix/client/versions
  Future<Either<Failure, Map<String, dynamic>>> getVersions({
    required String homeserver,
  }) async {
    try {
      final url = _normalizeHomeserverUrl(homeserver);
      final versionsUrl = Uri.parse('$url/_matrix/client/versions');

      final response = await http.get(
        versionsUrl,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else {
        throw ServerException(
          message: 'Homeserver not accessible',
          statusCode: response.statusCode,
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Check if a username is available
  /// GET /_matrix/client/v3/register/available?username={username}
  Future<Either<Failure, bool>> checkUsernameAvailability({
    required String homeserver,
    required String username,
  }) async {
    try {
      final baseUrl = _getMatrixUrl(homeserver);
      final url = Uri.parse('$baseUrl/register/available?username=$username');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final available = data['available'] as bool? ?? false;
        return Right(available);
      } else {
        return const Right(false);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
