import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/data/datasources/room_members_datasource.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/domain/entities/room_member.dart';
import 'package:voxmatrix/presentation/room_members/bloc/room_members_event.dart';
import 'package:voxmatrix/presentation/room_members/bloc/room_members_state.dart';

/// Room Members BLoC
@injectable
class RoomMembersBloc extends Bloc<RoomMembersEvent, RoomMembersState> {
  RoomMembersBloc(
    this._membersDataSource,
    this._authDataSource,
    this._logger,
  ) : super(RoomMembersInitial()) {
    on<LoadRoomMembers>(_onLoadMembers);
    on<RefreshRoomMembers>(_onRefreshMembers);
    on<KickUser>(_onKickUser);
    on<BanUser>(_onBanUser);
    on<UnbanUser>(_onUnbanUser);
    on<InviteUser>(_onInviteUser);
    on<LeaveRoom>(_onLeaveRoom);
  }

  final RoomMembersDataSource _membersDataSource;
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

  Future<void> _onLoadMembers(
    LoadRoomMembers event,
    Emitter<RoomMembersState> emit,
  ) async {
    emit(RoomMembersLoading());

    try {
      final authData = await _getAuthData();

      final result = await _membersDataSource.getRoomMembers(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
      );

      final membersData = result.getOrElse(() => []);

      // Parse member data
      final members = membersData.map((memberData) {
        final userId = memberData['user_id'] as String? ?? '';
        final content = memberData['content'] as Map<String, dynamic>? ?? {};
        final membership = content['membership'] as String? ?? 'join';
        final displayName = content['displayname'] as String? ?? userId;
        final avatarUrl = content['avatar_url'] as String?;
        final powerLevel = 0; // Would need to parse from events

        return RoomMember(
          userId: userId,
          displayName: displayName,
          avatarUrl: avatarUrl,
          powerLevel: powerLevel,
          membership: membership,
        );
      }).toList();

      emit(RoomMembersLoaded(members));
    } catch (e, stackTrace) {
      _logger.e('Error loading room members', error: e, stackTrace: stackTrace);
      emit(RoomMembersError(e.toString()));
    }
  }

  Future<void> _onRefreshMembers(
    RefreshRoomMembers event,
    Emitter<RoomMembersState> emit,
  ) async {
    add(LoadRoomMembers(event.roomId));
  }

  Future<void> _onKickUser(
    KickUser event,
    Emitter<RoomMembersState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomMembersLoaded) return;

    emit(RoomMembersActionInProgress(currentState.members, 'Kicking user...'));

    try {
      final authData = await _getAuthData();

      await _membersDataSource.kickUser(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
        userId: event.userId,
        reason: event.reason,
      );

      add(LoadRoomMembers(event.roomId));
    } catch (e, stackTrace) {
      _logger.e('Error kicking user', error: e, stackTrace: stackTrace);
      emit(RoomMembersLoaded(currentState.members));
      emit(RoomMembersError('Failed to kick user: ${e.toString()}'));
    }
  }

  Future<void> _onBanUser(
    BanUser event,
    Emitter<RoomMembersState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomMembersLoaded) return;

    emit(RoomMembersActionInProgress(currentState.members, 'Banning user...'));

    try {
      final authData = await _getAuthData();

      await _membersDataSource.banUser(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
        userId: event.userId,
        reason: event.reason,
      );

      add(LoadRoomMembers(event.roomId));
    } catch (e, stackTrace) {
      _logger.e('Error banning user', error: e, stackTrace: stackTrace);
      emit(RoomMembersLoaded(currentState.members));
      emit(RoomMembersError('Failed to ban user: ${e.toString()}'));
    }
  }

  Future<void> _onUnbanUser(
    UnbanUser event,
    Emitter<RoomMembersState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomMembersLoaded) return;

    emit(RoomMembersActionInProgress(currentState.members, 'Unbanning user...'));

    try {
      final authData = await _getAuthData();

      await _membersDataSource.unbanUser(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
        userId: event.userId,
      );

      add(LoadRoomMembers(event.roomId));
    } catch (e, stackTrace) {
      _logger.e('Error unbanning user', error: e, stackTrace: stackTrace);
      emit(RoomMembersLoaded(currentState.members));
      emit(RoomMembersError('Failed to unban user: ${e.toString()}'));
    }
  }

  Future<void> _onInviteUser(
    InviteUser event,
    Emitter<RoomMembersState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomMembersLoaded) return;

    emit(RoomMembersActionInProgress(currentState.members, 'Inviting user...'));

    try {
      final authData = await _getAuthData();

      await _membersDataSource.inviteUser(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
        userId: event.userId,
      );

      add(LoadRoomMembers(event.roomId));
    } catch (e, stackTrace) {
      _logger.e('Error inviting user', error: e, stackTrace: stackTrace);
      emit(RoomMembersLoaded(currentState.members));
      emit(RoomMembersError('Failed to invite user: ${e.toString()}'));
    }
  }

  Future<void> _onLeaveRoom(
    LeaveRoom event,
    Emitter<RoomMembersState> emit,
  ) async {
    emit(RoomMembersActionInProgress([], 'Leaving room...'));

    try {
      final authData = await _getAuthData();

      await _membersDataSource.leaveRoom(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        roomId: event.roomId,
      );

      emit(RoomMembersLoaded([]));
    } catch (e, stackTrace) {
      _logger.e('Error leaving room', error: e, stackTrace: stackTrace);
      emit(RoomMembersError('Failed to leave room: ${e.toString()}'));
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
