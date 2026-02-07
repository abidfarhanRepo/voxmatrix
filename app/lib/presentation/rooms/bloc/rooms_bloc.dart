import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/core/services/matrix_client_service.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/domain/usecases/rooms/create_room_usecase.dart';
import 'package:voxmatrix/domain/usecases/rooms/get_rooms_usecase.dart';
import 'package:voxmatrix/domain/usecases/rooms/join_room_usecase.dart';
import 'package:voxmatrix/domain/usecases/rooms/leave_room_usecase.dart';
import 'rooms_event.dart';
import 'rooms_state.dart';

@injectable
class RoomsBloc extends Bloc<RoomsEvent, RoomsState> {
  RoomsBloc(
    this._getRoomsUseCase,
    this._createRoomUseCase,
    this._joinRoomUseCase,
    this._leaveRoomUseCase,
    this._matrixClientService,
    this._authLocalDataSource,
    this._logger,
  ) : super(const RoomsInitial()) {
    on<LoadRooms>(_onLoadRooms);
    on<RefreshRooms>(_onRefreshRooms);
    on<SubscribeToRooms>(_onSubscribeToRooms);
    on<FilterRooms>(_onFilterRooms);
    on<SwitchRoomTab>(_onSwitchRoomTab);
    on<MarkRoomAsRead>(_onMarkRoomAsRead);
    on<ToggleFavouriteRoom>(_onToggleFavourite);
    on<ToggleMuteRoom>(_onToggleMute);
    on<LeaveRoom>(_onLeaveRoom);
    on<CreateRoom>(_onCreateRoom);
    on<JoinRoom>(_onJoinRoom);
  }

  final GetRoomsUseCase _getRoomsUseCase;
  final CreateRoomUseCase _createRoomUseCase;
  final JoinRoomUseCase _joinRoomUseCase;
  final LeaveRoomUseCase _leaveRoomUseCase;
  final MatrixClientService _matrixClientService;
  final AuthLocalDataSource _authLocalDataSource;
  final Logger _logger;

  StreamSubscription? _syncSubscription;
  Timer? _pollTimer;
  Timer? _debounceTimer;

