library;

enum AuditActionType {
  statusChange,
  reviewSubmitted,
  evidenceAdded,
  knowledgeLinkAdded,
  published,
  unpublished,
  republished,
  archived,
  restored,
  rollback,
}

class DetailedAuditLogEntry {
  final String id;
  final String objectId;
  final String actorId;
  final String actorName;
  final AuditActionType actionType;
  final String summary;
  final String? comments;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const DetailedAuditLogEntry({
    required this.id,
    required this.objectId,
    required this.actorId,
    required this.actorName,
    required this.actionType,
    required this.summary,
    this.comments,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'objectId': objectId,
        'actorId': actorId,
        'actorName': actorName,
        'actionType': actionType.name,
        'summary': summary,
        'comments': comments,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory DetailedAuditLogEntry.fromJson(Map<String, dynamic> json) => DetailedAuditLogEntry(
        id: json['id'] as String,
        objectId: json['objectId'] as String,
        actorId: json['actorId'] as String,
        actorName: json['actorName'] as String,
        actionType: AuditActionType.values.firstWhere(
          (a) => a.name == json['actionType'],
          orElse: () => AuditActionType.statusChange,
        ),
        summary: json['summary'] as String,
        comments: json['comments'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      );
}

class EditorialAuditTrail {
  final Map<String, List<DetailedAuditLogEntry>> _logsByObject = {};

  void record({
    required String objectId,
    required String actorId,
    required String actorName,
    required AuditActionType actionType,
    required String summary,
    String? comments,
    Map<String, dynamic> metadata = const {},
  }) {
    final entry = DetailedAuditLogEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      objectId: objectId,
      actorId: actorId,
      actorName: actorName,
      actionType: actionType,
      summary: summary,
      comments: comments,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _logsByObject.putIfAbsent(objectId, () => []).add(entry);
  }

  List<DetailedAuditLogEntry> getAuditTrail(String objectId) {
    return List.unmodifiable(_logsByObject[objectId] ?? []);
  }
}
