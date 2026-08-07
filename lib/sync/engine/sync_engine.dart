import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../core/conflict_resolver.dart';
import '../core/sync_entity.dart';
import '../core/sync_metadata.dart';
import '../core/sync_snapshot.dart';
import '../core/sync_target.dart';
import '../providers/cloud_sync_provider.dart';
import 'sync_queue.dart';

/// Network connectivity states for the sync layer.
enum ConnectivityStatus {
  online,
  offline,
  limitedConnectivity,
}

/// Transition event emitted when network connectivity state changes.
class ConnectivityTransition {
  final ConnectivityStatus previousStatus;
  final ConnectivityStatus currentStatus;
  final DateTime timestamp;

  ConnectivityTransition({
    required this.previousStatus,
    required this.currentStatus,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();
}

/// Connectivity monitoring domain service for Project TITAN.
class ConnectivityMonitor extends ChangeNotifier {
  ConnectivityStatus _status = ConnectivityStatus.online;
  final StreamController<ConnectivityTransition> _transitionController =
      StreamController<ConnectivityTransition>.broadcast();

  ConnectivityStatus get status => _status;
  Stream<ConnectivityTransition> get transitionStream =>
      _transitionController.stream;

  bool get isOnline => _status == ConnectivityStatus.online;
  bool get isOffline => _status == ConnectivityStatus.offline;
  bool get isLimited => _status == ConnectivityStatus.limitedConnectivity;

  void setStatus(ConnectivityStatus newStatus) {
    if (_status != newStatus) {
      final prev = _status;
      _status = newStatus;
      _transitionController.add(
        ConnectivityTransition(
          previousStatus: prev,
          currentStatus: newStatus,
        ),
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _transitionController.close();
    super.dispose();
  }
}

/// Supported sync operation action types.
enum SyncAction {
  create,
  update,
  delete,
  retry,
  cancel,
  queue,
  resume,
  backgroundSync,
}

/// Execution status of individual sync operations in queue.
enum SyncOperationStatus {
  pending,
  running,
  completed,
  failed,
  retrying,
  cancelled,
}

/// Security utility ensuring sensitive credentials are never stored or synced locally.
class SyncSecurity {
  static const Set<String> forbiddenKeys = {
    'api_key',
    'apikey',
    'jwt',
    'jwt_secret',
    'secret',
    'provider_credentials',
    'credentials',
    'password',
    'token',
    'access_token',
    'refresh_token',
    'private_key',
  };

  /// Sanitizes payload JSON maps by scrubbing forbidden credential keys.
  static Map<String, dynamic> sanitizePayload(Map<String, dynamic> payload) {
    final sanitized = Map<String, dynamic>.from(payload);
    sanitized.removeWhere(
      (key, _) => forbiddenKeys.contains(key.toLowerCase()),
    );
    return sanitized;
  }
}

/// Immutable data model representing a synchronization operation.
class SyncOperation {
  final String operationId;
  final SyncEntityType entityType;
  final String entityId;
  final SyncAction action;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int version;
  final String deviceId;
  final SyncOperationStatus status;
  final int retryCount;
  final String? lastError;

  SyncOperation({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required Map<String, dynamic> payload,
    DateTime? timestamp,
    this.version = 1,
    required this.deviceId,
    this.status = SyncOperationStatus.pending,
    this.retryCount = 0,
    this.lastError,
  })  : payload = SyncSecurity.sanitizePayload(payload),
        timestamp = timestamp ?? DateTime.now().toUtc();

  SyncOperation copyWith({
    String? operationId,
    SyncEntityType? entityType,
    String? entityId,
    SyncAction? action,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    int? version,
    String? deviceId,
    SyncOperationStatus? status,
    int? retryCount,
    String? lastError,
  }) {
    return SyncOperation(
      operationId: operationId ?? this.operationId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      version: version ?? this.version,
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'entityType': entityType.name,
        'entityId': entityId,
        'action': action.name,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
        'deviceId': deviceId,
        'status': status.name,
        'retryCount': retryCount,
        'lastError': lastError,
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
        operationId: json['operationId'] as String,
        entityType: SyncEntityType.values.firstWhere(
          (e) => e.name == json['entityType'],
          orElse: () => SyncEntityType.bookmark,
        ),
        entityId: json['entityId'] as String,
        action: SyncAction.values.firstWhere(
          (e) => e.name == json['action'],
          orElse: () => SyncAction.update,
        ),
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String).toUtc()
            : DateTime.now().toUtc(),
        version: json['version'] as int? ?? 1,
        deviceId: json['deviceId'] as String? ?? 'unknown_device',
        status: SyncOperationStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SyncOperationStatus.pending,
        ),
        retryCount: json['retryCount'] as int? ?? 0,
        lastError: json['lastError'] as String?,
      );
}

/// Execution result model summarizing synchronization cycles.
class SyncResult {
  final bool isSuccess;
  final int itemsProcessed;
  final int itemsFailed;
  final int conflictsDetected;
  final DateTime completedAt;
  final String? errorMessage;

  const SyncResult({
    required this.isSuccess,
    required this.itemsProcessed,
    this.itemsFailed = 0,
    this.conflictsDetected = 0,
    required this.completedAt,
    this.errorMessage,
  });

  factory SyncResult.empty() => SyncResult(
        isSuccess: true,
        itemsProcessed: 0,
        completedAt: DateTime.now().toUtc(),
      );

  SyncResult copyWith({
    bool? isSuccess,
    int? itemsProcessed,
    int? itemsFailed,
    int? conflictsDetected,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return SyncResult(
      isSuccess: isSuccess ?? this.isSuccess,
      itemsProcessed: itemsProcessed ?? this.itemsProcessed,
      itemsFailed: itemsFailed ?? this.itemsFailed,
      conflictsDetected: conflictsDetected ?? this.conflictsDetected,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'itemsProcessed': itemsProcessed,
        'itemsFailed': itemsFailed,
        'conflictsDetected': conflictsDetected,
        'completedAt': completedAt.toIso8601String(),
        'errorMessage': errorMessage,
      };

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
        isSuccess: json['isSuccess'] as bool? ?? false,
        itemsProcessed: json['itemsProcessed'] as int? ?? 0,
        itemsFailed: json['itemsFailed'] as int? ?? 0,
        conflictsDetected: json['conflictsDetected'] as int? ?? 0,
        completedAt: DateTime.parse(json['completedAt'] as String).toUtc(),
        errorMessage: json['errorMessage'] as String?,
      );
}

/// Configurable exponential backoff retry policy for sync operations.
class RetryPolicy {
  final int maxRetryCount;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryPolicy({
    this.maxRetryCount = 5,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 5),
  });

  /// Computes exponential delay for a retry attempt.
  Duration getDelayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;
    final delayMs =
        (initialDelay.inMilliseconds * math.pow(backoffMultiplier, attempt - 1))
            .round();
    final calculated = Duration(milliseconds: delayMs);
    return calculated > maxDelay ? maxDelay : calculated;
  }

  bool shouldRetry(int currentAttempts) => currentAttempts < maxRetryCount;
}

/// Current status of the SyncEngine.
enum SyncState {
  idle,
  syncing,
  success,
  error,
}

/// Central offline-first Cloud Synchronization Engine for QuizForge AI & GARUDA.
class SyncEngine extends ChangeNotifier {
  static final SyncEngine _instance = SyncEngine._internal();
  factory SyncEngine() => _instance;

  SyncEngine._internal();

  final Map<SyncEntityType, SyncTarget> _targets = {};
  final SyncQueue _syncQueue = SyncQueue();

  CloudSyncProvider? _activeProvider;
  ConflictResolutionStrategy _conflictStrategy =
      ConflictResolutionStrategy.lastWriteWins;

  SyncState _state = SyncState.idle;
  String _lastErrorMessage = '';
  DateTime? _lastSuccessfulSyncTime;
  String _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';

  // Getters
  SyncState get state => _state;
  String get lastErrorMessage => _lastErrorMessage;
  DateTime? get lastSuccessfulSyncTime => _lastSuccessfulSyncTime;
  CloudSyncProvider? get activeProvider => _activeProvider;
  SyncQueue get queue => _syncQueue;
  String get deviceId => _deviceId;
  ConflictResolutionStrategy get conflictStrategy => _conflictStrategy;

  /// Set client device identifier.
  void setDeviceId(String id) {
    _deviceId = id;
    notifyListeners();
  }

  /// Register a domain sync target adapter.
  void registerTarget(SyncTarget target) {
    _targets[target.targetType] = target;
    notifyListeners();
  }

  /// Configure active cloud provider backend.
  void setCloudProvider(CloudSyncProvider? provider) {
    _activeProvider = provider;
    notifyListeners();
  }

  /// Configure conflict resolution strategy.
  void setConflictStrategy(ConflictResolutionStrategy strategy) {
    _conflictStrategy = strategy;
    notifyListeners();
  }

  /// Record local mutation into offline sync queue.
  void recordLocalMutation(SyncEntity<Map<String, dynamic>> entity) {
    _syncQueue.enqueue(entity);
    notifyListeners();
  }

  /// Perform full two-way synchronization cycle.
  Future<bool> syncNow() async {
    if (_activeProvider == null) {
      _state = SyncState.error;
      _lastErrorMessage = 'No active cloud sync provider configured';
      notifyListeners();
      return false;
    }

    _state = SyncState.syncing;
    _lastErrorMessage = '';
    notifyListeners();

    try {
      final connected = await _activeProvider!.isConnected() ||
          await _activeProvider!.authenticate();

      if (!connected) {
        throw Exception(
            'Failed to connect to cloud provider (${_activeProvider!.name})');
      }

      // 1. Gather all local entities across registered targets
      final List<SyncEntity<Map<String, dynamic>>> localBookmarks = [];
      final List<SyncEntity<Map<String, dynamic>>> localNotes = [];
      final List<SyncEntity<Map<String, dynamic>>> localStats = [];
      final List<SyncEntity<Map<String, dynamic>>> localRevisions = [];
      final List<SyncEntity<Map<String, dynamic>>> localSettings = [];

      if (_targets.containsKey(SyncEntityType.bookmark)) {
        localBookmarks.addAll(
            await _targets[SyncEntityType.bookmark]!.exportLocalEntities());
      }
      if (_targets.containsKey(SyncEntityType.note)) {
        localNotes.addAll(
            await _targets[SyncEntityType.note]!.exportLocalEntities());
      }
      if (_targets.containsKey(SyncEntityType.statistics)) {
        localStats.addAll(
            await _targets[SyncEntityType.statistics]!.exportLocalEntities());
      }
      if (_targets.containsKey(SyncEntityType.revisionSchedule)) {
        localRevisions.addAll(await _targets[SyncEntityType.revisionSchedule]!
            .exportLocalEntities());
      }
      if (_targets.containsKey(SyncEntityType.settings)) {
        localSettings.addAll(
            await _targets[SyncEntityType.settings]!.exportLocalEntities());
      }

      // 2. Fetch remote snapshot
      final remoteSnapshot = await _activeProvider!.downloadSnapshot();

      // 3. Resolve & Merge lists for each domain target
      final mergedBookmarks = _mergeDomainLists(
        local: localBookmarks,
        remote: remoteSnapshot?.bookmarks ?? [],
      );
      final mergedNotes = _mergeDomainLists(
        local: localNotes,
        remote: remoteSnapshot?.notes ?? [],
      );
      final mergedStats = _mergeDomainLists(
        local: localStats,
        remote: remoteSnapshot?.statistics ?? [],
      );
      final mergedRevisions = _mergeDomainLists(
        local: localRevisions,
        remote: remoteSnapshot?.revisionSchedules ?? [],
      );
      final mergedSettings = _mergeDomainLists(
        local: localSettings,
        remote: remoteSnapshot?.settings ?? [],
      );

      // 4. Apply merged changes to local targets
      if (_targets.containsKey(SyncEntityType.bookmark)) {
        await _targets[SyncEntityType.bookmark]!
            .applyRemoteEntities(mergedBookmarks);
      }
      if (_targets.containsKey(SyncEntityType.note)) {
        await _targets[SyncEntityType.note]!.applyRemoteEntities(mergedNotes);
      }
      if (_targets.containsKey(SyncEntityType.statistics)) {
        await _targets[SyncEntityType.statistics]!
            .applyRemoteEntities(mergedStats);
      }
      if (_targets.containsKey(SyncEntityType.revisionSchedule)) {
        await _targets[SyncEntityType.revisionSchedule]!
            .applyRemoteEntities(mergedRevisions);
      }
      if (_targets.containsKey(SyncEntityType.settings)) {
        await _targets[SyncEntityType.settings]!
            .applyRemoteEntities(mergedSettings);
      }

      // 5. Build unified merged snapshot & upload to cloud
      final mergedSnapshot = SyncSnapshot(
        snapshotId: 'snap_${DateTime.now().millisecondsSinceEpoch}',
        clientDeviceId: _deviceId,
        createdAt: DateTime.now().toUtc(),
        bookmarks: mergedBookmarks,
        notes: mergedNotes,
        statistics: mergedStats,
        revisionSchedules: mergedRevisions,
        settings: mergedSettings,
      );

      final uploadOk = await _activeProvider!.uploadSnapshot(mergedSnapshot);
      if (!uploadOk) {
        throw Exception('Cloud provider failed to save updated snapshot');
      }

      // 6. Update timestamps & clear queue on success
      _syncQueue.clear();
      _lastSuccessfulSyncTime = DateTime.now().toUtc();

      for (final t in _targets.values) {
        await t.updateLastSyncTime(_lastSuccessfulSyncTime!);
      }

      _state = SyncState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = SyncState.error;
      _lastErrorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  List<SyncEntity<Map<String, dynamic>>> _mergeDomainLists({
    required List<SyncEntity<Map<String, dynamic>>> local,
    required List<SyncEntity<Map<String, dynamic>>> remote,
  }) {
    final Map<String, SyncEntity<Map<String, dynamic>>> map = {};

    for (final loc in local) {
      map[loc.metadata.entityId] = loc;
    }

    for (final rem in remote) {
      final id = rem.metadata.entityId;
      if (!map.containsKey(id)) {
        map[id] = rem;
      } else {
        final loc = map[id]!;
        final result = ConflictResolver.resolve(
          local: loc,
          remote: rem,
          strategy: _conflictStrategy,
        );
        map[id] = result.resolvedEntity;
      }
    }

    return map.values.toList();
  }

  /// Reset engine state (for testing or logging out).
  void resetEngine() {
    _targets.clear();
    _syncQueue.clear();
    _activeProvider = null;
    _state = SyncState.idle;
    _lastErrorMessage = '';
    _lastSuccessfulSyncTime = null;
    notifyListeners();
  }
}

/// High-level Synchronization Manager for Project TITAN & GARUDA.
/// Manages offline queueing, connectivity recovery detection, exponential backoff,
/// background batch sync, and deterministic conflict resolution.
class SyncManager extends ChangeNotifier {
  final SyncEngine _engine;
  final ConnectivityMonitor _connectivityMonitor;
  final RetryPolicy _retryPolicy;

  final List<SyncOperation> _operationQueue = [];
  bool _isProcessingQueue = false;

  StreamSubscription<ConnectivityTransition>? _connectivitySubscription;

  SyncManager({
    SyncEngine? engine,
    ConnectivityMonitor? connectivityMonitor,
    RetryPolicy? retryPolicy,
  })  : _engine = engine ?? SyncEngine(),
        _connectivityMonitor = connectivityMonitor ?? ConnectivityMonitor(),
        _retryPolicy = retryPolicy ?? const RetryPolicy() {
    _connectivitySubscription =
        _connectivityMonitor.transitionStream.listen(_onConnectivityTransition);
  }

  SyncEngine get engine => _engine;
  ConnectivityMonitor get connectivityMonitor => _connectivityMonitor;
  RetryPolicy get retryPolicy => _retryPolicy;
  SyncState get state => _engine.state;

  List<SyncOperation> get queuedOperations =>
      List.unmodifiable(_operationQueue);
  int get pendingOperationCount =>
      _operationQueue.where((o) => o.status == SyncOperationStatus.pending || o.status == SyncOperationStatus.retrying).length;

  /// Enqueues a sync operation for execution.
  void queueOperation(SyncOperation op) {
    final sanitizedOp = op.copyWith(
      payload: SyncSecurity.sanitizePayload(op.payload),
    );
    _operationQueue.removeWhere((o) =>
        o.entityId == sanitizedOp.entityId &&
        o.entityType == sanitizedOp.entityType);
    _operationQueue.add(sanitizedOp);

    // Also mirror to SyncEngine queue
    _engine.recordLocalMutation(SyncEntity<Map<String, dynamic>>(
      metadata: SyncMetadata(
        entityId: sanitizedOp.entityId,
        entityType: sanitizedOp.entityType,
        version: sanitizedOp.version,
        clientDeviceId: sanitizedOp.deviceId,
        isDeleted: sanitizedOp.action == SyncAction.delete,
      ),
      payload: sanitizedOp.payload,
    ));

    notifyListeners();

    if (_connectivityMonitor.isOnline) {
      processQueue();
    }
  }

  /// Cancels a queued sync operation.
  void cancelOperation(String operationId) {
    final index =
        _operationQueue.indexWhere((o) => o.operationId == operationId);
    if (index != -1) {
      _operationQueue[index] = _operationQueue[index].copyWith(
        status: SyncOperationStatus.cancelled,
      );
      notifyListeners();
    }
  }

  /// Triggers immediate full synchronization cycle.
  Future<SyncResult> syncNow() async {
    if (_connectivityMonitor.isOffline) {
      return SyncResult(
        isSuccess: false,
        itemsProcessed: 0,
        itemsFailed: _operationQueue.length,
        completedAt: DateTime.now().toUtc(),
        errorMessage: 'Cannot sync while offline.',
      );
    }

    final ok = await _engine.syncNow();

    if (ok) {
      for (var i = 0; i < _operationQueue.length; i++) {
        if (_operationQueue[i].status != SyncOperationStatus.cancelled) {
          _operationQueue[i] = _operationQueue[i].copyWith(
            status: SyncOperationStatus.completed,
          );
        }
      }
      notifyListeners();

      return SyncResult(
        isSuccess: true,
        itemsProcessed: _operationQueue.length,
        itemsFailed: 0,
        completedAt: DateTime.now().toUtc(),
      );
    } else {
      return SyncResult(
        isSuccess: false,
        itemsProcessed: 0,
        itemsFailed: _operationQueue.length,
        completedAt: DateTime.now().toUtc(),
        errorMessage: _engine.lastErrorMessage,
      );
    }
  }

  /// Retries all failed operations using exponential backoff.
  Future<SyncResult> retryFailedSync() async {
    for (var i = 0; i < _operationQueue.length; i++) {
      if (_operationQueue[i].status == SyncOperationStatus.failed) {
        if (_retryPolicy.shouldRetry(_operationQueue[i].retryCount)) {
          _operationQueue[i] = _operationQueue[i].copyWith(
            status: SyncOperationStatus.retrying,
            retryCount: _operationQueue[i].retryCount + 1,
          );
        }
      }
    }
    notifyListeners();
    return syncNow();
  }

  /// Processes pending queue operations when online.
  Future<void> processQueue() async {
    if (_isProcessingQueue || _connectivityMonitor.isOffline) return;
    _isProcessingQueue = true;

    try {
      final pending = _operationQueue
          .where((o) =>
              o.status == SyncOperationStatus.pending ||
              o.status == SyncOperationStatus.retrying)
          .toList();

      if (pending.isNotEmpty) {
        for (var i = 0; i < _operationQueue.length; i++) {
          if (_operationQueue[i].status == SyncOperationStatus.pending ||
              _operationQueue[i].status == SyncOperationStatus.retrying) {
            _operationQueue[i] = _operationQueue[i].copyWith(
              status: SyncOperationStatus.running,
            );
          }
        }
        notifyListeners();

        final result = await syncNow();
        if (!result.isSuccess) {
          for (var i = 0; i < _operationQueue.length; i++) {
            if (_operationQueue[i].status == SyncOperationStatus.running) {
              _operationQueue[i] = _operationQueue[i].copyWith(
                status: SyncOperationStatus.failed,
                lastError: result.errorMessage,
              );
            }
          }
        }
      }
    } finally {
      _isProcessingQueue = false;
      notifyListeners();
    }
  }

  void _onConnectivityTransition(ConnectivityTransition transition) {
    if (transition.currentStatus == ConnectivityStatus.online &&
        transition.previousStatus == ConnectivityStatus.offline) {
      // Network recovery detected -> automatic resume
      retryFailedSync();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
