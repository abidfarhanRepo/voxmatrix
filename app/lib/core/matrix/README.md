# VoxMatrix SDK Documentation

## Overview

The VoxMatrix SDK is a comprehensive Flutter implementation of the Matrix Client-Server API v1.11. It provides a complete set of features for building modern Matrix messaging applications with support for synchronization, encryption, push notifications, media sharing, and much more.

## Features

| Feature | Status | Description |
|---------|--------|-------------|
| **Synchronization** | ✅ Complete | Continuous sync with lazy loading and exponential backoff |
| **Room Management** | ✅ Complete | Full room state management with member tracking |
| **Event Handling** | ✅ Complete | Real-time event streaming with comprehensive event type support |
| **Message Operations** | ✅ Complete | Send, edit, react, redact, and reply to messages |
| **Media Management** | ✅ Complete | File upload/download with MXC URI handling |
| **Search** | ✅ Complete | Message and room search with pagination |
| **Encryption** | ⚠️ Partial | E2EE state management with device key handling (crypto lib needed) |
| **Push Notifications** | ✅ Complete | Matrix Push Gateway API with push rules |
| **Read Receipts** | ✅ Complete | Message read tracking |
| **Typing Indicators** | ✅ Complete | Real-time typing status |
| **Room Creation** | ✅ Complete | Create rooms, invite users, manage membership |
| **Presence** | ✅ Complete | User presence and status management |
| **Account Data** | ✅ Complete | User-specific account data storage |
| **ToDevice Messaging** | ✅ Complete | Direct device-to-device messaging |
| **User Profiles** | ✅ Complete | Display name and avatar management |

[{"m.room.message') {\n        // Handle new message\n        print(": "ew message in $roomId: ${event.messageBody"}, {"m.typing') {\n        final userIds = event.content['user_ids'] as List?;\n        print(": "yping users: $userIds');"}, {"event": {"syncStream.eventsForRoom('!roomId": "server.com').listen((events) {\n  for (final event in events) {\n    print('Event in room: ${event.type"}, "typing": "userIds');"}, {"m.room.message": {"onError": "error) {\n        controller.add(Left(ServerFailure(message: error.toString())));"}, "m.typing') {\n            final userIds = event.content['user_ids": "as List? ?? [];\n            controller.add(Right(userIds.cast<String>()));"}, {"controller.add(Left(ServerFailure(message": "error.toString())));"}, {"Features": "Real-time message delivery via Matrix `/sync` endpoint\n- \u2705 Typing indicators from `m.typing` ephemeral events\n- \u2705 Read receipts from `m.receipt` ephemeral events\n- \u2705 Automatic reconnection with exponential backoff\n- \u2705 Broadcast streams for multiple listeners\n- \u2705 Proper cleanup on stream cancellation\n\n**Sync Filter Configuration:**\n\nThe SDK automatically creates an optimized sync filter:\n```dart\nfinal filter = {\n  'room': {\n    'state': {\n      'types': ['m.room.name'", "m.room.topic', 'm.room.avatar', ...],\n      'lazy_load_members": true}, {"limit": 20, "ephemeral": {"types": ["m.receipt", "m.typing"], "Flow": "Matrix Homeserver (/sync endpoint)\n         \u2193\nSyncController (continuous polling)\n         \u2193\nSyncStream (filtered streams)\n         \u2193\nChatRepositoryImpl (converts to domain entities)\n         \u2193\nSubscribeToMessagesUseCase (wraps stream)\n         \u2193\nChatBloc (listens and updates state)\n         \u2193\nUI (ChatPage - auto-updates)\n```\n\n**Performance Considerations:**\n- Sync timeout: 30 seconds (long polling)\n- Backoff time: 1-60 seconds (exponential)\n- Timeline limit: 20 events per sync\n- Lazy loading enabled for members\n- Broadcast streams avoid memory leaks"}}]

```
MatrixClient
├── SyncController       - Synchronization with lazy loading
├── RoomManager          - Room state and member management
├── MediaManager         - File upload/download
├── SearchManager        - Message and room search
├── EncryptionManager    - E2EE state and device keys
├── PushManager          - Push notifications and rules
├── ReceiptManager       - Read receipts
├── TypingManager        - Typing indicators
├── RoomCreationManager  - Room operations
├── PresenceManager      - User presence
├── AccountDataManager   - Account data
├── MessageOperationsManager - Edit, react, redact, reply
├── ToDeviceManager      - Device-to-device messaging
└── UserProfileManager   - User profiles
```

