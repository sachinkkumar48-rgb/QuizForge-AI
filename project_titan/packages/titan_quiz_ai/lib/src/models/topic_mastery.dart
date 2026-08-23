import 'package:meta/meta.dart';
import 'mastery_trend.dart';
import 'retention_signal.dart';

/// Immutable domain entity tracking deterministic mastery and retention metrics for a learning topic.
@immutable
class TopicMastery {
  final String topic;
  final int attempts;
  final int correct;
  final int incorrect;
  final double accuracy;
  final double masteryScore;
  final double confidence;
  final MasteryTrend trend;
  final RetentionSignal retention;
  final int consecutiveCorrect;
  final DateTime? lastAttemptAt;
  final List<String> sourceChunkIds;
  final List<int> pageNumbers;
  final String? documentId;
  final List<double> historyAccuracies;

  TopicMastery({
    required this.topic,
    this.attempts = 0,
    this.correct = 0,
    this.incorrect = 0,
    double? accuracy,
    double? masteryScore,
    double? confidence,
    this.trend = MasteryTrend.insufficientData,
    this.retention = RetentionSignal.insufficientData,
    this.consecutiveCorrect = 0,
    this.lastAttemptAt,
    List<String>? sourceChunkIds,
    List<int>? pageNumbers,
    this.documentId,
    List<double>? historyAccuracies,
  })  : accuracy = accuracy ??
            (attempts > 0 ? (correct / attempts).clamp(0.0, 1.0) : 0.0),
        masteryScore =
            masteryScore ?? _calculateDefaultMastery(correct, attempts),
        confidence = confidence ?? _calculateDefaultConfidence(attempts),
        sourceChunkIds = List.unmodifiable(sourceChunkIds ?? const []),
        pageNumbers = List.unmodifiable(pageNumbers ?? const []),
        historyAccuracies = List.unmodifiable(historyAccuracies ?? const []);

  const TopicMastery.constMastery({
    required this.topic,
    required this.attempts,
    required this.correct,
    required this.incorrect,
    required this.accuracy,
    required this.masteryScore,
    required this.confidence,
    required this.trend,
    required this.retention,
    required this.consecutiveCorrect,
    required this.lastAttemptAt,
    required this.sourceChunkIds,
    required this.pageNumbers,
    required this.documentId,
    required this.historyAccuracies,
  });

  /// Factory for new topic with zero prior attempts.
  factory TopicMastery.initial(String topic, {String? documentId}) {
    return TopicMastery(
      topic: topic,
      attempts: 0,
      correct: 0,
      incorrect: 0,
      accuracy: 0.0,
      masteryScore: 0.0,
      confidence: 0.0,
      trend: MasteryTrend.insufficientData,
      retention: RetentionSignal.insufficientData,
      documentId: documentId,
    );
  }

  /// Calculates a bounded Bayesian-smoothed mastery score: (correct + 1) / (attempts + 2)
  /// scaled so it doesn't swing wildly on a single question.
  static double _calculateDefaultMastery(int correct, int attempts) {
    if (attempts == 0) return 0.0;
    // Smoothed estimate with prior mean of 0.5 (weight=2)
    final smoothed = (correct + 1.0) / (attempts + 2.0);
    return smoothed.clamp(0.0, 1.0);
  }

  /// Calculates confidence metric based on sample size (approaches 1.0 around 10 attempts).
  static double _calculateDefaultConfidence(int attempts) {
    if (attempts == 0) return 0.0;
    return (attempts / (attempts + 5.0)).clamp(0.0, 1.0);
  }

  bool get isWeak => masteryScore < 0.60;
  bool get isStrong => masteryScore >= 0.80 && confidence >= 0.40;
  bool get hasAttempted => attempts > 0;

  TopicMastery copyWith({
    String? topic,
    int? attempts,
    int? correct,
    int? incorrect,
    double? accuracy,
    double? masteryScore,
    double? confidence,
    MasteryTrend? trend,
    RetentionSignal? retention,
    int? consecutiveCorrect,
    DateTime? lastAttemptAt,
    List<String>? sourceChunkIds,
    List<int>? pageNumbers,
    String? documentId,
    List<double>? historyAccuracies,
  }) {
    return TopicMastery(
      topic: topic ?? this.topic,
      attempts: attempts ?? this.attempts,
      correct: correct ?? this.correct,
      incorrect: incorrect ?? this.incorrect,
      accuracy: accuracy ?? this.accuracy,
      masteryScore: masteryScore ?? this.masteryScore,
      confidence: confidence ?? this.confidence,
      trend: trend ?? this.trend,
      retention: retention ?? this.retention,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      sourceChunkIds: sourceChunkIds ?? this.sourceChunkIds,
      pageNumbers: pageNumbers ?? this.pageNumbers,
      documentId: documentId ?? this.documentId,
      historyAccuracies: historyAccuracies ?? this.historyAccuracies,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicMastery &&
          runtimeType == other.runtimeType &&
          topic == other.topic &&
          attempts == other.attempts &&
          correct == other.correct &&
          incorrect == other.incorrect &&
          masteryScore == other.masteryScore &&
          trend == other.trend;

  @override
  int get hashCode =>
      Object.hash(topic, attempts, correct, incorrect, masteryScore, trend);
}
