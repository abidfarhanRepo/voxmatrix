import 'package:flutter/material.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/message_reply.dart';

/// Widget showing a preview of the message being replied to
class ReplyPreviewWidget extends StatelessWidget {
  const ReplyPreviewWidget({
    super.key,
    required this.reply,
    required this.onCancel,
  });

  final MessageReply reply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reply.senderName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reply.preview,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            tooltip: 'Cancel reply',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Widget showing in-message reply (reply within the message bubble)
class InMessageReplyPreview extends StatelessWidget {
  const InMessageReplyPreview({
    super.key,
    required this.senderName,
    required this.content,
    this.isCurrentUser = false,
  });

  final String senderName;
  final String content;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.onPrimary.withOpacity(0.15)
            : AppColors.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.onPrimary.withOpacity(0.4)
                  : AppColors.primary.withOpacity(0.5),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser
                        ? AppColors.onPrimary.withOpacity(0.8)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrentUser
                        ? AppColors.onPrimary.withOpacity(0.7)
                        : AppColors.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
