import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/direct_message.dart';
import 'package:voxmatrix/presentation/direct_messages/bloc/direct_messages_bloc.dart';
import 'package:voxmatrix/presentation/direct_messages/bloc/direct_messages_event.dart';
import 'package:voxmatrix/presentation/direct_messages/bloc/direct_messages_state.dart';

class DirectMessagesPage extends StatefulWidget {
  const DirectMessagesPage({super.key});

  @override
  State<DirectMessagesPage> createState() => _DirectMessagesPageState();
}

class _DirectMessagesPageState extends State<DirectMessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<DirectMessagesBloc>().add(const LoadDirectMessages());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchSheet(context),
          ),
        ],
      ),
      body: BlocConsumer<DirectMessagesBloc, DirectMessagesState>(
        listener: (context, state) {
          if (state is DirectMessagesStarted) {
            Navigator.of(context).pop(state.roomId);
          } else if (state is DirectMessagesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DirectMessagesLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is DirectMessagesLoaded) {
            if (state.directMessages.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildDirectMessagesList(context, state.directMessages);
          } else if (state is DirectMessagesStarting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Starting conversation...'),
                ],
              ),
            );
          } else if (state is DirectMessagesError) {
            return _buildErrorState(context, state.message);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSearchSheet(context),
        icon: const Icon(Icons.edit),
        label: const Text('New Chat'),
      ),
    );
  }

  void _showSearchSheet(BuildContext context) {
    _searchController.clear();
    _isSearching = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => BlocProvider.value(
        value: BlocProvider.of<DirectMessagesBloc>(context),
        child: _NewChatSearchSheet(
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No direct messages yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "New Chat" to start a conversation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.4),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showSearchSheet(context),
            icon: const Icon(Icons.edit),
            label: const Text('New Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.4),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<DirectMessagesBloc>().add(const LoadDirectMessages());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectMessagesList(
    BuildContext context,
    List<DirectMessage> directMessages,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DirectMessagesBloc>().add(const LoadDirectMessages());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.spacing),
        itemCount: directMessages.length,
        itemBuilder: (context, index) {
          final dm = directMessages[index];
          return _DirectMessageTile(
            directMessage: dm,
            onTap: () => _openDirectMessage(dm),
          );
        },
      ),
    );
  }

  void _openDirectMessage(DirectMessage dm) {
    print('🟢 Opening direct message: ${dm.id} with ${dm.otherUserName}');
    
    // Navigate to chat page instead of just popping
    Navigator.of(context).pushNamed(
      '/chat',
      arguments: {
        'roomId': dm.id,
        'roomName': dm.otherUserName,
        'isDirect': true,
      },
    );
  }
}

class _NewChatSearchSheet extends StatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  const _NewChatSearchSheet({
    required this.searchController,
    required this.searchFocusNode,
  });

  @override
  State<_NewChatSearchSheet> createState() => _NewChatSearchSheetState();
}

class _NewChatSearchSheetState extends State<_NewChatSearchSheet> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.searchFocusNode.requestFocus();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    final query = widget.searchController.text.trim();
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        context.read<DirectMessagesBloc>().add(SearchUsers(query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectMessagesBloc, DirectMessagesState>(
      builder: (context, state) {
        final searchResults = state is DirectMessagesSearching
            ? (state.results as List<Map<String, dynamic>>)
            : <Map<String, dynamic>>[];
        final query = widget.searchController.text.trim();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.searchController,
                      focusNode: widget.searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search by name, username or Matrix ID',
                        hintStyle: TextStyle(
                          color: AppColors.onSurface.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: widget.searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  widget.searchController.clear();
                                  context
                                      .read<DirectMessagesBloc>()
                                      .add(const ClearSearch());
                                },
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 16),
                      autofocus: true,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: query.isEmpty
                  ? _buildInitialState(context)
                  : searchResults.isEmpty && state is DirectMessagesSearching
                      ? const Center(child: CircularProgressIndicator())
                      : searchResults.isEmpty
                          ? _buildNoResults(context, query)
                          : _buildSearchResults(context, searchResults),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start a new chat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for people by their Matrix ID, username or email address.',
            style: TextStyle(
              color: AppColors.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Popular rooms',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No rooms found',
            style: TextStyle(
              color: AppColors.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No users matching "$query". Check if the spelling is correct.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _showInviteSheet(context),
            icon: const Icon(Icons.mail_outline),
            label: const Text('Invite by email'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    List<Map<String, dynamic>> results,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacing),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return _UserSearchResultTile(
          user: user,
          onTap: () => _startChat(context, user),
        );
      },
    );
  }

  void _startChat(BuildContext context, Map<String, dynamic> user) {
    final userId = user['user_id'] as String;
    Navigator.of(context).pop();
    context.read<DirectMessagesBloc>().add(StartDirectMessage(userId));
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite by email',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter an email address to invite someone to join VoxMatrix and start a chat.',
              style: TextStyle(
                color: AppColors.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.send),
                label: const Text('Send invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSearchResultTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const _UserSearchResultTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userId = user['user_id'] as String? ?? '';
    final displayName = user['display_name'] as String? ??
        userId.split(':').first.replaceAll('@', '') ??
        'Unknown';
    final avatarUrl = user['avatar_url'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          userId,
          style: TextStyle(
            color: AppColors.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: const Icon(Icons.chat_bubble_outline),
        onTap: onTap,
      ),
    );
  }
}

class _DirectMessageTile extends StatelessWidget {
  final DirectMessage directMessage;
  final VoidCallback onTap;

  const _DirectMessageTile({
    required this.directMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing / 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: directMessage.otherUserAvatarUrl != null
              ? NetworkImage(directMessage.otherUserAvatarUrl!)
              : null,
          child: directMessage.otherUserAvatarUrl == null
              ? Text(
                  directMessage.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          directMessage.otherUserName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: directMessage.lastMessage != null
            ? Text(
                directMessage.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.onSurface.withOpacity(0.6),
                ),
              )
            : Text(
                'No messages yet',
                style: TextStyle(
                  color: AppColors.onSurface.withOpacity(0.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (directMessage.lastMessageTime != null)
              Text(
                _formatTime(directMessage.lastMessageTime!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.5),
                    ),
              ),
            if (directMessage.unreadCount > 0) ...[
              const SizedBox(height: 4),
              _UnreadBadge(count: directMessage.unreadCount),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
