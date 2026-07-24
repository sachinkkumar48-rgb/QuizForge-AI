class QuestionStatistics {
  final String questionId;
  final int totalAttempts;
  final int correctAttempts;
  final int incorrectAttempts;
  final double accuracyPercentage;
  final int averageTimeSeconds;
  final DateTime? lastAttemptedAt;

  QuestionStatistics({
    required this.questionId,
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.incorrectAttempts = 0,
    this.accuracyPercentage = 0.0,
    this.averageTimeSeconds = 0,
    this.lastAttemptedAt,
  });

  factory QuestionStatistics.fromJson(Map<String, dynamic> json) {
    return QuestionStatistics(
      questionId: json['questionId'] as String? ?? '',
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      correctAttempts: json['correctAttempts'] as int? ?? 0,
      incorrectAttempts: json['incorrectAttempts'] as int? ?? 0,
      accuracyPercentage:
          (json['accuracyPercentage'] as num?)?.toDouble() ?? 0.0,
      averageTimeSeconds: json['averageTimeSeconds'] as int? ?? 0,
      lastAttemptedAt: json['lastAttemptedAt'] != null
          ? DateTime.tryParse(json['lastAttemptedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'incorrectAttempts': incorrectAttempts,
      'accuracyPercentage': accuracyPercentage,
      'averageTimeSeconds': averageTimeSeconds,
      if (lastAttemptedAt != null)
        'lastAttemptedAt': lastAttemptedAt!.toIso8601String(),
    };
  }
}