## Quick Start

```dart
// Create the client
final client = MatrixClient(
  homeserver: 'https://matrix.org',
  accessToken: 'your_token',
  userId: '@user:matrix.org',
  deviceId: 'DEVICE_ID',
);

// Connect to the homeserver
await client.connect();

// Listen for events
client.events.listen((event) {
  print('Received: ${event.type}');
});

// Send a message
await client.sendTextMessage(roomId, 'Hello, World!');
```

## Usage Examples

### Sending Messages

```dart
// Send a text message
await client.sendTextMessage(roomId, 'Hello, World!');

// Send a custom event
final event = MatrixEvent(
  type: 'm.room.message',
  roomId: roomId,
  content: {
    'msgtype': 'm.text',
    'body': 'Hello!',
  },
  txnId: client.generateTxnId(),
);
await client.sendEvent(event);
```

### Message Operations

```dart
// Edit a message
await client.messageOperations.editMessage(
  roomId,
  eventId,
  {'msgtype': 'm.text', 'body': 'Edited message'},
);

// React to a message
await client.messageOperations.reactToMessage(roomId, eventId, '👍');

// Redact (delete) a message
await client.messageOperations.redactEvent(
  roomId,
  eventId,
  reason: 'Mistake',
);

// Reply to a message
await client.messageOperations.replyToMessage(
  roomId,
  eventId,
  {'msgtype': 'm.text', 'body': 'Reply'},
);

// Get reactions for a message
final reactions = await client.messageOperations.getReactions(roomId, eventId);
```

### Room Operations

```dart
// Create a new room
final response = await client.roomCreationManager.createRoom(
  name: 'My Room',
  topic: 'Room topic',
  isPublic: false,
);

// Invite a user
await client.roomCreationManager.inviteUser(roomId, '@user:matrix.org');

// Kick a user
await client.roomCreationManager.kickUser(roomId, '@user:matrix.org');

// Ban a user
await client.roomCreationManager.banUser(
  roomId,
  '@user:matrix.org',
  reason: 'Spam',
);

// Unban a user
await client.roomCreationManager.unbanUser(roomId, '@user:matrix.org');

// Set room name
await client.roomCreationManager.setRoomName(roomId, 'New Name');

// Set room topic
await client.roomCreationManager.setRoomTopic(roomId, 'New Topic');

// Set room avatar
await client.roomCreationManager.setRoomAvatar(roomId, mxcUri);
```

### Media Operations

```dart
// Upload a file
final mxcUri = await client.mediaManager.uploadFile(
  File('/path/to/file.jpg'),
  filename: 'photo.jpg',
);

// Upload image bytes
final mxcUri = await client.mediaManager.uploadImage(
  imageBytes,
  filename: 'photo.jpg',
  contentType: 'image/jpeg',
);

// Send an image message
await client.mediaManager.sendImageMessage(
  roomId,
  mxcUri,
  filename: 'photo.jpg',
  width: 1920,
  height: 1080,
);

// Download a file
final file = await client.mediaManager.downloadFile(
  'mxc://server.com/mediaId',
  '/path/to/save.jpg',
);

// Convert MXC to HTTP URL
final httpUrl = client.mediaManager.mxcToHttp('mxc://server.com/mediaId');
```

### Search Operations

```dart
// Search for messages
final results = await client.searchManager.searchMessages(
  'search query',
  limit: 20,
);

// Search rooms
final rooms = await client.searchManager.searchRooms(
  'room name',
  limit: 10,
);

// Get results grouped by room
final grouped = await client.searchManager.searchMessagesByRoom(
  'query',
  limit: 50,
);
```

### Read Receipts

```dart
// Send a read receipt
await client.receiptManager.sendReadReceipt(roomId, eventId);

// Send a fully read receipt (for notifications)
await client.receiptManager.sendFullyReadReceipt(roomId, eventId);

// Get read receipts for an event
final receipts = await client.receiptManager.getReadReceipts(roomId, eventId);
```

### Typing Indicators

```dart
// Send typing indicator
await client.typingManager.sendTyping(roomId, true);

// Stop typing indicator
await client.typingManager.sendTyping(roomId, false);

// Cancel typing for a room
client.typingManager.cancelTyping(roomId);
```

