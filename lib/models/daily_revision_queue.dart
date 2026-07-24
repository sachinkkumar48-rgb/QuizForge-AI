import 'pyq_question_model.dart';
import 'revision_schedule.dart';

class RevisionQueueItem {
  final PyqQuestionModel question;
  final RevisionSchedule schedule;
  final double priorityScore;
  final String priorityTier;
  final String reason;

  RevisionQueueItem({
    required this.question,
    required this.schedule,
    required this.priorityScore,
    required this.priorityTier,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': question.id,
      'schedule': schedule.toJson(),
      'priorityScore': priorityScore,
      'priorityTier': priorityTier,
      'reason': reason,
    };
  }
}

class DailyRevisionQueue {
  final DateTime date;
  final int totalDueCount;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final List<RevisionQueueItem> items;
  final String smartReminderMessage;
  final String aiRecommendationSummary;

  DailyRevisionQueue({
    required this.date,
    required this.totalDueCount,
    required this.criticalCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.items,
    required this.smartReminderMessage,
    required this.aiRecommendationSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalDueCount': totalDueCount,
      'criticalCount': criticalCount,
      'highCount': highCount,
      'mediumCount': mediumCount,
      'lowCount': lowCount,
      'items': items.map((i) => i.toJson()).toList(),
      'smartReminderMessage': smartReminderMessage,
      'aiRecommendationSummary': aiRecommendationSummary,
    };
  }
}
