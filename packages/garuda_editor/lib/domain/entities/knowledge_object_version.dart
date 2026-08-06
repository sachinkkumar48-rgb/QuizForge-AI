library;

import 'package:meta/meta.dart';
import 'knowledge_object.dart';

/// Immutable snapshot version of a Knowledge Object.
@immutable
class KnowledgeObjectVersion {
  final String id;
  final String objectId;
  final int versionNumber;
  final String editor;
  final String createdById;
  final String createdByName;
  final DateTime timestamp;
  final DateTime createdAt;
  final String changeSummary;
  final Map<String, dynamic> snapshot;

  KnowledgeObjectVersion({
    String? id,
    String? objectId,
    required this.versionNumber,
    String? editor,
    String? createdById,
    String? createdByName,
    DateTime? timestamp,
    DateTime? createdAt,
    this.changeSummary = '',
    required dynamic snapshot,
  })  : id = id ?? 'ver_$versionNumber',
        objectId = objectId ?? (snapshot is KnowledgeObject ? snapshot.id : (snapshot is Map ? snapshot['id'] as String? ?? '' : '')),
        editor = editor ?? createdByName ?? 'System',
        createdById = createdById ?? editor ?? 'System',
        createdByName = createdByName ?? editor ?? 'System',
        timestamp = timestamp ?? createdAt ?? DateTime.now(),
        createdAt = createdAt ?? timestamp ?? DateTime.now(),
        snapshot = snapshot is KnowledgeObject ? snapshot.toJson() : Map<String, dynamic>.from(snapshot as Map);

  KnowledgeObject get snapshotObject => KnowledgeObject.fromJson(snapshot);

  Map<String, dynamic> toJson() => {
        'id': id,
        'objectId': objectId,
        'versionNumber': versionNumber,
        'editor': editor,
        'createdById': createdById,
        'createdByName': createdByName,
        'timestamp': timestamp.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'changeSummary': changeSummary,
        'snapshot': snapshot,
      };

  factory KnowledgeObjectVersion.fromJson(Map<String, dynamic> json) =>
      KnowledgeObjectVersion(
        id: json['id'] as String? ?? '',
        objectId: json['objectId'] as String? ?? '',
        versionNumber: (json['versionNumber'] as num?)?.toInt() ?? 1,
        editor: json['editor'] as String? ?? 'System',
        createdById: json['createdById'] as String? ?? 'System',
        createdByName: json['createdByName'] as String? ?? 'System',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        changeSummary: json['changeSummary'] as String? ?? '',
        snapshot: Map<String, dynamic>.from(json['snapshot'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnowledgeObjectVersion &&
        other.versionNumber == versionNumber &&
        other.editor == editor &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(versionNumber, editor, timestamp);
}
