/// Institutional Notification Repository Interface & Typed Exceptions (TITAN-KO-054.0 P54).
///
/// Abstract repository contract specifying persistence, query filtering,
/// deduplication indexing, unread counting, and snapshot export/import operations.
library;

import '../domain/entities/lms_notification.dart';
import '../domain/entities/notification_audit_record.dart';

/// Base exception for all notification domain and storage failures.
class NotificationException implements Exception {
  final String message;
  final dynamic cause;

  const NotificationException(this.message, [this.cause]);

  @override
  String toString() =>
      'NotificationException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Thrown when a requested notification cannot be located.
class NotificationNotFoundException extends NotificationException {
  const NotificationNotFoundException(super.message, [super.cause]);
}

/// Thrown when notification validation or invariant checks fail.
class NotificationValidationException extends NotificationException {
  const NotificationValidationException(super.message, [super.cause]);
}

/// Thrown when cross-user access or unauthorized operations are attempted.
class NotificationSecurityException extends NotificationException {
  const NotificationSecurityException(super.message, [super.cause]);
}

/// Thrown when duplicate notifications violate uniqueness rules unexpectedly.
class DuplicateNotificationException extends NotificationException {
  const DuplicateNotificationException(super.message, [super.cause]);
}

/// Abstract contract for institutional notification storage.
abstract class NotificationRepository {
  /// Persists or updates a notification record.
  Future<void> saveNotification(LmsNotification notification);

  /// Retrieves a notification by unique identifier with optional tenant scoping.
  Future<LmsNotification?> getNotification(String notificationId,
      {String? tenantId});

  /// Retrieves a notification by its deterministic deduplication key.
  Future<LmsNotification?> getNotificationByDedupKey(String deduplicationKey,
      {String? tenantId});

  /// Lists notifications for a given recipient with optional filtering and pagination.
  Future<List<LmsNotification>> listNotifications({
    required String recipientId,
    String? tenantId,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
    int? limit,
  });

  /// Counts unread notifications for a recipient.
  Future<int> countUnread({
    required String recipientId,
    String? tenantId,
  });

  /// Persists an immutable notification audit record.
  Future<void> saveAuditRecord(NotificationAuditRecord record);

  /// Lists audit records matching filter criteria.
  Future<List<NotificationAuditRecord>> listAuditRecords({
    String? tenantId,
    String? recipientId,
    String? notificationId,
  });

  /// Exports full repository state for offline persistence and restart recovery.
  Future<Map<String, dynamic>> exportSnapshot();

  /// Restores repository state from a serialized snapshot.
  Future<void> importSnapshot(Map<String, dynamic> snapshot);
}
