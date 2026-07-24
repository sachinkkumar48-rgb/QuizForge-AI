import 'package:meta/meta.dart';

import 'sync_item.dart';

/// Immutable domain model representing a batched payload of SyncItems for network transmission.
@immutable
class SyncBatch {
  final String batchId;
  final String userId;
  final List<SyncItem> items;
  final DateTime createdAt;
  final bool isCompressed;
  final String? checksum;

  SyncBatch({
    required this.batchId,
    required this.userId,
    required List<SyncItem> items,
    required this.createdAt,
    this.isCompressed = false,
    this.checksum,
  }) : items = List<SyncItem>.unmodifiable(items);

  SyncBatch copyWith({
    String? batchId,
    String? userId,
    List<SyncItem>? items,
    DateTime? createdAt,
    bool? isCompressed,
    String? checksum,
  }) {
    return SyncBatch(
      batchId: batchId ?? this.batchId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      isCompressed: isCompressed ?? this.isCompressed,
      checksum: checksum ?? this.checksum,
    );
  }

  Map<String, dynamic> toJson() => {
        'batchId': batchId,
        'userId': userId,
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isCompressed': isCompressed,
        'checksum': checksum,
      };

  factory SyncBatch.fromJson(Map<String, dynamic> json) => SyncBatch(
        batchId: json['batchId'] as String,
        userId: json['userId'] as String,
        items: (json['items'] as List? ?? [])
            .map((e) => SyncItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isCompressed: json['isCompressed'] as bool? ?? false,
        checksum: json['checksum'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncBatch &&
          runtimeType == other.runtimeType &&
          batchId == other.batchId &&
          userId == other.userId &&
          createdAt == other.createdAt &&
          isCompressed == other.isCompressed &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(
        batchId,
        userId,
        createdAt,
        isCompressed,
        checksum,
      );
}
