import 'package:flutter/material.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';

/// Dialog for editing a message
class MessageEditDialog extends StatefulWidget {
  const MessageEditDialog({
    super.key,
    required this.originalContent,
    required this.onSave,
  });

  final String originalContent;
  final ValueChanged<String> onSave;

  @override
  State<MessageEditDialog> createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends State<MessageEditDialog> {
  late final TextEditingController _controller;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.originalContent);
    _controller.addListener(() {
      setState(() {
        _isModified = _controller.text != widget.originalContent;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit message'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter message',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Edited messages will show an edit icon',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isModified
              ? () {
                  widget.onSave(_controller.text.trim());
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Shows a dialog with message options (edit, delete, reply, etc.)
class MessageOptionsBottomSheet extends StatelessWidget {
  const MessageOptionsBottomSheet({
    super.key,
    required this.isCurrentUser,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReact,
    this.onCopy,
    this.onForward,
  });

  final bool isCurrentUser;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReact;
  final VoidCallback? onCopy;
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                color: AppColors.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Reaction button
            if (onReact != null)
              ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined),
                title: const Text('Add reaction'),
                onTap: () {
                  Navigator.pop(context);
                  onReact!();
                },
              ),
            // Reply button
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply!();
                },
              ),
            // Copy button
            if (onCopy != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  onCopy!();
                },
              ),
            // Forward button
            if (onForward != null)
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(context);
                  onForward!();
                },
              ),
            // Edit button (only for own messages)
            if (isCurrentUser && onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            // Delete button (only for own messages)
            if (isCurrentUser && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Shows message options bottom sheet
void showMessageOptions({
  required BuildContext context,
  required bool isCurrentUser,
  VoidCallback? onReply,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
  VoidCallback? onReact,
  VoidCallback? onCopy,
  VoidCallback? onForward,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => MessageOptionsBottomSheet(
      isCurrentUser: isCurrentUser,
      onReply: onReply,
      onEdit: onEdit,
      onDelete: onDelete,
      onReact: onReact,
      onCopy: onCopy,
      onForward: onForward,
    ),
  );
}

/// Shows edit message dialog
void showEditMessageDialog({
  required BuildContext context,
  required String originalContent,
  required ValueChanged<String> onSave,
}) {
  showDialog(
    context: context,
    builder: (context) => MessageEditDialog(
      originalContent: originalContent,
      onSave: onSave,
    ),
  );
}
