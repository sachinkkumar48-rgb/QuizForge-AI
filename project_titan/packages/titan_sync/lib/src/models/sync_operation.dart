import 'package:meta/meta.dart';

import 'sync_entity_type.dart';

/// Immutable model representing an individual delta mutation / sync operation in TITAN.
@immutable
class SyncOperation {
  final String operationId;
  final SyncEntityType entityType;
  final String entityId;
  final SyncAction action;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int version;
  final String deviceId;

  const SyncOperation({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.timestamp,
    required this.version,
    required this.deviceId,
  });

  SyncOperation copyWith({
    String? operationId,
    SyncEntityType? entityType,
    String? entityId,
    SyncAction? action,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    int? version,
    String? deviceId,
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
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
        operationId: json['operationId'] as String,
        entityType: SyncEntityType.values.firstWhere(
          (e) => e.name == json['entityType'],
          orElse: () => SyncEntityType.notes,
        ),
        entityId: json['entityId'] as String,
        action: SyncAction.values.firstWhere(
          (e) => e.name == json['action'],
          orElse: () => SyncAction.update,
        ),
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
        timestamp: DateTime.parse(json['timestamp'] as String),
        version: json['version'] as int? ?? 1,
        deviceId: json['deviceId'] as String? ?? 'unknown_device',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperation &&
          runtimeType == other.runtimeType &&
          operationId == other.operationId &&
          entityId == other.entityId &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(operationId, entityId, timestamp);
}
