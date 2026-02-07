import 'package:flutter/material.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/crypto.dart';

/// Widget showing encryption status for a room
class EncryptionIndicator extends StatelessWidget {
  const EncryptionIndicator({
    super.key,
    required this.state,
    this.showLabel = false,
    this.iconSize = 16,
  });

  final RoomEncryptionState state;
  final bool showLabel;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case RoomEncryptionState.encrypted:
        return _buildIndicator(
          icon: Icons.lock,
          color: Colors.green,
          label: 'Encrypted',
        );
      case RoomEncryptionState.encryptedUnverified:
        return _buildIndicator(
          icon: Icons.lock_outline,
          color: Colors.orange,
          label: 'Encrypted (unverified)',
        );
      case RoomEncryptionState.unencrypted:
        return _buildIndicator(
          icon: Icons.lock_open,
          color: Colors.grey,
          label: 'Not encrypted',
        );
      case RoomEncryptionState.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIndicator({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: iconSize,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Badge showing encryption status
class EncryptionBadge extends StatelessWidget {
  const EncryptionBadge({
    super.key,
    required this.state,
  });

  final RoomEncryptionState state;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (state) {
      case RoomEncryptionState.encrypted:
        color = Colors.green;
        label = 'E2EE';
        break;
      case RoomEncryptionState.encryptedUnverified:
        color = Colors.orange;
        label = 'E2EE!';
        break;
      case RoomEncryptionState.unencrypted:
        color = Colors.grey;
        label = 'No E2EE';
        break;
      case RoomEncryptionState.unknown:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Full encryption info widget for settings
class EncryptionInfoWidget extends StatelessWidget {
  const EncryptionInfoWidget({
    super.key,
    required this.state,
    this.algorithm,
  });

  final RoomEncryptionState state;
  final EncryptionAlgorithm? algorithm;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String title;
    String? description;

    switch (state) {
      case RoomEncryptionState.encrypted:
        icon = Icons.lock;
        color = Colors.green;
        title = 'Encrypted';
        description = 'Messages are end-to-end encrypted. Only you and the recipients can read them.';
        break;
      case RoomEncryptionState.encryptedUnverified:
        icon = Icons.warning;
        color = Colors.orange;
        title = 'Encrypted (Unverified)';
        description = 'Messages are encrypted but some devices are unverified. Verify devices for better security.';
        break;
      case RoomEncryptionState.unencrypted:
        icon = Icons.lock_open;
        color = Colors.grey;
        title = 'Not Encrypted';
        description = 'Messages are not encrypted. Anyone on the network could potentially read them.';
        break;
      case RoomEncryptionState.unknown:
        icon = Icons.help_outline;
        color = Colors.grey;
        title = 'Unknown';
        description = 'Unable to determine encryption status.';
        break;
    }

    String? algorithmName;
    if (algorithm != null) {
      algorithmName = algorithm == EncryptionAlgorithm.megolmV1
          ? 'Megolm v1 AES-SHA2'
          : 'Olm v1 Curve25519';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description != null)
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (algorithmName != null)
                  Text(
                    'Algorithm: $algorithmName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
