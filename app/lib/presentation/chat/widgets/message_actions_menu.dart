import 'package:flutter/material.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/message.dart';

/// Message action type
enum MessageAction {
  reply,
  edit,
  delete,
  copy,
  forward,
  pin,
  unpin,
  react,
  quote,
  report,
  retry,
  download,
}

/// Callback for message actions
typedef MessageActionCallback = void Function(MessageAction action);

/// Message actions menu bottom sheet
class MessageActionsMenu extends StatelessWidget {
  const MessageActionsMenu({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.onAction,
    this.canEdit = false,
    this.canDelete = false,
    this.canPin = false,
    this.isPinned = false,
  });

  final MessageEntity message;
  final bool isCurrentUser;
  final MessageActionCallback onAction;
  final bool canEdit;
  final bool canDelete;
  final bool canPin;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    final actions = _getAvailableActions();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Message Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Actions grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: actions.map((action) => _buildActionButton(action)).toList(),
            ),
            // Additional actions list
            if (_hasTextActions()) ...[
              const Divider(height: 1),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _getTextActions()
                    .map(
                      (action) => ListTile(
                        leading: Icon(_getActionIcon(action)),
                        title: Text(_getActionLabel(action)),
                        onTap: () {
                          Navigator.of(context).pop();
                          onAction(action);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  List<MessageAction> _getAvailableActions() {
    final actions = <MessageAction>[
      MessageAction.reply,
      MessageAction.react,
      if (message.content.isNotEmpty) MessageAction.quote,
      if (isCurrentUser && canEdit) MessageAction.edit,
      if (isCurrentUser && canDelete) MessageAction.delete,
      if (canPin) isPinned ? MessageAction.unpin : MessageAction.pin,
      if (message.attachments.isNotEmpty) MessageAction.download,
    ];

    return actions;
  }

  bool _hasTextActions() {
    return message.content.isNotEmpty;
  }

  List<MessageAction> _getTextActions() {
    return [
      MessageAction.copy,
      MessageAction.forward,
      MessageAction.report,
    ];
  }

  Widget _buildActionButton(MessageAction action) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onAction(action);
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getActionColor(action).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getActionIcon(action),
              color: _getActionColor(action),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getActionLabel(action),
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(MessageAction action) {
    switch (action) {
      case MessageAction.reply:
        return Icons.reply;
      case MessageAction.edit:
        return Icons.edit;
      case MessageAction.delete:
        return Icons.delete;
      case MessageAction.copy:
        return Icons.copy;
      case MessageAction.forward:
        return Icons.forward;
      case MessageAction.pin:
        return Icons.push_pin;
      case MessageAction.unpin:
        return Icons.push_pin;
      case MessageAction.react:
        return Icons.emoji_emotions_outlined;
      case MessageAction.quote:
        return Icons.format_quote;
      case MessageAction.report:
        return Icons.report;
      case MessageAction.retry:
        return Icons.refresh;
      case MessageAction.download:
        return Icons.download;
    }
  }

  String _getActionLabel(MessageAction action) {
    switch (action) {
      case MessageAction.reply:
        return 'Reply';
      case MessageAction.edit:
        return 'Edit';
      case MessageAction.delete:
        return 'Delete';
      case MessageAction.copy:
        return 'Copy';
      case MessageAction.forward:
        return 'Forward';
      case MessageAction.pin:
        return 'Pin';
      case MessageAction.unpin:
        return 'Unpin';
      case MessageAction.react:
        return 'React';
      case MessageAction.quote:
        return 'Quote';
      case MessageAction.report:
        return 'Report';
      case MessageAction.retry:
        return 'Retry';
      case MessageAction.download:
        return 'Save';
    }
  }

  Color _getActionColor(MessageAction action) {
    switch (action) {
      case MessageAction.delete:
      case MessageAction.report:
        return AppColors.error;
      case MessageAction.reply:
      case MessageAction.forward:
        return AppColors.primary;
      case MessageAction.edit:
      case MessageAction.quote:
        return AppColors.success;
      case MessageAction.react:
        return Colors.orange;
      case MessageAction.pin:
      case MessageAction.unpin:
        return Colors.purple;
      case MessageAction.copy:
      case MessageAction.download:
        return Colors.blue;
      case MessageAction.retry:
        return Colors.amber;
    }
  }
}

/// Show message actions menu
void showMessageActionsMenu({
  required BuildContext context,
  required MessageEntity message,
  required bool isCurrentUser,
  required MessageActionCallback onAction,
  bool canEdit = false,
  bool canDelete = false,
  bool canPin = false,
  bool isPinned = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => MessageActionsMenu(
      message: message,
      isCurrentUser: isCurrentUser,
      onAction: onAction,
      canEdit: canEdit,
      canDelete: canDelete,
      canPin: canPin,
      isPinned: isPinned,
    ),
  );
}

/// Compact message actions menu (for long press on message)
class CompactMessageActionsMenu extends StatelessWidget {
  const CompactMessageActionsMenu({
    super.key,
    required this.onAction,
    this.canEdit = false,
    this.canDelete = false,
    this.canPin = false,
    this.isPinned = false,
  });

  final MessageActionCallback onAction;
  final bool canEdit;
  final bool canDelete;
  final bool canPin;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactButton(
            icon: Icons.reply,
            label: 'Reply',
            onTap: () => onAction(MessageAction.reply),
          ),
          _buildCompactButton(
            icon: Icons.emoji_emotions_outlined,
            label: 'React',
            onTap: () => onAction(MessageAction.react),
          ),
          if (canEdit)
            _buildCompactButton(
              icon: Icons.edit,
              label: 'Edit',
              onTap: () => onAction(MessageAction.edit),
            ),
          if (canDelete)
            _buildCompactButton(
              icon: Icons.delete,
              label: 'Delete',
              color: AppColors.error,
              onTap: () => onAction(MessageAction.delete),
            ),
          _buildCompactButton(
            icon: Icons.more_horiz,
            label: 'More',
            onTap: () {
              // Show full menu
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: color ?? AppColors.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color ?? AppColors.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
