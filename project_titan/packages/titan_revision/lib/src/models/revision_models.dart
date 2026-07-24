import 'package:meta/meta.dart';

/// Immutable domain model representing a single topic/question item in the adaptive revision queue.
@immutable
class RevisionItem {
  final String id;
  final String topic;
  final String? subtopic;
  final String? questionId;
  final String? questionText;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewDate;
  final DateTime lastReviewedAt;
  final int qualityRating;
  final String masteryLevel;
  final String priority;
  final String sourceTag;

  const RevisionItem({
    required this.id,
    required this.topic,
    this.subtopic,
    this.questionId,
    this.questionText,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.repetitions = 0,
    required this.nextReviewDate,
    required this.lastReviewedAt,
    this.qualityRating = 3,
    this.masteryLevel = 'Learning',
    this.priority = 'Medium',
    this.sourceTag = 'AI Mentor',
  });

  bool get isOverdue => DateTime.now().isAfter(nextReviewDate);
  bool get isDueToday {
    final now = DateTime.now();
    return nextReviewDate.year == now.year &&
        nextReviewDate.month == now.month &&
        nextReviewDate.day == now.day;
  }

  RevisionItem copyWith({
    String? topic,
    String? subtopic,
    String? questionId,
    String? questionText,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewDate,
    DateTime? lastReviewedAt,
    int? qualityRating,
    String? masteryLevel,
    String? priority,
    String? sourceTag,
  }) {
    return RevisionItem(
      id: id,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      qualityRating: qualityRating ?? this.qualityRating,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      priority: priority ?? this.priority,
      sourceTag: sourceTag ?? this.sourceTag,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevisionItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          topic == other.topic &&
          subtopic == other.subtopic &&
          questionId == other.questionId &&
          questionText == other.questionText &&
          easeFactor == other.easeFactor &&
          intervalDays == other.intervalDays &&
          repetitions == other.repetitions &&
          nextReviewDate == other.nextReviewDate &&
          lastReviewedAt == other.lastReviewedAt &&
          qualityRating == other.qualityRating &&
          masteryLevel == other.masteryLevel &&
          priority == other.priority &&
          sourceTag == other.sourceTag;

  @override
  int get hashCode => Object.hash(
        id,
        topic,
        subtopic,
        questionId,
        questionText,
        easeFactor,
        intervalDays,
        repetitions,
        nextReviewDate,
        lastReviewedAt,
        qualityRating,
        masteryLevel,
        priority,
        sourceTag,
      );
}

/// Immutable calculation result produced by the SuperMemo-2 (SM-2) Spaced Repetition Engine.
@immutable
class SpacedRepetitionSchedule {
  final RevisionItem updatedItem;
  final double calculatedEaseFactor;
  final int nextIntervalDays;
  final DateTime nextReviewDate;

  const SpacedRepetitionSchedule({
    required this.updatedItem,
    required this.calculatedEaseFactor,
    required this.nextIntervalDays,
    required this.nextReviewDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpacedRepetitionSchedule &&
          runtimeType == other.runtimeType &&
          updatedItem == other.updatedItem &&
          calculatedEaseFactor == other.calculatedEaseFactor &&
          nextIntervalDays == other.nextIntervalDays &&
          nextReviewDate == other.nextReviewDate;

  @override
  int get hashCode => Object.hash(
        updatedItem,
        calculatedEaseFactor,
        nextIntervalDays,
        nextReviewDate,
      );
}

/// Immutable container model representing a personalized daily/upcoming revision queue.
@immutable
class RevisionQueue {
  final String id;
  final String userId;
  final DateTime generatedAt;
  final List<RevisionItem> items;
  final int dueTodayCount;
  final int overdueCount;
  final int masteredCount;
  final String summary;

  RevisionQueue({
    required this.id,
    required this.userId,
    required this.generatedAt,
    required List<RevisionItem> items,
    required this.dueTodayCount,
    required this.overdueCount,
    required this.masteredCount,
    required this.summary,
  }) : items = List<RevisionItem>.unmodifiable(items);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevisionQueue &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          generatedAt == other.generatedAt &&
          dueTodayCount == other.dueTodayCount &&
          overdueCount == other.overdueCount &&
          masteredCount == other.masteredCount &&
          summary == other.summary &&
          _listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        generatedAt,
        dueTodayCount,
        overdueCount,
        masteredCount,
        summary,
        Object.hashAll(items),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
