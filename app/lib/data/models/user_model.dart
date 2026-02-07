import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      email: email,
      isActive: isActive,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      username: entity.username,
      displayName: entity.displayName,
      avatarUrl: entity.avatarUrl,
      email: entity.email,
      isActive: entity.isActive,
    );
  }

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl, email, isActive];
}
