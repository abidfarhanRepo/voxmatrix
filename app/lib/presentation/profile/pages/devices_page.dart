import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/presentation/profile/bloc/profile_bloc.dart';

/// Devices management page
class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  bool _isLoading = false;
  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load devices from Matrix SDK
      // For now, showing a placeholder
      setState(() {
        _devices = [
          Device(
            id: 'CURRENT_DEVICE',
            name: 'This Device',
            lastSeen: DateTime.now(),
            isCurrent: true,
            isVerified: true,
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return _buildDeviceTile(device);
              },
            ),
    );
  }

  Widget _buildDeviceTile(Device device) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          device.isCurrent ? Icons.smartphone : Icons.devices,
          color: AppColors.primary,
        ),
      ),
      title: Row(
        children: [
          Text(device.name),
          if (device.isCurrent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'CURRENT',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${device.id}'),
          if (device.lastSeen != null)
            Text(
              'Last seen: ${DateFormat.yMMMd().add_jm().format(device.lastSeen!)}',
            ),
          if (device.isVerified)
            Row(
              children: [
                const Icon(
                  Icons.verified_user,
                  size: 14,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: device.isCurrent
          ? null
          : PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'verify') {
                  _verifyDevice(device);
                } else if (value == 'logout') {
                  _logoutDevice(device);
                } else if (value == 'block') {
                  _blockDevice(device);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'verify',
                  child: Row(
                    children: [
                      Icon(Icons.verified_user, size: 18),
                      SizedBox(width: 12),
                      Text('Verify'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 12),
                      Text('Sign out'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 18, color: AppColors.error),
                      SizedBox(width: 12),
                      Text('Block', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _verifyDevice(Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Device'),
        content: Text('Verify ${device.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle verification
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _logoutDevice(Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out Device'),
        content: Text('Sign out from ${device.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _blockDevice(Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Device'),
        content: Text(
          'Block ${device.name}?\n\n'
          'Blocked devices will not be able to read your encrypted messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle blocking
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}

/// Device model
class Device {
  const Device({
    required this.id,
    required this.name,
    this.lastSeen,
    this.isCurrent = false,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final DateTime? lastSeen;
  final bool isCurrent;
  final bool isVerified;
}
