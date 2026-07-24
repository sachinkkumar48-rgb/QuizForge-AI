import 'package:meta/meta.dart';

import 'sync_item.dart';

/// Immutable domain model representing a data conflict between local and remote versions.
@immutable
class SyncConflict {
  final String conflictId;
  final SyncItem localItem;
  final SyncItem remoteItem;
  final DateTime detectedAt;
  final bool isResolved;
  final SyncItem? resolvedItem;

  const SyncConflict({
    required this.conflictId,
    required this.localItem,
    required this.remoteItem,
    required this.detectedAt,
    this.isResolved = false,
    this.resolvedItem,
  });

  SyncConflict copyWith({
    String? conflictId,
    SyncItem? localItem,
    SyncItem? remoteItem,
    DateTime? detectedAt,
    bool? isResolved,
    SyncItem? resolvedItem,
  }) {
    return SyncConflict(
      conflictId: conflictId ?? this.conflictId,
      localItem: localItem ?? this.localItem,
      remoteItem: remoteItem ?? this.remoteItem,
      detectedAt: detectedAt ?? this.detectedAt,
      isResolved: isResolved ?? this.isResolved,
      resolvedItem: resolvedItem ?? this.resolvedItem,
    );
  }

  Map<String, dynamic> toJson() => {
        'conflictId': conflictId,
        'localItem': localItem.toJson(),
        'remoteItem': remoteItem.toJson(),
        'detectedAt': detectedAt.toIso8601String(),
        'isResolved': isResolved,
        'resolvedItem': resolvedItem?.toJson(),
      };

  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
        conflictId: json['conflictId'] as String,
        localItem: SyncItem.fromJson(
            Map<String, dynamic>.from(json['localItem'] as Map)),
        remoteItem: SyncItem.fromJson(
            Map<String, dynamic>.from(json['remoteItem'] as Map)),
        detectedAt: DateTime.parse(json['detectedAt'] as String),
        isResolved: json['isResolved'] as bool? ?? false,
        resolvedItem: json['resolvedItem'] != null
            ? SyncItem.fromJson(
                Map<String, dynamic>.from(json['resolvedItem'] as Map))
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncConflict &&
          runtimeType == other.runtimeType &&
          conflictId == other.conflictId &&
          localItem == other.localItem &&
          remoteItem == other.remoteItem &&
          detectedAt == other.detectedAt &&
          isResolved == other.isResolved &&
          resolvedItem == other.resolvedItem;

  @override
  int get hashCode => Object.hash(
        conflictId,
        localItem,
        remoteItem,
        detectedAt,
        isResolved,
        resolvedItem,
      );
}
