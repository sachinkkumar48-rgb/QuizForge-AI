import 'sync_entity.dart';

/// Container object representing a complete or delta cloud synchronization snapshot.
class SyncSnapshot {
  final String snapshotId;
  final String clientDeviceId;
  final DateTime createdAt;
  final List<SyncEntity<Map<String, dynamic>>> bookmarks;
  final List<SyncEntity<Map<String, dynamic>>> notes;
  final List<SyncEntity<Map<String, dynamic>>> statistics;
  final List<SyncEntity<Map<String, dynamic>>> revisionSchedules;
  final List<SyncEntity<Map<String, dynamic>>> settings;

  SyncSnapshot({
    required this.snapshotId,
    required this.clientDeviceId,
    DateTime? createdAt,
    this.bookmarks = const [],
    this.notes = const [],
    this.statistics = const [],
    this.revisionSchedules = const [],
    this.settings = const [],
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  factory SyncSnapshot.fromJson(Map<String, dynamic> json) {
    List<SyncEntity<Map<String, dynamic>>> parseList(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return SyncEntity<Map<String, dynamic>>.fromJson(
          map,
          (p) => p,
        );
      }).toList();
    }

    return SyncSnapshot(
      snapshotId: json['snapshotId'] as String? ?? '',
      clientDeviceId: json['clientDeviceId'] as String? ?? 'unknown_device',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toUtc()
          : DateTime.now().toUtc(),
      bookmarks: parseList(json['bookmarks']),
      notes: parseList(json['notes']),
      statistics: parseList(json['statistics']),
      revisionSchedules: parseList(json['revisionSchedules']),
      settings: parseList(json['settings']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'snapshotId': snapshotId,
      'clientDeviceId': clientDeviceId,
      'createdAt': createdAt.toIso8601String(),
      'bookmarks': bookmarks.map((e) => e.toJson((p) => p)).toList(),
      'notes': notes.map((e) => e.toJson((p) => p)).toList(),
      'statistics': statistics.map((e) => e.toJson((p) => p)).toList(),
      'revisionSchedules':
          revisionSchedules.map((e) => e.toJson((p) => p)).toList(),
      'settings': settings.map((e) => e.toJson((p) => p)).toList(),
    };
  }

  bool get isEmpty =>
      bookmarks.isEmpty &&
      notes.isEmpty &&
      statistics.isEmpty &&
      revisionSchedules.isEmpty &&
      settings.isEmpty;

  int get totalEntityCount =>
      bookmarks.length +
      notes.length +
      statistics.length +
      revisionSchedules.length +
      settings.length;
}
