import 'quiz_analytics.dart';

class QuizAttempt {
  final String id;
  final DateTime completedAt;
  final String sourceName;
  final QuizAnalytics analytics;

  const QuizAttempt({
    required this.id,
    required this.completedAt,
    required this.sourceName,
    required this.analytics,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      sourceName: json['sourceName'] as String,
      analytics:
          QuizAnalytics.fromJson(json['analytics'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completedAt': completedAt.toIso8601String(),
      'sourceName': sourceName,
      'analytics': analytics.toJson(),
    };
  }

  QuizAttempt copyWith({
    String? id,
    DateTime? completedAt,
    String? sourceName,
    QuizAnalytics? analytics,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      completedAt: completedAt ?? this.completedAt,
      sourceName: sourceName ?? this.sourceName,
      analytics: analytics ?? this.analytics,
    );
  }
}
