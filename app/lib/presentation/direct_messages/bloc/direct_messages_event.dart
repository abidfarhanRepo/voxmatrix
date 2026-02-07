import 'package:equatable/equatable.dart';

/// Base direct messages event
abstract class DirectMessagesEvent extends Equatable {
  const DirectMessagesEvent();

  @override
  List<Object?> get props => [];
}

/// Load all direct messages
class LoadDirectMessages extends DirectMessagesEvent {
  const LoadDirectMessages();
}

/// Start a new direct message with a user
class StartDirectMessage extends DirectMessagesEvent {
  const StartDirectMessage(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Search for users
class SearchUsers extends DirectMessagesEvent {
  const SearchUsers(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Clear search results
class ClearSearch extends DirectMessagesEvent {
  const ClearSearch();
}
