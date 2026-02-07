import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:rxdart/rxdart.dart';

/// Matrix client service - integrates the Matrix SDK (Famedly)
///
/// This service provides a wrapper around the Matrix SDK with dependency injection
/// support and connection status tracking.
@singleton
class MatrixClientService {
  MatrixClientService({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  /// The Matrix SDK client (Famedly)
  matrix.Client? _client;

  /// Subject for connection status
  final BehaviorSubject<ConnectionStatus> _connectionStatus =
      BehaviorSubject.seeded(ConnectionStatus.disconnected);

  /// Stream of connection status
  Stream<ConnectionStatus> get connectionStatusStream => _connectionStatus.stream;

  /// Current connection status
  ConnectionStatus get connectionStatus => _connectionStatus.value;

  /// Check if client is initialized
  bool get isInitialized => _client != null;

  /// Get the Matrix client (throws if not initialized)
  matrix.Client get client {
    if (_client == null) {
      throw StateError('Matrix client not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Initialize the Matrix client
  Future<bool> initialize({
    required String homeserver,
    required String accessToken,
    required String userId,
    String? deviceId,
  }) async {
    _logger.i('Initializing Matrix SDK client');
    _logger.i('Homeserver: $homeserver');
    _logger.i('User: $userId');

    try {
      final homeserverUri = _normalizeHomeserver(homeserver);

      // Create the Matrix client (Famedly SDK)
      _client ??= matrix.Client(
        'voxmatrix',
        databaseBuilder: (client) async {
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

      await _client!.init(
        newToken: accessToken,
        newUserID: userId,
        newDeviceID: deviceId ?? 'VOXMATRIX',
        newDeviceName: 'VoxMatrix',
        newHomeserver: homeserverUri,
        waitForFirstSync: false,
        waitUntilLoadCompletedLoaded: false,
      );

      // Start background sync
      _client!.backgroundSync = true;

      _logger.i('Matrix SDK initialized successfully');
      _connectionStatus.add(ConnectionStatus.connected);
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Matrix SDK', error: e, stackTrace: stackTrace);
      _connectionStatus.add(ConnectionStatus.error);
      _client = null;
      return false;
    }
  }

  Uri _normalizeHomeserver(String homeserver) {
    final trimmed = homeserver.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Uri.parse(trimmed);
    }
    return Uri.parse('http://$trimmed');
  }

  /// Start syncing (already started by connect(), but can be called separately)
  Future<void> startSync() async {
    if (_client == null) {
      _logger.w('Cannot start sync - client not initialized');
      return;
    }
    _client!.backgroundSync = true;
    _logger.d('Matrix SDK background sync enabled');
  }

  /// Stop syncing
  Future<void> stopSync() async {
    if (_client == null) {
      _logger.w('Cannot stop sync - client not initialized');
      return;
    }
    _client!.backgroundSync = false;
    _logger.i('Sync stopped');
  }

  /// Check if E2EE is enabled
  bool get isE2EEEnabled => _client?.encryptionEnabled == true;

  /// Cleanup resources
  Future<void> dispose() async {
    await _client?.dispose();
    _client = null;
    await _connectionStatus.close();
  }
}

/// Connection status enum
enum ConnectionStatus {
  /// Disconnected from the homeserver
  disconnected,

  /// Connected to the homeserver
  connected,

  /// Currently syncing
  syncing,

  /// Connection error
  error,
}
