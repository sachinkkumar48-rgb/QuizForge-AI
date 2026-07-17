import 'quiz_model.dart';

enum PerformanceLevel {
  excellent,
  good,
  average,
  needsImprovement,
}

class QuizAnalytics {
  final int score;
  final int totalQuestions;
  final int attempted;
  final int skipped;
  final int incorrect;
  final double accuracy;
  final PerformanceLevel performanceLevel;
  final Duration timeSpent;
  final Duration remainingTime;
  final Duration totalDuration;
  final Map<QuestionStatus, int> statusCounts;

  QuizAnalytics({
    required this.score,
    required this.totalQuestions,
    required this.attempted,
    required this.skipped,
    required this.incorrect,
    required this.accuracy,
    required this.performanceLevel,
    required this.timeSpent,
    required this.remainingTime,
    required this.totalDuration,
    required this.statusCounts,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'totalQuestions': totalQuestions,
      'attempted': attempted,
      'skipped': skipped,
      'incorrect': incorrect,
      'accuracy': accuracy,
      'performanceLevel': performanceLevel.name,
      'timeSpent': timeSpent.inSeconds,
      'remainingTime': remainingTime.inSeconds,
      'totalDuration': totalDuration.inSeconds,
      'statusCounts':
          statusCounts.map((key, value) => MapEntry(key.name, value)),
    };
  }

  factory QuizAnalytics.fromJson(Map<String, dynamic> json) {
    return QuizAnalytics(
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      attempted: json['attempted'] as int,
      skipped: json['skipped'] as int,
      incorrect: json['incorrect'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
      performanceLevel:
          PerformanceLevel.values.byName(json['performanceLevel'] as String),
      timeSpent: Duration(seconds: json['timeSpent'] as int),
      remainingTime: Duration(seconds: json['remainingTime'] as int),
      totalDuration: Duration(seconds: json['totalDuration'] as int),
      statusCounts: (json['statusCounts'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(QuestionStatus.values.byName(key), value as int),
      ),
    );
  }

  String get formattedTimeSpent {
    final s = timeSpent.inSeconds;
    final hrs = s ~/ 3600;
    final mins = (s % 3600) ~/ 60;
    final secs = s % 60;
    if (hrs > 0) {
      return "${hrs}h ${mins}m ${secs}s";
    } else if (mins > 0) {
      return "${mins}m ${secs}s";
    } else {
      return "${secs}s";
    }
  }

  String get formattedRemainingTime {
    final s = remainingTime.inSeconds;
    final hrs = s ~/ 3600;
    final mins = (s % 3600) ~/ 60;
    final secs = s % 60;
    if (hrs > 0) {
      return "${hrs}h ${mins}m ${secs}s";
    } else if (mins > 0) {
      return "${mins}m ${secs}s";
    } else {
      return "${secs}s";
    }
  }

  String get formattedAverageTimePerQuestion {
    if (attempted == 0) return "0s";
    final s = timeSpent.inSeconds ~/ attempted;
    if (s > 60) {
      return "${s ~/ 60}m ${s % 60}s";
    }
    return "${s}s";
  }
}
