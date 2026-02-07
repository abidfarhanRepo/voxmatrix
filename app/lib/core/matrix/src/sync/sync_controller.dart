/// Sync Controller for Matrix synchronization
///
/// Handles the /sync endpoint with support for lazy loading, filtering, and resuming
/// See: https://spec.matrix.org/v1.11/client-server-api/#syncing

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';
import 'package:voxmatrix/core/matrix/src/models/event.dart';
import 'package:voxmatrix/core/matrix/src/models/room.dart';
import 'package:voxmatrix/core/matrix/src/models/user.dart';
import 'package:voxmatrix/core/matrix/src/room/room_manager.dart';

/// Sync Controller for Matrix synchronization
class SyncController {
  /// Create a new sync controller
  SyncController({
    required this.client,
    required Logger logger,
  }) : _logger = logger {
    _syncStream = StreamController<MatrixSyncData>.broadcast();
  }

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Stream controller for sync data
  late final StreamController<MatrixSyncData> _syncStream;

  /// Stream of sync data
  Stream<MatrixSyncData> get stream => _syncStream.stream;

  /// The sync token (for resuming sync)
  String? _syncToken;

  /// Get the current sync token
  String? get syncToken => _syncToken;

  /// The user's Matrix ID
  String? userId;

  /// Is the sync loop running
  bool _isRunning = false;

  /// The sync subscription
  Future<void>? _syncSubscription;

  /// Backoff time for reconnection
  Duration _backoffTime = const Duration(seconds: 1);

  /// Maximum backoff time
  static const _maxBackoffTime = Duration(seconds: 60);

  /// The sync filter
  String? _syncFilterId;

  /// Get the sync filter ID
  String? get syncFilterId => _syncFilterId;

  /// Start the sync loop
  ///
  /// This will begin continuous synchronization with the Matrix homeserver
  Future<void> start() async {
    if (_isRunning) {
      _logger.w('Sync already running');
      return;
    }

    _logger.i('Starting sync loop');
    _isRunning = true;

    // Create sync filter if not already created
    if (_syncFilterId == null) {
      await _createSyncFilter();
    }

    // Start the sync loop
    await _syncLoop();
  }

  /// Stop the sync loop
  Future<void> stop() async {
    if (!_isRunning) {
      _logger.w('Sync not running');
      return;
    }

    _logger.i('Stopping sync loop');
    _isRunning = false;

    // Cancel any ongoing sync request
    // (This is handled by checking _isRunning in the sync loop)

    // Reset backoff time
    _backoffTime = const Duration(seconds: 1);
  }

  /// Create a sync filter on the server
  Future<void> _createSyncFilter() async {
    _logger.d('Creating sync filter');

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/user/${client.userId ?? ""}/filter/matrix_filter');

    final filter = {
      'room': {
        'state': {
          'types': [
            'm.room.name',
            'm.room.topic',
            'm.room.avatar',
            'm.room.member',
            'm.room.create',
            'm.room.join_rules',
            'm.room.power_levels',
            'm.room.history_visibility',
            'm.room.canonical_alias',
            'm.room.encryption',
          ],
          'lazy_load_members': true,
        },
        'timeline': {
          'limit': 20,
        },
        'account_data': {
          'types': ['m.direct'],
        },
        'ephemeral': {
          'types': ['m.receipt', 'm.typing'],
        },
      },
      'presence': {
        'types': [],
        'senders': [],
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
      body: jsonEncode(filter),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _syncFilterId = data['filter_id'] as String?;
      _logger.d('Sync filter created: $_syncFilterId');
    } else {
      _logger.w('Failed to create sync filter, continuing without filter');
    }
  }

  /// The main sync loop
  Future<void> _syncLoop() async {
    while (_isRunning) {
      try {
        client.setConnectionState(MatrixConnectionState.syncing);

        final syncData = await _performSync();

        // Reset backoff on successful sync
        _backoffTime = const Duration(seconds: 1);

        // Emit sync data to stream
        _syncStream.add(syncData);

        // Process the sync data
        await _processSyncData(syncData);

        client.setConnectionState(MatrixConnectionState.connected);
      } catch (e, stackTrace) {
        _logger.e('Sync failed', error: e, stackTrace: stackTrace);

        // Exponential backoff for retries
        _backoffTime = Duration(
          milliseconds: (_backoffTime.inMilliseconds * 2).clamp(1000, _maxBackoffTime.inMilliseconds),
        );

        client.setConnectionState(MatrixConnectionState.reconnecting);

        // Wait before retrying
        await Future.delayed(_backoffTime);
      }
    }
  }

  /// Perform a single sync request
  Future<MatrixSyncData> _performSync() async {
    final queryParams = <String, String>{
      'timeout': '30000',
    };

    if (_syncToken != null) {
      queryParams['since'] = _syncToken!;
    }

    if (_syncFilterId != null) {
      queryParams['filter'] = _syncFilterId!;
    }

    final url = Uri.parse('${client.homeserver}/_matrix/client/v3/sync').replace(
          queryParameters: queryParams,
        );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${client.accessToken}',
      },
    ).timeout(const Duration(seconds: 35));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Debug: Log sync request details
      _logger.d('=== SYNC REQUEST ===');
      _logger.d('homeserver: ${client.homeserver}');
      _logger.d('userId: ${client.userId}');
      _logger.d('hasAccessToken: ${client.accessToken != null && client.accessToken!.isNotEmpty}');
      _logger.d('syncToken: ${_syncToken?.substring(0, 20) ?? 'null'}...');
      
