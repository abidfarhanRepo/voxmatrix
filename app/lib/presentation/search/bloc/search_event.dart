import 'package:equatable/equatable.dart';

/// Base search event
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Search rooms
class SearchRooms extends SearchEvent {
  const SearchRooms(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Search all (rooms, messages, users)
class SearchAll extends SearchEvent {
  const SearchAll(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Clear search results
class ClearSearch extends SearchEvent {
  const ClearSearch();
}

/// Search messages in a specific room
class SearchMessages extends SearchEvent {
  const SearchMessages({
    required this.roomId,
    required this.query,
  });

  final String roomId;
  final String query;

  @override
  List<Object?> get props => [roomId, query];
}

/// Search for users
class SearchUsers extends SearchEvent {
  const SearchUsers(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
