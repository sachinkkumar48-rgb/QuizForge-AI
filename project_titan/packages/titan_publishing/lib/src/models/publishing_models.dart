import 'package:titan_content_authoring/titan_content_authoring.dart';

/// Single historical revision snapshot of content.
class ContentVersionRecord {
  final String versionId;
  final String contentId;
  final String versionNumber;
  final String snapshotTitle;
  final String snapshotBody;
  final String changeLogSummary;
  final String authorId;
  final DateTime createdAt;

  const ContentVersionRecord({
    required this.versionId,
    required this.contentId,
    required this.versionNumber,
    required this.snapshotTitle,
    required this.snapshotBody,
    required this.changeLogSummary,
    required this.authorId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'versionId': versionId,
        'contentId': contentId,
        'versionNumber': versionNumber,
        'snapshotTitle': snapshotTitle,
        'snapshotBody': snapshotBody,
        'changeLogSummary': changeLogSummary,
        'authorId': authorId,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Publishing Workflow Audit Log entry.
class WorkflowAuditEntry {
  final String id;
  final String contentId;
  final PublicationStatus fromStatus;
  final PublicationStatus toStatus;
  final String actorId;
  final String actorRole;
  final String comments;
  final DateTime timestamp;

  const WorkflowAuditEntry({
    required this.id,
    required this.contentId,
    required this.fromStatus,
    required this.toStatus,
    required this.actorId,
    required this.actorRole,
    this.comments = '',
    required this.timestamp,
  });
}
