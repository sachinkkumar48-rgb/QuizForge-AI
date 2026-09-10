import 'package:garuda_learning/garuda_learning.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';

/// HTTP and offline-first implementation of [NotificationRepository] (TITAN-KO P54 / P57).
/// Communicates with FastAPI backend `/api/v1/lms/notifications`.
class HttpNotificationRepository implements NotificationRepository {
  final ApiClient _apiClient;
  final InMemoryNotificationRepository _local;

  HttpNotificationRepository({
    ApiClient? apiClient,
    InMemoryNotificationRepository? localStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _local = localStore ?? InMemoryNotificationRepository();

  @override
  Future<void> saveNotification(LmsNotification notification) async {
    await _local.saveNotification(notification);
    try {
      await _apiClient.post('/api/v1/lms/notifications', body: notification.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveNotification failed, cached locally: $e', tag: 'HttpNotificationRepo');
    }
  }

  @override
  Future<LmsNotification?> getNotification(String notificationId, {String? tenantId}) async {
    try {
      final query = tenantId != null ? '?tenantId=${Uri.encodeComponent(tenantId)}' : '';
      final res = await _apiClient.get('/api/v1/lms/notifications/${Uri.encodeComponent(notificationId)}$query');
      if (res.isNotEmpty && (res['notification'] != null || res['notificationId'] != null)) {
        final nMap = (res['notification'] is Map)
            ? Map<String, dynamic>.from(res['notification'] as Map)
            : Map<String, dynamic>.from(res);
        final notification = LmsNotification.fromJson(nMap);
        await _local.saveNotification(notification);
        return notification;
      }
    } catch (e) {
      AppLogger.debug('Remote getNotification fallback to local: $e', tag: 'HttpNotificationRepo');
    }
    return _local.getNotification(notificationId, tenantId: tenantId);
  }

  @override
  Future<LmsNotification?> getNotificationByDedupKey(String deduplicationKey, {String? tenantId}) async {
    try {
      final query = tenantId != null ? '?tenantId=${Uri.encodeComponent(tenantId)}' : '';
      final res = await _apiClient.get('/api/v1/lms/notifications/by-dedup-key/${Uri.encodeComponent(deduplicationKey)}$query');
      if (res.isNotEmpty && (res['notification'] != null || res['notificationId'] != null)) {
        final nMap = (res['notification'] is Map)
            ? Map<String, dynamic>.from(res['notification'] as Map)
            : Map<String, dynamic>.from(res);
        final notification = LmsNotification.fromJson(nMap);
        await _local.saveNotification(notification);
        return notification;
      }
    } catch (e) {
      AppLogger.debug('Remote getNotificationByDedupKey fallback to local: $e', tag: 'HttpNotificationRepo');
    }
    return _local.getNotificationByDedupKey(deduplicationKey, tenantId: tenantId);
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
    try {
      final params = [
        'recipientId=${Uri.encodeComponent(recipientId)}',
        if (tenantId != null) 'tenantId=${Uri.encodeComponent(tenantId)}',
        if (type != null) 'type=${Uri.encodeComponent(type.name)}',
        if (status != null) 'status=${Uri.encodeComponent(status.name)}',
        if (priority != null) 'priority=${Uri.encodeComponent(priority.name)}',
        if (limit != null) 'limit=$limit',
      ];
      final res = await _apiClient.get('/api/v1/lms/notifications?${params.join('&')}');
      final dynamic listData = res['notifications'] ?? res['data'];
      if (listData is List) {
        final notifications = listData
            .map((n) => LmsNotification.fromJson(Map<String, dynamic>.from(n as Map)))
            .toList();
        for (final n in notifications) {
          await _local.saveNotification(n);
        }
        return notifications;
      }
    } catch (e) {
      AppLogger.debug('Remote listNotifications fallback to local: $e', tag: 'HttpNotificationRepo');
    }
    return _local.listNotifications(
      recipientId: recipientId,
      tenantId: tenantId,
      type: type,
      status: status,
      priority: priority,
      limit: limit,
    );
  }

  @override
  Future<int> countUnread({
    required String recipientId,
    String? tenantId,
  }) async {
    try {
      final params = [
        'recipientId=${Uri.encodeComponent(recipientId)}',
        if (tenantId != null) 'tenantId=${Uri.encodeComponent(tenantId)}',
      ];
      final res = await _apiClient.get('/api/v1/lms/notifications/unread-count?${params.join('&')}');
      if (res['unreadCount'] is num) {
        return (res['unreadCount'] as num).toInt();
      }
    } catch (e) {
      AppLogger.debug('Remote countUnread fallback to local: $e', tag: 'HttpNotificationRepo');
    }
    return _local.countUnread(recipientId: recipientId, tenantId: tenantId);
  }

  @override
  Future<void> saveAuditRecord(NotificationAuditRecord record) async {
    await _local.saveAuditRecord(record);
    try {
      await _apiClient.post('/api/v1/lms/notifications/audit', body: record.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveAuditRecord failed: $e', tag: 'HttpNotificationRepo');
    }
  }

  @override
  Future<List<NotificationAuditRecord>> listAuditRecords({
    String? tenantId,
    String? recipientId,
    String? notificationId,
  }) async {
    try {
      final params = <String>[];
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      if (recipientId != null) params.add('recipientId=${Uri.encodeComponent(recipientId)}');
      if (notificationId != null) params.add('notificationId=${Uri.encodeComponent(notificationId)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/notifications/audit$query');
      final dynamic listData = res['audits'] ?? res['data'];
      if (listData is List) {
        return listData
            .map((a) => NotificationAuditRecord.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
      }
    } catch (e) {
      AppLogger.debug('Remote listAuditRecords fallback to local: $e', tag: 'HttpNotificationRepo');
    }
    return _local.listAuditRecords(
      tenantId: tenantId,
      recipientId: recipientId,
      notificationId: notificationId,
    );
  }

  @override
  Future<Map<String, dynamic>> exportSnapshot() => _local.exportSnapshot();

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) => _local.importSnapshot(snapshot);
}
