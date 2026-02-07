import 'package:flutter/material.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/room.dart';
import '../../widgets/glass_container.dart';

/// Widget displaying a single room in the room list
class RoomListItem extends StatelessWidget {
  const RoomListItem({
    super.key,
    required this.room,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  final RoomEntity room;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing,
        vertical: 6,
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: GlassContainer(
          borderRadius: 24,
          opacity: isSelected ? 0.25 : 0.1,
          color: isSelected ? AppColors.primary : Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(context),
              const SizedBox(width: 16),
              Expanded(child: _buildContent(context)),
              _buildTrailing(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final hasAvatar = room.avatarUrl != null && room.avatarUrl!.isNotEmpty;
    final displayName = room.name.isNotEmpty ? room.name : '?';

    Widget avatarChild;
    if (hasAvatar) {
      avatarChild = Hero(
        tag: 'avatar_${room.id}',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: ClipOval(
            child: Image.network(
              room.avatarUrl!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(displayName),
            ),
          ),
        ),
      );
    } else {
      avatarChild = Hero(
        tag: 'avatar_${room.id}',
        child: _buildFallbackAvatar(displayName),
      );
    }

    if (room.isDirect && room.members.isNotEmpty) {
      final member = room.members.first;
      if (member.presence == PresenceState.online) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            avatarChild,
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F172A), // Match mesh background base
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    return avatarChild;
  }

  Widget _buildFallbackAvatar(String displayName) {
    final colorIndex = displayName.hashCode % _avatarColors.length;
    final avatarColor = _avatarColors[colorIndex.abs()];

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: avatarColor.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: avatarColor.withOpacity(0.5), width: 1),
      ),
      child: Center(
        child: Text(
          displayName[0].toUpperCase(),
          style: TextStyle(
            color: avatarColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessage = room.lastMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                room.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (room.isMuted)
              Icon(Icons.volume_off, size: 14, color: AppColors.textSecondary),
            if (room.isFavourite)
              const Icon(Icons.star, size: 14, color: AppColors.warning),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          lastMessage != null
              ? '${lastMessage.senderName}: ${lastMessage.content}'
              : room.topic ?? 'No messages yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: room.unreadCount > 0
                ? AppColors.textPrimary.withOpacity(0.9)
                : AppColors.textSecondary,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (room.lastMessage != null)
          Text(
            _formatTimestamp(room.lastMessage!.timestamp),
            style: TextStyle(
              color: room.unreadCount > 0 ? AppColors.primary : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        if (room.unreadCount > 0) ...[
          const SizedBox(height: 6),
          _buildUnreadBadge(context),
        ],
      ],
    );
  }

  Widget _buildUnreadBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8),
        ],
      ),
      child: Text(
        room.unreadCount > 99 ? '99+' : room.unreadCount.toString(),
        style: const TextStyle(
          color: AppColors.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Material Design 3 inspired color palette for avatars
  static const _avatarColors = [
    Color(0xFF6200EE), // Deep Purple
    Color(0xFF3700B3), // Purple
    Color(0xFF03DAC6), // Teal
    Color(0xFF018786), // Cyan
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFF8BC34A), // Light Green
    Color(0xFFCDDC39), // Lime
    Color(0xFFFFC107), // Amber
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Deep Orange
  ];
}
