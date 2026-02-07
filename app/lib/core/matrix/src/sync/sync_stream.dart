/// Sync Stream for Matrix synchronization
///
/// Provides a convenient stream-based API for Matrix sync data

import 'dart:async';
import 'package:voxmatrix/core/matrix/src/sync/sync_controller.dart';
import 'package:voxmatrix/core/matrix/src/models/room.dart';
import 'package:voxmatrix/core/matrix/src/models/event.dart';

/// Sync Stream - provides a filtered, typed stream for Matrix events
class SyncStream {
  /// Create a new sync stream
  SyncStream(this._syncController);

  /// The sync controller
  final SyncController _syncController;

  /// Get all room updates
  Stream<MatrixRoom> get rooms => _syncController.stream.asyncExpand((syncData) {
    final rooms = <MatrixRoom>[];
    for (final entry in syncData.rooms.entries) {
      final roomId = entry.key;
      final roomSync = entry.value;
      // Create a basic room from the sync data
      rooms.add(MatrixRoom(
        id: roomId,
        name: _getRoomName(roomSync),
        joinedMemberCount: roomSync.joinedMemberCount,
        invitedMemberCount: roomSync.invitedMemberCount,
        heroes: roomSync.heroes,
        currentState: roomSync.state,
        lastEvent: roomSync.timeline.isNotEmpty ? roomSync.timeline.last : null,
        unreadCount: roomSync.notificationCount,
        highlightCount: roomSync.highlightCount,
      ));
    }
    return Stream.fromIterable(rooms);
  });

  /// Get all timeline events
  Stream<MatrixEvent> get timelineEvents => _syncController.stream.asyncExpand((syncData) {
    final events = <MatrixEvent>[];
    for (final roomSync in syncData.rooms.values) {
      events.addAll(roomSync.timeline);
    }
    return Stream.fromIterable(events);
  });

  /// Get all state events
  Stream<MatrixEvent> get stateEvents => _syncController.stream.asyncExpand((syncData) {
    final events = <MatrixEvent>[];
    for (final roomSync in syncData.rooms.values) {
      events.addAll(roomSync.state);
    }
    return Stream.fromIterable(events);
  });

  /// Get events for a specific room
  Stream<List<MatrixEvent>> eventsForRoom(String roomId) {
    return _syncController.stream.map((syncData) {
      final roomSync = syncData.rooms[roomId];
      if (roomSync == null) return [];
      return [...roomSync.timeline, ...roomSync.state];
    });
  }

  /// Get room name from sync data
  String _getRoomName(MatrixRoomSync roomSync) {
    // Try to get name from state events
    for (final event in roomSync.state) {
      if (event.type == 'm.room.name') {
        return event.roomName ?? roomSync.roomId;
      }
    }

    // Use heroes to generate name
    if (roomSync.heroes.isNotEmpty) {
      return roomSync.heroes.take(3).join(', ');
    }

    // Fallback to room ID
    return roomSync.roomId;
  }

  /// Get typing events
  Stream<MatrixEvent> get typingEvents => _syncController.stream.asyncExpand((syncData) {
    final events = <MatrixEvent>[];
    for (final roomSync in syncData.rooms.values) {
      for (final event in roomSync.ephemeral) {
        if (event.type == 'm.typing') {
          events.add(event);
        }
      }
    }
    return Stream.fromIterable(events);
  });

  /// Get receipt events
  Stream<MatrixEvent> get receiptEvents => _syncController.stream.asyncExpand((syncData) {
    final events = <MatrixEvent>[];
    for (final roomSync in syncData.rooms.values) {
      for (final event in roomSync.ephemeral) {
        if (event.type == 'm.receipt') {
          events.add(event);
        }
      }
    }
    return Stream.fromIterable(events);
  });
}
