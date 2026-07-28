import 'package:meta/meta.dart';

import 'sync_entity_type.dart';

export 'sync_entity_type.dart';

/// Immutable domain entity representing an offline-first item queued for cloud sync.
@immutable
class SyncItem {
  final String id;
  final String entityId;
  final SyncEntityType entityType;
  final SyncAction action;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int version;
  final SyncItemStatus status;
  final int retryCount;
  final String? lastError;

  /// Alias for [id].
  String get syncId => id;

  SyncItem({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.action,
    required Map<String, dynamic> payload,
    required this.timestamp,
    this.version = 1,
    this.status = SyncItemStatus.pending,
    this.retryCount = 0,
    this.lastError,
  }) : payload = Map<String, dynamic>.unmodifiable(payload);

  SyncItem copyWith({
    String? id,
    String? entityId,
    SyncEntityType? entityType,
    SyncAction? action,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    int? version,
    SyncItemStatus? status,
    int? retryCount,
    String? lastError,
  }) {
    return SyncItem(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      version: version ?? this.version,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityId': entityId,
        'entityType': entityType.name,
        'action': action.name,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
        'status': status.name,
        'retryCount': retryCount,
        'lastError': lastError,
      };

  factory SyncItem.fromJson(Map<String, dynamic> json) => SyncItem(
        id: json['id'] as String,
        entityId: json['entityId'] as String,
        entityType: SyncEntityType.values.firstWhere(
          (e) => e.name == json['entityType'],
          orElse: () => SyncEntityType.notes,
        ),
        action: SyncAction.values.firstWhere(
          (e) => e.name == json['action'],
          orElse: () => SyncAction.update,
        ),
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
        timestamp: DateTime.parse(json['timestamp'] as String),
        version: json['version'] as int? ?? 1,
        status: SyncItemStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SyncItemStatus.pending,
        ),
        retryCount: json['retryCount'] as int? ?? 0,
        lastError: json['lastError'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          entityId == other.entityId &&
          entityType == other.entityType &&
          action == other.action &&
          timestamp == other.timestamp &&
          version == other.version &&
          status == other.status &&
          retryCount == other.retryCount;

  @override
  int get hashCode => Object.hash(
        id,
        entityId,
        entityType,
        action,
        timestamp,
        version,
        status,
        retryCount,
      );
}