  Future<void> _onLoadRooms(
    LoadRooms event,
    Emitter<RoomsState> emit,
  ) async {
    emit(const RoomsLoading());

    try {
      final result = await _getRoomsUseCase();

      result.fold<void>(
        (Failure failure) {
          _logger.e('Failed to load rooms: ${failure.message}');
          emit(RoomsError(message: failure.message));
        },
        (rooms) {
          _logger.i('Loaded ${rooms.length} rooms');
          emit(RoomsLoaded(rooms: rooms));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error loading rooms', error: e, stackTrace: stackTrace);
      emit(const RoomsError(message: 'Failed to load rooms'));
    }
  }

  Future<void> _onRefreshRooms(
    RefreshRooms event,
    Emitter<RoomsState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;
    if (currentState is! RoomsLoaded) {
      emit(const RoomsLoading());
    }

    try {
      final result = await _getRoomsUseCase();

      result.fold<void>(
        (Failure failure) {
          _logger.e('Failed to refresh rooms: ${failure.message}');
          if (currentState is RoomsLoaded) {
            emit(RoomsError(message: failure.message));
          } else {
            emit(RoomsError(message: failure.message));
          }
        },
        (rooms) {
          _logger.i('Refreshed ${rooms.length} rooms');
          // Preserve current filter settings
          if (currentState is RoomsLoaded) {
            emit(currentState.copyWith(rooms: rooms));
          } else {
            emit(RoomsLoaded(rooms: rooms));
          }
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error refreshing rooms', error: e, stackTrace: stackTrace);
      if (currentState is RoomsLoaded) {
        emit(currentState);
      } else {
        emit(const RoomsError(message: 'Failed to refresh rooms'));
      }
    }
  }

  Future<void> _onSubscribeToRooms(
    SubscribeToRooms event,
    Emitter<RoomsState> emit,
  ) async {
    _logger.i('Subscribing to room updates');

    // Load initial rooms
    add(const LoadRooms());

    // Cancel existing subscriptions/timers
    await _syncSubscription?.cancel();
    _pollTimer?.cancel();
    _debounceTimer?.cancel();

    // Try to initialize Matrix client for realtime updates
    if (!_matrixClientService.isInitialized) {
      final accessToken = await _authLocalDataSource.getAccessToken();
      final homeserver = await _authLocalDataSource.getHomeserver();
      final userId = await _authLocalDataSource.getUserId();
      if (accessToken != null && homeserver != null && userId != null && userId.isNotEmpty) {
        try {
          await _matrixClientService.initialize(
            homeserver: homeserver,
            accessToken: accessToken,
            userId: userId,
          );
          await _matrixClientService.startSync();
        } catch (_) {
          // Fall through to polling
        }
      }
    }

    if (_matrixClientService.isInitialized) {
      final client = _matrixClientService.client;
      _syncSubscription = client.onSync.stream.listen((_) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 400), () {
          add(const RefreshRooms());
        });
      });
    } else {
      // Fallback: periodic refresh
      _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        add(const RefreshRooms());
      });
    }
  }

  void _onFilterRooms(
    FilterRooms event,
    Emitter<RoomsState> emit,
  ) {
    if (state is RoomsLoaded) {
      final currentState = state as RoomsLoaded;
      emit(currentState.copyWith(
        filteredRooms: null, // Clear to let displayRooms recalculate
        searchQuery: event.query,
      ));
    }
  }

  void _onSwitchRoomTab(
    SwitchRoomTab event,
    Emitter<RoomsState> emit,
  ) {
    if (state is RoomsLoaded) {
      final currentState = state as RoomsLoaded;
      emit(currentState.copyWith(
        showDirectMessagesOnly: event.showDirectMessagesOnly,
      ));
    }
  }

  Future<void> _onMarkRoomAsRead(
    MarkRoomAsRead event,
    Emitter<RoomsState> emit,
  ) async {
    // TODO: Implement mark as read use case
    _logger.i('Marking room ${event.roomId} as read');

    if (state is RoomsLoaded) {
      final currentState = state as RoomsLoaded;
      final updatedRooms = currentState.rooms.map((room) {
        if (room.id == event.roomId) {
          return room.copyWith(unreadCount: 0);
        }
        return room;
      }).toList();

      emit(currentState.copyWith(rooms: updatedRooms));
    }
  }

  Future<void> _onToggleFavourite(
    ToggleFavouriteRoom event,
    Emitter<RoomsState> emit,
  ) async {
    // TODO: Implement toggle favourite use case
    _logger.i('Toggling favourite for room ${event.roomId}');

    if (state is RoomsLoaded) {
      final currentState = state as RoomsLoaded;
      final updatedRooms = currentState.rooms.map((room) {
        if (room.id == event.roomId) {
          return room.copyWith(isFavourite: !room.isFavourite);
        }
        return room;
      }).toList();

      emit(RoomsActionSuccess(
        message: 'Favourite toggled',
        roomId: event.roomId,
      ));
      emit(currentState.copyWith(rooms: updatedRooms));
    }
  }

  Future<void> _onToggleMute(
    ToggleMuteRoom event,
    Emitter<RoomsState> emit,
  ) async {
    // TODO: Implement toggle mute use case
    _logger.i('Toggling mute for room ${event.roomId}');

    if (state is RoomsLoaded) {
      final currentState = state as RoomsLoaded;
      final updatedRooms = currentState.rooms.map((room) {
        if (room.id == event.roomId) {
          return room.copyWith(isMuted: !room.isMuted);
        }
        return room;
      }).toList();

      emit(RoomsActionSuccess(
        message: 'Mute toggled',
        roomId: event.roomId,
      ));
      emit(currentState.copyWith(rooms: updatedRooms));
    }
  }

  Future<void> _onLeaveRoom(
    LeaveRoom event,
    Emitter<RoomsState> emit,
  ) async {
    _logger.i('Leaving room ${event.roomId}');

    final result = await _leaveRoomUseCase(event.roomId);

    result.fold<void>(
      (Failure failure) {
        _logger.e('Failed to leave room: ${failure.message}');
        emit(RoomsActionError(message: failure.message, roomId: event.roomId));
      },
      (_) {
        if (state is RoomsLoaded) {
          final currentState = state as RoomsLoaded;
          final updatedRooms = currentState.rooms.where((room) => room.id != event.roomId).toList();

          emit(RoomsActionSuccess(
            message: 'Left room',
            roomId: event.roomId,
          ));
          emit(currentState.copyWith(rooms: updatedRooms));
        }
      },
    );
  }

  Future<void> _onCreateRoom(
    CreateRoom event,
    Emitter<RoomsState> emit,
  ) async {
    _logger.i('Creating room: ${event.name}');

    final currentState = state;
    emit(const RoomsCreating());

    final result = await _createRoomUseCase(
      name: event.name,
      topic: event.topic,
      isPrivate: event.isPrivate,
    );

    result.fold<void>(
      (Failure failure) {
        _logger.e('Failed to create room: ${failure.message}');
        emit(RoomsActionError(message: failure.message));
        // Restore previous state
        if (currentState is RoomsLoaded) {
          emit(currentState);
        }
      },
      (room) async {
        _logger.i('Room created successfully: ${room.id}');
        // Don't show success message, just reload rooms
        // The new room should appear in the list
        add(const LoadRooms());
      },
    );
  }

  Future<void> _onJoinRoom(
    JoinRoom event,
    Emitter<RoomsState> emit,
  ) async {
    _logger.i('Joining room: ${event.roomIdOrAlias}');

    final result = await _joinRoomUseCase(event.roomIdOrAlias);

    result.fold<void>(
      (Failure failure) {
        _logger.e('Failed to join room: ${failure.message}');
        emit(RoomsActionError(message: failure.message));
      },
      (_) {
        emit(const RoomsActionSuccess(message: 'Joined room successfully'));

        // Reload rooms to get the new room
        add(const LoadRooms());
      },
    );
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    _pollTimer?.cancel();
    _debounceTimer?.cancel();
    return super.close();
  }
}
