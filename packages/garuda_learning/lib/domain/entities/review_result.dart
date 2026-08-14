import 'performance_rating.dart';

/// Value object capturing the outcome of a review attempt for a learning objective.
class ReviewResult {
  /// Target P17 objective ID.
  final String objectiveId;

  /// SM-2 performance rating derived or self-rated.
  final PerformanceRating rating;

  /// P18 assessment score float in range [0.0, 1.0].
  final double assessmentScore;

  /// UTC timestamp when the review attempt took place.
  final DateTime timestamp;

  ReviewResult({
    required this.objectiveId,
    required this.rating,
    required double assessmentScore,
    DateTime? timestamp,
  })  : assessmentScore = assessmentScore.clamp(0.0, 1.0),
        timestamp = (timestamp ?? DateTime.now()).toUtc();

  /// Creates a [ReviewResult] automatically from a P18 assessment score.
  factory ReviewResult.fromScore({
    required String objectiveId,
    required double score,
    DateTime? timestamp,
  }) {
    return ReviewResult(
      objectiveId: objectiveId,
      rating: PerformanceRating.fromScore(score),
      assessmentScore: score,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectiveId': objectiveId,
      'rating': rating.name,
      'assessmentScore': assessmentScore,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ReviewResult.fromJson(Map<String, dynamic> json) {
    return ReviewResult(
      objectiveId: json['objectiveId'] as String,
      rating: PerformanceRating.values.byName(json['rating'] as String),
      assessmentScore: (json['assessmentScore'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewResult &&
        other.objectiveId == objectiveId &&
        other.rating == rating &&
        (other.assessmentScore - assessmentScore).abs() < 0.001 &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(objectiveId, rating, assessmentScore, timestamp);
  }

  @override
  String toString() {
    return 'ReviewResult(objectiveId: $objectiveId, rating: ${rating.label}, '
        'score: ${assessmentScore.toStringAsFixed(2)}, timestamp: $timestamp)';
  }
}
