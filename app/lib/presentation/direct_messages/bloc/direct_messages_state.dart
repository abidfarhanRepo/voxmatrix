import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/direct_message.dart';

/// Base direct messages state
abstract class DirectMessagesState extends Equatable {
  const DirectMessagesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DirectMessagesInitial extends DirectMessagesState {
  const DirectMessagesInitial();
}

/// Loading state
class DirectMessagesLoading extends DirectMessagesState {
  const DirectMessagesLoading();
}

/// Direct messages loaded successfully
class DirectMessagesLoaded extends DirectMessagesState {
  const DirectMessagesLoaded(this.directMessages);

  final List<DirectMessage> directMessages;

  @override
  List<Object?> get props => [directMessages];
}

/// Searching for users
class DirectMessagesSearching extends DirectMessagesState {
  const DirectMessagesSearching(this.results);

  final List<Map<String, dynamic>> results;

  @override
  List<Object?> get props => [results];
}

/// Error state
class DirectMessagesError extends DirectMessagesState {
  const DirectMessagesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Starting a new direct message
class DirectMessagesStarting extends DirectMessagesState {
  const DirectMessagesStarting();
}

/// Direct message started successfully
class DirectMessagesStarted extends DirectMessagesState {
  const DirectMessagesStarted(this.roomId);

  final String roomId;

  @override
  List<Object?> get props => [roomId];
}
