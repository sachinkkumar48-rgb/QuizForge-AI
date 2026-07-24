import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Supported sync entity types in QuizForge AI.
enum SyncEntityType {
  bookmark,
  note,
  statistics,
  revisionSchedule,
  settings,
}

/// Change tracking metadata attached to all syncable entity envelopes.
class SyncMetadata {
  final String entityId;
  final SyncEntityType entityType;
  final int version;
  final DateTime updatedAt;
  final String clientDeviceId;
  final bool isDeleted;
  final String checksum;

  SyncMetadata({
    required this.entityId,
    required this.entityType,
    required this.version,
    DateTime? updatedAt,
    required this.clientDeviceId,
    this.isDeleted = false,
    this.checksum = '',
  }) : updatedAt = updatedAt ?? DateTime.now().toUtc();

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      entityId: json['entityId'] as String? ?? '',
      entityType: SyncEntityType.values.byName(
        json['entityType'] as String? ?? 'bookmark',
      ),
      version: json['version'] as int? ?? 1,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toUtc()
          : DateTime.now().toUtc(),
      clientDeviceId: json['clientDeviceId'] as String? ?? 'unknown_device',
      isDeleted: json['isDeleted'] as bool? ?? false,
      checksum: json['checksum'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entityType': entityType.name,
      'version': version,
      'updatedAt': updatedAt.toIso8601String(),
      'clientDeviceId': clientDeviceId,
      'isDeleted': isDeleted,
      'checksum': checksum,
    };
  }

  SyncMetadata copyWith({
    String? entityId,
    SyncEntityType? entityType,
    int? version,
    DateTime? updatedAt,
    String? clientDeviceId,
    bool? isDeleted,
    String? checksum,
  }) {
    return SyncMetadata(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      clientDeviceId: clientDeviceId ?? this.clientDeviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      checksum: checksum ?? this.checksum,
    );
  }

  /// Utility to compute SHA-256 checksum string for a payload JSON map.
  static String computeChecksum(Map<String, dynamic> payloadJson) {
    final str = jsonEncode(payloadJson);
    return sha256.convert(utf8.encode(str)).toString();
  }
}
