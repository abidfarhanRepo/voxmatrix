import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.displayName,
    this.avatarUrl,
    this.userId,
  });

  final String displayName;
  final String? avatarUrl;
  final String? userId;

  @override
  List<Object?> get props => [displayName, avatarUrl, userId];

  ProfileLoaded copyWith({
    String? displayName,
    String? avatarUrl,
    String? userId,
  }) {
    return ProfileLoaded(
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userId: userId ?? this.userId,
    );
  }
}

class ProfileUpdating extends ProfileState {
  const ProfileUpdating(this.field);

  final String field; // 'displayName' or 'avatar'

  @override
  List<Object?> get props => [field];
}

class ProfileSuccess extends ProfileState {
  const ProfileSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
