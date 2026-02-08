import 'package:flutter/material.dart';
import 'package:voxmatrix/core/config/injection_container.dart' as di;
import 'package:voxmatrix/core/services/device_verification_service.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';

/// Devices page - shows user's devices and their verification status
class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  late final DeviceVerificationService _verificationService;
  late final AuthLocalDataSource _authLocalDataSource;
  List<DeviceInfo>? _devices;
  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _verificationService = di.sl<DeviceVerificationService>();
    _authLocalDataSource = di.sl<AuthLocalDataSource>();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user ID
      _userId = await _authLocalDataSource.getUserId();
      
      if (_userId == null) {
        setState(() {
          _errorMessage = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      final devices = await _verificationService.getUserDevices(_userId!);
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load devices: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyDevice(DeviceInfo device) async {
    if (_userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Device'),
        content: Text(
          'Mark "${device.deviceName}" as verified? '
          'This should only be done after confirming device security through another method.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _verificationService.verifyDevice(_userId!, device.deviceId);
      if (mounted) {
        _loadDevices();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device marked as verified'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _blockDevice(DeviceInfo device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Device'),
        content: Text(
          'Are you sure you want to block "${device.deviceName}"? '
          'Messages from this device will not be readable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true && _userId != null) {
      await _verificationService.blockDevice(_userId!, device.deviceId);
      if (mounted) {
        _loadDevices();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device blocked'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDevices,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_devices == null || _devices!.isEmpty) {
      return const Center(
        child: Text('No devices found'),
      );
    }

    return Column(
      children: [
        _buildE2EEInfoBanner(),
        Expanded(
          child: ListView.builder(
            itemCount: _devices!.length,
            itemBuilder: (context, index) {
              return _buildDeviceCard(_devices![index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildE2EEInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verify devices to enable end-to-end encryption. Only verified devices can decrypt your messages.',
              style: TextStyle(color: Colors.blue[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(DeviceInfo device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          device.verified
              ? Icons.verified_user
              : (device.blocked ? Icons.block : Icons.devices),
          color: _getStatusColor(device),
          size: 32,
        ),
        title: Text(
          device.deviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Device ID: ${device.deviceId}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(device).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(device)),
                  ),
                  child: Text(
                    _getStatusText(device),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(device),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (device.lastSeenTs != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatLastSeen(device.lastSeenTs!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'verify':
                _verifyDevice(device);
                break;
              case 'block':
                _blockDevice(device);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!device.verified)
              const PopupMenuItem(
                value: 'verify',
                child: Row(
                  children: [
                    Icon(Icons.verified_user, size: 20),
                    SizedBox(width: 8),
                    Text('Verify'),
                  ],
                ),
              ),
            if (!device.blocked)
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DeviceInfo device) {
    if (device.blocked) return Colors.red;
    if (device.verified) return Colors.green;
    return Colors.orange;
  }

  String _getStatusText(DeviceInfo device) {
    if (device.blocked) return 'Blocked';
    if (device.verified) return 'Verified';
    return 'Unverified';
  }

  String _formatLastSeen(int timestamp) {
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Active now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}
