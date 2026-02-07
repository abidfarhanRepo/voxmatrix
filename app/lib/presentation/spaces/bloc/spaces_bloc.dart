import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/data/datasources/space_remote_datasource.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/presentation/spaces/bloc/spaces_event.dart';
import 'package:voxmatrix/presentation/spaces/bloc/spaces_state.dart';

/// Spaces BLoC - handles Matrix Spaces operations
@injectable
class SpacesBloc extends Bloc<SpacesEvent, SpacesState> {
  SpacesBloc(
    this._spaceDataSource,
    this._authDataSource,
    this._logger,
  ) : super(SpacesInitial()) {
    on<LoadSpaces>(_onLoadSpaces);
    on<CreateSpace>(_onCreateSpace);
    on<RefreshSpaces>(_onRefreshSpaces);
  }

  final SpaceRemoteDataSource _spaceDataSource;
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

  Future<void> _onLoadSpaces(
    LoadSpaces event,
    Emitter<SpacesState> emit,
  ) async {
    emit(SpacesLoading());

    try {
      final authData = await _getAuthData();

      final result = await _spaceDataSource.getSpaces(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
      );

      final spaces = result.getOrElse(() => []);
      emit(SpacesLoaded(spaces));
    } catch (e, stackTrace) {
      _logger.e('Error loading spaces', error: e, stackTrace: stackTrace);
      emit(SpacesError(e.toString()));
    }
  }

  Future<void> _onCreateSpace(
    CreateSpace event,
    Emitter<SpacesState> emit,
  ) async {
    emit(SpacesLoading());

    try {
      final authData = await _getAuthData();

      final result = await _spaceDataSource.createSpace(
        homeserver: authData.homeserver,
        accessToken: authData.accessToken,
        name: event.name,
        topic: event.topic,
      );

      final space = result.getOrElse(() => throw Exception('Failed to create space'));

      // Reload spaces after creating
      add(const LoadSpaces());
    } catch (e, stackTrace) {
      _logger.e('Error creating space', error: e, stackTrace: stackTrace);
      emit(SpacesError(e.toString()));
    }
  }

  Future<void> _onRefreshSpaces(
    RefreshSpaces event,
    Emitter<SpacesState> emit,
  ) async {
    add(const LoadSpaces());
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
