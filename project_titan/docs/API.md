# Project TITAN 2.0 — API Reference Manual

## Overview
Project TITAN exposes a clean modular API surface across its 25 sub-packages.

---

## Package References

### 1. `titan_security`
Production security, key management, encryption, and certificate validation.

- **`SecretManager`**: Obfuscates transient string secrets (`obfuscate`), computes SHA-256 hashes (`hashSecret`), stores and verifies secrets in memory (`setSecret`, `getSecret`, `verifySecret`, `hasSecret`, `loadFromMap`).
- **`SecureApiKeyManager`**: Reads and writes API keys to platform secure keychain (`saveApiKey`, `getApiKey`, `hasApiKey`, `deleteApiKey`, `clearAllApiKeys`), validates format (`isValidApiKey`).
- **`EncryptionService`**: Base64 XOR cipher encryption (`encrypt`, `decrypt`), SHA-256 hash generation (`hash`), and HMAC SHA-256 signature computation (`computeHmac`).
- **`CertificateValidator`**: Validates X.509 certificates (`validateCertificate`) against allowed domain hosts (`allowedDomains`) and SHA-256 fingerprints (`allowedSha256Fingerprints`).
- **`PermissionManager`**: Abstraction for querying and requesting platform device permissions (`requestPermission`, `checkPermission`, `isGranted`, `setPermissionStatus`, `reset`).

---

### 2. `titan_core`
Core foundation, telemetry, global error handling, feature flags, and performance optimization suite.

#### Observability & Telemetry
- **`GlobalErrorHandler`** (`TitanErrorHandler`): Attaches framework error handler (`FlutterError.onError`) and async error dispatcher (`PlatformDispatcher.onError`), captures uncaught exceptions (`captureFrameworkError`, `captureAsyncError`, `captureUncaughtError`).
- **`CrashReport`**: Immutable crash telemetry payload aggregating error ID, message, stack trace, error type, timestamp, and metadata. Supports `toJson()` / `fromJson()`.
- **`TitanLogger`** & **`ConsoleTitanLogger`**: Multi-sink logger with PII sanitization and level filtering (`trace`, `debug`, `info`, `warning`, `error`, `critical`).
- **`HealthMonitor`**: Subsystem operational health registry (`registerChecker`, `checkHealth`, `isSystemOperational`).
- **`FeatureFlagService`**: Manages 8 production beta feature toggles (`video_classes`, `live_classes`, `marketplace`, `voice_mentor`, `ai_tutor`, `gamification`, `multiplayer`, `teacher_portal`).

#### Performance Optimization Suite
- **`StartupOptimizer`**: Phased asynchronous startup measurement (`runPhase`, `start`, `stop`), post-frame task deferral (`deferTask`), and duration metrics.
- **`MemoryManager`**: Memory pressure listener registry (`registerTrimListener`), cache size tracking (`updateCacheCount`), and trim trigger (`triggerMemoryPressure`).
- **`LazyLoader<T>`**: On-demand instance instantiation (`instance`, `instanceOrNull`, `isInitialized`, `reset`).
- **`BackgroundWorker`**: Heavy compute isolate execution (`run`) and non-blocking batch microtask queueing (`processBatch`).
- **`TitanCacheOptimizer<K, V>`**: Multi-tier memory cache with LRU eviction (`put`, `get`), TTL expiration (`cleanExpired`), and capacity limits.

---

### 3. `titan_ai_mentor`
AI Mentor orchestration engine.

- **`MentorEngine`**: Multi-provider AI completion and stream generation.
- **`ContextAssembler`**: Aggregates learner profile, quiz history, knowledge graph context, and planner progress into unified prompts.
- **Providers**: `GeminiMentorProvider`, `OpenAIMentorProvider`, `MockMentorProvider`.

---

### 4. `titan_dashboard`
Analytics Dashboard 2.0.

- **`DashboardEngine`**: Snapshot calculation and real-time metric updates.
- **`MetricsAggregator`**: Aggregates metrics from all TITAN engines.
- **`DashboardCache`**: Offline-first snapshot storage with TTL validation.
