import 'package:injectable/injectable.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:voxmatrix/core/services/matrix_client_service.dart';

/// Service to handle device verification using Matrix SDK's built-in verification
@injectable
class DeviceVerificationService {
  DeviceVerificationService(this._matrixClientService);

  final MatrixClientService _matrixClientService;

  /// Get list of user's devices
  Future<List<DeviceInfo>> getUserDevices(String userId) async {
    if (!_matrixClientService.isInitialized) {
      throw Exception('Matrix client not initialized');
    }
    
    final client = _matrixClientService.client;
    
    // Query device keys from server if not cached
    final deviceKeysList = client.userDeviceKeys[userId];
    if (deviceKeysList == null || deviceKeysList.outdated) {
      await client.queryKeys({userId: []});
    }

    final deviceKeys = client.userDeviceKeys[userId]?.deviceKeys.values ?? [];
    
    return deviceKeys.map((deviceKey) {
      return DeviceInfo(
        deviceId: deviceKey.deviceId ?? '',
        deviceName: deviceKey.deviceDisplayName ?? 'Unknown Device',
        verified: deviceKey.verified,
        blocked: deviceKey.blocked,
        lastSeenTs: deviceKey.lastActive?.millisecondsSinceEpoch,
      );
    }).toList();
  }

  /// Verify a device (mark as trusted)
  Future<void> verifyDevice(String userId, String deviceId) async {
    if (!_matrixClientService.isInitialized) {
      throw Exception('Matrix client not initialized');
    }
    
    final client = _matrixClientService.client;

    final deviceKeys = client.userDeviceKeys[userId]?.deviceKeys[deviceId];
    if (deviceKeys != null) {
      await deviceKeys.setVerified(true);
    }
  }

  /// Block a device
  Future<void> blockDevice(String userId, String deviceId) async {
    if (!_matrixClientService.isInitialized) {
      throw Exception('Matrix client not initialized');
    }
    
    final client = _matrixClientService.client;

    final deviceKeys = client.userDeviceKeys[userId]?.deviceKeys[deviceId];
    if (deviceKeys != null) {
      await deviceKeys.setBlocked(true);
    }
  }
}

/// Device information
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final bool verified;
  final bool blocked;
  final int? lastSeenTs;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.verified,
    required this.blocked,
    this.lastSeenTs,
  });
}
