import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.email,
    this.isActive = true,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? email;
  final bool isActive;

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl, email, isActive];

  UserEntity copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? email,
    bool? isActive,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
    );
  }
}
