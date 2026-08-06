library;

enum NotificationEventType {
  newAssignment,
  reviewCompleted,
  approvalRequired,
  publicationCompleted,
  rollback,
  rejectedObject,
}

class EditorialNotificationEvent {
  final String id;
  final NotificationEventType type;
  final String objectId;
  final String recipientId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const EditorialNotificationEvent({
    required this.id,
    required this.type,
    required this.objectId,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  EditorialNotificationEvent copyWith({bool? isRead}) {
    return EditorialNotificationEvent(
      id: id,
      type: type,
      objectId: objectId,
      recipientId: recipientId,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class EditorialNotificationService {
  final List<EditorialNotificationEvent> _events = [];

  EditorialNotificationEvent notify({
    required NotificationEventType type,
    required String objectId,
    required String recipientId,
    required String title,
    required String message,
  }) {
    final event = EditorialNotificationEvent(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${_events.length}',
      type: type,
      objectId: objectId,
      recipientId: recipientId,
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );

    _events.add(event);
    return event;
  }

  List<EditorialNotificationEvent> getNotificationsForUser(String recipientId) {
    return _events.where((e) => e.recipientId == recipientId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void markAsRead(String notificationId) {
    final index = _events.indexWhere((e) => e.id == notificationId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(isRead: true);
    }
  }

  List<EditorialNotificationEvent> get allEvents => List.unmodifiable(_events);
}
