import 'package:logger/logger.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';

/// Diagnostic helper for debugging Matrix client initialization issues
class MatrixInitializationDiagnostics {
  MatrixInitializationDiagnostics({
    required MatrixClientService matrixClientService,
    required Logger logger,
  })  : _matrixClientService = matrixClientService,
        _logger = logger;

  final MatrixClientService _matrixClientService;
  final Logger _logger;

  /// Get comprehensive diagnostic report
  String getDiagnosticReport() {
    final buffer = StringBuffer();

    buffer.writeln('=== Matrix Client Initialization Diagnostics ===');
    buffer.writeln('');

    // 1. Client Status
    buffer.writeln('## Client Status');
    buffer.writeln('Is Initialized: ${_matrixClientService.isInitialized}');
    buffer.writeln('Connection Status: ${_matrixClientService.connectionStatus}');
    buffer.writeln('');

    // 2. Client Details (if available)
    if (_matrixClientService.isInitialized) {
      try {
        final client = _matrixClientService.client;
        buffer.writeln('## Client Details');
        buffer.writeln('User ID: ${client.userID ?? "N/A"}');
        buffer.writeln('Device ID: ${client.deviceID ?? "N/A"}');
        buffer.writeln('Homeserver: ${client.homeserver ?? "N/A"}');
        buffer.writeln('E2EE Enabled: ${client.encryptionEnabled}');
        buffer.writeln('Background Sync: ${client.backgroundSync}');
        buffer.writeln('Rooms Count: ${client.rooms.length}');
        buffer.writeln('');
      } catch (e) {
        buffer.writeln('## Client Details');
        buffer.writeln('Error retrieving client details: $e');
        buffer.writeln('');
      }
    }

    // 3. Timeline
    buffer.writeln('## Initialization Timeline');
    buffer.writeln('(Use InitializationLogger.printSummary() for full timeline)');
    buffer.writeln('');

    // 4. Recommendations
    buffer.writeln('## Recommendations');
    if (!_matrixClientService.isInitialized) {
      buffer
          .writeln('⚠️  Client not initialized - Call initialize() on MatrixClientService');
      buffer.writeln('   or wait for it to complete using waitForInitialization()');
    } else {
      buffer.writeln('✅ Client is properly initialized');
    }
    buffer.writeln('');

    return buffer.toString();
  }

  /// Check specific component status
  void checkComponentStatus(String component) {
    _logger.i('=== Checking $component Status ===');

    switch (component.toLowerCase()) {
      case 'matrix':
      case 'client':
      case 'sdk':
        _logger.i('Matrix Client Status:');
        _logger.i('  - Initialized: ${_matrixClientService.isInitialized}');
        _logger.i(
            '  - Connection: ${_matrixClientService.connectionStatus.toString().split('.').last}');
        break;

      case 'chat':
        _logger.i('Chat Component Status:');
        _logger.i('  - Ensure MatrixClientService.waitForInitialization() is called');
        _logger.i('  - Check ChatBloc._ensureMatrixClientReady() implementation');
        break;

      case 'dm':
      case 'directmessages':
        _logger.i('Direct Messages Component Status:');
        _logger.i('  - Ensure MatrixClientService.waitForInitialization() is called');
        _logger.i(
            '  - Check DirectMessagesBloc._ensureMatrixClientReady() implementation');
        break;

      default:
        _logger.w('Unknown component: $component');
    }
  }

  /// Test initialization with timeout
  Future<void> testInitializationWithTimeout({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    _logger.i('Testing initialization with timeout: ${timeout.inSeconds}s');

    final startTime = DateTime.now();
    final ready = await _matrixClientService.waitForInitialization(timeout: timeout);
    final duration = DateTime.now().difference(startTime);

    _logger.i('Initialization result:');
    _logger.i('  - Ready: $ready');
    _logger.i('  - Duration: ${duration.inMilliseconds}ms');
    _logger.i('  - Timeout: ${timeout.inMilliseconds}ms');
  }

  /// Print full diagnostic report
  void printDiagnosticReport() {
    final report = getDiagnosticReport();
    _logger.i(report);
  }
}

/// Extension on MatrixClientService for convenient diagnostics
extension DiagnosticsExtension on MatrixClientService {
  /// Get a quick status string
  String getStatus() {
    return 'Initialized: $isInitialized, Connection: $connectionStatus';
  }

  /// Check if client is ready to use
  bool isReadyToUse() {
    return isInitialized && connectionStatus == ConnectionStatus.connected;
  }
}
