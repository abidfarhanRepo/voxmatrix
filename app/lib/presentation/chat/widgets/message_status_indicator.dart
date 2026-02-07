import 'package:flutter/material.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';

/// Message status indicator (sending, sent, delivered, read)
class MessageStatusIndicator extends StatelessWidget {
  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.size = 16,
  });

  final MessageStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: size,
          color: Colors.grey,
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: size,
          color: Colors.grey,
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: size,
          color: AppColors.primary,
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: size,
          color: Colors.red,
        );
    }
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}
