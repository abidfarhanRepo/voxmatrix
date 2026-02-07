import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class UpdateDisplayName extends ProfileEvent {
  const UpdateDisplayName(this.displayName);

  final String displayName;

  @override
  List<Object?> get props => [displayName];
}

class UpdateAvatar extends ProfileEvent {
  const UpdateAvatar(this.filePath);

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

class RemoveAvatar extends ProfileEvent {
  const RemoveAvatar();
}

class UploadAvatar extends ProfileEvent {
  const UploadAvatar({
    required this.filePath,
    required this.fileName,
    required this.bytes,
    required this.contentType,
  });

  final String filePath;
  final String fileName;
  final List<int> bytes;
  final String contentType;

  @override
  List<Object?> get props => [filePath, fileName, bytes, contentType];
}

class UpdateNotificationSettings extends ProfileEvent {
  const UpdateNotificationSettings({
    this.enableNotifications = true,
    this.enableSound = true,
    this.enableVibrate = true,
    this.notifyForAllMessages = false,
  });

  final bool enableNotifications;
  final bool enableSound;
  final bool enableVibrate;
  final bool notifyForAllMessages;

  @override
  List<Object?> get props => [
    enableNotifications,
    enableSound,
    enableVibrate,
    notifyForAllMessages,
  ];
}

class UpdateAppearanceSettings extends ProfileEvent {
  const UpdateAppearanceSettings({
    this.themeMode = ThemeMode.system,
    this.fontScale = 1.0,
    this.showReadReceipts = true,
    this.showTypingIndicators = true,
    this.compactView = false,
  });

  final ThemeMode themeMode;
  final double fontScale;
  final bool showReadReceipts;
  final bool showTypingIndicators;
  final bool compactView;

  @override
  List<Object?> get props => [
    themeMode,
    fontScale,
    showReadReceipts,
    showTypingIndicators,
    compactView,
  ];
}

class UpdatePrivacySettings extends ProfileEvent {
  const UpdatePrivacySettings({
    this.showReadReceipts = true,
    this.sendTypingNotifications = true,
    this.enablePresence = true,
    this.allowOnlineStatus = true,
    this.requireEncryption = true,
    this.ignoreUnknownRequests = false,
  });

  final bool showReadReceipts;
  final bool sendTypingNotifications;
  final bool enablePresence;
  final bool allowOnlineStatus;
  final bool requireEncryption;
  final bool ignoreUnknownRequests;

  @override
  List<Object?> get props => [
    showReadReceipts,
    sendTypingNotifications,
    enablePresence,
    allowOnlineStatus,
    requireEncryption,
    ignoreUnknownRequests,
  ];
}
