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

  /// Completer for initialization - signals when initialization is complete
  Completer<bool>? _initializationCompleter;

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

  /// Wait for the Matrix client to be initialized
  /// 
  /// Returns true if initialization succeeded, false if timeout or failed.
  /// This is useful when the client might be initializing in the background.
  Future<bool> waitForInitialization({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // Already initialized
    if (_client != null) {
      _logger.d('Matrix client already initialized');
      return true;
    }

    _logger.d('Waiting for Matrix client initialization (timeout: ${timeout.inSeconds}s)');

    // Create completer if not already created
    _initializationCompleter ??= Completer<bool>();

    try {
      final result = await _initializationCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          _logger.w('Matrix client initialization timeout after ${timeout.inSeconds}s');
          return false;
        },
      );
      return result;
    } catch (e) {
      _logger.e('Error waiting for initialization', error: e);
      return false;
    }
  }

  /// Get client or wait for it to initialize
  /// 
  /// Throws if client fails to initialize or timeout occurs.
  /// Use [waitForInitialization] if you want to handle failures gracefully.
  Future<matrix.Client> getClientOrWait({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_client != null) {
      return _client!;
    }

    final ready = await waitForInitialization(timeout: timeout);
    if (!ready) {
      throw StateError('Matrix client failed to initialize within $timeout');
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

    // If already initialized, return immediately
    if (_client != null) {
      _logger.d('Matrix client already initialized');
      return true;
    }

    // If initialization is already in progress, return the existing future
    if (_initializationCompleter != null) {
      _logger.d('Matrix client initialization already in progress; awaiting result');
      return _initializationCompleter!.future;
    }

    // Mark initialization as in-progress so concurrent callers can await it
    _initializationCompleter = Completer<bool>();

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

      // Signal that initialization is complete
      if (_initializationCompleter != null && !_initializationCompleter!.isCompleted) {
        _initializationCompleter!.complete(true);
      }
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Matrix SDK', error: e, stackTrace: stackTrace);
      _connectionStatus.add(ConnectionStatus.error);
      _client = null;
      // Signal that initialization failed
      if (_initializationCompleter != null && !_initializationCompleter!.isCompleted) {
        _initializationCompleter!.complete(false);
      }
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
    
    // Complete the initialization completer if pending
    if (_initializationCompleter != null && !_initializationCompleter!.isCompleted) {
      _initializationCompleter!.complete(false);
    }
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
