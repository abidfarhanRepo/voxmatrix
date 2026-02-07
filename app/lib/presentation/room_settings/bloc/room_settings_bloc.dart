import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/data/datasources/room_management_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/domain/entities/room_settings.dart';
import 'package:voxmatrix/presentation/room_settings/bloc/room_settings_event.dart';
import 'package:voxmatrix/presentation/room_settings/bloc/room_settings_state.dart';

/// Room Settings BLoC
@injectable
class RoomSettingsBloc
    extends Bloc<RoomSettingsEvent, RoomSettingsState> {
  RoomSettingsBloc(
    this._roomManagementDataSource,
    this._authDataSource,
    this._logger,
  ) : super(RoomSettingsInitial()) {
    on<LoadRoomSettings>(_onLoadSettings);
    on<UpdateRoomName>(_onUpdateName);
    on<UpdateRoomTopic>(_onUpdateTopic);
    on<UpdateRoomAvatar>(_onUpdateAvatar);
    on<UpdateJoinRule>(_onUpdateJoinRule);
    on<UpdateGuestAccess>(_onUpdateGuestAccess);
    on<UpdateHistoryVisibility>(_onUpdateHistoryVisibility);
    on<DeleteRoom>(_onDeleteRoom);
    on<LeaveRoom>(_onLeaveRoom);
  }

  final RoomManagementRemoteDataSource _roomManagementDataSource;
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

  Future<void> _onLoadSettings(
    LoadRoomSettings event,
    Emitter<RoomSettingsState> emit,
  ) async {
    emit(RoomSettingsLoading());

    try {
      final authData = await _getAuthData();

      final result = await _roomManagementDataSource.getRoomState(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
      );

      result.fold(
        (failure) {
          _logger.e('Failed to load room settings: ${failure.message}');
          emit(RoomSettingsError(failure.message));
        },
        (stateData) {
          final settings = RoomSettings(
            roomId: event.roomId,
            name: stateData['name'] as String?,
            topic: stateData['topic'] as String?,
            avatarUrl: stateData['avatar_url'] as String?,
            joinRule: JoinRuleExtension.fromValue(
                  stateData['join_rule'] as String? ?? 'invite',
                ) ??
                JoinRule.invite,
            guestAccess: GuestAccessExtension.fromValue(
                  stateData['guest_access'] as String? ?? 'forbidden',
                ) ??
                GuestAccess.forbidden,
            historyVisibility: HistoryVisibilityExtension.fromValue(
                  stateData['history_visibility'] as String? ?? 'shared',
                ) ??
                HistoryVisibility.shared,
            canModify: true,
          );
          emit(RoomSettingsLoaded(settings));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error loading room settings', error: e, stackTrace: stackTrace);
      emit(RoomSettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateName(
    UpdateRoomName event,
    Emitter<RoomSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomSettingsLoaded) return;

    emit(RoomSettingsSaving(currentState.settings, 'name'));

    try {
      final authData = await _getAuthData();

      final result = await _roomManagementDataSource.setRoomName(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
        name: event.name,
      );

      result.fold(
        (failure) {
          emit(RoomSettingsLoaded(currentState.settings));
          emit(RoomSettingsError('Failed to update name: ${failure.message}'));
        },
        (_) {
          emit(RoomSettingsLoaded(
            currentState.settings.copyWith(name: event.name),
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating room name', error: e, stackTrace: stackTrace);
      emit(RoomSettingsLoaded(currentState.settings));
      emit(RoomSettingsError('Failed to update name: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTopic(
    UpdateRoomTopic event,
    Emitter<RoomSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomSettingsLoaded) return;

    emit(RoomSettingsSaving(currentState.settings, 'topic'));

    try {
      final authData = await _getAuthData();

      final result = await _roomManagementDataSource.setRoomTopic(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
        topic: event.topic,
      );

      result.fold(
        (failure) {
          emit(RoomSettingsLoaded(currentState.settings));
          emit(RoomSettingsError('Failed to update topic: ${failure.message}'));
        },
        (_) {
          emit(RoomSettingsLoaded(
            currentState.settings.copyWith(topic: event.topic),
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating room topic', error: e, stackTrace: stackTrace);
      emit(RoomSettingsLoaded(currentState.settings));
      emit(RoomSettingsError('Failed to update topic: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAvatar(
    UpdateRoomAvatar event,
    Emitter<RoomSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomSettingsLoaded) return;

    emit(RoomSettingsSaving(currentState.settings, 'avatar'));

    try {
      final authData = await _getAuthData();

      final result = await _roomManagementDataSource.setRoomAvatar(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
        mxcUrl: event.mxcUrl,
      );

      result.fold(
        (failure) {
          emit(RoomSettingsLoaded(currentState.settings));
          emit(RoomSettingsError('Failed to update avatar: ${failure.message}'));
        },
        (_) {
          emit(RoomSettingsLoaded(
            currentState.settings.copyWith(avatarUrl: event.mxcUrl),
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating room avatar', error: e, stackTrace: stackTrace);
      emit(RoomSettingsLoaded(currentState.settings));
      emit(RoomSettingsError('Failed to update avatar: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateJoinRule(
    UpdateJoinRule event,
    Emitter<RoomSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomSettingsLoaded) return;

    emit(RoomSettingsSaving(currentState.settings, 'join rule'));

    try {
      final authData = await _getAuthData();

      final result = await _roomManagementDataSource.setJoinRules(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
        joinRule: event.joinRule.value,
      );

      result.fold(
        (failure) {
          emit(RoomSettingsLoaded(currentState.settings));
          emit(
            RoomSettingsError('Failed to update join rule: ${failure.message}'),
          );
        },
        (_) {
          emit(RoomSettingsLoaded(
            currentState.settings.copyWith(joinRule: event.joinRule),
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating join rule', error: e, stackTrace: stackTrace);
      emit(RoomSettingsLoaded(currentState.settings));
      emit(RoomSettingsError('Failed to update join rule: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateGuestAccess(
    UpdateGuestAccess event,
    Emitter<RoomSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomSettingsLoaded) return;

    emit(RoomSettingsSaving(currentState.settings, 'guest access'));

    try {
      final authData = await _getAuthData();

      final result = await _roomManagementDataSource.setGuestAccess(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
        allowed: event.guestAccess == GuestAccess.canJoin,
      );

      result.fold(
        (failure) {
          emit(RoomSettingsLoaded(currentState.settings));
          emit(
            RoomSettingsError(
              'Failed to update guest access: ${failure.message}',
            ),
          );
        },
        (_) {
          emit(RoomSettingsLoaded(
            currentState.settings.copyWith(guestAccess: event.guestAccess),
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating guest access', error: e, stackTrace: stackTrace);
      emit(RoomSettingsLoaded(currentState.settings));
      emit(
        RoomSettingsError('Failed to update guest access: ${e.toString()}'),
      );
    }
  }

  Future<void> _onUpdateHistoryVisibility(
    UpdateHistoryVisibility event,
    Emitter<RoomSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomSettingsLoaded) return;

    emit(RoomSettingsSaving(currentState.settings, 'history visibility'));

    try {
      final authData = await _getAuthData();

      final result = await _roomManagementDataSource.setHistoryVisibility(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
        visibility: event.historyVisibility.value,
      );

      result.fold(
        (failure) {
          emit(RoomSettingsLoaded(currentState.settings));
          emit(
            RoomSettingsError(
              'Failed to update history visibility: ${failure.message}',
            ),
          );
        },
        (_) {
          emit(RoomSettingsLoaded(
            currentState.settings.copyWith(
              historyVisibility: event.historyVisibility,
            ),
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Error updating history visibility',
        error: e,
        stackTrace: stackTrace,
      );
      emit(RoomSettingsLoaded(currentState.settings));
      emit(
        RoomSettingsError(
          'Failed to update history visibility: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteRoom(
    DeleteRoom event,
    Emitter<RoomSettingsState> emit,
  ) async {
    try {
      final authData = await _getAuthData();

      final result = await _roomManagementDataSource.deleteRoom(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
      );

      result.fold(
        (failure) {
          emit(RoomSettingsError('Failed to delete room: ${failure.message}'));
        },
        (_) {
          emit(const RoomSettingsDeleted());
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error deleting room', error: e, stackTrace: stackTrace);
      emit(RoomSettingsError('Failed to delete room: ${e.toString()}'));
    }
  }

  Future<void> _onLeaveRoom(
    LeaveRoom event,
    Emitter<RoomSettingsState> emit,
  ) async {
    try {
      final authData = await _getAuthData();

      final result = await _roomManagementDataSource.leaveRoom(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
      );

      result.fold(
        (failure) {
          emit(RoomSettingsError('Failed to leave room: ${failure.message}'));
        },
        (_) {
          emit(const RoomSettingsLeft());
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error leaving room', error: e, stackTrace: stackTrace);
      emit(RoomSettingsError('Failed to leave room: ${e.toString()}'));
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
