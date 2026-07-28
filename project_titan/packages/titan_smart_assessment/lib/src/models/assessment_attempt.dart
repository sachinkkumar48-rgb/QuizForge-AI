import 'package:meta/meta.dart';

/// Immutable domain model representing a single question attempt in an assessment.
@immutable
class AssessmentAttempt {
  final String id;
  final String sessionId;
  final String questionId;
  final String selectedOptionId;
  final String textResponse;
  final bool isCorrect;
  final double pointsEarned;
  final int timeSpentSeconds;
  final double confidenceLevel; // 0.0 to 1.0
  final DateTime timestamp;

  const AssessmentAttempt({
    required this.id,
    required this.sessionId,
    required this.questionId,
    this.selectedOptionId = '',
    this.textResponse = '',
    this.isCorrect = false,
    this.pointsEarned = 0.0,
    this.timeSpentSeconds = 0,
    this.confidenceLevel = 0.5,
    required this.timestamp,
  });

  AssessmentAttempt copyWith({
    String? id,
    String? sessionId,
    String? questionId,
    String? selectedOptionId,
    String? textResponse,
    bool? isCorrect,
    double? pointsEarned,
    int? timeSpentSeconds,
    double? confidenceLevel,
    DateTime? timestamp,
  }) {
    return AssessmentAttempt(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      questionId: questionId ?? this.questionId,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      textResponse: textResponse ?? this.textResponse,
      isCorrect: isCorrect ?? this.isCorrect,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'questionId': questionId,
        'selectedOptionId': selectedOptionId,
        'textResponse': textResponse,
        'isCorrect': isCorrect,
        'pointsEarned': pointsEarned,
        'timeSpentSeconds': timeSpentSeconds,
        'confidenceLevel': confidenceLevel,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AssessmentAttempt.fromJson(Map<String, dynamic> json) =>
      AssessmentAttempt(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        questionId: json['questionId'] as String,
        selectedOptionId: json['selectedOptionId'] as String? ?? '',
        textResponse: json['textResponse'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
        pointsEarned: (json['pointsEarned'] as num? ?? 0.0).toDouble(),
        timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
        confidenceLevel: (json['confidenceLevel'] as num? ?? 0.5).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentAttempt &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          questionId == other.questionId;

  @override
  int get hashCode => Object.hash(id, sessionId, questionId);
}
