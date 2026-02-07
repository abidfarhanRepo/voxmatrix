import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/room.dart';

/// Base search state
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SearchInitial extends SearchState {
  const SearchInitial();
}

/// Search in progress
class SearchLoading extends SearchState {
  const SearchLoading();
}

/// Search completed with results
class SearchLoaded extends SearchState {
  const SearchLoaded({
    this.rooms,
    this.messages,
    this.users,
  });

  final List<RoomEntity>? rooms;
  final List<Map<String, dynamic>>? messages;
  final List<Map<String, dynamic>>? users;

  @override
  List<Object?> get props => [rooms, messages, users];
}

/// Search error
class SearchError extends SearchState {
  const SearchError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
