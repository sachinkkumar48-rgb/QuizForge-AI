import 'package:meta/meta.dart';

/// Status of an item within the spaced review schedule.
enum ReviewStatus {
  due,
  learning,
  mastered,
}

/// Immutable model representing a scheduled spaced-repetition review target for a question or topic.
@immutable
class ReviewScheduleItem {
  final String id;
  final String topic;
  final String? questionId;
  final ReviewStatus status;
  final Duration reviewInterval;
  final DateTime nextReviewAt;
  final DateTime lastAttemptAt;
  final int consecutiveCorrect;
  final String? sourceChunkId;
  final int? pageNumber;
  final String? documentId;

  ReviewScheduleItem({
    required this.id,
    required this.topic,
    this.questionId,
    this.status = ReviewStatus.learning,
    this.reviewInterval = const Duration(days: 1),
    required this.nextReviewAt,
    required this.lastAttemptAt,
    this.consecutiveCorrect = 0,
    this.sourceChunkId,
    this.pageNumber,
    this.documentId,
  });

  const ReviewScheduleItem.constItem({
    required this.id,
    required this.topic,
    required this.questionId,
    required this.status,
    required this.reviewInterval,
    required this.nextReviewAt,
    required this.lastAttemptAt,
    required this.consecutiveCorrect,
    required this.sourceChunkId,
    required this.pageNumber,
    required this.documentId,
  });

  bool isDue([DateTime? asOf]) {
    final threshold = asOf ?? DateTime.now();
    return nextReviewAt.isBefore(threshold) ||
        nextReviewAt.isAtSameMomentAs(threshold);
  }

  ReviewScheduleItem copyWith({
    String? id,
    String? topic,
    String? questionId,
    ReviewStatus? status,
    Duration? reviewInterval,
    DateTime? nextReviewAt,
    DateTime? lastAttemptAt,
    int? consecutiveCorrect,
    String? sourceChunkId,
    int? pageNumber,
    String? documentId,
  }) {
    return ReviewScheduleItem(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      questionId: questionId ?? this.questionId,
      status: status ?? this.status,
      reviewInterval: reviewInterval ?? this.reviewInterval,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      sourceChunkId: sourceChunkId ?? this.sourceChunkId,
      pageNumber: pageNumber ?? this.pageNumber,
      documentId: documentId ?? this.documentId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewScheduleItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          topic == other.topic &&
          questionId == other.questionId &&
          status == other.status &&
          consecutiveCorrect == other.consecutiveCorrect &&
          nextReviewAt == other.nextReviewAt;

  @override
  int get hashCode => Object.hash(
      id, topic, questionId, status, consecutiveCorrect, nextReviewAt);
}
