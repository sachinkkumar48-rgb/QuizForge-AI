/// Institutional Notification Domain Entity (TITAN-KO-054.0 P54).
///
/// Production domain models representing academic communication, delivery states,
/// deterministic deduplication keys, priority levels, and recipient boundaries.
library;

import 'package:meta/meta.dart';

/// Supported academic and institutional notification categories.
enum NotificationType {
  /// Course registration, approval, activation, or status update.
  enrollment,

  /// Assessment published, scheduled, or deadline approaching.
  assessment,

  /// Learner attempt evaluated and score available.
  result,

  /// Institutional grade published or updated.
  grade,

  /// Grade dispute raised, reviewed, or resolved.
  gradeDispute,

  /// Class session scheduled, opened, or recorded.
  attendance,

  /// Academic monitoring early-warning or intervention alert.
  intervention,

  /// Course or degree completion eligibility achieved.
  completion,

  /// Official academic transcript generated or verified.
  transcript,

  /// Institutional certificate issued or tamper-evident seal verified.
  certificate,
}

/// Explicit lifecycle states for an institutional notification.
enum NotificationStatus {
  /// Delivered to recipient inbox; not yet viewed.
  unread,

  /// Viewed / marked as read by the recipient.
  read,

  /// Formally acknowledged by the recipient (for alerts requiring confirmation).
  acknowledged,

  /// Dismissed / archived by the recipient.
  dismissed,
}

/// Presentation and urgency priority for notification delivery.
enum NotificationPriority {
  /// Informational or low-urgency background updates.
  low,

  /// Standard operational notifications (default).
  normal,

  /// Important academic notices requiring prompt attention.
  high,

  /// Critical academic or administrative alerts (e.g. intervention alerts).
  urgent,
}

/// Immutable production notification model.
@immutable
class LmsNotification {
  /// Unique canonical notification identifier.
  final String notificationId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Target user identifier (learnerId, facultyId, or adminId).
  final String recipientId;

  /// Role of recipient ('learner', 'faculty', 'admin').
  final String recipientRole;

  /// Originating actor identifier where applicable (e.g. facultyId or 'system').
  final String? actorId;

  /// Institutional category of the notification.
  final NotificationType type;

  /// Concise notification title / subject.
  final String title;

  /// Detailed human-readable notification message body.
  final String message;

  /// Categorical type of the originating academic entity.
  final String sourceEntityType;

  /// Identifier of the originating academic entity.
  final String sourceEntityId;

  /// Deterministic deduplication key ensuring idempotent delivery.
  final String deduplicationKey;

  /// Urgency and sorting priority.
  final NotificationPriority priority;

  /// Current lifecycle state.
  final NotificationStatus status;

  /// UTC creation and dispatch timestamp.
  final DateTime createdAt;

  /// UTC timestamp when read by recipient.
  final DateTime? readAt;

  /// UTC timestamp when acknowledged by recipient.
  final DateTime? acknowledgedAt;

  /// UTC timestamp when dismissed by recipient.
  final DateTime? dismissedAt;

  /// Optional client navigation route or action destination.
  final String? actionRoute;

  /// Extensible metadata payload.
  final Map<String, dynamic> metadata;

