class QuestionAttempt {
  final String attemptId;
  final String questionId;
  final String userSelectedAnswer;
  final bool isCorrect;
  final int timeSpentSeconds;
  final DateTime attemptedAt;
  final String mode; // Exam, Practice, Revision, Custom

  QuestionAttempt({
    required this.attemptId,
    required this.questionId,
    required this.userSelectedAnswer,
    required this.isCorrect,
    this.timeSpentSeconds = 0,
    DateTime? attemptedAt,
    this.mode = 'Practice',
  }) : attemptedAt = attemptedAt ?? DateTime.now();

  factory QuestionAttempt.fromJson(Map<String, dynamic> json) {
    return QuestionAttempt(
      attemptId: json['attemptId'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      userSelectedAnswer: json['userSelectedAnswer'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      attemptedAt: json['attemptedAt'] != null
          ? DateTime.tryParse(json['attemptedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      mode: json['mode'] as String? ?? 'Practice',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attemptId': attemptId,
      'questionId': questionId,
      'userSelectedAnswer': userSelectedAnswer,
      'isCorrect': isCorrect,
      'timeSpentSeconds': timeSpentSeconds,
      'attemptedAt': attemptedAt.toIso8601String(),
      'mode': mode,
    };
  }
}
