import 'package:meta/meta.dart';

import 'sync_entity_type.dart';

/// Immutable model representing a system state snapshot checkpoint for multi-device sync recovery.
@immutable
class SyncSnapshot {
  final String snapshotId;
  final String userId;
  final String deviceId;
  final DateTime createdAt;
  final Map<SyncEntityType, Map<String, dynamic>> entitySnapshots;
  final String checksum;

  const SyncSnapshot({
    required this.snapshotId,
    required this.userId,
    required this.deviceId,
    required this.createdAt,
    required this.entitySnapshots,
    required this.checksum,
  });

  int get totalEntityCount {
    int total = 0;
    for (final map in entitySnapshots.values) {
      total += map.length;
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
        'snapshotId': snapshotId,
        'userId': userId,
        'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
        'entitySnapshots': entitySnapshots.map(
          (k, v) => MapEntry(k.name, v),
        ),
        'checksum': checksum,
      };

  factory SyncSnapshot.fromJson(Map<String, dynamic> json) => SyncSnapshot(
        snapshotId: json['snapshotId'] as String,
        userId: json['userId'] as String,
        deviceId: json['deviceId'] as String? ?? 'unknown_device',
        createdAt: DateTime.parse(json['createdAt'] as String),
        entitySnapshots: (json['entitySnapshots'] as Map? ?? {}).map(
          (k, v) => MapEntry(
            SyncEntityType.values.firstWhere(
              (e) => e.name == k,
              orElse: () => SyncEntityType.notes,
            ),
            Map<String, dynamic>.from(v as Map),
          ),
        ),
        checksum: json['checksum'] as String? ?? '',
      );
}
