# VoxMatrix Production Roadmap

This roadmap breaks the production plan into milestones and issue‑style tasks.

## Milestone 1: Core Messaging Reliability

### Goal
Stable, realtime, SDK‑only messaging with consistent unread counts and read receipts.

### Tasks
1. SDK‑only room list and timeline
2. Ensure SDK init is single‑instance and idempotent
3. Timeline pagination + scroll anchor
4. Message de‑duplication and ordering guarantees
5. Read markers auto‑sent when chat in view
6. Read receipts per message
7. Unread badges update on sync

## Milestone 2: E2EE Hardening

### Goal
Reliable encryption and device trust for real users.

### Tasks
1. Device verification UX (emoji/number)
2. Cross‑signing state support
3. Key backup / recovery
4. Encrypted search index (local)

## Milestone 3: Performance & UX

### Goal
Fast UI with large room timelines.

### Tasks
1. Timeline virtualization
2. Lazy load room members
3. Offline cache for rooms/messages
4. Background sync tuning
5. Presence/typing reliability

## Milestone 4: Calls & Media

### Goal
Production‑grade voice/video and media flows.

### Tasks
1. WebRTC stability (ICE retry, call recovery)
2. Media upload progress + retry
3. Background call handling
4. Call UI polish

## Milestone 5: Security & Privacy

### Goal
Security posture suitable for public deployment.

### Tasks
1. Secure storage audit
2. Sensitive log suppression
3. Threat model review
4. Dependency audit

## Milestone 6: Server & Deployment

### Goal
Reliable Synapse + TURN deployment with backups.

### Tasks
1. Postgres + Redis config
2. TURN configuration review
3. Automated backups
4. Monitoring + alerting
5. Health checks

## Milestone 7: QA & Release

### Goal
Repeatable releases with automated testing.

### Tasks
1. Unit tests for repositories
2. Integration tests for sync + E2EE
3. UI smoke tests
4. CI for Android/iOS
5. Release workflow + changelog
