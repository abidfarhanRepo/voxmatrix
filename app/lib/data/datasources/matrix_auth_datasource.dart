import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:sqflite/sqflite.dart' as sqflite;

/// Matrix authentication datasource using the matrix SDK
class MatrixAuthDataSource {
  const MatrixAuthDataSource({
    required Logger logger,
    required FlutterSecureStorage secureStorage,
  })  : _logger = logger,
        _secureStorage = secureStorage;

  final Logger _logger;
  final FlutterSecureStorage _secureStorage;

  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _homeserverKey = 'homeserver';
  static const String _deviceIdKey = 'device_id';
  static const String _syncTokenKey = 'sync_token';

  /// Matrix client instance (created after login)
  matrix.Client? _client;

  /// Get the current Matrix client
  matrix.Client? get client => _client;

  /// Login to Matrix homeserver
  Future<Map<String, dynamic>> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    _logger.i('Logging in to $homeserver as $username');

    try {
      // Create a new Matrix client
      _client = matrix.Client(
        'voxmatrix',
        enableE2ee: true,
        databaseBuilder: (matrix.Client client) async {
          final dbPath = await sqflite.getDatabasesPath();
          final sqliteDb = await sqflite.openDatabase('$dbPath/voxmatrix.sqlite');
          final db = matrix.MatrixSdkDatabase(
            'voxmatrix',
            database: sqliteDb,
          );
          await db.open();
          return db;
        },
      );

      await _client!.checkHomeserver(Uri.parse(homeserver));

      // Perform login
      final loginResponse = await _client!.login(
        type: matrix.LoginType.mLoginPassword,
        identifier: matrix.AuthenticationIdentifier(
          type: matrix.AuthenticationIdentifierTypes.user,
          user: username,
        ),
        password: password,
      );

      final response = {
        'access_token': loginResponse.accessToken,
        'user_id': loginResponse.userId,
        'device_id': loginResponse.deviceId,
        'homeserver': homeserver,
      };

      // Store session
      await _secureStorage.write(key: _accessTokenKey, value: response['access_token'] as String);
      await _secureStorage.write(key: _userIdKey, value: response['user_id'] as String);
      await _secureStorage.write(key: _homeserverKey, value: response['homeserver'] as String);
      await _secureStorage.write(key: _deviceIdKey, value: response['device_id'] as String);

      _logger.i('Login successful for ${response['user_id']}');
      return response;
    } catch (e, stackTrace) {
      _logger.e('Login failed', error: e, stackTrace: stackTrace);
      throw _handleMatrixError(e);
    }
  }

  /// Register a new account
  Future<Map<String, dynamic>> register({
    required String homeserver,
    required String username,
    required String password,
    String? email,
  }) async {
    _logger.i('Registering on $homeserver as $username');

    try {
      // Create a new Matrix client
      _client = matrix.Client(
        'voxmatrix',
        enableE2ee: true,
      );

      await _client!.checkHomeserver(Uri.parse(homeserver));

      // Check if registration is available
      await _client!.registerIsSupported();

      // Perform registration
      final registerResponse = await _client!.register(
        username: username,
        password: password,
        auth: matrix.AuthenticationData(
          type: matrix.AuthenticationTypes.mLoginDummy,
        ),
      );

      final response = {
        'access_token': registerResponse.accessToken ?? '',
        'user_id': registerResponse.userId ?? '',
        'device_id': registerResponse.deviceId ?? '',
        'homeserver': homeserver,
      };

      // Store session
      if (response['access_token'] != null) {
        await _secureStorage.write(key: _accessTokenKey, value: response['access_token'] as String);
        await _secureStorage.write(key: _userIdKey, value: response['user_id'] as String);
        await _secureStorage.write(key: _homeserverKey, value: response['homeserver'] as String);
        await _secureStorage.write(key: _deviceIdKey, value: response['device_id'] as String);
      }

      _logger.i('Registration successful for ${response['user_id']}');
      return response;
    } catch (e, stackTrace) {
      _logger.e('Registration failed', error: e, stackTrace: stackTrace);
      throw _handleMatrixError(e);
    }
  }

  /// Restore an existing session from stored credentials
  Future<matrix.Client> restoreSession() async {
    _logger.i('Restoring existing session');

    try {
      final accessToken = await getAccessToken();
      final userId = await getUserId();
      final homeserver = await getHomeserver();
      final deviceId = await _secureStorage.read(key: _deviceIdKey);

      if (accessToken == null || userId == null || homeserver == null) {
        throw Exception('No stored session found');
      }

      // Create client with stored credentials
      _client = matrix.Client(
        'voxmatrix',
        enableE2ee: true,
        databaseBuilder: (matrix.Client client) async {
          final dbPath = await sqflite.getDatabasesPath();
          final sqliteDb = await sqflite.openDatabase('$dbPath/voxmatrix.sqlite');
          final db = matrix.MatrixSdkDatabase(
            'voxmatrix',
            database: sqliteDb,
          );
          await db.open();
          return db;
        },
      );

      // Restore session
      await _client!.checkHomeserver(matrix.MatrixApis(
        accessToken: accessToken,
        userId: matrix.UserID(userId),
        deviceId: deviceId,
        homeserver: Uri.parse(homeserver),
      ));

      _logger.i('Session restored for $userId');
      return _client!;
    } catch (e, stackTrace) {
      _logger.e('Session restore failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    _logger.i('Logging out');

    try {
      if (_client != null) {
        // Logout from Matrix server
        await _client!.logout();
      }
    } catch (e) {
      _logger.w('Server logout failed: $e');
    } finally {
      // Always clear local storage
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _homeserverKey);
      await _secureStorage.delete(key: _deviceIdKey);
      await _secureStorage.delete(key: _syncTokenKey);

      _client = null;
      _logger.i('Logout successful');
    }
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// Get stored homeserver
  Future<String?> getHomeserver() async {
    return await _secureStorage.read(key: _homeserverKey);
  }

  /// Get stored device ID
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: _deviceIdKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get session info
  Future<Map<String, String?>> getSession() async {
    return {
      'access_token': await getAccessToken(),
      'user_id': await getUserId(),
      'homeserver': await getHomeserver(),
      'device_id': await _secureStorage.read(key: _deviceIdKey),
    };
  }

  /// Discover homeserver URL from domain
  Future<String> discoverHomeserver(String domain) async {
    _logger.i('Discovering homeserver for $domain');

    try {
      // If domain already looks like a URL, return it
      if (domain.startsWith('http://') || domain.startsWith('https://')) {
        return domain;
      }

      // Try to discover via .well-known
      final client = matrix.Client('voxmatrix');

      await client.checkHomeserver(Uri.parse('https://$domain'));

      return client.homeserver.toString();
    } catch (e) {
      _logger.w('Homeserver discovery failed for $domain, using default');
      // Fall back to assuming matrix.domain.com
      return 'https://matrix.$domain';
    }
  }

  /// Handle Matrix SDK errors and convert to readable messages
  Exception _handleMatrixError(dynamic error) {
    if (error is matrix.MatrixException) {
      switch (error.error) {
        case matrix.MatrixError.M_FORBIDDEN:
          return Exception('Invalid username or password');
        case matrix.MatrixError.M_USER_IN_USE:
          return Exception('Username already taken');
        case matrix.MatrixError.M_INVALID_USERNAME:
          return Exception('Invalid username format');
        case matrix.MatrixError.M_WEAK_PASSWORD:
          return Exception('Password is too weak');
        case matrix.MatrixError.M_UNAUTHORIZED:
          return Exception('Unauthorized');
        case matrix.MatrixError.M_LIMIT_EXCEEDED:
          return Exception('Too many attempts. Try again later');
        default:
          return Exception(error.message);
      }
    }
    return Exception(error.toString());
  }
}
