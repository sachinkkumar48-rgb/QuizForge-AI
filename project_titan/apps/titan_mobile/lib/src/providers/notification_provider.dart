import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationCategory {
  planner,
  liveClass,
  aiTutor,
  assessment,
  revision,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier()
      : super([
          AppNotification(
            id: 'n1',
            title: 'Planner Reminder',
            body: 'Daily Study Plan for Polity is ready!',
            category: NotificationCategory.planner,
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          AppNotification(
            id: 'n2',
            title: 'Live Class Starting Soon',
            body: 'UPSC Mains Answer Writing Session starts in 15 mins.',
            category: NotificationCategory.liveClass,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          AppNotification(
            id: 'n3',
            title: 'AI Tutor Recommendation',
            body: 'Review Fundamental Rights misconception analysis.',
            category: NotificationCategory.aiTutor,
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          AppNotification(
            id: 'n4',
            title: 'Revision Queue Overdue',
            body: '12 flashcards are due for spaced repetition.',
            category: NotificationCategory.revision,
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]);

  void markAsRead(String id) {
    state = state.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void clearAll() {
    state = const [];
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier();
});
