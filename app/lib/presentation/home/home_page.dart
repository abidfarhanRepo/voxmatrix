import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/presentation/auth/bloc/auth_bloc.dart';
import 'package:voxmatrix/presentation/auth/bloc/auth_event.dart';
import 'package:voxmatrix/presentation/auth/bloc/auth_state.dart';
import 'package:voxmatrix/presentation/rooms/rooms_page.dart';
import 'package:voxmatrix/presentation/search/search_page.dart';
import 'package:voxmatrix/presentation/spaces/spaces_page.dart';
import 'package:voxmatrix/presentation/profile/profile_page.dart';
import 'package:voxmatrix/presentation/widgets/loading_widget.dart';
import 'package:voxmatrix/presentation/widgets/glass_app_bar.dart';
import 'package:voxmatrix/presentation/widgets/glass_bottom_nav_bar.dart';
import 'package:voxmatrix/presentation/widgets/glass_container.dart';
import 'package:voxmatrix/presentation/widgets/glass_scaffold.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const RoomsPage(),
    const _PeoplePage(), // Placeholder for people/contacts
    const ProfilePage(), // Settings/Profile page
  ];

  // Handle back button press - if not on chats tab, go to chats tab instead of exiting
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false; // Prevent app from exiting
    }
    return true; // Allow app to exit if on chats tab
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0, // Only allow pop if on chats tab
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: GlassScaffold(
        extendBody: true, // Allow body to go behind the glass nav bar
        appBar: GlassAppBar(
          title: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return Text('Welcome, ${state.user.displayName}');
              }
              return const Text(AppConstants.appName);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SearchPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.workspaces, color: AppColors.textPrimary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SpacesPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.textPrimary),
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: GlassBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'People',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// People/Contacts page - Shows direct conversations and user directory
class _PeoplePage extends StatefulWidget {
  const _PeoplePage();

  @override
  State<_PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<_PeoplePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _directMessages = [];

  @override
  void initState() {
    super.initState();
    _loadDirectMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectMessages() async {
    // Load direct message rooms
    // In a real implementation, this would query the Matrix SDK
    setState(() {
      _directMessages = [];
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Search users via Matrix user directory
    // In a real implementation, this would use the Matrix SDK
    try {
      // Placeholder results
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _startChat(String userId, String displayName) {
    // Start a direct chat with the user
    // In a real implementation, this would create or open a DM room
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting chat with $displayName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: GlassContainer(
            borderRadius: 24,
            opacity: 0.08,
            blur: 10,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search people...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary.withOpacity(0.7), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: AppColors.textSecondary.withOpacity(0.7), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: _searchUsers,
            ),
          ),
        ),

        // Content
        Expanded(
          child: _isSearching
              ? Center(child: LoadingWidget())
              : _searchController.text.isEmpty
                  ? _buildDirectMessagesList()
                  : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildDirectMessagesList() {
    if (_directMessages.isEmpty) {
      return Center(
        child: GlassContainer(
          opacity: 0.1,
          borderRadius: 24,
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text('No contacts yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Search for users to start chatting', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _directMessages.length,
      padding: const EdgeInsets.only(bottom: 120, top: 8),
      itemBuilder: (context, index) {
        final dm = _directMessages[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 400)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
            );
          },
          child: _buildDirectMessageTile(dm),
        );
      },
    );
  }

  Widget _buildDirectMessageTile(Map<String, dynamic> dm) {
    final displayName = dm['displayName'] as String? ?? dm['userId'] as String;
    final avatarUrl = dm['avatarUrl'] as String?;
    final lastMessage = dm['lastMessage'] as String? ?? '';
    final timestamp = dm['timestamp'] as DateTime?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GlassContainer(
        opacity: 0.05,
        borderRadius: 16,
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: avatarUrl == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary),
                  )
                : null,
          ),
          title: Text(displayName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: timestamp != null
              ? Text(
                  _formatTimestamp(timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                )
              : null,
          onTap: () {
            // Navigate to chat
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final userId = user['userId'] as String;
    final displayName = user['displayName'] as String? ?? userId;
    final avatarUrl = user['avatarUrl'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GlassContainer(
        opacity: 0.05,
        borderRadius: 16,
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: avatarUrl == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary),
                  )
                : null,
          ),
          title: Text(displayName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          subtitle: Text(userId, style: const TextStyle(color: AppColors.textSecondary)),
          trailing: IconButton(
            icon: const Icon(Icons.chat, color: AppColors.primary),
            onPressed: () => _startChat(userId, displayName),
          ),
          onTap: () => _startChat(userId, displayName),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
