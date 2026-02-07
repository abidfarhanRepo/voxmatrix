import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/room.dart';
import 'package:voxmatrix/presentation/search/bloc/search_bloc.dart';
import 'package:voxmatrix/presentation/search/bloc/search_event.dart';
import 'package:voxmatrix/presentation/search/bloc/search_state.dart';

/// Search page for messages and rooms
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacing,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search messages or rooms...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SearchBloc>().add(const ClearSearch());
                        },
                      )
                    : null,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: AppColors.onSurface.withOpacity(0.5),
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  context.read<SearchBloc>().add(const ClearSearch());
                } else {
                  context.read<SearchBloc>().add(SearchRooms(value));
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  context.read<SearchBloc>().add(SearchAll(value));
                }
              },
            ),
          ),
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchInitial && _searchController.text.isEmpty) {
            return _buildEmptyState(context);
          } else if (state is SearchLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is SearchError) {
            return _buildErrorState(context, state.message);
          } else if (state is SearchLoaded) {
            return _buildResults(context, state);
          }
          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppColors.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Search VoxMatrix',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find messages, rooms, and people',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface.withOpacity(0.4),
            ),
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
            'Search failed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onSurface.withOpacity(0.5),
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
              if (_searchController.text.isNotEmpty) {
                context.read<SearchBloc>().add(SearchAll(_searchController.text));
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, SearchLoaded state) {
    return Column(
      children: [
        if (state.rooms != null && state.rooms!.isNotEmpty)
          _buildSectionHeader(context, 'Rooms', Icons.chat_bubble),
        if (state.rooms != null && state.rooms!.isNotEmpty)
          _buildRoomList(context, state.rooms!),
        if (state.messages != null && state.messages!.isNotEmpty)
          _buildSectionHeader(context, 'Messages', Icons.message),
        if (state.messages != null && state.messages!.isNotEmpty)
          _buildMessageList(context, state.messages!),
        if (state.users != null && state.users!.isNotEmpty)
          _buildSectionHeader(context, 'People', Icons.people),
        if (state.users != null && state.users!.isNotEmpty)
          _buildUserList(context, state.users!),
        if ((state.rooms?.isEmpty ?? true) &&
            (state.messages?.isEmpty ?? true) &&
            (state.users?.isEmpty ?? true))
          _buildNoResults(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacing * 2,
        AppConstants.spacing,
        AppConstants.spacing * 2,
        AppConstants.spacing,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(BuildContext context, List<RoomEntity> rooms) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              room.name.isNotEmpty ? room.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(room.name),
          subtitle: room.topic != null
              ? Text(
                  room.topic!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: room.unreadCount > 0
              ? Chip(
                  label: Text('${room.unreadCount}'),
                  backgroundColor: AppColors.primary,
                  labelStyle: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 12,
                  ),
                )
              : null,
          onTap: () {
            // TODO: Navigate to room
          },
        );
      },
    );
  }

  Widget _buildMessageList(BuildContext context, List<Map<String, dynamic>> messages) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.message, color: AppColors.onPrimary, size: 20),
          ),
          title: Text(
            message['content'] as String? ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${message['roomId'] as String? ?? ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () {
            // TODO: Navigate to message in room
          },
        );
      },
    );
  }

  Widget _buildUserList(BuildContext context, List<Map<String, dynamic>> users) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final displayName = user['displayName'] as String?;
        final userId = user['userId'] as String?;
        final initial = (displayName != null && displayName.isNotEmpty)
            ? displayName[0].toUpperCase()
            : (userId?.isNotEmpty ?? false)
                ? userId![0].toUpperCase()
                : '?';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.secondary.withOpacity(0.1),
            child: Text(
              initial,
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(displayName ?? userId ?? ''),
          subtitle: Text(userId ?? ''),
          onTap: () {
            // TODO: Start chat with user
          },
        );
      },
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