  LmsNotification({
    required this.notificationId,
    this.tenantId = 'default_tenant',
    required this.recipientId,
    this.recipientRole = 'learner',
    this.actorId,
    required this.type,
    required this.title,
    required this.message,
    required this.sourceEntityType,
    required this.sourceEntityId,
    String? deduplicationKey,
    this.priority = NotificationPriority.normal,
    this.status = NotificationStatus.unread,
    DateTime? createdAt,
    this.readAt,
    this.acknowledgedAt,
    this.dismissedAt,
    this.actionRoute,
    Map<String, dynamic>? metadata,
  })  : deduplicationKey = deduplicationKey ??
            computeDeduplicationKey(
              tenantId: tenantId,
              recipientId: recipientId,
              type: type,
              sourceEntityType: sourceEntityType,
              sourceEntityId: sourceEntityId,
            ),
        createdAt = (createdAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (notificationId.trim().isEmpty) {
      throw ArgumentError('notificationId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (recipientId.trim().isEmpty) {
      throw ArgumentError('recipientId cannot be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title cannot be empty');
    }
    if (message.trim().isEmpty) {
      throw ArgumentError('message cannot be empty');
    }
    if (sourceEntityType.trim().isEmpty) {
      throw ArgumentError('sourceEntityType cannot be empty');
    }
    if (sourceEntityId.trim().isEmpty) {
      throw ArgumentError('sourceEntityId cannot be empty');
    }
  }

  bool get isUnread => status == NotificationStatus.unread;
  bool get isRead => status == NotificationStatus.read;
  bool get isAcknowledged => status == NotificationStatus.acknowledged;
  bool get isDismissed => status == NotificationStatus.dismissed;

  /// Computes deterministic deduplication key across tenants and source events.
  static String computeDeduplicationKey({
    required String tenantId,
    required String recipientId,
    required NotificationType type,
    required String sourceEntityType,
    required String sourceEntityId,
  }) {
    return '${tenantId.trim()}_${recipientId.trim()}_${type.name}_${sourceEntityType.trim()}_${sourceEntityId.trim()}';
  }

  /// Canonical ID generator from parameters.
  static String generateId({
    required String recipientId,
    required NotificationType type,
    required String sourceEntityId,
  }) {
    final now = DateTime.now().toUtc();
    return 'notif_${type.name}_${recipientId.trim()}_${sourceEntityId.trim()}_${now.millisecondsSinceEpoch}';
  }

  /// Transitions notification to READ.
  ///
  /// Valid transitions: UNREAD -> READ.
  /// If already READ or ACKNOWLEDGED, returns idempotent copy.
  LmsNotification markRead({DateTime? at}) {
    if (status == NotificationStatus.dismissed) {
      throw StateError('Cannot mark a dismissed notification as read.');
    }
    if (status == NotificationStatus.read ||
        status == NotificationStatus.acknowledged) {
      return this; // Idempotent
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: NotificationStatus.read,
      readAt: now,
    );
  }

  /// Transitions notification to ACKNOWLEDGED.
  ///
  /// Valid transitions: UNREAD -> ACKNOWLEDGED or READ -> ACKNOWLEDGED.
  LmsNotification acknowledge({DateTime? at}) {
    if (status == NotificationStatus.dismissed) {
      throw StateError('Cannot acknowledge a dismissed notification.');
    }
    if (status == NotificationStatus.acknowledged) {
      return this; // Idempotent
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: NotificationStatus.acknowledged,
      readAt: readAt ?? now,
      acknowledgedAt: now,
    );
  }

  /// Transitions notification to DISMISSED.
  ///
  /// Allowed from UNREAD, READ, or ACKNOWLEDGED.
  LmsNotification dismiss({DateTime? at}) {
    if (status == NotificationStatus.dismissed) {
      return this; // Idempotent
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: NotificationStatus.dismissed,
      dismissedAt: now,
    );
  }

  LmsNotification copyWith({
    String? notificationId,
    String? tenantId,
    String? recipientId,
    String? recipientRole,
    String? actorId,
    NotificationType? type,
    String? title,
    String? message,
    String? sourceEntityType,
    String? sourceEntityId,
    String? deduplicationKey,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? acknowledgedAt,
    DateTime? dismissedAt,
    String? actionRoute,
    Map<String, dynamic>? metadata,
  }) {
    return LmsNotification(
      notificationId: notificationId ?? this.notificationId,
      tenantId: tenantId ?? this.tenantId,
      recipientId: recipientId ?? this.recipientId,
      recipientRole: recipientRole ?? this.recipientRole,
      actorId: actorId ?? this.actorId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      sourceEntityType: sourceEntityType ?? this.sourceEntityType,
      sourceEntityId: sourceEntityId ?? this.sourceEntityId,
      deduplicationKey: deduplicationKey ?? this.deduplicationKey,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      actionRoute: actionRoute ?? this.actionRoute,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'tenantId': tenantId,
        'recipientId': recipientId,
        'recipientRole': recipientRole,
        if (actorId != null) 'actorId': actorId,
        'type': type.name,
        'title': title,
        'message': message,
        'sourceEntityType': sourceEntityType,
        'sourceEntityId': sourceEntityId,
        'deduplicationKey': deduplicationKey,
        'priority': priority.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        if (readAt != null) 'readAt': readAt!.toIso8601String(),
        if (acknowledgedAt != null)
          'acknowledgedAt': acknowledgedAt!.toIso8601String(),
        if (dismissedAt != null) 'dismissedAt': dismissedAt!.toIso8601String(),
        if (actionRoute != null) 'actionRoute': actionRoute,
        'metadata': metadata,
      };

  factory LmsNotification.fromJson(Map<String, dynamic> json) {
    return LmsNotification(
      notificationId: json['notificationId'] as String,
      tenantId: json['tenantId'] as String? ?? 'default_tenant',
      recipientId: json['recipientId'] as String,
      recipientRole: json['recipientRole'] as String? ?? 'learner',
      actorId: json['actorId'] as String?,
      type: NotificationType.values.byName(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      sourceEntityType: json['sourceEntityType'] as String,
      sourceEntityId: json['sourceEntityId'] as String,
      deduplicationKey: json['deduplicationKey'] as String?,
      priority: json['priority'] != null
          ? NotificationPriority.values.byName(json['priority'] as String)
          : NotificationPriority.normal,
      status: json['status'] != null
          ? NotificationStatus.values.byName(json['status'] as String)
          : NotificationStatus.unread,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
      dismissedAt: json['dismissedAt'] != null
          ? DateTime.parse(json['dismissedAt'] as String)
          : null,
      actionRoute: json['actionRoute'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
