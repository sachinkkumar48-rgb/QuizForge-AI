import '../models/learning_content_models.dart';

/// Pure Dart domain engine tracking, recording, and summarizing learning activities
/// performed on educational content items without UI dependencies.
class LearningActivityEngine {
  final Map<String, List<LearningActivity>> _userActivityLog =
      {}; // Key: '${userId}_${contentId}'

  /// Records a new learning activity event and returns updated aggregate record.
  LearningActivityRecord recordActivity({
    required String userId,
    required String contentId,
    required LearningActivityType activityType,
    int durationSeconds = 0,
    Map<String, dynamic>? metadata,
  }) {
    final key = '${userId}_$contentId';
    final history = _userActivityLog.putIfAbsent(key, () => []);

    final newActivity = LearningActivity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}_${history.length + 1}',
      userId: userId,
      contentId: contentId,
      activityType: activityType,
      timestamp: DateTime.now(),
      durationSeconds: durationSeconds,
      metadata: metadata,
    );

    history.add(newActivity);
    return getActivityRecord(userId: userId, contentId: contentId);
  }

  /// Convenience helpers for specific activity types
  LearningActivityRecord recordStarted(
      {required String userId, required String contentId}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.started);
  }

  LearningActivityRecord recordViewed(
      {required String userId,
      required String contentId,
      int durationSeconds = 0}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.viewed,
        durationSeconds: durationSeconds);
  }

  LearningActivityRecord recordPlayed(
      {required String userId,
      required String contentId,
      int durationSeconds = 0}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.played,
        durationSeconds: durationSeconds);
  }

  LearningActivityRecord recordRead(
      {required String userId,
      required String contentId,
      int durationSeconds = 0}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.read,
        durationSeconds: durationSeconds);
  }

  LearningActivityRecord recordPaused(
      {required String userId,
      required String contentId,
      int durationSeconds = 0}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.paused,
        durationSeconds: durationSeconds);
  }

  LearningActivityRecord recordResumed(
      {required String userId, required String contentId}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.resumed);
  }

  LearningActivityRecord recordAttempted(
      {required String userId,
      required String contentId,
      Map<String, dynamic>? metadata}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.attempted,
        metadata: metadata);
  }

  LearningActivityRecord recordCompleted(
      {required String userId,
      required String contentId,
      int durationSeconds = 0}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.completed,
        durationSeconds: durationSeconds);
  }

  LearningActivityRecord recordRevised(
      {required String userId,
      required String contentId,
      int durationSeconds = 0}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.revised,
        durationSeconds: durationSeconds);
  }

  LearningActivityRecord recordDownloaded(
      {required String userId, required String contentId}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.downloaded);
  }

  LearningActivityRecord recordShared(
      {required String userId, required String contentId}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.shared);
  }

  LearningActivityRecord recordAskedAI(
      {required String userId,
      required String contentId,
      required String query}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.askedAI,
        metadata: {'query': query});
  }

  LearningActivityRecord recordDiscussed(
      {required String userId,
      required String contentId,
      required String topic}) {
    return recordActivity(
        userId: userId,
        contentId: contentId,
        activityType: LearningActivityType.discussed,
        metadata: {'topic': topic});
  }

  /// Calculates and returns an immutable [LearningActivityRecord] aggregate summary.
  LearningActivityRecord getActivityRecord({
    required String userId,
    required String contentId,
  }) {
    final key = '${userId}_$contentId';
    final history = _userActivityLog[key] ?? const [];

    if (history.isEmpty) {
      return LearningActivityRecord(
        userId: userId,
        contentId: contentId,
        activities: const [],
        totalDurationSeconds: 0,
        activityCount: 0,
        lastActivityAt: DateTime.now(),
        activityBreakdown: const {},
      );
    }

    int totalDuration = 0;
    final Map<String, int> breakdown = {};

    for (final act in history) {
      totalDuration += act.durationSeconds;
      final typeStr = act.activityType.name;
      breakdown[typeStr] = (breakdown[typeStr] ?? 0) + 1;
    }

    return LearningActivityRecord(
      userId: userId,
      contentId: contentId,
      activities: List<LearningActivity>.from(history),
      totalDurationSeconds: totalDuration,
      activityCount: history.length,
      lastActivityAt: history.last.timestamp,
      activityBreakdown: breakdown,
    );
  }
}
