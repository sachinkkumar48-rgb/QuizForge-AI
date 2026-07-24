class RevisionSchedule {
  final String scheduleId;
  final String questionId;
  final DateTime lastReviewed;
  final DateTime nextReviewDue;
  final int repetitionLevel; // Leitner Box 1 to 5
  final double easeFactor;
  final int mistakeCount;
  final int confidenceRating; // 1: Again, 2: Hard, 3: Good, 4: Easy
  final double priorityScore; // 0.0 to 100.0
  final String priorityTier; // Critical, High, Medium, Low
  final String? aiRecommendationReason;

  RevisionSchedule({
    required this.scheduleId,
    required this.questionId,
    DateTime? lastReviewed,
    DateTime? nextReviewDue,
    this.repetitionLevel = 1,
    this.easeFactor = 2.5,
    this.mistakeCount = 0,
    this.confidenceRating = 3,
    this.priorityScore = 50.0,
    this.priorityTier = 'Medium',
    this.aiRecommendationReason,
  })  : lastReviewed = lastReviewed ?? DateTime.now(),
        nextReviewDue = nextReviewDue ?? DateTime.now();

  RevisionSchedule copyWith({
    String? scheduleId,
    String? questionId,
    DateTime? lastReviewed,
    DateTime? nextReviewDue,
    int? repetitionLevel,
    double? easeFactor,
    int? mistakeCount,
    int? confidenceRating,
    double? priorityScore,
    String? priorityTier,
    String? aiRecommendationReason,
  }) {
    return RevisionSchedule(
      scheduleId: scheduleId ?? this.scheduleId,
      questionId: questionId ?? this.questionId,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReviewDue: nextReviewDue ?? this.nextReviewDue,
      repetitionLevel: repetitionLevel ?? this.repetitionLevel,
      easeFactor: easeFactor ?? this.easeFactor,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      confidenceRating: confidenceRating ?? this.confidenceRating,
      priorityScore: priorityScore ?? this.priorityScore,
      priorityTier: priorityTier ?? this.priorityTier,
      aiRecommendationReason:
          aiRecommendationReason ?? this.aiRecommendationReason,
    );
  }

  factory RevisionSchedule.fromJson(Map<String, dynamic> json) {
    return RevisionSchedule(
      scheduleId: json['scheduleId'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      lastReviewed: json['lastReviewed'] != null
          ? DateTime.tryParse(json['lastReviewed'] as String) ?? DateTime.now()
          : DateTime.now(),
      nextReviewDue: json['nextReviewDue'] != null
          ? DateTime.tryParse(json['nextReviewDue'] as String) ?? DateTime.now()
          : DateTime.now(),
      repetitionLevel: json['repetitionLevel'] as int? ?? 1,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      mistakeCount: json['mistakeCount'] as int? ?? 0,
      confidenceRating: json['confidenceRating'] as int? ?? 3,
      priorityScore: (json['priorityScore'] as num?)?.toDouble() ?? 50.0,
      priorityTier: json['priorityTier'] as String? ?? 'Medium',
      aiRecommendationReason: json['aiRecommendationReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId,
      'questionId': questionId,
      'lastReviewed': lastReviewed.toIso8601String(),
      'nextReviewDue': nextReviewDue.toIso8601String(),
      'repetitionLevel': repetitionLevel,
      'easeFactor': easeFactor,
      'mistakeCount': mistakeCount,
      'confidenceRating': confidenceRating,
      'priorityScore': priorityScore,
      'priorityTier': priorityTier,
      if (aiRecommendationReason != null)
        'aiRecommendationReason': aiRecommendationReason,
    };
  }
}
