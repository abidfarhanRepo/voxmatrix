# LiveKit Setup Progress

## Date: 2026-02-06

## Current Status

### ✅ **Completed**
1. **Server Infrastructure Running**
   - Synapse: ✅ Running (http://192.168.10.4:8008)
   - PostgreSQL: ✅ Running (port 5432)
   - Redis: ✅ Running (port 6379)
   - Coturn: ✅ Running (TURN server)
   - Caddy: ✅ Running (reverse proxy)

2. **API Keys Generated**
   - API Key: `APIpDM6DpJK43cN`
   - API Secret: `f38Ks5oBVlC0IKapWHueB9V9aJvL8ycU1qCnlzfr1FmA`

### ⚠️ **In Progress**
1. **LiveKit Server Setup**
   - **Issue**: Docker-compose configuration conflicts with legacy containers
   - **Root Cause**: Old container metadata (`ContainerConfig` key errors)
   - **Current Status**: LiveKit container exits immediately

2. **Configuration Challenges**
   - LiveKit server requires specific key format: `key: secret` (with space)
   - Environment variable parsing issues in docker-compose
   - Network connectivity between services

---

## Solutions Attempted

### Attempt 1: Configuration File
```yaml
port: 7880
rtc:
  port_range_start: 50000
  port_range_end: 60000
  use_external_ip: true
redis:
  address: redis:6379
room:
  auto_create: true
keys:
  VoxMatrixKey1: VoxMatrixSecret12345678901234567890
```
**Result**: Failed - "Could not parse keys" error

### Attempt 2: Environment Variables
```yaml
environment:
  - LIVEKIT_KEYS=VoxMatrixKey1:VoxMatrixSecret12345678901234567890
  - LIVEKIT_REDIS_ADDRESS=redis:6379
```
**Result**: Failed - Parsing error

### Attempt 3: Command Line Arguments
```yaml
command: --dev --redis redis:6379 --keys "VoxMatrixKey1:VoxMatrixSecret..."
```
**Result**: Failed - Flag parsing error

### Attempt 4: Docker Direct Run
```bash
docker run --rm \
  --network voxmatrix_voxmatrix-network \
  --link voxmatrix-redis:redis \
  -p 7880:7880 -p 7881:7881 \
  -e LIVEKIT_REDIS_ADDRESS="redis:6379" \
  -e LIVEKIT_KEYS="APIpDM6DpJK43cN:f38Ks5oBVlC0IKapWHue..." \
  livekit/livekit-server:latest
```
**Result**: Failed - Same parsing errors

---

## Root Cause Analysis

### Issue 1: LiveKit Version Compatibility
**Problem**: LiveKit server v1.9.11 has strict configuration requirements
**Evidence**:
- Error: `Could not parse keys, it needs to be exactly, "key: secret", including the space`
- Multiple attempts with different formats all failed

### Issue 2: Docker Legacy Metadata
**Problem**: Old containers have incompatible metadata
**Evidence**:
```
KeyError: 'ContainerConfig'
```
This suggests docker-compose is trying to access old container metadata structures.

---

## Recommended Next Steps

### Option 1: Alternative WebRTC Solution (RECOMMENDED)
Instead of using LiveKit server, consider:

1. **Use Matrix Built-in Calling**
   - Synapse supports `m.call` events
   - No additional server needed
   - Simpler architecture
   - Better Matrix protocol compliance

2. **Use Jitsi Meet (Matrix-compatible)**
   - Well-established Matrix integration
   - Docker deployment available
   - Battle-tested

3. **Use Mediasoup (Matrix WebRTC implementation)**
   - Matrix-focused WebRTC library
   - Direct Matrix protocol support

### Option 2: Simplified LiveKit Setup
If LiveKit must be used:

1. **Clean All VoxMatrix Containers**
   ```bash
   docker-compose down
   docker system prune -a
   docker volume ls | grep voxmatrix | awk '{print $2}' | xargs docker volume rm -f
   ```

2. **Use Official LiveKit Docker Compose**
   Reference: https://github.com/livekit/livekit/tree/master/deploy/docker-compose

3. **Start Fresh**
   ```bash
   git clone https://github.com/livekit/livekit.git temp-livekit
   cd temp-livekit/deploy/docker-compose
   docker-compose up -d
   ```

### Option 3: Defer WebRTC to Phase 2
Focus on E2EE fix first, then return to WebRTC with fresh approach.

---

## Working Server Configuration

### Synapse
- **Status**: ✅ Running and Healthy
- **URL**: http://192.168.10.4:8008
- **Version**: Latest
- **Database**: PostgreSQL 16

### PostgreSQL
- **Status**: ✅ Running and Healthy
- **User**: synapse
- **Database**: synapse

### Coturn (TURN)
- **Status**: ✅ Running
- **Protocol**: TCP/UDP
- **Ports**: 3478, 5349

### Redis
- **Status**: ✅ Running
- **Port**: 6379
- **Purpose**: For LiveKit (when configured)

---

## Generated LiveKit Credentials

**API Key**: `APIpDM6DpJK43cN`
**API Secret**: `f38Ks5oBVlC0IKapWHueB9V9aJvL8ycU1qCnlzfr1FmA`

⚠️ **IMPORTANT**: These credentials were generated but LiveKit server is not yet running. Save these securely.

---

## Decision Needed

Given the LiveKit configuration challenges, please choose:

1. **Alternative WebRTC**: Use Matrix built-in calling or Jitsi instead
2. **Fresh LiveKit**: Clean containers and use official LiveKit deployment
3. **Defer WebRTC**: Focus on E2EE first, return to WebRTC later

**Recommendation**: Option 1 (Alternative WebRTC) for fastest path to beta.

---

## Files Modified

- `/server/docker-compose.yml` - Multiple iterations attempted
- `/server/livekit/livekit.yaml` - Configuration created
- `/server/start-livekit.sh` - Setup script created

## Files Created

- `/server/LIVEKIT_SETUP_PROGRESS.md` - This file
- `/server/livekit-credentials.txt` - API keys (NEVER COMMIT THIS)

---

**Next Action**: Please choose one of the three options above, or ask for help with specific LiveKit configuration.