### Presence

```dart
// Set own presence
await client.presenceManager.setPresence(
  PresenceStatus.online,
  statusMessage: 'Available',
);

// Get user presence
final presence = await client.presenceManager.getPresence('@user:matrix.org');

// Get presence for multiple users
final presences = await client.presenceManager.getPresenceList([
  '@user1:matrix.org',
  '@user2:matrix.org',
]);
```

### User Profiles

```dart
// Get display name
final displayName = await client.userProfileManager.getDisplayName();

// Set display name
await client.userProfileManager.setDisplayName('John Doe');

// Get avatar URL
final avatarUrl = await client.userProfileManager.getAvatarUrl();

// Set avatar URL
await client.userProfileManager.setAvatarUrl(mxcUri);

// Upload and set avatar
await client.userProfileManager.uploadAndSetAvatar(
  imageBytes,
  'avatar.jpg',
  contentType: 'image/jpeg',
);

// Get full profile
final profile = await client.userProfileManager.getProfile('@user:matrix.org');
```

### Account Data

```dart
// Set account data
await client.accountDataManager.setAccountData('m.my_data', {'key': 'value'});

// Get account data
final data = await client.accountDataManager.getAccountData('m.my_data');

// Set room-specific account data
await client.accountDataManager.setRoomAccountData(
  roomId,
  'm.my_room_data',
  {'key': 'value'},
);

// Get direct message mapping
final directMessages = await client.accountDataManager.getDirectMessages();

// Set ignored users
await client.accountDataManager.setIgnoredUsers(['@spam:matrix.org']);

// Get ignored users
final ignored = await client.accountDataManager.getIgnoredUsers();
```

### To-Device Messaging

```dart
// Send to-device event
await client.toDeviceManager.sendToDevice(
  'm.room_key',
  {'algorithm': 'm.megolm.v1.aes-sha2'},
  '@user:matrix.org',
  'DEVICE_ID',
);

// Send to multiple devices
await client.toDeviceManager.sendToDeviceMultiple(
  'm.verification',
  {
    '@user1:matrix.org': {
      'DEVICE1': {'key': 'value'},
    },
  },
);
```

### Encryption

```dart
// Check if room is encrypted
final isEncrypted = client.encryptionManager.isRoomEncrypted(roomId);

// Enable encryption
await client.encryptionManager.enableEncryption(
  roomId,
  algorithm: 'm.megolm.v1.aes-sha2',
  rotationPeriodMs: 604800000,
);

// Get encryption config
final config = client.encryptionManager.getRoomEncryptionConfig(roomId);

// Upload device keys
await client.encryptionManager.uploadDeviceKeys();

// Query device keys
final deviceKeys = await client.encryptionManager.queryDeviceKeys([
  '@user:matrix.org',
]);

// Claim one-time keys
final oneTimeKeys = await client.encryptionManager.claimOneTimeKeys({
  '@user:matrix.org': ['DEVICE1'],
});
```

### Push Notifications

```dart
// Enable push
await client.pushManager.enablePush(
  gatewayUrl: 'https://matrix.org/_matrix/push/v1/notify',
  token: 'fcm_token',
  appId: 'io.voxmatrix.app',
  deviceName: 'My Device',
);

// Update push token
await client.pushManager.setPushToken('new_token');

// Get pushers
final pushers = await client.pushManager.getPushers();

// Get push rules
final rules = await client.pushManager.getPushRules();

// Disable push
await client.pushManager.disablePush();
```

## Models

### MatrixEvent

```dart
final event = MatrixEvent(
  type: 'm.room.message',
  roomId: '!roomId:server.com',
  eventId: '$eventId:server.com',
  senderId: '@user:server.com',
  timestamp: 1234567890,
  content: {'msgtype': 'm.text', 'body': 'Hello!'},
  stateKey: '@user:server.com',
);

// Convenience getters
event.isStateEvent;     // true if stateKey is not null
event.isMessageEvent;   // true if type is m.room.message
event.messageBody;      // Extract message body
event.roomName;         // Extract room name
event.membership;       // Extract membership
```

### MatrixRoom