      // Comprehensive sync debugging
      final roomsJoin = data['rooms']?['join'] as Map<String, dynamic>?;
      final roomsInvite = data['rooms']?['invite'] as Map<String, dynamic>?;
      final roomsLeave = data['rooms']?['leave'] as Map<String, dynamic>?;
      
      _logger.d('=== SYNC RESPONSE ===');
      _logger.d('next_batch: ${data['next_batch']?.substring(0, 20) ?? 'null'}...');
      _logger.d('rooms.join: ${roomsJoin?.keys?.toList() ?? 'null'} (count: ${roomsJoin?.length ?? 0})');
      _logger.d('rooms.invite: ${roomsInvite?.keys?.toList() ?? 'null'}');
      _logger.d('rooms.leave: ${roomsLeave?.keys?.toList() ?? 'null'}');
      _logger.d('account_data: ${data['account_data']?.length ?? 0}');
      _logger.d('===================');
      
      _syncToken = data['next_batch'] as String?;

      // Get user ID from the first sync response
      if (userId == null) {
        final rooms = data['rooms'] as Map<String, dynamic>?;
        if (rooms != null) {
          // Try to get user ID from join events
          final joined = rooms['join'] as Map<String, dynamic>?;
          if (joined != null && joined.isNotEmpty) {
            final firstRoom = joined.entries.first;
            final roomData = firstRoom.value as Map<String, dynamic>;
            final stateEvents = roomData['state'] as Map<String, dynamic>?;
            if (stateEvents != null) {
              final events = stateEvents['events'] as List?;
              if (events != null) {
                for (final event in events) {
                  if (event is Map<String, dynamic>) {
                    final type = event['type'] as String?;
                    if (type == 'm.room.member') {
                      final content = event['content'] as Map<String, dynamic>?;
                      if (content != null && content['membership'] == 'join') {
                        userId = event['sender'] as String?;
                        break;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      _logger.d('Sync successful, next_batch: $_syncToken');
      return MatrixSyncData.fromJson(data);
    } else if (response.statusCode == 401) {
      throw MatrixException('Access token expired or invalid');
    } else {
      throw MatrixException('Sync failed with status ${response.statusCode}');
    }
  }

  /// Process the sync data and update room manager
  Future<void> _processSyncData(MatrixSyncData syncData) async {
    // Update rooms
    for (final roomEntry in syncData.rooms.entries) {
      final roomId = roomEntry.key;
      final roomSync = roomEntry.value;

      await client.roomManager.processRoomSync(roomId, roomSync);
    }

    // Handle direct message changes
    if (syncData.accountData.isNotEmpty) {
      for (final event in syncData.accountData) {
        if (event.type == 'm.direct') {
          client.roomManager.updateDirectMessages(event.content as Map<String, dynamic>? ?? {});
        }
      }
    }
  }

  /// Dispose of the sync controller
  Future<void> dispose() async {
    await stop();
    await _syncStream.close();
  }
}

/// Matrix sync data
class MatrixSyncData {
  /// Create sync data from JSON
  factory MatrixSyncData.fromJson(Map<String, dynamic> json) {
    final rooms = <String, MatrixRoomSync>{};

    final joined = json['rooms']?['join'] as Map<String, dynamic>?;
    if (joined != null) {
      for (final entry in joined.entries) {
        final roomId = entry.key;
        final roomData = entry.value as Map<String, dynamic>;
        rooms[roomId] = MatrixRoomSync(
          roomId: roomId,
          membership: RoomMembership.join,
          timeline: (roomData['timeline']?['events'] as List?)
                  ?.map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
                  .whereType<MatrixEvent>()
                  .toList() ??
              [],
          state: (roomData['state']?['events'] as List?)
                  ?.map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
                  .whereType<MatrixEvent>()
                  .toList() ??
              [],
          ephemeral: (roomData['ephemeral']?['events'] as List?)
                  ?.map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
                  .whereType<MatrixEvent>()
                  .toList() ??
              [],
          accountData: (roomData['account_data']?['events'] as List?)
                  ?.map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
                  .whereType<MatrixEvent>()
                  .toList() ??
              [],
          summary: roomData['summary'] as Map<String, dynamic>? ?? {},
          unreadNotifications: roomData['unread_notifications'] as Map<String, dynamic>? ?? {},
        );
      }
    }

    final invited = json['rooms']?['invite'] as Map<String, dynamic>?;
    if (invited != null) {
      for (final entry in invited.entries) {
        final roomId = entry.key;
        final roomData = entry.value as Map<String, dynamic>;
        final inviteState = roomData['invite_state'] as Map<String, dynamic>? ?? {};
        rooms[roomId] = MatrixRoomSync(
          roomId: roomId,
          membership: RoomMembership.invite,
          state: (inviteState['events'] as List?)
                  ?.map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
                  .whereType<MatrixEvent>()
                  .toList() ??
              [],
        );
      }
    }

    final left = json['rooms']?['leave'] as Map<String, dynamic>?;
    if (left != null) {
      for (final entry in left.entries) {
        final roomId = entry.key;
        final roomData = entry.value as Map<String, dynamic>;
        rooms[roomId] = MatrixRoomSync(
          roomId: roomId,
          membership: RoomMembership.leave,
          timeline: (roomData['timeline']?['events'] as List?)
                  ?.map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
                  .whereType<MatrixEvent>()
                  .toList() ??
              [],
          state: (roomData['state']?['events'] as List?)
                  ?.map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
                  .whereType<MatrixEvent>()
                  .toList() ??
              [],
        );
      }
    }

    return MatrixSyncData(
      nextBatch: json['next_batch'] as String?,
      rooms: rooms,
      accountData: (json['account_data']?['events'] as List?)
              ?.map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
              .whereType<MatrixEvent>()
              .toList() ??
          [],
      presence: (json['presence']?['events'] as List?)
              ?.map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
              .whereType<MatrixEvent>()
              .toList() ??
          [],
      toDevice: (json['to_device']?['events'] as List?)
              ?.map((e) => e is Map<String, dynamic> ? MatrixEvent.fromJson(e) : null)
              .whereType<MatrixEvent>()
              .toList() ??
          [],
      deviceLists: json['device_lists'] as Map<String, dynamic>? ?? {},
      deviceOneTimeKeysCount: json['device_one_time_keys_count'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Create a new sync data
  MatrixSyncData({
    required this.nextBatch,
    required this.rooms,
    required this.accountData,
    required this.presence,
    required this.toDevice,
    required this.deviceLists,
    required this.deviceOneTimeKeysCount,
  });

  /// The next batch token for resuming sync
  final String? nextBatch;

  /// The rooms in this sync
  final Map<String, MatrixRoomSync> rooms;

  /// Account data events
  final List<MatrixEvent> accountData;

  /// Presence events
  final List<MatrixEvent> presence;

  /// To-device events
  final List<MatrixEvent> toDevice;

  /// Device lists
  final Map<String, dynamic> deviceLists;

  /// Device one-time keys count
  final Map<String, dynamic> deviceOneTimeKeysCount;
}

/// Room sync data
class MatrixRoomSync {
  /// Create a new room sync
  MatrixRoomSync({
    required this.roomId,
    required this.membership,
    this.timeline = const [],
    this.state = const [],
    this.ephemeral = const [],
    this.accountData = const [],
    this.summary = const {},
    this.unreadNotifications = const {},
  });

  /// The room ID
  final String roomId;

  /// The membership state
  final RoomMembership membership;

  /// Timeline events
  final List<MatrixEvent> timeline;

  /// State events
  final List<MatrixEvent> state;

  /// Ephemeral events
  final List<MatrixEvent> ephemeral;

  /// Account data events
  final List<MatrixEvent> accountData;

  /// Room summary
  final Map<String, dynamic> summary;

  /// Unread notifications
  final Map<String, dynamic> unreadNotifications;

  /// Get the heroes from the summary
  List<String> get heroes {
    final heroes = summary['m.heroes'];
    if (heroes is List) {
      return heroes.cast<String>();
    }
    return [];
  }

  /// Get the joined member count
  int get joinedMemberCount {
    return summary['m.joined_member_count'] as int? ?? 0;
  }

  /// Get the invited member count
  int get invitedMemberCount {
    return summary['m.invited_member_count'] as int? ?? 0;
  }

  /// Get the unread notification count
  int get notificationCount {
    return unreadNotifications['notification_count'] as int? ?? 0;
  }

  /// Get the highlight count
  int get highlightCount {
    return unreadNotifications['highlight_count'] as int? ?? 0;
  }
}

/// Room membership state
enum RoomMembership {
  /// The user has joined the room
  join,

  /// The user has been invited to the room
  invite,

  /// The user has left the room
  leave,

  /// The user has been banned from the room
  ban,
}
