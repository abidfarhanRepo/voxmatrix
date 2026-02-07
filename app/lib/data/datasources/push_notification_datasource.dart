import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';

/// Push notification datasource - handles Matrix push notifications via FCM
/// See: https://spec.matrix.org/v1.11/client-server-api/#push-notifications
@injectable
class PushNotificationDataSource {
  const PushNotificationDataSource(this._logger);

  final Logger _logger;

  /// Register push notifications with Matrix homeserver
  /// POST /_matrix/client/v3/pushers/set
  Future<Either<Failure, void>> registerPusher({
    required String homeserver,
    required String accessToken,
    required String pushKey,
    required String appId,
    required String appDisplayName,
    required String deviceDisplayName,
    required String profileTag,
    String lang = 'en',
  }) async {
    try {
      final baseUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$baseUrl/_matrix/client/v3/pushers/set');

      final body = {
        'pushkey': pushKey,
        'kind': 'http',
        'app_id': appId,
        'app_display_name': appDisplayName,
        'device_display_name': deviceDisplayName,
        'profile_tag': profileTag,
        'lang': lang,
        'data': {
          'url': 'https://matrix.org/_matrix/push/v1/notify',
          'format': 'event_id_only',
        },
      };

      _logger.i('Registering pusher for device: $deviceDisplayName');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('Pusher registered successfully');
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to register pusher',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error registering pusher', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Unregister push notifications
  /// POST /_matrix/client/v3/pushers/set with null append
  Future<Either<Failure, void>> unregisterPusher({
    required String homeserver,
    required String accessToken,
    required String pushKey,
  }) async {
    try {
      final baseUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$baseUrl/_matrix/client/v3/pushers/set');

      final body = {
        'pushkey': pushKey,
        'kind': null,
        'app_id': 'org.matrix.voxmatrix',
        'app_display_name': 'VoxMatrix',
        'device_display_name': 'VoxMatrix',
      };

      _logger.i('Unregistering pusher');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('Pusher unregistered successfully');
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to unregister pusher',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error unregistering pusher', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get push rules
  /// GET /_matrix/client/v3/pushrules/
  Future<Either<Failure, Map<String, dynamic>>> getPushRules({
    required String homeserver,
    required String accessToken,
  }) async {
    try {
      final baseUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$baseUrl/_matrix/client/v3/pushrules/');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to get push rules',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error getting push rules', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Enable/disable push rule
  /// PUT /_matrix/client/v3/pushrules/{scope}/{kind}/{ruleId}/enabled
  Future<Either<Failure, void>> setPushRuleEnabled({
    required String homeserver,
    required String accessToken,
    required String scope,
    required String kind,
    required String ruleId,
    required bool enabled,
  }) async {
    try {
      final baseUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse(
        '$baseUrl/_matrix/client/v3/pushrules/$scope/$kind/$ruleId/enabled',
      );

      final body = {'enabled': enabled};

      _logger.i('Setting push rule enabled: $ruleId -> $enabled');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to set push rule',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error setting push rule', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
