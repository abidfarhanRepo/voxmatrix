import 'package:flutter/material.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';

/// Widget for picking emoji reactions
class ReactionPicker extends StatefulWidget {
  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.currentReactions = const [],
  });

  final ValueChanged<String> onReactionSelected;
  final List<String> currentReactions;

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker> {
  static const List<String> _commonEmojis = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '🎉',
    '🔥',
    '👏',
    '🙏',
    '👀',
    '💯',
    '✨',
    '🚀',
    '💪',
    '🤔',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _commonEmojis.length,
            itemBuilder: (context, index) {
              final emoji = _commonEmojis[index];
              final isSelected = widget.currentReactions.contains(emoji);

              return _ReactionButton(
                emoji: emoji,
                isSelected: isSelected,
                onTap: () => widget.onReactionSelected(emoji),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget showing reactions on a message
class MessageReactions extends StatelessWidget {
  const MessageReactions({
    super.key,
    required this.reactions,
    this.onReactionTap,
  });

  final Map<String, int> reactions;
  final ValueChanged<String>? onReactionTap;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: reactions.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value;

        return _ReactionChip(
          emoji: emoji,
          count: count,
          onTap: onReactionTap != null ? () => onReactionTap!(emoji) : null,
        );
      }).toList(),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    this.onTap,
  });

  final String emoji;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gestureDetector = onTap != null
        ? GestureDetector(onTap: onTap, child: _buildContent())
        : _buildContent();

    return gestureDetector;
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          if (count > 1) ...[
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Overlay for showing reaction picker
class ReactionPickerOverlay extends StatefulWidget {
  const ReactionPickerOverlay({
    super.key,
    required this.child,
    required this.onReactionSelected,
    this.currentReactions = const [],
  });

  final Widget child;
  final ValueChanged<String> onReactionSelected;
  final List<String> currentReactions;

  @override
  State<ReactionPickerOverlay> createState() => _ReactionPickerOverlayState();
}

class _ReactionPickerOverlayState extends State<ReactionPickerOverlay> {
  OverlayEntry? _overlayEntry;

  void _showReactionPicker(BuildContext context, Offset position) {
    _overlayEntry = OverlayEntry(
      builder: (context) => _ReactionPickerOverlay(
        position: position,
        onReactionSelected: (emoji) {
          widget.onReactionSelected(emoji);
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        currentReactions: widget.currentReactions,
        onRemove: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        _showReactionPicker(context, details.globalPosition);
      },
      child: widget.child,
    );
  }
}

class _ReactionPickerOverlay extends StatelessWidget {
  const _ReactionPickerOverlay({
    required this.position,
    required this.onReactionSelected,
    required this.currentReactions,
    required this.onRemove,
  });

  final Offset position;
  final ValueChanged<String> onReactionSelected;
  final List<String> currentReactions;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Full screen transparent overlay
          Positioned.fill(
            child: Container(color: Colors.transparent),
          ),
          // Reaction picker positioned at tap location
          Positioned(
            left: position.dx - 100,
            top: position.dy - 180,
            child: ReactionPicker(
              onReactionSelected: onReactionSelected,
              currentReactions: currentReactions,
            ),
          ),
        ],
      ),
    );
  }
}
