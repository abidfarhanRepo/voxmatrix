import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:voxmatrix/data/datasources/auth_local_datasource.dart';
import 'package:voxmatrix/domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(
    this._profileRepository,
    this._localDataSource,
    this._logger,
  ) : super(const ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateDisplayName>(_onUpdateDisplayName);
    on<UpdateAvatar>(_onUpdateAvatar);
    on<UploadAvatar>(_onUploadAvatar);
  }

  final ProfileRepository _profileRepository;
  final AuthLocalDataSource _localDataSource;
  final Logger _logger;

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final userId = await _localDataSource.getUserId();

      final result = await _profileRepository.getProfile();

      result.fold<void>(
        (Failure failure) {
          _logger.e('Failed to load profile: ${failure.message}');
          // On error, still show loaded state with current user info
          emit(ProfileLoaded(
            displayName: userId?.split(':')?.first?.replaceAll('@', '') ?? 'User',
            userId: userId,
          ));
        },
        (profileData) {
          final displayName = profileData['displayname'] as String?;
          final avatarUrl = profileData['avatar_url'] as String?;

          emit(ProfileLoaded(
            displayName: displayName ?? userId?.split(':')?.first?.replaceAll('@', '') ?? 'User',
            avatarUrl: avatarUrl,
            userId: userId,
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error loading profile', error: e, stackTrace: stackTrace);
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateDisplayName(
    UpdateDisplayName event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      emit(const ProfileError('Profile not loaded'));
      return;
    }

    emit(const ProfileUpdating('displayName'));

    final result = await _profileRepository.setDisplayName(event.displayName);

    result.fold<void>(
      (Failure failure) {
        _logger.e('Failed to update display name: ${failure.message}');
        emit(ProfileError( failure.message));
        // Restore previous state
        emit(currentState);
      },
      (_) {
        _logger.i('Display name updated: ${event.displayName}');
        emit(ProfileSuccess('Display name updated'));
        emit(currentState.copyWith(displayName: event.displayName));
      },
    );
  }

  Future<void> _onUpdateAvatar(
    UpdateAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      emit(const ProfileError('Profile not loaded'));
      return;
    }

    emit(const ProfileUpdating('avatar'));

    final result = await _profileRepository.updateAvatar(event.filePath);

    result.fold<void>(
      (Failure failure) {
        _logger.e('Failed to update avatar: ${failure.message}');
        emit(ProfileError( failure.message));
        emit(currentState);
      },
      (_) {
        _logger.i('Avatar updated');
        emit(ProfileSuccess('Avatar updated'));
        // Reload profile to get new avatar URL
        add(const LoadProfile());
      },
    );
  }

  Future<void> _onUploadAvatar(
    UploadAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      emit(const ProfileError('Profile not loaded'));
      return;
    }

    emit(const ProfileUpdating('avatar'));

    // Upload
    final uploadResult = await _profileRepository.uploadAvatar(
      filePath: event.filePath,
      fileName: event.fileName,
      bytes: event.bytes,
      contentType: event.contentType,
    );

    uploadResult.fold<void>(
      (Failure failure) {
        _logger.e('Failed to upload avatar: ${failure.message}');
        emit(ProfileError( failure.message));
        emit(currentState);
      },
      (mxcUri) async {
        // Set avatar URL
        final setResult = await _profileRepository.setAvatarUrl(mxcUri);
        setResult.fold<void>(
          (Failure failure) {
            _logger.e('Failed to set avatar URL: ${failure.message}');
            emit(ProfileError( failure.message));
            emit(currentState);
          },
          (_) {
            _logger.i('Avatar uploaded and set: $mxcUri');
            emit(ProfileSuccess('Avatar updated'));
            add(const LoadProfile());
          },
        );
      },
    );
  }
}
