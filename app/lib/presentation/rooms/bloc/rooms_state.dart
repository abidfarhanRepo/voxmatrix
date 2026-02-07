import 'package:equatable/equatable.dart';
import 'package:voxmatrix/domain/entities/room.dart';

/// Base class for all room states
abstract class RoomsState extends Equatable {
  const RoomsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any rooms are loaded
class RoomsInitial extends RoomsState {
  const RoomsInitial();
}

/// Loading state when fetching rooms
class RoomsLoading extends RoomsState {
  const RoomsLoading();
}

/// State when creating a room
class RoomsCreating extends RoomsState {
  const RoomsCreating();
}

/// State when rooms have been loaded successfully
class RoomsLoaded extends RoomsState {
  const RoomsLoaded({
    required this.rooms,
    this.filteredRooms,
    this.showDirectMessagesOnly = false,
    this.searchQuery = '',
  });

  /// All rooms the user is a member of
  final List<RoomEntity> rooms;

  /// Filtered rooms (by search or tab)
  final List<RoomEntity>? filteredRooms;

  /// Whether showing only direct messages
  final bool showDirectMessagesOnly;

  /// Current search query
  final String searchQuery;

  /// Get the effective list of rooms to display
  List<RoomEntity> get displayRooms {
    if (filteredRooms != null) {
      return filteredRooms!;
    }

    var result = rooms;

    // Filter by direct messages if tab is selected
    if (showDirectMessagesOnly) {
      result = result.where((room) => room.isDirect).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((room) {
        return room.name.toLowerCase().contains(query) ||
            (room.topic?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort by timestamp (most recent first)
    result = [
      ...result,
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return result;
  }

  /// Get total unread count across all rooms
  int get totalUnreadCount {
    return rooms.fold(0, (sum, room) => sum + room.unreadCount);
  }

  @override
  List<Object?> get props {
    return [rooms, filteredRooms, showDirectMessagesOnly, searchQuery];
  }

  RoomsLoaded copyWith({
    List<RoomEntity>? rooms,
    List<RoomEntity>? filteredRooms,
    bool? showDirectMessagesOnly,
    String? searchQuery,
  }) {
    return RoomsLoaded(
      rooms: rooms ?? this.rooms,
      filteredRooms: filteredRooms ?? this.filteredRooms,
      showDirectMessagesOnly: showDirectMessagesOnly ?? this.showDirectMessagesOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// State when room operations succeed
class RoomsActionSuccess extends RoomsState {
  const RoomsActionSuccess({
    required this.message,
    this.roomId,
  });

  /// Success message to display
  final String message;

  /// Optional room ID affected by the action
  final String? roomId;

  @override
  List<Object?> get props => [message, roomId];
}

/// State when room action fails
class RoomsActionError extends RoomsState {
  const RoomsActionError({
    required this.message,
    this.roomId,
  });

  /// Error message to display
  final String message;

  /// Optional room ID related to the error
  final String? roomId;

  @override
  List<Object?> get props => [message, roomId];
}

/// State when an error occurs
class RoomsError extends RoomsState {
  const RoomsError({
    required this.message,
    this.roomId,
  });

  /// Error message to display
  final String message;

  /// Optional room ID related to the error
  final String? roomId;

  @override
  List<Object?> get props => [message, roomId];
}