```dart
final room = MatrixRoom(
  id: '!roomId:server.com',
  name: 'My Room',
  topic: 'Room topic',
  avatarUrl: 'mxc://server.com/mediaId',
  isDirect: false,
  members: [user1, user2],
  joinedMemberCount: 5,
  invitedMemberCount: 1,
);
```

### UserProfile

```dart
final profile = UserProfile(
  displayName: 'John Doe',
  avatarUrl: 'mxc://server.com/avatar',
);

profile.hasDisplayName; // true if has display name
profile.hasAvatar;      // true if has avatar
profile.isEmpty;        // true if no data
```

### PresenceInfo

```dart
final presence = PresenceInfo(
  userId: '@user:matrix.org',
  presence: PresenceStatus.online,
  lastActiveAgo: 60000,
  statusMessage: 'Available',
  currentlyActive: true,
);

presence.lastActiveTime; // DateTime of last activity
```

## Connection States

- `disconnected` - Not connected to the homeserver
- `connecting` - Currently connecting
- `connected` - Connected and idle
- `syncing` - Currently syncing
- `reconnecting` - Reconnecting after failure
- `failed` - Connection failed
- `waitingForToken` - Waiting for authentication token

## Error Handling

```dart
try {
  await client.joinRoom(roomId);
} on MatrixException catch (e) {
  print('Failed to join room: ${e.message}');
}
```

## API Reference

### MatrixClient

| Method | Description |
|--------|-------------|
| `connect()` | Connect to homeserver and start syncing |
| `disconnect()` | Stop syncing and disconnect |
| `dispose()` | Clean up all resources |
| `sendTextMessage(roomId, text)` | Send a text message |
| `sendEvent(event)` | Send a custom event |
| `joinRoom(roomId)` | Join a room |
| `leaveRoom(roomId)` | Leave a room |
| `generateTxnId()` | Generate a transaction ID |

### MessageOperationsManager

| Method | Description |
|--------|-------------|
| `editMessage(roomId, eventId, content)` | Edit a message |
| `reactToMessage(roomId, eventId, emoji)` | React to a message |
| `redactEvent(roomId, eventId, reason)` | Delete a message |
| `replyToMessage(roomId, eventId, content)` | Reply to a message |
| `getReactions(roomId, eventId)` | Get reactions |
| `getEditHistory(roomId, eventId)` | Get edit history |

### RoomCreationManager

| Method | Description |
|--------|-------------|
| `createRoom(name, topic, ...)` | Create a new room |
| `inviteUser(roomId, userId)` | Invite a user |
| `kickUser(roomId, userId, reason)` | Kick a user |
| `banUser(roomId, userId, reason)` | Ban a user |
| `unbanUser(roomId, userId)` | Unban a user |
| `setRoomName(roomId, name)` | Set room name |
| `setRoomTopic(roomId, topic)` | Set room topic |
| `setRoomAvatar(roomId, mxcUri)` | Set room avatar |

### UserProfileManager

| Method | Description |
|--------|-------------|
| `getDisplayName(userId)` | Get display name |
| `setDisplayName(name)` | Set own display name |
| `getAvatarUrl(userId)` | Get avatar URL |
| `setAvatarUrl(mxcUri)` | Set own avatar |
| `uploadAndSetAvatar(bytes, filename)` | Upload and set avatar |
| `getProfile(userId)` | Get full profile |

## Matrix Spec Compliance

| Feature | Status |
|---------|--------|
| Sync endpoint | ✅ Complete |
| Room events | ✅ Complete |
| Member management | ✅ Complete |
| Message sending | ✅ Complete |
| Room operations | ✅ Complete |
| Media operations | ✅ Complete |
| Search | ✅ Complete |
| E2EE | ⚠️ Partial |
| Push notifications | ✅ Complete |
| Device management | ⚠️ Partial |
| Read receipts | ✅ Complete |
| Typing indicators | ✅ Complete |
| Presence | ✅ Complete |
| Account data | ✅ Complete |
| To-device messaging | ✅ Complete |
| User profiles | ✅ Complete |

## Future Enhancements

- [ ] Complete E2EE implementation with Olm/Megolm
- [ ] Voice/Video calling (WebRTC)
- [ ] Cross-signing for device verification
- [ ] Secret storage (SSSS)
- [ ] Spaces support
- [ ] Location sharing
- [ ] Polls support
- [ ] Threaded conversations

## License

This SDK is part of the VoxMatrix project.
