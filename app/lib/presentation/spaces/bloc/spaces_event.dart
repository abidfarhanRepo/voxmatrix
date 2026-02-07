import 'package:equatable/equatable.dart';

/// Base spaces event
abstract class SpacesEvent extends Equatable {
  const SpacesEvent();

  @override
  List<Object?> get props => [];
}

/// Load all spaces
class LoadSpaces extends SpacesEvent {
  const LoadSpaces();
}

/// Create a new space
class CreateSpace extends SpacesEvent {
  const CreateSpace({
    required this.name,
    this.topic,
  });

  final String name;
  final String? topic;

  @override
  List<Object?> get props => [name, topic];
}

/// Refresh spaces list
class RefreshSpaces extends SpacesEvent {
  const RefreshSpaces();
}
