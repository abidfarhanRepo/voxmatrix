import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/constants/app_strings.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/domain/entities/room.dart';
import 'package:voxmatrix/presentation/chat/chat_page.dart';
import 'package:voxmatrix/presentation/direct_messages/bloc/direct_messages_bloc.dart';
import 'package:voxmatrix/presentation/direct_messages/bloc/direct_messages_event.dart';
import 'package:voxmatrix/presentation/direct_messages/bloc/direct_messages_state.dart';
import 'package:voxmatrix/presentation/rooms/bloc/rooms_bloc.dart';
import 'package:voxmatrix/presentation/rooms/bloc/rooms_event.dart';
import 'package:voxmatrix/presentation/rooms/bloc/rooms_state.dart';
import 'package:voxmatrix/presentation/rooms/widgets/room_list_item.dart';
import 'package:voxmatrix/presentation/widgets/loading_widget.dart';
import 'package:voxmatrix/core/widgets/app_widgets.dart';
import 'package:voxmatrix/presentation/widgets/glass_container.dart';

/// Room list page showing all Matrix rooms
class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<RoomsBloc>().add(const SubscribeToRooms());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomsBloc, RoomsState>(
      listener: (context, state) {
        if (state is RoomsActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(fontWeight: FontWeight.w600)),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.primary.withOpacity(0.9),
            ),
          );
        } else if (state is RoomsActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildSearchBar(context),
                  _buildTabBar(context),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: state is RoomsCreating || state is RoomsLoading
                          ? const Center(child: LoadingWidget())
                          : _buildRoomsList(context, state),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 100, 
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: () => _showCreateOptions(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.w800)),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GlassContainer(
        borderRadius: 24,
        opacity: 0.08,
        blur: 10,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary.withOpacity(0.7), size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textSecondary.withOpacity(0.7), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      context.read<RoomsBloc>().add(const FilterRooms(''));
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (query) {
            context.read<RoomsBloc>().add(FilterRooms(query));
          },
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return BlocBuilder<RoomsBloc, RoomsState>(
      buildWhen: (previous, current) =>
          current is RoomsLoaded &&
          previous is RoomsLoaded &&
          current.showDirectMessagesOnly != previous.showDirectMessagesOnly,
      builder: (context, state) {
        final showDirectMessagesOnly =
            state is RoomsLoaded ? state.showDirectMessagesOnly : false;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildTab(
                context,
                'All Chats',
                !showDirectMessagesOnly,
                () => context.read<RoomsBloc>().add(const SwitchRoomTab(false)),
              ),
              const SizedBox(width: 12),
              _buildTab(
                context,
                'Direct',
                showDirectMessagesOnly,
                () => context.read<RoomsBloc>().add(const SwitchRoomTab(true)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(BuildContext context, String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.black : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsList(BuildContext context, RoomsState state) {
    if (state is! RoomsLoaded) return const SizedBox.shrink();
    
    if (state.displayRooms.isEmpty) {
      return _buildEmptyState(context, state);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<RoomsBloc>().add(const RefreshRooms());
      },
      color: AppColors.primary,
      backgroundColor: const Color(0xFF1E293B),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.displayRooms.length,
        padding: const EdgeInsets.only(bottom: 120, top: 8),
        itemBuilder: (context, index) {
          final room = state.displayRooms[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 400)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: RoomListItem(
              room: room,
              onTap: () => _openRoom(context, room),
              onLongPress: () => _showRoomOptions(context, room),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, RoomsLoaded state) {
    final isSearching = state.searchQuery.isNotEmpty;

    return Center(
      child: GlassContainer(
        opacity: 0.1,
        borderRadius: 24,
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacing),
            Text(
              isSearching ? 'No rooms found' : 'No rooms yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Start a new chat to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: GlassContainer(
        opacity: 0.1,
        borderRadius: 24,
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppConstants.spacing),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacing * 2),
            ElevatedButton.icon(
              onPressed: () {
    context.read<RoomsBloc>().add(const SubscribeToRooms());
              },
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.errorRetry),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: BlocProvider.of<DirectMessagesBloc>(context),
        child: GlassContainer(
          borderRadius: 24,
          opacity: 0.1,
          color: AppColors.surface,
          child: _NewChatBottomSheet(),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      _openDirectMessage(context, result);
    }
  }

  void _openDirectMessage(BuildContext context, String roomId) {
    final roomsState = context.read<RoomsBloc>().state;
    if (roomsState is RoomsLoaded) {
      final room = roomsState.displayRooms.firstWhere(
        (r) => r.id == roomId,
        orElse: () => roomsState.displayRooms.first,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            roomId: room.id,
            roomName: room.name,
            isDirect: room.isDirect,
          ),
        ),
      );
    }
  }

  void _openRoom(BuildContext context, RoomEntity room) {
    // Mark as read when opening
    context.read<RoomsBloc>().add(MarkRoomAsRead(room.id));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          roomId: room.id,
          roomName: room.name,
          isDirect: room.isDirect,
        ),
      ),
    );
  }

  void _showRoomOptions(BuildContext context, RoomEntity room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 24,
        opacity: 0.1,
        color: AppColors.surface,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  room.isFavourite ? Icons.star_border : Icons.star,
                  color: AppColors.primary,
                ),
                title: Text(
                  room.isFavourite ? 'Remove favourite' : 'Add favourite',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<RoomsBloc>()
                      .add(ToggleFavouriteRoom(room.id));
                },
              ),
              ListTile(
                leading: Icon(
                  room.isMuted ? Icons.notifications : Icons.notifications_off,
                  color: AppColors.primary,
                ),
                title: Text(
                  room.isMuted ? 'Unmute notifications' : 'Mute notifications',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<RoomsBloc>()
                      .add(ToggleMuteRoom(room.id));
                },
              ),
              ListTile(
                leading: const Icon(Icons.leave_bags_at_home, color: AppColors.error),
                title: const Text('Leave room', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveRoomDialog(context, room);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveRoomDialog(BuildContext context, RoomEntity room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface.withOpacity(0.9),
        title: const Text('Leave room', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to leave "${room.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RoomsBloc>().add(LeaveRoom(room.id));
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Dialog for creating a new room
class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({super.key});

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _topicController = TextEditingController();
  bool _isPrivate = false;

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.createRoom),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.roomNameHint,
                hintText: 'My Awesome Room',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a room name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacing),
            TextFormField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: AppStrings.roomTopicHint,
                hintText: 'What is this room about?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppConstants.spacing),
            SwitchListTile(
              title: const Text('Private room'),
              subtitle: const Text('Only invited users can join'),
              value: _isPrivate,
              onChanged: (value) {
                setState(() {
                  _isPrivate = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<RoomsBloc>().add(CreateRoom(
                    name: _nameController.text,
                    topic: _topicController.text.isEmpty
                        ? null
                        : _topicController.text,
                    isPrivate: _isPrivate,
                  ));
              Navigator.pop(context);
            }
          },
          child: const Text(AppStrings.create),
        ),
      ],
    );
  }
}

/// Bottom sheet for starting a new chat (New Chat dialog)
class _NewChatBottomSheet extends StatefulWidget {
  @override
  State<_NewChatBottomSheet> createState() => _NewChatBottomSheetState();
}

class _NewChatBottomSheetState extends State<_NewChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        context.read<DirectMessagesBloc>().add(SearchUsers(query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DirectMessagesBloc, DirectMessagesState>(
      listener: (context, state) async {
        if (state is DirectMessagesStarted) {
          Navigator.of(context).pop(state.roomId);
        } else if (state is DirectMessagesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: BlocBuilder<DirectMessagesBloc, DirectMessagesState>(
        builder: (context, state) {
          final searchResults = state is DirectMessagesSearching
              ? (state.results as List<Map<String, dynamic>>)
              : <Map<String, dynamic>>[];
          final query = _searchController.text.trim();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by name, username or Matrix ID',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<DirectMessagesBloc>()
                                      .add(const ClearSearch());
                                },
                              )
                            : null,
                      ),
                      autofocus: true,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.glassBorder),
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
      ),
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
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for people by their Matrix ID, username or email address.',
            style: TextStyle(
              color: AppColors.textSecondary,
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
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No users matching "$query". Check if the spelling is correct.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
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
        return _UserSearchTile(
          user: user,
          onTap: () => _startChat(context, user),
        );
      },
    );
  }

  void _startChat(BuildContext context, Map<String, dynamic> user) {
    final userId = user['user_id'] as String;
    context.read<DirectMessagesBloc>().add(StartDirectMessage(userId));
  }
}

class _UserSearchTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const _UserSearchTile({
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        opacity: 0.1,
        borderRadius: 16,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
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
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          subtitle: Text(
            userId,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
          onTap: onTap,
        ),
      ),
    );
  }
}
