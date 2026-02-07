import 'package:flutter/material.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';

/// Emoji picker widget for reactions and messages
class EmojiPicker extends StatelessWidget {
  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.showRecent = true,
  });

  final void Function(String emoji) onEmojiSelected;
  final bool showRecent;

  // Common emoji categories
  static const List<String> _smileys = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
    '😘', '😗', '😚', '😙', '🥲', '😋', '😛', '😜',
    '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐',
    '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬',
    '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒',
  ];

  static const List<String> _gestures = [
    '👍', '👎', '👏', '🙌', '🤝', '🙏', '✍️', '💪',
    '🦵', '🦶', '👂', '👃', '🧠', '🦷', '🦴', '👀',
    '👁️', '👅', '👄', '💋', '🩸', '☂️', '🤧', '🧳',
  ];

  static const List<String> _hearts = [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
    '💘', '💝', '💟', '♥️', '💌', '💋', '💯', '💢',
  ];

  static const List<String> _reactions = [
    '👍', '👎', '❤️', '🔥', '🎉', '👀', '😂', '😮',
    '😢', '😡', '👏', '🙏', '💯', '🤝', '🤔', '🎉',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Category tabs
          DefaultTabController(
            length: 3,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Smileys', icon: Icon(Icons.sentiment_satisfied)),
                Tab(text: 'Gestures', icon: Icon(Icons.waving_hand)),
                Tab(text: 'Hearts', icon: Icon(Icons.favorite)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Emoji grid
          Expanded(
            child: TabBarView(
              children: [
                _buildEmojiGrid(_smileys),
                _buildEmojiGrid(_gestures),
                _buildEmojiGrid(_hearts),
              ],
            ),
          ),

          // Quick reactions row
          if (showRecent)
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _reactions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final emoji = _reactions[index];
                    return GestureDetector(
                      onTap: () => onEmojiSelected(emoji),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid(List<String> emojis) {
    return GridView.builder(
      itemCount: emojis.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return GestureDetector(
          onTap: () => onEmojiSelected(emoji),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      },
    );
  }
}
