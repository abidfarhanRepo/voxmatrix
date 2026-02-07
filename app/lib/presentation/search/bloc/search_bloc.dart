import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/data/datasources/search_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/domain/repositories/room_repository.dart';
import 'package:voxmatrix/presentation/search/bloc/search_event.dart';
import 'package:voxmatrix/presentation/search/bloc/search_state.dart';

/// Search BLoC - handles search operations for rooms, messages, and users
@injectable
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(
    this._searchDataSource,
    this._roomRepository,
    this._authDataSource,
    this._logger,
  ) : super(SearchInitial()) {
    on<SearchRooms>(_onSearchRooms);
    on<SearchAll>(_onSearchAll);
    on<ClearSearch>(_onClearSearch);
    on<SearchMessages>(_onSearchMessages);
    on<SearchUsers>(_onSearchUsers);
  }

  final SearchRemoteDataSource _searchDataSource;
  final RoomRepository _roomRepository;
  final AuthLocalDataSource _authDataSource;
  final Logger _logger;

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

  Future<void> _onSearchRooms(
    SearchRooms event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      // Search for rooms locally using room repository
      final roomsResult = await _roomRepository.getRooms();

      final rooms = roomsResult.getOrElse(() => []);
      final filteredRooms = rooms.where((room) {
        return room.name.toLowerCase().contains(event.query.toLowerCase()) ||
            (room.topic?.toLowerCase().contains(event.query.toLowerCase()) ?? false);
      }).toList();

      emit(SearchLoaded(rooms: filteredRooms));
    } catch (e, stackTrace) {
      _logger.e('Error searching rooms', error: e, stackTrace: stackTrace);
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onSearchAll(
    SearchAll event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      // Get authenticated user's session
      final authData = await _getAuthData();

      // Search for rooms locally
      final roomsResult = await _roomRepository.getRooms();
      final rooms = roomsResult.getOrElse(() => []);
      final filteredRooms = rooms.where((room) {
        return room.name.toLowerCase().contains(event.query.toLowerCase()) ||
            (room.topic?.toLowerCase().contains(event.query.toLowerCase()) ?? false);
      }).toList();

      // Search for users via Matrix API
      final usersResult = await _searchDataSource.searchUsers(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        query: event.query,
        limit: 10,
      );

      final usersData = usersResult.getOrElse(() => {'results': <dynamic>[]});
      final users = (usersData['results'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .where((user) {
            final userId = user['user_id'] as String?;
            return userId != null && !userId.contains(authData.userId);
          })
          .toList();

      // Message search would require room message history
      // For now, return empty list
      final List<Map<String, dynamic>> messages = [];

      emit(SearchLoaded(
        rooms: filteredRooms,
        messages: messages,
        users: users,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error searching', error: e, stackTrace: stackTrace);
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchInitial());
  }

  Future<void> _onSearchMessages(
    SearchMessages event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      // TODO: Implement message search within a room
      // This requires fetching room message history and searching through it
      emit(SearchLoaded(messages: []));
    } catch (e, stackTrace) {
      _logger.e('Error searching messages', error: e, stackTrace: stackTrace);
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      // Get authenticated user's session
      final authData = await _getAuthData();

      // Search for users via Matrix API
      final usersResult = await _searchDataSource.searchUsers(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        query: event.query,
        limit: 10,
      );

      final usersData = usersResult.getOrElse(() => {'results': <dynamic>[]});
      final users = (usersData['results'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .where((user) {
            final userId = user['user_id'] as String?;
            return userId != null && !userId.contains(authData.userId);
          })
          .toList();

      emit(SearchLoaded(users: users));
    } catch (e, stackTrace) {
      _logger.e('Error searching users', error: e, stackTrace: stackTrace);
      emit(SearchError(e.toString()));
    }
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
