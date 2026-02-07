# Matrix Built-in Calling Implementation

## Overview

Instead of using LiveKit server, we'll use Matrix's built-in `m.call` events for WebRTC signaling. This leverages:
- Existing Synapse server
- Existing Coturn TURN server
- Flutter WebRTC directly (no LiveKit dependency needed)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Matrix Protocol Signaling                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Caller                         Callee                      │
│      │                            │                          │
│      │  m.call.invite             │                          │
│      ├───────────────────────────►│                          │
│      │                            │                          │
│      │                            │  m.call.answer             │
│      │◄───────────────────────────┤                          │
│      │                            │                          │
│      │  ICE candidates exchange   │                          │
│      │◄──────────────────────────►│                          │
│      │                            │                          │
│      │  WebRTC Connection         │                          │
│      │◄──────────────────────────►│                          │
│      │                            │                          │
│      │  m.call.hangup             │                          │
│      ├───────────────────────────►│                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Steps

### Phase 1: Remove LiveKit Dependencies (Day 1)

1. Update pubspec.yaml
2. Remove LiveKit from docker-compose
3. Update datasources

### Phase 2: Implement Matrix Calling (Days 2-3)

1. Create MatrixCallSignalingDataSource (already exists)
2. Update WebRTCDataSource to use flutter_webrtc
3. Implement CallRepository with Matrix signaling
4. Create call UI components

### Phase 3: Testing (Day 4)

1. Test call flow
2. Test audio/video
3. Test across devices

## Benefits

✅ No additional server needed
✅ Uses Matrix protocol natively
✅ Works with existing infrastructure
✅ Simpler architecture
✅ Better Matrix compliance