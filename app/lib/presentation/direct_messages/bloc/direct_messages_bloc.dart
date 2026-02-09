import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';
import 'package:voxmatrix/data/datasources/room_management_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/data/datasources/room_remote_datasource.dart';
import 'package:voxmatrix/domain/entities/direct_message.dart';
import 'package:voxmatrix/presentation/direct_messages/bloc/direct_messages_event.dart';
import 'package:voxmatrix/presentation/direct_messages/bloc/direct_messages_state.dart';

/// Direct Messages BLoC
@injectable
class DirectMessagesBloc
    extends Bloc<DirectMessagesEvent, DirectMessagesState> {
  DirectMessagesBloc(
    this._roomManagementDataSource,
    this._authDataSource,
    this._roomDataSource,
    this._matrixClientService,
    this._logger,
  ) : super(DirectMessagesInitial()) {
    on<LoadDirectMessages>(_onLoadDirectMessages);
    on<StartDirectMessage>(_onStartDirectMessage);
    on<SearchUsers>(_onSearchUsers);
    on<ClearSearch>(_onClearSearch);
  }

  final RoomManagementRemoteDataSource _roomManagementDataSource;
  final AuthLocalDataSource _authDataSource;
  final RoomRemoteDataSource _roomDataSource;
  final MatrixClientService _matrixClientService;
  final Logger _logger;

  /// Ensure Matrix client is initialized before proceeding
  /// 
  /// If the client is not initialized, waits up to 15 seconds for initialization.
  /// Returns true if client is ready, false if initialization failed or timed out.
  Future<bool> _ensureMatrixClientReady({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_matrixClientService.isInitialized) {
      return true;
    }

    _logger.d('Matrix client not ready in DirectMessagesBloc, waiting for initialization...');

    // Wait for initialization with timeout
    final ready = await _matrixClientService.waitForInitialization(timeout: timeout);

    if (!ready) {
      _logger.w('Matrix client failed to initialize in DirectMessagesBloc');
    }

    return ready;
  }

  Future<_AuthData> _getAuthData() async {
    final accessToken = await _authDataSource.getAccessToken();
    final userId = await _authDataSource.getUserId();
    final homeserver = await _authDataSource.getHomeserver();

    if (accessToken == null || userId == null || homeserver == null) {
      throw Exception('Not authenticated');
    }

    return _AuthData(
      accessToken: accessToken,
      userId: userId,
      homeserver: homeserver,
    );
  }

  Future<void> _onLoadDirectMessages(
    LoadDirectMessages event,
    Emitter<DirectMessagesState> emit,
  ) async {
    emit(DirectMessagesLoading());

    try {
      // Ensure Matrix client is initialized before loading rooms
      final clientReady = await _ensureMatrixClientReady();
      if (!clientReady) {
        _logger.w('Matrix client not ready for loading direct messages');
        // Still proceed with HTTP fallback, but log the warning
      }

      final authData = await _getAuthData();

      final result = await _roomDataSource.getRooms(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
      );

      result.fold(
        (failure) {
          _logger.e('Failed to load direct messages: ${failure.message}');
          emit(DirectMessagesError(failure.message));
        },
        (rooms) {
          // Filter for direct messages only
          final directMessages = rooms
              .where((room) => room['isDirect'] == true)
              .map((room) {
                final members = room['members'] as List? ?? [];
                // Find the other user (not current user)
                final otherMember = members.firstWhere(
                  (m) => m['userId'] != authData.userId,
                  orElse: () => null,
                );

                if (otherMember == null) return null;

                final lastMessage = room['lastMessage'] as Map<String, dynamic>?;

                return DirectMessage(
                  id: room['id'] as String,
                  otherUserId: otherMember['userId'] as String,
                  otherUserName: otherMember['displayName'] as String? ??
                      otherMember['userId'] as String,
                  otherUserAvatarUrl: otherMember['avatarUrl'] as String?,
                  lastMessage: lastMessage?['content'] as String?,
                  lastMessageTime: lastMessage?['timestamp'] as DateTime?,
                  unreadCount: room['unreadCount'] as int? ?? 0,
                );
              })
              .whereType<DirectMessage>()
              .toList();

          // Sort by last message time (most recent first)
          directMessages.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) {
              return 0;
            }
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });

          emit(DirectMessagesLoaded(directMessages));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error loading direct messages', error: e, stackTrace: stackTrace);
      emit(DirectMessagesError(e.toString()));
    }
  }

  Future<void> _onStartDirectMessage(
    StartDirectMessage event,
    Emitter<DirectMessagesState> emit,
  ) async {
    emit(const DirectMessagesStarting());

    try {
      final authData = await _getAuthData();

      final result = await _roomManagementDataSource.createRoom(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        name: '', // Direct messages don't have a name
        isDirect: true,
        inviteUserIds: [event.userId],
      );

      result.fold(
        (failure) {
          _logger.e('Failed to start direct message: ${failure.message}');
          emit(DirectMessagesError(failure.message));
        },
        (data) {
          final roomId = data['room_id'] as String;
          _logger.i('Started direct message: $roomId with ${event.userId}');
          emit(DirectMessagesStarted(roomId));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error starting direct message', error: e, stackTrace: stackTrace);
      emit(DirectMessagesError(e.toString()));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<DirectMessagesState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(const DirectMessagesSearching([]));
      return;
    }

    emit(const DirectMessagesSearching([]));

    try {
      final authData = await _getAuthData();
      final query = event.query.trim();
      final results = <Map<String, dynamic>>[];

      // Check if it's a full Matrix user ID (@username:server)
      if (query.startsWith('@') && query.contains(':')) {
        final profileResult = await _roomDataSource.getUserProfile(
          homeserver: authData.homeserver,
          accessToken: authData.accessToken,
          userId: query,
        );

        profileResult.fold(
          (failure) {},
          (profile) {
            final userId = profile['user_id'] as String? ?? query;
            final displayName = profile['displayname'] as String? ?? query.split(':')[0].replaceAll('@', '');
            final avatarUrl = profile['avatar_url'] as String?;

            results.add({
              'user_id': userId,
              'display_name': displayName,
              'avatar_url': avatarUrl,
            });
          },
        );
      }

      // Search in user directory (works for partial usernames)
      final searchResult = await _roomDataSource.searchUsers(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        query: query,
      );

      searchResult.fold(
        (failure) {},
        (users) {
          // Add users from directory search
          for (final user in users) {
            final userId = user['user_id'] as String?;
            // Avoid duplicates
            if (userId != null && !results.any((r) => r['user_id'] == userId)) {
              results.add(user);
            }
          }
        },
      );

      // If no results yet and query doesn't contain @, try as localpart on current homeserver
      if (results.isEmpty && !query.contains('@')) {
        final localUserId = '@$query:${authData.homeserver.split(':')[0]}';
        final profileResult = await _roomDataSource.getUserProfile(
          homeserver: authData.homeserver,
          accessToken: authData.accessToken,
          userId: localUserId,
        );

        profileResult.fold(
          (failure) {},
          (profile) {
            final userId = profile['user_id'] as String? ?? localUserId;
            final displayName = profile['displayname'] as String? ?? query;
            final avatarUrl = profile['avatar_url'] as String?;

            results.add({
              'user_id': userId,
              'display_name': displayName,
              'avatar_url': avatarUrl,
            });
          },
        );
      }

      emit(DirectMessagesSearching(results));
    } catch (e, stackTrace) {
      _logger.e('Error searching users', error: e, stackTrace: stackTrace);
      emit(const DirectMessagesSearching([]));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<DirectMessagesState> emit,
  ) async {
    // Reload direct messages
    add(const LoadDirectMessages());
  }
}

class _AuthData {
  const _AuthData({
    required this.accessToken,
    required this.userId,
    required this.homeserver,
  });

  final String accessToken;
  final String userId;
  final String homeserver;
}
