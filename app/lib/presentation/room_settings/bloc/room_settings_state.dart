import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/room_settings.dart';

/// Base room settings state
abstract class RoomSettingsState extends Equatable {
  const RoomSettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class RoomSettingsInitial extends RoomSettingsState {
  const RoomSettingsInitial();
}

/// Loading state
class RoomSettingsLoading extends RoomSettingsState {
  const RoomSettingsLoading();
}

/// Settings loaded successfully
class RoomSettingsLoaded extends RoomSettingsState {
  const RoomSettingsLoaded(this.settings);

  final RoomSettings settings;

  @override
  List<Object?> get props => [settings];
}

/// Saving settings
class RoomSettingsSaving extends RoomSettingsState {
  const RoomSettingsSaving(this.settings, this.setting);

  final RoomSettings settings;
  final String setting;

  @override
  List<Object?> get props => [settings, setting];
}

/// Error state
class RoomSettingsError extends RoomSettingsState {
  const RoomSettingsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Room deleted
class RoomSettingsDeleted extends RoomSettingsState {
  const RoomSettingsDeleted();
}

/// Room left
class RoomSettingsLeft extends RoomSettingsState {
  const RoomSettingsLeft();
}
