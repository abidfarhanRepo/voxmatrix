import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/space_entity.dart';

/// Base spaces state
abstract class SpacesState extends Equatable {
  const SpacesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SpacesInitial extends SpacesState {
  const SpacesInitial();
}

/// Loading state
class SpacesLoading extends SpacesState {
  const SpacesLoading();
}

/// Spaces loaded successfully
class SpacesLoaded extends SpacesState {
  const SpacesLoaded(this.spaces);

  final List<SpaceEntity> spaces;

  @override
  List<Object?> get props => [spaces];
}

/// Error state
class SpacesError extends SpacesState {
  const SpacesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
