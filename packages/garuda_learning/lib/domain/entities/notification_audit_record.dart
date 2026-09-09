/// Institutional Communication & Notification Audit Record Domain Entity (TITAN-KO-054.0 P54).
///
/// Immutable audit trail capturing notification creation, delivery, read tracking,
/// formal acknowledgement, and dismissal actions.
library;

import 'package:meta/meta.dart';

/// Supported notification lifecycle audit events.
enum NotificationAuditAction {
  notificationCreated,
  notificationRead,
  notificationAllRead,
  notificationAcknowledged,
  notificationDismissed,
}

/// Immutable record capturing an institutional notification audit event.
@immutable
class NotificationAuditRecord {
  /// Unique audit record identifier.
  final String auditId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Lifecycle action performed.
  final NotificationAuditAction action;

  /// Target notification identifier where applicable.
  final String? notificationId;

  /// Target recipient identifier.
  final String recipientId;

  /// Identifier of the actor executing the action (learnerId, facultyId, system).
  final String actorId;

  /// Associated source event/entity type where applicable.
  final String? sourceEventType;

  /// Associated source entity identifier where applicable.
  final String? sourceEntityId;

  /// Additional diagnostic details, reason, or batch count notes.
  final String? details;

  /// UTC occurrence timestamp.
  final DateTime timestamp;

  NotificationAuditRecord({
    required this.auditId,
    this.tenantId = 'default_tenant',
    required this.action,
    this.notificationId,
    required this.recipientId,
    required this.actorId,
    this.sourceEventType,
    this.sourceEntityId,
    this.details,
    DateTime? timestamp,
  }) : timestamp = (timestamp ?? DateTime.now()).toUtc() {
    if (auditId.trim().isEmpty) {
      throw ArgumentError('auditId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (recipientId.trim().isEmpty) {
      throw ArgumentError('recipientId cannot be empty');
    }
    if (actorId.trim().isEmpty) {
      throw ArgumentError('actorId cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'auditId': auditId,
        'tenantId': tenantId,
        'action': action.name,
        if (notificationId != null) 'notificationId': notificationId,
        'recipientId': recipientId,
        'actorId': actorId,
        if (sourceEventType != null) 'sourceEventType': sourceEventType,
        if (sourceEntityId != null) 'sourceEntityId': sourceEntityId,
        if (details != null) 'details': details,
        'timestamp': timestamp.toIso8601String(),
      };

  factory NotificationAuditRecord.fromJson(Map<String, dynamic> json) {
    return NotificationAuditRecord(
      auditId: json['auditId'] as String,
      tenantId: json['tenantId'] as String? ?? 'default_tenant',
      action: NotificationAuditAction.values.byName(json['action'] as String),
      notificationId: json['notificationId'] as String?,
      recipientId: json['recipientId'] as String,
      actorId: json['actorId'] as String,
      sourceEventType: json['sourceEventType'] as String?,
      sourceEntityId: json['sourceEntityId'] as String?,
      details: json['details'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}
