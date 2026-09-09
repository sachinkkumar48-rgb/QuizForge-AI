/// In-Memory Notification Repository Implementation (TITAN-KO-054.0 P54).
///
/// Thread-safe in-memory store supporting secondary deduplication indexing,
/// multi-tenant filtering, simulated failure handling, and snapshot persistence.
library;

import '../domain/entities/lms_notification.dart';
import '../domain/entities/notification_audit_record.dart';
import 'notification_repository.dart';

/// In-memory implementation of [NotificationRepository].
class InMemoryNotificationRepository implements NotificationRepository {
  final Map<String, LmsNotification> _notifications = {};
  final Map<String, String> _dedupIndex = {};
  final List<NotificationAuditRecord> _auditRecords = [];

  bool _simulateFailure = false;

  /// Sets failure simulation flag for error-handling and offline verification.
  void setSimulateFailure(bool simulate) {
    _simulateFailure = simulate;
  }

  void _checkFailure() {
    if (_simulateFailure) {
      throw const NotificationException(
          'Simulated notification repository failure.');
    }
  }

  @override
  Future<void> saveNotification(LmsNotification notification) async {
    _checkFailure();
    _notifications[notification.notificationId] = notification;
    _dedupIndex[notification.deduplicationKey] = notification.notificationId;
  }

  @override
  Future<LmsNotification?> getNotification(String notificationId,
      {String? tenantId}) async {
    _checkFailure();
    final notif = _notifications[notificationId.trim()];
    if (notif == null) return null;
    if (tenantId != null && notif.tenantId != tenantId) return null;
    return notif;
  }

  @override
  Future<LmsNotification?> getNotificationByDedupKey(String deduplicationKey,
      {String? tenantId}) async {
    _checkFailure();
    final id = _dedupIndex[deduplicationKey.trim()];
    if (id == null) return null;
    final notif = _notifications[id];
    if (notif == null) return null;
    if (tenantId != null && notif.tenantId != tenantId) return null;
    return notif;
  }

  @override
  Future<List<LmsNotification>> listNotifications({
    required String recipientId,
    String? tenantId,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
    int? limit,
  }) async {
    _checkFailure();
    final cleanRecipient = recipientId.trim();

    var results = _notifications.values.where((n) {
      if (n.recipientId != cleanRecipient) return false;
      if (tenantId != null && n.tenantId != tenantId) return false;
      if (type != null && n.type != type) return false;
      if (status != null && n.status != status) return false;
      if (priority != null && n.priority != priority) return false;
      return true;
    }).toList();

    // Sort newest first
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (limit != null && limit > 0 && results.length > limit) {
      results = results.sublist(0, limit);
    }

    return results;
  }

  @override
  Future<int> countUnread({
    required String recipientId,
    String? tenantId,
  }) async {
    _checkFailure();
    final cleanRecipient = recipientId.trim();

    return _notifications.values.where((n) {
      if (n.recipientId != cleanRecipient) return false;
      if (tenantId != null && n.tenantId != tenantId) return false;
      return n.isUnread;
    }).length;
  }

  @override
  Future<void> saveAuditRecord(NotificationAuditRecord record) async {
    _checkFailure();
    _auditRecords.add(record);
  }

  @override
  Future<List<NotificationAuditRecord>> listAuditRecords({
    String? tenantId,
    String? recipientId,
    String? notificationId,
  }) async {
    _checkFailure();
    return _auditRecords.where((a) {
      if (tenantId != null && a.tenantId != tenantId) return false;
      if (recipientId != null && a.recipientId != recipientId) return false;
      if (notificationId != null && a.notificationId != notificationId)
        return false;
      return true;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> exportSnapshot() async {
    _checkFailure();
    return {
      'notifications': _notifications.values.map((n) => n.toJson()).toList(),
      'auditRecords': _auditRecords.map((a) => a.toJson()).toList(),
    };
  }

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    _checkFailure();
    _notifications.clear();
    _dedupIndex.clear();
    _auditRecords.clear();

    final rawNotifs = snapshot['notifications'] as List<dynamic>? ?? [];
    for (final raw in rawNotifs) {
      if (raw is Map<String, dynamic>) {
        final notif = LmsNotification.fromJson(raw);
        _notifications[notif.notificationId] = notif;
        _dedupIndex[notif.deduplicationKey] = notif.notificationId;
      }
    }

    final rawAudits = snapshot['auditRecords'] as List<dynamic>? ?? [];
    for (final raw in rawAudits) {
      if (raw is Map<String, dynamic>) {
        _auditRecords.add(NotificationAuditRecord.fromJson(raw));
      }
    }
  }
}
