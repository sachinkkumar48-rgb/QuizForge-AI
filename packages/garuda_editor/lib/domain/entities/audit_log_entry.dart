library;

import 'package:meta/meta.dart';

/// Single audit trail log record for GARUDA Editorial Studio actions.
@immutable
class AuditLogEntry {
  final String id;
  final String editor;
  final DateTime timestamp;
  final String action;
  final String objectId;
  final String previousState;
  final String newState;
  final String comment;

  const AuditLogEntry({
    required this.id,
    required this.editor,
    required this.timestamp,
    required this.action,
    required this.objectId,
    this.previousState = '',
    this.newState = '',
    this.comment = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'editor': editor,
        'timestamp': timestamp.toIso8601String(),
        'action': action,
        'objectId': objectId,
        'previousState': previousState,
        'newState': newState,
        'comment': comment,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: json['id'] as String? ?? '',
        editor: json['editor'] as String? ?? 'System',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        action: json['action'] as String? ?? '',
        objectId: json['objectId'] as String? ?? '',
        previousState: json['previousState'] as String? ?? '',
        newState: json['newState'] as String? ?? '',
        comment: json['comment'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditLogEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
