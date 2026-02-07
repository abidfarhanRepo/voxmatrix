import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/message_entity.dart';
import 'package:voxmatrix/presentation/chat/widgets/reaction_picker.dart';
import 'package:voxmatrix/presentation/widgets/glass_container.dart';

/// Widget displaying a single message bubble
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.previousMessage,
    this.showSenderName = true,
    this.onReactionTap,
    this.onLongPress,
  });

  final MessageEntity message;
  final bool isCurrentUser;
  final MessageEntity? previousMessage;
  final bool showSenderName;
  final ValueChanged<String>? onReactionTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderName && !isCurrentUser) _buildSenderName(context),
          Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCurrentUser) _buildAvatar(context),
              if (!isCurrentUser) const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: GestureDetector(
                        onLongPress: onLongPress,
                        child: GlassContainer(
                          borderRadius: 18,
                          blur: 10,
                          opacity: isCurrentUser ? 0.25 : 0.08,
                          color: isCurrentUser ? const Color(0xFFB30000) : Colors.white,
                          border: Border.all(
                            color: isCurrentUser 
                                ? const Color(0x4DB30000) 
                                : const Color(0x0DFFFFFF),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (message.replyToId != null) _buildReplyPreview(context),
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              if (message.attachments.isNotEmpty) _buildAttachments(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (message.reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                        child: MessageReactions(
                          reactions: message.reactions,
                          onReactionTap: onReactionTap,
                        ),
                      ),
                    const SizedBox(height: 4),
                    _buildMessageMeta(context),
                  ],
                ),
              ),
              if (isCurrentUser) const SizedBox(width: 8),
              if (isCurrentUser) _buildAvatar(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final hasAvatar = message.senderAvatarUrl != null && message.senderAvatarUrl!.isNotEmpty;
    final displayName = message.senderName.isNotEmpty ? message.senderName : '?';

    return Hero(
      tag: 'avatar_${message.id}_${message.senderId}',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: CircleAvatar(
          radius: 14,
          backgroundColor: _getAvatarColor(message.senderName).withOpacity(0.3),
          backgroundImage: hasAvatar ? NetworkImage(message.senderAvatarUrl!) : null,
          child: !hasAvatar
              ? Text(
                  displayName[0].toUpperCase(),
                  style: TextStyle(
                    color: _getAvatarColor(message.senderName),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSenderName(BuildContext context) {
    final shouldShow = previousMessage == null ||
        previousMessage!.senderId != message.senderId ||
        _isMoreThan5MinutesApart();

    if (!shouldShow) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 4),
      child: Text(
        message.senderName,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isCurrentUser ? Colors.black.withOpacity(0.3) : AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Text(
        'Replying to a message',
        style: TextStyle(
          color: isCurrentUser ? Colors.black.withOpacity(0.6) : AppColors.textSecondary,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: message.attachments.map((attachment) {
          return _buildAttachment(context, attachment);
        }).toList(),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, attachment) {
    switch (attachment.type) {
      case AttachmentType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            attachment.thumbnailUrl ?? attachment.url,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFileAttachment(context, attachment);
            },
          ),
        );
      default:
        return _buildFileAttachment(context, attachment);
    }
  }

  Widget _buildFileAttachment(BuildContext context, attachment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.onPrimary.withOpacity(0.1)
            : AppColors.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(attachment.type),
            color: isCurrentUser
                ? AppColors.onPrimary.withOpacity(0.7)
                : AppColors.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  attachment.name,
                  style: TextStyle(
                    color: isCurrentUser
                        ? AppColors.onPrimary
                        : AppColors.onSurface,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (attachment.size != null)
                Text(
                  _formatFileSize(attachment.size!),
                  style: TextStyle(
                    color: isCurrentUser
                        ? AppColors.onPrimary.withOpacity(0.7)
                        : AppColors.onSurface.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageMeta(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isCurrentUser
                    ? AppColors.messageSentTime
                    : AppColors.messageReceivedTime,
                fontSize: 10,
              ),
        ),
        if (isCurrentUser) ...[
          const SizedBox(width: 4),
          _buildReadReceipt(context),
        ],
        if (message.editedTimestamp != null) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.edit,
            size: 10,
            color: isCurrentUser
                ? AppColors.messageSentTime
                : AppColors.messageReceivedTime,
          ),
        ],
      ],
    );
  }

  Widget _buildReadReceipt(BuildContext context) {
    final readCount = message.readReceipts.length;

    IconData icon;
    Color color;

    if (readCount == 0) {
      icon = Icons.check;
      color = isCurrentUser
          ? AppColors.messageSentTime
          : AppColors.messageReceivedTime;
    } else if (readCount == 1) {
      icon = Icons.done_all;
      color = isCurrentUser
          ? AppColors.messageSentTime
          : AppColors.messageReceivedTime;
    } else {
      icon = Icons.done_all;
      color = AppColors.primary;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  BorderRadius _getBorderRadius() {
    const radius = 12.0;

    if (isCurrentUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(4),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(radius),
      );
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6200EE),
      const Color(0xFFE91E63),
      const Color(0xFF009688),
      const Color(0xFFFFC107),
      const Color(0xFF2196F3),
      const Color(0xFFFF5722),
    ];

    if (name.isEmpty) return colors.first;
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  IconData _getFileIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.video:
        return Icons.videocam;
      case AttachmentType.audio:
        return Icons.audio_file;
      case AttachmentType.file:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(timestamp);
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  bool _isMoreThan5MinutesApart() {
    if (previousMessage == null) return false;

    final difference =
        message.timestamp.difference(previousMessage!.timestamp);
    return difference.inMinutes > 5;
  }
}
